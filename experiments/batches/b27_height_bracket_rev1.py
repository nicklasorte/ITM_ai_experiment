#!/usr/bin/env python3
"""B27 D27a: do 707 and stock ITM bracket the measured height contrast? (diagnostic)

Reads B23's frozen pair table (experiments/D23a-height-contrasts/pairs_rev1.csv).
It runs no model and reads no lockbox data. Development data only; not a scored run.

For matched height pairs (same base, frequency and other-end height), the
contrast is L_high - L_low and e = predicted contrast - measured contrast.
B23 reported 707's signed e and only |e_stock| - |e_707| for stock ITM. This
script reports, per stratum and site:

  signed e_707 and e_stock   equal-base mean, 95 % base bootstrap (b23_common)
  bracket share              share of bases whose mean measured contrast lies
                             between the two models' mean contrasts
  blend ceiling              the largest cut in the equal-base mean |e| that any
                             single weight w in [0, 1] on
                             dL_707 + w (dL_stock - dL_707) achieves, in sample
                             (optimistic), and with w taken from the other sites

The blend is a diagnostic ceiling for "a height response between 707's and
stock's". It is not a model and w is never used as a constant. It is optimistic
twice over: w is chosen in sample, and blending averages the two models'
independent errors, which cuts |e| even with no shared physics.

Usage (from the repository root):
  python3 -I experiments/batches/b27_height_bracket_rev1.py --selftest
  python3 -I experiments/batches/b27_height_bracket_rev1.py --dry
  python3 -I experiments/batches/b27_height_bracket_rev1.py --run
"""
import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
import b23_common_rev1 as C  # noqa: E402

PAIRS = C.ROOT / "experiments/D23a-height-contrasts/pairs_rev1.csv"
OUT = C.ROOT / "experiments/D27-height-bracket"
NEED = ["kind", "set", "tier", "siting", "pair_class", "physical_base_id", "detected_pair",
        "meas_dL", "dL_707", "e_707", "dL_stock", "e_stock"]
STRATA = [("O blocked-blocked (primary)", "blocked-blocked"), ("O clear-clear", "clear-clear")]
W_GRID = np.round(np.arange(0.0, 1.0001, 0.01), 2)   # search grid for the ceiling, not a model constant
MIN_CUT_DB = 1.0    # B23 section 3.4 resolution (1 dB), reused as the ceiling rule
MIN_BASES = 10      # B23 section 3.4 minimum independent bases
B23_CELL = (5.64, 29)   # B23 D23a: R1 open blocked-blocked signed 707 error and bases


def die(msg):
    raise SystemExit("B27 STOP: " + msg)


def select(df, pair_class):
    d = df[(df.kind == "HGT_RX") & (df.siting == "O") & (df.pair_class == pair_class) & df.detected_pair]
    for c in ("meas_dL", "dL_707", "e_707", "dL_stock", "e_stock"):
        if not np.isfinite(d[c]).all():
            die(f"non-finite {c} in detected {pair_class} pairs")
    return d


def base_abs(d, w):
    """Per-base mean of |e_707 + w (e_stock - e_707)|."""
    e = d.e_707 + w * (d.e_stock - d.e_707)
    return e.abs().groupby(d.physical_base_id).mean()


def best_w(d):
    m = [base_abs(d, w).mean() for w in W_GRID]
    return float(W_GRID[int(np.argmin(m))])


def cell(d, others):
    """Statistics for one stratum x site. d: this site's pairs; others: other sites' pairs."""
    r = {"n_pairs": int(len(d)), "n_bases": int(d.physical_base_id.nunique())}
    for name in ("e_707", "e_stock"):
        m, lo, hi, n, _ = C.boot_interval(C.base_means(d, name).values)
        r[name] = m; r[name + "_lo"] = lo; r[name + "_hi"] = hi
        r[name + "_disp"] = C.disposition(m, lo, hi, n)
    g = d.groupby("physical_base_id")[["meas_dL", "dL_707", "dL_stock"]].mean()
    lo_m = g[["dL_707", "dL_stock"]].min(axis=1); hi_m = g[["dL_707", "dL_stock"]].max(axis=1)
    r["bracket_share"] = float(((g.meas_dL >= lo_m) & (g.meas_dL <= hi_m)).mean())
    w_in = best_w(d)
    cut = base_abs(d, 0.0) - base_abs(d, w_in)
    m, lo, hi, n, _ = C.boot_interval(cut.values)
    r["w_in_sample"] = w_in; r["cut_in_sample"] = m; r["cut_lo"] = lo; r["cut_hi"] = hi
    if len(others):
        w_out = best_w(others)
        r["w_other_sites"] = w_out
        r["cut_other_sites"] = float((base_abs(d, 0.0) - base_abs(d, w_out)).mean())
    else:
        r["w_other_sites"] = math.nan; r["cut_other_sites"] = math.nan
    return r


