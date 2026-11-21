#!/usr/bin/env python3
"""Censored violations on R2's no-signal rows by number of Deygout edges (D03 geometry).

Usage, from the repository root:
    python3 experiments/D03-r2-dead-paths/violations_by_edges_rev1.py <experiment tag> [<tag> ...]
Reads experiments/<tag>/predictions_phase2.csv and D03's rows_rev1.csv.
Prints, per tag, the share of R2 no-signal rows whose predicted loss is
below the measured bound, by edge count (0-1, 2, 3, 4+), and the mean error
on R2's measured rows by the same edge count. Diagnostic only.
"""
import sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
G = pd.read_csv(ROOT / "experiments/D03-r2-dead-paths/rows_rev1.csv")[["link_id", "n_edges"]]
for tag in sys.argv[1:]:
    P = pd.read_csv(ROOT / "experiments" / tag / "predictions_phase2.csv").merge(G, on="link_id")
    R = P[P.set == "R2"].copy()
    R["edges"] = pd.cut(R.n_edges, [-1, 1, 2, 3, 99], labels=["0-1", "2", "3", "4+"])
    dead = R[R.censored == 1]
    meas = R[R.censored == 0]
    v = (dead.var_lb_50 < dead.meas_lb_db).groupby(dead.edges, observed=True).agg(["mean", "size"])
    e = (meas.var_lb_50 - meas.meas_lb_db).groupby(meas.edges, observed=True).mean()
    print(tag)
    for k in v.index:
        print(f"  edges {k:>3}: dead rows violated {100 * v.loc[k, 'mean']:5.1f} % of {int(v.loc[k, 'size']):4d};"
              f" measured-row mean error {e.get(k, float('nan')):+6.1f} dB")
