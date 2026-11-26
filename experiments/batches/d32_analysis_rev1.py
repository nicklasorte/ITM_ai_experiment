#!/usr/bin/env python3
"""B32 (D32) registered analysis: 707 vs stock ITM on OT 75-74 height contrasts.

Usage:
    python3 -I d32_analysis_rev1.py <predictions_rev1.csv> <out_dir>
    python3 -I d32_analysis_rev1.py --selftest

Rule: experiments/batches/B32.md sections 3 and 3a. For each path, band and
table, C_hi = L(3 m) - L(10 m) and C_lo = L(0.35 m) - L(3 m) at 50 %;
e = C_model - C_measured. Cells flagged missing, lower bound, questionable
or uncertain are excluded, and a contrast exists only when both of its cells
pass. Graham R5 (table 8, receiver 5) is excluded. Per stratum (table x band
x contrast): mean |e| for each model, D = mean|e_707| - mean|e_stock|, 95 %
percentile interval from 2,000 bootstrap draws over paths. One generator,
seed 1, is used for all strata in the order table, band (VHF, UHF),
contrast (hi, lo). Section 3a: only the 10 C_hi strata decide; A needs
D < 0 excluding zero in >= 6 of 10 and D > 0 excluding zero in none; B is
the mirror; C otherwise. C_lo is descriptive.

Fails loud (SystemExit with a message) if the stratum counts differ from
the registered counts.
"""
import csv
import json
import os
import sys

import numpy as np

TABLES = [7, 8, 9, 10, 11]
BANDS = ["VHF", "UHF"]
CONTRASTS = ["hi", "lo"]
HEIGHTS = {"hi": (3.0, 10.0), "lo": (0.35, 3.0)}   # (lower antenna, upper antenna)
REGISTERED_COUNTS = {   # B32.md section 3 table (reviewer's count, R5 removed)
    (7, "VHF", "hi"): 39, (7, "VHF", "lo"): 35, (7, "UHF", "hi"): 37, (7, "UHF", "lo"): 37,
    (8, "VHF", "hi"): 35, (8, "VHF", "lo"): 29, (8, "UHF", "hi"): 18, (8, "UHF", "lo"): 16,
    (9, "VHF", "hi"): 33, (9, "VHF", "lo"): 37, (9, "UHF", "hi"): 39, (9, "UHF", "lo"): 39,
    (10, "VHF", "hi"): 31, (10, "VHF", "lo"): 33, (10, "UHF", "hi"): 31, (10, "UHF", "lo"): 18,
    (11, "VHF", "hi"): 34, (11, "VHF", "lo"): 30, (11, "UHF", "hi"): 28, (11, "UHF", "lo"): 22,
}
N_BOOT = 2000
SEED = 1
MIN_PATHS = 10
DECIDE_K = 6       # of the 10 C_hi strata (section 3a)
IDENT_DB = 0.01


def truthy(v):
    s = str(v).strip().lower()
    if s in ("true", "1"):
        return True
    if s in ("false", "0", ""):
        return False
    raise SystemExit(f"Unreadable flag value {v!r}")


def load(path):
    rows = []
    with open(path, newline="") as f:
        for r in csv.DictReader(f):
            rows.append({
                "table": int(r["table"]), "tx": int(r["tx"]), "rx": int(r["rx"]), "band": r["band"],
                "h": float(r["rx_ant_m"]), "meas": float(r["loss_db"]) if r["loss_db"] not in ("", "NaN") else np.nan,
                "bad": any(truthy(r[k]) for k in ("missing", "lower_bound", "questionable", "uncertain")),
                "L707": float(r["L_707_db"]), "Lst": float(r["L_stock_db"]),
            })
    return rows


