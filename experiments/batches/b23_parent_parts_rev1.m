function T = b23_parent_parts_rev1(out_dir)
%B23_PARENT_PARTS_REV1 B23 preflight: 707 parity on every in-scope Phase 2 link, with report-only parts.
%   T = B23_PARENT_PARTS_REV1(out_dir) runs the historical 707 configuration through
%   itm_p2p_core_exp on every in-scope Phase 2 row at 50 %, with the exact evaluation
%   settings, and
%     - stops unless every loss matches 707's stored prediction to 1e-9 dB;
%     - re-runs a declared subset with info output off and requires exact equality
%       (report-only info must not change a result);
%     - re-runs a declared subset of rows with the pinned stock itm_p2p_rev1 and
%       compares with the stored baseline (itm_lb_50) and with stock predictions in
%       experiments/000-baseline;
%     - records N_s (for the geometry check), the ITM mode, A_ref, and the delta parts.
%   Model outputs only: no measured loss is read. Does not call load_profiles_rev1
%   (it would write a cache under data/); profiles are read and hash-checked here.
%   Development data only.
P = itm_exp_paths_rev1(); St = settings_rev1(); root = char(P.root);
setenv('ITMEXP_OVERRIDES', '');
c = params_exp();
c.diffraction = "delta_cascaded_isolated"; c.diffraction_bound = "itm_troposcatter_line";
c.terminal_clutter = "p2108_height_gain"; c.terminal_clutter_base = "clutter_height";
c.terminal_clutter_frange = "hold3";
run = "707-cascaded-isolated-clutter-at-r";
% Compare against the stored cfg, field by field (record, do not assume)
M = jsondecode(fileread(fullfile(root, 'experiments', run, 'metrics.json')));
diffs = cfg_diff(M.cfg, c);
fprintf('cfg fields differing from the stored 707 cfg: %d\n', numel(diffs));
if ~isempty(diffs), error('itmexp:b23', 'cfg differs from stored 707: %s', strjoin(diffs, ', ')); end

I = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
I = I(I.dataset == "phase2", :);
L = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
E = readtable(fullfile(root, 'experiments', run, 'predictions_phase2.csv'), 'TextType', 'string');
B = readtable(fullfile(root, 'experiments', '000-baseline', 'predictions_phase2.csv'), 'TextType', 'string');
if isnumeric(L.itm_error), ok = true(height(L), 1); else, ok = ismissing(L.itm_error) | L.itm_error == ""; end
L = L(ok, :);
[tf, je] = ismember(L.link_id, E.link_id);
if ~all(tf), error('itmexp:b23', '%d links lack a stored 707 prediction.', nnz(~tf)); end
if numel(unique(E.link_id)) ~= height(E), error('itmexp:b23', 'duplicate keys in stored 707 predictions'); end
stored = E.var_lb_50(je);
[tb, jb] = ismember(L.link_id, B.link_id);
if ~all(tb), error('itmexp:b23', 'links lack a stored baseline prediction'); end
if max(abs(B.itm_lb_50(jb) - L.itm_lb_50)) > 1e-12, error('itmexp:b23', 'stored baseline differs from the frozen table'); end

n = height(L);
prof = containers.Map();
vars_ = {'A_ref_db', 'bound_binds', 'L_ba_db', 'L_bs_db', 'A_s_db', 'N_s', 'mode'};
V = NaN(n, numel(vars_)); loss = NaN(n, 1);
for i = 1:n
    pid = L.path_id(i);
    if ~isKey(prof, char(pid))
        k = find(I.path_id == pid, 1);
        f = fullfile(root, 'data', 'profiles', 'phase2', pid + ".csv");
        if sha(f) ~= I.sha256(k), error('itmexp:b23', 'profile hash mismatch %s', pid); end
        h = readmatrix(f, 'NumHeaderLines', 1);
        prof(char(pid)) = [numel(h) - 1; I.spacing_m(k); h(:)];
    end
    pfl = prof(char(pid));
    ci = c;
    ci.row = struct('set', string(L.set(i)), 'siting', string(L.siting(i)), 'reversed', false, 'path_id', pid);
    [a, info] = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, St.confidence, St.location, ...
        L.climate(i), L.N_0(i), L.pol(i), St.epsilon, St.sigma, St.mdvar, true, [], ci);
    if ~isfinite(a) || ~isreal(a), error('itmexp:b23', 'non-finite output on %s', L.link_id(i)); end
    if abs(a - stored(i)) > 1e-9
        error('itmexp:b23', '%s: %.12g here, %.12g stored.', L.link_id(i), a, stored(i));
    end
    loss(i) = a;
    q = info.delta_parts;
    V(i, :) = [info.A_ref_db, q.bound_binds, q.L_ba_db, q.L_bs_db, q.A_s_db, info.N_s, info.mode];
