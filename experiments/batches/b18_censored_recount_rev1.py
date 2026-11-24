#!/usr/bin/env python3
"""Exact censored-bound recount for a model-only candidate (planner tool, B18).

Usage:  python3 experiments/batches/b18_censored_recount_rev1.py <deltas.csv> [<deltas.csv> ...]

For each Phase 2 censored row, the candidate's 50 % prediction is the
parent's stored prediction (707, predictions_phase2.csv) plus the model-only
change d_50 from the smoke test (b17_smoke_rev1.m output). A violation is a
prediction below the measured lower bound, as the evaluator's censored gate
counts it (FRAMEWORK.md acceptance rule 5). Reads the development bounds the
gate reads and no other measured value; never lockbox data.
Prints the share violated, its change from 707, and the split by site.
"""
import csv
import os
import sys
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PARENT = os.path.join(ROOT, "experiments", "707-cascaded-isolated-clutter-at-r", "predictions_phase2.csv")


def main(paths):
    rows = [r for r in csv.DictReader(open(PARENT)) if r["censored"] not in ("0", "false", "False")]
    base = [r for r in rows if float(r["var_lb_50"]) < float(r["meas_lb_db"])]
    b_site = Counter(r["set"] for r in base)
    print("707: %d of %d censored rows violated (%.1f %%); by site %s" % (
        len(base), len(rows), 100 * len(base) / len(rows), dict(b_site)))
    for p in paths:
        D = {r["link_id"]: float(r["d_50"]) for r in csv.DictReader(open(p))}
        miss = [r["link_id"] for r in rows if r["link_id"] not in D]
        if miss:
            sys.exit("error: %d censored rows have no change, e.g. %s" % (len(miss), miss[:3]))
        v = [r for r in rows if float(r["var_lb_50"]) + D[r["link_id"]] < float(r["meas_lb_db"])]
        site = Counter(r["set"] for r in v)
        share = 100 * len(v) / len(rows)
        print("%s: %d violated (%.1f %%, %+.1f points); by site %s" % (
            os.path.basename(p), len(v), share, share - 100 * len(base) / len(rows),
            {s: site.get(s, 0) - b_site.get(s, 0) for s in sorted(set(site) | set(b_site))}))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1:])