def contrasts(rows):
    """Return {stratum: list of dicts(path, cm, c7, cs, ident)} and per-height cells."""
    cell = {}
    for r in rows:
        if r["table"] == 8 and r["rx"] == 5:
            continue                                          # Graham R5: reported, doesn't count
        cell[(r["table"], r["tx"], r["rx"], r["band"], r["h"])] = r
    out = {k: [] for k in REGISTERED_COUNTS}
    paths = sorted({k[:4] for k in cell})
    for (t, tx, rx, b) in paths:
        for c in CONTRASTS:
            lo, hi = HEIGHTS[c]
            a = cell.get((t, tx, rx, b, lo))
            u = cell.get((t, tx, rx, b, hi))
            if a is None or u is None:
                raise SystemExit(f"Table {t} T{tx} R{rx} {b} lacks a {lo} or {hi} m row.")
            if a["bad"] or u["bad"] or not np.isfinite(a["meas"]) or not np.isfinite(u["meas"]):
                continue
            out[(t, b, c)].append({
                "path": f"{t}_T{tx}_R{rx}", "cm": a["meas"] - u["meas"],
                "c7": a["L707"] - u["L707"], "cs": a["Lst"] - u["Lst"],
                "ident": abs(a["L707"] - a["Lst"]) < IDENT_DB and abs(u["L707"] - u["Lst"]) < IDENT_DB,
            })
    return out, cell


def stratum_stats(S, rng):
    res = []
    for key in sorted(S, key=lambda k: (TABLES.index(k[0]), BANDS.index(k[1]), CONTRASTS.index(k[2]))):
        v = S[key]
        n = len(v)
        e7 = np.array([x["c7"] - x["cm"] for x in v])
        es = np.array([x["cs"] - x["cm"] for x in v])
        r = {"table": key[0], "band": key[1], "contrast": key[2], "n_paths": n,
             "deciding": key[2] == "hi" and n >= MIN_PATHS,
             "mae_707": float(np.mean(np.abs(e7))) if n else np.nan,
             "mae_stock": float(np.mean(np.abs(es))) if n else np.nan,
             "mean_e_707": float(np.mean(e7)) if n else np.nan,
             "mean_e_stock": float(np.mean(es)) if n else np.nan,
             "n_identical": int(sum(x["ident"] for x in v))}
        r["D"] = r["mae_707"] - r["mae_stock"]
        if n:
            idx = rng.integers(0, n, size=(N_BOOT, n))
            Db = np.mean(np.abs(e7[idx]), axis=1) - np.mean(np.abs(es[idx]), axis=1)
            r["D_lo95"], r["D_hi95"] = (float(x) for x in np.percentile(Db, [2.5, 97.5]))
        else:
            r["D_lo95"] = r["D_hi95"] = np.nan
        r["sign"] = ("707" if r["D_hi95"] < 0 else "stock" if r["D_lo95"] > 0 else "none") if n else "none"
        res.append(r)
    return res


def decide(res):
    dec = [r for r in res if r["deciding"]]
    n707 = sum(r["sign"] == "707" for r in dec)
    nst = sum(r["sign"] == "stock" for r in dec)
    if n707 >= DECIDE_K and nst == 0:
        out = "A"
    elif nst >= DECIDE_K and n707 == 0:
        out = "B"
    else:
        out = "C"
    return out, n707, nst, len(dec)


def height_errors(cell):
    """Descriptive: each model's absolute 50 % error by table, band and measured height (valid cells)."""
    acc = {}
    for (t, tx, rx, b, h), r in cell.items():
        if r["bad"] or not np.isfinite(r["meas"]):
            continue
        acc.setdefault((t, b, h), []).append((r["L707"] - r["meas"], r["Lst"] - r["meas"]))
    out = []
    for k in sorted(acc):
        a = np.array(acc[k])
        out.append({"table": k[0], "band": k[1], "rx_ant_m": k[2], "n": len(a),
                    "mean_abs_e_707": float(np.mean(np.abs(a[:, 0]))), "mean_abs_e_stock": float(np.mean(np.abs(a[:, 1]))),
                    "mean_e_707": float(np.mean(a[:, 0])), "mean_e_stock": float(np.mean(a[:, 1]))})
    return out


def analyse(rows, check_counts=True):
    S, cell = contrasts(rows)
    counts = {k: len(v) for k, v in S.items()}
    if check_counts and counts != REGISTERED_COUNTS:
        diff = {f"{k}": (counts[k], REGISTERED_COUNTS[k]) for k in REGISTERED_COUNTS if counts[k] != REGISTERED_COUNTS[k]}
        raise SystemExit(f"Stratum counts differ from B32.md (got, registered): {diff}")
    rng = np.random.default_rng(SEED)
    res = stratum_stats(S, rng)
    return res, decide(res), height_errors(cell)


