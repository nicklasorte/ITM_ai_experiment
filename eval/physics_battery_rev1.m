function B = physics_battery_rev1(cfg, P2, profiles)
%PHYSICS_BATTERY_REV1 Sanity checks every variant must pass before it is scored. Read-only.
%   B = PHYSICS_BATTERY_REV1(cfg, P2, profiles) runs the variant
%   (itm_p2p_core_exp with cfg) and the baseline (public itm_p2p_rev1)
%   side by side on synthetic sweeps and a fixed sample of real links, and
%   passes the variant only if it is no worse than the baseline by more
%   than a stated margin. Baseline ITM is itself not perfectly reciprocal
%   or smooth, so the checks are relative to it.
%
%   Checks:
%     finite        all outputs finite and real
%     continuity    largest step between neighboring points of a
%                   distance, frequency, or height sweep: variant <= baseline + 1 dB
%     height_gain   receiver-height sweep over a ridge (1 to 30 m): net change
%                   in loss from the lowest to the highest receiver,
%                   variant <= max(baseline, 0) + 1 dB. Loss must not grow
%                   as the antenna rises; measured Phase 2 loss falls about
%                   9 dB from 1 m to 8 m receivers (B06 reviewer pass;
%                   added with Nick's approval, 2026-11-21)
%     height_gain_real  every Phase 2 row, each antenna raised by 10 m in turn:
%                   the variant's change in loss minus the larger of stock's
%                   change and 0, worst row: <= 1 dB. Relative to stock
%                   because two-ray interference makes loss rise with height
%                   on many line-of-sight rows in stock ITM too (6,799 of
%                   16,805 rows by more than 1 dB). Catches loss jumps that
%                   the one-ridge synthetic sweep can't, such as a principal
%                   edge switching in a multi-edge method (707: 51.7 dB).
%                   Added with Nick's approval, 2026-11-22.
%     reciprocity   swap the terminals and reverse the profile; 95th
%                   percentile of |difference| on 300 real links:
%                   variant <= max(0.1, baseline + 0.1) dB
%     two_ray_bound loss never more than 6.1 dB below free space on the real
%                   links (two-ray gain limit), or below the baseline minimum
%
%   B.pass is true only if every check passes. B.checks holds the numbers.

S = settings_rev1();
B = struct('pass', true, 'checks', struct());
% cfg.row: row metadata (see run_eval_rev1). Synthetic sweeps have none.
norow = struct('set', "", 'siting', "", 'reversed', false);
cfg.row = norow;
fvar = @(htx, hrx, pfl, f, clim, n0, pol) itm_p2p_core_exp(htx, hrx, pfl, f, 50, S.confidence, ...
    S.location, clim, n0, pol, S.epsilon, S.sigma, S.mdvar, false, [], cfg);
fvar_row = @(htx, hrx, pfl, f, clim, n0, pol, row) itm_p2p_core_exp(htx, hrx, pfl, f, 50, S.confidence, ...
    S.location, clim, n0, pol, S.epsilon, S.sigma, S.mdvar, false, [], setfield(cfg, 'row', row)); %#ok<SFLD>
fbase = @(htx, hrx, pfl, f, clim, n0, pol) itm_p2p_rev1(htx, hrx, pfl, f, 50, confidence=S.confidence, ...
    climate=clim, N_0=n0, polarization=pol, epsilon=S.epsilon, sigma=S.sigma, mdvar=S.mdvar, validity="off");

% ---- synthetic sweeps ----
step = 30;
flat = @(d_km) zeros(round(d_km * 1000 / step) + 1, 1);
ridge = @(d_km) ridge_profile(d_km, step, 150);
rough = @(d_km) rough_profile(d_km, step);
mk = @(h) [numel(h) - 1; step; h(:)];
sweeps = struct('name', {}, 'x', {}, 'fun', {});
d = 2:0.5:150;
sweeps(end + 1) = struct('name', "distance_flat", 'x', d, 'fun', @(x, m) m(10, 10, mk(flat(x)), 3000, 5, 301, 0));
sweeps(end + 1) = struct('name', "distance_ridge", 'x', d, 'fun', @(x, m) m(10, 10, mk(ridge(x)), 3000, 5, 301, 0));
sweeps(end + 1) = struct('name', "distance_rough", 'x', d, 'fun', @(x, m) m(10, 10, mk(rough(x)), 3000, 5, 301, 0));
f = logspace(log10(50), log10(10000), 150);
pr = rough(60);
sweeps(end + 1) = struct('name', "frequency_rough60", 'x', f, 'fun', @(x, m) m(10, 10, mk(pr), x, 5, 301, 0));
hh = 1:0.25:30;
sweeps(end + 1) = struct('name', "rx_height_ridge40", 'x', hh, 'fun', @(x, m) m(10, x, mk(ridge(40)), 3000, 5, 301, 0));
finite_ok = true;
for k = 1:numel(sweeps)
    sw = sweeps(k);
    Lv = arrayfun(@(x) sw.fun(x, fvar), sw.x);
    Lb = arrayfun(@(x) sw.fun(x, fbase), sw.x);
    finite_ok = finite_ok && all(isfinite(Lv)) && isreal(Lv);
    jv = max(abs(diff(Lv))); jb = max(abs(diff(Lb)));
    ok = jv <= jb + 1;
    B.checks.("continuity_" + sw.name) = struct('variant_max_step_db', jv, 'baseline_max_step_db', jb, 'pass', ok);
    B.pass = B.pass && ok;
    if sw.name == "rx_height_ridge40"
        nv = Lv(end) - Lv(1); nb = Lb(end) - Lb(1);
        ok = nv <= max(nb, 0) + 1;
        B.checks.height_gain_rx_height_ridge40 = struct('variant_net_change_db', nv, 'baseline_net_change_db', nb, 'pass', ok);
        B.pass = B.pass && ok;
    end
end

% ---- real links ----
rng(1, 'twister');                          % fixed sample, same every run
ids = [profiles.path_id];
k = find(~P2.censored);
k = k(randperm(numel(k), min(300, numel(k))));
dv = NaN(numel(k), 1); db = dv; av = dv; ab = dv;
for i = 1:numel(k)
    r = P2(k(i), :);
    p = profiles(ids == r.path_id);
    pfl = mk(p.h_m); pflr = mk(flipud(p.h_m(:)));
    row = norow;
    if all(ismember({'set', 'siting'}, P2.Properties.VariableNames))
        row = struct('set', string(r.set), 'siting', string(r.siting), 'reversed', false);
    end
    rowr = row; rowr.reversed = true;
    a = fvar_row(r.htx_m, r.hrx_m, pfl, r.f_mhz, r.climate, r.N_0, r.pol, row);
    b = fvar_row(r.hrx_m, r.htx_m, pflr, r.f_mhz, r.climate, r.N_0, r.pol, rowr);
    a0 = fbase(r.htx_m, r.hrx_m, pfl, r.f_mhz, r.climate, r.N_0, r.pol);
    b0 = fbase(r.hrx_m, r.htx_m, pflr, r.f_mhz, r.climate, r.N_0, r.pol);
    dv(i) = abs(a - b); db(i) = abs(a0 - b0);
    av(i) = a - r.fs_db; ab(i) = a0 - r.fs_db;
    finite_ok = finite_ok && isfinite(a) && isfinite(b) && isreal(a);
end
% ---- real-path height gain (all rows, both antennas raised 10 m) ----
dh = 10;                                    % raise in metres
xs = -Inf; xs_row = "";
for i = 1:height(P2)
    r = P2(i, :);
    p = profiles(ids == r.path_id);
    pfl = mk(p.h_m);
    row = norow;
    if all(ismember({'set', 'siting'}, P2.Properties.VariableNames))
        row = struct('set', string(r.set), 'siting', string(r.siting), 'reversed', false);
    end
    h = [r.htx_m, r.hrx_m];
    v0 = fvar_row(h(1), h(2), pfl, r.f_mhz, r.climate, r.N_0, r.pol, row);
    b0 = fbase(h(1), h(2), pfl, r.f_mhz, r.climate, r.N_0, r.pol);
    for e = 1:2
        hh = h; hh(e) = hh(e) + dh;
        dvh = fvar_row(hh(1), hh(2), pfl, r.f_mhz, r.climate, r.N_0, r.pol, row) - v0;
        dbh = fbase(hh(1), hh(2), pfl, r.f_mhz, r.climate, r.N_0, r.pol) - b0;
        finite_ok = finite_ok && isfinite(dvh) && isreal(dvh);
        x = dvh - max(dbh, 0);
        if x > xs
            xs = x; xs_row = sprintf('%s f %g MHz, antenna %d', r.path_id, r.f_mhz, e);
        end
    end
end
ok = xs <= 1;
B.checks.height_gain_real = struct('worst_excess_db', xs, 'worst_row', string(xs_row), 'pass', ok);
B.pass = B.pass && ok;

pv = prctile(dv, 95); pb = prctile(db, 95);
ok = pv <= max(0.1, pb + 0.1);
B.checks.reciprocity = struct('variant_p95_db', pv, 'baseline_p95_db', pb, 'pass', ok);
B.pass = B.pass && ok;
lim = min(-6.1, min(ab)) - 0.1;
ok = min(av) >= lim;
B.checks.two_ray_bound = struct('variant_min_excess_db', min(av), 'limit_db', lim, 'pass', ok);
B.pass = B.pass && ok;
B.checks.finite = struct('pass', finite_ok);
B.pass = B.pass && finite_ok;
end

function h = ridge_profile(d_km, step, height_m)
n = round(d_km * 1000 / step) + 1;
x = linspace(0, 1, n)';
h = height_m * max(0, 1 - abs(x - 0.5) / 0.05);
end

function h = rough_profile(d_km, step)
n = round(d_km * 1000 / step) + 1;
x = (0:n - 1)' * step / 1000;
h = 200 + 60 * sin(2 * pi * x / 7.3) + 35 * sin(2 * pi * x / 2.9 + 1) + 15 * sin(2 * pi * x / 0.9 + 2);
end
