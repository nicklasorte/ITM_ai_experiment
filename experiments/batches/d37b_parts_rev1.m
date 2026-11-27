function T = d37b_parts_rev1(root, options)
%D37B_PARTS_REV1 B37 D37b: 707 minus stock, one switch at a time, on B36's rows (model only).
%   T = D37B_PARTS_REV1(root) selects the B36 population (siting O,
%   uncensored, f <= 1000 MHz, steepest profile interval <= 10 deg; R1 1,427
%   rows on 29 paths, VA 243 on 61, R2 13 on 1), runs each row at 50 % with
%   five settings (experiments/batches/B37.md section 3: S, C1, C2, C3, C4),
%   checks S and C3 against the rescored stock and 707 predictions, and
%   writes experiments/D37-pe-repair-and-707-parts/parts_rev1.csv. It reads
%   no measured value: the link table's meas_lb_db column isn't loaded.
%
%   T = D37B_PARTS_REV1(root, Smoke=true) runs the rows of three R1 paths,
%   checks parity, and writes nothing.
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
if ~all(ok), error('itmexp:d37b', 'Link rows without a profile.'); end
sel = L.siting == "O" & L.censored == 0 & L.f_mhz <= 1000 & maxs(ip) <= tand(10);
L = L(sel, :); ip = ip(sel);
want = struct('R1', [1427 29], 'VA', [243 61], 'R2', [13 1]);
for s = string(fieldnames(want))'
    got = [nnz(L.set == s), numel(unique(L.path_id(L.set == s)))];
    if ~isequal(got, want.(s))
        error('itmexp:d37b', 'Population %s: %d rows on %d paths, registered %d on %d.', s, got, want.(s));
    end
end
if options.Smoke
    u = unique(L.path_id(L.set == "R1"));
    s = ismember(L.path_id, u(1:3));
    L = L(s, :); ip = ip(s);
end

% ---- settings (B37 section 3)
c = params_exp();
S0 = c;                                                      % S: stock
C1 = c; C1.diffraction = "delta_bullington"; C1.diffraction_bound = "none";
C2 = c; C2.diffraction = "delta_cascaded_isolated"; C2.diffraction_bound = "none";
C3 = C2; C3.diffraction_bound = "itm_troposcatter_line";    % 707 at siting O
% 707's terminal clutter settings, inactive at siting O; set so C3 is 707 exactly
C3.terminal_clutter = "p2108_height_gain"; C3.terminal_clutter_base = "clutter_height";
C3.terminal_clutter_frange = "hold3";
C4 = C3; C4.smooth_reference = "p452_spherical";
arms = {S0, C1, C2, C3, C4};

n = height(L); V = NaN(n, 5); mode = NaN(n, 1); parts = NaN(n, 5); pd = false(n, 1);
for i = 1:n
    pr = P(ip(i));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    for a = 1:5
        cc = arms{a};
        cc.row = struct('set', L.set(i), 'siting', L.siting(i), 'reversed', false, 'path_id', L.path_id(i));
        [v, info] = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, St.confidence, St.location, ...
            L.climate(i), L.N_0(i), L.pol(i), St.epsilon, St.sigma, St.mdvar, true, [], cc);
        if ~isfinite(v) || ~isreal(v), error('itmexp:d37b', 'Non-finite loss on %s arm %d.', L.link_id(i), a); end
        V(i, a) = v;
        if a == 1, mode(i) = info.mode; end
        if a == 4
            q = info.delta_parts;
            pd(i) = isfield(q, 'L_ba_db');
            if pd(i)
                parts(i, :) = [q.L_ba_db, q.L_bs_db, q.A_s_db, q.A_delta_db, double(q.bound_binds)];
            end
        end
    end
    if mod(i, 200) == 0, fprintf('row %d/%d\n', i, n); end
end

% ---- parity against the rescored predictions (stock = itm_lb_50, 707 = var_lb_50)
R = readtable(fullfile(root, 'experiments', '707r-rescore-screen36', 'predictions_phase2.csv'), 'TextType', 'string');
[tf, jr] = ismember(L.link_id, R.link_id);
if ~all(tf), error('itmexp:d37b', '%d rows missing from the rescored predictions.', nnz(~tf)); end
dS = max(abs(V(:, 1) - R.itm_lb_50(jr))); d7 = max(abs(V(:, 4) - R.var_lb_50(jr)));
fprintf('parity: stock max |diff| %.3g dB, 707 max |diff| %.3g dB\n', dS, d7);
if dS > 1e-9 || d7 > 1e-9, error('itmexp:d37b', 'Parity failed: stock %.3g dB, 707 %.3g dB.', dS, d7); end

T = table(L.link_id, L.path_id, L.set, L.f_mhz, L.htx_m, L.hrx_m, mode, pd, ...
    V(:, 1), V(:, 2), V(:, 3), V(:, 4), V(:, 5), parts(:, 1), parts(:, 2), parts(:, 3), parts(:, 4), parts(:, 5), ...
    'VariableNames', {'link_id', 'path_id', 'set', 'f_mhz', 'htx_m', 'hrx_m', 'itm_mode', 'delta_applies', ...
    'L_S', 'L_C1', 'L_C2', 'L_C3', 'L_C4', 'L_ba_db', 'L_bs_db', 'A_s_db', 'A_delta_db', 'bound_binds'});
if options.Smoke
    fprintf('smoke: %d rows on %d paths; delta applies on %d; modes %s\n', n, numel(unique(L.path_id)), nnz(pd), mat2str(unique(mode)'));
    return
end
od = fullfile(root, 'experiments', 'D37-pe-repair-and-707-parts');
if ~isfolder(od), mkdir(od); end
writetable(T, fullfile(od, 'parts_rev1.csv'));
fprintf('wrote %d rows\n', n);
end
