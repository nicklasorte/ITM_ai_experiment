function A = pareto_rev1(options)
%PARETO_REV1 Build the experiment archive: Pareto front and MAP-Elites cells. Read-only.
%   A = PARETO_REV1() reads every experiments/*/metrics.json, keeps the runs
%   scored on the current data version, and writes
%     results/archive_rev1.csv   one row per run: objectives, status, front
%                                membership, MAP-Elites cell, elite flag
%     results/archive_rev1.txt   agent-facing summary, rounded to 0.1 dB
%
%   Objectives (all minimized, all held-out):
%     p2_cell     Phase 2 cell-balanced RMS at 50 % time, dB
%     lt_level    long-term level RMS over time percentages, dB
%     lt_shape    long-term shape RMS of (L_p - L_50), dB
%     censor_pct  Phase 2 censored-bound violations, percent
%   A run is on the Pareto front when no other eligible run is at least as
%   good on all four and strictly better on one.
%
%   MAP-Elites archive (Mouret and Clune 2015, arXiv:1504.04909): one cell
%   per combination of model structure (the cfg submodel switches, plus
%   whether ITM's constants were refit) and free-parameter count bin
%   (0, 1-2, 3-5, 6+). Each cell keeps its lowest-composite run: the elite.
%
%   Eligible runs: physics battery passed, all four objectives present, and
%   scored on the current data version (the hash in
%   data/splits/folds_rev1.sha256). Every other run is listed with the
%   reason it was left out; none is dropped silently.
%
%   The archive is for choosing parents and reporting trade-offs. The
%   acceptance rule in FRAMEWORK.md still decides what becomes `best`.
%
%   Options:
%     Write  true

arguments
    options.Write (1,1) logical = true
end
P = itm_exp_paths_rev1();
root = P.root;
current = strtrim(string(fileread(fullfile(root, 'data', 'splits', 'folds_rev1.sha256'))));
files = dir(fullfile(root, 'experiments', '*', 'metrics.json'));
obj = ["p2_cell" "lt_level" "lt_shape" "censor_pct"];

rows = {};
refs = {};
ref_from = "";
ref_date = NaT;
for k = 1:numel(files)
    J = jsondecode(fileread(fullfile(files(k).folder, files(k).name)));
    [~, tag] = fileparts(files(k).folder);
    if isfield(J, 'variant'), m = J.variant;
    elseif isfield(J, 'recalibrated'), m = J.recalibrated;
    else, error('itmexp:archive', '%s: metrics.json has no variant or recalibrated block.', tag);
    end
    r = struct('tag', string(tag));
    o = objectives(m);
    for f = obj, r.(f) = o.(f); end
    r.composite = num(m, 'composite');
    r.physics = "not run";
    if isfield(J, 'physics') && isfield(J.physics, 'pass') && ~isempty(J.physics.pass)
        if islogical(J.physics.pass) || isnumeric(J.physics.pass)
            if J.physics.pass, r.physics = "PASS"; else, r.physics = "FAIL"; end
        end
    end
    r.data_version = "legacy";
    if isfield(J, 'data_version') && isfield(J.data_version, 'split_sha')
        r.data_version = string(J.data_version.split_sha);
    end
    [r.structure, r.n_free] = describe(J);
    r.cell = r.structure + " | " + param_bin(r.n_free);
    % Status
    if r.data_version ~= current
        r.status = "other data version";
    elseif r.physics ~= "PASS"
        r.status = "physics " + lower(r.physics);
    elseif any(isnan([r.p2_cell r.lt_level r.lt_shape r.censor_pct]))
        r.status = "missing objective";
    else
        r.status = "eligible";
    end
    rows{end + 1} = r; %#ok<AGROW>
    % Reference models from the newest current-version run
    d = datetime(files(k).datenum, 'ConvertFrom', 'datenum');
    if r.data_version == current && (isnat(ref_date) || d > ref_date)
        ref_date = d; ref_from = r.tag; refs = {};
        for nm = ["baseline" "p452" "p2001"]
            if isfield(J, nm)
                q = objectives(J.(nm)); q.model = nm; q.composite = num(J.(nm), 'composite');
                refs{end + 1} = q; %#ok<AGROW>
            end
        end
    end
end
if isempty(rows)
    error('itmexp:archive', 'No experiments/*/metrics.json found.');
end
T = struct2table([rows{:}], 'AsArray', true);
el = T.status == "eligible";
X = T{:, cellstr(obj)};

% Pareto front among eligible runs
T.on_front = false(height(T), 1);
T.dominated_by = strings(height(T), 1);
idx = find(el);
for i = idx'
    dom = idx(all(X(idx, :) <= X(i, :), 2) & any(X(idx, :) < X(i, :), 2));
    if isempty(dom)
        T.on_front(i) = true;
    else
        T.dominated_by(i) = strjoin(T.tag(dom), ";");
    end
end

% MAP-Elites: lowest composite per cell
T.elite = false(height(T), 1);
for c = unique(T.cell(el))'
    in = find(el & T.cell == c);
    [~, j] = min(T.composite(in));
    T.elite(in(j)) = true;
end

