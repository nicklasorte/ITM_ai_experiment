#!/usr/bin/env python3
"""Model-discrepancy floor per score cell (planner tool, rev 1).

Any model whose output depends only on its inputs (terrain profile,
frequency, antenna heights, polarization, climate, N_0, siting) must give
the same prediction to rows with identical inputs. When those rows have
different measurements, the spread around their weighted group mean can't
be removed by any such model: it is the Bayes error of the fixed inputs.
For one score cell with path weights w,

    floor^2 = sum over rows in identical-input groups of w (y - ybar_g)^2  /  sum of all w in the cell

where ybar_g is the w-weighted mean of the group. Rows outside such groups
add zero, because a model could in principle fit them exactly. This is a
strict lower bound on the cell's weighted RMS; it uses measurements only,
never a model.

Where the data has identical-input groups:
  - Long-term: the same path, frequency and antenna heights measured in
    different years or for different periods (year and record length aren't
    model inputs). Floors are computed for every level percentile and for the
    shape error (L_p - L_50).
  - Phase 2: none. Every row has distinct inputs, so the floor isn't
    identifiable from the data and is written as 0 (no constraint).

The screen uses these floors with --floor (hm_screen_rev1.py): a cell's
best-case RMS can't fall below its floor.

Output: results/model_floor_rev1.csv with columns
  component, cell, floor_db, n_rows, n_group_rows, n_groups
component is p2, lt_level_<p> or lt_shape_<p>, matching hm_screen_rev1.py.

Usage (from the repository root):  python3 experiments/batches/model_floor_rev1.py
"""
import csv
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(__file__))
import hm_screen_rev1 as hm  # shared bins and helpers

ROOT = hm.ROOT
LT_KEY = ("path_id", "f_mhz", "htx_m", "hrx_m", "pol")
P2_KEY = ("path_id", "f_mhz", "htx_m", "hrx_m", "pol", "siting")


def floor_for(rows, values, cells):
    """rows: dicts; values: measured quantity per row; cells: cell name per row."""
    w = hm.path_weights([r["path_id"] for r in rows])
    by_cell = defaultdict(list)
    for i, c in enumerate(cells):
        by_cell[c].append(i)
    out = {}
    for c, idx in by_cell.items():
        W = sum(w[i] for i in idx)
        groups = defaultdict(list)
        for i in idx:
            groups[tuple(rows[i][k] for k in LT_KEY)].append(i)
        ss, n_rows_g, n_g = 0.0, 0, 0
        for g in groups.values():
            if len(g) < 2:
                continue
            wg = sum(w[i] for i in g)
            yb = sum(w[i] * values[i] for i in g) / wg
            ss += sum(w[i] * (values[i] - yb) ** 2 for i in g)
            n_rows_g += len(g)
            n_g += 1
        out[c] = (math.sqrt(ss / W), len(idx), n_rows_g, n_g)
    return out


def main():
    lt = hm.read_csv(os.path.join(ROOT, "data", "links", "longterm_links_rev1.csv"))
    p2 = hm.read_csv(os.path.join(ROOT, "data", "links", "phase2_links_rev1.csv"))
    rows_out = []

    # Phase 2: check there really are no identical-input groups
    seen = defaultdict(int)
    for r in p2:
        if r["censored"] in ("0", "false", "False"):
            seen[tuple(r[k] for k in P2_KEY)] += 1
    dup = sum(1 for v in seen.values() if v > 1)
    if dup:
        sys.exit(f"error: Phase 2 has {dup} identical-input groups; extend this tool before using a 0 floor")
    p2u = [r for r in p2 if r["censored"] in ("0", "false", "False")]
    for c in sorted({r["set"] + "|" + hm.disc(hm.fnum(r["f_mhz"]), hm.BAND_EDGES, hm.BAND_NAMES) for r in p2u}):
        rows_out.append(dict(component="p2", cell=c, floor_db=0.0, n_rows="", n_group_rows=0, n_groups=0))

    cell_of = lambda r: hm.disc(hm.fnum(r["f_mhz"]), hm.LT_BAND_EDGES, hm.LT_BAND_NAMES) + "|" + \
        hm.disc(hm.fnum(r["d_km"]), hm.LT_DIST_EDGES, hm.LT_DIST_NAMES)
    for t in hm.P_SCORED:
        k = [r for r in lt if math.isfinite(hm.fnum(r[f"meas_lb_{t}"]))]
        f = floor_for(k, [hm.fnum(r[f"meas_lb_{t}"]) for r in k], [cell_of(r) for r in k])
        for c, (fl, n, ng, g) in sorted(f.items()):
            rows_out.append(dict(component=f"lt_level_{t}", cell=c, floor_db=round(fl, 4), n_rows=n, n_group_rows=ng, n_groups=g))
        if t != "50":
            k2 = [r for r in k if math.isfinite(hm.fnum(r["meas_lb_50"]))]
            f = floor_for(k2, [hm.fnum(r[f"meas_lb_{t}"]) - hm.fnum(r["meas_lb_50"]) for r in k2], [cell_of(r) for r in k2])
            for c, (fl, n, ng, g) in sorted(f.items()):
                rows_out.append(dict(component=f"lt_shape_{t}", cell=c, floor_db=round(fl, 4), n_rows=n, n_group_rows=ng, n_groups=g))

    out = os.path.join(ROOT, "results", "model_floor_rev1.csv")
    with open(out, "w", newline="") as fh:
        wr = csv.DictWriter(fh, fieldnames=["component", "cell", "floor_db", "n_rows", "n_group_rows", "n_groups"])
        wr.writeheader()
        wr.writerows(rows_out)
    print(f"wrote {out}: {len(rows_out)} cells")


if __name__ == "__main__":
    main()