def decide(r):
    """Registered rule (B27.md section 4), applied to the strict primary cell."""
    if r["n_bases"] < MIN_BASES:
        return "C", "fewer than 10 bases: hand back to the planner"
    bracketed = (r["e_707_lo"] > 0 and r["e_stock_hi"] < 0) or (r["e_707_hi"] < 0 and r["e_stock_lo"] > 0)
    if not bracketed:
        return "C", "the two models' signed errors don't have opposite signs with intervals that exclude zero: hand back"
    if r["cut_in_sample"] >= MIN_CUT_DB:
        return "A", "bracketed, and the in-sample ceiling is at least 1 dB: go to stage B (planner)"
    return "B", "bracketed, but even the in-sample ceiling is under 1 dB: close the mechanism"


def analyse(df):
    rows = []
    for label, pc in STRATA:
        s = select(df, pc)
        for site in sorted(s.set.unique()):
            d = s[s.set == site]
            r = cell(d, s[s.set != site])
            r.update(stratum=label, site=site, tier=";".join(sorted(d.tier.unique())),
                     population=f"{site} open {pc} detected height pairs, {r['n_pairs']} pairs, {r['n_bases']} bases")
            rows.append(r)
    return pd.DataFrame(rows)


def render(T, outcome, why, decided_on):
    lines = ["B27 D27a: height-contrast bracket (development data only; not a scored run)", "",
             "e = predicted minus measured contrast (dB); positive: too little loss reduction with height.",
             "The blend weight is a diagnostic ceiling, in sample and optimistic; it is not a model constant.",
             "By construction: at w = 0 the blend is 707, so the cut is never negative in sample.", ""]
    for _, r in T.iterrows():
        lines.append(f"{r.stratum} | {r.population} | tier {r.tier}")
        lines.append(f"  e_707 {r.e_707:+.2f} [{r.e_707_lo:+.2f}, {r.e_707_hi:+.2f}] {r.e_707_disp}; "
                     f"e_stock {r.e_stock:+.2f} [{r.e_stock_lo:+.2f}, {r.e_stock_hi:+.2f}] {r.e_stock_disp}")
        lines.append(f"  bracket share {r.bracket_share:.2f}; ceiling cut {r.cut_in_sample:.2f} dB at w = {r.w_in_sample:.2f} "
                     f"[{r.cut_lo:.2f}, {r.cut_hi:.2f}]; with w from other sites ({r.w_other_sites:.2f}): {r.cut_other_sites:.2f} dB")
    lines += ["", f"OUTCOME {outcome}: {why}", f"Decided on: {decided_on}"]
    return lines


def load():
    df = pd.read_csv(PAIRS)
    miss = [c for c in NEED if c not in df.columns]
    if miss:
        die("pair table lacks columns " + ", ".join(miss))
    if df.detected_pair.dtype != bool:
        die("detected_pair is not boolean")
    d = select(df, "blocked-blocked"); d = d[d.set == "R1"]
    got = C.base_means(d, "e_707").mean(); nb = d.physical_base_id.nunique()
    if abs(got - B23_CELL[0]) > 0.01 or nb != B23_CELL[1]:
        die(f"B23 cell not reproduced: {got:.3f} dB on {nb} bases, expected {B23_CELL[0]} on {B23_CELL[1]}")
    if not np.allclose(d.e_stock - d.e_707, d.dL_stock - d.dL_707, atol=1e-9):
        die("e_stock - e_707 differs from dL_stock - dL_707")
    return df


