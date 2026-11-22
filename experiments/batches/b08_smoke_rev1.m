function [T, G] = b08_smoke_rev1()
%B08_SMOKE_REV1 Model-only change from the B07 clutter term (701) to the B08 term, on concealed rows. No scores.
%   [T, G] = B08_SMOKE_REV1() runs the concealed ("C") Phase 2 rows with
%   three settings on the 604 base (delta_cascaded_isolated with the
%   itm_troposcatter_line bound) and on the 705 base (delta_deygout_isolated,
%   bound):
%     b07   P.2108 term added to loss at the actual antenna height, "extend" (701, 702)
%     b08   loss computed at max(h, R), then the term, "hold3"              (707, 708)
%     b08x  as b08 but "extend"                                              (709)
%   T: per-row losses (dB). G: mean change from b07 by base, set, profile
%   obstruction class (the "obstructed" flag of experiments/batches/b07_split_rev1.py
%   is not used here; the class is whether ITM's propagation mode is line of sight),
%   and frequency band. Reads only geometry and siting columns; no measured
%   loss is read and no error against measurements is reported.
P = itm_exp_paths_rev1(); S = settings_rev1();
profiles = load_profiles_rev1(P.root); ids = [profiles.path_id];
L = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
L = L(L.siting == "C", ["link_id" "path_id" "set" "siting" "f_mhz" "htx_m" "hrx_m" "pol" "climate" "N_0"]);
[~, ip] = ismember(L.path_id, ids);
if any(ip == 0), error('itmexp:profile', 'Missing terrain profile for a concealed row.'); end
n = height(L);
    function [v, mode] = run(cfg)
        v = zeros(n, 1); mode = zeros(n, 1);
        for i = 1:n
            pr = profiles(ip(i));
            c = cfg; c.row = struct('set', L.set(i), 'siting', L.siting(i), 'reversed', false);
            [v(i), info] = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)], ...
                L.f_mhz(i), 50, S.confidence, S.location, L.climate(i), L.N_0(i), L.pol(i), ...
                S.epsilon, S.sigma, S.mdvar, true, [], c);
            mode(i) = info.mode;
        end
        if ~all(isfinite(v)), error('itmexp:nonfinite', 'Non-finite loss.'); end
    end
T = L(:, ["link_id" "set" "f_mhz" "htx_m" "hrx_m"]);
bases = ["delta_cascaded_isolated" "delta_deygout_isolated"];
for b = 1:2
    c = params_exp(); c.diffraction = bases(b); c.diffraction_bound = "itm_troposcatter_line";
    c.terminal_clutter = "p2108_height_gain";
    c.terminal_clutter_base = "actual"; c.terminal_clutter_frange = "extend";
    [T.("b07_" + b), T.("mode_" + b)] = run(c);
    c.terminal_clutter_base = "clutter_height"; c.terminal_clutter_frange = "hold3";
    T.("b08_" + b) = run(c);
    c.terminal_clutter_frange = "extend";
    T.("b08x_" + b) = run(c);
end
band = discretize(T.f_mhz, [0 500 1500 3000 1e5], 'categorical', ["<0.5 GHz" "0.5-1.5" "1.5-3" ">3 GHz"]);
los = T.mode_1 == 1;
G = table(T.set, band, los, T.b08_1 - T.b07_1, T.b08x_1 - T.b07_1, T.b08_2 - T.b07_2, ...
    'VariableNames', ["set" "band" "los" "d707_vs_701" "d709_vs_701" "d708_vs_702"]);
G = groupsummary(G, ["set" "los" "band"], "mean", ["d707_vs_701" "d709_vs_701" "d708_vs_702"]);
end
