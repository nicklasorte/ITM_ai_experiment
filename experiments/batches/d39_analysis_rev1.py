"""B39: secondary-edge separation on R1 (D39a, model only) and EVH canopy in the first Fresnel zone (D39b).

Usage:
    python3 -I d39_analysis_rev1.py <repo> <out_dir>
    python3 -I d39_analysis_rev1.py --selftest <repo>

Rules: experiments/batches/B39.md sections 2 and 3. Seed 20261139.
"""
import csv
import hashlib
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import d38b_fresnel_rev1 as d38  # noqa: E402  (footprint geometry, itm_gamma, slope)

SEED = 20261139
NDRAW = 2000
SITES = ["R1", "R2", "R3", "VA"]
B_MIN = 5.0
CUTS = [1, 2, 3, 5, 10]


def J(nu):
    """ITU-R P.526-16 eq. (31); 0 for nu <= -0.78."""
    if not (nu > -0.78):
        return 0.0
    return 6.9 + 20 * math.log10(math.sqrt((nu - 0.1) ** 2 + 1) + nu - 0.1)


def parse(s):
    return [float(v) for v in s.split()]


def secondaries(e):
    """T and the secondary contributions [(separation, T*w*J)] for one edges row (D39 edges_rev2.csv, full precision)."""
    idx = [int(round(v)) for v in parse(e["edges"])]
    nu = parse(e["nu"]); w = parse(e["weights"])
    if len(idx) == 1:
        return 0.0, []
    if len(idx) != 3:
        raise SystemExit(f"unexpected edge count on {e['link_id']}")
    Jp = J(nu[1])
    T = 1.0 - math.exp(-Jp / 6.0)
    out = []
    for k in (0, 2):
        out.append((abs(idx[k] - idx[1]), T * w[k] * J(nu[k])))
    return T, out


def evh_height(code):
    return float(code - 100) if 101 <= code <= 199 else 0.0


def canopy_q(h, xi, htx, hrx, f_mhz, gamma_e, tree):
    """Share of interior samples where only the canopy reaches into the first Fresnel zone."""
    n = len(h)
    d = (n - 1) * xi
    lam = d38.C_LIGHT / f_mhz
    za, zb = h[0] + htx, h[-1] + hrx
    cnt = 0
    for i in range(1, n - 1):
        x = i * xi
        ray = za + (zb - za) * x / d
        g = h[i] + x * (d - x) * gamma_e / 2.0
        r1 = math.sqrt(lam * x * (d - x) / d)
        if ray - g >= r1 and ray - (g + tree[i]) < r1:
            cnt += 1
    return cnt / (n - 2)


def share_interval(rows, cut, seed):
    """Ratio-of-sums share of secondary contribution within `cut` samples; interval over paths."""
    paths = sorted({r["path_id"] for r in rows})
    ix = {p: i for i, p in enumerate(paths)}
    num = np.zeros(len(paths)); den = np.zeros(len(paths))
    for r in rows:
        for sep, v in r["sec"]:
            den[ix[r["path_id"]]] += v
            if sep <= cut:
                num[ix[r["path_id"]]] += v
    draws = np.random.default_rng(seed).integers(0, len(paths), size=(NDRAW, len(paths)))
    N = num[draws].sum(axis=1); D = den[draws].sum(axis=1)
    ok = D > 0
    lo, hi = np.percentile(N[ok] / D[ok], [2.5, 97.5])
    return {"share": float(num.sum() / den.sum()), "lo": float(lo), "hi": float(hi),
            "total_secondary_db_sum": float(den.sum()), "n_rows": len(rows), "n_paths": len(paths)}


def reading(s):
    return "adjacent" if s["lo"] > 0.5 else ("separated" if s["hi"] < 0.5 else "mixed")


def decide_q(by, ykey, seed, sites=SITES):
    rng = np.random.default_rng(seed)
    out = {}
    for s in sites:
        rows = [dict(r, f_F=r["q"]) for r in by[s]]          # d38.site_slope reads "f_F"
        out[s] = d38.site_slope(rows, ykey, rng)
    neg = sum(1 for s in sites if out[s]["resolved"] and out[s]["b"] < 0)
    pos = sum(1 for s in sites if out[s]["resolved"] and out[s]["b"] > 0)
    out["outcome"] = "C-" if neg >= 2 and pos == 0 else ("C+" if pos >= 2 and neg == 0 else "none")
    return out


def read_csv(p):
    with open(p, newline="") as f:
        return list(csv.DictReader(f))


