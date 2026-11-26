function R = d34_roundtrip_rev1(root, options)
%D34_ROUNDTRIP_REV1 B34 D34c: does ITM's loss depend on how the profile was stored? (diagnostic, no score)
%   R = D34_ROUNDTRIP_REV1(root) reruns stock ITM and 707 on the B32 rows
%   with a 3 m or 10 m receiver (transmitter 0.5 m, 840 rows), using six
%   versions of each profile:
%     fresh      resampled now from the B31 terminals, as d32_run_models_rev1
%     csv        rebuilt from D32-ot7574-heights/profiles_rev1.csv and paths_rev1.csv
%     spacing    fresh elevations with the CSV spacing
%     elevation  CSV elevations with the fresh spacing
%     text17     fresh written with %.17g and read back
%     mat        fresh saved to a MAT file and loaded
%   It checks fresh against B32's stored predictions (1e-6 dB, B33.md),
%   checks that text17 and mat are bit-identical to fresh, and writes
%   experiments/D34c-profile-roundtrip/{profile_hashes_rev1.csv,
%   parity_rev1.csv, profiles_lossless_rev1.mat}.
%
%   R = D34_ROUNDTRIP_REV1(root, Smoke=true) runs one pair (Hunter|T4|R4,
%   the pair B33 examined) and writes nothing.
%
%   Nothing in eval/, data/ or itm_variant/ is changed. Fails loud.
arguments
    root (1,1) string
    options.Smoke (1,1) logical = false
end
itm_exp_paths_rev1();
S = settings_rev1();
d32 = fullfile(root, 'experiments', 'D32-ot7574-heights');
Pr = readtable(fullfile(d32, 'predictions_rev1.csv'), 'TextType', 'string');
G = readtable(fullfile(d32, 'paths_rev1.csv'), 'TextType', 'string');
H = readtable(fullfile(d32, 'profiles_rev1.csv'), 'TextType', 'string');
ter = readtable(fullfile(root, 'experiments', 'D31-ot7574', 'terminals_all_rev1.csv'), 'TextType', 'string');
R = Pr(Pr.rx_ant_m == 3 | Pr.rx_ant_m == 10, :);
if height(R) ~= 840
    error('itmexp:d34c', 'Expected 840 rows with a 3 m or 10 m receiver, found %d.', height(R));
end
if options.Smoke
    G = G(G.geom_key == "Hunter|T4|R4", :);
    R = R(R.geom_key == "Hunter|T4|R4", :);
end
ng = height(G);

% ---- Fresh profiles, as d32_run_models_rev1 / d33_tx_sensitivity_rev1
tkey = ter.area + "|" + ter.terminal;
parts = split(G.geom_key, "|");
if size(parts, 2) == 1, parts = parts'; end
[okT, iT] = ismember(parts(:, 1) + "|" + parts(:, 2), tkey);
[okR, iR] = ismember(parts(:, 1) + "|" + parts(:, 3), tkey);
if ~all(okT) || ~all(okR)
    error('itmexp:d34c', 'Terminal positions missing for some pairs.');
end
pf_fresh = itm_terrain_profile_rev1(ter.lat(iT), ter.lon(iT), ter.lat(iR), ter.lon(iR), ...
    spacing_m=S.profile_spacing_m);
if ~iscell(pf_fresh), pf_fresh = {pf_fresh}; end

% ---- Other versions
tmpmat = [tempname '.mat'];
V = struct('fresh', {pf_fresh}, 'csv', {cell(ng, 1)}, 'spacing', {cell(ng, 1)}, ...
    'elevation', {cell(ng, 1)}, 'text17', {cell(ng, 1)}, 'mat', {cell(ng, 1)});
hashes = table('Size', [ng 9], 'VariableTypes', ["string" "double" "string" "string" "double" "double" "double" "double" "double"], ...
    'VariableNames', ["geom_key" "n_points" "spacing_fresh_hex" "spacing_csv_hex" "spacing_diff_m" ...
    "spacing_diff_ulp" "n_elev_differ" "max_abs_elev_diff_m" "max_elev_diff_ulp"]);
