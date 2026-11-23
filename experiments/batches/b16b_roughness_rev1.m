function S = b16b_roughness_rev1(out_dir)
%B16B_ROUGHNESS_REV1 Terrain irregularity (delta h) estimator audit, model only (B16b).
%   S = B16B_ROUGHNESS_REV1(out_dir) runs the registered B16b design
%   (experiments/batches/B16.md; research review item 4, H04) on every
%   Phase 2 profile and writes per_path.csv and summary.txt to out_dir.
%   No scores and no measured loss are read.
%
%   Estimator (ITM v1.4 QuickPfl and the d1thx routine; Hufford, Longley
%   and Kissick, NTIA TR-82-100): within the trim [d_s, d_e], resample the
%   profile at n evenly spaced points (n = 10 p10 - 5, p10 = 4..25), fit a
%   least-squares line, and take the interdecile range of the residuals,
%   divided by 1 - 0.8 exp(-(d_e - d_s)/50 km). Spans shorter than two
%   profile intervals give 0 (kept as a separate control).
%   The legacy code here is a copy of compute_delta_h and find_horizons
%   from itm_variant/itm_p2p_core_exp.m; it must reproduce the core's
%   info.delta_h_m exactly on every path, or the script errors.
%
%   Continuous estimator (review item 4 definition): exact segment
%   integrals of the piecewise-linear profile for the line fit, and the
%   10th and 90th percentiles as generalized inverses of the
%   distance-weighted residual CDF (a nonflat segment spreads its length
%   uniformly over its residual range; a flat one is a point mass).
%   The 2 x 2: detrending {legacy, continuous} x quantiles {legacy,
%   distance-weighted}.
%
%   Invariance tests, trim held fixed in metres (estimator only), and
%   end to end (trim recomputed, through the core's info.delta_h_m):
%   collinear refinement (every interval split in 2 and in 3), reversal
%   (profile and antennas swapped), affine tilt (z + 50 m + 0.01 x, fixed
%   trim only, because a tilt moves the horizons). Analytic profiles: a
%   sinusoid over whole periods (interdecile range 2 sin(0.4 pi) A, from
%   the arcsine distribution) and a profile of flat terraces.

P = itm_exp_paths_rev1(); St = settings_rev1();
if ~isfolder(out_dir), mkdir(out_dir); end
profiles = load_profiles_rev1(P.root); ids = string({profiles.path_id});
T2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
[pids, ia] = unique(T2.path_id, 'stable');
c0 = params_exp();
n = numel(pids);
V = NaN(n, 16);
for i = 1:n
    r = T2(ia(i), :);
    pr = profiles(ids == pids(i));
    if isempty(pr), error('itmexp:b16b', 'Missing profile %s.', pids(i)); end
    g = pr.h_m(:); xi = pr.spacing_m; np = numel(g) - 1;
    pfl = [np; xi; g]; h = [r.htx_m r.hrx_m];
    a_e = a_e_of(pfl, h, r, St, c0);
    [ds, de] = trim(pfl, a_e, h);
    dh_core = core_dh(pfl, h, r, St, c0);
    dh_leg = legacy_dh(pfl, ds, de);
    if dh_leg ~= dh_core
        error('itmexp:b16b', 'Legacy copy differs from the core on %s (%.17g vs %.17g).', pids(i), dh_leg, dh_core);
    end
    % 2 x 2
    [~, ~, LL, LC, CL, CC] = two_by_two(pfl, ds, de);
    % refinement (fixed trim, and end to end)
    p2 = refine(pfl, 2); p3 = refine(pfl, 3);
    f2 = legacy_dh(p2, ds, de) - dh_leg; f3 = legacy_dh(p3, ds, de) - dh_leg;
    e2 = core_dh(p2, h, r, St, c0) - dh_core; e3 = core_dh(p3, h, r, St, c0) - dh_core;
    [~, ~, ~, ~, ~, CC2] = two_by_two(p2, ds, de); cc2 = CC2 - CC;
    % reversal
    pr_ = [np; xi; flipud(g)];
    frv = legacy_dh(pr_, pfl(1) * xi - de, pfl(1) * xi - ds) - dh_leg;
    erv = core_dh(pr_, fliplr(h), r, St, c0) - dh_core;
    % affine tilt, fixed trim
    x = (0:np)' * xi;
    ftl = legacy_dh([np; xi; g + 50 + 0.01 * x], ds, de) - dh_leg;
    V(i, :) = [dh_leg LL LC CL CC f2 f3 e2 e3 frv erv ftl cc2 ds de (de - ds) / xi];
end
W = array2table(V, 'VariableNames', ["dh_legacy" "LL" "LC" "CL" "CC" "fix_refine2" "fix_refine3" ...
    "e2e_refine2" "e2e_refine3" "fix_reverse" "e2e_reverse" "fix_tilt" "CC_refine2" "d_start_m" "d_end_m" "span_intervals"]);
W = [table(pids, T2.set(ia), 'VariableNames', ["path_id" "set"]) W];
writetable(W, fullfile(out_dir, 'per_path.csv'));
S.per_path = W;

fid = fopen(fullfile(out_dir, 'summary.txt'), 'w');
cleanup = onCleanup(@() fclose(fid));
out = @(varargin) both(fid, varargin{:});
out('B16b terrain irregularity audit. %d Phase 2 paths. Generated %s.\n', n, string(datetime('now'), 'yyyy-MM-dd HH:mm'));
out('Legacy copy reproduces the core''s delta h exactly on all %d paths.\n', n);
out('Short-span rule (fewer than 2 intervals, delta h = 0): %d paths.\n', nnz(W.span_intervals < 2));
out('\nInvariance, |change in delta h| (m): max, 99th percentile, paths over 0.01 m\n');
cols = ["fix_refine2" "fix_refine3" "fix_reverse" "fix_tilt" "e2e_refine2" "e2e_refine3" "e2e_reverse" "CC_refine2"];
for c = cols
    a = abs(W.(c));
    out('  %-12s %10.3g %10.3g %5d\n', c, max(a), prctile(a, 99), nnz(a > 0.01));
end
out('\n2 x 2 relative to legacy (LL), (X - LL)/LL in %%, by set: median, 5th and 95th percentiles\n');
for s = ["all" unique(W.set)']
    m = W.dh_legacy > 0;
    if s ~= "all", m = m & W.set == s; end
    out('  %-4s n=%3d', s, nnz(m));
    for c = ["LC" "CL" "CC"]
        q = 100 * (W.(c)(m) - W.LL(m)) ./ W.LL(m);
        out('  %s %6.2f [%6.2f %6.2f]', c, median(q), prctile(q, 5), prctile(q, 95));
    end
    out('\n');
end
% analytic profiles
out('\nAnalytic profiles (fixed trim = whole path):\n');
xi = 30; L = 30000; x = (0:xi:L)'; A = 40;
for Pm = [1000 3000 7500]
    z = 1000 + A * sin(2 * pi * x / Pm);
    p = [numel(x) - 1; xi; z];
    corr = 1 - 0.8 * exp(-L / 50e3);
    truth = 2 * sin(0.4 * pi) * A / corr;
    [~, ~, LLa, ~, ~, CCa] = two_by_two(p, 0, L);
    out('  sinusoid A = %g m, period %5g m: truth %.3f, legacy %.3f, continuous %.3f m\n', A, Pm, truth, LLa, CCa);
end
z = 1000 + 20 * floor(x / 2000) + 0 * x;        % terraces: 2 km flat steps of 20 m, joined by one 30 m interval
p = [numel(x) - 1; xi; z];
[~, ~, LLt, LCt, CLt, CCt] = two_by_two(p, 0, L);
out('  terraces (flat 2 km steps of 20 m): LL %.3f, LC %.3f, CL %.3f, CC %.3f m\n', LLt, LCt, CLt, CCt);
end

% ------------------------------------------------------------------------
function a_e = a_e_of(pfl, h, r, St, c0)
[~, info] = itm_p2p_core_exp(h(1), h(2), pfl, r.f_mhz, 50, St.confidence, St.location, r.climate, r.N_0, ...
    r.pol, St.epsilon, St.sigma, St.mdvar, true, [], c0);
a_e = 1 / (157e-9 * (1 - 0.04665 * exp(info.N_s / 179.3)));   % ITM v1.4 InitializePointToPoint
end

function dh = core_dh(pfl, h, r, St, c0)
[~, info] = itm_p2p_core_exp(h(1), h(2), pfl, r.f_mhz, 50, St.confidence, St.location, r.climate, r.N_0, ...
    r.pol, St.epsilon, St.sigma, St.mdvar, true, [], c0);
dh = info.delta_h_m;
end

function [ds, de] = trim(pfl, a_e, h)
% QuickPfl trim, from itm_p2p_core_exp quick_pfl
d = pfl(1) * pfl(2);
[~, dz] = find_horizons(pfl, a_e, h);
ds = min(15.0 * h(1), 0.1 * dz(1));
de = d - min(15.0 * h(2), 0.1 * dz(2));
end

function p = refine(pfl, k)
% Collinear refinement: every interval split into k equal parts on the same straight segments
np = pfl(1); xi = pfl(2); g = pfl(3:end);
x = (0:np)' * xi; xr = (0:k * np)' * (xi / k);
xr(end) = x(end);
p = [k * np; xi / k; interp1(x, g, xr)];
end

function [line_l, line_c, LL, LC, CL, CC] = two_by_two(pfl, ds, de)
% The four estimators. Line coefficients are in metres versus distance (m).
corr = 1.0 - 0.8 * exp(-(de - ds) / 50e3);
[xs, zs] = legacy_samples(pfl, ds, de);
if isempty(xs)
    line_l = [NaN NaN]; line_c = line_l; LL = 0; LC = 0; CL = 0; CC = 0;
    return
end
line_l = legacy_line(xs, zs);
[xv, zv] = clip_profile(pfl, ds, de);
line_c = continuous_line(xv, zv);
LL = legacy_dh(pfl, ds, de);
LC = weighted_idr(xv, zv - polyval(line_l, xv)) / corr;
CL = sample_idr(zs - polyval(line_c, xs), numel(xs)) / corr;
CC = weighted_idr(xv, zv - polyval(line_c, xv)) / corr;
end

function [xs, zs] = legacy_samples(pfl, ds, de)
% Positions (m) and values of compute_delta_h's resampled points
x_start = ds / pfl(2); x_end = de / pfl(2);
if x_end - x_start < 2.0, xs = []; zs = []; return, end
p10 = min(max(4, fix(0.1 * (x_end - x_start + 8.0))), 25);
n = 10 * p10 - 5;
[zs, ~] = resample_legacy(pfl, x_start, x_end, n);
xs = linspace(ds, de, n)';
end

function c = legacy_line(xs, zs)
% compute_delta_h's least-squares line (trapezoidal end weights) in metres
n = numel(xs);
s = [n - 1; 1.0; zs];
[y1, y2] = lls(s, 0.0, n - 1);
c = [(y2 - y1) / (xs(end) - xs(1)), y1 - (y2 - y1) / (xs(end) - xs(1)) * xs(1)];
end

function [xv, zv] = clip_profile(pfl, ds, de)
% Vertices of the piecewise-linear profile on [ds, de]
np = pfl(1); xi = pfl(2); g = pfl(3:end);
x = (0:np)' * xi;
in = x > ds & x < de;
xv = [ds; x(in); de];
zv = [interp1(x, g, ds); g(in); interp1(x, g, de)];
end

function c = continuous_line(xv, zv)
% Least-squares line minimizing the integral of the squared residual of
% the piecewise-linear profile, by exact segment integrals
x0 = xv(1:end - 1); x1 = xv(2:end); z0 = zv(1:end - 1); z1 = zv(2:end);
Lseg = x1 - x0;
I1 = sum(Lseg);
Ix = sum((x1.^2 - x0.^2) / 2);
Ixx = sum((x1.^3 - x0.^3) / 3);
Iz = sum(Lseg .* (z0 + z1) / 2);
Ixz = sum(Lseg .* (x0 .* (2 * z0 + z1) + x1 .* (z0 + 2 * z1)) / 6);
b = [Ixx Ix; Ix I1] \ [Ixz; Iz];
c = b';
end

function idr = weighted_idr(xv, rv)
% Interdecile range of the distance-weighted residual CDF (generalized inverse)
q = @(p) ginv(xv, rv, p);
idr = q(0.9) - q(0.1);
end

function y = ginv(xv, rv, p)
% inf{y : F(y) >= p}, F the distance-weighted CDF of the piecewise-linear residual
r0 = rv(1:end - 1); r1 = rv(2:end); w = diff(xv); W = sum(w);
lo = min(r0, r1); hi = max(r0, r1);
F = @(y) sum(w .* ((hi > lo) .* min(max((y - lo) ./ max(hi - lo, realmin), 0), 1) + (hi == lo) .* (y >= lo))) / W;
a = min(lo); b = max(hi);
if F(a) >= p, y = a; return, end
for it = 1:200                              % bisection to a few ulps
    m = (a + b) / 2;
    if F(m) >= p, b = m; else, a = m; end
    if b - a <= 4 * eps(max(abs([a b])) + 1), break, end
end
y = b;
end

function idr = sample_idr(diffs, n)
% compute_delta_h's quantiles of n resampled residuals
p10 = (n + 5) / 10; p90 = n - p10;
s = sort(diffs, 'descend');
idr = s(p10) - s(p90 + 1);
end

% ---- copies of the core's routines (itm_variant/itm_p2p_core_exp.m) -------
function delta_h_m = legacy_dh(pfl, d_start_m, d_end_m)
x_start = d_start_m / pfl(2); x_end = d_end_m / pfl(2);
if x_end - x_start < 2.0, delta_h_m = 0; return, end
p10 = min(max(4, fix(0.1 * (x_end - x_start + 8.0))), 25);
n = 10 * p10 - 5; p90 = n - p10; np_s = n - 1;
s3 = resample_legacy(pfl, x_start, x_end, n);
s = [np_s; 1.0; s3];
[fit_y1, fit_y2] = lls(s, 0.0, np_s);
fit_y2 = (fit_y2 - fit_y1) / np_s;
fit_line = cumsum([fit_y1; repmat(fit_y2, n - 1, 1)]);
sorted = sort(s3 - fit_line, 'descend');
delta_h_m = (sorted(p10) - sorted(p90 + 1)) / (1.0 - 0.8 * exp(-(d_end_m - d_start_m) / 50e3));
end

function [z, idx] = resample_legacy(pfl, x_start, x_end, n)
np = fix(pfl(1)); np_s = n - 1;
step = (x_end - x_start) / np_s;
i = fix(x_start);
x_start = x_start - double(single(i + 1.0));
idx = zeros(n, 1); pos = zeros(n, 1);
for j = 1:n
    if x_start > 0.0
        m = min(ceil(x_start), np - 1 - i);
        if m > 0, x_start = x_start - m; i = i + m; end
    end
    idx(j) = i; pos(j) = x_start; x_start = x_start + step;
end
z_hi = pfl(idx + 4);
z = z_hi + (z_hi - pfl(idx + 3)) .* pos;
end

function [fit_y1, fit_y2] = lls(pfl, d_start, d_end)
np = fix(pfl(1));
i_start = fix(max(d_start / pfl(2), 0)); i_end = np - fix(max(np - d_end / pfl(2), 0));
if i_end <= i_start
    i_start = fix(max(i_start - 1, 0)); i_end = np - fix(max(np - (i_end + 1), 0));
end
x_length = i_end - i_start; mid = i_end - 0.5 * x_length;
y_s = pfl(i_start + 3); y_e = pfl(i_end + 3);
inner = pfl((i_start + 1:i_end - 1) + 3);
m = -0.5 * x_length + (1:x_length - 1)';
acc_y = cumsum([0.5 * (y_s + y_e); inner]);
acc_s = cumsum([0.5 * (y_s - y_e) * (-0.5 * x_length); inner .* m]);
sum_y = acc_y(end) / x_length;
ss = acc_s(end) * 12.0 / ((x_length * x_length + 2.0) * x_length);
fit_y1 = sum_y - ss * mid; fit_y2 = sum_y + ss * (np - mid);
end

function [theta_hzn, d_hzn_m] = find_horizons(pfl, a_e, h_m)
np = fix(pfl(1)); xi = pfl(2); d_m = pfl(1) * pfl(2);
z_tx = pfl(3) + h_m(1); z_rx = pfl(np + 3) + h_m(2);
theta_hzn = [(z_rx - z_tx) / d_m - d_m / (2 * a_e), -(z_rx - z_tx) / d_m - d_m / (2 * a_e)];
d_hzn_m = [d_m, d_m];
if np < 2, return, end
d_tx = cumsum(repmat(xi, np - 1, 1));
d_rx = cumsum([d_m; repmat(-xi, np - 1, 1)]); d_rx = d_rx(2:end);
z = pfl((1:np - 1)' + 3);
[theta_tx, i_tx] = max((z - z_tx) ./ d_tx - d_tx / (2 * a_e));
[theta_rx, i_rx] = max(-(z_rx - z) ./ d_rx - d_rx / (2 * a_e));
if theta_tx > theta_hzn(1), theta_hzn(1) = theta_tx; d_hzn_m(1) = d_tx(i_tx); end
if theta_rx > theta_hzn(2), theta_hzn(2) = theta_rx; d_hzn_m(2) = d_rx(i_rx); end
end

function both(fid, varargin)
fprintf(varargin{:}); fprintf(fid, varargin{:});
end
