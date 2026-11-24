#!/usr/bin/env python3
"""B16c: eligibility count for the rounded-crest diagnostic (research review item 3, H05).

Usage:  python3 -I experiments/batches/b16c_eligibility_rev1.py <out_dir>

Geometry only: reads the surveyed Phase 2 profiles in data/raw/its_phase2.zip
(native map vertices, the profiles the data set itself gives) and the
geometry columns of data/links/phase2_links_rev1.csv (heights, frequency,
N_0). No measured loss is read.

Registered rule (experiments/batches/B16.md, B16c). A (path, frequency,
receiver height) case is geometry-eligible when all of these hold:
  1. Single tangent-defined crest: the radio horizon from each antenna (the
     native vertex of highest elevation angle on ITM's effective Earth, as
     in ITM's FindHorizons) is the same vertex, and it blocks the direct ray.
  2. Native support on both flanks: a native survey vertex on each side of
     the crest within W = 250 m (the obstruction sample-spacing limit of
     ITU-R P.526-16 section 4.4); W = 500 m is reported as a sensitivity.
  3. Isolated: every native vertex between each antenna and the crest
     clears the line from that antenna to the crest top by at least 0.6 of
     the first Fresnel zone radius of that arm (ITU-R P.526-16 section 2.5,
     eq. (2)).
  4. Documented vertical error small relative to the crest drops. The .pfl
     headers give the source map scale but no contour interval or vertical
     accuracy; the rule classifies an undocumented case as unresolved.
Paths are counted as distinct survey profiles (open and concealed twins on
one profile count once) and as distinct fixed sites (the R1-R3 receivers and
the VA transmitters).

Effective Earth: ITM v1.4 InitializePointToPoint, N_s = N_0 exp(-h_sys/9460)
with h_sys the mean elevation over the middle 80 % of the 30 m profile in
data/profiles, gamma_e = 157e-9 (1 - 0.04665 exp(N_s/179.3)).
"""
import csv
import io
import math
import os
import sys
import zipfile
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
C_LIGHT = 299.792458  # m * MHz


def read_pfl(text):
    """Port of data/private/p2_profile.m read_pfl: [(km, m)], first-point flag."""
    first_rx = None
    v = []
    scale = None
    for t in text.splitlines():
        if "First Point" in t:
            first_rx = t.strip().endswith("R")
        elif "SCALE" in t:
            scale = t.split(":")[-1].strip()
        else:
            parts = t.split()
            if len(parts) >= 2:
                try:
                    a, b = float(parts[0]), float(parts[1])
                except ValueError:
                    continue
                if not v or a != v[-1][0]:
                    if all(a != q[0] for q in v):
                        v.append((a, b))
    return v, first_rx, scale


def candidates(path_id):
    """Port of p2_profile.m file-name rule."""
    # path_id: P2_<set>_<name>_<siting>; name may contain '_' (e.g. R1-0_5-T1)
    body = path_id[3:]
    s = body.split("_")[0]
    site = body.rsplit("_", 1)[1]
    name = body[len(s) + 1:-(len(site) + 1)]
    p = name.split("-")
    nom = p[1].replace("_", "'")
    if s == "VA":
        return s, [(nom + p[0] + p[2]).lower()]
    num = p[2][1:]
    if site == "C":
        return s, [(nom + p[0] + "c" + num).lower()]
    if site == "A":
        return s, [(nom + p[0] + "a" + num).lower()]
    return s, [(nom + p[0] + "o" + num).lower(), (nom + p[0] + "t" + num).lower()]


def a_e_for(path_id, n0):
    h = []
    with open(os.path.join(ROOT, "data", "profiles", "phase2", path_id + ".csv")) as f:
        next(f)
        h = [float(x) for x in f if x.strip()]
    np_ = len(h) - 1
    p10 = int(0.1 * np_)
    seg = h[p10:np_ - p10 + 1]
    hs = sum(seg) / len(seg)
    ns = n0 * math.exp(-hs / 9460.0)
    return 1.0 / (157e-9 * (1 - 0.04665 * math.exp(ns / 179.3))), h


