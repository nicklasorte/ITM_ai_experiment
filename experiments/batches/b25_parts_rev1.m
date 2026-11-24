function S = b25_parts_rev1(out_dir)
%B25_PARTS_REV1 B25 D25a/D25b: delta parts with the spherical-earth reference (model only).
%   S = B25_PARTS_REV1(out_dir) runs every in-scope Phase 2 row at 50 % with
%   707's settings plus cfg.smooth_reference = "p452_spherical", and records
%   the loss and the delta parts (A_s is then L_dsph, ITU-R P.452-18 section
%   4.2.2). It joins B23's 707 parts (experiments/D23m-metadata-audit/
%   parent_parts_rev1.csv) and writes parts_rev1.csv. Then D25b: the
%   R1-005-T5_O row at 230 MHz with the fixed antenna at 1 to 30 m, for 707 and
%   the hybrid (sweep_rev1.csv), and a kernel reversal check on 2,000 random
%   cases. No measured loss is read. Development data only.
P = itm_exp_paths_rev1(); St = settings_rev1(); root = char(P.root);
setenv('ITMEXP_OVERRIDES', '');
c0 = params_exp();
c0.diffraction = "delta_cascaded_isolated"; c0.diffraction_bound = "itm_troposcatter_line";
c0.terminal_clutter = "p2108_height_gain"; c0.terminal_clutter_base = "clutter_height";
c0.terminal_clutter_frange = "hold3";
c1 = c0; c1.smooth_reference = "p452_spherical";

I = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
I = I(I.dataset == "phase2", :);
B = readtable(fullfile(root, 'experiments', 'D23m-metadata-audit', 'parent_parts_rev1.csv'), 'TextType', 'string');
L = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
[tf, jb] = ismember(L.link_id, B.link_id); L = L(tf, :); B = B(jb(tf), :);
n = height(L); prof = containers.Map();
V = NaN(n, 6);
for i = 1:n
    pfl = get_pfl(L.path_id(i));
    [a, info] = core(L(i, :), L.hrx_m(i), pfl, c1);
    q = info.delta_parts;
    V(i, :) = [a, info.A_ref_db, q.A_s_db, q.L_bs_db, q.bound_binds, info.mode];
end
T = table(L.link_id, L.set, L.siting, L.f_mhz, B.loss_707_db, B.A_s_db, B.L_bs_db, B.L_ba_db, B.bound_binds, B.itm_mode, ...
    V(:, 1), V(:, 2), V(:, 3), V(:, 4), V(:, 5), V(:, 6), 'VariableNames', ...
    {'link_id', 'set', 'siting', 'f_mhz', 'loss_707', 'A_s_itm', 'L_bs', 'L_ba', 'bound_707', 'mode_707', ...
    'loss_hyb', 'A_ref_hyb', 'L_dsph', 'L_bs_hyb', 'bound_hyb', 'mode_hyb'});
if max(abs(T.L_bs - T.L_bs_hyb)) > 1e-9, error('itmexp:b25', 'L_bs changed: the switch touched more than A_s.'); end
if ~isfolder(out_dir), mkdir(out_dir); end
writetable(T, fullfile(out_dir, 'parts_rev1.csv'));

% D25b: height sweep on the R1 inversion row (B20 D20a)
k = find(L.path_id == "P2_R1_R1-005-T5_O" & L.f_mhz == 230, 1);
if isempty(k), error('itmexp:b25', 'R1-005-T5_O at 230 MHz not found.'); end
pfl = get_pfl(L.path_id(k)); hh = (1:30)'; W = NaN(30, 4);
for q = 1:30
    [a0, i0] = core(L(k, :), hh(q), pfl, c0); [a1, i1] = core(L(k, :), hh(q), pfl, c1);
    W(q, :) = [a0, i0.delta_parts.A_s_db, a1, i1.delta_parts.A_s_db];
end
Sw = table(hh, W(:, 1), W(:, 2), W(:, 3), W(:, 4), 'VariableNames', {'h_fixed_m', 'loss_707', 'A_s_itm', 'loss_hyb', 'L_dsph'});
writetable(Sw, fullfile(out_dir, 'sweep_rev1.csv'));

% Reversal: L_dsph with the ends swapped
rng(20261124); r = zeros(2000, 1);
for q = 1:2000
    d = 0.5 + 299.5 * rand^2; ht = 1 + 499 * rand^2; hr = 1 + 499 * rand^2;
    f = 0.03 * 10^(log10(20 / 0.03) * rand); ae = 6000 + 6000 * rand; pol = randi([0 1]);
    r(q) = spherical_earth_diffraction_rev1(d, ht, hr, ae, f, pol) - spherical_earth_diffraction_rev1(d, hr, ht, ae, f, pol);
end
S = struct('rows', n, 'max_step_rise_707', max(diff(W(:, 1))), 'max_step_rise_hyb', max(diff(W(:, 3))), ...
    'total_707', W(end, 1) - W(1, 1), 'total_hyb', W(end, 3) - W(1, 3), ...
    'max_step_rise_A_s', max(diff(W(:, 2))), 'max_step_rise_L_dsph', max(diff(W(:, 4))), 'reversal_max_db', max(abs(r)));
writelines(jsonencode(S, 'PrettyPrint', true), fullfile(out_dir, 'checks_rev1.json'));
disp(S)

    function pfl = get_pfl(pid)
        if ~isKey(prof, char(pid))
            kk = find(I.path_id == pid, 1);
            f = fullfile(root, 'data', 'profiles', 'phase2', pid + ".csv");
            h = readmatrix(f, 'NumHeaderLines', 1);
            prof(char(pid)) = [numel(h) - 1; I.spacing_m(kk); h(:)];
        end
        pfl = prof(char(pid));
    end

    function [a, info] = core(row, hrx, pfl, c)
        c.row = struct('set', string(row.set), 'siting', string(row.siting), 'reversed', false, 'path_id', row.path_id);
        [a, info] = itm_p2p_core_exp(row.htx_m, hrx, pfl, row.f_mhz, 50, St.confidence, St.location, ...
            row.climate, row.N_0, row.pol, St.epsilon, St.sigma, St.mdvar, true, [], c);
        if ~isfinite(a) || ~isreal(a), error('itmexp:b25', 'Non-finite output on %s.', row.link_id); end
    end
end
