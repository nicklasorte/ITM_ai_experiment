"""B38 D38b: land cover in the first Fresnel zone and at the cascade's principal edge.

Usage:
    python3 -I d38b_fresnel_rev1.py <repo> <out_dir>
    python3 -I d38b_fresnel_rev1.py --selftest

Rule: experiments/batches/B38.md section 3. Population: Phase 2 rows with
siting O, not censored, with a 707 prediction. Footprint: interior samples
with ray(x) - (z + x (d - x) gamma_e / 2) < sqrt(lambda x (d - x) / d)
(ITU-R P.526-16 eq. (2)); f_F is the forest share (NLCD 41, 42, 43, 90).
Within each site, y = e_707 and x = f_F are demeaned within frequency x
obstructed strata; b = sum(xy) / sum(x^2); 95 % interval over paths, 2,000
draws, seed 20261138, sites R1, R2, R3, VA in order, paths sorted,
demeaning redone in each draw. Resolved: interval excludes zero and
|b| >= 5 dB. Outcome F- / F+ / none.
"""
import csv
import hashlib
import json
import math
import os
import sys

import numpy as np

SEED = 20261138
NDRAW = 2000
FOREST = {41, 42, 43, 90}
SITES = ["R1", "R2", "R3", "VA"]
B_MIN = 5.0
C_LIGHT = 299.792458  # m * MHz


def itm_gamma(h, N_0):
    """ITM's effective curvature (as d36_run_rev1 itm_gamma)."""
    np_ = len(h) - 1
    p10 = int(0.1 * np_)
    seg = h[p10:np_ - p10 + 1]
    acc = 0.0
    for v in seg:                     # sequential sum, as the C++
        acc += v
    h_sys = acc / (np_ - 2 * p10 + 1)
    N_s = N_0 if h_sys == 0 else N_0 * math.exp(-h_sys / 9460.0)
    return 157e-9 * (1.0 - 0.04665 * math.exp(N_s / 179.3))


def footprint(h, xi, htx, hrx, f_mhz, gamma_e):
    """Indices (0-based, interior) in the first Fresnel zone, and whether the path is obstructed."""
    n = len(h)
    d = (n - 1) * xi
    lam = C_LIGHT / f_mhz
    za, zb = h[0] + htx, h[-1] + hrx
    idx, obstructed = [], False
    for i in range(1, n - 1):
        x = i * xi
        ray = za + (zb - za) * x / d
        g = h[i] + x * (d - x) * gamma_e / 2.0
        c = ray - g
        if c < 0:
            obstructed = True
        if c < math.sqrt(lam * x * (d - x) / d):
            idx.append(i)
    return idx, obstructed


def slope(y, x, strata):
    """Within-stratum demeaned OLS slope through the origin."""
    y = np.asarray(y, float); x = np.asarray(x, float)
    _, code = np.unique(np.asarray(strata), return_inverse=True)
    cnt = np.bincount(code)
    yd = y - (np.bincount(code, y) / cnt)[code]
    xd = x - (np.bincount(code, x) / cnt)[code]
    den = (xd * xd).sum()
    return float((xd * yd).sum() / den) if den > 0 else float("nan")


def site_slope(rows, ykey, rng):
    paths = sorted({r["path_id"] for r in rows})
    pos = {p: [] for p in paths}
    for i, r in enumerate(rows):
        pos[r["path_id"]].append(i)
    Y = np.array([r[ykey] for r in rows]); X = np.array([r["f_F"] for r in rows])
    S = np.array([r["stratum"] for r in rows])
    b = slope(Y, X, S)
    draws = rng.integers(0, len(paths), size=(NDRAW, len(paths)))
    est = []
    for row in draws:
        ii = np.concatenate([pos[paths[j]] for j in row])
        est.append(slope(Y[ii], X[ii], S[ii]))
    est = np.array(est)
    est = est[np.isfinite(est)]
    lo, hi = np.percentile(est, [2.5, 97.5])
    res = (lo > 0 or hi < 0) and abs(b) >= B_MIN
    return {"b": b, "lo": float(lo), "hi": float(hi), "resolved": bool(res), "n_rows": len(rows),
            "n_paths": len(paths), "n_finite_draws": int(len(est))}


