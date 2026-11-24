#!/usr/bin/env python3
"""Hybrids, frontier and strata of stored runs (planner tool, phase plan rev 3).

Planning analysis on finished runs. Nothing is run or scored anew: every
number comes from the stored predictions of past experiments
(experiments/<tag>/predictions_*.csv, development data only, never lockbox),
the frozen link table and the frozen terrain profiles. Reuses the score
replica in hm_screen_rev1.py, which reproduces metrics.json.

Reports:

  hybrid    Score of 707 with another stored run's predictions on one class
            of rows: Phase 2 rows by number of terrain obstacles above the
            direct ray (the D04 rule, as in headroom_map_rev1.py), and
            long-term links by distance class. Shows where two method
            families differ in score and in censored violations. A hybrid
            isn't a model (it switches method by class); it's a bound on
            what a change confined to that class can do.
  frontier  One line per stored run under the current 36-link screen: full
            and screened composite, Phase 2 cell RMS on detected rows, the
            same with censored rows scored as lower bounds (error
            min(0, predicted - bound)), censored share, and the mean depth
            of a violation.
  strata    707 and stock ITM on detected Phase 2 rows by frequency band,
            lower antenna height (at or under 3 m, above 3 m) and terrain
            (clear, obstructed). The development strata nearest the lockbox
            sets (FRAMEWORK.md Tier B: VHF, and antennas under 3 m).

Usage (from the repository root):
  python3 experiments/batches/hm_frontier_rev1.py hybrid
  python3 experiments/batches/hm_frontier_rev1.py frontier
  python3 experiments/batches/hm_frontier_rev1.py strata
"""
import argparse
import csv
import math
import os
import shutil
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import hm_screen_rev1 as hm

ROOT = hm.ROOT
PARENT = os.path.join(ROOT, "experiments", "707-cascaded-isolated-clutter-at-r")
A_E_43 = 6371e3 * 4 / 3          # 4/3 Earth, as headroom_map_rev1.py (the D04 rule)
C_LIGHT = 299792458.0
RUNS = [("707-cascaded-isolated-clutter-at-r", "707 (best)"),
        ("708-deygout-isolated-clutter-at-r", "708 Deygout isolated, no C"),
        ("702-deygout-isolated-clutter", "702 Deygout isolated, no C"),
        ("703-bullington-clutter", "703 delta-Bullington"),
        ("502-delta-bullington-afo", "502 delta-Bullington + A_fo"),
        ("603-delta-bullington-afo-bounded", "603 as 502, bounded"),
        ("604-delta-cascaded-isolated-bounded", "604 707 without clutter"),
        ("712-nlcd-open-forest-only", "712 707 + forest at open terminals")]


def uncensored(r):
    return r["censored"] in ("0", "false", "False")


def obstacle_classes():
    """link_id -> number of separate terrain runs above the direct ray (capped at 4)."""
    idx = {r["path_id"]: r for r in hm.read_csv(os.path.join(ROOT, "data", "profiles", "profiles_index_rev1.csv"))}
    cache, out = {}, {}
    for r in hm.read_csv(os.path.join(ROOT, "data", "links", "phase2_links_rev1.csv")):
        pid = r["path_id"]
        if pid not in cache:
            h = np.loadtxt(os.path.join(ROOT, "data", "profiles", idx[pid]["dataset"], pid + ".csv"), skiprows=1)
            cache[pid] = (h.astype(float), float(idx[pid]["spacing_m"]))
        h, step = cache[pid]
        n = len(h)
        d = (n - 1) * step
        zt, zr = h[0] + float(r["htx_m"]), h[-1] + float(r["hrx_m"])
        x = np.arange(1, n - 1) * step
        above = h[1:n - 1] + x * (d - x) / (2 * A_E_43) - (zt + (zr - zt) * x / d) > 0
        runs = int(np.sum(above[1:] & ~above[:-1]) + (1 if above.size and above[0] else 0))
        out[r["link_id"]] = (min(runs, 4), float(r["htx_m"]), float(r["hrx_m"]))
    return out


def score_dir(cand):
    out = {}
    for drop in (False, True):
        comps, sites = hm.build(PARENT, "var", cand, "var", None, drop_screen=drop)
        res, comp, site = hm.summarize(comps, sites, {})
        out["screened" if drop else "full"] = dict(
            gain=comp["rms"] - comp["actual"], composite=comp["actual"],
            p2=res["p2"]["actual"], lt_level=res["lt_level"]["actual"], lt_shape=res["lt_shape"]["actual"])
        if not drop:
            out["sites"] = {s: site[s]["actual"] - site[s]["rms"] for s in hm.SITES}
    return out


