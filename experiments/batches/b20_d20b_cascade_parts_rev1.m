function T = b20_d20b_cascade_parts_rev1(out_csv)
%B20_D20B_CASCADE_PARTS_REV1 D20b (B20): 707's delta and cascade terms on every row at 50 %.
%   T = B20_D20B_CASCADE_PARTS_REV1(out_csv) runs 707 with info output on every
%   in-scope Phase 2 row and every long-term row at 50 %, checks each loss
%   against 707's stored prediction to 1e-9 dB (stops otherwise), and writes
%   one row per link with: A_ref, the bound flag, L_ba, L_bs, A_s, and the
%   P.526-11 eq. (50a) terms (J_p, T, L_t, L_r, C) of both cascade calls.
%   Model outputs only; no measured loss is read here (the analysis script
%   b20_d20b_analysis_rev1.py joins the residuals).
P = itm_exp_paths_rev1(); St = settings_rev1();
profiles = load_profiles_rev1(P.root); ids = string({profiles.path_id});
setenv('ITMEXP_OVERRIDES', '');
c = params_exp();
c.diffraction = "delta_cascaded_isolated"; c.diffraction_bound = "itm_troposcatter_line";
c.terminal_clutter = "p2108_height_gain"; c.terminal_clutter_base = "clutter_height";
c.terminal_clutter_frange = "hold3";
run = "707-cascaded-isolated-clutter-at-r";
parts = {};
for ds = ["phase2" "longterm"]
    L = readtable(fullfile(P.root, 'data', 'links', ds + "_links_rev1.csv"), 'TextType', 'string');
    E = readtable(fullfile(P.root, 'experiments', run, "predictions_" + ds + ".csv"), 'TextType', 'string');
    L = L(ismember(L.link_id, E.link_id), :);
    [~, je] = ismember(L.link_id, E.link_id);
    stored = E.var_lb_50(je);
    meta = all(ismember({'set', 'siting'}, L.Properties.VariableNames));
    [~, ip] = ismember(L.path_id, ids);
    if any(ip == 0), error('itmexp:d20b', 'Profiles missing for %d rows.', nnz(ip == 0)); end
    for i = 1:height(L)
        pr = profiles(ip(i)); pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
        ci = c;
        if meta
            ci.row = struct('set', string(L.set(i)), 'siting', string(L.siting(i)), 'reversed', false, 'path_id', L.path_id(i));
        else
            ci.row = struct('set', "", 'siting', "", 'reversed', false, 'path_id', L.path_id(i));
        end
        [a, info] = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, St.confidence, St.location, ...
            L.climate(i), L.N_0(i), L.pol(i), St.epsilon, St.sigma, St.mdvar, true, [], ci);
        if abs(a - stored(i)) > 1e-9
            error('itmexp:d20b', '%s: %.6g dB here, %.6g dB stored.', L.link_id(i), a, stored(i));
        end
        q = info.delta_parts; tb = q.terms_ba; ts = q.terms_bs;
        parts(end + 1, :) = {ds, L.link_id(i), info.mode, info.A_ref_db, q.bound_binds, q.L_ba_db, q.L_bs_db, q.A_s_db, ...
            tb.J_p, tb.T, tb.L_t, tb.L_r, tb.C, ts.J_p, ts.T, ts.L_t, ts.L_r, ts.C}; %#ok<AGROW>
    end
    fprintf('%s: %d rows checked against %s\n', ds, height(L), run);
end
T = cell2table(parts, 'VariableNames', {'dataset', 'link_id', 'itm_mode', 'A_ref_db', 'bound_binds', 'L_ba_db', 'L_bs_db', ...
    'A_s_db', 'ba_J_p', 'ba_T', 'ba_L_t', 'ba_L_r', 'ba_C', 'bs_J_p', 'bs_T', 'bs_L_t', 'bs_L_r', 'bs_C'});
writetable(T, out_csv);
end