def decide(rows_by_site, ykey="e_707", seed=SEED):
    rng = np.random.default_rng(seed)
    out = {s: site_slope(rows_by_site[s], ykey, rng) for s in SITES}
    neg = sum(1 for s in SITES if out[s]["resolved"] and out[s]["b"] < 0)
    pos = sum(1 for s in SITES if out[s]["resolved"] and out[s]["b"] > 0)
    out["outcome"] = "F-" if neg >= 2 and pos == 0 else ("F+" if pos >= 2 and neg == 0 else "none")
    return out


def read_csv(p):
    with open(p, newline="") as f:
        return list(csv.DictReader(f))


def check_hash(path, shafile):
    want = open(shafile).read().split()[0]
    got = hashlib.sha256(open(path, "rb").read()).hexdigest()
    if want != got:
        raise SystemExit(f"hash mismatch: {path}")


def build(repo):
    lc_p = os.path.join(repo, "data", "landcover", "phase2_profiles_nlcd_rev1.csv")
    check_hash(lc_p, os.path.join(repo, "data", "landcover", "phase2_profiles_nlcd_rev1.sha256"))
    nl = {}
    for r in read_csv(lc_p):
        a = nl.setdefault(r["path_id"], {})
        for i in range(int(r["i_first"]), int(r["i_last"]) + 1):
            a[i] = int(r["nlcd2001"])          # 1-based sample index
    idx = {r["path_id"]: r for r in read_csv(os.path.join(repo, "data", "profiles", "profiles_index_rev1.csv"))
           if r["dataset"] == "phase2"}
    pred = {r["link_id"]: r for r in read_csv(os.path.join(repo, "experiments", "707r-rescore-screen36",
                                                           "predictions_phase2.csv"))}
    edges = {r["link_id"]: r for r in read_csv(os.path.join(repo, "experiments", "D38-cascade-parts-landcover",
                                                            "edges_rev1.csv"))}
    links = [r for r in read_csv(os.path.join(repo, "data", "links", "phase2_links_rev1.csv"))
             if r["siting"] == "O" and r["censored"] in ("0", "false", "False")]
    prof = {}
    rows, nofoot = [], 0
    for r in links:
        if r["link_id"] not in pred:
            raise SystemExit(f"no 707 prediction for {r['link_id']}")
        pid = r["path_id"]
        if pid not in prof:
            with open(os.path.join(repo, "data", "profiles", "phase2", pid + ".csv")) as f:
                next(f)
                prof[pid] = [float(v) for v in f.read().split()]
        h = prof[pid]
        if len(h) != int(idx[pid]["n_points"]):
            raise SystemExit(f"profile length {pid}")
        xi = float(idx[pid]["spacing_m"])
        f = float(r["f_mhz"])
        ge = itm_gamma(h, float(r["N_0"]))
        fp, obs = footprint(h, xi, float(r["htx_m"]), float(r["hrx_m"]), f, ge)
        lc = nl[pid]
        p = pred[r["link_id"]]
        meas = float(p["meas_lb_db"])
        e = edges.get(r["link_id"])
        pe_cls = lc[int(e["principal_index"])] if e and float(e["principal_nu"]) > -0.78 else None
        row = {"link_id": r["link_id"], "path_id": pid, "set": r["set"], "f_mhz": f,
               "obstructed": obs, "n_foot": len(fp),
               "f_F": (sum(1 for i in fp if lc[i + 1] in FOREST) / len(fp)) if fp else None,
               "principal_class": pe_cls,
               "e_707": float(p["var_lb_50"]) - meas, "e_stock": float(p["itm_lb_50"]) - meas,
               "stratum": f"{f:g}|{int(obs)}"}
        if not fp:
            nofoot += 1
        rows.append(row)
    return rows, nofoot


