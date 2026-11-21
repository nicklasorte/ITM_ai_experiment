#!/usr/bin/env python3
"""D01: where does the long-term level error come from? (rev 1)

Reads the frozen long-term links and CSV terrain profiles, replicates
eval/score_rev1.m's long-term level metric exactly (cells = band x distance,
path weights, mean over p = 1, 10, 50, 90, 99), and breaks the error down.
Writes breakdown CSVs next to this file. Diagnostic only: it changes no
data, splits, or scores.

Run from the repository root:  python3 experiments/D01-longterm-level/diagnose_lt_level_rev1.py
"""
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
P_SCORED = ["1", "10", "50", "90", "99"]
BAND = ([0, 300, 1000, 3000, np.inf], ["<0.3", "0.3-1", "1-3", "3-10"])
DIST = ([0, 100, 300, np.inf], ["<100", "100-300", ">=300"])
K43 = 6371e3 * 4 / 3                  # 4/3-earth radius, standard refractivity


def cells(df):
    b = pd.cut(df.f_mhz, BAND[0], labels=BAND[1], right=False).astype(str)
    d = pd.cut(df.d_km, DIST[0], labels=DIST[1], right=False).astype(str)
    return b + "|" + d


def level(df, model):
    """Long-term level RMS exactly as score_rev1: mean over p of mean cell RMS."""
    out = []
    for p in P_SCORED:
        e = df[f"{model}_lb_{p.replace('.', '_')}"] - df[f"meas_lb_{p}"]
        k = e.notna()
        if not k.any():
            continue
        sub = df[k].assign(e=e[k])
        sub["w"] = 1 / sub.groupby("path_id").path_id.transform("size")
        sub["cell"] = cells(sub)
        r = sub.groupby("cell").apply(lambda g: np.sqrt((g.w * g.e**2).sum() / g.w.sum()), include_groups=False)
        out.append(r.mean())
    return float(np.mean(out))


def clearance(pid, ht, hr, spacing):
    """Largest terrain obstruction above the terminal-to-terminal ray, 4/3 earth (m)."""
    h = pd.read_csv(ROOT / "data/profiles/longterm" / f"{pid}.csv").h_m.to_numpy()
    x = np.arange(len(h)) * spacing
    D = x[-1]
    zt, zr = h[0] + ht, h[-1] + hr
    obs = h + x * (D - x) / (2 * K43) - (zt + (zr - zt) * x / D)
    return obs[1:-1].max()


def main():
    L = pd.read_csv(ROOT / "data/links/longterm_links_rev1.csv")
    I = pd.read_csv(ROOT / "data/profiles/profiles_index_rev1.csv").set_index("path_id")
    L["obs_m"] = [clearance(r.path_id, r.htx_m, r.hrx_m, I.loc[r.path_id, "spacing_m"]) for r in L.itertuples()]
    L["record_los"] = L.path_type.eq("LOS")
    L["profile_blocked"] = L.obs_m > 0
    L["conus"] = (L.tx_lat.between(24, 50) & L.rx_lat.between(24, 50)
                  & L.tx_lon.between(-125, -66) & L.rx_lon.between(-125, -66))
    L["country"] = L.rx_name.str.split().str[-1].fillna("?")
    L["e50_itm"] = L.itm_lb_50 - L.meas_lb_50
    L["e50_p2001"] = L.p2001_lb_50 - L.meas_lb_50
    L["cell"] = cells(L)

    lines = []
    full = {m: level(L, m) for m in ["itm", "p452", "p2001"]}
    lines.append("Long-term level RMS, replicated from score_rev1 (dB):")
    for m, v in full.items():
        lines.append(f"  {m:6s} all 548 rows on 325 paths: {v:5.2f}")

    mism = L.record_los & L.profile_blocked
    lines.append("")
    lines.append(f"Record says line of sight, 30 m profile is blocked: {mism.sum()} rows on "
                 f"{L[mism].path_id.nunique()} paths (obstruction {L[mism].obs_m.min():.1f}"
                 f"-{L[mism].obs_m.max():.0f} m)")
    for name, k in [("record LOS, profile clear", L.record_los & ~L.profile_blocked),
                    ("record LOS, profile blocked", mism),
                    ("record not LOS", ~L.record_los)]:
        s = L[k]
        lines.append(f"  {name:28s} rows {len(s):3d}  ITM p50 mean {s.e50_itm.mean():+6.1f}  "
                     f"RMS {np.sqrt((s.e50_itm**2).mean()):5.1f}   P.2001 RMS {np.sqrt((s.e50_p2001**2).mean()):5.1f}")
    lines.append("")
    lines.append("Level RMS without the mismatched rows (sensitivity only; the set is unchanged):")
    for m in ["itm", "p452", "p2001"]:
        lines.append(f"  {m:6s} {level(L[~mism], m):5.2f}   (all rows {full[m]:5.2f})")

    lines.append("")
    lines.append("By region (p50, path-weighted):")
    L["w"] = 1 / L.groupby("path_id").path_id.transform("size")
    def wrms(g, col):
        return np.sqrt((g.w * g[col] ** 2).sum() / g.w.sum())
    reg = (L.assign(region=np.where(L.conus, "CONUS", L.country))
             .groupby("region")
             .apply(lambda g: pd.Series({"rows": len(g), "paths": g.path_id.nunique(),
                                         "itm_mean": (g.w * g.e50_itm).sum() / g.w.sum(),
                                         "itm_rms": wrms(g, "e50_itm"), "p2001_rms": wrms(g, "e50_p2001"),
                                         "mismatch_rows": int((g.record_los & g.profile_blocked).sum())}),
                    include_groups=False)
             .sort_values("rows", ascending=False))
    reg.to_csv(OUT / "by_region_rev1.csv")
    lines += ["  " + l for l in reg.round(1).to_string().splitlines()]

    lines.append("")
    lines.append("By cell (band | distance), p50:")
    cel = (L.groupby("cell")
             .apply(lambda g: pd.Series({"rows": len(g), "itm_mean": (g.w * g.e50_itm).sum() / g.w.sum(),
                                         "itm_rms": wrms(g, "e50_itm"), "p2001_rms": wrms(g, "e50_p2001"),
                                         "mismatch_rows": int((g.record_los & g.profile_blocked).sum())}),
                    include_groups=False))
    cel.to_csv(OUT / "by_cell_rev1.csv")
    lines += ["  " + l for l in cel.round(1).to_string().splitlines()]

    lines.append("")
    lines.append("Largest ITM p50 errors where P.2001 is within 25 dB of the measurement (ITM-specific misses):")
    spec = L[(L.e50_p2001.abs() < 25)].reindex(L.e50_itm.abs().sort_values(ascending=False).index).dropna(subset=["e50_p2001"])
    spec = spec[spec.e50_p2001.abs() < 25].head(10)
    for r in spec.itertuples():
        lines.append(f"  {r.link_id}  {r.d_km:6.1f} km {r.f_mhz:7.1f} MHz  htx {r.htx_m:5.1f} hrx {r.hrx_m:5.1f}  "
                     f"ITM {r.e50_itm:+6.1f}  P.2001 {r.e50_p2001:+6.1f}  obstruction {r.obs_m:7.1f} m  record LOS {r.record_los}")

    L[["link_id", "path_id", "d_km", "f_mhz", "htx_m", "hrx_m", "path_type", "obs_m", "record_los",
       "profile_blocked", "conus", "country", "cell", "meas_lb_50", "itm_lb_50", "p2001_lb_50",
       "e50_itm", "e50_p2001"]].to_csv(OUT / "rows_rev1.csv", index=False)
    (OUT / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
