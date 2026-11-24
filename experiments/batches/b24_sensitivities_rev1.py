"""B24: registered B23 sensitivities. Reads B23 pair CSVs only. Run: python3 -I experiments/batches/b24_sensitivities_rev1.py"""
import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
import b23_common_rev1 as C  # noqa: E402

OUT = C.ROOT / "experiments/D24-sensitivities"
OUT.mkdir(parents=True, exist_ok=True)
A = pd.read_csv(C.ROOT / "experiments/D23a-height-contrasts/pairs_rev1.csv")
F = pd.read_csv(C.ROOT / "experiments/D23c-frequency-contrasts/pairs_rev1.csv")


def die(m):
    raise SystemExit("B24 STOP: " + m)


def base_means(df, col):
    d = df[np.isfinite(df[col])]
    return d.groupby("physical_base_id")[col].mean()


def cell(df, col):
    bm = base_means(df, col)
    m, lo, hi, n, _ = C.boot_interval(bm.values)
    return m, lo, hi, n, C.disposition(m, lo, hi, n)


def prim_a(df):
    return df[(df.kind == "HGT_RX") & (df.siting == "O") & (df.pair_class == "blocked-blocked") & df.detected_pair]


def prim_c(df):
    return df[(df.kind == "FRQ_HIGH") & (df.siting == "O") & (df.pair_class == "clear-clear") & df.detected_pair]


# 1. reproduction
want = {("A", "R1"): 5.64, ("A", "R2"): 3.14, ("A", "R3"): 1.65, ("C", "R1"): 3.94, ("C", "VA"): 4.61, ("C", "R3"): 1.37, ("C", "R2"): 9.10}
for (k, s), w in want.items():
    d = prim_a(A) if k == "A" else prim_c(F)
    d = d[d.set == s]
    got = base_means(d, "e_707" if k == "A" else "T_707").mean()
    if abs(got - w) > 0.01:
        die(f"reproduction {k} {s}: {got:.3f} vs {w}")

rows = []


def add(study, site, variant, d, col):
    m, lo, hi, n, disp = cell(d, col)
    rows.append(dict(study=study, site=site, variant=variant, mean=m, lo=lo, hi=hi, n_bases=n, disposition=disp))


for study, prim, col in (("D23a", prim_a(A), "e_707"), ("D23c", prim_c(F), "T_707")):
    for s, g in prim.groupby("set"):
        add(study, s, "primary", g, col)
        add(study, s, "F1>=0.6 low end", g[g.low_min_clear_f1 >= 0.6], col)
        add(study, s, "F1>=0.6 both ends", g[(g.low_min_clear_f1 >= 0.6) & (g.high_min_clear_f1 >= 0.6)], col)
        # leave-one-fixed-terminal-out
        terms = sorted(g.fixed_terminal_id.unique())
        loo = []
        for t in terms:
            gg = g[g.fixed_terminal_id != t]
            if len(gg):
                loo.append(base_means(gg, col).mean())
        rows.append(dict(study=study, site=s, variant=f"leave-one-fixed-terminal-out ({len(terms)} terminals)",
                         mean=np.mean(loo) if loo else math.nan, lo=min(loo) if loo else math.nan,
                         hi=max(loo) if loo else math.nan, n_bases=len(terms), disposition="range of means"))
        # bootstrap over fixed terminals
        tm = g.groupby("fixed_terminal_id").apply(lambda x: base_means(x, col).mean())
        m, lo, hi, n, _ = C.boot_interval(tm.values)
        rows.append(dict(study=study, site=s, variant="bootstrap over fixed terminals", mean=m, lo=lo, hi=hi, n_bases=n,
                         disposition=C.disposition(m, lo, hi, n)))
    # leave-one-site-out of the cross-site mean of site means
    sm = prim.groupby("set").apply(lambda x: base_means(x, col).mean())
    for s in sm.index:
        rows.append(dict(study=study, site="ALL", variant=f"cross-site mean without {s}", mean=sm.drop(s).mean(),
                         lo=math.nan, hi=math.nan, n_bases=len(sm) - 1, disposition="mean of site means"))

# D23c per decade
pc = prim_c(F).copy()
pc["T_per_decade"] = pc["T_707"] / pc["decades"]
for s, g in pc.groupby("set"):
    add("D23c", s, "T per decade", g, "T_per_decade")

# calibration margin (D23a, D23c primary)
S = pd.DataFrame(rows)
cal = []
for _, r in S[S.variant == "primary"].iterrows():
    cal.append(dict(study=r.study, site=r.site, mean_minus_2dB=r["mean"] - 2.0, lo_minus_2dB=r.lo - 2.0,
                    lower_bound_survives_2dB=bool(r.lo - 2.0 > 0)))
cal = pd.DataFrame(cal)

# censored-bound sign check, D23a: all blocked-blocked O pairs including censored
pa = A[(A.kind == "HGT_RX") & (A.siting == "O") & (A.pair_class == "blocked-blocked")].copy()
pa["e_lo"] = pa.dL_707 - pa.meas_iv_hi
pa["e_hi"] = pa.dL_707 - pa.meas_iv_lo
pa["sign_determined_pos"] = pa.e_lo > 0
pa["sign_determined_neg"] = pa.e_hi < 0
cen = pa.groupby("set").agg(pairs=("pair_id", "size"), detected=("detected_pair", "sum"),
                            determined_pos=("sign_determined_pos", "sum"), determined_neg=("sign_determined_neg", "sum"))

S.to_csv(OUT / "sensitivities_rev1.csv", index=False)
cal.to_csv(OUT / "calibration_margin_rev1.csv", index=False)
cen.to_csv(OUT / "censored_signs_rev1.csv")
with open(OUT / "summary.txt", "w") as f:
    f.write("B24 sensitivities (development data only)\n\n")
    f.write(S.round(2).to_string(index=False) + "\n\nCalibration margin (2 dB)\n" + cal.round(2).to_string(index=False))
    f.write("\n\nCensored-bound signs, D23a blocked-blocked open pairs\n" + cen.to_string() + "\n")
print(open(OUT / "summary.txt").read())