def classify(v, ht, hr, f_mhz, a_e, W):
    """Return (eligible, reason, crest_index, drop_t, drop_r) on native vertices v (m, m)."""
    lam = C_LIGHT / f_mhz
    x = [p[0] for p in v]
    z = [p[1] for p in v]
    n = len(v)
    d = x[-1]
    if n < 3:
        return False, "fewer than 3 vertices", None, None, None
    zt, zr = z[0] + ht, z[-1] + hr
    th_t = [(z[i] - zt) / x[i] - x[i] / (2 * a_e) for i in range(1, n - 1)]
    th_r = [(z[i] - zr) / (d - x[i]) - (d - x[i]) / (2 * a_e) for i in range(1, n - 1)]
    it = 1 + max(range(n - 2), key=lambda j: (th_t[j], -j))
    ir = 1 + max(range(n - 2), key=lambda j: (th_r[j], -j))
    direct_t = (zr - zt) / d - d / (2 * a_e)
    if th_t[it - 1] <= direct_t:
        return False, "line of sight", None, None, None
    if it != ir:
        return False, "two horizons", None, None, None
    k = it
    # 2. native flank support
    if x[k] - x[k - 1] > W or x[k + 1] - x[k] > W:
        return False, "flank vertex beyond W", k, None, None
    # 3. isolation on both arms (bulge relative to each arm's chord)
    for (a, b) in ((0, k), (k, n - 1)):
        za = zt if a == 0 else z[a]
        zb = zr if b == n - 1 else z[b]
        for i in range(a + 1, b):
            da, db = x[i] - x[a], x[b] - x[i]
            ray = (za * db + zb * da) / (da + db)
            clr = ray - (z[i] + da * db / (2 * a_e))
            r1 = math.sqrt(lam * da * db / (da + db))
            if clr < 0.6 * r1:
                return False, "arm not clear", k, None, None
    return True, "geometry eligible", k, z[k] - z[k - 1], z[k] - z[k + 1]