def selftest():
    # (a) flat profile, known clearance: antennas 10 m on flat ground, 1 km, 300 MHz
    h = [0.0] * 101
    fp, obs = footprint(h, 10.0, 10.0, 10.0, 299.792458, 0.0)
    lam = 1.0
    exp = [i for i in range(1, 100) if 10.0 < math.sqrt(lam * (10 * i) * (1000 - 10 * i) / 1000)]
    assert fp == exp and not obs and len(exp) > 0
    # (b) planted slope -10 dB per unit forest share, resolved and F-
    rng = np.random.default_rng(5)

    def synth(bt):
        out = {}
        for s in SITES:
            rr = []
            for q in range(30):
                fq = rng.uniform(0, 1)
                for k in range(20):
                    ff = min(1, max(0, fq + rng.normal(0, 0.05)))
                    f = [230.0, 910.0][k % 2]
                    rr.append({"path_id": f"{s}{q:02d}", "f_F": ff, "stratum": f"{f:g}|0",
                               "e_707": bt * ff + (3.0 if f > 500 else 0.0) + rng.normal(0, 2)})
            out[s] = rr
        return out

    d = decide(synth(-10.0))
    assert d["outcome"] == "F-" and all(d[s]["resolved"] for s in SITES)
    assert decide(synth(0.0))["outcome"] == "none"
    # (d) bootstrap against an independent loop for one site
    S = synth(-10.0)
    rng2 = np.random.default_rng(SEED)
    first = site_slope(S["R1"], "e_707", rng2)
    paths = sorted({r["path_id"] for r in S["R1"]})
    dr = np.random.default_rng(SEED).integers(0, len(paths), size=(NDRAW, len(paths)))
    est = []
    for row in dr:
        rr = [r for j in row for r in S["R1"] if r["path_id"] == paths[j]]
        est.append(slope([r["e_707"] for r in rr], [r["f_F"] for r in rr], [r["stratum"] for r in rr]))
    lo, hi = np.percentile(est, [2.5, 97.5])
    assert abs(lo - first["lo"]) < 1e-9 and abs(hi - first["hi"]) < 1e-9
    print("selftest PASS")


def main(repo, out_dir):
    rows, nofoot = build(repo)
    use = [r for r in rows if r["f_F"] is not None]
    by = {s: [r for r in use if r["set"] == s] for s in SITES}
    dec = {"population_rows": len(rows), "no_footprint_rows": nofoot, "used_rows": len(use),
           "e_707": decide(by, "e_707"), "e_stock_descriptive": decide(by, "e_stock")}
    # descriptive: forest share and error by site; principal-edge class on obstructed rows
    desc = []
    for s in SITES:
        g = by[s]
        ob = [r for r in g if r["obstructed"] and r["principal_class"] is not None]
        fe = [r for r in ob if r["principal_class"] in FOREST]
        nf = [r for r in ob if r["principal_class"] not in FOREST]
        m = lambda L, k: (sum(r[k] for r in L) / len(L)) if L else float("nan")
        desc.append({"set": s, "rows": len(g), "paths": len({r["path_id"] for r in g}),
                     "mean_f_F": m(g, "f_F"), "share_obstructed": m([{"o": float(r["obstructed"])} for r in g], "o"),
                     "obstructed_with_edge": len(ob), "edge_forest_share": (len(fe) / len(ob)) if ob else float("nan"),
                     "e707_edge_forest": m(fe, "e_707"), "e707_edge_not_forest": m(nf, "e_707"),
                     "estock_edge_forest": m(fe, "e_stock"), "estock_edge_not_forest": m(nf, "e_stock")})
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "d38b_decision_rev1.json"), "w") as f:
        json.dump(dec, f, indent=2)
    with open(os.path.join(out_dir, "d38b_descriptive_rev1.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(desc[0].keys()))
        w.writeheader()
        for d in desc:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in d.items()})
    with open(os.path.join(out_dir, "d38b_rows_rev1.csv"), "w", newline="") as f:
        keys = ["link_id", "path_id", "set", "f_mhz", "obstructed", "n_foot", "f_F", "principal_class",
                "e_707", "e_stock"]
        w = csv.DictWriter(f, fieldnames=keys, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: (f"{r[k]:.6g}" if isinstance(r[k], float) else r[k]) for k in keys})
    print(json.dumps(dec, indent=1))


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        selftest()
    else:
        main(sys.argv[1], sys.argv[2])
