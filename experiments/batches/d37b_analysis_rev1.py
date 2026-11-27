"""B37 D37b analysis: attribute 707 minus stock on B36's R1 rows (model only).

Usage:
    python3 -I d37b_analysis_rev1.py <repo> <out_dir>
    python3 -I d37b_analysis_rev1.py --selftest

Reads experiments/D37-pe-repair-and-707-parts/parts_rev1.csv (no measured
value). Registered rule: experiments/batches/B37.md section 3.
Steps D1 = C1 - S, D2 = C2 - C1, D3 = C3 - C2; mean over rows, 95 %
interval over paths (2,000 draws, seed 20261137, numpy default_rng, paths
sorted, draws of shape (2000, n_paths)); D1 + D2 + D3 = C3 - S by
construction. A step "carries" the excess if its mean is at least half of
mean(C3 - S) and its interval excludes zero; otherwise the result is
"spread".
"""
import csv
import json
import os
import sys

import numpy as np

SEED = 20261137
NDRAW = 2000


def load(path):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        for k in ("L_S", "L_C1", "L_C2", "L_C3", "L_C4", "L_ba_db", "L_bs_db", "A_s_db",
                  "A_delta_db", "bound_binds", "f_mhz", "itm_mode"):
            r[k] = float(r[k])
    return rows


def boot_mean(rows, fn, rng_draws, paths):
    """Ratio-of-sums mean of fn over rows; interval over resampled paths."""
    idx = {p: i for i, p in enumerate(paths)}
    s = np.zeros(len(paths))
    c = np.zeros(len(paths))
    for r in rows:
        v = fn(r)
        if v is None:
            continue
        j = idx[r["path_id"]]
        s[j] += v
        c[j] += 1
    if c.sum() == 0:
        return None
    point = s.sum() / c.sum()
    S = s[rng_draws].sum(axis=1)
    C = c[rng_draws].sum(axis=1)
    ok = C > 0
    est = S[ok] / C[ok]
    lo, hi = np.percentile(est, [2.5, 97.5])
    return {"mean": point, "lo": lo, "hi": hi, "n_rows": int(c.sum()),
            "n_paths": int((c > 0).sum())}


def attribute(rows, seed=SEED):
    paths = sorted({r["path_id"] for r in rows})
    rng = np.random.default_rng(seed)
    draws = rng.integers(0, len(paths), size=(NDRAW, len(paths)))
    f = {
        "total": lambda r: r["L_C3"] - r["L_S"],
        "D1_delta_bullington": lambda r: r["L_C1"] - r["L_S"],
        "D2_cascade": lambda r: r["L_C2"] - r["L_C1"],
        "D3_bound": lambda r: r["L_C3"] - r["L_C2"],
        "C4_minus_C3": lambda r: r["L_C4"] - r["L_C3"],
    }
    out = {k: boot_mean(rows, fn, draws, paths) for k, fn in f.items()}
    ident = max(abs((r["L_C1"] - r["L_S"]) + (r["L_C2"] - r["L_C1"]) + (r["L_C3"] - r["L_C2"])
                    - (r["L_C3"] - r["L_S"])) for r in rows)
    if ident > 1e-9:
        raise SystemExit(f"identity check failed: {ident}")
    tot = out["total"]["mean"]
    carriers = []
    for k in ("D1_delta_bullington", "D2_cascade", "D3_bound"):
        s = out[k]
        excl = s["lo"] > 0 or s["hi"] < 0
        if tot != 0 and s["mean"] / tot >= 0.5 and excl:
            carriers.append(k)
    out["carries"] = carriers[0] if len(carriers) == 1 else ("spread" if not carriers else carriers)
    out["identity_max_db"] = ident
    return out


