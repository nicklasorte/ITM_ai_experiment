function S = b13_smoke_rev1(cand_json, out_csv)
%B13_SMOKE_REV1 Model-only change of one candidate against 707 on every row (B13).
%   S = B13_SMOKE_REV1(cand_json, out_csv) runs every in-scope Phase 2 row at
%   50 % time and every long-term row at the nine evaluator percentages,
%   with 707's settings and with 707's settings plus the JSON object
%   cand_json (extra switches), and writes the per-row change (candidate
%   minus 707) to out_csv in the hm_screen_rev1.py --delta format:
%   link_id, d_50, d_0_01 ... d_99_99 (NaN for Phase 2 rows).
%   It checks that its 707 predictions match the stored 707 run to 1e-9 dB.
%   Reads geometry, frequency and climate columns only; no measured loss.
%   Returns a struct of summary tables (by set and mode, by percentage).
P = itm_exp_paths_rev1(); St = settings_rev1();
profiles = load_profiles_rev1(P.root); ids = string({profiles.path_id});
base = ['{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line",' ...
    '"terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height",' ...
    '"terminal_clutter_frange":"hold3"}'];
setenv('ITMEXP_OVERRIDES', base); c0 = params_exp();
extra = jsondecode(char(cand_json)); c1 = c0;
for f = string(fieldnames(extra))', c1.(f) = string(extra.(f)); end
setenv('ITMEXP_OVERRIDES', '');
E2 = readtable(fullfile(P.root, 'experiments', '707-cascaded-isolated-clutter-at-r', 'predictions_phase2.csv'), 'TextType', 'string');
EL = readtable(fullfile(P.root, 'experiments', '707-cascaded-isolated-clutter-at-r', 'predictions_longterm.csv'), 'TextType', 'string');
T2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
TL = readtable(fullfile(P.root, 'data', 'links', 'longterm_links_rev1.csv'), 'TextType', 'string');
T2 = T2(ismember(T2.link_id, E2.link_id), :); TL = TL(ismember(TL.link_id, EL.link_id), :);
[A0, m0] = run(T2, 50, c0, true); A1 = run(T2, 50, c1, true);
[B0, b0m] = run(TL, St.p_all, c0, false); B1 = run(TL, St.p_all, c1, false);
[~, j] = ismember(T2.link_id, E2.link_id); e2 = max(abs(A0 - E2.var_lb_50(j)));
[~, j] = ismember(TL.link_id, EL.link_id); V = EL{j, "var_lb_" + St.p_tags}; eL = max(abs(B0 - V), [], 'all', 'omitnan');
if e2 > 1e-9 || eL > 1e-9
    error('itmexp:smoke', '707 predictions differ from the stored run (%.2g, %.2g dB): wrong settings.', e2, eL);
end
D = table([T2.link_id; TL.link_id], 'VariableNames', {'link_id'});
D.d_50 = [A1 - A0; B1(:, St.p_tags == "50") - B0(:, St.p_tags == "50")];
for k = find(St.p_tags ~= "50")
    D.("d_" + St.p_tags(k)) = [NaN(height(T2), 1); B1(:, k) - B0(:, k)];
end
writetable(D, out_csv);
d2 = A1 - A0; dL = B1 - B0;
S.p2 = groupsummary(table(T2.set, m0, d2, abs(d2) > 0.01, 'VariableNames', ["set" "mode" "d" "changed"]), ["set" "mode"], ["mean" "max" "min"], ["d" "changed"]);
S.lt = table(St.p_all(:), mean(dL)', min(dL)', max(dL)', sum(abs(dL) > 0.01)', 'VariableNames', ["p" "mean" "min" "max" "n_changed"]);
S.lt_mode = groupsummary(table(b0m, dL(:, St.p_tags == "50"), 'VariableNames', ["mode" "d50"]), "mode", ["mean" "max" "min"], "d50");
S.check = [e2 eL];
disp(S.p2); disp(S.lt); disp(S.lt_mode);

    function [L, mode] = run(T, p, cfg, meta)
        L = NaN(height(T), numel(p)); mode = zeros(height(T), 1);
        [~, ip] = ismember(T.path_id, ids);
        if any(ip == 0), error('itmexp:profile', 'Missing terrain profile.'); end
        for i = 1:height(T)
            pr = profiles(ip(i)); c = cfg;
            if meta
                c.row = struct('set', T.set(i), 'siting', T.siting(i), 'reversed', false, 'path_id', T.path_id(i));
            else
                c.row = struct('set', "", 'siting', "", 'reversed', false, 'path_id', T.path_id(i));
            end
            [a, info] = itm_p2p_core_exp(T.htx_m(i), T.hrx_m(i), [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)], ...
                T.f_mhz(i), p, St.confidence, St.location, T.climate(i), T.N_0(i), T.pol(i), ...
                St.epsilon, St.sigma, St.mdvar, true, [], c);
            if ~all(isfinite(a)), error('itmexp:nonfinite', 'Non-finite loss on %s.', T.link_id(i)); end
            L(i, :) = a(:)'; mode(i) = info.mode;
        end
    end
end