% References: which front runs dominate each reference model
R = table();
for i = 1:numel(refs)
    q = refs{i};
    v = [q.p2_cell q.lt_level q.lt_shape q.censor_pct];
    beat = T.on_front & all(X <= v, 2) & any(X < v, 2);
    R = [R; table(q.model, q.composite, q.p2_cell, q.lt_level, q.lt_shape, q.censor_pct, ...
        strjoin(T.tag(beat), ";"), 'VariableNames', ...
        ["model" "composite" obj "dominated_by_front"])]; %#ok<AGROW>
end

A = struct('runs', T, 'references', R, 'data_version', current, 'references_from', ref_from);
if ~options.Write
    return
end

out = fullfile(root, 'results');
writetable(T(:, ["tag" "status" "composite" obj "physics" "on_front" "dominated_by" ...
    "structure" "n_free" "cell" "elite" "data_version"]), fullfile(out, 'archive_rev1.csv'));

r1 = @(x) round(x, 1);
L = [
    sprintf("experiment archive (data version %s)", extractBefore(current + "            ", 13))
    sprintf("objectives, all minimized: Phase 2 cell RMS | long-term level RMS | long-term shape RMS | censored violations %%")
    ""
    "Pareto front (eligible runs no other run beats on all four):"
    ];
front = T(T.on_front, :);
front = sortrows(front, 'composite');
for i = 1:height(front)
    L(end + 1) = sprintf("  %-34s composite %5.1f | %5.1f %5.1f %5.1f %5.1f%%   cell: %s", front.tag(i), ...
        r1(front.composite(i)), r1(front.p2_cell(i)), r1(front.lt_level(i)), r1(front.lt_shape(i)), ...
        r1(front.censor_pct(i)), front.cell(i)); %#ok<AGROW>
end
if isempty(front), L(end + 1) = "  (none yet)"; end
L(end + 1) = "";
L(end + 1) = "MAP-Elites cells (structure | free parameters): elite by composite";
E = sortrows(T(T.elite, :), 'composite');
for i = 1:height(E)
    L(end + 1) = sprintf("  %-50s %s (%.1f)", E.cell(i), E.tag(i), r1(E.composite(i))); %#ok<AGROW>
end
if isempty(E), L(end + 1) = "  (none yet)"; end
L(end + 1) = "";
L(end + 1) = sprintf("Reference models (from %s):", ref_from);
for i = 1:height(R)
    b = R.dominated_by_front(i); if b == "", b = "no front run"; end
    L(end + 1) = sprintf("  %-8s composite %5.1f | %5.1f %5.1f %5.1f %5.1f%%   beaten on all four by: %s", ...
        R.model(i), r1(R.composite(i)), r1(R.p2_cell(i)), r1(R.lt_level(i)), r1(R.lt_shape(i)), ...
        r1(R.censor_pct(i)), b); %#ok<AGROW>
end
L(end + 1) = "";
L(end + 1) = "Not eligible:";
ne = T(~el, :);
for i = 1:height(ne)
    L(end + 1) = sprintf("  %-34s %s", ne.tag(i), ne.status(i)); %#ok<AGROW>
end
if isempty(ne), L(end + 1) = "  (none)"; end
writelines(L, fullfile(out, 'archive_rev1.txt'));
fprintf('%s\n', L);
end

function o = objectives(m)
o.p2_cell = NaN; o.censor_pct = NaN; o.lt_level = NaN; o.lt_shape = NaN;
if isfield(m, 'p2') && ~isempty(m.p2)
    o.p2_cell = num(m.p2, 'cell');
    o.censor_pct = num(m.p2, 'censored_violation_pct');
end
if isfield(m, 'lt') && ~isempty(m.lt)
    o.lt_level = num(m.lt, 'level');
    o.lt_shape = num(m.lt, 'shape');
end
end

function x = num(s, f)
x = NaN;
if isstruct(s) && isfield(s, f) && isnumeric(s.(f)) && isscalar(s.(f))
    x = double(s.(f));
end
end

function [key, n] = describe(J)
% Structure key from the submodel switches; free parameters from the
% refit constants (cv_calibrate) or the cal constants that differ from ITM.
sw = ["diffraction" "line_of_sight" "troposcatter" "effective_height" "variability"];
cfg = struct();
if isfield(J, 'cfg'), cfg = J.cfg; end
parts = strings(1, numel(sw));
for i = 1:numel(sw)
    if isfield(cfg, sw(i)), parts(i) = string(cfg.(sw(i))); else, parts(i) = "itm"; end
end
n = 0;
refit = false;
if isfield(J, 'median_params')
    n = numel(fieldnames(J.median_params));
    refit = true;
elseif isfield(cfg, 'cal')
    itm = struct('w_const', 25.1, 'afo_scale', 1, 'knife_scale', 1, 'los_w_scale', 1, ...
        'time_minus_scale', 1, 'time_plus_scale', 1);    % ITM values (params_exp.m)
    for f = string(fieldnames(cfg.cal))'
        if ~isfield(itm, f) || abs(cfg.cal.(f) - itm.(f)) > 1e-12
            n = n + 1; refit = true;
        end
    end
end
if isfield(cfg, 'n_free_params'), n = cfg.n_free_params; end
key = strjoin(parts, "/");
if refit, key = key + " +refit"; end
end

function b = param_bin(n)
if n == 0, b = "0";
elseif n <= 2, b = "1-2";
elseif n <= 5, b = "3-5";
else, b = "6+";
end
end