save(tmpmat, 'pf_fresh', '-v7.3');
L = load(tmpmat); delete(tmpmat);
for j = 1:ng
    f = pf_fresh{j};
    h = H.h_m(H.geom_key == G.geom_key(j));
    c = [G.n_points(j) - 1; G.spacing_m(j); h(:)];
    if numel(c) ~= numel(f) || c(1) ~= f(1)
        error('itmexp:d34c', 'CSV profile %s has %d points; fresh has %d.', G.geom_key(j), numel(c) - 2, numel(f) - 2);
    end
    V.csv{j} = c;
    V.spacing{j} = [f(1); c(2); f(3:end)];
    V.elevation{j} = [f(1); f(2); c(3:end)];
    t = sscanf(sprintf('%.17g\n', f), '%f');
    if ~isequal(t, f)
        error('itmexp:d34c', '%%.17g text round trip is not bit-identical on %s.', G.geom_key(j));
    end
    V.text17{j} = t;
    if ~isequal(L.pf_fresh{j}, f)
        error('itmexp:d34c', 'MAT round trip is not bit-identical on %s.', G.geom_key(j));
    end
    V.mat{j} = L.pf_fresh{j};
    de = abs(c(3:end) - f(3:end));
    hashes(j, :) = {G.geom_key(j), f(1) + 1, string(num2hex(f(2))), string(num2hex(c(2))), c(2) - f(2), ...
        (c(2) - f(2)) / eps(f(2)), nnz(de > 0), max(de), max(de ./ max(eps(f(3:end)), realmin))};
end
fprintf('Round trips: %%.17g text and MAT are bit-identical to fresh on all %d profiles\n', ng);
fprintf('CSV vs fresh: %d of %d profiles differ in spacing, %d in at least one elevation\n', ...
    nnz(hashes.spacing_diff_m ~= 0), ng, nnz(hashes.n_elev_differ > 0));

% ---- Configurations (as d33_tx_sensitivity_rev1)
ov = '{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}';
setenv('ITMEXP_OVERRIDES', ov); cfg7 = params_exp(); setenv('ITMEXP_OVERRIDES', '');
if cfg7.diffraction ~= "delta_cascaded_isolated"
    error('itmexp:d34c', 'params_exp did not load 707''s switches.');
end

names = ["fresh" "csv" "spacing" "elevation" "text17" "mat"];
[~, ig] = ismember(R.geom_key, G.geom_key);
n = height(R);
Ls = NaN(n, numel(names)); L7 = Ls;
for i = 1:n
    c = cfg7;
    c.row = struct('set', "OT7574", 'siting', "O", 'reversed', false, ...
        'path_id', sprintf("%d_T%d_R%d", R.table(i), R.tx(i), R.rx(i)));
    for k = 1:numel(names)
        pf = V.(names(k)){ig(i)};
        L7(i, k) = itm_p2p_core_exp(R.tx_model_m(i), R.rx_model_m(i), pf, R.f_mhz(i), 50, S.confidence, ...
            S.location, R.climate(i), R.N_0(i), 1, R.epsilon(i), R.sigma(i), S.mdvar, false, [], c);
        Ls(i, k) = itm_p2p_rev1(R.tx_model_m(i), R.rx_model_m(i), pf, R.f_mhz(i), 50, confidence=S.confidence, ...
            climate=R.climate(i), N_0=R.N_0(i), polarization=1, epsilon=R.epsilon(i), sigma=R.sigma(i), ...
            mdvar=S.mdvar, validity="off");
    end
end
dev = max(abs([L7(:, 1) - R.L_707_db; Ls(:, 1) - R.L_stock_db]));
if dev > 1e-6
    error('itmexp:d34c', 'Fresh profiles differ from B32''s stored predictions by %.3g dB; stop (source or runtime drift).', dev);
end
fprintf('Parity: fresh vs B32 stored predictions, largest difference %.2g dB\n', dev);
P = R(:, {'table', 'tx', 'rx', 'geom_key', 'band', 'f_mhz', 'rx_ant_m'});
for k = 1:numel(names)
    P.("stock_" + names(k)) = Ls(:, k);
    P.("m707_" + names(k)) = L7(:, k);
end
for k = 2:numel(names)
    ds = abs(Ls(:, k) - Ls(:, 1)); d7 = abs(L7(:, k) - L7(:, 1));
    fprintf('%-9s vs fresh: stock %3d rows > 1e-6 dB (max %.3g), 707 %3d rows (max %.3g)\n', names(k), ...
        nnz(ds > 1e-6), max(ds), nnz(d7 > 1e-6), max(d7));
end
if options.Smoke
    disp(P(:, {'band', 'rx_ant_m', 'stock_fresh', 'stock_csv', 'stock_spacing', 'stock_elevation'}));
    return
end
out = fullfile(root, 'experiments', 'D34c-profile-roundtrip');
if ~isfolder(out), mkdir(out); end
writetable(hashes, fullfile(out, 'profile_hashes_rev1.csv'));
writetable(P, fullfile(out, 'parity_rev1.csv'));
profiles = struct('geom_key', cellstr(G.geom_key), 'pfl', pf_fresh(:)); %#ok<NASGU>
save(fullfile(out, 'profiles_lossless_rev1.mat'), 'profiles', '-v7');
fprintf('Wrote %s\n', out);
end