def descriptive(rows):
    """Plain means (no interval) by mode, by frequency, and delta parts."""
    res = []
    groups = {}
    for r in rows:
        for key in (("all",), ("mode", int(r["itm_mode"])), ("f_mhz", int(r["f_mhz"]))):
            groups.setdefault(key, []).append(r)
    for key, g in sorted(groups.items(), key=lambda kv: str(kv[0])):
        n = len(g)
        m = lambda fn: sum(fn(r) for r in g) / n
        res.append({
            "group": "/".join(str(x) for x in key), "n_rows": n,
            "total": m(lambda r: r["L_C3"] - r["L_S"]),
            "D1": m(lambda r: r["L_C1"] - r["L_S"]),
            "D2": m(lambda r: r["L_C2"] - r["L_C1"]),
            "D3": m(lambda r: r["L_C3"] - r["L_C2"]),
            "C4_minus_C3": m(lambda r: r["L_C4"] - r["L_C3"]),
            "L_ba_minus_L_bs": m(lambda r: r["L_ba_db"] - r["L_bs_db"]),
            "pos_As_minus_Lbs": m(lambda r: max(r["A_s_db"] - r["L_bs_db"], 0.0)),
            "share_As_gt_Lbs": m(lambda r: 1.0 if r["A_s_db"] - r["L_bs_db"] > 0 else 0.0),
            "share_bound_binds": m(lambda r: r["bound_binds"]),
        })
    return res


def selftest():
    rng = np.random.default_rng(1)

    def synth(d1, d2, d3, npath=29, nper=40, noise=0.3):
        rows = []
        for p in range(npath):
            pe = rng.normal(0, noise)
            for _ in range(nper):
                S = 140 + rng.normal(0, 5)
                a = d1 + pe + rng.normal(0, noise)
                b = d2 + rng.normal(0, noise)
                c = d3 + rng.normal(0, noise)
                rows.append({"path_id": f"p{p:02d}", "L_S": S, "L_C1": S + a, "L_C2": S + a + b,
                             "L_C3": S + a + b + c, "L_C4": S + a + b + c, "L_ba_db": 0.0,
                             "L_bs_db": 0.0, "A_s_db": 0.0, "A_delta_db": 0.0,
                             "bound_binds": 0.0, "f_mhz": 230.0, "itm_mode": 1.0})
        return rows

    assert attribute(synth(2.5, 0.0, 0.0))["carries"] == "D1_delta_bullington"
    assert attribute(synth(0.2, 2.3, 0.0))["carries"] == "D2_cascade"
    assert attribute(synth(0.0, 0.1, 2.4))["carries"] == "D3_bound"
    assert attribute(synth(1.0, 1.0, 1.0))["carries"] == "spread"
    # large but noisy step: interval includes zero, so not a carrier
    assert attribute(synth(2.5, 0.0, 0.0, noise=40.0))["carries"] == "spread"
    # independent interval check for one statistic
    rows = synth(2.5, 0.0, 0.0)
    out = attribute(rows)
    paths = sorted({r["path_id"] for r in rows})
    d = np.random.default_rng(SEED).integers(0, len(paths), size=(NDRAW, len(paths)))
    per = {p: [r["L_C1"] - r["L_S"] for r in rows if r["path_id"] == p] for p in paths}
    est = [np.mean(np.concatenate([per[paths[j]] for j in row])) for row in d]
    lo, hi = np.percentile(est, [2.5, 97.5])
    assert abs(lo - out["D1_delta_bullington"]["lo"]) < 1e-9 and abs(hi - out["D1_delta_bullington"]["hi"]) < 1e-9
    print("selftest PASS")


def main(repo, out_dir):
    rows = load(os.path.join(repo, "experiments", "D37-pe-repair-and-707-parts", "parts_rev1.csv"))
    r1 = [r for r in rows if r["set"] == "R1"]
    if len(r1) != 1427 or len({r["path_id"] for r in r1}) != 29:
        raise SystemExit("R1 population differs from B36")
    dec = {"R1": attribute(r1)}
    va = [r for r in rows if r["set"] == "VA"]
    dec["VA_descriptive"] = attribute(va)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "attribution_rev1.json"), "w") as f:
        json.dump(dec, f, indent=2, default=float)
    with open(os.path.join(out_dir, "attribution_descriptive_rev1.csv"), "w", newline="") as f:
        out = []
        for s, g in (("R1", r1), ("VA", va)):
            for d in descriptive(g):
                out.append({"set": s, **d})
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
        w.writeheader()
        for d in out:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in d.items()})
    print(json.dumps(dec, indent=2, default=float))


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        selftest()
    else:
        main(sys.argv[1], sys.argv[2])
