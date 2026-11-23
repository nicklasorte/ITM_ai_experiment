#!/usr/bin/env python3
"""Ceilings for a family of changes, from the parent's stored predictions (planner tool).

History matching rules out candidates before they run (hm_screen_rev1.py).
This tool rules out whole families before they're built. It asks: if a
change removed every cell-mean error of one kind perfectly, how much would
the composite gain? A sourced model that depends smoothly on frequency
band, distance class and time percentage can't do better than that on the
cell-balanced score, unless it brings path-specific information that
reduces the spread inside cells.

Three reports, all for the parent run (default 707):

  parts      Composite gain if every cell mean were zero, by score part
             (Phase 2 level, long-term level, long-term shape).
  variability
             Composite gain if the long-term shape bias (L_p - L_50) were
             removed in every band x distance cell, for the fading side
             (90, 99 %), the enhancement side (1, 10 %) and both. Cell
             means are taken over all links, and over kept links only
             (36-link screen), to bracket the answer.
  hybrid     Score of a hybrid of two stored runs: the parent everywhere,
             except the long-term percentiles listed in --take, which come
             from --other. Example: 707 with D06a's fading side.

Reads development data only (the parent's and other stored runs'
predictions); never lockbox data. Reuses the score replica in
hm_screen_rev1.py, which reproduces metrics.json.

Usage (from the repository root):
  python3 experiments/batches/hm_ceiling_rev1.py parts
  python3 experiments/batches/hm_ceiling_rev1.py variability
  python3 experiments/batches/hm_ceiling_rev1.py hybrid --other experiments/D06a-p617-time-mode3 --take 90 99
"""
import argparse
import csv
import os
import shutil
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import hm_screen_rev1 as hm

PARENT = os.path.join(hm.ROOT, "experiments", "707-cascaded-isolated-clutter-at-r")
TAGS = {"0.01": "0_01", "0.1": "0_1", "1": "1", "10": "10", "50": "50", "90": "90", "99": "99",
        "99.9": "99_9", "99.99": "99_99"}


def score(parent, cand):
    out = {}
    for drop in (False, True):
        comps, sites = hm.build(parent, "var", cand, "var", None, drop_screen=drop)
        res, comp, _ = hm.summarize(comps, sites, {})
        out["screened" if drop else "full"] = dict(
            gain=comp["rms"] - comp["actual"], composite=comp["actual"],
            **{k: res[k]["actual"] for k in ("p2", "lt_level", "lt_shape")})
    return out


def show(label, s):
    print(f"{label:44s} full gain {s['full']['gain']:+.3f} (level {s['full']['lt_level']:.2f}, shape {s['full']['lt_shape']:.2f}); "
          f"screened gain {s['screened']['gain']:+.3f} (level {s['screened']['lt_level']:.2f}, shape {s['screened']['lt_shape']:.2f})")


def parts(parent):
    for drop in (False, True):
        comps, sites = hm.build(parent, "var", parent, "var", None, drop_screen=drop)
        tot, tot0 = [], []
        print("screened composite:" if drop else "full composite:")
        for name in ("p2", "lt_level", "lt_shape"):
            v = np.mean([np.mean([c["rms"] for c in g.cell_stats().values()]) for g in comps[name]])
            v0 = np.mean([np.mean([c["s_e"] for c in g.cell_stats().values()]) for g in comps[name]])
            tot.append(v); tot0.append(v0)
            print(f"  {name:9s} {v:6.2f} -> {v0:6.2f} if every cell mean were zero (composite gain {(v - v0) / 3:+.2f})")
        print(f"  all parts: composite {np.mean(tot):.2f} -> {np.mean(tot0):.2f} (gain {np.mean(tot) - np.mean(tot0):+.2f})")


def variability(parent):
    rows = hm.read_csv(os.path.join(parent, "predictions_longterm.csv"))
    drop = hm.screen_ids()
    w = hm.path_weights([r["path_id"] for r in rows])
    cell = [hm.disc(hm.fnum(r["f_mhz"]), hm.LT_BAND_EDGES, hm.LT_BAND_NAMES) + "|" +
            hm.disc(hm.fnum(r["d_km"]), hm.LT_DIST_EDGES, hm.LT_DIST_NAMES) for r in rows]
    for label, ps in (("fading side (90, 99 %)", ["90", "99"]), ("enhancement side (1, 10 %)", ["1", "10"]),
                      ("both sides", ["1", "10", "90", "99"])):
        for kept_only in (False, True):
            new = [dict(r) for r in rows]
            for t in ps:
                e = np.array([(hm.fnum(r[f"var_lb_{t}"]) - hm.fnum(r["var_lb_50"])) -
                              (hm.fnum(r[f"meas_lb_{t}"]) - hm.fnum(r["meas_lb_50"])) for r in rows])
                use = np.isfinite(e) & np.array([(r["link_id"] not in drop) or not kept_only for r in rows])
                for c in set(cell):
                    k = use & (np.array(cell) == c)
                    if not k.any():
                        continue
                    m = (w[k] * e[k]).sum() / w[k].sum()
                    for i in np.flatnonzero(np.array(cell) == c):
                        v = hm.fnum(rows[i][f"var_lb_{t}"])
                        if np.isfinite(v):
                            new[i][f"var_lb_{t}"] = repr(float(v - m))
            with tempfile.TemporaryDirectory() as d:
                with open(os.path.join(d, "predictions_longterm.csv"), "w", newline="") as fh:
                    wr = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
                    wr.writeheader(); wr.writerows(new)
                shutil.copy(os.path.join(parent, "predictions_phase2.csv"), d)
                show(f"{label}, means from {'kept' if kept_only else 'all'} links", score(parent, d))


def hybrid(parent, other, take):
    a = hm.read_csv(os.path.join(parent, "predictions_longterm.csv"))
    b = {r["link_id"]: r for r in hm.read_csv(os.path.join(other, "predictions_longterm.csv"))}
    for r in a:
        for t in take:
            r[f"var_lb_{TAGS[t]}"] = b[r["link_id"]][f"var_lb_{TAGS[t]}"]
    with tempfile.TemporaryDirectory() as d:
        with open(os.path.join(d, "predictions_longterm.csv"), "w", newline="") as fh:
            wr = csv.DictWriter(fh, fieldnames=list(a[0].keys()))
            wr.writeheader(); wr.writerows(a)
        shutil.copy(os.path.join(parent, "predictions_phase2.csv"), d)
        show(f"parent with {os.path.basename(other)} at {', '.join(take)} %", score(parent, d))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("report", choices=["parts", "variability", "hybrid"])
    ap.add_argument("--parent", default=PARENT)
    ap.add_argument("--other")
    ap.add_argument("--take", nargs="+", default=["90", "99"])
    a = ap.parse_args()
    if a.report == "parts":
        parts(a.parent)
    elif a.report == "variability":
        variability(a.parent)
    else:
        if not a.other:
            sys.exit("error: hybrid needs --other")
        hybrid(a.parent, a.other, a.take)


if __name__ == "__main__":
    main()
