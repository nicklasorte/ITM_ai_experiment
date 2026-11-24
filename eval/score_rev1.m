function R = score_rev1(P2, LT, predcol, options)
%SCORE_REV1 Score predictions against the measurements. Read-only.
%   R = SCORE_REV1(P2, LT, predcol) scores one model on the Phase 2 table
%   P2 (one row per link, 50 % time) and the long-term table LT (one row
%   per measured time distribution). predcol names the prediction columns:
%   P2.(predcol + "_lb_50") and LT.(predcol + "_lb_<p>"), for example
%   "itm", "var", "p452", "p2001".
%
%   Error is predicted minus measured basic transmission loss (dB).
%   Each path gets a total weight of 1, split evenly over its rows. Rows
%   are grouped into cells; each cell's weighted RMS counts equally.
%
%   Phase 2 cells: site (R1, R2, R3, VA) x frequency band.
%   Long-term cells: frequency band x distance class.
%
%   Scores (dB, lower is better):
%     R.p2.cell     Phase 2 cell-balanced RMS at 50 % time
%     R.lt.level    long-term level error, mean over p in settings p_scored
%     R.lt.shape    long-term shape error (L_p - L_50), mean over p ~= 50
%     R.composite   mean of the three; the number the agent climbs
%     R.screened    the same long-term scores and composite with the rows in
%                   data/links/longterm_screen_rev1.csv left out (record says
%                   line of sight, 30 m profile is blocked; experiment D01).
%                   A kept change must improve both composites
%                   (FRAMEWORK.md, acceptance rule).
%
%   Options: Round (0) rounds the reported scores to this step, used for
%   the agent-facing summary (FRAMEWORK.md, reusable-holdout rule).
%   Screen (true) also computes R.screened.

arguments
    P2 table
    LT table
    predcol (1,1) string
    options.Round (1,1) double = 0
    options.Screen (1,1) logical = true
end
S = settings_rev1();
R = struct('model', predcol);

