#!/usr/bin/env python3
"""B33 (D33) registered analysis: X01 season pairing, X06 quantile widths, X03 transmitter sensitivity.

Usage:
    python3 -I d33_analysis_rev1.py <repo root> <out_dir>
    python3 -I d33_analysis_rev1.py --selftest

Rule: experiments/batches/B33.md section 3. Cells flagged missing, lower
bound, questionable or uncertain are excluded. Graham R5 is excluded.
Bootstrap: 2,000 draws over paths, one generator seeded 20261126, strata in
the order X01 (area, band, height), X01 J, X06, X03. "Resolved": |mean| >= 1 dB
and the 95 % percentile interval excludes zero. Strata under 10 paths are
descriptive.
"""
import csv
import json
import os
import sys

import numpy as np

SEED = 20261126
N_BOOT = 2000
RES_DB = 1.0
MIN_PATHS = 10
PAIRS = {"Graham": ("8", "9"), "Hunter Liggett": ("10", "11")}   # (earlier, later)
BANDS = ["VHF", "UHF"]
HEIGHTS = [10.0, 3.0, 0.35]


def truthy(v):
    s = str(v).strip().lower()
    if s in ("true", "1"):
        return True
    if s in ("false", "0", ""):
        return False
    raise SystemExit(f"Unreadable flag {v!r}")


def bad(r):
    return any(truthy(r[k]) for k in ("missing", "lower_bound", "questionable", "uncertain"))


def boot(x, rng):
    x = np.asarray(x, float)
    if len(x) == 0:
        return np.nan, np.nan, np.nan
    m = np.mean(x[rng.integers(0, len(x), size=(N_BOOT, len(x)))], axis=1)
    lo, hi = np.percentile(m, [2.5, 97.5])
    return float(np.mean(x)), float(lo), float(hi)


def resolved(mean, lo, hi, n):
    return bool(n >= MIN_PATHS and abs(mean) >= RES_DB and (lo > 0 or hi < 0))


def load_tables(path):
    """{(table, tx, rx, band, h, pct): row} for usable and flagged cells alike."""
    out = {}
    for r in csv.DictReader(open(path, newline="")):
        if r["table"] == "8" and r["rx"] == "5":
            continue
        out[(r["table"], r["tx"], r["rx"], r["band"], float(r["rx_ant_m"]), int(r["pct"]))] = r
    return out


def val(cells, key):
    r = cells.get(key)
    if r is None:
        raise SystemExit(f"Missing table row {key}")
    if bad(r) or r["loss_db"] in ("", "NaN", "nan"):
        return None
    return float(r["loss_db"])