def rle(path, key):
    out = {}
    for r in read_csv(path):
        a = out.setdefault(r["path_id"], {})
        for i in range(int(r["i_first"]), int(r["i_last"]) + 1):
            a[i] = int(r[key])
    return out


def d39a(repo):
    base = os.path.join(repo, "experiments", "D38-cascade-parts-landcover")
    parts = {r["link_id"]: r for r in read_csv(os.path.join(base, "parts_rev1.csv"))}
    edges = {r["link_id"]: r for r in read_csv(os.path.join(repo, "experiments", "D39-secondary-edges-canopy", "edges_rev2.csv"))}
    worst = 0.0
    rows = []
    for lid, p in parts.items():
        T, sec = secondaries(edges[lid])
        got = sum(v for _, v in sec)
        want = float(p["Lba_U"]) - float(p["Lba_P"])
        worst = max(worst, abs(got - want))
        if p["in_b36"] in ("1", "true", "True") and p["set"] in ("R1", "VA"):
            rows.append({"path_id": p["path_id"], "set": p["set"], "itm_mode": int(float(p["itm_mode"])),
                         "sec": sec})
    if worst > 1e-9:
        raise SystemExit(f"rebuild of T(L_t + L_r) failed: {worst} dB")
    r1 = [r for r in rows if r["set"] == "R1"]; va = [r for r in rows if r["set"] == "VA"]
    if len(r1) != 1427 or len(va) != 243:
        raise SystemExit("B36 population differs")
    res = {"rebuild_max_db": worst, "R1": {}, "VA_descriptive": {}}
    for c in CUTS:
        res["R1"][f"within_{c}"] = share_interval(r1, c, SEED)
        res["VA_descriptive"][f"within_{c}"] = share_interval(va, c, SEED)
    res["R1"]["reading"] = reading(res["R1"]["within_3"])
    for m in (1, 2):
        g = [r for r in r1 if r["itm_mode"] == m]
        res["R1"][f"mode{m}_within_3"] = share_interval(g, 3, SEED)
    return res


def d39b(repo):
    evh_p = os.path.join(repo, "experiments", "D30-landfire-evh", "phase2_profiles_evh_rev1.csv")
    d38.check_hash(evh_p, os.path.join(repo, "experiments", "D30-landfire-evh", "phase2_profiles_evh_rev1.sha256"))
    evh = rle(evh_p, "evh_code")
    idx = {r["path_id"]: r for r in read_csv(os.path.join(repo, "data", "profiles", "profiles_index_rev1.csv"))
           if r["dataset"] == "phase2"}
    pred = {r["link_id"]: r for r in read_csv(os.path.join(repo, "experiments", "707r-rescore-screen36",
                                                           "predictions_phase2.csv"))}
    links = [r for r in read_csv(os.path.join(repo, "data", "links", "phase2_links_rev1.csv"))
             if r["siting"] == "O" and r["censored"] in ("0", "false", "False")]
    prof = {}
    rows = []
    for r in links:
        pid = r["path_id"]
        if pid not in prof:
            with open(os.path.join(repo, "data", "profiles", "phase2", pid + ".csv")) as f:
                next(f)
                h = [float(v) for v in f.read().split()]
            if len(h) != int(idx[pid]["n_points"]):
                raise SystemExit(f"profile length {pid}")
            ev = evh[pid]
            if len(ev) != len(h):
                raise SystemExit(f"EVH length {pid}")
            prof[pid] = (h, [evh_height(ev[i + 1]) for i in range(len(h))])
        h, tree = prof[pid]
        xi = float(idx[pid]["spacing_m"]); f = float(r["f_mhz"])
        ge = d38.itm_gamma(h, float(r["N_0"]))
        _, obs = d38.footprint(h, xi, float(r["htx_m"]), float(r["hrx_m"]), f, ge)
        q = canopy_q(h, xi, float(r["htx_m"]), float(r["hrx_m"]), f, ge, tree)
        p = pred[r["link_id"]]
        meas = float(p["meas_lb_db"])
        rows.append({"link_id": r["link_id"], "path_id": pid, "set": r["set"], "f_mhz": f, "q": q,
                     "obstructed": obs, "stratum": f"{f:g}|{int(obs)}",
                     "e_707": float(p["var_lb_50"]) - meas, "e_stock": float(p["itm_lb_50"]) - meas})
    by = {s: [r for r in rows if r["set"] == s] for s in SITES}
    res = {"population_rows": len(rows), "e_707": decide_q(by, "e_707", SEED),
           "e_stock_descriptive": decide_q(by, "e_stock", SEED)}
    for drop in SITES:
        keep = [s for s in SITES if s != drop]
        res[f"e_707_without_{drop}"] = decide_q(by, "e_707", SEED, keep)["outcome"]
    res["descriptive"] = {s: {"mean_q": float(np.mean([r["q"] for r in by[s]])),
                              "rows_q_pos": sum(1 for r in by[s] if r["q"] > 0),
                              "max_q": max(r["q"] for r in by[s])} for s in SITES}
    return res, rows


