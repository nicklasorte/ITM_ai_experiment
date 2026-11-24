"""Apply LOCKBOX_REGISTRATION_rev2.md sections 4 and 5 to scored lockbox files (for Nick).

Usage:
  python3 -I summarize_lockbox_rev1.py <out_dir> <set_name> <kind>

<kind> is the prediction that applies, from registration section 5:
  low_antenna   ITS low antenna height (230, 416 MHz)
  vhf           ITS Phase 1 VHF (20 to 100 MHz)
  report_only   DBSG3 Table VI-2 (no verdict)

Reads <out_dir>/<set_name>_{707,R02,R03}_rev1.csv from score_lockbox_rev1.m
(707 is required; R02 and R03 are used if present) and writes
<out_dir>/<set_name>_summary_rev1.md. A file whose name starts with TEST_
is never read as a result; pass the TEST_ prefix in set_name to check the
script on development rows.

Section 4 rule: per set, never pooled. Primary metric: RMS error at 50 %
on uncensored rows, 707 minus stock ITM, paired path bootstrap 95 %
(2,000 draws). 707 confirms if the point estimate meets the set's
prediction and the interval excludes zero in that direction; fails if the
interval excludes zero the other way; otherwise inconclusive. With a site
column and 3 or more sites, a site-cluster bootstrap is reported beside it.
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

OUT, SET, KIND = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
if KIND not in ("low_antenna", "vhf", "report_only"):
    raise SystemExit(f"unknown kind {KIND!r}")
TEST = SET.startswith("TEST_")
RNG = np.random.default_rng(20261124)
B = 2000

# Section 5 predictions: gain = RMS(stock) - RMS(707), dB
PRED = {
    "low_antenna": {"gain": (1.0, 6.0), "mean": None,
                    "text": "707 beats stock; pooled gain 1 to 6 dB (larger on rough terrain)"},
    "vhf": {"gain": (1.0, 4.0), "mean": (-4.0, 4.0),
            "text": "707 beats stock by 1 to 4 dB; 707 mean error between -4 and +4 dB"},
    "report_only": None,
}


def load(model):
    f = OUT / f"{SET}_{model}_rev1.csv"
    if not f.exists():
        if model == "707":
            raise SystemExit(f"missing {f}")
        return None
    d = pd.read_csv(f)
    return d.rename(columns={"model_lb_50": f"lb_{model}"})


base = load("707")
for m in ("R02", "R03"):
    x = load(m)
    if x is not None:
        if len(x) != len(base) or not (x.link_id.values == base.link_id.values).all():
            raise SystemExit(f"{m} rows don't match 707's")
        base[f"lb_{m}"] = x[f"lb_{m}"].values
d = base
d["lb_stock"] = d.itm_lb_50
if "censored" not in d:
    d["censored"] = 0
models = ["stock", "707"] + [m for m in ("R02", "R03") if f"lb_{m}" in d] + \
         [m for m, c in (("P452", "p452_lb_50"), ("P2001", "p2001_lb_50")) if c in d]
if "p452_lb_50" in d: d["lb_P452"] = d.p452_lb_50
if "p2001_lb_50" in d: d["lb_P2001"] = d.p2001_lb_50

u = d[d.censored == 0].copy()
c = d[d.censored != 0]
for m in models:
    u["e_" + m] = u["lb_" + m] - u.meas_lb_db


def rms(e):
    return float(np.sqrt(np.mean(np.square(e))))


def boot(g, a, b, unit):
    groups = g[unit].to_numpy()
    keys = np.unique(groups)
    idx = {k: np.flatnonzero(groups == k) for k in keys}
    ea, eb = g["e_" + a].to_numpy(), g["e_" + b].to_numpy()
    out = np.empty(B)
    for i in range(B):
        s = np.concatenate([idx[k] for k in RNG.choice(keys, len(keys))])
        out[i] = rms(ea[s]) - rms(eb[s])
    return np.percentile(out, [2.5, 97.5])


lines = [f"# Lockbox result: {SET}", ""]
if TEST:
    lines += ["**TEST RUN on development rows. Not a lockbox result.**", ""]
lines += [f"Rows: {len(d)} ({len(u)} uncensored, {len(c)} censored); paths: {u.path_id.nunique()}.", ""]

# Primary endpoint
diff = rms(u.e_707) - rms(u.e_stock)              # 707 minus stock; negative = 707 better
lo, hi = boot(u, "707", "stock", "path_id")
gain = -diff
lines += ["## Primary endpoint (registration section 4)", "",
          f"RMS 707 minus stock ITM: {diff:+.2f} dB (paired path bootstrap 95 %: {lo:+.2f} to {hi:+.2f}).",
          f"Gain over stock: {gain:.2f} dB."]
if "site" in u and u.site.nunique() >= 3:
    slo, shi = boot(u, "707", "stock", "site")
    lines.append(f"Site-cluster bootstrap ({u.site.nunique()} sites): {slo:+.2f} to {shi:+.2f}.")
p = PRED[KIND]
if p is None:
    verdict = "REPORT ONLY (no verdict)"
else:
    # Rule as amended 2026-11-24 (registration section 4): direction decides;
    # the predicted gain range is a calibration check reported beside it.
    mean_ok = True
    if p["mean"] is not None:
        mean707 = u.e_707.mean()
        mean_ok = p["mean"][0] <= mean707 <= p["mean"][1]
    if hi < 0 and mean_ok:
        verdict = "CONFIRMS"
    elif lo > 0:
        verdict = "FAILS"
    else:
        verdict = "INCONCLUSIVE"
    in_range = p["gain"][0] <= gain <= p["gain"][1]
    lines += ["", f"Prediction: {p['text']}.",
              f"Calibration check (not part of the verdict): gain inside the predicted "
              f"{p['gain'][0]:g} to {p['gain'][1]:g} dB: {'yes' if in_range else 'no'}."]
    if p["mean"] is not None:
        lines.append(f"707 mean error {mean707:+.2f} dB; inside {p['mean'][0]:g} to {p['mean'][1]:+g} dB: "
                     f"{'yes' if mean_ok else 'no'} (part of the verdict).")
lines += ["", f"**Verdict: {verdict}**", ""]

# Secondary (no verdicts)
lines += ["## Secondary metrics (no verdicts)", "", "| Model | RMS | Mean | Censored violations |", "| --- | --- | --- | --- |"]
for m in models:
    ok = u["e_" + m].notna()
    cc = c[c["lb_" + m].notna()]
    cv = f"{100 * (cc['lb_' + m] < cc.meas_lb_db).mean():.1f} %" if len(cc) else "none censored"
    note = "" if ok.all() else f" ({ok.sum()} rows with a value)"
    lines.append(f"| {m}{note} | {rms(u.loc[ok, 'e_' + m]):.2f} | {u.loc[ok, 'e_' + m].mean():+.2f} | {cv} |")
for m in [x for x in models if x not in ("stock", "707")]:
    g = u[u["e_" + m].notna()]
    a, b = boot(g, m, "707", "path_id")
    lines.append(f"\n{m} minus 707 RMS, on its {len(g)} rows: {rms(g['e_' + m]) - rms(g.e_707):+.2f} dB (95 %: {a:+.2f} to {b:+.2f}).")
u["band"] = pd.cut(u.f_mhz, [0, 50, 100, 300, 1000, 3000, 1e5],
                   labels=["<50 MHz", "50-100 MHz", "100-300 MHz", "300 MHz-1 GHz", "1-3 GHz", ">3 GHz"])
lines += ["", "### By band", "", "| Band | Rows | RMS stock | RMS 707 | Mean 707 |", "| --- | --- | --- | --- | --- |"]
for bnd, g in u.groupby("band", observed=True):
    lines.append(f"| {bnd} | {len(g)} | {rms(g.e_stock):.2f} | {rms(g.e_707):.2f} | {g.e_707.mean():+.2f} |")
if "site" in u:
    lines += ["", "### By site", "", "| Site | Rows | RMS stock | RMS 707 | Mean 707 |", "| --- | --- | --- | --- | --- |"]
    for s, g in u.groupby("site"):
        lines.append(f"| {s} | {len(g)} | {rms(g.e_stock):.2f} | {rms(g.e_707):.2f} | {g.e_707.mean():+.2f} |")

out = OUT / f"{SET}_summary_rev1.md"
out.write_text("\n".join(lines) + "\n")
print("\n".join(lines))
