function M = run_eval_rev1(options)
%RUN_EVAL_REV1 Run the ITM variant on the frozen links and score it. Read-only.
%   M = RUN_EVAL_REV1(Tag="001-short-name") runs itm_variant/itm_p2p_core_exp
%   with the settings from itm_variant/params_exp on every link in
%   data/links, runs the physics battery, scores the variant and the
%   baseline and reference models with score_rev1, and writes:
%     experiments/<Tag>/metrics.json        full metrics (human view)
%     experiments/<Tag>/summary.txt         agent-facing summary, scores rounded to 0.1 dB
%     experiments/<Tag>/predictions_phase2.csv, predictions_longterm.csv
%   and then refreshes the archive (pareto_rev1: results/archive_rev1.*).
%
%   Before scoring it checks that the split file matches its hash and that
%   the pinned matlab_itm is in use. With Parity=true it also requires the
%   variant to match the stored baseline to 1e-9 dB (use for 000-baseline
%   and after harness changes).
%
%   Options:
%     Tag         experiment folder name (required)
%     Datasets    ["phase2" "longterm"]
%     Physics     true
%     Parity      false
%     Write       true
%     Best        ""      tag of the current best; when given, a paired
%                         bootstrap of the gain over it (paired_gain_rev1)
%                         is appended to summary.txt

arguments
    options.Tag (1,1) string
    options.Datasets (1,:) string = ["phase2" "longterm"]
    options.Physics (1,1) logical = true
    options.Parity (1,1) logical = false
    options.Write (1,1) logical = true
    options.Best (1,1) string = ""
end
t0 = tic;
P = itm_exp_paths_rev1();
S = settings_rev1();
root = P.root;
check_splits(root);
profiles = load_profiles_rev1(root); ids = [profiles.path_id];
cfg = params_exp();

opts = {'TextType', 'string'};
P2 = table(); LT = table();
if any(options.Datasets == "phase2")
    P2 = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), opts{:});
    P2.set = string(P2.set);
    P2 = P2(baseline_ok(P2), :);
    P2.var_lb_50 = run_rows(P2, profiles, ids, 50, cfg, S);
end
if any(options.Datasets == "longterm")
    LT = readtable(fullfile(root, 'data', 'links', 'longterm_links_rev1.csv'), opts{:});
    LT = LT(baseline_ok(LT), :);
    V = run_rows(LT, profiles, ids, S.p_all, cfg, S);
    for j = 1:numel(S.p_tags), LT.("var_lb_" + S.p_tags(j)) = V(:, j); end
end

% Parity with the stored baseline
M = struct('tag', options.Tag, 'cfg', cfg, 'matlab_itm', P.itm_head, 'matlab', string(version));
M.data_version = struct('split_sha', split_sha(root), 'datasets', options.Datasets);
dmax = 0;
if ~isempty(P2), dmax = max(dmax, max(abs(P2.var_lb_50 - P2.itm_lb_50), [], 'omitnan')); end
if ~isempty(LT)
    for t = S.p_tags, dmax = max(dmax, max(abs(LT.("var_lb_" + t) - LT.("itm_lb_" + t)), [], 'omitnan')); end
end
M.max_abs_diff_from_baseline_db = dmax;
if options.Parity && dmax > 1e-9
    error('itmexp:parity', 'Variant differs from the stored baseline by %.3g dB; parity required.', dmax);
end

% Physics battery
if options.Physics && ~isempty(P2)
    M.physics = physics_battery_rev1(cfg, P2, profiles);
else
    M.physics = struct('pass', NaN);
end

% Scores
M.variant = score_rev1(P2, LT, "var");
M.baseline = score_rev1(P2, LT, "itm");
for m = ["p452" "p2001"]
    if (~isempty(P2) && ismember(m + "_lb_50", P2.Properties.VariableNames))
        M.(m) = score_rev1(P2, LT, m);
    end
end
M.runtime_s = toc(t0);

% Agent-facing summary (rounded)
A = score_rev1(P2, LT, "var", Round=0.1);
B0 = score_rev1(P2, LT, "itm", Round=0.1);
lines = [
    sprintf("experiment %s   (matlab_itm %s, %s)", options.Tag, P.itm_head, string(datetime('now')))
    sprintf("composite  %.1f dB   (baseline %.1f)", A.composite, B0.composite)
    sprintf("  phase2 cell-balanced RMS @50%%   %.1f   (baseline %.1f)", A.p2.cell, B0.p2.cell)
    sprintf("  long-term level RMS             %.1f   (baseline %.1f)", A.lt.level, B0.lt.level)
    sprintf("  long-term shape RMS             %.1f   (baseline %.1f)", A.lt.shape, B0.lt.shape)
    ];