end
fprintf('707 parity: %d rows, max |diff| %.3g dB\n', n, max(abs(loss - stored)));

% Info on/off: every 20th row (all sites and sitings), exact equality
sub = 1:20:n; off = NaN(numel(sub), 1);
for q = 1:numel(sub)
    i = sub(q); pfl = prof(char(L.path_id(i))); ci = c;
    ci.row = struct('set', string(L.set(i)), 'siting', string(L.siting(i)), 'reversed', false, 'path_id', L.path_id(i));
    a = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, St.confidence, St.location, ...
        L.climate(i), L.N_0(i), L.pol(i), St.epsilon, St.sigma, St.mdvar, false, [], ci);
    off(q) = a - loss(i);
end
fprintf('info on/off: %d rows, max |diff| %.3g dB\n', numel(sub), max(abs(off)));
if max(abs(off)) > 1e-9, error('itmexp:b23', 'info output changes a result'); end

% Stock baseline spot check: every 40th row with the pinned itm_p2p_rev1
sb = 1:40:n; dst = NaN(numel(sb), 1);
for q = 1:numel(sb)
    i = sb(q); pfl = prof(char(L.path_id(i)));
    a = itm_p2p_rev1(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, confidence=St.confidence, climate=L.climate(i), ...
        N_0=L.N_0(i), polarization=L.pol(i), epsilon=St.epsilon, sigma=St.sigma, mdvar=St.mdvar, validity="off");
    dst(q) = a - L.itm_lb_50(i);
end
fprintf('stock itm_p2p_rev1 vs stored baseline: %d rows, max |diff| %.3g dB\n', numel(sb), max(abs(dst)));
if max(abs(dst)) > 1e-9, error('itmexp:b23', 'stock baseline mismatch'); end

T = table(L.link_id, loss, V(:, 1), V(:, 2), V(:, 3), V(:, 4), V(:, 5), V(:, 6), V(:, 7), ...
    'VariableNames', {'link_id', 'loss_707_db', 'A_ref_db', 'bound_binds', 'L_ba_db', 'L_bs_db', 'A_s_db', 'N_s', 'itm_mode'});
if ~isfolder(out_dir), mkdir(out_dir); end
writetable(T, fullfile(out_dir, 'parent_parts_rev1.csv'));
S = struct('rows', n, 'max_abs_diff_707_db', max(abs(loss - stored)), 'info_onoff_rows', numel(sub), ...
    'info_onoff_max_db', max(abs(off)), 'stock_rows', numel(sb), 'stock_max_db', max(abs(dst)), ...
    'cfg_fields_differing', numel(diffs), 'matlab', string(version), 'matlab_itm', P.itm_head);
writelines(jsonencode(S, 'PrettyPrint', true), fullfile(out_dir, 'parity_rev1.json'));
end

function d = cfg_diff(a, b)
d = strings(0, 1);
f = fieldnames(a);
for k = 1:numel(f)
    if ~isfield(b, f{k}), d(end + 1) = string(f{k}); continue, end %#ok<AGROW>
    va = a.(f{k}); vb = b.(f{k});
    if isstruct(va)
        dd = cfg_diff(va, vb); d = [d; f{k} + "." + dd(:)]; %#ok<AGROW>
    elseif ~isequal(string(va), string(vb)) && ~(isnumeric(va) && isnumeric(vb) && isequal(double(va), double(vb)))
        d(end + 1) = string(f{k}); %#ok<AGROW>
    end
end
end

function h = sha(f)
fid = fopen(f, 'r'); c = onCleanup(@() fclose(fid));
b = fread(fid, Inf, '*uint8');
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
h = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
end
