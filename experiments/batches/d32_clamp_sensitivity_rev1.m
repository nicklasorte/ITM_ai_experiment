function T = d32_clamp_sensitivity_rev1(root)
%D32_CLAMP_SENSITIVITY_REV1 How much each model's loss changes just above ITM's 0.5 m height limit (B32, descriptive).
%   T = D32_CLAMP_SENSITIVITY_REV1(root) reruns 707 and stock ITM on the
%   B32 rows whose measured receiver is at 0.35 m, with the receiver at
%   0.5, 0.7 and 1.0 m (transmitter at 0.5 m, every other input as in
%   d32_run_models_rev1), on the saved profiles in
%   experiments/D32-ot7574-heights/. It writes clamp_sensitivity_rev1.csv
%   there. The slope of loss against height just above the limit says how
%   much the 0.35 m to 0.5 m receiver clamp could matter inside each model;
%   it isn't a prediction at 0.35 m. Also reruns the 0.5 m case and stops if
%   it differs from predictions_rev1.csv.
arguments
    root (1,1) string
end
itm_exp_paths_rev1();
S = settings_rev1();
d = fullfile(root, 'experiments', 'D32-ot7574-heights');
Pr = readtable(fullfile(d, 'predictions_rev1.csv'), 'TextType', 'string');
G = readtable(fullfile(d, 'paths_rev1.csv'), 'TextType', 'string');
H = readtable(fullfile(d, 'profiles_rev1.csv'), 'TextType', 'string');
R = Pr(Pr.rx_ant_m == 0.35, :);
if height(R) ~= 420
    error('itmexp:d32', 'Expected 420 rows with a 0.35 m receiver, found %d.', height(R));
end
ov = '{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}';
setenv('ITMEXP_OVERRIDES', ov); cfg7 = params_exp(); setenv('ITMEXP_OVERRIDES', '');
if cfg7.diffraction ~= "delta_cascaded_isolated"
    error('itmexp:d32', 'params_exp did not load 707''s switches.');
end
hs = [0.5 0.7 1.0];
L7 = NaN(height(R), numel(hs)); Ls = L7;
for i = 1:height(R)
    g = find(G.geom_key == R.geom_key(i));
    h = H.h_m(H.geom_key == R.geom_key(i));
    pf = [G.n_points(g) - 1; G.spacing_m(g); h(:)];
    c = cfg7;
    c.row = struct('set', "OT7574", 'siting', "O", 'reversed', false, ...
        'path_id', sprintf("%d_T%d_R%d", R.table(i), R.tx(i), R.rx(i)));
    for k = 1:numel(hs)
        L7(i, k) = itm_p2p_core_exp(R.tx_model_m(i), hs(k), pf, R.f_mhz(i), 50, S.confidence, S.location, ...
            R.climate(i), R.N_0(i), 1, R.epsilon(i), R.sigma(i), S.mdvar, false, [], c);
        Ls(i, k) = itm_p2p_rev1(R.tx_model_m(i), hs(k), pf, R.f_mhz(i), 50, confidence=S.confidence, ...
            climate=R.climate(i), N_0=R.N_0(i), polarization=1, epsilon=R.epsilon(i), sigma=R.sigma(i), ...
            mdvar=S.mdvar, validity="off");
    end
end
% The saved profile is written to 15 significant digits, so allow a small tolerance
dev = max(abs([L7(:, 1) - R.L_707_db; Ls(:, 1) - R.L_stock_db]));
if dev > 1e-6
    error('itmexp:d32', 'The 0.5 m rerun differs from predictions_rev1.csv by %.3g dB.', dev);
end
fprintf('0.5 m rerun matches predictions_rev1.csv (largest difference %.2g dB)\n', dev);
T = R(:, {'table', 'tx', 'rx', 'geom_key', 'band', 'f_mhz', 'loss_db', 'lower_bound', 'questionable', 'missing', 'uncertain'});
T.L707_h050 = L7(:, 1); T.L707_h070 = L7(:, 2); T.L707_h100 = L7(:, 3);
T.Lst_h050 = Ls(:, 1); T.Lst_h070 = Ls(:, 2); T.Lst_h100 = Ls(:, 3);
writetable(T, fullfile(d, 'clamp_sensitivity_rev1.csv'));
fprintf('Wrote clamp_sensitivity_rev1.csv (%d rows)\n', height(T));
end
