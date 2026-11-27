"""B38 D38a analysis: parts of the cascade step on B36's R1 rows (model only).

Usage:
    python3 -I d38a_analysis_rev1.py <repo> <out_dir>
    python3 -I d38a_analysis_rev1.py --selftest

Reads experiments/D38-cascade-parts-landcover/parts_rev1.csv (no measured
value). Rule: experiments/batches/B38.md section 2. Parts of
D2 = C2 - C1: principal (P - C1), secondary (U - P), correction (C2 - U).
Mean over rows; 95 % interval over paths (2,000 draws, seed 20261138,
numpy default_rng, paths sorted, draws of shape (2000, n_paths)). A part
carries D2 if mean/total >= 0.5 and its interval excludes zero.
"""
import csv
import json
import os
import sys

import numpy as np

SEED = 20261138
NDRAW = 2000
PARTS = {
    "principal_vs_bullington": ("L_P", "L_C1"),
    "secondary_edges": ("L_U", "L_P"),
    "correction_C": ("L_C2", "L_U"),
}


def load(path):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        for k in ("L_C1", "L_C1u", "L_P", "L_U", "L_C2", "f_mhz", "itm_mode"):
            r[k] = float(r[k])
        r["in_b36"] = r["in_b36"] in ("1", "true", "True")
    return rows


def boot(rows, fn, draws, paths):
    idx = {p: i for i, p in enumerate(paths)}
    s = np.zeros(len(paths)); c = np.zeros(len(paths))
    for r in rows:
        j = idx[r["path_id"]]
        s[j] += fn(r); c[j] += 1
    S = s[draws].sum(axis=1); C = c[draws].sum(axis=1)
    lo, hi = np.percentile(S / C, [2.5, 97.5])
    return {"mean": s.sum() / c.sum(), "lo": lo, "hi": hi, "n_rows": int(c.sum()), "n_paths": len(paths)}


def attribute(rows, seed=SEED):
    paths = sorted({r["path_id"] for r in rows})
    draws = np.random.default_rng(seed).integers(0, len(paths), size=(NDRAW, len(paths)))
    out = {"D2_total": boot(rows, lambda r: r["L_C2"] - r["L_C1"], draws, paths)}
    for k, (a, b) in PARTS.items():
        out[k] = boot(rows, lambda r, a=a, b=b: r[a] - r[b], draws, paths)
    out["bullington_correction_C1_minus_C1u"] = boot(rows, lambda r: r["L_C1"] - r["L_C1u"], draws, paths)
    ident = max(abs(sum(r[a] - r[b] for a, b in PARTS.values()) - (r["L_C2"] - r["L_C1"])) for r in rows)
    if ident > 1e-9:
        raise SystemExit(f"identity failed: {ident}")
    tot = out["D2_total"]["mean"]
    car = [k for k in PARTS if tot != 0 and out[k]["mean"] / tot >= 0.5
           and (out[k]["lo"] > 0 or out[k]["hi"] < 0)]
    out["carries"] = car[0] if len(car) == 1 else ("spread" if not car else car)
    out["identity_max_db"] = ident
    return out


def descriptive(rows):
    groups = {}
    for r in rows:
        for key in ("all", f"mode/{int(r['itm_mode'])}", f"f_mhz/{r['f_mhz']:g}"):
            groups.setdefault(key, []).append(r)
    res = []
    for key, g in sorted(groups.items()):
        n = len(g)
        m = lambda fn: sum(fn(r) for r in g) / n
        d = {"group": key, "n_rows": n, "D2": m(lambda r: r["L_C2"] - r["L_C1"])}
        for k, (a, b) in PARTS.items():
            d[k] = m(lambda r, a=a, b=b: r[a] - r[b])
        d["C1_minus_C1u"] = m(lambda r: r["L_C1"] - r["L_C1u"])
        res.append(d)
    return res


def selftest():
    rng = np.random.default_rng(3)

    def synth(p, s, c, noise=0.3):
        rows = []
        for q in range(29):
            e = rng.normal(0, noise)
            for _ in range(40):
                b = 140 + rng.normal(0, 5)
                P = b + p + e + rng.normal(0, noise)
                U = P + s + rng.normal(0, noise)
                C2 = U + c + rng.normal(0, noise)
                rows.append({"path_id": f"p{q:02d}", "L_C1": b, "L_C1u": b - 1, "L_P": P, "L_U": U,
                             "L_C2": C2, "f_mhz": 230.0, "itm_mode": 1.0, "in_b36": True})
        return rows

    assert attribute(synth(2.0, 0.1, 0.1))["carries"] == "principal_vs_bullington"
    assert attribute(synth(0.1, 2.0, 0.1))["carries"] == "secondary_edges"
    assert attribute(synth(0.1, 0.1, 2.0))["carries"] == "correction_C"
    assert attribute(synth(0.8, 0.8, 0.8))["carries"] == "spread"
    assert attribute(synth(-1.0, 3.0, 0.2))["carries"] == "secondary_edges"   # opposite-sign part
    rows = synth(0.1, 2.0, 0.1)
    out = attribute(rows)
    paths = sorted({r["path_id"] for r in rows})
    d = np.random.default_rng(SEED).integers(0, len(paths), size=(NDRAW, len(paths)))
    per = {p: [r["L_U"] - r["L_P"] for r in rows if r["path_id"] == p] for p in paths}
    est = [np.mean(np.concatenate([per[paths[j]] for j in row])) for row in d]
    lo, hi = np.percentile(est, [2.5, 97.5])
    assert abs(lo - out["secondary_edges"]["lo"]) < 1e-9 and abs(hi - out["secondary_edges"]["hi"]) < 1e-9
    print("selftest PASS")


def main(repo, out_dir):
    rows = [r for r in load(os.path.join(repo, "experiments", "D38-cascade-parts-landcover", "parts_rev1.csv"))
            if r["in_b36"]]
    r1 = [r for r in rows if r["set"] == "R1"]
    va = [r for r in rows if r["set"] == "VA"]
    if len(r1) != 1427 or len({r["path_id"] for r in r1}) != 29 or len(va) != 243:
        raise SystemExit("B36 population differs")
    dec = {"R1": attribute(r1), "VA_descriptive": attribute(va)}
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "d38a_attribution_rev1.json"), "w") as f:
        json.dump(dec, f, indent=2, default=float)
    out = [{"set": s, **d} for s, g in (("R1", r1), ("VA", va)) for d in descriptive(g)]
    with open(os.path.join(out_dir, "d38a_descriptive_rev1.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
        w.writeheader()
        for d in out:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in d.items()})
    print(json.dumps(dec, indent=1, default=float))


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        selftest()
    else:
        main(sys.argv[1], sys.argv[2])
