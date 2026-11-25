function R = cv_calibrate_rev1(options)
%CV_CALIBRATE_REV1 Recalibrated-ITM baseline: fit ITM's constants in cross-validation, no agent.
%   R = CV_CALIBRATE_REV1() fits the constants in params_exp().cal (smooth-
%   earth weight constant, scales on the clutter term A_fo, the knife-edge
%   loss, the line-of-sight blend, and the two sides of the time spread)
%   with Bayesian optimization (bayesopt), separately for each fold, on the
%   training folds only, and predicts the held-out fold with the fitted
%   values. The out-of-fold predictions are scored with score_rev1 exactly
%   like any experiment.
%
%   This is the honest comparator for any agent result: a conventional
%   optimizer retuning the existing model (see docs/PUBLICATION_LITERATURE.md,
%   section 2). Submodel structure is not changed.
%
%   Folds: Phase 2 by site (R1, R2, R3, VA = folds 1-4) and the long-term set
%   by receiver-site group (folds 1-5), from data/splits/folds_rev1.csv.
%   Fold k holds out Phase 2 fold k (if any) and long-term fold k together.
%
%   Writes experiments/<Tag>/: summary.txt, metrics.json, params_by_fold.csv,
%   predictions_phase2.csv, predictions_longterm.csv.
%
%   With Constrained=true (experiment R02), each trial must also satisfy two
%   coupled constraints, both evaluated without held-out data:
%     censored  censored-bound violations on the training folds no more
%               than 1 percentage point above stock ITM on the same rows
%               (the acceptance rule's censored gate)
%     physics   every check in physics_battery_rev1 within its margin
%               (largest margin over continuity, reciprocity, two-ray)
%   The search starts from ITM's own constants, which satisfy both, plus
%   each constant nudged down and up one at a time (so the surrogate learns
%   which directions stay feasible), and the fold's fit is the best feasible
%   trial observed.
%
%   Options:
%     Tag        "R01-recalibrated-itm"
%     MaxEvals   40      objective evaluations per fold
%     Seed       1
%     Params     all six; a subset of the field names of params_exp().cal
%     Constrained false

arguments
    options.Tag (1,1) string = "R01-recalibrated-itm"
    options.MaxEvals (1,1) double = 40
    options.Seed (1,1) double = 1
    options.Params (1,:) string = ["w_const" "afo_scale" "knife_scale" "los_w_scale" "time_minus_scale" "time_plus_scale"]
    options.Constrained (1,1) logical = false
end
t0 = tic;
P = itm_exp_paths_rev1();
S = settings_rev1();
root = P.root;
profiles = load_profiles_rev1(root);
ids = [profiles.path_id];
base_cfg = params_exp();

% Search ranges (physically plausible; log scale where the constant spans decades)
spec = struct( ...
    'w_const',          {[2.51 251],  "log"}, ...
    'afo_scale',        {[0 2],       "none"}, ...
    'knife_scale',      {[0.3 1.5],   "none"}, ...
    'los_w_scale',      {[0.01 100],  "log"}, ...
    'time_minus_scale', {[0.3 3],     "none"}, ...
    'time_plus_scale',  {[0.3 3],     "none"});
vars = optimizableVariable.empty;
for nm = options.Params
    v = spec(1).(nm); tr = spec(2).(nm);
    vars(end + 1) = optimizableVariable(char(nm), v, 'Transform', char(tr)); %#ok<AGROW>
end

opts = {'TextType', 'string'};
P2 = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), opts{:});
P2.set = string(P2.set); P2 = P2(baseline_ok(P2), :);
LT = readtable(fullfile(root, 'data', 'links', 'longterm_links_rev1.csv'), opts{:});
LT = LT(baseline_ok(LT), :);
F = readtable(fullfile(root, 'data', 'splits', 'folds_rev1.csv'), opts{:});
[~, i2] = ismember(P2.path_id, F.path_id(F.dataset == "phase2"));
f2 = F.fold(F.dataset == "phase2"); P2.cvfold = f2(i2);
[~, il] = ismember(LT.path_id, F.path_id(F.dataset == "longterm"));
fl = F.fold(F.dataset == "longterm"); LT.cvfold = fl(il);
if any(i2 == 0) || any(il == 0)
    error('itmexp:folds', 'Some links have no fold in data/splits/folds_rev1.csv.');
