#!/usr/bin/env python3
"""D02: how big must a score change be to count? (rev 1)

Replicates eval/score_rev1.m (Phase 2 cell RMS, long-term level and shape,
composite, and the screened composite), checks the replica against the
stored metrics, then bootstraps paths with replacement within each Phase 2
site and each long-term fold to get:
  - the sampling spread of each model's composite
  - the spread of a paired difference between two models (the quantity the
    acceptance threshold is about)
Diagnostic only. Run from the repository root.
"""
from pathlib import Path
import json
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
P2_BANDS = ([0, 300, 1000, 3000, 6000, np.inf], ["<0.3", "0.3-1", "1-3", "3-6", "6-10"])
LT_BANDS = ([0, 300, 1000, 3000, np.inf], ["<0.3", "0.3-1", "1-3", "3-10"])
LT_DIST = ([0, 100, 300, np.inf], ["<100", "100-300", ">=300"])
P = ["1", "10", "50", "90", "99"]
N_BOOT = 500


def cell_rms(e, w, cell):
    d = pd.DataFrame({"e2w": w * e**2, "w": w, "c": cell})
    g = d.groupby("c")[["e2w", "w"]].sum()
    return np.sqrt(g.e2w / g.w)


def weights(path_id):
    return 1 / path_id.map(path_id.value_counts())


def p2_cell(D, m):
    u = ~D.censored & D[f"{m}_lb_50"].notna()
    d = D[u]
    band = pd.cut(d.f_mhz, P2_BANDS[0], labels=P2_BANDS[1], right=False).astype(str)
    return cell_rms(d[f"{m}_lb_50"] - d.meas_lb_db, weights(d.path_id).values, (d.set + "|" + band).values).mean()


def lt_scores(L, m):
    band = pd.cut(L.f_mhz, LT_BANDS[0], labels=LT_BANDS[1], right=False).astype(str)
    dist = pd.cut(L.d_km, LT_DIST[0], labels=LT_DIST[1], right=False).astype(str)
    cell = (band + "|" + dist).values
    lvl, shp = [], []
    for p in P:
        e = (L[f"{m}_lb_{p}"] - L[f"meas_lb_{p}"]).values
        k = np.isfinite(e)
        if not k.any():
            continue
        lvl.append(cell_rms(e[k], weights(L.path_id[k]).values, cell[k]).mean())
        if p != "50":
            es = ((L[f"{m}_lb_{p}"] - L[f"{m}_lb_50"]) - (L[f"meas_lb_{p}"] - L["meas_lb_50"])).values
            k2 = k & np.isfinite(es)
            if k2.any():
                shp.append(cell_rms(es[k2], weights(L.path_id[k2]).values, cell[k2]).mean())
    return np.mean(lvl), np.mean(shp)


def composite(D, L, m):
    c = p2_cell(D, m)
    lv, sh = lt_scores(L, m)
    return np.mean([c, lv, sh]), c, lv, sh


def resample(df, group, rng):
    parts = []
    for _, g in df.groupby(group):
        ids = g.path_id.unique()
        pick = rng.choice(ids, size=len(ids), replace=True)
        for j, pid in enumerate(pick):
            parts.append(g[g.path_id == pid].assign(path_id=f"{pid}#{j}"))
    return pd.concat(parts, ignore_index=True)


def main():
    D = pd.read_csv(ROOT / "data/links/phase2_links_rev1.csv")
    L = pd.read_csv(ROOT / "data/links/longterm_links_rev1.csv")
    for t in (D, L):
        if "itm_error" in t:
            t.drop(t.index[t.itm_error.notna() & (t.itm_error.astype(str) != "")], inplace=True)
    L.columns = [c.replace("_0_01", "_0.01") if False else c for c in L.columns]
    screen = set(pd.read_csv(ROOT / "data/links/longterm_screen_rev1.csv").link_id)
    # Recalibrated-ITM predictions (R01), aligned by link
    r1 = ROOT / "experiments/R01-recalibrated-itm"
    c2 = pd.read_csv(r1 / "predictions_phase2.csv")[["link_id", "cal_lb_50"]]
    cl = pd.read_csv(r1 / "predictions_longterm.csv")
    D = D.merge(c2, on="link_id", how="left")
    L = L.merge(cl[["link_id"] + [f"cal_lb_{p}" for p in P]], on="link_id", how="left")

    M = json.loads((ROOT / "experiments/000-baseline/metrics.json").read_text())
    lines = ["Replica check against experiments/000-baseline/metrics.json (composite):"]
    models = {"itm": "baseline", "p452": "p452", "p2001": "p2001"}
    for m, key in models.items():
        got = composite(D, L, m)[0]
        want = M[key]["composite"]
        lines.append(f"  {m:6s} replica {got:.4f}  stored {want:.4f}  diff {got - want:+.1e}")
        if abs(got - want) > 1e-6:
            raise SystemExit("replica does not match score_rev1; stop")
    models["cal"] = "R01"

    Ls = L[~L.link_id.isin(screen)]
    lines.append("")
    lines.append("Point scores (dB): composite | Phase 2 cell | LT level | LT shape | screened composite")
    for m, key in models.items():
        c = composite(D, L, m)
        s = composite(D, Ls, m)[0]
        lines.append(f"  {key:8s} {c[0]:6.2f} | {c[1]:6.2f} | {c[2]:6.2f} | {c[3]:5.2f} | {s:6.2f}")

    rng = np.random.default_rng(1)
    B = {m: [] for m in models}
    for b in range(N_BOOT):
        Db = resample(D, "set", rng)
        Lb = resample(L, "fold", rng)
        for m in models:
            B[m].append(composite(Db, Lb, m)[0])
    B = pd.DataFrame(B)
    B.to_csv(OUT / "bootstrap_composites_rev1.csv", index=False)
    lines.append("")
    lines.append(f"Bootstrap over paths within site / fold, {N_BOOT} draws:")
    for m, key in models.items():
        q = B[m].quantile([0.025, 0.975])
        lines.append(f"  {key:8s} composite SD {B[m].std():.2f} dB; 95 % interval {q.iloc[0]:.2f}-{q.iloc[1]:.2f}")
    lines.append("")
    lines.append("Paired differences (same resampled paths for both models):")
    for a, b in [("cal", "itm"), ("p2001", "itm"), ("p452", "p2001")]:
        d = B[a] - B[b]
        q = d.quantile([0.025, 0.975])
        lines.append(f"  {models[a]} - {models[b]}: mean {d.mean():+.2f}, SD {d.std():.2f} dB, "
                     f"95 % interval {q.iloc[0]:+.2f} to {q.iloc[1]:+.2f}")
    (OUT / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
