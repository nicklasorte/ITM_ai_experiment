"""B30 (D30): do 707's errors track vegetation height above the antennas? Diagnostic only.

Implements B30.md section 3 exactly.

Usage:
  python3 -I experiments/batches/d30_analysis_rev1.py --selftest
  python3 -I experiments/batches/d30_analysis_rev1.py --run

--run reads experiments/D30-landfire-evh/phase2_profiles_evh_rev1.csv
(hash-checked), data/profiles/profiles_index_rev1.csv,
data/links/phase2_links_rev1.csv and
experiments/707r-rescore-screen36/predictions_phase2.csv, and writes
slopes_rev1.csv, path_heights_rev1.csv, decision_rev1.json and summary.txt
in experiments/D30-landfire-evh/. It refuses to overwrite decision_rev1.json.
"""
import hashlib
import json
import os
import sys

import numpy as np
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "experiments", "D30-landfire-evh")
NEAR_M = 300.0          # B30.md section 3
N_BOOT = 2000
SEED = 1
MIN_PATHS = 10          # paths with E > 0 for a site to count
RMS_GAIN_DB = 0.5       # outcome A threshold (planner-chosen)
SITES = ["R1", "R2", "R3", "VA"]


def stop(msg):
    print("B30 STOP: " + msg)
    sys.exit(1)


def evh_height_m(code):
    """LF2016 Remap EVH code -> vegetation height (m); other codes -> 0."""
    c = np.asarray(code, dtype=float)
    h = np.zeros_like(c)
    t = (c >= 101) & (c <= 199)
    s = (c >= 201) & (c <= 230)
    g = (c >= 301) & (c <= 310)
    h[t] = c[t] - 100
    h[s] = (c[s] - 200) / 10
    h[g] = (c[g] - 300) / 10
    return h


def path_heights(evh, idx):
    """Mean vegetation height within NEAR_M of each end, and along-path tree fraction."""
    rows = []
    for pid, q in evh.groupby("path_id", sort=False):
        n = int(idx.loc[pid, "n_points"])
        dx = float(idx.loc[pid, "spacing_m"])
        codes = np.repeat(q.evh_code.to_numpy(), (q.i_last - q.i_first + 1).to_numpy())
        if len(codes) != n:
            stop("%s: %d samples, expected %d" % (pid, len(codes), n))
        h = evh_height_m(codes)
        dist = np.arange(n) * dx
        near_tx = dist <= NEAR_M
        near_rx = dist >= dist[-1] - NEAR_M
        rows.append({"path_id": pid, "H_tx": h[near_tx].mean(), "H_rx": h[near_rx].mean(),
                     "tree_frac": float(np.mean(h >= 5)), "n_samples": n})
    return pd.DataFrame(rows)


def slope(x, y):
    xc = x - x.mean()
    d = float(np.dot(xc, xc))
    return np.nan if d == 0 else float(np.dot(xc, y - y.mean()) / d)


def boot_slope(df, xcol, rng):
    paths = df.path_id.unique()
    g = {p: df.index[df.path_id == p].to_numpy() for p in paths}
    out = np.empty(N_BOOT)
    for b in range(N_BOOT):
        pick = rng.choice(paths, size=len(paths), replace=True)
        ii = np.concatenate([g[p] for p in pick])
        out[b] = slope(df.loc[ii, xcol].to_numpy(), df.loc[ii, "err"].to_numpy())
    return np.nanpercentile(out, [2.5, 97.5])


def analyse(rows, xcol="E"):
    """rows: path_id, set, err, E (and others). Returns per-site table and decision."""
    rng = np.random.default_rng(SEED)
    res = []
    fitted = rows.err.copy()
    for s in SITES:
        d = rows[rows.set == s].reset_index(drop=True)
        n_pos_paths = d.loc[d[xcol] > 0, "path_id"].nunique()
        counted = n_pos_paths >= MIN_PATHS
        b = slope(d[xcol].to_numpy(), d.err.to_numpy()) if len(d) else np.nan
        lo, hi = boot_slope(d, xcol, rng) if counted else (np.nan, np.nan)
        neg = counted and hi < 0
        if counted and np.isfinite(b):
            a = d.err.mean() - b * d[xcol].mean()
            m = rows.set == s
            fitted[m] = rows.loc[m, "err"] - (a + b * rows.loc[m, xcol])
            # subtract the fitted line, keep the site mean: only the slope part is credited
            fitted[m] = fitted[m] + rows.loc[m, "err"].mean()
        res.append({"site": s, "rows": len(d), "paths": d.path_id.nunique(),
                    "paths_E_pos": int(n_pos_paths), "counted": counted,
                    "slope_db_per_m": b, "ci_lo": lo, "ci_hi": hi, "negative_excludes_zero": bool(neg)})
    rms0 = float(np.sqrt(np.mean(rows.err ** 2)))
    rms1 = float(np.sqrt(np.mean(fitted ** 2)))
    tab = pd.DataFrame(res)
    n_neg = int(tab.negative_excludes_zero.sum())
    outcome = "A" if (n_neg >= 2 and rms0 - rms1 >= RMS_GAIN_DB) else "B"
    return tab, {"outcome": outcome, "n_sites_negative": n_neg, "rms_before_db": rms0,
                 "rms_after_db": rms1, "rms_gain_db_in_sample": rms0 - rms1}


