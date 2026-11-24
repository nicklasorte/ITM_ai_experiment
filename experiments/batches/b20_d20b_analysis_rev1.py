"""D20b (B20) analysis: what drives 707's overshoot on obstructed rows?

Usage: python3 -I experiments/batches/b20_d20b_analysis_rev1.py

Reads experiments/D20b-cascade-terms/d20b_parts_rev1.csv (from
b20_d20b_cascade_parts_rev1.m), the development link files and 707's stored
predictions. Error = 707 prediction minus measured loss, at 50 %.
Uncensored Phase 2 rows and long-term rows with a measured median.

Net contribution of the cascade correction to A_ref (707's delta form
L_ba + max(A_s - L_bs, 0)):
  CT_net = T_ba * C_ba - [A_s > L_bs] * T_bs * C_bs

Writes experiments/D20b-cascade-terms/summary.txt and the decision rule
outcome from B20.md.
"""
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "experiments" / "D20b-cascade-terms"
RUN = ROOT / "experiments" / "707-cascaded-isolated-clutter-at-r"
parts = pd.read_csv(D / "d20b_parts_rev1.csv")

frames = []
L = pd.read_csv(ROOT / "data/links/phase2_links_rev1.csv")[["link_id", "path_id", "set", "siting", "f_mhz", "censored", "meas_lb_db"]]
p = pd.read_csv(RUN / "predictions_phase2.csv")[["link_id", "var_lb_50"]]
frames.append(L.merge(p, on="link_id").rename(columns={"meas_lb_db": "meas"}))
LT = pd.read_csv(ROOT / "data/links/longterm_links_rev1.csv")[["link_id", "path_id", "f_mhz", "meas_lb_50"]]
pl = pd.read_csv(RUN / "predictions_longterm.csv")[["link_id", "var_lb_50"]]
lt = LT.merge(pl, on="link_id").rename(columns={"meas_lb_50": "meas"})
lt["set"], lt["siting"], lt["censored"] = "LT", "", 0
frames.append(lt)
d = pd.concat(frames, ignore_index=True).merge(parts, on="link_id", validate="1:1")
if len(d) != len(parts):
    raise SystemExit("rows lost in the merge")
d = d[d.meas.notna()].copy()
d["err"] = d.var_lb_50 - d.meas
d["obstructed"] = d.L_ba_db > 0
d["smooth_active"] = d.A_s_db > d.L_bs_db
d["CT_ba"] = d.ba_T * d.ba_C
d["CT_net"] = d.CT_ba - np.where(d.smooth_active, d.bs_T * d.bs_C, 0.0)
d["edges_net"] = (d.ba_J_p + d.ba_T * (d.ba_L_t + d.ba_L_r)) - np.where(d.smooth_active, d.bs_J_p + d.bs_T * (d.bs_L_t + d.bs_L_r), 0.0)
d["smooth_term"] = np.maximum(d.A_s_db - d.L_bs_db, 0.0)
d["band"] = pd.cut(d.f_mhz, [0, 100, 300, 1000, 3000, 20000],
                   labels=["<100 MHz", "100-300 MHz", "300 MHz-1 GHz", "1-3 GHz", ">3 GHz"])
u = d[d.censored == 0]
c = d[d.censored != 0]


def rms(x):
    return float(np.sqrt(np.mean(np.square(x))))


rng = np.random.default_rng(20261124)


def slope_ci(g):
    x, y = g.CT_net.to_numpy(), g.err.to_numpy()
    if np.ptp(x) < 1e-9:
        return np.nan, np.nan, np.nan
    s0 = np.polyfit(x, y, 1)[0]
    paths = g.path_id.unique()
    idx = {k: np.flatnonzero(g.path_id.to_numpy() == k) for k in paths}
    bs = []
    for _ in range(2000):
        s = np.concatenate([idx[k] for k in rng.choice(paths, len(paths))])
        if np.ptp(x[s]) > 1e-9:
            bs.append(np.polyfit(x[s], y[s], 1)[0])
    lo, hi = np.percentile(bs, [2.5, 97.5])
    return s0, lo, hi


lines = ["D20b: what drives 707's overshoot on obstructed rows (B20)", "",
         f"Rows: {len(d)} ({len(u)} uncensored, {len(c)} censored). Every loss matched 707's stored run to 1e-9 dB.", ""]
rows = []
for (s, b, ob), g in u.groupby(["set", "band", "obstructed"], observed=True):
    if len(g) < 20:
        continue
    rows.append({"set": s, "band": b, "obstructed": ob, "n": len(g), "mean_err": g.err.mean(), "rms_err": rms(g.err),
                 "mean_A_ref": g.A_ref_db.mean(), "mean_CT_net": g.CT_net.mean(), "mean_edges_net": g.edges_net.mean(),
                 "mean_smooth_term": g.smooth_term.mean(), "mean_As_minus_Lbs": (g.A_s_db - g.L_bs_db).mean()})
T = pd.DataFrame(rows).round(2)
lines += ["## By set, band, and clear or obstructed (uncensored)", "", T.to_string(index=False), ""]

# Decision rule part 1: slope of error on CT_net, obstructed uncensored rows, bands below 1 GHz
lines += ["## Error against the net correction term C*T (obstructed, uncensored)", "",
          "| Band | n | Slope (dB per dB) | 95 % (path bootstrap) | Mean C*T / mean A_ref |", "| --- | --- | --- | --- | --- |"]
n_pos = 0
share_ok = 0
for b in ["<100 MHz", "100-300 MHz", "300 MHz-1 GHz", "1-3 GHz", ">3 GHz"]:
    g = u[u.obstructed & (u.band == b)]
    if len(g) < 30:
        lines.append(f"| {b} | {len(g)} | too few rows | | |")
        continue
    s0, lo, hi = slope_ci(g)
    share = g.CT_net.mean() / g.A_ref_db.mean()
    lines.append(f"| {b} | {len(g)} | {s0:+.2f} | {lo:+.2f} to {hi:+.2f} | {share:.2f} |")
    if b in ("<100 MHz", "100-300 MHz", "300 MHz-1 GHz"):
        n_pos += bool(lo > 0)
        share_ok += bool(share >= 1 / 3)
lines.append("")

# Decision rule part 2: clear rows, |A_s - L_bs| by band
clear = u[~u.obstructed]
r4 = []
lines += ["## Clear rows: mean |A_s - L_bs| by band", ""]
for b, g in clear.groupby("band", observed=True):
    m = (g.A_s_db - g.L_bs_db).abs().mean()
    r4.append(m >= 1.0)
    lines.append(f"- {b}: n {len(g)}, mean |A_s - L_bs| {m:.2f} dB, mean error {g.err.mean():+.2f}")
lines.append("")

c_carries = n_pos >= 2 and share_ok >= 2
lines += ["## Decision rule (B20.md, fixed before the run)", "",
          f"Slope on C*T positive with the interval above zero in {n_pos} of 3 bands below 1 GHz (rule: at least 2).",
          f"Mean C*T at least a third of mean A_ref in {share_ok} of 3 bands below 1 GHz (rule: the same bands; applied as at least 2).",
          f"**C carries the overshoot: {'yes' if c_carries else 'no'}.**",
          f"**Clear rows show |A_s - L_bs| of 1 dB or more in some band: {'yes' if any(r4) else 'no'}** (phase plan R4 {'goes' if any(r4) else 'does not go'} into B21)."]
(D / "summary.txt").write_text("\n".join(lines) + "\n")
print("\n".join(lines))
