function T = b06_smoke_rev1(settings)
%B06_SMOKE_REV1 Smoke test of settings against stock ITM on the long-term paths. No scores.
%   T = B06_SMOKE_REV1(settings) runs each row of settings ([diffraction,
%   diffraction_region, diffraction_bound]) on every long-term link at 50 %
%   time and compares the variant with the variant at its defaults (stock
%   ITM): share of links changed, the largest increase and decrease, and
%   how many links are more than 50 dB above stock (the B05 experiment 501
%   failure). It reads only geometry and system columns; it reads no
%   measured loss and reports no error against measurements.
P = itm_exp_paths_rev1(); S = settings_rev1();
profiles = load_profiles_rev1(P.root); ids = [profiles.path_id];
LT = readtable(fullfile(P.root, 'data', 'links', 'longterm_links_rev1.csv'), 'TextType', 'string');
LT = LT(:, ["link_id" "path_id" "d_km" "f_mhz" "htx_m" "hrx_m" "pol" "climate" "N_0"]);
[~, ip] = ismember(LT.path_id, ids);
n = height(LT);
run = @(cfg) arrayfun(@(i) itm_p2p_core_exp(LT.htx_m(i), LT.hrx_m(i), ...
    [numel(profiles(ip(i)).h_m) - 1; profiles(ip(i)).spacing_m; profiles(ip(i)).h_m(:)], LT.f_mhz(i), 50, ...
    S.confidence, S.location, LT.climate(i), LT.N_0(i), LT.pol(i), S.epsilon, S.sigma, S.mdvar, false, [], cfg), (1:n)');
base = run(params_exp());
m = size(settings, 1);
T = table('Size', [m 7], 'VariableTypes', ["string" repmat("double", 1, 6)], ...
    'VariableNames', ["setting" "pct_changed" "max_up_db" "max_down_db" "n_over_50_db" "n_over_50_db_beyond_300km" "seconds"]);
for k = 1:m
    cfg = params_exp();
    cfg.diffraction = settings(k, 1); cfg.diffraction_region = settings(k, 2); cfg.diffraction_bound = settings(k, 3);
    t = tic; v = run(cfg); el = toc(t);
    if ~all(isfinite(v)), error('itmexp:nonfinite', 'Non-finite loss for %s.', settings(k, 1)); end
    dlt = v - base;
    T(k, :) = {join(settings(k, :), " | "), 100 * mean(abs(dlt) > 0.05), max(dlt), min(dlt), nnz(dlt > 50), nnz(dlt > 50 & LT.d_km > 300), el};
end
end