def synth(slope_va, slope_r2, n_paths=40, seed=3):
    rng = np.random.default_rng(seed)
    rows = []
    for s, b in [("R1", 0.0), ("R2", slope_r2), ("R3", 0.0), ("VA", slope_va)]:
        for p in range(n_paths):
            e_path = rng.uniform(0, 15) if s in ("R2", "VA") or p < 12 else 0.0
            u = rng.normal(0, 3)
            for _ in range(10):
                E = max(0.0, e_path + rng.normal(0, 1))
                rows.append({"path_id": "%s-%d" % (s, p), "set": s, "E": E, "err": b * E + u + rng.normal(0, 4)})
    return pd.DataFrame(rows)


def selftest():
    ok = True
    tab, d = analyse(synth(-1.5, -1.2))   # strong enough to clear the 0.5 dB RMS rule
    print("strong signal:", d["outcome"], d["n_sites_negative"], round(d["rms_gain_db_in_sample"], 2))
    ok &= d["outcome"] == "A" and abs(tab.set_index("site").loc["VA", "slope_db_per_m"] + 1.5) < 0.2
    tab, d = analyse(synth(0.0, 0.0))
    print("no signal:", d["outcome"], d["n_sites_negative"], round(d["rms_gain_db_in_sample"], 2))
    ok &= d["outcome"] == "B"
    tab, d = analyse(synth(-0.8, 0.0))
    print("one site:", d["outcome"], d["n_sites_negative"])
    ok &= d["outcome"] == "B" and d["n_sites_negative"] == 1
    h = evh_height_m([11, 100, 101, 150, 199, 201, 230, 301, 310, -9999])
    ok &= np.allclose(h, [0, 0, 1, 50, 99, 0.1, 3.0, 0.1, 1.0, 0])
    print("selftest", "PASS" if ok else "FAIL")
    return ok


def run():
    f = os.path.join(OUT, "phase2_profiles_evh_rev1.csv")
    if os.path.exists(os.path.join(OUT, "decision_rev1.json")):
        stop("decision_rev1.json exists; B30 runs once")
    want = open(os.path.join(OUT, "phase2_profiles_evh_rev1.sha256")).read().strip()
    if hashlib.sha256(open(f, "rb").read()).hexdigest() != want:
        stop("EVH file hash mismatch")
    evh = pd.read_csv(f)
    idx = pd.read_csv(os.path.join(ROOT, "data/profiles/profiles_index_rev1.csv")).set_index("path_id")
    ph = path_heights(evh, idx)
    if len(ph) != (idx.dataset == "phase2").sum():
        stop("EVH covers %d paths, expected %d" % (len(ph), (idx.dataset == "phase2").sum()))
    L = pd.read_csv(os.path.join(ROOT, "data/links/phase2_links_rev1.csv"))
    P = pd.read_csv(os.path.join(ROOT, "experiments/707r-rescore-screen36/predictions_phase2.csv"))
    D = L.merge(P[["link_id", "var_lb_50"]], on="link_id", how="inner", validate="one_to_one")
    if len(D) != len(L):
        stop("prediction join lost rows")
    D = D.merge(ph, on="path_id", how="left", validate="many_to_one")
    D = D[(D.censored == 0) & np.isfinite(D.var_lb_50)].copy()
    D["err"] = D.var_lb_50 - D.meas_lb_db
    D["E"] = np.maximum(0, D.H_tx - D.htx_m) + np.maximum(0, D.H_rx - D.hrx_m)
    out = {}
    lines = ["B30 (D30) vegetation height near the terminals vs 707 signed error (pred - meas, dB)", ""]
    for label, sub, xcol, deciding in [("O rows, excess E (deciding)", D[D.siting == "O"], "E", True),
                                       ("C rows, excess E (exploratory)", D[D.siting == "C"], "E", False),
                                       ("O rows, along-path tree fraction (exploratory)", D[D.siting == "O"], "tree_frac", False)]:
        tab, dec = analyse(sub.reset_index(drop=True), xcol)
        tab.insert(0, "population", label)
        out[label] = (tab, dec)
        lines.append(label)
        lines.append("  population: uncensored Phase 2 rows, %d rows on %d paths" % (len(sub), sub.path_id.nunique()))
        for _, r in tab.iterrows():
            lines.append("  %s: %d rows, %d paths (%d with %s > 0)%s slope %+.3f dB per unit [%+.3f, %+.3f]%s" % (
                r.site, r.rows, r.paths, r.paths_E_pos, xcol, "" if r.counted else " DESCRIPTIVE",
                r.slope_db_per_m, r.ci_lo, r.ci_hi, " NEGATIVE" if r.negative_excludes_zero else ""))
        lines.append("  RMS %.2f -> %.2f dB after per-site lines (in sample, optimistic); outcome rule %s" % (
            dec["rms_before_db"], dec["rms_after_db"], dec["outcome"]))
        lines.append("")
    dec = out["O rows, excess E (deciding)"][1]
    lines.append("OUTCOME %s (decided on uncensored siting-O rows, excess E)" % dec["outcome"])
    pd.concat([t for t, _ in out.values()]).to_csv(os.path.join(OUT, "slopes_rev1.csv"), index=False)
    ph.to_csv(os.path.join(OUT, "path_heights_rev1.csv"), index=False)
    json.dump({"deciding": dec, "exploratory": {k: v[1] for k, v in out.items() if "exploratory" in k}},
              open(os.path.join(OUT, "decision_rev1.json"), "w"), indent=1)
    open(os.path.join(OUT, "summary.txt"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        sys.exit(0 if selftest() else 1)
    elif sys.argv[1:] == ["--run"]:
        run()
    else:
        stop("usage: --selftest | --run")
