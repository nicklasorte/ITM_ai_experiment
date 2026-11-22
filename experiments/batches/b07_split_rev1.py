"""B07 split report: Phase 2 error by siting (open, concealed) and by clear or obstructed path.

Usage: python3 experiments/batches/b07_split_rev1.py <tag> [<tag> ...]

A path is obstructed when terrain rises above the straight ray between the
antennas on a 4/3 effective Earth (the same rule as the long-term screen of
D01). For each tag, prints measured-row mean error and RMS (prediction minus
measured, dB) and the censored-row violation rate, by site, siting, and
clear or obstructed. Reads experiments/<tag>/predictions_phase2.csv, the
Phase 2 link table, and the profiles.
"""
import csv, math, sys, collections, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A_E = 6371e3 * 4 / 3  # 4/3 effective Earth radius (m)


def obstructed(h, step, htx, hrx):
    n = len(h); d = (n - 1) * step
    zt, zr = h[0] + htx, h[-1] + hrx
    for i in range(1, n - 1):
        x = i * step
        ray = zt + (zr - zt) * x / d
        if h[i] + x * (d - x) / (2 * A_E) > ray:
            return True
    return False


def main(tags):
    links = {r['link_id']: r for r in csv.DictReader(open(os.path.join(ROOT, 'data/links/phase2_links_rev1.csv')))}
    idx = {r['path_id']: r for r in csv.DictReader(open(os.path.join(ROOT, 'data/profiles/profiles_index_rev1.csv')))}
    cache = {}
    def obs(l):
        k = (l['path_id'], l['htx_m'], l['hrx_m'])
        if k not in cache:
            p = idx[l['path_id']]
            with open(os.path.join(ROOT, 'data/profiles', p['dataset'], l['path_id'] + '.csv')) as f:
                next(f); h = [float(v) for v in f]
            cache[k] = obstructed(h, float(p['spacing_m']), float(l['htx_m']), float(l['hrx_m']))
        return cache[k]
    for tag in tags:
        P = list(csv.DictReader(open(os.path.join(ROOT, 'experiments', tag, 'predictions_phase2.csv'))))
        col = 'var_lb_50' if 'var_lb_50' in P[0] else 'itm_lb_50'
        err = collections.defaultdict(list); cen = collections.defaultdict(lambda: [0, 0])
        for r in P:
            l = links[r['link_id']]
            key = (l['set'], l['siting'], 'obstructed' if obs(l) else 'clear')
            v, m = float(r[col]), float(l['meas_lb_db'])
            if l['censored'] == '1':
                cen[key][0] += 1; cen[key][1] += v < m
            else:
                err[key].append(v - m)
        print(tag)
        for key in sorted(set(err) | set(cen)):
            e = err.get(key, []); c = cen[key]
            s = f"  {key[0]:3s} {key[1]} {key[2]:10s}"
            s += f"  n {len(e):5d}  mean {sum(e)/len(e):+6.1f}  rms {math.sqrt(sum(x*x for x in e)/len(e)):5.1f}" if e else f"  n {0:5d}{'':27s}"
            s += f"  censored violated {c[1]:4d} of {c[0]:4d}" if c[0] else ""
            print(s)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