end
K = max([P2.cvfold; LT.cvfold]);

P2.cal_lb_50 = NaN(height(P2), 1);
for t = S.p_tags, LT.("cal_lb_" + t) = NaN(height(LT), 1); end
fits = table();
for k = 1:K
    tr2 = P2.cvfold ~= k; trl = LT.cvfold ~= k;
    rng(options.Seed + k, 'twister');
    if options.Constrained
        cens0 = score_rev1(P2(tr2, :), LT(trl, :), "itm").p2.censored_violation_pct;
        obj = @(x) objective_constrained(x, base_cfg, P2(tr2, :), LT(trl, :), P2, profiles, ids, S, cens0);
        x0 = start_points(base_cfg, options.Params, spec);   % ITM's constants, then one-at-a-time nudges
        res = bayesopt(obj, vars, 'MaxObjectiveEvaluations', options.MaxEvals, 'IsObjectiveDeterministic', true, ...
            'NumCoupledConstraints', 2, 'AreCoupledConstraintsDeterministic', [true true], ...
            'InitialX', x0, 'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0, 'PlotFcn', []);
        ok = all(res.ConstraintsTrace <= 0, 2) & res.ObjectiveTrace < 1e3;
        if ~any(ok)
            error('itmexp:infeasible', 'Fold %d: no feasible trial, not even ITM''s own constants.', k);
        end
        tr = res.ObjectiveTrace; tr(~ok) = Inf;
        [fmin, ib] = min(tr);
        x = res.XTrace(ib, :);
        res_min = fmin; n_feasible = nnz(ok);
    else
        obj = @(x) objective(x, base_cfg, P2(tr2, :), LT(trl, :), profiles, ids, S);
        res = bayesopt(obj, vars, 'MaxObjectiveEvaluations', options.MaxEvals, 'IsObjectiveDeterministic', true, ...
            'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0, 'PlotFcn', []);
        x = res.XAtMinObjective;
        res_min = res.MinObjective; n_feasible = NaN;
    end
    cfg = apply(base_cfg, x);
    h2 = ~tr2; hl = ~trl;
    if any(h2), P2.cal_lb_50(h2) = predict(P2(h2, :), profiles, ids, 50, cfg, S); end
    if any(hl)
        V = predict(LT(hl, :), profiles, ids, S.p_all, cfg, S);
        for j = 1:numel(S.p_tags), LT.("cal_lb_" + S.p_tags(j))(hl) = V(:, j); end
    end
    row = x; row.fold = k; row.train_composite = res_min; row.n_feasible = n_feasible;
    fits = [fits; row]; %#ok<AGROW>
    fprintf('fold %d of %d: train composite %.2f dB, %g feasible trials  (%s)\n', k, K, res_min, n_feasible, ...
        strjoin(compose("%s=%.3g", string(x.Properties.VariableNames)', table2array(x)'), ", "));
end

Rc = score_rev1(P2, LT, "cal");
Rb = score_rev1(P2, LT, "itm");
% Physics battery at the median fitted values
med = varfun(@median, fits(:, cellstr(options.Params)));
med.Properties.VariableNames = cellstr(options.Params);
B = physics_battery_rev1(apply(base_cfg, med), P2, profiles);

R = struct('tag', options.Tag, 'recalibrated', Rc, 'baseline', Rb, 'physics', B, ...
    'median_params', table2struct(med), 'runtime_s', toc(t0));
R.cfg = apply(base_cfg, med);
R.constrained = options.Constrained;
R.data_version = struct('split_sha', strtrim(string(fileread(fullfile(root, 'data', 'splits', 'folds_rev1.sha256')))), ...
    'datasets', ["phase2" "longterm"]);
lines = [
    sprintf("%s: recalibrated ITM, constants fitted in %d-fold cross-validation (bayesopt, %d evals per fold%s)", options.Tag, K, options.MaxEvals, ...
        string(repmat(', constrained: censored +1 point and physics battery', 1, options.Constrained)))
    sprintf("composite  %.2f dB   (baseline ITM %.2f)", Rc.composite, Rb.composite)
    sprintf("  phase2 cell-balanced RMS   %.2f   (baseline %.2f)", Rc.p2.cell, Rb.p2.cell)
    sprintf("  long-term level RMS        %.2f   (baseline %.2f)", Rc.lt.level, Rb.lt.level)
    sprintf("  long-term shape RMS        %.2f   (baseline %.2f)", Rc.lt.shape, Rb.lt.shape)
    ];
for s = ["R1" "R2" "R3" "VA"]
    lines(end + 1) = sprintf("  site %s RMS %.1f  mean %+.1f   (baseline %.1f, mean %+.1f)", s, Rc.p2.site.(s).rms, ...
        Rc.p2.site.(s).mean, Rb.p2.site.(s).rms, Rb.p2.site.(s).mean); %#ok<AGROW>
end
lines(end + 1) = sprintf("  censored violations %.1f%%   (baseline %.1f%%)", Rc.p2.censored_violation_pct, Rb.p2.censored_violation_pct);
if isfield(Rc, 'screened')
    lines(end + 1) = sprintf("composite, screened set  %.2f dB   (baseline %.2f; %d rows left out)", ...
        Rc.screened.composite, Rb.screened.composite, Rc.screened.n_dropped);
end
lines(end + 1) = sprintf("physics battery at median fitted constants: %s", string(B.pass));
lines(end + 1) = "median fitted constants: " + strjoin(compose("%s=%.3g", string(med.Properties.VariableNames)', table2array(med)'), ", ");
lines(end + 1) = sprintf("runtime %.0f s", R.runtime_s);
fprintf('%s\n', lines);

out = fullfile(root, 'experiments', options.Tag);
if ~isfolder(out), mkdir(out); end
writelines(lines, fullfile(out, 'summary.txt'));
J = R; J.recalibrated.p2 = rmfield(J.recalibrated.p2, 'cells'); J.baseline.p2 = rmfield(J.baseline.p2, 'cells');
writelines(jsonencode(J, 'PrettyPrint', true), fullfile(out, 'metrics.json'));
writetable(fits, fullfile(out, 'params_by_fold.csv'));
writetable(P2(:, {'link_id', 'path_id', 'set', 'cvfold', 'f_mhz', 'censored', 'meas_lb_db', 'itm_lb_50', 'cal_lb_50'}), ...
    fullfile(out, 'predictions_phase2.csv'));
keep = ["link_id" "path_id" "cvfold" "f_mhz" "d_km", "meas_lb_" + S.p_tags, "itm_lb_" + S.p_tags, "cal_lb_" + S.p_tags];
writetable(LT(:, cellstr(keep)), fullfile(out, 'predictions_longterm.csv'));
pareto_rev1();     % refresh results/archive_rev1.*
end

function [f, c] = objective_constrained(x, base_cfg, P2, LT, P2all, profiles, ids, S, cens0)
% Training composite, with coupled constraints c <= 0:
%   c(1) training censored violations minus (stock ITM + 1 point)
%   c(2) largest physics-battery margin (variant minus its allowed limit)
cfg = apply(base_cfg, x);
f = 1e3; c = [1e3 1e3];
try
    P2.cal_lb_50 = predict(P2, profiles, ids, 50, cfg, S);
    V = predict(LT, profiles, ids, S.p_all, cfg, S);
    for j = 1:numel(S.p_tags), LT.("cal_lb_" + S.p_tags(j)) = V(:, j); end
    r = score_rev1(P2, LT, "cal");
    B = physics_battery_rev1(cfg, P2all, profiles);
catch
    return                       % a trial that breaks the model is infeasible
end
if ~isfinite(r.composite), return, end
m = -Inf;
for nm = string(fieldnames(B.checks))'
    q = B.checks.(nm);
    if isfield(q, 'report_only') && q.report_only
        continue                 % report-only fields (2f0692b) set no limit and lack the step fields
    end
    if startsWith(nm, "continuity_")
        m = max(m, q.variant_max_step_db - (q.baseline_max_step_db + 1));
    elseif nm == "reciprocity"
        m = max(m, q.variant_p95_db - max(0.1, q.baseline_p95_db + 0.1));
    elseif nm == "two_ray_bound"
        m = max(m, q.limit_db - q.variant_min_excess_db);
    elseif nm == "finite" && ~q.pass
        m = max(m, 1);
    end
end
f = r.composite;
c = [r.p2.censored_violation_pct - (cens0 + 1), m];
end

function f = objective(x, base_cfg, P2, LT, profiles, ids, S)
cfg = apply(base_cfg, x);
try
    P2.cal_lb_50 = predict(P2, profiles, ids, 50, cfg, S);
    V = predict(LT, profiles, ids, S.p_all, cfg, S);
catch
    f = 1e3;                     % a trial that breaks the model scores as very bad
    return
end
for j = 1:numel(S.p_tags), LT.("cal_lb_" + S.p_tags(j)) = V(:, j); end
r = score_rev1(P2, LT, "cal");
f = r.composite;
if ~isfinite(f), f = 1e3; end
end

function x0 = start_points(base_cfg, names, spec)
% ITM's constants, then each constant moved alone to a lower and a higher
% value inside its search range: x0.5 and x2 for log-scaled constants,
% x0.8 and x1.2 otherwise.
base = table();
for nm = names, base.(nm) = base_cfg.cal.(nm); end
x0 = base;
for nm = names
    r = spec(1).(nm);
    if spec(2).(nm) == "log", m = [0.5 2]; else, m = [0.8 1.2]; end
    for f = m
        t = base; t.(nm) = min(max(base.(nm) * f, r(1)), r(2));
        x0 = [x0; t]; %#ok<AGROW>
    end
end
end

function cfg = apply(cfg, x)
for nm = string(x.Properties.VariableNames)
    cfg.cal.(nm) = x.(nm);
end
end

function L = predict(T, profiles, ids, p, cfg, S)
L = NaN(height(T), numel(p));
[~, ip] = ismember(T.path_id, ids);
% Row metadata for the variant (cfg.row), set exactly as run_eval_rev1's
% run_rows does, so variants with terminal clutter or path inputs keyed by
% path_id run here too. Rows without set and siting (long-term) get empty
% strings.
meta = all(ismember({'set', 'siting'}, T.Properties.VariableNames));
for i = 1:height(T)
    pr = profiles(ip(i));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    c = cfg;
    if meta
        c.row = struct('set', string(T.set(i)), 'siting', string(T.siting(i)), 'reversed', false, ...
            'path_id', string(T.path_id(i)));
    else
        c.row = struct('set', "", 'siting', "", 'reversed', false, 'path_id', string(T.path_id(i)));
    end
    a = itm_p2p_core_exp(T.htx_m(i), T.hrx_m(i), pfl, T.f_mhz(i), p, S.confidence, S.location, ...
        T.climate(i), T.N_0(i), T.pol(i), S.epsilon, S.sigma, S.mdvar, false, [], c);
    if ~all(isfinite(a)) || ~isreal(a)
        error('itmexp:nonfinite', 'Non-finite loss on %s with the trial constants.', T.link_id(i));
    end
    L(i, :) = a(:)';
end
end

function ok = baseline_ok(T)
if ~ismember('itm_error', T.Properties.VariableNames) || isnumeric(T.itm_error)
    ok = true(height(T), 1);
else
    ok = ismissing(T.itm_error) | T.itm_error == "";
end
end