def x01_x06(cells, rng):
    x01, j, x06 = [], [], []
    paths = sorted({(k[1], k[2]) for k in cells if k[0] == "9"}, key=lambda p: (int(p[0]), int(p[1])))
    for area, (te, tl) in PAIRS.items():
        ps = sorted({(k[1], k[2]) for k in cells if k[0] == te}, key=lambda p: (int(p[0]), int(p[1])))
        for b in BANDS:
            S = {}
            for h in HEIGHTS:
                v = []
                for (tx, rx) in ps:
                    a, c = val(cells, (te, tx, rx, b, h, 50)), val(cells, (tl, tx, rx, b, h, 50))
                    if a is not None and c is not None:
                        v.append(c - a)
                        S[(tx, rx, h)] = c - a
                m, lo, hi = boot(v, rng)
                x01.append({"area": area, "band": b, "rx_ant_m": h, "n_paths": len(v), "mean_S": m, "S_lo95": lo,
                            "S_hi95": hi, "resolved": resolved(m, lo, hi, len(v)) if h != 0.35 else "measured only"})
            v = [S[(tx, rx, 3.0)] - S[(tx, rx, 10.0)] for (tx, rx) in ps if (tx, rx, 3.0) in S and (tx, rx, 10.0) in S]
            m, lo, hi = boot(v, rng)
            j.append({"area": area, "band": b, "n_paths": len(v), "mean_J": m, "J_lo95": lo, "J_hi95": hi,
                      "resolved": resolved(m, lo, hi, len(v))})
            for h in HEIGHTS:
                W = {"early": [], "late": []}
                dW, dK, absS, Wm = [], [], [], []
                for (tx, rx) in ps:
                    q = {}
                    for t, lab in ((te, "early"), (tl, "late")):
                        vals = [val(cells, (t, tx, rx, b, h, p)) for p in (10, 50, 90)]
                        q[lab] = None if any(x is None for x in vals) else vals
                    if q["early"] is None or q["late"] is None:
                        continue
                    w = {k: q[k][2] - q[k][0] for k in q}
                    kk = {k: q[k][2] + q[k][0] - 2 * q[k][1] for k in q}
                    W["early"].append(w["early"]); W["late"].append(w["late"])
                    dW.append(w["late"] - w["early"]); dK.append(kk["late"] - kk["early"])
                    absS.append(abs(q["late"][1] - q["early"][1])); Wm.append((w["early"] + w["late"]) / 2)
                mW, loW, hiW = boot(dW, rng)
                mK, loK, hiK = boot(dK, rng)
                x06.append({"area": area, "band": b, "rx_ant_m": h, "n_paths": len(dW),
                            "mean_W_early": float(np.mean(W["early"])) if dW else np.nan,
                            "mean_W_late": float(np.mean(W["late"])) if dW else np.nan,
                            "mean_dW": mW, "dW_lo95": loW, "dW_hi95": hiW,
                            "mean_dK": mK, "dK_lo95": loK, "dK_hi95": hiK,
                            "ratio_meanabsS_to_meanW": float(np.mean(absS) / np.mean(Wm)) if dW else np.nan})
    return x01, j, x06


def x03(root, rng_unused):
    tx = list(csv.DictReader(open(os.path.join(root, "experiments", "D32-ot7574-heights", "tx_sensitivity_rev1.csv"))))
    cell = {}
    for r in tx:
        if r["table"] == "8" and r["rx"] == "5":
            continue
        cell[(r["table"], r["tx"], r["rx"], r["band"], float(r["rx_ant_m"]))] = r
    rows = []
    for (t, a, b_, band, h), r3 in cell.items():
        if h != 3.0:
            continue
        r10 = cell[(t, a, b_, band, 10.0)]
        if bad(r3) or bad(r10):
            continue                                   # B32 deciding support only
        rec = {"table": t, "band": band}
        for m, p in (("707", "L707"), ("stock", "Lst")):
            c = {s: float(r3[f"{p}_t{s}"]) - float(r10[f"{p}_t{s}"]) for s in ("050", "070", "100")}
            rec[f"dC070_{m}"] = c["070"] - c["050"]
            rec[f"dC100_{m}"] = c["100"] - c["050"]
        rows.append(rec)
    def summ(sel):
        out = {"n_paths": len(sel)}
        for m in ("707", "stock"):
            ok = [abs(r[f"dC070_{m}"]) < 1 and abs(r[f"dC100_{m}"]) < 1 for r in sel]
            out[f"share_under_1dB_{m}"] = float(np.mean(ok)) if sel else np.nan
            out[f"median_abs_dC100_{m}"] = float(np.median([abs(r[f"dC100_{m}"]) for r in sel])) if sel else np.nan
            out[f"max_abs_dC100_{m}"] = float(np.max([abs(r[f"dC100_{m}"]) for r in sel])) if sel else np.nan
        out["median_dC100_707_minus_stock"] = float(np.median([r["dC100_707"] - r["dC100_stock"] for r in sel])) if sel else np.nan
        return out
    overall = summ(rows)
    by = []
    for t in ("7", "8", "9", "10", "11"):
        for band in BANDS:
            s = summ([r for r in rows if r["table"] == t and r["band"] == band])
            by.append({"table": t, "band": band, **s})
    overall["stop_rule_holds"] = bool(overall["share_under_1dB_707"] >= 0.9 and overall["share_under_1dB_stock"] >= 0.9)
    return overall, by


