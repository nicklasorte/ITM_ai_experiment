#!/usr/bin/env python3
"""B36 (D36) registered analysis: PE reference against 707 on gentle Phase 2 paths.

Usage:
    python3 -I d36_analysis_rev1.py --selftest
    python3 -I d36_analysis_rev1.py <repo root> <out dir>

Rule: experiments/batches/B36.md section 4. Error e = L_model - meas_lb_db.
Deciding strata R1 and VA; R2 descriptive. D = mean|e_PE| - mean|e_707| over
rows; 95 % percentile interval, 2,000 draws over paths,
numpy.random.default_rng(20261136), R1 first then VA, paths sorted, each
draw rng.integers(0, n, size=(2000, n)), n the stratum's path count after
convergence exclusions. Resolved: |D| >= 1 dB and the interval excludes 0.
P: resolved negative in both; M: resolved positive in both; N otherwise.
A stratum that loses more than 20 % of its rows to the convergence screen
is descriptive, and the outcome is then N.

Script details fixed before the analysis is run on data: descriptive
intervals use default_rng(20261137) over the paths with rows, in the order
written below (stock D per stratum, then D by frequency per stratum, then
the point-value D per stratum).
"""
import csv
import json
import os
import sys

import numpy as np

N_BOOT = 2000
SEED = 20261136
SEED_DESC = 20261137
RES = 1.0
DROP = 0.20
DECIDE = ["R1", "VA"]


def load(root):
    pe = {r["link_id"]: r for r in csv.DictReader(open(os.path.join(root, "experiments", "D36-pe-reference", "pe_predictions_rev1.csv")))}
    rows = []
    for r in csv.DictReader(open(os.path.join(root, "experiments", "707r-rescore-screen36", "predictions_phase2.csv"))):
        p = pe.get(r["link_id"])
        if p is None:
            continue
        rows.append({"path": p["path_id"], "set": p["set"], "f": float(p["f_mhz"]), "h": float(p["hrx_m"]),
                     "conv": p["converged"].strip().lower() in ("1", "true"),
                     "meas": float(r["meas_lb_db"]), "pe": float(p["L_pe_db"]),
                     "pe_pt": float(p["L_pe_db"]) - float(p["A_pe_db"]) + float(p["A_pe_point_db"]),
                     "m707": float(r["var_lb_50"]), "stock": float(r["itm_lb_50"])})
    if len(rows) != len(pe):
        raise SystemExit(f"Joined {len(rows)} rows of {len(pe)} PE rows; every PE row needs a 707 prediction.")
    return rows


def boot(rows, key_a, key_b, rng, over_all_paths=True):
    """Mean of |e_a| - |e_b| and its bootstrap interval over paths (ratio of sums)."""
    paths = sorted({r["path"] for r in rows})
    n = len(paths)
    idx = rng.integers(0, max(n, 1), size=(N_BOOT, max(n, 1)))
    if not rows:
        return {"n_rows": 0, "n_paths": 0, "D": None, "lo95": None, "hi95": None, "resolved": False}
    pos = {p: i for i, p in enumerate(paths)}
    s = np.zeros(n); c = np.zeros(n)
    for r in rows:
        v = abs(r[key_a] - r["meas"]) - abs(r[key_b] - r["meas"])
        s[pos[r["path"]]] += v; c[pos[r["path"]]] += 1
    num = s[idx].sum(axis=1); den = c[idx].sum(axis=1)
    if np.any(den == 0):
        raise SystemExit("A bootstrap draw has no rows.")
    b = num / den
    D = float(s.sum() / c.sum())
    lo, hi = np.percentile(b, [2.5, 97.5])
    return {"n_rows": int(c.sum()), "n_paths": n, "D": D, "lo95": float(lo), "hi95": float(hi),
            "resolved": bool(abs(D) >= RES and (lo > 0 or hi < 0))}


