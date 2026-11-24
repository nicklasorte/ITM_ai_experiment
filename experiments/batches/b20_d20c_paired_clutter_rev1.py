"""D20c (B20): is 707's P.2108-1 terminal clutter term physics or an offset?

Usage: python3 -I experiments/batches/b20_d20c_paired_clutter_rev1.py

Matched pairs: Phase 2 rows with siting C and O on the same base path (path_id
without its _C or _O suffix), frequency and antenna heights.

CORRECTION (2026-11-24, raised in ChatGPT's post-B20 review, confirmed in the
code): 707's predicted difference pred(C) - pred(O) is NOT the clutter term
alone. With terminal_clutter_base = "clutter_height" the core runs the whole
concealed path with the mobile antenna at max(h, R) and then adds the
P.2108-1 term A_h. The difference is that height change plus A_h. The earlier
claim that the other terms were checked as identical was wrong: no such
check was run. The numbers below test 707's full concealed-terminal
treatment, not P.2108-1's A_h in isolation (B23 D23b separates them).

Compares, on pairs with both rows uncensored:
- P.2108-1 (707's predicted difference)
- the 704 constant control (terminal_clutter_db from 704's metrics.json)
- a constant refitted on the training sites only (leave-one-site-out)
- zero (no clutter term)

Development data only. Writes experiments/D20c-paired-clutter/.
"""
import json
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "experiments" / "D20c-paired-clutter"
OUT.mkdir(parents=True, exist_ok=True)

L = pd.read_csv(ROOT / "data/links/phase2_links_rev1.csv")
P = pd.read_csv(ROOT / "experiments/707-cascaded-isolated-clutter-at-r/predictions_phase2.csv")[["link_id", "var_lb_50"]]
L = L.merge(P, on="link_id", validate="1:1")
const704 = json.load(open(ROOT / "experiments/704-cascaded-isolated-constant/metrics.json"))["cfg"]["terminal_clutter_db"]

L["base"] = L.path_id.str.rsplit("_", n=1).str[0]
key = ["base", "f_mhz", "htx_m", "hrx_m"]
C = L[L.siting == "C"].set_index(key)
O = L[L.siting == "O"].set_index(key)
both = C.join(O, lsuffix="_c", rsuffix="_o", how="inner").reset_index()
if both.duplicated(key).any():
    raise SystemExit("pairs aren't one-to-one")
# Mobile terminal height: transmitter in R1, R2, R3; receiver in VA (core comment, B07)
both["h_mobile"] = np.where(both.set_c == "VA", both.hrx_m, both.htx_m)
both["d707"] = both.var_lb_50_c - both.var_lb_50_o
both["dm"] = both.meas_lb_db_c - both.meas_lb_db_o
both["band"] = pd.cut(both.f_mhz, [0, 300, 1000, 3000, 20000], labels=["<300 MHz", "300 MHz-1 GHz", "1-3 GHz", ">3 GHz"])
unc = both[(both.censored_c == 0) & (both.censored_o == 0)].copy()
cen = both[(both.censored_c != 0) | (both.censored_o != 0)]


def rms(x):
    return float(np.sqrt(np.mean(np.square(x))))


lines = ["D20c: paired open/concealed clutter (B20)", "",
         f"Matched pairs: {len(both)}; both uncensored: {len(unc)}; with a censored row: {len(cen)}.",
         f"704 constant: {const704} dB.", ""]

# Check: 707's difference should be its clutter term only (non-negative, zero only where the term is zero)
lines.append(f"707 predicted difference: min {unc.d707.min():.2f}, mean {unc.d707.mean():.2f}, max {unc.d707.max():.2f} dB.")
lines.append(f"Measured difference: mean {unc.dm.mean():.2f}, SD {unc.dm.std():.2f} dB.")
lines.append("")

# Overall and by stratum
def table(g, name):
    rows = []
    for lev, x in g:
        if len(x) < 10:
            continue
        rows.append({name: lev, "n": len(x), "mean_dm": x.dm.mean(), "mean_d707": x.d707.mean(),
                     "rms_p2108": rms(x.dm - x.d707), "rms_const704": rms(x.dm - const704),
                     "rms_zero": rms(x.dm)})
    return pd.DataFrame(rows).round(2)


T_all = table([("all", unc)], "stratum")
T_set = table(unc.groupby("set_c"), "set")
T_band = table(unc.groupby("band", observed=True), "band")
T_h = table(unc.groupby("h_mobile"), "h_mobile_m")
for name, T in (("Overall", T_all), ("By set", T_set), ("By band", T_band), ("By mobile antenna height", T_h)):
    lines += [f"## {name}", "", T.to_string(index=False), ""]

# Frequency slope of measured and predicted difference (dB per decade)
def slope(x, y):
    return float(np.polyfit(x, y, 1)[0])


lf = np.log10(unc.f_mhz)
s_m, s_p = slope(lf, unc.dm), slope(lf, unc.d707)
rng = np.random.default_rng(20261124)
bases = unc.base.unique()
idx = {b: np.flatnonzero(unc.base.to_numpy() == b) for b in bases}
bs = []
for _ in range(2000):
    s = np.concatenate([idx[b] for b in rng.choice(bases, len(bases))])
    bs.append(slope(lf.to_numpy()[s], unc.dm.to_numpy()[s]))
lo, hi = np.percentile(bs, [2.5, 97.5])
lines += ["## Frequency dependence", "",
          f"Measured difference vs log10(f): {s_m:+.2f} dB per decade (path bootstrap 95 %: {lo:+.2f} to {hi:+.2f}).",
          f"P.2108-1 (707) difference vs log10(f): {s_p:+.2f} dB per decade.", ""]
slope_sign_ok = (np.sign(s_m) == np.sign(s_p)) and (lo > 0 if s_p > 0 else hi < 0)

# Leave one site out: P.2108 (no fit) vs constant refitted on training sites vs 704's constant
lines += ["## Leave one site out", "", "| Held-out site | n | RMS P.2108-1 | RMS constant refit on others (value) | RMS 704 constant | P.2108-1 wins |", "| --- | --- | --- | --- | --- | --- |"]
wins = 0
sites = sorted(unc.set_c.unique())
for s in sites:
    test, train = unc[unc.set_c == s], unc[unc.set_c != s]
    c_fit = train.dm.mean()
    r_p, r_c, r_704 = rms(test.dm - test.d707), rms(test.dm - c_fit), rms(test.dm - const704)
    win = r_p < r_c
    wins += win
    lines.append(f"| {s} | {len(test)} | {r_p:.2f} | {r_c:.2f} ({c_fit:.2f}) | {r_704:.2f} | {'yes' if win else 'no'} |")
lines.append("")

supported = wins >= 2 and slope_sign_ok
lines += ["## Decision rule (B20.md, fixed before the run)", "",
          f"P.2108-1 beats the refitted constant on {wins} of {len(sites)} held-out sites (rule: at least 2 of 3).",
          f"Measured frequency slope has P.2108-1's sign with the interval excluding zero: {'yes' if slope_sign_ok else 'no'}.",
          f"**Outcome: {'P.2108-1 supported' if supported else 'recorded as an empirical offset'}.**"]
if len(sites) != 3:
    lines.append(f"Note: {len(sites)} sites have matched pairs, not 3; the rule's 2-of-3 is applied as written.")

(OUT / "summary.txt").write_text("\n".join(lines) + "\n")
unc.to_csv(OUT / "pairs_uncensored_rev1.csv", index=False)
print("\n".join(lines))