def write_csv(path, recs):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(recs[0].keys()))
        w.writeheader()
        for r in recs:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in r.items()})


def synth(kind, rng):
    """Synthetic rows with the predictions schema. kind: 'A' (707 closer), 'B' (stock closer), 'C' (equal)."""
    rows = []
    for t in TABLES:
        for tx in range(1, 11):
            for rx in range(1, 5):
                for b in BANDS:
                    base = 120 + rng.normal(0, 5)
                    true = {10.0: base, 3.0: base + 4 + rng.normal(0, 2), 0.35: base + 10 + rng.normal(0, 3)}
                    for h, m in true.items():
                        n7 = rng.normal(0, 1.0 if kind == "A" else 3.0)
                        ns = rng.normal(0, 3.0 if kind in ("A", "C") else 1.0)
                        if kind == "C":
                            n7 = rng.normal(0, 3.0)
                        rows.append({"table": t, "tx": tx, "rx": rx, "band": b, "h": h, "meas": m, "bad": False,
                                     "L707": m + n7, "Lst": m + ns})
    return rows


def selftest():
    rng = np.random.default_rng(123)
    for kind in ("A", "B", "C"):
        res, (out, n7, ns, nd), _ = analyse(synth(kind, rng), check_counts=False)
        print(f"self-test {kind}: outcome {out} ({n7} strata favour 707, {ns} favour stock, of {nd})")
        if out != kind:
            raise SystemExit(f"Self-test failed: expected {kind}, got {out}")
    # Identical models must give D = 0 and an interval of [0, 0]
    rows = synth("C", rng)
    for r in rows:
        r["L707"] = r["Lst"]
    res, (out, _, _, _), _ = analyse(rows, check_counts=False)
    if out != "C" or any(abs(r["D"]) > 1e-12 or r["n_identical"] != r["n_paths"] for r in res):
        raise SystemExit("Self-test failed: identical models")
    print("self-test identical: outcome C, D = 0 in every stratum")
    print("SELF-TEST PASS")


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--selftest":
        selftest()
        return
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    pred, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    res, (out, n7, ns, nd), herr = analyse(load(pred))
    write_csv(os.path.join(out_dir, "strata_rev1.csv"), res)
    write_csv(os.path.join(out_dir, "height_errors_rev1.csv"), herr)
    t7lo = {r["band"]: (r["mean_e_707"], r["mean_e_stock"]) for r in res if r["table"] == 7 and r["contrast"] == "lo"}
    dec = {"outcome": out, "strata_favour_707": n7, "strata_favour_stock": ns, "deciding_strata": nd,
           "rule": "B32.md section 3a: C_hi decides, A needs >= 6 of 10 favouring 707 and none favouring stock",
           "n_boot": N_BOOT, "seed": SEED,
           "prediction_table7_clo_both_under": all(a < 0 and b < 0 for a, b in t7lo.values()),
           "table7_clo_mean_e": t7lo,
           "prediction_note": ("The models' lower antenna is at 0.5 m (B32.md section 3a), which lowers the "
                               "modeled C_lo by construction, so this match doesn't test the forest reasoning.")}
    with open(os.path.join(out_dir, "decision_rev1.json"), "w") as f:
        json.dump(dec, f, indent=2)
    print(f"{'tab':>3} {'band':4} {'c':2} {'n':>3} {'mae707':>7} {'maeSt':>7} {'D':>7} {'95% interval':>17} "
          f"{'e707':>6} {'eSt':>6} {'ident':>5}")
    for r in res:
        print(f"{r['table']:>3} {r['band']:4} {r['contrast']:2} {r['n_paths']:>3} {r['mae_707']:7.2f} {r['mae_stock']:7.2f} "
              f"{r['D']:+7.2f} [{r['D_lo95']:+6.2f}, {r['D_hi95']:+6.2f}] {r['mean_e_707']:+6.2f} {r['mean_e_stock']:+6.2f} "
              f"{r['n_identical']:>5}{'' if r['deciding'] else '  (descriptive)'}")
    print(json.dumps(dec, indent=2))


if __name__ == "__main__":
    main()
