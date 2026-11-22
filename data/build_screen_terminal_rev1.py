"""Long-term terminal-geometry screen (proposed rule, B10 / Nick 2026-11-22).

A long-term link is screened when, at either terminal, the radio horizon on
the frozen 30 m profile (highest elevation angle on a 4/3 effective Earth,
as ITM's FindHorizons) lies within 0.5 km of the antenna at an elevation
angle above 50 mrad: the antenna sits below terrain a few profile samples
away, which on a recorded relay or measurement site means the coordinates
don't match the terrain. Geometry only; no measured or predicted loss is read.
Writes data/links/longterm_screen_rev1.csv as the union of the existing
rows (D01: record says LOS, 30 m profile blocked; kept unchanged) and the
links this rule adds, then its .sha256. Thresholds were chosen after seeing
three outlier paths (LT2241, LT2246, LT2233); they're stated here so they
stay fixed.
Usage, from the repository root: python3 -I data/build_screen_terminal_rev1.py .
"""
import hashlib
import csv, math, os, sys
root = sys.argv[1]
AE = 6371e3 * 4 / 3
DMAX, AMIN = 500.0, 0.050
idx = {r['path_id']: r for r in csv.DictReader(open(os.path.join(root, 'data/profiles/profiles_index_rev1.csv')))}
links = list(csv.DictReader(open(os.path.join(root, 'data/links/longterm_links_rev1.csv'))))
paths = {}
for r in links:
    paths.setdefault(r['path_id'], r)
hit = {}
for pid, r in paths.items():
    i = idx[pid]
    with open(os.path.join(root, 'data/profiles', i['dataset'], pid + '.csv')) as f:
        next(f); h = [float(v) for v in f]
    s = float(i['spacing_m']); n = len(h)
    for end, ha in (('tx', float(r['htx_m'])), ('rx', float(r['hrx_m']))):
        seq = h if end == 'tx' else h[::-1]
        z = seq[0] + ha
        best, at, kk = -1e9, 0.0, 0
        for k in range(1, n - 1):
            x = k * s
            e = (seq[k] - z) / x - x / (2 * AE)
            if e > best:
                best, at, kk = e, x, k
        if at <= DMAX and best > AMIN:
            obs = seq[kk] - z            # terrain at the horizon above the antenna (m)
            prev = hit.get(pid)
            if prev is None or obs > prev[0]:
                hit[pid] = (obs, f"{end} horizon {at/1000:.2f} km at {best*1000:.0f} mrad")
path = os.path.join(root, 'data/links/longterm_screen_rev1.csv')
old = list(csv.DictReader(open(path)))
have = {r['link_id'] for r in old}
rows = [[r['link_id'], r['path_id'], r['obs_m'], r['reason']] for r in old]
added = 0
for r in links:
    if r['path_id'] in hit and r['link_id'] not in have:
        obs, why = hit[r['path_id']]
        rows.append([r['link_id'], r['path_id'], f"{obs:.2f}", f"terminal below nearby terrain: {why}"])
        added += 1
rows.sort(key=lambda x: x[0])
with open(path, 'w', newline='') as f:
    w = csv.writer(f, lineterminator='\n'); w.writerow(['link_id', 'path_id', 'obs_m', 'reason']); w.writerows(rows)
digest = hashlib.sha256(open(path, 'rb').read()).hexdigest()
open(os.path.join(root, 'data/links/longterm_screen_rev1.sha256'), 'w').write(digest + '\n')
print(f"{len(hit)} paths match the rule; {added} links added; screen now {len(rows)} links; sha256 {digest}")
