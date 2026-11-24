function T = b23_clutter_factorial_rev1(out_dir, pairs_csv)
%B23_CLUTTER_FACTORIAL_REV1 D23b: height-substitution / additive-clutter factorial on every C row of the D20c pairs.
%   T = B23_CLUTTER_FACTORIAL_REV1(out_dir, pairs_csv) runs, for each concealed (C) row in
%   the C/O pair registry, five calls of itm_p2p_core_exp using only existing cfg switches:
%     G00  height h,      terminal_clutter none,     base actual
%     G10  height H,      terminal_clutter none,     base actual
%     G01  height h,      terminal_clutter constant, base actual, A_h(h)
%     G11  height H,      terminal_clutter constant, base actual, A_h(h)
%     PAR  height h,      707 default (p2108_height_gain, clutter_height)
%   with H = max(h, R) and [A_h, R] from p2108_height_gain_rev1 at the row's frequency
%   (trees_forest, hold3), unchanged fixed-terminal height. Stops unless PAR equals the
%   stored 707 prediction and G11 equals PAR to 1e-9 dB, and unless the four cells
%   coincide where h >= R. Model outputs only; no measured loss is read.
%   Development data only.
P = itm_exp_paths_rev1(); St = settings_rev1(); root = char(P.root);
setenv('ITMEXP_OVERRIDES', '');
base = params_exp();
base.diffraction = "delta_cascaded_isolated"; base.diffraction_bound = "itm_troposcatter_line";
base.terminal_clutter_type = "trees_forest"; base.terminal_clutter_frange = "hold3";
run = "707-cascaded-isolated-clutter-at-r";
I = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
I = I(I.dataset == "phase2", :);
L = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
E = readtable(fullfile(root, 'experiments', run, 'predictions_phase2.csv'), 'TextType', 'string');
CO = readtable(pairs_csv, 'TextType', 'string');
ids = unique(CO.link_id_c, 'stable');
if numel(ids) ~= height(CO), error('itmexp:b23', 'C rows repeat in the pair registry'); end
[tf, il] = ismember(ids, L.link_id); if ~all(tf), error('itmexp:b23', 'C row missing in links'); end
[tf, ie] = ismember(ids, E.link_id); if ~all(tf), error('itmexp:b23', 'C row missing in stored 707'); end
n = numel(ids);
cell_names = ["G00" "G10" "G01" "G11" "PAR"];
Y = NaN(n, 5); A_h = NaN(n, 1); R = NaN(n, 1); H = NaN(n, 1); hm = NaN(n, 1);
X = NaN(n, 5, 7);      % per cell: mode, A_ref, L_ba, L_bs, A_s, bound_binds, delta_parts present
prof = containers.Map();
for i = 1:n
    r = il(i); pid = L.path_id(r);
    if ~isKey(prof, char(pid))
        k = find(I.path_id == pid, 1);
        f = fullfile(root, 'data', 'profiles', 'phase2', pid + ".csv");
        if sha(f) ~= I.sha256(k), error('itmexp:b23', 'profile hash mismatch %s', pid); end
        h = readmatrix(f, 'NumHeaderLines', 1);
        prof(char(pid)) = [numel(h) - 1; I.spacing_m(k); h(:)];
    end
    pfl = prof(char(pid));
    if L.siting(r) ~= "C", error('itmexp:b23', 'not a C row: %s', ids(i)); end
    va = L.set(r) == "VA";
    if va, hmob = L.hrx_m(r); else, hmob = L.htx_m(r); end
    if L.f_mhz(r) < 30, error('itmexp:b23', 'below the P.2108 range: %s', ids(i)); end
    [ah, Rm] = p2108_height_gain_rev1(L.f_mhz(r), hmob, "trees_forest", "hold3");
    hm(i) = hmob; A_h(i) = ah; R(i) = Rm; H(i) = max(hmob, Rm);
    for k = 1:5
        c = base; c.row = struct('set', string(L.set(r)), 'siting', "C", 'reversed', false, 'path_id', pid);
        hh = hmob;
        switch cell_names(k)
            case "G00", c.terminal_clutter = "none"; c.terminal_clutter_base = "actual"; c.terminal_clutter_db = 0;
            case "G10", c.terminal_clutter = "none"; c.terminal_clutter_base = "actual"; c.terminal_clutter_db = 0; hh = H(i);
            case "G01", c.terminal_clutter = "constant"; c.terminal_clutter_base = "actual"; c.terminal_clutter_db = ah;
            case "G11", c.terminal_clutter = "constant"; c.terminal_clutter_base = "actual"; c.terminal_clutter_db = ah; hh = H(i);
            case "PAR", c.terminal_clutter = "p2108_height_gain"; c.terminal_clutter_base = "clutter_height"; c.terminal_clutter_db = 0;
        end
        htx = L.htx_m(r); hrx = L.hrx_m(r);
        if va, hrx = hh; else, htx = hh; end
        [a, info] = itm_p2p_core_exp(htx, hrx, pfl, L.f_mhz(r), 50, St.confidence, St.location, ...
            L.climate(r), L.N_0(r), L.pol(r), St.epsilon, St.sigma, St.mdvar, true, [], c);
        if ~isfinite(a) || ~isreal(a), error('itmexp:b23', 'non-finite output %s %s', ids(i), cell_names(k)); end
        Y(i, k) = a;
        q = info.delta_parts;
        X(i, k, :) = [info.mode, info.A_ref_db, q.L_ba_db, q.L_bs_db, q.A_s_db, q.bound_binds, 1];
    end
    if abs(Y(i, 5) - E.var_lb_50(ie(i))) > 1e-9
        error('itmexp:b23', '%s: parent %.12g, stored 707 %.12g', ids(i), Y(i, 5), E.var_lb_50(ie(i)));
    end
    if abs(Y(i, 4) - Y(i, 5)) > 1e-9
        error('itmexp:b23', '%s: G11 %.12g differs from parent %.12g (stop, ask planner)', ids(i), Y(i, 4), Y(i, 5));
    end
    if hmob >= Rm && max(abs(Y(i, 1:4) - Y(i, 1))) > 1e-9
        error('itmexp:b23', '%s: h >= R but the four cells differ', ids(i));
    end
end
fprintf('factorial: %d C rows; parent vs stored max %.3g; G11 vs parent max %.3g dB\n', n, ...
    max(abs(Y(:, 5) - E.var_lb_50(ie))), max(abs(Y(:, 4) - Y(:, 5))));
T = table(ids, L.f_mhz(il), hm, R, H, A_h, Y(:, 1), Y(:, 2), Y(:, 3), Y(:, 4), Y(:, 5), ...
    'VariableNames', {'link_id', 'f_mhz', 'h_m', 'R_m', 'H_m', 'A_h_db', 'G00', 'G10', 'G01', 'G11', 'PAR'});
for k = 1:5
    s = cell_names(k);
    T.("mode_" + s) = X(:, k, 1); T.("Aref_" + s) = X(:, k, 2); T.("Lba_" + s) = X(:, k, 3);
    T.("Lbs_" + s) = X(:, k, 4); T.("As_" + s) = X(:, k, 5); T.("bound_" + s) = X(:, k, 6);
end
if ~isfolder(out_dir), mkdir(out_dir); end
writetable(T, fullfile(out_dir, 'factorial_rev1.csv'));
end

function h = sha(f)
fid = fopen(f, 'r'); c = onCleanup(@() fclose(fid));
b = fread(fid, Inf, '*uint8');
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
h = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
end