def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    zf = zipfile.ZipFile(os.path.join(ROOT, "data", "raw", "its_phase2.zip"))
    names = {n.lower(): n for n in zf.namelist()}
    rows = list(csv.DictReader(open(os.path.join(ROOT, "data", "links", "phase2_links_rev1.csv"))))
    by_path = defaultdict(list)
    for r in rows:
        by_path[r["path_id"]].append(r)
    out_rows = []
    check_max = 0.0
    for pid, rs in sorted(by_path.items()):
        s, cands = candidates(pid)
        fn = None
        for c in cands:
            key = "phase_2/%s_pfl/%s.pfl" % (s.lower(), c)
            if key in names:
                fn = names[key]
                break
        if fn is None:
            raise SystemExit("no survey profile for %s" % pid)
        v, first_rx, scale = read_pfl(zf.read(fn).decode("latin-1"))
        if first_rx:
            dk = v[-1][0]
            v = [(dk - a, b) for (a, b) in reversed(v)]
        vm = [(1000 * a, b) for (a, b) in v]
        a_e, h30 = a_e_for(pid, float(rs[0]["N_0"]))
        # check: the 30 m profile is these vertices resampled linearly
        sp = vm[-1][0] / (len(h30) - 1)
        for i in range(0, len(h30), max(1, len(h30) // 50)):
            xx = i * sp
            j = max(q for q in range(len(vm) - 1) if vm[q][0] <= xx) if xx < vm[-1][0] else len(vm) - 2
            t = (xx - vm[j][0]) / (vm[j + 1][0] - vm[j][0])
            check_max = max(check_max, abs(vm[j][1] + t * (vm[j + 1][1] - vm[j][1]) - h30[i]))
        cases = sorted({(float(r["f_mhz"]), float(r["htx_m"]), float(r["hrx_m"])) for r in rs})
        for (f, ht, hr) in cases:
            res = {}
            for W in (250.0, 500.0):
                res[W] = classify(vm, ht, hr, f, a_e, W)
            spacing = [vm[i + 1][0] - vm[i][0] for i in range(len(vm) - 1)]
            out_rows.append({
                "path_id": pid, "set": s, "site": fixed_site(pid), "survey_file": fn.split("/")[-1],
                "map_scale": scale, "n_vertices": len(vm), "median_spacing_m": round(sorted(spacing)[len(spacing) // 2], 1),
                "f_mhz": f, "htx_m": ht, "hrx_m": hr,
                "eligible_250": res[250.0][0], "reason_250": res[250.0][1],
                "eligible_500": res[500.0][0], "reason_500": res[500.0][1],
                "crest_vertex": res[500.0][2] if res[500.0][2] is not None else "",
                "drop_t_m": "" if res[500.0][3] is None else res[500.0][3],
                "drop_r_m": "" if res[500.0][4] is None else res[500.0][4],
            })
    with open(os.path.join(out_dir, "cases.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out_rows[0].keys()))
        w.writeheader()
        w.writerows(out_rows)
    lines = ["B16c rounded-crest eligibility count (geometry only).",
             "Survey-vertex check: 30 m profiles in data/profiles match the survey vertices "
             "resampled linearly to %.3f m at most." % check_max,
             "Cases (path, frequency, heights): %d on %d paths." % (len(out_rows), len(by_path))]
    for W in ("250", "500"):
        reasons = defaultdict(int)
        for r in out_rows:
            reasons[r["reason_" + W]] += 1
        el = [r for r in out_rows if r["eligible_" + W]]
        prof = {r["survey_file"] for r in el}
        sites = {(r["set"], r["site"]) for r in el}
        prof_all = defaultdict(set)
        for r in out_rows:
            prof_all[r["survey_file"]].add(bool(r["eligible_" + W]))
        allh = sum(1 for k, sv in prof_all.items() if sv == {True})
        lines.append("")
        lines.append("W = %s m: geometry-eligible cases %d; distinct survey profiles %d (eligible at every case: %d); "
                     "distinct fixed sites %d %s" % (W, len(el), len(prof), allh, len(sites), sorted(sites)))
        lines.append("  reasons: " + "; ".join("%s %d" % kv for kv in sorted(reasons.items(), key=lambda kv: -kv[1])))
        by_set = defaultdict(set)
        for r in el:
            by_set[r["set"]].add(r["survey_file"])
        lines.append("  eligible profiles by set: " + ", ".join("%s %d" % (k, len(v)) for k, v in sorted(by_set.items())))
    scales = defaultdict(set)
    for r in out_rows:
        scales[r["set"]].add(r["map_scale"])
    lines.append("")
    lines.append("Vertical error: map scales by set " + str({k: sorted(v) for k, v in scales.items()}) +
                 "; no contour interval or vertical accuracy in any header, so rule 4 leaves every case unresolved.")
    # Sensitivity, not part of the rule: if the maps met the US National Map
    # Accuracy Standards (1947: 90 % of tested elevations within half the
    # contour interval), the error would be 3.05 m (20 ft interval) or
    # 6.10 m (40 ft). "Small" is read as both crest drops >= 3 times that.
    for e in (3.048, 6.096):
        el = {}
        for r in out_rows:
            if r["eligible_250"] and min(r["drop_t_m"], r["drop_r_m"]) >= 3 * e:
                el[r["survey_file"]] = (r["set"], r["site"], r["path_id"])
        lines.append("Sensitivity (W = 250 m, both drops >= 3 x %.2f m): %d profiles %s" % (e, len(el), sorted(el.values())))
    open(os.path.join(out_dir, "summary.txt"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


def fixed_site(pid):
    body = pid[3:]
    s = body.split("_")[0]
    name = body[len(s) + 1:].rsplit("_", 1)[0]
    p = name.split("-")
    return p[0] if s == "VA" else s


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