def analyse(rows):
    out = {"strata": {}}
    rng = np.random.default_rng(SEED)
    labels = {}
    for st in DECIDE:
        allr = [r for r in rows if r["set"] == st]
        keep = [r for r in allr if r["conv"]]
        drop = 1 - len(keep) / len(allr) if allr else 1.0
        res = boot(keep, "pe", "m707", rng)
        res["dropped_share"] = drop
        res["descriptive"] = drop > DROP
        out["strata"][st] = res
        if res["descriptive"] or not res["resolved"]:
            labels[st] = "none"
        else:
            labels[st] = "pe" if res["D"] < 0 else "707"
    if labels["R1"] == labels["VA"] == "pe":
        out["outcome"] = "P"
    elif labels["R1"] == labels["VA"] == "707":
        out["outcome"] = "M"
    else:
        out["outcome"] = "N"
    # descriptive
    rx = np.random.default_rng(SEED_DESC)
    desc = []
    sets = DECIDE + ["R2"]
    for st in sets:
        keep = [r for r in rows if r["set"] == st and r["conv"]]
        d = boot(keep, "pe", "stock", rx); d.update({"stratum": st, "what": "PE vs stock"}); desc.append(d)
    for st in sets:
        keep = [r for r in rows if r["set"] == st and r["conv"]]
        for f in sorted({r["f"] for r in keep}):
            k2 = [r for r in keep if r["f"] == f]
            d = boot(k2, "pe", "m707", rx); d.update({"stratum": st, "what": f"PE vs 707, {f:g} MHz"}); desc.append(d)
    for st in sets:
        keep = [r for r in rows if r["set"] == st and r["conv"]]
        d = boot(keep, "pe_pt", "m707", rx); d.update({"stratum": st, "what": "PE point value vs 707"}); desc.append(d)
    signed = []
    for st in sets:
        keep = [r for r in rows if r["set"] == st and r["conv"]]
        for f in [None] + sorted({r["f"] for r in keep}):
            k2 = [r for r in keep if f is None or r["f"] == f]
            if not k2:
                continue
            signed.append({"stratum": st, "f_mhz": "all" if f is None else f, "n_rows": len(k2),
                           "mean_e_pe": float(np.mean([r["pe"] - r["meas"] for r in k2])),
                           "mean_e_707": float(np.mean([r["m707"] - r["meas"] for r in k2])),
                           "mean_e_stock": float(np.mean([r["stock"] - r["meas"] for r in k2])),
                           "mean_abs_e_pe": float(np.mean([abs(r["pe"] - r["meas"]) for r in k2])),
                           "mean_abs_e_707": float(np.mean([abs(r["m707"] - r["meas"]) for r in k2])),
                           "mean_abs_e_stock": float(np.mean([abs(r["stock"] - r["meas"]) for r in k2])),
                           "share_pe_707_within_1db": float(np.mean([abs(r["pe"] - r["m707"]) < 1 for r in k2]))})
    return out, desc, signed


def synth(rng, kind, drop_va=0.0):
    rows = []
    for st, npath in (("R1", 29), ("VA", 61), ("R2", 1)):
        for i in range(npath):
            off = rng.normal(0, 3)
            conv = not (st == "VA" and i < round(drop_va * npath))
            for f in (230, 410, 910):
                for h in (1, 3, 9):
                    meas = 120 + off + rng.normal(0, 2)
                    m7 = meas + rng.normal(0, 6)
                    if kind == "P":
                        pe = meas + rng.normal(0, 2)
                    elif kind == "M":
                        pe = meas + rng.normal(0, 12)
                    else:
                        pe = m7 + rng.normal(0, 0.3)
                    rows.append({"path": f"{st}{i:02d}", "set": st, "f": f, "h": h, "conv": conv, "meas": meas,
                                 "pe": pe, "pe_pt": pe, "m707": m7, "stock": m7})
    return rows


def selftest():
    rng = np.random.default_rng(3)
    for kind in ("P", "M", "N"):
        o = analyse(synth(rng, kind))[0]
        print(f"self-test {kind}: {o['outcome']}")
        if o["outcome"] != kind:
            raise SystemExit(f"Self-test failed: {kind} gave {o['outcome']}")
    o = analyse(synth(rng, "P", drop_va=0.3))[0]
    print(f"self-test P with 30 % of VA unconverged: {o['outcome']}, VA descriptive {o['strata']['VA']['descriptive']}")
    if o["outcome"] != "N" or not o["strata"]["VA"]["descriptive"]:
        raise SystemExit("Self-test failed: 20 % rule")
    # independent check of the deciding interval (seed, order, shape)
    rows = synth(rng, "P")
    o = analyse(rows)[0]
    g = np.random.default_rng(20261136)
    for st in DECIDE:
        keep = [r for r in rows if r["set"] == st and r["conv"]]
        paths = sorted({r["path"] for r in keep}); n = len(paths)
        draws = g.integers(0, n, size=(2000, n))
        vals = {p: [abs(r["pe"] - r["meas"]) - abs(r["m707"] - r["meas"]) for r in keep if r["path"] == p] for p in paths}
        b = [sum(sum(vals[paths[k]]) for k in row) / sum(len(vals[paths[k]]) for k in row) for row in draws]
        lo, hi = np.percentile(b, [2.5, 97.5])
        got = o["strata"][st]
        if abs(got["lo95"] - lo) > 1e-9 or abs(got["hi95"] - hi) > 1e-9:
            raise SystemExit(f"Self-test failed: {st} interval doesn't match the registered draws")
    print("self-test intervals match an independent computation")
    print("SELF-TEST PASS")


def write_csv(path, rows):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        for r in rows:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in r.items()})


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--selftest":
        selftest(); return
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    root, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    rows = load(root)
    dec, desc, signed = analyse(rows)
    json.dump(dec, open(os.path.join(out, "decision_rev1.json"), "w"), indent=2)
    write_csv(os.path.join(out, "descriptive_rev1.csv"), desc)
    write_csv(os.path.join(out, "signed_rev1.csv"), signed)
    print(json.dumps(dec, indent=2))
    for d in desc:
        print(f"  {d['stratum']:3s} {d['what']:28s} n={d['n_rows']:5d} D={d['D'] if d['D'] is None else round(d['D'], 2)} "
              f"[{d['lo95'] if d['lo95'] is None else round(d['lo95'], 2)}, {d['hi95'] if d['hi95'] is None else round(d['hi95'], 2)}]")
    for s in signed:
        print("  " + ", ".join(f"{k}={v:.2f}" if isinstance(v, float) else f"{k}={v}" for k, v in s.items()))


if __name__ == "__main__":
    main()
