"""B25 D25a summary from parts_rev1.csv (model only). Run: python3 -I experiments/batches/b25_summary_rev1.py"""
from pathlib import Path
import json
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "experiments/D25-spherical-reference"
T = pd.read_csv(D / "parts_rev1.csv")
T["d"] = T.loss_hyb - T.loss_707
T["smooth_707"] = np.maximum(T.A_s_itm - T.L_bs, 0)
T["smooth_hyb"] = np.maximum(T.L_dsph - T.L_bs, 0)
T["term_changed"] = (T.smooth_hyb - T.smooth_707).abs() > 0.01
T["kernel_diff"] = T.L_dsph - T.A_s_itm
g = T.groupby(["set", "mode_707"]).agg(rows=("d", "size"), mean_d=("d", "mean"), min_d=("d", "min"), max_d=("d", "max"),
                                         share_term_changed=("term_changed", "mean"),
                                         mean_kernel_diff=("kernel_diff", "mean"))
S = {"rows": int(len(T)), "share_term_changed": float(T.term_changed.mean()),
     "share_abs_d_gt_1dB": float((T.d.abs() > 1).mean()), "max_abs_d": float(T.d.abs().max()),
     "mode_changes": int((T.mode_707 != T.mode_hyb).sum()), "bound_changes": int((T.bound_707 != T.bound_hyb).sum())}
txt = "B25 D25a: hybrid (L_dsph) minus 707, Phase 2, 50 %\n\n" + g.round(3).to_string() + "\n\n" + json.dumps(S, indent=1) + "\n"
(D / "summary.txt").write_text(txt + "\n" + (D / "checks_rev1.json").read_text())
g.to_csv(D / "d25a_by_set_mode_rev1.csv")
print(txt)