def synth(n_bases, pairs_per, e707, estock, noise, seed, site="R1", tier="strict", shared=0.0):
    rng = np.random.default_rng(seed)
    rec = []
    for b in range(n_bases):
        for _ in range(pairs_per):
            meas = -8.0 + rng.normal(0, 2)
            m = rng.normal(0, shared)   # measurement noise, common to both models' errors
            a = e707 + m + rng.normal(0, noise); s = estock + m + rng.normal(0, noise)
            rec.append(dict(kind="HGT_RX", set=site, tier=tier, siting="O", pair_class="blocked-blocked",
                            physical_base_id=f"{site}-{b}", detected_pair=True, meas_dL=meas,
                            dL_707=meas + a, e_707=a, dL_stock=meas + s, e_stock=s))
    return pd.DataFrame(rec)


def selftest():
    # A: 707 under-predicts the height gain (+5), stock over-predicts (-10): bracketed, w* near 1/3
    a = analyse(pd.concat([synth(30, 5, 5, -10, 1.0, 1), synth(30, 5, 5, -10, 1.0, 2, "R2", "limited")]))
    ra = a[(a.site == "R1") & (a.stratum == STRATA[0][0])].iloc[0]
    assert decide(ra)[0] == "A", decide(ra)
    assert abs(ra.w_in_sample - 1 / 3) < 0.08 and ra.cut_in_sample > 3, (ra.w_in_sample, ra.cut_in_sample)
    assert ra.bracket_share > 0.9 and abs(ra.w_other_sites - 1 / 3) < 0.08
    # B: opposite signs, but shared measurement noise far above the bias: ceiling under 1 dB
    b = analyse(synth(200, 5, 1.2, -1.2, 0.2, 3, shared=12.0))
    rb = b.iloc[0]
    assert decide(rb)[0] == "B", (decide(rb), rb.cut_in_sample, rb.e_707_lo, rb.e_stock_hi)
    # C: both models under-predict the height gain: not bracketed
    c = analyse(synth(30, 5, 5, 9, 1.0, 4))
    assert decide(c.iloc[0])[0] == "C"
    assert c.iloc[0].w_in_sample == 0.0 and abs(c.iloc[0].cut_in_sample) < 1e-12   # by construction at w = 0
    # C: too few bases
    assert decide(analyse(synth(6, 5, 5, -10, 1.0, 5)).iloc[0])[0] == "C"
    # the summary text renders, including a one-base site with no interval
    mix = analyse(pd.concat([synth(30, 5, 5, -10, 1.0, 6), synth(1, 4, 5, -10, 1.0, 7, "VA", "limited")]))
    txt = "\n".join(render(mix, "A", "x", "p"))
    assert "OUTCOME A" in txt and "VA open" in txt
    print("selftest: 4 scenarios pass")


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--selftest", action="store_true")
    g.add_argument("--dry", action="store_true", help="check the pair table and the B23 cell; compute nothing new")
    g.add_argument("--run", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    df = load()
    if a.dry:
        print("dry: columns present, B23 cell reproduced (+5.64 dB, 29 bases), identity e_stock - e_707 holds")
        return
    if OUT.exists():
        die(f"{OUT} exists: D27a has already run. Don't rerun; hand back.")
    T = analyse(df)
    prim = T[(T.stratum == STRATA[0][0]) & (T.site == "R1")]
    if len(prim) != 1:
        die("strict primary cell not found")
    outcome, why = decide(prim.iloc[0])
    OUT.mkdir(parents=True)
    cols = ["stratum", "site", "tier", "population", "e_707", "e_707_lo", "e_707_hi", "e_707_disp", "e_stock",
            "e_stock_lo", "e_stock_hi", "e_stock_disp", "bracket_share", "w_in_sample", "cut_in_sample", "cut_lo",
            "cut_hi", "w_other_sites", "cut_other_sites"]
    T[cols].to_csv(OUT / "bracket_rev1.csv", index=False)
    (OUT / "decision_rev1.json").write_text(json.dumps(
        {"outcome": outcome, "reason": why, "decided_on": prim.iloc[0].population,
         "pairs_sha256": C.sha256_file(PAIRS)}, indent=1) + "\n")
    lines = render(T, outcome, why, prim.iloc[0].population)
    (OUT / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
