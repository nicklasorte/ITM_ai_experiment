function done = collect_runs_rev1(jobs, wait_s)
%COLLECT_RUNS_REV1 Report the evaluator runs started by launch_runs_rev1 (B09 tooling).
%   done = COLLECT_RUNS_REV1(jobs, wait_s) waits up to wait_s seconds
%   (default 60, to stay inside one MCP call) for the jobs, prints each
%   finished run's summary up to the archive section, prints any error,
%   and returns true when every job has finished. When all are finished it
%   rebuilds the archive once (pareto_rev1), because parallel runs each
%   refresh it at the end and the last writer may have missed a run.
%   Call it again until it returns true.
%
%   A job that errored after its outputs were written (for example in the
%   archive refresh) still has experiments/<tag>/summary.txt; the report
%   says so. Treat any other error as a stop condition.
arguments
    jobs (1,:) parallel.Job
    wait_s (1,1) double = 60
end
t = tic;
while toc(t) < wait_s && ~all(arrayfun(@(j) j.State == "finished" || j.State == "failed", jobs))
    pause(2);
end
P = itm_exp_paths_rev1();
done = true;
for k = 1:numel(jobs)
    j = jobs(k);
    args = j.Tasks(1).InputArguments{3};        % batch stores {fcn, nargout, args, path}
    tag = string(args{2});
    if ~(j.State == "finished" || j.State == "failed")
        fprintf('%s: %s\n', tag, j.State);
        done = false;
        continue
    end
    d = string(j.Tasks(1).Diary);
    i = strfind(d, "experiment archive");
    if isempty(i), fprintf('%s\n', d); else, fprintf('%s\n', extractBefore(d, i(1))); end
    if ~isempty(j.Tasks(1).Error)
        has = isfile(fullfile(P.root, 'experiments', tag, 'summary.txt'));
        fprintf('ERROR in %s: %s (summary.txt written: %d)\n', tag, j.Tasks(1).Error.message, has);
    end
end
if done
    evalc('pareto_rev1();');                       % rebuild quietly; summary is in results/archive_rev1.txt
    fprintf('archive rebuilt after %d runs\n', numel(jobs));
end
end
