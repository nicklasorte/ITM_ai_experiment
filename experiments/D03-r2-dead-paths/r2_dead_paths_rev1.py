#!/usr/bin/env python3
"""D03: what separates R2's no-signal (censored) rows from its measured rows? (rev 1)

Diagnostic only. For every Phase 2 row, computes path geometry from the
frozen 30 m CSV profile on a 4/3 earth (8,495 km effective radius, the
ITU-R P.526-16 default), and compares rows where no signal was received
(censored) with rows that were measured, conditional on what the models
predicted. Writes rows_rev1.csv and summary.txt next to this file.

Geometry per row:
  obs_m       largest terrain height above the antenna-to-antenna ray
  nu_bull     Bullington diffraction parameter of the single equivalent edge
              (ITU-R P.526-16 eq. (49)-(55)); < -0.78 means a clear path
  n_edges     edges with nu > 0 found by Deygout recursion (principal edge,
              then the two sub-paths, to depth 3; ITU-R P.526-11 s4.4.2)
  edge_spread distance between the outermost such edges (km)

Run from the repository root.
"""
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
AE = 8495e3


def nu_row(x, z, a, b, lam):
    """nu of every interior point between indices a and b (P.526-11 eq. 49, 49a)."""
    if b - a < 2:
        return np.array([]), np.array([], dtype=int)
    i = np.arange(a + 1, b)
    da = x[i] - x[a]; db = x[b] - x[i]; dab = x[b] - x[a]
    h = z[i] + da * db / (2 * AE) - (z[a] * db + z[b] * da) / dab
    return h * np.sqrt(2 * dab / (lam * da * db)), i


def deygout_edges(x, z, a, b, lam, depth):
    nu, i = nu_row(x, z, a, b, lam)
    if nu.size == 0 or depth == 0:
        return []
    k = int(np.argmax(nu))
    if nu[k] <= 0:
        return []
    p = int(i[k])
    return deygout_edges(x, z, a, p, lam, depth - 1) + [p] + deygout_edges(x, z, p, b, lam, depth - 1)


def bullington_nu(x, z, lam):
    d = x[-1]; i = np.arange(1, len(x) - 1); di = x[i]
    bulge = di * (d - di) / (2 * AE)
    hts, hrs = z[0], z[-1]
    s_tim = np.max((z[i] + bulge - hts) / di)
    s_tr = (hrs - hts) / d
    if s_tim < s_tr:
        return np.max((z[i] + bulge - (hts * (d - di) + hrs * di) / d) * np.sqrt(2 * d / (lam * di * (d - di))))
    s_rim = np.max((z[i] + bulge - hrs) / (d - di))
    db = (hrs - hts + s_rim * d) / (s_tim + s_rim)
    return (hts + s_tim * db - (hts * (d - db) + hrs * db) / d) * np.sqrt(2 * d / (lam * db * (d - db)))


def main():
    L = pd.read_csv(ROOT / "data/links/phase2_links_rev1.csv")
    I = pd.read_csv(ROOT / "data/profiles/profiles_index_rev1.csv").set_index("path_id")
    P = pd.read_csv(ROOT / "experiments/401-delta-bullington-p452/predictions_phase2.csv")[["link_id", "var_lb_50"]]
    L = L.merge(P.rename(columns={"var_lb_50": "delta_lb_50"}), on="link_id")
    cache = {}
    rows = []
    for r in L.itertuples():
        if r.path_id not in cache:
            cache[r.path_id] = pd.read_csv(ROOT / "data/profiles/phase2" / f"{r.path_id}.csv").h_m.to_numpy()
        g = cache[r.path_id]
        x = np.arange(len(g)) * I.loc[r.path_id, "spacing_m"]
        z = g.copy(); z[0] += r.htx_m; z[-1] += r.hrx_m
        lam = 299.792458 / r.f_mhz
        d = x[-1]; i = np.arange(1, len(x) - 1)
        ray = z[0] + (z[-1] - z[0]) * x[i] / d
        obs = np.max(z[i] + x[i] * (d - x[i]) / (2 * AE) - ray)
        e = deygout_edges(x, z, 0, len(x) - 1, lam, 3)
        rows.append((obs, bullington_nu(x, z, lam), len(e), (x[max(e)] - x[min(e)]) / 1000 if len(e) > 1 else 0.0))
    L[["obs_m", "nu_bull", "n_edges", "edge_spread_km"]] = pd.DataFrame(rows, index=L.index)
    L["dead"] = L.censored == 1
    L.to_csv(OUT / "rows_rev1.csv", index=False,
             columns=["link_id", "path_id", "set", "f_mhz", "d_km", "htx_m", "hrx_m", "censored", "meas_lb_db",
                      "itm_lb_50", "delta_lb_50", "p2001_lb_50", "obs_m", "nu_bull", "n_edges", "edge_spread_km"])

    lines = []
    R = L[L.set == "R2"].copy()
    lines.append(f"R2: {len(R)} rows, {R.dead.sum()} no-signal (censored), {(~R.dead).sum()} measured")
    lines.append("")
    lines.append("Medians, dead vs measured (R2):")
    for c in ["d_km", "f_mhz", "hrx_m", "obs_m", "nu_bull", "n_edges", "edge_spread_km", "itm_lb_50", "delta_lb_50", "p2001_lb_50"]:
        lines.append(f"  {c:15s} dead {R[R.dead][c].median():9.2f}   measured {R[~R.dead][c].median():9.2f}")
    # Conditional on the delta model's predicted loss: does geometry still separate dead from measured?
    R["delta_bin"] = pd.qcut(R.delta_lb_50, 5)
    lines.append("")
    lines.append("Within bins of delta-Bullington predicted loss (R2), share dead by number of Deygout edges:")
    tab = R.groupby(["delta_bin", R.n_edges.clip(upper=4)], observed=True).dead.agg(["mean", "size"]).unstack()
    lines += ["  " + l for l in tab.round(2).to_string().splitlines()]
    lines.append("")
    lines.append("Within the same bins, share dead by frequency band:")
    R["band"] = pd.cut(R.f_mhz, [0, 300, 1000, 3000, 6000, 1e9], labels=["<0.3", "0.3-1", "1-3", "3-6", "6-10"])
    tab2 = R.groupby(["delta_bin", "band"], observed=True).dead.agg(["mean", "size"]).unstack()
    lines += ["  " + l for l in tab2["mean"].round(2).to_string().splitlines()]
    # Same-path comparison: paths with both dead and measured rows
    both = R.groupby("path_id").dead.agg(["any", "all"])
    mixed = both[both["any"] & ~both["all"]].index
    M = R[R.path_id.isin(mixed)]
    lines.append("")
    lines.append(f"Paths with both dead and measured rows: {len(mixed)} of {R.path_id.nunique()} R2 paths")
    lines.append("  On those paths, medians dead vs measured:")
    for c in ["f_mhz", "hrx_m", "htx_m", "delta_lb_50", "itm_lb_50"]:
        lines.append(f"    {c:12s} dead {M[M.dead][c].median():8.1f}   measured {M[~M.dead][c].median():8.1f}")
    lines.append("")
    lines.append("Paths where every row is dead:")
    alld = both[both["all"]].index
    lines.append(f"  {len(alld)} paths; their median obstruction {R[R.path_id.isin(alld)].obs_m.median():.0f} m, "
                 f"edges {R[R.path_id.isin(alld)].n_edges.median():.0f}, distance {R[R.path_id.isin(alld)].d_km.median():.1f} km")
    (OUT / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