def censored_share(rows, col="var_lb_50"):
    c = [r for r in rows if not uncensored(r)]
    return 100.0 * sum(1 for r in c if hm.fnum(r[col]) < hm.fnum(r["meas_lb_db"])) / len(c)


def write_and_score(p2_rows, lt_rows):
    with tempfile.TemporaryDirectory() as d:
        for name, rows in (("predictions_phase2.csv", p2_rows), ("predictions_longterm.csv", lt_rows)):
            if rows is None:
                shutil.copy(os.path.join(PARENT, name), d)
            else:
                with open(os.path.join(d, name), "w", newline="") as fh:
                    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
                    w.writeheader()
                    w.writerows(rows)
        return score_dir(d)


def hybrid():
    cls = obstacle_classes()
    base2 = hm.read_csv(os.path.join(PARENT, "predictions_phase2.csv"))
    basel = hm.read_csv(os.path.join(PARENT, "predictions_longterm.csv"))
    print("707 with another stored run on one class of rows. Gain is 707 minus hybrid (positive is better).")
    print("707 censored violations: %.1f %%" % censored_share(base2))
    others = [("000-baseline", "itm", "stock ITM"), ("708-deygout-isolated-clutter-at-r", "var", "708"),
              ("703-bullington-clutter", "var", "703")]
    print("\nPhase 2 rows by obstacle count (long-term rows stay 707):")
    print("%-28s %6s %8s %9s %9s  %s" % ("hybrid", "rows", "gain", "screened", "censored", "site RMS change R1 R2 R3 VA"))
    for tag, col, name in others:
        other = {r["link_id"]: r for r in hm.read_csv(os.path.join(ROOT, "experiments", tag, "predictions_phase2.csv"))}
        for k in list(range(5)) + [None]:
            new, n = [dict(r) for r in base2], 0
            for r in new:
                if k is None or cls[r["link_id"]][0] == k:
                    r["var_lb_50"] = other[r["link_id"]][col + "_lb_50"]
                    n += 1
            s = write_and_score(new, None)
            label = "%s on %s" % (name, "all rows" if k is None else ("4+" if k == 4 else str(k)) + " obstacles")
            print("%-28s %6d %+8.3f %+9.3f %8.1f%%  %s" % (
                label, n, s["full"]["gain"], s["screened"]["gain"], censored_share(new),
                " ".join("%+.2f" % s["sites"][x] for x in hm.SITES)))
    print("\nLong-term links by distance class (Phase 2 rows stay 707):")
    print("%-28s %6s %8s %9s" % ("hybrid", "links", "gain", "screened"))
    for tag, col, name in others:
        other = {r["link_id"]: r for r in hm.read_csv(os.path.join(ROOT, "experiments", tag, "predictions_longterm.csv"))}
        for label, pick in (("all", lambda d: True), ("< 100 km", lambda d: d < 100),
                            ("100-300 km", lambda d: 100 <= d < 300), (">= 300 km", lambda d: d >= 300)):
            new, n = [dict(r) for r in basel], 0
            for r in new:
                if pick(hm.fnum(r["d_km"])):
                    n += 1
                    for key in r:
                        if key.startswith("var_lb_"):
                            r[key] = other[r["link_id"]][key.replace("var", col, 1)]
            s = write_and_score(None, new)
            print("%-28s %6d %+8.3f %+9.3f" % (name + " on " + label, n, s["full"]["gain"], s["screened"]["gain"]))


def p2_cells(tag, col, with_bounds):
    """Phase 2 cell-balanced RMS; with_bounds adds censored rows with error min(0, predicted - bound)."""
    rows = hm.read_csv(os.path.join(ROOT, "experiments", tag, "predictions_phase2.csv"))
    use, err = [], []
    for r in rows:
        e = hm.fnum(r[col + "_lb_50"]) - hm.fnum(r["meas_lb_db"])
        if uncensored(r):
            use.append(r)
            err.append(e)
        elif with_bounds:
            use.append(r)
            err.append(min(0.0, e))
    w = hm.path_weights([r["path_id"] for r in use])
    e = np.array(err)
    cells = np.array([r["set"] + "|" + hm.disc(hm.fnum(r["f_mhz"]), hm.BAND_EDGES, hm.BAND_NAMES) for r in use])
    cell_rms = [math.sqrt((w[cells == c] * e[cells == c] ** 2).sum() / w[cells == c].sum()) for c in sorted(set(cells))]
    sets = np.array([r["set"] for r in use])
    site = {s: math.sqrt((w[sets == s] * e[sets == s] ** 2).sum() / w[sets == s].sum()) for s in hm.SITES}
    short = np.array([max(0.0, hm.fnum(r["meas_lb_db"]) - hm.fnum(r[col + "_lb_50"])) for r in rows if not uncensored(r)])
    depth = float(short[short > 0].mean()) if (short > 0).any() else 0.0
    return float(np.mean(cell_rms)), site, 100.0 * float((short > 0).mean()), depth