def selftest(repo):
    # (a) rebuild on the committed B38 outputs
    base = os.path.join(repo, "experiments", "D38-cascade-parts-landcover")
    parts = read_csv(os.path.join(base, "parts_rev1.csv"))[:3000]
    edges = {r["link_id"]: r for r in read_csv(os.path.join(repo, "experiments", "D39-secondary-edges-canopy", "edges_rev2.csv"))}
    for p in parts:
        _, sec = secondaries(edges[p["link_id"]])
        assert abs(sum(v for _, v in sec) - (float(p["Lba_U"]) - float(p["Lba_P"]))) < 1e-9
    # (b) hand-built row
    e = {"link_id": "x", "edges": "10 14 30", "nu": "0.5 1.2 -2", "weights": "1 1 0.4"}
    T, sec = secondaries(e)
    assert abs(T - (1 - math.exp(-J(1.2) / 6))) < 1e-15 and sec[0][0] == 4 and sec[1][0] == 16
    assert abs(sec[0][1] - T * J(0.5)) < 1e-12 and sec[1][1] == 0.0
    # (c) flat profile, 20 m antennas, 1 km, 300 MHz (lambda 1 m); trees of 10 m on samples 40-60
    h = [0.0] * 101
    tree = [10.0 if 40 <= i <= 60 else 0.0 for i in range(101)]
    q = canopy_q(h, 10.0, 20.0, 20.0, 299.792458, 0.0, tree)
    exp = 0
    for i in range(1, 100):
        x = 10.0 * i; r1 = math.sqrt(x * (1000 - x) / 1000)
        if 20.0 >= r1 and 20.0 - tree[i] < r1:
            exp += 1
    assert q == exp / 99 and exp > 0
    # (d) planted slope, (e) independent bootstrap: d38b's tested site_slope does both; check the wrapper
    rng = np.random.default_rng(7)
    by = {}
    for s in SITES:
        rr = []
        for k in range(30):
            qq = rng.uniform(0, 0.5)
            for j in range(20):
                f = [230.0, 910.0][j % 2]
                rr.append({"path_id": f"{s}{k:02d}", "q": qq, "stratum": f"{f:g}|0",
                           "e_707": -20 * qq + rng.normal(0, 2)})
        by[s] = rr
    assert decide_q(by, "e_707", SEED)["outcome"] == "C-"
    for s in SITES:
        for r in by[s]:
            r["e_707"] = rng.normal(0, 2)
    assert decide_q(by, "e_707", SEED)["outcome"] == "none"
    # share interval against an independent loop
    rows = [{"path_id": f"p{k:02d}", "sec": [(k % 6, 1.0 + k), (12, 0.5)]} for k in range(29)]
    s = share_interval(rows, 3, SEED)
    paths = sorted({r["path_id"] for r in rows})
    d = np.random.default_rng(SEED).integers(0, 29, size=(NDRAW, 29))
    est = []
    for row in d:
        num = den = 0.0
        for j in row:
            for r in rows:
                if r["path_id"] == paths[j]:
                    for sep, v in r["sec"]:
                        den += v; num += v if sep <= 3 else 0.0
        est.append(num / den)
    lo, hi = np.percentile(est, [2.5, 97.5])
    assert abs(lo - s["lo"]) < 1e-12 and abs(hi - s["hi"]) < 1e-12
    print("selftest PASS")


def main(repo, out_dir):
    a = d39a(repo)
    b, rows = d39b(repo)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "d39a_rev1.json"), "w") as f:
        json.dump(a, f, indent=2)
    with open(os.path.join(out_dir, "d39b_rev1.json"), "w") as f:
        json.dump(b, f, indent=2)
    with open(os.path.join(out_dir, "d39b_rows_rev1.csv"), "w", newline="") as f:
        keys = ["link_id", "path_id", "set", "f_mhz", "obstructed", "q", "e_707", "e_stock"]
        w = csv.DictWriter(f, fieldnames=keys, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: (f"{r[k]:.6g}" if isinstance(r[k], float) else r[k]) for k in keys})
    print(json.dumps({"d39a": a, "d39b": b}, indent=1))


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--selftest":
        selftest(sys.argv[2])
    else:
        main(sys.argv[1], sys.argv[2])