def check_season_inputs(root):
    """B33 check 1: both models predict identical loss in the two seasons."""
    p = list(csv.DictReader(open(os.path.join(root, "experiments", "D32-ot7574-heights", "predictions_rev1.csv"))))
    d = {(r["table"], r["tx"], r["rx"], r["band"], r["rx_ant_m"]): r for r in p}
    worst = 0.0
    n = 0
    for te, tl in PAIRS.values():
        for k, r in d.items():
            if k[0] != te or (te == "8" and k[2] == "5"):
                continue
            r2 = d[(tl,) + k[1:]]
            for c in ("L_707_db", "L_stock_db"):
                worst = max(worst, abs(float(r[c]) - float(r2[c])))
            n += 1
    if worst > 1e-9:
        raise SystemExit(f"Check 1 failed: seasons differ in model inputs (largest model difference {worst:.3g} dB)")
    return n, worst


def write_csv(path, recs):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(recs[0].keys()))
        w.writeheader()
        for r in recs:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in r.items()})


def selftest():
    rng = np.random.default_rng(7)
    for shift, want in ((3.0, True), (0.0, False)):
        cells = {}
        for area, (te, tl) in PAIRS.items():
            for tx in range(1, 11):
                for rx in range(1, 5):
                    for b in BANDS:
                        for h in HEIGHTS:
                            base = 120 + rng.normal(0, 4)
                            for t, s in ((te, 0.0), (tl, shift)):
                                for p, off in ((10, -4), (50, 0), (90, 5)):
                                    cells[(t, str(tx), str(rx), b, h, p)] = {
                                        "loss_db": str(base + s + off + rng.normal(0, 0.5)), "missing": "False",
                                        "lower_bound": "False", "questionable": "False", "uncertain": "False"}
        x01, j, x06 = x01_x06(cells, np.random.default_rng(SEED))
        got = any(r["resolved"] is True for r in x01)
        jres = any(r["resolved"] for r in j)
        print(f"self-test shift {shift}: any S resolved = {got}, any J resolved = {jres}, "
              f"ratio |S|/W {min(r['ratio_meanabsS_to_meanW'] for r in x06):.2f} to {max(r['ratio_meanabsS_to_meanW'] for r in x06):.2f}")
        if got != want or jres:
            raise SystemExit("Self-test failed")
    print("SELF-TEST PASS")


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--selftest":
        selftest()
        return
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    root, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    n, worst = check_season_inputs(root)
    print(f"Check 1: {n} season-paired model rows, largest model difference {worst:.2g} dB")
    cells = load_tables(os.path.join(root, "experiments", "D31-ot7574", "ot7574_tables_rev1.csv"))
    rng = np.random.default_rng(SEED)
    x01, j, x06 = x01_x06(cells, rng)
    ov, by = x03(root, rng)
    write_csv(os.path.join(out, "x01_season_shift_rev1.csv"), x01)
    write_csv(os.path.join(out, "x01_interaction_rev1.csv"), j)
    write_csv(os.path.join(out, "x06_quantile_width_rev1.csv"), x06)
    write_csv(os.path.join(out, "x03_tx_sensitivity_rev1.csv"), by)
    summary = {"x01_any_S_resolved": any(r["resolved"] is True for r in x01),
               "x01_any_J_resolved": any(r["resolved"] for r in j),
               "x06_ratio_below_0.5_everywhere": all(r["ratio_meanabsS_to_meanW"] < 0.5 for r in x06 if r["n_paths"]),
               "x03_overall": ov, "seed": SEED, "n_boot": N_BOOT}
    json.dump(summary, open(os.path.join(out, "summary_rev1.json"), "w"), indent=2)
    for name, recs in (("X01 S", x01), ("X01 J", j), ("X06", x06), ("X03", by)):
        print(f"--- {name}")
        for r in recs:
            print("  " + ", ".join(f"{k}={v:.2f}" if isinstance(v, float) else f"{k}={v}" for k, v in r.items()))
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