def frontier():
    print("Stored runs under the current 36-link screen. P2 = Phase 2 cell RMS; 'bounds' adds censored rows")
    print("scored as lower bounds. 'With bounds' composites replace the Phase 2 part by the bounds form.")
    print("%-36s %6s %6s | %6s %6s | %6s %6s | %8s %6s | %6s %6s | %s" % (
        "run", "full", "scr", "P2", "bounds", "LTfull", "LTscr", "censored", "depth", "b.full", "b.scr", "sites with bounds R1 R2 R3 VA"))
    for tag, name in RUNS:
        s = score_dir(os.path.join(ROOT, "experiments", tag))
        a, _, viol, depth = p2_cells(tag, "var", False)
        b, site, _, _ = p2_cells(tag, "var", True)
        bf = (b + s["full"]["lt_level"] + s["full"]["lt_shape"]) / 3
        bs = (b + s["screened"]["lt_level"] + s["screened"]["lt_shape"]) / 3
        print("%-36s %6.2f %6.2f | %6.2f %6.2f | %6.2f %6.2f | %7.1f%% %6.1f | %6.2f %6.2f | %s" % (
            name, s["full"]["composite"], s["screened"]["composite"], a, b, s["full"]["lt_level"],
            s["screened"]["lt_level"], viol, depth, bf, bs, " ".join("%.1f" % site[x] for x in hm.SITES)))
    a, _, viol, depth = p2_cells("000-baseline", "itm", False)
    b, site, _, _ = p2_cells("000-baseline", "itm", True)
    print("%-36s %6s %6s | %6.2f %6.2f | %6s %6s | %7.1f%% %6.1f | %6s %6s | %s" % (
        "stock ITM", "", "", a, b, "", "", viol, depth, "", "", " ".join("%.1f" % site[x] for x in hm.SITES)))


def strata():
    cls = obstacle_classes()
    rows = [r for r in hm.read_csv(os.path.join(PARENT, "predictions_phase2.csv")) if uncensored(r)]
    w = hm.path_weights([r["path_id"] for r in rows])
    f = np.array([hm.fnum(r["f_mhz"]) for r in rows])
    e7 = np.array([hm.fnum(r["var_lb_50"]) - hm.fnum(r["meas_lb_db"]) for r in rows])
    e0 = np.array([hm.fnum(r["itm_lb_50"]) - hm.fnum(r["meas_lb_db"]) for r in rows])
    low = np.array([min(cls[r["link_id"]][1], cls[r["link_id"]][2]) <= 3 for r in rows])
    clear = np.array([cls[r["link_id"]][0] == 0 for r in rows])
    sets = np.array([r["set"] for r in rows])
    print("Detected Phase 2 rows, path-weighted: mean / RMS error in dB (predicted minus measured).")
    print("%-12s %-8s %-11s %6s %-12s %14s %14s" % ("band", "antenna", "terrain", "rows", "sites", "707", "stock ITM"))
    for lo, hi, name in ((0, 150, "< 150 MHz"), (150, 300, "150-300"), (300, 1000, "300-1000"),
                         (1000, 3000, "1-3 GHz"), (3000, 1e9, "> 3 GHz")):
        for lw, lname in ((True, "<= 3 m"), (False, "> 3 m")):
            for cl, cname in ((True, "clear"), (False, "obstructed")):
                k = (f >= lo) & (f < hi) & (low == lw) & (clear == cl)
                if not k.any():
                    continue
                st = lambda e: "%+5.1f / %4.1f" % ((w[k] * e[k]).sum() / w[k].sum(),
                                                   math.sqrt((w[k] * e[k] ** 2).sum() / w[k].sum()))
                print("%-12s %-8s %-11s %6d %-12s %14s %14s" % (
                    name, lname, cname, int(k.sum()), ",".join(sorted(set(sets[k]))), st(e7), st(e0)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("report", choices=["hybrid", "frontier", "strata"])
    a = ap.parse_args()
    {"hybrid": hybrid, "frontier": frontier, "strata": strata}[a.report]()


if __name__ == "__main__":
    main()
