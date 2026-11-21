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
%   Options:
%     Tag        "R01-recalibrated-itm"
%     MaxEvals   40      objective evaluations per fold
%     Seed       1
%     Params     all six; a subset of the field names of params_exp().cal

arguments
    options.Tag (1,1) string = "R01-recalibrated-itm"
    options.MaxEvals (1,1) double = 40
    options.Seed (1,1) double = 1
    options.Params (1,:) string = ["w_const" "afo_scale" "knife_scale" "los_w_scale" "time_minus_scale" "time_plus_scale"]
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
    obj = @(x) objective(x, base_cfg, P2(tr2, :), LT(trl, :), profiles, ids, S);
    rng(options.Seed + k, 'twister');
    res = bayesopt(obj, vars, 'MaxObjectiveEvaluations', options.MaxEvals, 'IsObjectiveDeterministic', true, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0, 'PlotFcn', []);
    x = res.XAtMinObjective;
    cfg = apply(base_cfg, x);
    h2 = ~tr2; hl = ~trl;
    if any(h2), P2.cal_lb_50(h2) = predict(P2(h2, :), profiles, ids, 50, cfg, S); end
    if any(hl)
        V = predict(LT(hl, :), profiles, ids, S.p_all, cfg, S);
        for j = 1:numel(S.p_tags), LT.("cal_lb_" + S.p_tags(j))(hl) = V(:, j); end
    end
    row = x; row.fold = k; row.train_composite = res.MinObjective;
    fits = [fits; row]; %#ok<AGROW>
    fprintf('fold %d of %d: train composite %.2f dB  (%s)\n', k, K, res.MinObjective, ...
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
R.data_version = struct('split_sha', strtrim(string(fileread(fullfile(root, 'data', 'splits', 'folds_rev1.sha256')))), ...
    'datasets', ["phase2" "longterm"]);
lines = [
    sprintf("%s: recalibrated ITM, constants fitted in %d-fold cross-validation (bayesopt, %d evals per fold)", options.Tag, K, options.MaxEvals)
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

function cfg = apply(cfg, x)
for nm = string(x.Properties.VariableNames)
    cfg.cal.(nm) = x.(nm);
end
end

function L = predict(T, profiles, ids, p, cfg, S)
L = NaN(height(T), numel(p));
[~, ip] = ismember(T.path_id, ids);
for i = 1:height(T)
    pr = profiles(ip(i));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    a = itm_p2p_core_exp(T.htx_m(i), T.hrx_m(i), pfl, T.f_mhz(i), p, S.confidence, S.location, ...
        T.climate(i), T.N_0(i), T.pol(i), S.epsilon, S.sigma, S.mdvar, false, [], cfg);
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
