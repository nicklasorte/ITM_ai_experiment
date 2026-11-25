function tests = test_cv_calibrate_smoke_rev1
%TEST_CV_CALIBRATE_SMOKE_REV1 Smoke test: cv_calibrate runs on the current best variant.
%   Runs eval/cv_calibrate_rev1 with Constrained=true and Smoke=true on the
%   switches of the current best run (tag from the environment variable
%   ITMEXP_BEST_TAG, default "707r-rescore-screen36"; switches from that
%   run's metrics.json, cfg.overrides). Passes when every fold's trial
%   at ITM's constants evaluates without throwing (finite composite, no
%   error text). Feasibility per fold is reported, not asserted: a variant
%   may legitimately break a constraint (B28, fold 4).
%
%   Run on the Mac (needs MATLAB, matlab_itm, profiles):
%     results = runtests('eval/tests/test_cv_calibrate_smoke_rev1.m');
%   Takes a few minutes (one variant run and one physics battery per fold).
tests = functiontests(localfunctions);
end

function test_best_variant_evaluates(tc)
P = itm_exp_paths_rev1();
b = string(getenv('ITMEXP_BEST_TAG'));
if b == ""
    b = "707r-rescore-screen36";   % current best as scored (results.tsv row 707); update when best changes
end
if ~isfile(fullfile(P.root, 'experiments', b, 'metrics.json'))
    error('itmexp:test', 'experiments/%s/metrics.json is missing; set ITMEXP_BEST_TAG.', b);
end
m = jsondecode(fileread(fullfile(P.root, 'experiments', b, 'metrics.json')));
ov = '';
if isfield(m, 'cfg') && isfield(m.cfg, 'overrides') && ~isempty(m.cfg.overrides)
    ov = m.cfg.overrides;              % stored as the JSON text that was set in ITMEXP_OVERRIDES
    if isstruct(ov), ov = jsonencode(ov); end
    ov = char(ov);
end
old = getenv('ITMEXP_OVERRIDES');
c = onCleanup(@() setenv('ITMEXP_OVERRIDES', old));
setenv('ITMEXP_OVERRIDES', ov);
R = cv_calibrate_rev1(Tag="smoke-" + b, Constrained=true, Smoke=true);
sm = R.smoke;
fprintf('best run %s: %d of %d folds feasible at ITM''s constants\n', b, nnz(sm.feasible), height(sm));
verifyEqual(tc, sm.error, repmat("", height(sm), 1), 'A trial threw; see R.smoke.error.');
verifyTrue(tc, all(isfinite(sm.train_composite) & sm.train_composite < 1e3), ...
    'A fold returned the failure sentinel composite.');
end
