function jobs = launch_runs_rev1(tags, overrides, best)
%LAUNCH_RUNS_REV1 Start several evaluator runs at once, one batch job each (B09 tooling).
%   jobs = LAUNCH_RUNS_REV1(tags, overrides, best) submits one
%   run_eval_rev1(Tag=tags(k), Best=best) batch job per experiment. Each
%   job gets its switch settings from the environment variable
%   ITMEXP_OVERRIDES (overrides(k), a JSON object read by params_exp.m), so
%   params_exp.m isn't edited and the runs can go in parallel on the local
%   cluster.
%
%   Inputs:
%     tags       string array of experiment tags, e.g. "901-name"
%     overrides  string array of JSON objects, one per tag, e.g.
%                '{"diffraction":"delta_cascaded_isolated"}'
%     best       tag of the current best run (paired bootstrap reference)
%
%   Before submitting, every override is checked by calling params_exp()
%   with it, so a typo fails here, not inside a job. Jobs are submitted 5 s
%   apart so their final archive refresh (pareto_rev1, inside
%   run_eval_rev1) is less likely to overlap; collect_runs_rev1 rebuilds
%   the archive once after all jobs finish in any case.
%
%   Use collect_runs_rev1(jobs) to wait for and report the results.
arguments
    tags (1,:) string
    overrides (1,:) string
    best (1,1) string
end
if numel(tags) ~= numel(overrides)
    error('itmexp:launch', 'tags and overrides must have the same length.');
end
if numel(unique(tags)) ~= numel(tags)
    error('itmexp:launch', 'Duplicate experiment tags.');
end
P = itm_exp_paths_rev1();
root = char(P.root);
c = parcluster;
if numel(tags) > c.NumWorkers
    error('itmexp:launch', '%d runs but the cluster has %d workers.', numel(tags), c.NumWorkers);
end
old = getenv('ITMEXP_OVERRIDES');
restore = onCleanup(@() setenv('ITMEXP_OVERRIDES', old));
for k = 1:numel(tags)
    if isfolder(fullfile(root, 'experiments', tags(k)))
        error('itmexp:launch', 'experiments/%s already exists; pick a new tag.', tags(k));
    end
    setenv('ITMEXP_OVERRIDES', char(overrides(k)));
    params_exp();                                 % fails loud on a bad override
end
jobs = parallel.Job.empty;
for k = 1:numel(tags)
    setenv('ITMEXP_OVERRIDES', char(overrides(k)));
    jobs(k) = batch(@run_eval_rev1, 1, {"Tag", tags(k), "Best", best}, ...
        'CurrentFolder', root, ...
        'AdditionalPaths', {fullfile(root, 'eval'), fullfile(root, 'itm_variant')}, ...
        'EnvironmentVariables', {'ITMEXP_OVERRIDES'}, ...
        'CaptureDiary', true, 'AutoAddClientPath', false, 'AutoAttachFiles', false);
    if k < numel(tags), pause(5); end
end
setenv('ITMEXP_OVERRIDES', '');
end
