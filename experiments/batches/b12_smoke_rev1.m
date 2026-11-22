function [G2, GL, nchg] = b12_smoke_rev1()
%B12_SMOKE_REV1 Model-only change of the B12 settings against 707. No scores.
%   [G2, GL, NCHG] = B12_SMOKE_REV1() runs every in-scope Phase 2 row at 50 %
%   time and every in-scope long-term row at the nine evaluator time
%   percentages, with 707's settings and with each B12 setting:
%     1201  707 + los_phase = "curved_specular"   (P.530-19 eqs. 121-126)
%     1202  707 + time_variability = "two_leg"    (NBS TN101 sec. 10 two-leg idea)
%   G2: Phase 2 mean change (1201 - 707) by set and ITM mode.
%   GL: long-term mean, 5th and 95th percentile change by time percentage.
%   NCHG: number of long-term links whose loss changed by more than 0.01 dB.
%   Reads only geometry, frequency and radio-climate columns; no measured
%   loss is read and no error against measurements is reported.
P = itm_exp_paths_rev1(); S = settings_rev1();
profiles = load_profiles_rev1(P.root); ids = [profiles.path_id];
base = struct('diffraction', "delta_cascaded_isolated", 'diffraction_bound', "itm_troposcatter_line", ...
    'terminal_clutter', "p2108_height_gain", 'terminal_clutter_base', "clutter_height", ...
    'terminal_clutter_frange', "hold3");
c0 = params_exp(); for f = string(fieldnames(base))', c0.(f) = base.(f); end
c1 = c0; c1.los_phase = "curved_specular";
c2 = c0; c2.time_variability = "two_leg";

cols2 = ["link_id" "path_id" "set" "siting" "f_mhz" "htx_m" "hrx_m" "pol" "climate" "N_0" "itm_error"];
T2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
T2 = T2(in_scope(T2), cols2);
[a0, m0] = run(T2, 50, c0, true); a1 = run(T2, 50, c1, true);
G2 = groupsummary(table(T2.set, m0, a1 - a0, abs(a1 - a0) > 0.01, 'VariableNames', ["set" "mode" "d1201" "changed"]), ...
    ["set" "mode"], "mean", ["d1201" "changed"]);

colsL = ["link_id" "path_id" "f_mhz" "htx_m" "hrx_m" "pol" "climate" "N_0" "itm_error"];
TL = readtable(fullfile(P.root, 'data', 'links', 'longterm_links_rev1.csv'), 'TextType', 'string');
TL = TL(in_scope(TL), colsL);
b0 = run(TL, S.p_all, c0, false); b1 = run(TL, S.p_all, c1, false); b2 = run(TL, S.p_all, c2, false);
d1 = b1 - b0; d2 = b2 - b0;
GL = table(S.p_all(:), mean(d1)', prctile(d1, 5)', prctile(d1, 95)', mean(d2)', prctile(d2, 5)', prctile(d2, 95)', ...
    'VariableNames', ["p" "d1201_mean" "d1201_p5" "d1201_p95" "d1202_mean" "d1202_p5" "d1202_p95"]);
nchg = [nnz(any(abs(d1) > 0.01, 2)) nnz(any(abs(d2) > 0.01, 2)) height(TL)];
disp(G2); disp(GL); fprintf('long-term links changed: 1201 %d, 1202 %d, of %d\n', nchg);

    function [L, mode] = run(T, p, cfg, meta)
        L = NaN(height(T), numel(p)); mode = zeros(height(T), 1);
        [~, ip] = ismember(T.path_id, ids);
        if any(ip == 0), error('itmexp:profile', 'Missing terrain profile.'); end
        for i = 1:height(T)
            pr = profiles(ip(i)); c = cfg;
            if meta
                c.row = struct('set', string(T.set(i)), 'siting', string(T.siting(i)), 'reversed', false, 'path_id', string(T.path_id(i)));
            else
                c.row = struct('set', "", 'siting', "", 'reversed', false, 'path_id', string(T.path_id(i)));
            end
            [a, info] = itm_p2p_core_exp(T.htx_m(i), T.hrx_m(i), [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)], ...
                T.f_mhz(i), p, S.confidence, S.location, T.climate(i), T.N_0(i), T.pol(i), ...
                S.epsilon, S.sigma, S.mdvar, true, [], c);   % 14th argument true returns info
            if ~all(isfinite(a)), error('itmexp:nonfinite', 'Non-finite loss on %s.', T.link_id(i)); end
            L(i, :) = a(:)'; mode(i) = info.mode;
        end
    end
end

function ok = in_scope(T)
% Same rule as baseline_ok in eval/run_eval_rev1.m.
if isnumeric(T.itm_error), ok = true(height(T), 1); else, ok = ismissing(T.itm_error) | T.itm_error == ""; end
end