if isfield(A, 'screened')
    lines(end + 1) = sprintf("composite, screened set  %.1f dB   (baseline %.1f; %d rows left out)", ...
        A.screened.composite, B0.screened.composite, A.screened.n_dropped);
end
if ~isempty(P2)
    for s = ["R1" "R2" "R3" "VA"]
        lines(end + 1) = sprintf("  site %s RMS %.1f  mean %+.1f   (baseline %.1f)", s, ...
            round(A.p2.site.(s).rms, 1), round(A.p2.site.(s).mean, 1), round(B0.p2.site.(s).rms, 1)); %#ok<AGROW>
    end
    lines(end + 1) = sprintf("  worst cell %.1f   censored violations %.1f%% (baseline %.1f%%)", ...
        round(A.p2.worst_cell, 1), A.p2.censored_violation_pct, B0.p2.censored_violation_pct);
end
lines(end + 1) = sprintf("physics battery: %s", passfail(M.physics.pass));
lines(end + 1) = sprintf("max |variant - baseline| = %.3g dB; runtime %.0f s", dmax, M.runtime_s);
fprintf('%s\n', lines);

if options.Write
    out = fullfile(root, 'experiments', options.Tag);
    if ~isfolder(out), mkdir(out); end
    writelines(lines, fullfile(out, 'summary.txt'));
    J = M; J.variant.p2 = rmfield(J.variant.p2, 'cells'); J.baseline.p2 = rmfield(J.baseline.p2, 'cells');
    for m = ["p452" "p2001"]
        if isfield(J, m), J.(m).p2 = rmfield(J.(m).p2, 'cells'); end
    end
    writelines(jsonencode(J, 'PrettyPrint', true), fullfile(out, 'metrics.json'));
    writetable(M.variant.p2.cells, fullfile(out, 'cells_phase2.csv'));
    if ~isempty(P2)
        writetable(P2(:, {'link_id', 'path_id', 'set', 'f_mhz', 'censored', 'meas_lb_db', 'itm_lb_50', 'var_lb_50'}), ...
            fullfile(out, 'predictions_phase2.csv'));
    end
    if ~isempty(LT)
        keep = ["link_id" "path_id" "fold" "f_mhz" "d_km", "meas_lb_" + S.p_tags, "itm_lb_" + S.p_tags, "var_lb_" + S.p_tags];
        writetable(LT(:, cellstr(keep)), fullfile(out, 'predictions_longterm.csv'));
    end
    if options.Best ~= ""
        G = paired_gain_rev1(options.Tag, options.Best, Write=true);
        lines = [lines; ""; readlines(fullfile(out, "paired_vs_" + options.Best + ".txt"))];
        writelines(lines, fullfile(out, 'summary.txt'));
        M.paired = G;
    end
    pareto_rev1();     % refresh results/archive_rev1.*
end
end

function L = run_rows(T, profiles, ids, p, cfg, S)
L = NaN(height(T), numel(p));
[~, ip] = ismember(T.path_id, ids);
if any(ip == 0)
    error('itmexp:profiles', 'Profiles missing for %d rows. Run data/build_links_rev1(ProfilesOnly=true).', nnz(ip == 0));
end
for i = 1:height(T)
    pr = profiles(ip(i));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    a = itm_p2p_core_exp(T.htx_m(i), T.hrx_m(i), pfl, T.f_mhz(i), p, S.confidence, S.location, ...
        T.climate(i), T.N_0(i), T.pol(i), S.epsilon, S.sigma, S.mdvar, false, [], cfg);
    if ~all(isfinite(a)) || ~isreal(a)
        error('itmexp:nonfinite', 'Variant returned a non-finite or complex loss on %s.', T.link_id(i));
    end
    L(i, :) = a(:)';
end
end

function ok = baseline_ok(T)
% Rows where the baseline ITM returned an error are out of scope for every model
if ~ismember('itm_error', T.Properties.VariableNames) || isnumeric(T.itm_error)
    ok = true(height(T), 1);
else
    ok = ismissing(T.itm_error) | T.itm_error == "";
end
end

function s = split_sha(root)
s = strtrim(string(fileread(fullfile(root, 'data', 'splits', 'folds_rev1.sha256'))));
end

function check_splits(root)
f = fullfile(root, 'data', 'splits', 'folds_rev1.csv');
want = strtrim(string(fileread(fullfile(root, 'data', 'splits', 'folds_rev1.sha256'))));
fid = fopen(f, 'r'); c = onCleanup(@() fclose(fid));
b = fread(fid, Inf, '*uint8');
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
got = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
if got ~= want
    error('itmexp:splits', 'data/splits/folds_rev1.csv does not match its hash. The splits are frozen.');
end
end

function s = passfail(x)
if isnan(x), s = "not run"; elseif x, s = "PASS"; else, s = "FAIL"; end
end
