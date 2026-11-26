function T = d32_run_models_rev1(root, options)
%D32_RUN_MODELS_REV1 Terrain profiles and 50 % predictions of 707 and stock ITM on the OT 75-74 paths (B32, diagnostic).
%   T = D32_RUN_MODELS_REV1(root) reads the B31 tables and terminal
%   positions in experiments/D31-ot7574/, builds one terrain profile per
%   transmitter-receiver pair with itm_terrain_profile_rev1 (matlab_itm,
%   30 m spacing, default source, transmitter first), and predicts the
%   50 % basic transmission loss of every table row at 50 % with
%     - 707: itm_p2p_core_exp with 707's switches (ITMEXP_OVERRIDES as in
%       b28_calibrate_rev1.m) and cfg.row set as B32.md section 2 says;
%     - stock ITM: itm_p2p_rev1 from the pinned matlab_itm;
%     - a parity column: itm_p2p_core_exp at params_exp() defaults, which
%       must equal stock ITM (the variant's bit-identity contract).
%   It writes experiments/D32-ot7574-heights/predictions_rev1.csv,
%   paths_rev1.csv and profiles_rev1.csv.
%
%   T = D32_RUN_MODELS_REV1(root, Smoke=true) runs one pair per area
%   (Eglin, Graham, Graham R5, Hunter Liggett) and writes nothing.
%
%   Inputs are fixed by experiments/batches/B32.md sections 2 and 3a (heights
%   below 0.5 m are modeled at 0.5 m). Fails loud on
%   an unknown terminal, a profile whose length differs from the
%   tabulated distance by more than 2 %, a non-finite loss, or a parity
%   mismatch.
arguments
    root (1,1) string
    options.Smoke (1,1) logical = false
end
P = itm_exp_paths_rev1();
S = settings_rev1();
d31 = fullfile(root, 'experiments', 'D31-ot7574');
tab = readtable(fullfile(d31, 'ot7574_tables_rev1.csv'), 'TextType', 'string');
tab = tab(tab.pct == 50, :);
ter = readtable(fullfile(d31, 'terminals_all_rev1.csv'), 'TextType', 'string');
if height(tab) ~= 210 * 6
    error('itmexp:d32', 'Expected 1,260 rows at 50 %% (210 paths x 2 bands x 3 heights), found %d.', height(tab));
end

% ---- Terminal keys (B31: Hunter Liggett T7a for R1 and R2, T7b for R3 and R4)
n = height(tab);
akey = strings(n, 1); txn = strings(n, 1); rxn = "R" + string(tab.rx);
for i = 1:n
    a = tab.area(i);
    if startsWith(a, "Eglin")
        akey(i) = "Eglin";
    elseif startsWith(a, "Graham")
        akey(i) = "Graham";
        if tab.rx(i) == 5, akey(i) = "Graham_R5"; end
    elseif startsWith(a, "Hunter")
        akey(i) = "Hunter";
    else
        error('itmexp:d32', 'Unknown area "%s" in table %d.', a, tab.table(i));
    end
    txn(i) = "T" + string(tab.tx(i));
    if akey(i) == "Hunter" && tab.tx(i) == 7
        if tab.rx(i) <= 2, txn(i) = "T7a"; else, txn(i) = "T7b"; end
    end
end
tab.geom_key = akey + "|" + txn + "|" + rxn;
tkey = ter.area + "|" + ter.terminal;
[okT, iT] = ismember(akey + "|" + txn, tkey);
[okR, iR] = ismember(akey + "|" + rxn, tkey);
if ~all(okT) || ~all(okR)
    bad = unique([akey(~okT) + "|" + txn(~okT); akey(~okR) + "|" + rxn(~okR)]);
    error('itmexp:d32', 'No position for terminal(s): %s', strjoin(bad, ', '));
end
tab.tx_lat = ter.lat(iT); tab.tx_lon = ter.lon(iT);
tab.rx_lat = ter.lat(iR); tab.rx_lon = ter.lon(iR);

% ---- Unique pairs; smoke keeps the first pair of each area
[gk, ig] = unique(tab.geom_key, 'stable');
if options.Smoke
    ga = extractBefore(gk, "|");
    [~, keep] = unique(ga, 'stable');
    gk = gk(keep);
    tab = tab(ismember(tab.geom_key, gk), :);
    [~, ig] = ismember(gk, tab.geom_key);   % first row of each kept pair
end
ng = numel(gk);
fprintf('B32: %d pairs, %d rows\n', ng, height(tab));

% ---- Terrain profiles, one pass over the tiles
t0 = tic;
[pfls, pinfo] = itm_terrain_profile_rev1(tab.tx_lat(ig), tab.tx_lon(ig), tab.rx_lat(ig), tab.rx_lon(ig), ...
    spacing_m=S.profile_spacing_m);
if ~iscell(pfls), pfls = {pfls}; end
fprintf('Profiles: %.1f s\n', toc(t0));
d_prof = zeros(ng, 1); clim = zeros(ng, 1); n0 = zeros(ng, 1);
for j = 1:ng
    pf = pfls{j};
    if any(~isfinite(pf))
        error('itmexp:d32', 'Profile %s has non-finite elevations.', gk(j));
    end
    d_prof(j) = pf(1) * pf(2) / 1000;
    mid = pinfo(j).midpoint_deg;
    % As data/build_links_rev1.m: climate at the midpoint, falling back to
    % the terminals when the midpoint is over water (climate 7)
    clim(j) = itm_radio_climate_rev1(mid(1), mid(2));
    if clim(j) == 7
        i = ig(j);
        clim(j) = min(itm_radio_climate_rev1(tab.tx_lat(i), tab.tx_lon(i)), ...
            itm_radio_climate_rev1(tab.rx_lat(i), tab.rx_lon(i)));
    end
    n0(j) = itm_surface_refractivity_rev1(mid(1), mid(2));
end
[~, ip] = ismember(tab.geom_key, gk);
tab.dist_prof_km = d_prof(ip);
rel = abs(tab.dist_prof_km - tab.dist_km) ./ tab.dist_km;
if any(rel > 0.02)
    k = find(rel > 0.02, 1);
    error('itmexp:d32', ['Check 2 failed: profile %s is %.3f km, table %d gives %.3f km (%.1f %%). ', ...
        'Hand back (B32.md section 5).'], tab.geom_key(k), tab.dist_prof_km(k), tab.table(k), tab.dist_km(k), 100 * rel(k));
end
fprintf('Check 2: largest profile vs tabulated distance difference %.2f %%\n', 100 * max(rel));
tab.climate = clim(ip); tab.N_0 = n0(ip);

% ---- Ground constants (B32.md section 2 table)
tab.epsilon = NaN(height(tab), 1); tab.sigma = NaN(height(tab), 1);
ae = extractBefore(tab.geom_key, "|");
tab.epsilon(ae == "Eglin") = 5;   tab.sigma(ae == "Eglin") = 0.015;     % Report 5.1; sigma planner midpoint
tab.epsilon(startsWith(ae, "Graham")) = 5; tab.sigma(startsWith(ae, "Graham")) = 0.010;   % Report 6.1
tab.epsilon(ae == "Hunter") = 10; tab.sigma(ae == "Hunter") = 0.060;    % Report section 7
if any(isnan(tab.epsilon))
    error('itmexp:d32', 'Rows without ground constants.');
end
pol = 1;            % vertical: quarter-wave monopoles at both ends (Report Appendix A)

% ---- Configurations: defaults (parity) and 707
setenv('ITMEXP_OVERRIDES', '');
cfg0 = params_exp();
% 707's switches, copied from experiments/707r-rescore-screen36/metrics.json (cfg.overrides)
ov = '{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}';
setenv('ITMEXP_OVERRIDES', ov);
cfg7 = params_exp();
setenv('ITMEXP_OVERRIDES', '');
want = struct('diffraction', "delta_cascaded_isolated", 'diffraction_bound', "itm_troposcatter_line", ...
    'terminal_clutter', "p2108_height_gain", 'terminal_clutter_base', "clutter_height", ...
    'terminal_clutter_frange', "hold3", 'smooth_heights', "p452_diffraction", 'smooth_reference', "itm", ...
    'path_vegetation', "none");
for f = string(fieldnames(want))'
    if cfg7.(f) ~= want.(f)
        error('itmexp:d32', 'params_exp().%s is "%s", expected "%s" for 707.', f, cfg7.(f), want.(f));
    end
end

% ---- Predictions
m = height(tab);
L7 = NaN(m, 1); Ls = NaN(m, 1); L0 = NaN(m, 1); mode7 = NaN(m, 1);
t0 = tic;
% B32.md section 3a: ITM v1.4 rejects heights below 0.5 m (NTIA
% ValidateInputs.cpp, errors 1000 and 1001), so both models use 0.5 m where
% the report gives 0.35 m.
h_min = 0.5;
tab.tx_model_m = max(tab.tx_ant_m, h_min);
tab.rx_model_m = max(tab.rx_ant_m, h_min);
for i = 1:m
    pf = pfls{ip(i)};
    htx = tab.tx_model_m(i); hrx = tab.rx_model_m(i); f = tab.f_mhz(i);
    c = cfg7;
    c.row = struct('set', "OT7574", 'siting', "O", 'reversed', false, ...
        'path_id', sprintf("%d_T%d_R%d", tab.table(i), tab.tx(i), tab.rx(i)));
    [a, ~, ~, ~, mc] = itm_p2p_core_exp(htx, hrx, pf, f, 50, S.confidence, S.location, ...
        tab.climate(i), tab.N_0(i), pol, tab.epsilon(i), tab.sigma(i), S.mdvar, false, [], c);
    L7(i) = a; mode7(i) = mc;
    c0 = cfg0;
    c0.row = c.row;
    L0(i) = itm_p2p_core_exp(htx, hrx, pf, f, 50, S.confidence, S.location, ...
        tab.climate(i), tab.N_0(i), pol, tab.epsilon(i), tab.sigma(i), S.mdvar, false, [], c0);
    Ls(i) = itm_p2p_rev1(htx, hrx, pf, f, 50, confidence=S.confidence, climate=tab.climate(i), ...
        N_0=tab.N_0(i), polarization=pol, epsilon=tab.epsilon(i), sigma=tab.sigma(i), mdvar=S.mdvar, ...
        validity="off");
end
fprintf('Predictions: %d rows x 3 runs, %.1f s\n', m, toc(t0));
if any(~isfinite([L7; Ls; L0])) || ~isreal([L7; Ls; L0])
    error('itmexp:d32', 'Non-finite or complex loss.');
end
par = max(abs(L0 - Ls));
if par > 1e-9
    error('itmexp:d32', 'Parity failed: core at defaults differs from stock ITM by %.3g dB.', par);
end
fprintf('Parity: core at defaults vs stock ITM, largest difference %.2g dB\n', par);
tab.L_707_db = L7; tab.L_stock_db = Ls; tab.mode_707 = mode7;
fprintf('707 minus stock: mean %+.2f dB, range %+.2f to %+.2f dB; identical (<0.01 dB) %d of %d rows\n', ...
    mean(L7 - Ls), min(L7 - Ls), max(L7 - Ls), nnz(abs(L7 - Ls) < 0.01), m);

T = tab(:, {'table', 'area', 'period', 'tx', 'rx', 'geom_key', 'dist_km', 'dist_prof_km', 'band', 'f_mhz', ...
    'tx_ant_m', 'rx_ant_m', 'tx_model_m', 'rx_model_m', 'loss_db', 'lower_bound', 'questionable', 'missing', 'uncertain', ...
    'climate', 'N_0', 'epsilon', 'sigma', 'L_707_db', 'L_stock_db', 'mode_707'});
if options.Smoke
    return
end
out = fullfile(root, 'experiments', 'D32-ot7574-heights');
if ~isfolder(out), mkdir(out); end
writetable(T, fullfile(out, 'predictions_rev1.csv'));
G = table(gk, d_prof, clim, n0, 'VariableNames', {'geom_key', 'dist_prof_km', 'climate', 'N_0'});
G.n_points = cellfun(@(p) p(1) + 1, pfls(:)); G.spacing_m = cellfun(@(p) p(2), pfls(:));
writetable(G, fullfile(out, 'paths_rev1.csv'));
% Profiles, long format (geom_key, i, h_m); i = 0 at the transmitter
key = strings(0, 1); ii = zeros(0, 1); hh = zeros(0, 1);
for j = 1:ng
    h = pfls{j}(3:end);
    key = [key; repmat(gk(j), numel(h), 1)]; %#ok<AGROW>
    ii = [ii; (0:numel(h) - 1)']; %#ok<AGROW>
    hh = [hh; h(:)]; %#ok<AGROW>
end
writetable(table(key, ii, hh, 'VariableNames', {'geom_key', 'i', 'h_m'}), fullfile(out, 'profiles_rev1.csv'));
fprintf('Wrote %s\n', out);
end
