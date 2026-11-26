#!/usr/bin/env python3
"""B32 'Not done' items, descriptive only (no decision).

Usage: python3 -I d32_extras_rev1.py <D32 dir>

1. Clamp sensitivity: on rows whose measured receiver is 0.35 m and whose
   0.35 m cell passes the B32 exclusions, each model's loss change from a
   0.7 m to a 0.5 m receiver (clamp_sensitivity_rev1.csv). Two
   extrapolations to 0.35 m, both stated as assumptions: linear in height,
   dL * 0.15 / 0.2, and linear in log height, dL * ln(0.5/0.35) / ln(0.7/0.5).
   Either estimates how much higher each model's C_lo would be at 0.35 m;
   neither is a model run at 0.35 m.
2. Graham R5 (table 8, receiver 5): the B32 contrasts and per-path errors
   on its 10 paths, with the same exclusions; no interval (n <= 10).
Writes extras_rev1.json and prints a summary.
"""
import csv, json, math, os, sys
import numpy as np

def truthy(v):
    return str(v).strip().lower() in ("true", "1")

def bad(r):
    return any(truthy(r[k]) for k in ("missing", "lower_bound", "questionable", "uncertain"))

def main():
    d = sys.argv[1]
    out = {}
    # 1. clamp sensitivity
    C = [r for r in csv.DictReader(open(os.path.join(d, "clamp_sensitivity_rev1.csv")))
         if not bad(r) and not (r["table"] == "8" and r["rx"] == "5")]
    lin, lg = 0.15 / 0.2, math.log(0.5 / 0.35) / math.log(0.7 / 0.5)
    res = {}
    for b in ("VHF", "UHF"):
        rows = [r for r in C if r["band"] == b]
        for m, p in (("707", "L707"), ("stock", "Lst")):
            d57 = np.array([float(r[p + "_h050"]) - float(r[p + "_h070"]) for r in rows])
            d71 = np.array([float(r[p + "_h070"]) - float(r[p + "_h100"]) for r in rows])
            res[f"{b}_{m}"] = {"n": len(rows), "median_dL_0.5_to_0.7": float(np.median(d57)),
                               "p10": float(np.percentile(d57, 10)), "p90": float(np.percentile(d57, 90)),
                               "median_dL_0.7_to_1.0": float(np.median(d71)),
                               "median_extrap_linear": float(np.median(d57) * lin),
                               "median_extrap_loglinear": float(np.median(d57) * lg)}
    out["clamp_sensitivity"] = res
    # 2. Graham R5
    P = [r for r in csv.DictReader(open(os.path.join(d, "predictions_rev1.csv"))) if r["table"] == "8" and r["rx"] == "5"]
    cell = {(r["tx"], r["band"], float(r["rx_ant_m"])): r for r in P}
    r5 = {}
    for b in ("VHF", "UHF"):
        for c, (lo, hi) in (("hi", (3.0, 10.0)), ("lo", (0.35, 3.0))):
            e7, es = [], []
            for tx in sorted({k[0] for k in cell}, key=int):
                a, u = cell[(tx, b, lo)], cell[(tx, b, hi)]
                if bad(a) or bad(u):
                    continue
                cm = float(a["loss_db"]) - float(u["loss_db"])
                e7.append(float(a["L_707_db"]) - float(u["L_707_db"]) - cm)
                es.append(float(a["L_stock_db"]) - float(u["L_stock_db"]) - cm)
            e7, es = np.array(e7), np.array(es)
            r5[f"{b}_{c}"] = {"n_paths": len(e7),
                              "mae_707": float(np.mean(np.abs(e7))) if len(e7) else None,
                              "mae_stock": float(np.mean(np.abs(es))) if len(es) else None,
                              "mean_e_707": float(np.mean(e7)) if len(e7) else None,
                              "mean_e_stock": float(np.mean(es)) if len(es) else None}
    out["graham_r5"] = r5
    json.dump(out, open(os.path.join(d, "extras_rev1.json"), "w"), indent=2)
    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