% ---------------- Phase 2 ----------------
pred = P2.(predcol + "_lb_50");
meas = P2.meas_lb_db;
use = ~P2.censored & isfinite(pred);
e = pred(use) - meas(use);
w = path_weights(P2.path_id(use));
band = discretize(P2.f_mhz(use), S.band_edges_mhz);
site = P2.set(use);
[cells, cell_rms, cell_n] = cell_scores(e, w, site + "|" + S.band_names(band)');
R.p2 = struct('cell', mean(cell_rms), 'worst_cell', max(cell_rms), ...
    'row_rms', rms(e), 'row_mean', mean(e), 'path_rms', sqrt(sum(w .* e .^ 2) / sum(w)), ...
    'n_rows', numel(e), 'n_paths', numel(unique(P2.path_id(use))), 'coverage', mean(isfinite(pred(~P2.censored))));
R.p2.cells = table(cells, cell_rms, cell_n, 'VariableNames', {'cell', 'rms_db', 'n'});
for s = unique(site)'
    k = site == s;
    R.p2.site.(s) = struct('rms', sqrt(sum(w(k) .* e(k) .^ 2) / sum(w(k))), 'mean', sum(w(k) .* e(k)) / sum(w(k)), 'n', nnz(k));
end
c = P2.censored & isfinite(pred);
R.p2.censored_violation_pct = 100 * mean(pred(c) < meas(c));
% Report only (E2, 2026-11-24): censored rows scored as lower bounds. A
% censored row's error is min(0, predicted - bound): zero when the
% prediction is at or above the bound, the shortfall when below. Phase 2
% cell RMS over detected and censored rows together, path weights and cells
% as above; and the mean depth of a violation.
ub = isfinite(pred) & (use | c);
eb = pred(ub) - meas(ub);
cb = P2.censored(ub) ~= 0;
eb(cb) = min(eb(cb), 0);
wb = path_weights(P2.path_id(ub));
bb = discretize(P2.f_mhz(ub), S.band_edges_mhz);
sb = P2.set(ub);
[~, cell_rms_b] = cell_scores(eb, wb, sb + "|" + S.band_names(bb)');
R.p2.cell_with_bounds = mean(cell_rms_b);
for s = unique(sb)'
    k = sb == s;
    R.p2.site_with_bounds.(s) = sqrt(sum(wb(k) .* eb(k) .^ 2) / sum(wb(k)));
end
short = meas(c) - pred(c);
R.p2.censored_violation_depth_db = mean(short(short > 0));
if ~any(short > 0), R.p2.censored_violation_depth_db = 0; end

% ---------------- Long-term ----------------
if isempty(LT)
    R.lt = struct('level', NaN, 'shape', NaN);
    R.composite = R.p2.cell;
else
    band = discretize(LT.f_mhz, S.lt_band_edges_mhz);
    dist = discretize(LT.d_km, S.lt_dist_edges_km);
    cellname = S.lt_band_names(band)' + "|" + S.lt_dist_names(dist)';
    lvl = NaN(1, numel(S.p_scored)); shp = NaN(1, numel(S.p_scored));
    p50 = S.p_tags(S.p_all == 50);
    for j = 1:numel(S.p_scored)
        tag = S.p_tags(S.p_all == S.p_scored(j));
        pr = LT.(predcol + "_lb_" + tag); me = LT.("meas_lb_" + tag);
        k = isfinite(pr) & isfinite(me);
        if nnz(k) == 0, continue, end
        [~, cr] = cell_scores(pr(k) - me(k), path_weights(LT.path_id(k)), cellname(k));
        lvl(j) = mean(cr);
        R.lt.level_by_p.("p" + tag) = mean(cr);
        if S.p_scored(j) ~= 50
            pr0 = LT.(predcol + "_lb_" + p50); me0 = LT.("meas_lb_" + p50);
            k2 = k & isfinite(pr0) & isfinite(me0);
            if nnz(k2) == 0, continue, end
            es = (pr(k2) - pr0(k2)) - (me(k2) - me0(k2));
            [~, cr2] = cell_scores(es, path_weights(LT.path_id(k2)), cellname(k2));
            shp(j) = mean(cr2);
            R.lt.shape_by_p.("p" + tag) = mean(cr2);
        end
    end
    R.lt.level = mean(lvl, 'omitnan');
    R.lt.shape = mean(shp(S.p_scored ~= 50), 'omitnan');
    R.lt.n_rows = height(LT); R.lt.n_paths = numel(unique(LT.path_id));
    % Per-fold level RMS at 50 % (folds are receiver-site groups)
    pr = LT.(predcol + "_lb_" + p50); me = LT.("meas_lb_" + p50); k = isfinite(pr) & isfinite(me);
    for f = unique(LT.fold(k))'
        kk = k & LT.fold == f;
        ww = path_weights(LT.path_id(kk)); ee = pr(kk) - me(kk);
        R.lt.fold.("f" + f) = struct('rms50', sqrt(sum(ww .* ee .^ 2) / sum(ww)), 'mean50', sum(ww .* ee) / sum(ww), 'n', nnz(kk));
    end
    R.composite = mean([R.p2.cell, R.lt.level, R.lt.shape], 'omitnan');
end

if options.Screen && ~isempty(LT)
    drop = ismember(string(LT.link_id), screen_list());
    Q = score_rev1(P2, LT(~drop, :), predcol, Screen=false);
    R.screened = struct('n_dropped', nnz(drop), 'lt_level', Q.lt.level, 'lt_shape', Q.lt.shape, ...
        'composite', Q.composite);
end

if options.Round > 0
    rnd = @(x) options.Round * round(x / options.Round);
    R.composite = rnd(R.composite); R.p2.cell = rnd(R.p2.cell); R.lt.level = rnd(R.lt.level); R.lt.shape = rnd(R.lt.shape);
    if isfield(R, 'screened')
        R.screened.composite = rnd(R.screened.composite);
        R.screened.lt_level = rnd(R.screened.lt_level); R.screened.lt_shape = rnd(R.screened.lt_shape);
    end
end
end

function w = path_weights(ids)
[~, ~, g] = unique(ids);
n = accumarray(g, 1);
w = 1 ./ n(g);
end

function [names, r, n] = cell_scores(e, w, cellname)
[names, ~, g] = unique(cellname);
r = sqrt(accumarray(g, w .* e .^ 2) ./ accumarray(g, w));
n = accumarray(g, 1);
end

function ids = screen_list()
% Link IDs left out of the screened scores. Fixed on 2026-11-21 (D01) by a
% rule set before any experiment: the record gives path type LOS and the
% 30 m profile blocks the 4/3-earth ray between the antennas. Hash-checked.
persistent cache
if isempty(cache)
    root = fileparts(fileparts(mfilename('fullpath')));
    f = fullfile(root, 'data', 'links', 'longterm_screen_rev1.csv');
    want = strtrim(string(fileread(fullfile(root, 'data', 'links', 'longterm_screen_rev1.sha256'))));
    fid = fopen(f, 'r'); b = fread(fid, Inf, '*uint8'); fclose(fid);
    md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
    got = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
    if got ~= want
        error('itmexp:screen', 'data/links/longterm_screen_rev1.csv does not match its hash.');
    end
    T = readtable(f, 'TextType', 'string', 'Delimiter', ',', 'ReadVariableNames', true);
    if ~ismember('link_id', T.Properties.VariableNames) || height(T) == 0
        error('itmexp:screen', 'The screen list has no link_id column or no rows.');
    end
    cache = T.link_id;
end
ids = cache;
end
