function G = paired_gain_rev1(newTag, bestTag, options)
%PAIRED_GAIN_REV1 Paired bootstrap of the score gain of one run over another. Read-only.
%   G = PAIRED_GAIN_REV1(newTag, bestTag) reads the stored out-of-fold
%   predictions of two experiments (experiments/<Tag>/predictions_*.csv),
%   resamples paths with replacement within each Phase 2 site and each
%   long-term fold, and scores both runs on every resample with score_rev1.
%   The gain is best minus new, so a positive gain means the new run is
%   better. Experiment D02 found the paired SD between similar models is
%   about 0.3 dB, which is why a fixed threshold alone isn't enough.
%
%   G.full and G.screened hold the point gain, the bootstrap SD, the 95 %
%   interval, and pass = the interval's lower end is above zero.
%   Writes experiments/<newTag>/paired_vs_<bestTag>.txt when Write is true.
%
%   Options:
%     N      500   bootstrap draws
%     Seed   1
%     Write  true

arguments
    newTag (1,1) string
    bestTag (1,1) string
    options.N (1,1) double = 500
    options.Seed (1,1) double = 1
    options.Write (1,1) logical = true
end
P = itm_exp_paths_rev1();
root = P.root;
[A2, AL] = load_run(root, newTag, "a");
[B2, BL] = load_run(root, bestTag, "b");
% Align the two runs on the same links
P2 = innerjoin(A2, B2(:, {'link_id', 'b_lb_50'}), 'Keys', 'link_id');
LT = innerjoin(AL, BL(:, ["link_id", "b_lb_" + settings_rev1().p_tags]), 'Keys', 'link_id');
if height(P2) ~= height(A2) || height(LT) ~= height(AL)
    error('itmexp:paired', '%s and %s were not scored on the same links.', newTag, bestTag);
end

g0 = gains(P2, LT);
rng(options.Seed, 'twister');
gb = NaN(options.N, 2);
for b = 1:options.N
    gb(b, :) = gains(resample(P2, 'set'), resample(LT, 'fold'));
end
names = ["full" "screened"];
for k = 1:2
    q = prctile(gb(:, k), [2.5 97.5]);
    G.(names(k)) = struct('gain', g0(k), 'sd', std(gb(:, k)), 'lo', q(1), 'hi', q(2), 'pass', q(1) > 0);
end
G.new = newTag; G.best = bestTag; G.n = options.N;

lines = [
    sprintf("paired bootstrap: %s vs %s (%d draws, paths resampled within site and fold)", newTag, bestTag, options.N)
    sprintf("  composite gain   %+.2f dB  (SD %.2f; 95%% interval %+.2f to %+.2f)  %s", G.full.gain, G.full.sd, G.full.lo, G.full.hi, verdict(G.full.pass))
    sprintf("  screened gain    %+.2f dB  (SD %.2f; 95%% interval %+.2f to %+.2f)  %s", G.screened.gain, G.screened.sd, G.screened.lo, G.screened.hi, verdict(G.screened.pass))
    "  gain = best minus new; positive means the new run is better"
    ];
fprintf('%s\n', lines);
if options.Write
    writelines(lines, fullfile(root, 'experiments', newTag, "paired_vs_" + bestTag + ".txt"));
end
end

function g = gains(P2, LT)
a = score_rev1(P2, LT, "a");
b = score_rev1(P2, LT, "b");
g = [b.composite - a.composite, b.screened.composite - a.screened.composite];
end

function T = resample(T, group)
% Draw paths with replacement within each group; a path drawn twice gets
% two distinct IDs so score_rev1 weights each copy as a separate path.
out = cell(0, 1);
for gv = unique(T.(group))'
    G = T(T.(group) == gv, :);
    ids = unique(G.path_id);
    pick = ids(randi(numel(ids), numel(ids), 1));
    for j = 1:numel(pick)
        R = G(G.path_id == pick(j), :);
        R.path_id(:) = pick(j) + "#" + j;
        out{end + 1, 1} = R; %#ok<AGROW>
    end
end
T = vertcat(out{:});
end

function [P2, LT] = load_run(root, tag, as)
% Load one run's stored predictions and rename its prediction columns to
% <as>_lb_<p>. run_eval writes var_*, cv_calibrate writes cal_* and cvfold.
S = settings_rev1();
d = fullfile(root, 'experiments', tag);
opts = {'TextType', 'string'};
f2 = fullfile(d, 'predictions_phase2.csv'); fl = fullfile(d, 'predictions_longterm.csv');
if ~isfile(f2) || ~isfile(fl)
    error('itmexp:paired', '%s has no stored predictions.', tag);
end
P2 = readtable(f2, opts{:});
LT = readtable(fl, opts{:});
src = "var";
if ismember('cal_lb_50', P2.Properties.VariableNames), src = "cal"; end
P2 = renamevars(P2, src + "_lb_50", as + "_lb_50");
for t = S.p_tags
    LT = renamevars(LT, src + "_lb_" + t, as + "_lb_" + t);
end
if ~ismember('fold', LT.Properties.VariableNames) && ismember('cvfold', LT.Properties.VariableNames)
    LT = renamevars(LT, 'cvfold', 'fold');
end
P2.censored = logical(P2.censored);
P2.path_id = string(P2.path_id); LT.path_id = string(LT.path_id);
if as == "b"
    P2 = P2(:, {'link_id', 'b_lb_50'});
    LT = LT(:, ["link_id", "b_lb_" + S.p_tags]);
end
end

function s = verdict(ok)
if ok, s = "PASS"; else, s = "not distinguishable from zero"; end
end
