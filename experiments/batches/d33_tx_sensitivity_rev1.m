function T = d33_tx_sensitivity_rev1(root)
%D33_TX_SENSITIVITY_REV1 Transmitter height 0.5, 0.7 and 1.0 m on the B32 rows with 3 m and 10 m receivers (B33 X03, descriptive).
%   T = D33_TX_SENSITIVITY_REV1(root) reruns 707 and stock ITM on the B32
%   rows whose receiver is at 3 m or 10 m, with the transmitter at 0.5, 0.7
%   and 1.0 m and every other input as in d32_run_models_rev1. Profiles are
%   resampled from the B31 terminal positions exactly as d32_run_models_rev1
%   does, not read back from profiles_rev1.csv: on a few paths ITM's loss
%   jumps by up to 0.2 dB under the 1e-13 m rounding of that CSV (B33.md
%   section 6). It writes
%   tx_sensitivity_rev1.csv there. Checks that the 0.5 m rerun reproduces
%   predictions_rev1.csv (B33.md section 5 check 2). No run below 0.5 m.
arguments
    root (1,1) string
end
itm_exp_paths_rev1();
S = settings_rev1();
d = fullfile(root, 'experiments', 'D32-ot7574-heights');
Pr = readtable(fullfile(d, 'predictions_rev1.csv'), 'TextType', 'string');
G = readtable(fullfile(d, 'paths_rev1.csv'), 'TextType', 'string');
ter = readtable(fullfile(root, 'experiments', 'D31-ot7574', 'terminals_all_rev1.csv'), 'TextType', 'string');
tkey = ter.area + "|" + ter.terminal;
parts = split(G.geom_key, "|");
[okT, iT] = ismember(parts(:, 1) + "|" + parts(:, 2), tkey);
[okR, iR] = ismember(parts(:, 1) + "|" + parts(:, 3), tkey);
if ~all(okT) || ~all(okR)
    error('itmexp:d33', 'Terminal positions missing for some B32 pairs.');
end
pfls = itm_terrain_profile_rev1(ter.lat(iT), ter.lon(iT), ter.lat(iR), ter.lon(iR), spacing_m=S.profile_spacing_m);
if ~iscell(pfls), pfls = {pfls}; end
for j = 1:height(G)
    if pfls{j}(1) + 1 ~= G.n_points(j) || abs(pfls{j}(2) - G.spacing_m(j)) > 1e-9
        error('itmexp:d33', 'Resampled profile %s differs from paths_rev1.csv.', G.geom_key(j));
    end
end
R = Pr(Pr.rx_ant_m == 3 | Pr.rx_ant_m == 10, :);
if height(R) ~= 840
    error('itmexp:d33', 'Expected 840 rows with a 3 m or 10 m receiver, found %d.', height(R));
end
ov = '{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}';
setenv('ITMEXP_OVERRIDES', ov); cfg7 = params_exp(); setenv('ITMEXP_OVERRIDES', '');
if cfg7.diffraction ~= "delta_cascaded_isolated"
    error('itmexp:d33', 'params_exp did not load 707''s switches.');
end
hs = [0.5 0.7 1.0];
L7 = NaN(height(R), numel(hs)); Ls = L7;
for i = 1:height(R)
    pf = pfls{G.geom_key == R.geom_key(i)};
    c = cfg7;
    c.row = struct('set', "OT7574", 'siting', "O", 'reversed', false, ...
        'path_id', sprintf("%d_T%d_R%d", R.table(i), R.tx(i), R.rx(i)));
    for k = 1:numel(hs)
        L7(i, k) = itm_p2p_core_exp(hs(k), R.rx_model_m(i), pf, R.f_mhz(i), 50, S.confidence, S.location, ...
            R.climate(i), R.N_0(i), 1, R.epsilon(i), R.sigma(i), S.mdvar, false, [], c);
        Ls(i, k) = itm_p2p_rev1(hs(k), R.rx_model_m(i), pf, R.f_mhz(i), 50, confidence=S.confidence, ...
            climate=R.climate(i), N_0=R.N_0(i), polarization=1, epsilon=R.epsilon(i), sigma=R.sigma(i), ...
            mdvar=S.mdvar, validity="off");
    end
end
% Fresh profiles, so the 0.5 m rerun must match B32 exactly (tolerance for summation order only)
dev = max(abs([L7(:, 1) - R.L_707_db; Ls(:, 1) - R.L_stock_db]));
if dev > 1e-6
    error('itmexp:d33', 'The 0.5 m rerun differs from predictions_rev1.csv by %.3g dB.', dev);
end
fprintf('0.5 m rerun matches predictions_rev1.csv (largest difference %.2g dB)\n', dev);
T = R(:, {'table', 'tx', 'rx', 'geom_key', 'band', 'f_mhz', 'rx_ant_m', 'loss_db', 'lower_bound', 'questionable', 'missing', 'uncertain'});
T.L707_t050 = L7(:, 1); T.L707_t070 = L7(:, 2); T.L707_t100 = L7(:, 3);
T.Lst_t050 = Ls(:, 1); T.Lst_t070 = Ls(:, 2); T.Lst_t100 = Ls(:, 3);
writetable(T, fullfile(d, 'tx_sensitivity_rev1.csv'));
fprintf('Wrote tx_sensitivity_rev1.csv (%d rows)\n', height(T));
end
