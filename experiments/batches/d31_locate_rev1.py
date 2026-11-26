"""B31 step 2: locate OT 75-74 terminals (map prior + least squares on tabulated distances).

Reads experiments/D31-ot7574/map_reading_<area>_rev1.json (page-pixel
readings of graticule ticks, scale bar and terminal dots) and the digitized
table (distances per T-R pair). Steps:

1. Map frame: the meridians' direction comes from the two points read on one
   meridian (map rotation); east and south distances (km) of each terminal
   from the reference meridian/parallel crossing come from the scale bar.
2. Least squares: adjust all terminal positions (local east/north km) to
   fit the tabulated distances, with each map position as a prior of
   PRIOR_SD_KM (planner-chosen, B31 step 2).
3. Convert local km to latitude and longitude about the reference crossing.

Checks (B31 step 2): distance RMS < 0.03 km; every adjusted position within
0.3 km of its map position. Fails loud otherwise unless --report-only.

Usage: python3 -I experiments/batches/d31_locate_rev1.py <area> <table_csv> [--report-only]
"""
import json
import math
import os
import sys

import numpy as np
import pandas as pd
from scipy.optimize import least_squares

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "experiments", "D31-ot7574")
PRIOR_SD_KM = 0.10
KM_PER_DEG_LAT = 110.86   # near 30-36 deg N (planner's approximation; error < 0.2 %)


def map_frame(m):
    lon0, pts0 = [(float(k), v) for k, v in m["lon_lines"].items() if len(v) == 2][0]   # first two-point meridian is the reference
    (x0, y0), (x1, y1) = pts0
    th = math.atan2(x1 - x0, y1 - y0)                  # meridian lean from vertical
    e_s = np.array([math.sin(th), math.cos(th)])       # south, page pixels
    e_e = np.array([math.cos(th), -math.sin(th)])      # east
    (lat0, ((lx, ly),)), = [(float(k), v) for k, v in m["lat_ticks"].items()]
    # reference point: on the meridian lon0, on the parallel through the lat tick
    p_m = np.array([x0, y0]); p_l = np.array([lx, ly])
    t = np.dot(p_l - p_m, e_s)                          # move along the meridian to the parallel
    ref = p_m + t * e_s
    return lat0, lon0, ref, e_e, e_s, m["scale_px_per_km"]


def to_local(m, frame):
    lat0, lon0, ref, e_e, e_s, s = frame
    out = {}
    for name, (x, y) in m["terminals"].items():
        d = np.array([x, y]) - ref
        out[name] = (np.dot(d, e_e) / s, -np.dot(d, e_s) / s)   # east km, north km
    return out


def main(area, table_csv, report_only):
    m = json.load(open(os.path.join(OUT, "map_reading_%s_rev1.json" % area.lower())))
    frame = map_frame(m)
    lat0, lon0 = frame[0], frame[1]
    prior = to_local(m, frame)
    # check of the second meridian, if read: its east offset vs the expected
    for k, v in m["lon_lines"].items():
        if float(k) != lon0:
            for (x, y) in v:
                e = np.dot(np.array([x, y]) - frame[2], frame[3]) / frame[5]
                exp = (float(k) - lon0) * KM_PER_DEG_LAT * 1.0042 * math.cos(math.radians(lat0))
                print("second meridian %s: %.3f km east on the map, %.3f km expected (%.1f %%)" % (
                    k, e, exp, 100 * (e - exp) / exp))
    D = pd.read_csv(table_csv, dtype=str, keep_default_na=False)
    D = D[D.table.astype(int) == int(m["table"])][["tx", "rx", "dist_km"]].drop_duplicates()
    D["dist_km"] = D.dist_km.astype(float)
    names = sorted(prior)
    ix = {n: i for i, n in enumerate(names)}
    pairs = [(ix["T%s" % r.tx], ix["R%s" % r.rx], r.dist_km) for r in D.itertuples()
             if "T%s" % r.tx in ix and "R%s" % r.rx in ix]
    missing = [(r.tx, r.rx) for r in D.itertuples() if "T%s" % r.tx not in ix or "R%s" % r.rx not in ix]
    if missing:
        print("pairs with a terminal not read from the map:", missing)
    p0 = np.array([prior[n] for n in names]).ravel()

    def resid(p):
        q = p.reshape(-1, 2)
        r1 = [np.hypot(*(q[a] - q[b])) - d for a, b, d in pairs]
        r2 = (p - p0) / PRIOR_SD_KM * 0.01            # prior, in units comparable to 0.01 km
        return np.concatenate([np.array(r1) / 0.01, r2 / 0.01])

    sol = least_squares(resid, p0)
    q = sol.x.reshape(-1, 2)
    dres = np.array([np.hypot(*(q[a] - q[b])) - d for a, b, d in pairs])
    d0 = np.array([np.hypot(*(p0.reshape(-1, 2)[a] - p0.reshape(-1, 2)[b])) - d for a, b, d in pairs])
    shift = np.hypot(*(q - p0.reshape(-1, 2)).T)
    rows = []
    for n, (e, nn), sh in zip(names, q, shift):
        lat = lat0 + nn / KM_PER_DEG_LAT
        lon = lon0 + e / (KM_PER_DEG_LAT * 1.0042 * math.cos(math.radians(lat0)))
        rows.append({"area": area, "terminal": n, "lat": round(lat, 6), "lon": round(lon, 6),
                     "east_km": round(e, 4), "north_km": round(nn, 4), "shift_from_map_km": round(sh, 4)})
    T = pd.DataFrame(rows)
    rms0, rms1 = float(np.sqrt(np.mean(d0 ** 2))), float(np.sqrt(np.mean(dres ** 2)))
    print("%s: %d pairs; distance RMS map-only %.3f km, adjusted %.3f km; max shift %.3f km (%s)" % (
        area, len(pairs), rms0, rms1, shift.max(), names[int(shift.argmax())]))
    ok = rms1 < 0.03 and shift.max() <= 0.3
    T.to_csv(os.path.join(OUT, "terminals_%s_rev1.csv" % area.lower()), index=False)
    pd.DataFrame([{"tx": names[a], "rx": names[b], "dist_table_km": d,
                   "dist_map_km": d + e0, "dist_adjusted_km": d + e1}
                  for (a, b, d), e0, e1 in zip(pairs, d0, dres)]).round(4).to_csv(
        os.path.join(OUT, "distances_%s_rev1.csv" % area.lower()), index=False)
    print("checks:", "PASS" if ok else "FAIL")
    if not ok and not report_only:
        sys.exit(1)


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) not in (2, 3):
        sys.exit("usage: d31_locate_rev1.py <area> <table_csv> [--report-only]")
    main(a[0], a[1], "--report-only" in a)
