function T = d36_run_rev1(root, options)
%D36_RUN_REV1 B36: PE reference predictions on gentle Phase 2 paths (diagnostic, no score).
%   T = D36_RUN_REV1(root) selects the B36 population (experiments/batches/
%   B36.md section 3), runs pe2d_rev1 once per path, frequency and
%   transmitter height with all that group's receiver heights, runs the
%   per-path convergence screen, and writes
%   experiments/D36-pe-reference/pe_predictions_rev1.csv and
%   convergence_rev1.csv. It reads no measured value (the link table's
%   meas_lb_db column is not used here).
%
%   T = D36_RUN_REV1(root, Smoke=true) runs three paths (the first R1, the
%   first VA and the R2 path of the population) and writes nothing.
arguments
    root (1,1) string
    options.Smoke (1,1) logical = false
end
itm_exp_paths_rev1();
L = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
L = L(:, {'link_id', 'path_id', 'set', 'siting', 'f_mhz', 'htx_m', 'hrx_m', 'censored', 'fs_db', 'N_0'});
P = load_profiles_rev1(root);
ids = [P.path_id];
% steepest interval per profile
maxs = zeros(numel(P), 1);
for j = 1:numel(P)
    maxs(j) = max(abs(diff(P(j).h_m))) / P(j).spacing_m;
end
[ok, ip] = ismember(L.path_id, ids);
if ~all(ok), error('itmexp:d36', 'Link rows without a profile.'); end
sel = L.siting == "O" & L.censored == 0 & L.f_mhz <= 1000 & maxs(ip) <= tand(10);
L = L(sel, :); ip = ip(sel);
want = struct('R1', [1427 29], 'VA', [243 61], 'R2', [13 1]);
for s = string(fieldnames(want))'
    got = [nnz(L.set == s), numel(unique(L.path_id(L.set == s)))];
    if ~isequal(got, want.(s))
        error('itmexp:d36', 'Population %s: %d rows on %d paths, registered %d on %d.', s, got, want.(s));
    end
end
if numel(unique(L.set)) ~= 3, error('itmexp:d36', 'Unexpected sets in the population.'); end
fprintf('Population: R1 1427 rows/29 paths, VA 243/61, R2 13/1: matches B36\n');
if options.Smoke
    keep = [L.path_id(find(L.set == "R1", 1)); L.path_id(find(L.set == "VA", 1)); L.path_id(find(L.set == "R2", 1))];
    s = ismember(L.path_id, keep);
    L = L(s, :); ip = ip(s);
end

% ---- groups: one PE run per path, frequency, transmitter height
[G, gp, gf, gh] = findgroups(L.path_id, L.f_mhz, L.htx_m);
ng = max(G);
A = NaN(height(L), 1); Ap = NaN(height(L), 1); runtime = zeros(ng, 1);
for g = 1:ng
    r = find(G == g);
    pr = P(ip(r(1)));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    gamma_e = itm_gamma(pfl, L.N_0(r(1)));
    t0 = tic;
    o = pe2d_rev1(gf(g), gh(g), pfl, gamma_e, L.hrx_m(r)');
    runtime(g) = toc(t0);
    A(r) = o.A_db(:); Ap(r) = o.A_point_db(:);
    if mod(g, 25) == 0 || options.Smoke
        fprintf('group %d/%d: %s %g MHz, %d rows, %.1f s\n', g, ng, gp(g), gf(g), numel(r), runtime(g));
    end
end
fprintf('PE runs: %d, median %.1f s, max %.1f s, total %.0f s\n', ng, median(runtime), max(runtime), sum(runtime));

% ---- convergence screen: per path, highest frequency, first receiver row
up = unique(L.path_id, 'stable');
C = table(up, NaN(numel(up), 1), NaN(numel(up), 1), NaN(numel(up), 1), false(numel(up), 1), ...
    'VariableNames', {'path_id', 'f_mhz', 'A_base_db', 'A_fine_db', 'converged'});
for j = 1:numel(up)
    r = find(L.path_id == up(j));
    [~, k] = max(L.f_mhz(r)); r1 = r(k);
    pr = P(ip(r1));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    gamma_e = itm_gamma(pfl, L.N_0(r1));
    base = pe2d_rev1(L.f_mhz(r1), L.htx_m(r1), pfl, gamma_e, L.hrx_m(r1));
    fine = pe2d_rev1(L.f_mhz(r1), L.htx_m(r1), pfl, gamma_e, L.hrx_m(r1), DzLambda=0.125, DxMax=base.dx / 2);
    C.f_mhz(j) = L.f_mhz(r1); C.A_base_db(j) = base.A_db; C.A_fine_db(j) = fine.A_db;
    C.converged(j) = abs(fine.A_db - base.A_db) <= 1;
end
fprintf('Convergence screen: %d of %d paths converged within 1 dB\n', nnz(C.converged), height(C));
[~, ic] = ismember(L.path_id, C.path_id);
T = L(:, {'link_id', 'path_id', 'set', 'f_mhz', 'htx_m', 'hrx_m'});
T.A_pe_db = A; T.A_pe_point_db = Ap; T.L_pe_db = L.fs_db + A;
T.max_slope_deg = atand(maxs(ip)); T.converged = C.converged(ic);
if any(~isfinite(T.A_pe_db)), error('itmexp:d36', 'Non-finite PE attenuation.'); end
if options.Smoke
    return
end
out = fullfile(root, 'experiments', 'D36-pe-reference');
if ~isfolder(out), mkdir(out); end
writetable(T, fullfile(out, 'pe_predictions_rev1.csv'));
writetable(C, fullfile(out, 'convergence_rev1.csv'));
fprintf('Wrote %s\n', out);
end

function gamma_e = itm_gamma(pfl, N_0)
% ITM's effective curvature, as itm_p2p_core_exp computes it: h_sys is the
% mean elevation of the middle 80 % of the profile (sequential sum, as the
% C++), N_s = N_0 exp(-h_sys/9460), gamma_e = 157e-9 (1 - 0.04665 exp(N_s/179.3)).
np = fix(pfl(1));
p10 = fix(0.1 * np);
h_acc = cumsum(pfl((p10:np - p10) + 3));
h_sys = h_acc(end) / (np - 2 * p10 + 1);
if h_sys == 0, N_s = N_0; else, N_s = N_0 * exp(-h_sys / 9460.0); end
gamma_e = 157e-9 * (1.0 - 0.04665 * exp(N_s / 179.3));
end
