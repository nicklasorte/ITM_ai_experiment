function T = d38a_parts_rev1(root, options)
%D38A_PARTS_REV1 B38 D38a: parts of the cascade step, and the cascade's edges (model only).
%   T = D38A_PARTS_REV1(root) runs every Phase 2 row with siting O and not
%   censored at 50 % with five settings (experiments/batches/B38.md
%   section 2: C1, C1u, P, U, C2; bound none), flags B36's rows, checks C1
%   and C2 against B37's parts on those rows, checks P <= U <= C2 on L_ba,
%   and writes experiments/D38-cascade-parts-landcover/parts_rev1.csv and
%   edges_rev1.csv (the C2 arm's L_ba edges, nu and weights). It uses no
%   measured value: measured columns are read with the link table and
%   dropped.
%
%   T = D38A_PARTS_REV1(root, Smoke=true) runs three R1 paths of B36's
%   rows, runs the checks, and writes nothing.
arguments
    root (1,1) string
    options.Smoke (1,1) logical = false
end
itm_exp_paths_rev1(); St = settings_rev1();
setenv('ITMEXP_OVERRIDES', '');
L = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
L = L(:, {'link_id', 'path_id', 'set', 'siting', 'f_mhz', 'htx_m', 'hrx_m', 'censored', 'N_0', 'climate', 'pol'});
P = load_profiles_rev1(root);
ids = [P.path_id];
maxs = zeros(numel(P), 1);
for j = 1:numel(P)
    maxs(j) = max(abs(diff(P(j).h_m))) / P(j).spacing_m;
end
[ok, ip] = ismember(L.path_id, ids);
if ~all(ok), error('itmexp:d38a', 'Link rows without a profile.'); end
sel = L.siting == "O" & L.censored == 0;
L = L(sel, :); ip = ip(sel);
in36 = L.f_mhz <= 1000 & maxs(ip) <= tand(10);
want = struct('R1', [1427 29], 'VA', [243 61], 'R2', [13 1]);
for s = string(fieldnames(want))'
    got = [nnz(in36 & L.set == s), numel(unique(L.path_id(in36 & L.set == s)))];
    if ~isequal(got, want.(s))
        error('itmexp:d38a', 'B36 population %s: %d rows on %d paths, registered %d on %d.', s, got, want.(s));
    end
end
if nnz(in36) ~= 1683, error('itmexp:d38a', 'B36 population: %d rows, expected 1,683.', nnz(in36)); end
if options.Smoke
    u = unique(L.path_id(in36 & L.set == "R1"));
    s = ismember(L.path_id, u(1:3)) & in36;
    L = L(s, :); ip = ip(s); in36 = in36(s);
end

c = params_exp();
names = ["C1" "C1u" "P" "U" "C2"];
forms = ["delta_bullington" "delta_bullington_uc" "delta_cascaded_isolated_principal" ...
    "delta_cascaded_isolated_uc" "delta_cascaded_isolated"];
n = height(L); V = NaN(n, 5); Lba = NaN(n, 5); mode = NaN(n, 1);
E = cell(n, 3);
for i = 1:n
    pr = P(ip(i));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    for a = 1:5
        cc = c; cc.diffraction = forms(a); cc.diffraction_bound = "none";
        cc.row = struct('set', L.set(i), 'siting', L.siting(i), 'reversed', false, 'path_id', L.path_id(i));
        [v, info] = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, St.confidence, St.location, ...
            L.climate(i), L.N_0(i), L.pol(i), St.epsilon, St.sigma, St.mdvar, true, [], cc);
        if ~isfinite(v) || ~isreal(v), error('itmexp:d38a', 'Non-finite loss on %s arm %s.', L.link_id(i), names(a)); end
        V(i, a) = v; q = info.delta_parts; Lba(i, a) = q.L_ba_db;
        if a == 1, mode(i) = info.mode; end
        if a == 5, E(i, :) = {q.edges_ba, q.nu_ba, q.weight_ba}; end
    end
    if mod(i, 1000) == 0, fprintf('row %d/%d\n', i, n); end
end

% ---- checks
tol = 1e-9;
bad = Lba(:, 3) > Lba(:, 4) + tol | Lba(:, 4) > Lba(:, 5) + tol;
if any(bad), error('itmexp:d38a', 'P <= U <= C2 fails on L_ba for %d rows.', nnz(bad)); end
B = readtable(fullfile(root, 'experiments', 'D37-pe-repair-and-707-parts', 'parts_rev1.csv'), 'TextType', 'string');
k = find(in36);
[tf, jb] = ismember(L.link_id(k), B.link_id);
if ~all(tf), error('itmexp:d38a', 'B36 rows missing from B37 parts.'); end
d1 = max(abs(V(k, 1) - B.L_C1(jb))); d2 = max(abs(V(k, 5) - B.L_C2(jb)));
fprintf('parity with B37: C1 %.3g dB, C2 %.3g dB on %d rows\n', d1, d2, numel(k));
if d1 > tol || d2 > tol, error('itmexp:d38a', 'Parity with B37 failed: C1 %.3g, C2 %.3g dB.', d1, d2); end

T = table(L.link_id, L.path_id, L.set, L.f_mhz, L.htx_m, L.hrx_m, in36, mode, ...
    V(:, 1), V(:, 2), V(:, 3), V(:, 4), V(:, 5), Lba(:, 1), Lba(:, 3), Lba(:, 4), Lba(:, 5), ...
    'VariableNames', {'link_id', 'path_id', 'set', 'f_mhz', 'htx_m', 'hrx_m', 'in_b36', 'itm_mode', ...
    'L_C1', 'L_C1u', 'L_P', 'L_U', 'L_C2', 'Lba_C1', 'Lba_P', 'Lba_U', 'Lba_C2'});
ne = cellfun(@numel, E(:, 1));
pi_ = zeros(n, 1); pnu = NaN(n, 1);
for i = 1:n
    if ne(i) == 3, j = 2; else, j = 1; end     % principal: middle of [t p r], else the only edge
    e = E{i, 1}; v = E{i, 2};
    pi_(i) = e(j); pnu(i) = v(j);
end
Te = table(L.link_id, L.path_id, ne, pi_, pnu, ...
    string(cellfun(@(x) strjoin(string(x), ' '), E(:, 1), 'UniformOutput', false)), ...
    string(cellfun(@(x) strjoin(string(x), ' '), E(:, 2), 'UniformOutput', false)), ...
    string(cellfun(@(x) strjoin(string(x), ' '), E(:, 3), 'UniformOutput', false)), ...
    'VariableNames', {'link_id', 'path_id', 'n_edges', 'principal_index', 'principal_nu', 'edges', 'nu', 'weights'});
if any(ne == 2), error('itmexp:d38a', 'The full cascade returned a two-edge set on %d rows; principal ambiguous.', nnz(ne == 2)); end
if options.Smoke
    fprintf('smoke: %d rows; edges per row %s; checks pass\n', n, mat2str(unique(ne)'));
    return
end
od = fullfile(root, 'experiments', 'D38-cascade-parts-landcover');
if ~isfolder(od), mkdir(od); end
writetable(T, fullfile(od, 'parts_rev1.csv'));
writetable(Te, fullfile(od, 'edges_rev1.csv'));
fprintf('wrote %d rows (%d in B36)\n', n, nnz(in36));
end
