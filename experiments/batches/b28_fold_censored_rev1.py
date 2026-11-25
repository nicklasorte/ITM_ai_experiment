"""B28: training-fold censored-violation rates, 707 versus stock ITM.

Reproduces the constraint in eval/cv_calibrate_rev1.m objective_constrained
(training censored % <= stock ITM training censored % + 1) at ITM's own
constants, from experiments/707r-rescore-screen36/predictions_phase2.csv
(var_lb_50 = 707, itm_lb_50 = stock) and data/splits/folds_rev1.csv.
A violation is a censored row predicted below its measured bound.

Usage: python3 -I experiments/batches/b28_fold_censored_rev1.py
"""
import os
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
p = pd.read_csv(os.path.join(ROOT, "experiments/707r-rescore-screen36/predictions_phase2.csv"))
f = pd.read_csv(os.path.join(ROOT, "data/splits/folds_rev1.csv"))
p = p.merge(f[["path_id", "fold"]], on="path_id", how="left")
if p.fold.isna().any():
    raise SystemExit("B28 STOP: rows without a fold")
c = p[p.censored == 1]
pct = lambda d, col: 100.0 * (d[col] < d.meas_lb_db).mean()
rows = [{"fold": "all", "held_out": "none", "train_censored_rows": len(c),
         "pct_707": pct(c, "var_lb_50"), "pct_stock": pct(c, "itm_lb_50")}]
for k in sorted(p.fold.unique()):
    t = c[c.fold != k]
    held = ",".join(sorted(p[p.fold == k].set.unique())) or "longterm only"
    rows.append({"fold": int(k), "held_out": held, "train_censored_rows": len(t),
                 "pct_707": pct(t, "var_lb_50"), "pct_stock": pct(t, "itm_lb_50")})
out = pd.DataFrame(rows)
out["limit_stock_plus_1"] = out.pct_stock + 1
out["707_meets_censored_constraint_at_itm_constants"] = out.pct_707 <= out.limit_stock_plus_1
od = os.path.join(ROOT, "experiments/B28-calibration-attempt")
os.makedirs(od, exist_ok=True)
out.round(2).to_csv(os.path.join(od, "fold_censored_rev1.csv"), index=False)
print(out.round(2).to_string(index=False))
