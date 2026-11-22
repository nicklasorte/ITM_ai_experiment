"""D04: are open, geometrically clear Phase 2 paths too optimistic because of Fresnel-zone intrusion?

Usage, from the repository root:
    python3 -I experiments/D04-open-clear-paths/fresnel_clearance_rev1.py <tag>

Research plan hypotheses H04 (foreground Fresnel clearance) and H21 (hidden
clutter on open paths), docs/research/FUTURE_RESEARCH_PLAN_rev1.md.

For every Phase 2 row, computes from the frozen terrain profile (4/3
effective Earth, the same rule as b07_split_rev1.py):
  - clear/obstructed: terrain above the straight ray anywhere
  - nu_max: the largest Fresnel-Kirchhoff parameter over the profile,
    nu = h * sqrt(2 d / (lambda d1 d2)), with h the height of terrain plus
    Earth bulge above the ray (negative when below). This is the
    Bullington/P.452 "highest intrusion" parameter (ITU-R P.526-16
    section 4.5, eq. (51)-(54); ITU-R P.452-18 eq. (14)-(16)).
  - J(nu_max): single knife-edge loss, ITU-R P.526-16 eq. (31), 0 for nu <= -0.78
  - where the intrusion sits: distance of the nu_max point from the nearer
    terminal, as a fraction of the path ("foreground" when within 10 %)
Then reports, for open (siting O) clear rows with a measured value, the
mean and RMS of (prediction - measured) for <tag> by site and by nu_max bin,
frequency band, distance band, and foreground/midpath; and the mean
J(nu_max). No model is changed; no score is reported to the loop.
"""
import csv, math, os, sys, collections

A_E = 6371e3 * 4 / 3
C = 299792458.0


def J(nu):
    if nu <= -0.78:
        return 0.0
    return 6.9 + 20 * math.log10(math.sqrt((nu - 0.1) ** 2 + 1) + nu - 0.1)


def geometry(h, step, htx, hrx, f_mhz):
    n = len(h); d = (n - 1) * step
    zt, zr = h[0] + htx, h[-1] + hrx
    lam = C / (f_mhz * 1e6)
    obstructed = False
    nu_max, x_at = -1e9, 0.0
    for i in range(1, n - 1):
        x = i * step
        ray = zt + (zr - zt) * x / d
        hh = h[i] + x * (d - x) / (2 * A_E) - ray
        if hh > 0:
            obstructed = True
        nu = hh * math.sqrt(2 * d / (lam * x * (d - x)))
        if nu > nu_max:
            nu_max, x_at = nu, x
    frac = min(x_at, d - x_at) / d if d > 0 else 0
    return obstructed, nu_max, frac, d


def main(tag):
    links = {r['link_id']: r for r in csv.DictReader(open('data/links/phase2_links_rev1.csv'))}
    idx = {r['path_id']: r for r in csv.DictReader(open('data/profiles/profiles_index_rev1.csv'))}
    prof = {}
    P = list(csv.DictReader(open(os.path.join('experiments', tag, 'predictions_phase2.csv'))))
    rows = []
    for r in P:
        l = links[r['link_id']]
        pid = l['path_id']
        if pid not in prof:
            p = idx[pid]
            with open(os.path.join('data/profiles', p['dataset'], pid + '.csv')) as f:
                next(f); prof[pid] = ([float(v) for v in f], float(p['spacing_m']))
        h, step = prof[pid]
        obs, nu, frac, d = geometry(h, step, float(l['htx_m']), float(l['hrx_m']), float(l['f_mhz']))
        rows.append(dict(set=l['set'], siting=l['siting'], censored=l['censored'] == '1',
                         f=float(l['f_mhz']), d_km=d / 1000, obs=obs, nu=nu, frac=frac,
                         J=J(nu), err=float(r['var_lb_50']) - float(l['meas_lb_db']),
                         viol=float(r['var_lb_50']) < float(l['meas_lb_db'])))
    out = os.path.join('experiments', 'D04-open-clear-paths', 'rows_rev1.csv')
    with open(out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)

    def report(title, sel, keyf):
        g = collections.defaultdict(list); gj = collections.defaultdict(list)
        for x in sel:
            g[keyf(x)].append(x['err']); gj[keyf(x)].append(x['J'])
        print(title)
        for k in sorted(g):
            e = g[k]
            print(f"  {str(k):28s} n {len(e):5d}  mean {sum(e)/len(e):+6.1f}  rms {math.sqrt(sum(v*v for v in e)/len(e)):5.1f}"
                  f"  mean J(nu_max) {sum(gj[k])/len(gj[k]):5.1f}")

    meas = [x for x in rows if not x['censored']]
    oc = [x for x in meas if x['siting'] == 'O' and not x['obs']]
    print(f"{tag}: open clear measured rows {len(oc)}; all measured rows {len(meas)}")
    nub = lambda x: (x['set'], '<-2' if x['nu'] < -2 else '-2..-0.78' if x['nu'] < -0.78 else '-0.78..0')
    report("by site and nu_max bin (open, clear):", oc, nub)
    fb = lambda x: (x['set'], '<0.5' if x['f'] < 500 else '0.5-1.5' if x['f'] < 1500 else '1.5-3' if x['f'] < 3000 else '>3 GHz')
    report("by site and band (open, clear):", oc, fb)
    db = lambda x: (x['set'], '<2 km' if x['d_km'] < 2 else '2-5' if x['d_km'] < 5 else '5-10' if x['d_km'] < 10 else '>10 km')
    report("by site and distance (open, clear):", oc, db)
    fg = lambda x: (x['set'], 'foreground' if x['frac'] < 0.1 else 'midpath')
    report("by site and where nu_max sits (open, clear, nu_max > -0.78 only):", [x for x in oc if x['nu'] > -0.78], fg)
    # censored open clear rows
    cc = [x for x in rows if x['censored'] and x['siting'] == 'O' and not x['obs']]
    cv = collections.defaultdict(lambda: [0, 0])
    for x in cc:
        cv[x['set']][0] += 1; cv[x['set']][1] += x['viol']
    print("censored open clear rows violated:", {k: f"{v[1]}/{v[0]}" for k, v in sorted(cv.items())})
    print(f"rows written: {out}")


if __name__ == '__main__':
    main(sys.argv[1])
