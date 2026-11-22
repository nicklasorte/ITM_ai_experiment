function [T, C] = b07_smoke_rev1(settings)
%B07_SMOKE_REV1 Smoke test of B07 settings against stock ITM, and the clutter term's size. No scores.
%   [T, C] = B07_SMOKE_REV1(settings) runs each row of settings
%   ([diffraction, diffraction_bound, terminal_clutter]) on every Phase 2
%   and long-term link at 50 % time and compares it with stock ITM (the
%   variant at its defaults): share of links changed, largest increase and
%   decrease, and links more than 50 dB above stock. cfg.row is set here
%   from the Phase 2 set and siting columns, as the evaluator change in
%   PR #3 would. C summarizes the P.2108 term on the concealed Phase 2
%   rows by set and frequency. Reads only geometry and siting columns; no
%   measured loss is read and no error against measurements is reported.
P = itm_exp_paths_rev1(); S = settings_rev1();
profiles = load_profiles_rev1(P.root); ids = [profiles.path_id];
cols = ["link_id" "path_id" "f_mhz" "htx_m" "hrx_m" "pol" "climate" "N_0"];
P2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
P2 = P2(:, [cols "set" "siting"]);
LT = readtable(fullfile(P.root, 'data', 'links', 'longterm_links_rev1.csv'), 'TextType', 'string');
LT = LT(:, cols); LT.set = repmat("", height(LT), 1); LT.siting = repmat("", height(LT), 1);
A = [P2; LT];
[~, ip] = ismember(A.path_id, ids);
n = height(A);
    function v = run(cfg)
        v = zeros(n, 1);
        for i = 1:n
            pr = profiles(ip(i));
            c = cfg; c.row = struct('set', A.set(i), 'siting', A.siting(i), 'reversed', false);
            v(i) = itm_p2p_core_exp(A.htx_m(i), A.hrx_m(i), [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)], ...
                A.f_mhz(i), 50, S.confidence, S.location, A.climate(i), A.N_0(i), A.pol(i), ...
                S.epsilon, S.sigma, S.mdvar, false, [], c);
        end
    end
base = run(params_exp());
m = size(settings, 1);
T = table('Size', [m 6], 'VariableTypes', ["string" repmat("double", 1, 5)], ...
    'VariableNames', ["setting" "pct_changed" "max_up_db" "max_down_db" "n_over_50_db" "seconds"]);
for k = 1:m
    cfg = params_exp();
    cfg.diffraction = settings(k, 1); cfg.diffraction_bound = settings(k, 2); cfg.terminal_clutter = settings(k, 3);
    t = tic; v = run(cfg); el = toc(t);
    if ~all(isfinite(v)), error('itmexp:nonfinite', 'Non-finite loss for %s.', join(settings(k, :))); end
    dlt = v - base;
    T(k, :) = {join(settings(k, :), " | "), 100 * mean(abs(dlt) > 0.05), max(dlt), min(dlt), nnz(dlt > 50), el};
end
% Size of the P.2108 term on concealed rows (trees_forest, frequency rule "extend")
cfg = params_exp();
k = find(P2.siting == "C");
h = P2.htx_m(k); h(P2.set(k) == "VA") = P2.hrx_m(k(P2.set(k) == "VA"));
a = arrayfun(@(i) p2108_height_gain_rev1(P2.f_mhz(k(i)), h(i), cfg.terminal_clutter_type, "extend"), (1:numel(k))');
band = discretize(P2.f_mhz(k), [0 500 1500 3000 1e5], 'categorical', ["<0.5 GHz" "0.5-1.5" "1.5-3" ">3 GHz"]);
G = table(P2.set(k), band, h, a, 'VariableNames', ["set" "band" "h_m" "A_db"]);
C = groupsummary(G, ["set" "band"], ["mean" "min" "max"], "A_db");
C.overall_mean_db = repmat(mean(a), height(C), 1);
end
