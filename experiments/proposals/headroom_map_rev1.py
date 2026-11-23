"""Headroom map and error attribution for the kept variant (707), training folds only.

Usage, from the repository root:
    python3 experiments/proposals/headroom_map_rev1.py [<tag>]

Reads only stored predictions (experiments/<tag>/predictions_*.csv), the frozen
link tables, the frozen terrain profiles and the frozen long-term screen. No
model is changed, no experiment is run and no lockbox data is touched.

What it does
  1. Classifies every Phase 2 and long-term row by ITM propagation mode,
     number of profile horizons, number of terrain obstacles above the direct
     ray, distance band, frequency band, site and siting. Mode, horizons,
     effective heights and delta_h come from itm_stock_py_rev1, a transcription
     of itm_variant/itm_p2p_core_exp.m at cfg defaults that reproduces the
     stored itm_lb_* columns to 7e-13 dB.
  2. Replicates eval/score_rev1.m in numpy (composite = mean of the Phase 2
     cell-balanced RMS, the long-term level RMS and the long-term shape RMS).
  3. For each class computes three counterfactual composites:
       perfect  the class's errors set to zero
       bias     the class's weight-mean error removed, spread kept
       floor    the class's RMS scaled down to a measurement-noise floor
     each with a paired bootstrap that resamples paths with replacement within
     each Phase 2 site and each long-term fold, the scheme eval/paired_gain_rev1.m
     uses (reimplemented here; draws are not bit-identical to the MATLAB ones).

Writes experiments/proposals/headroom_classes_rev1.csv and prints the tables
used in headroom_map_rev1.md.
"""
import math, os, sys
import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get("ITMEXP_ROOT") or os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import itm_stock_py_rev1 as S

TAG = sys.argv[1] if len(sys.argv) > 1 else "707-cascaded-isolated-clutter-at-r"
NBOOT = 500
SEED = 1
FLOORS = {"floor5": 5.0, "floor3": 3.0, "floor8": 8.0}

P_ALL = [0.01, 0.1, 1, 10, 50, 90, 99, 99.9, 99.99]
P_TAGS = ["0_01", "0_1", "1", "10", "50", "90", "99", "99_9", "99_99"]
P_SCORED = [1, 10, 50, 90, 99]
BAND_EDGES = [0, 300, 1000, 3000, 6000, np.inf]          # eval/settings_rev1.m
BAND_NAMES = ["<0.3", "0.3-1", "1-3", "3-6", "6-10"]
LT_BAND_EDGES = [0, 300, 1000, 3000, np.inf]
LT_BAND_NAMES = ["<0.3", "0.3-1", "1-3", "3-10"]
LT_DIST_EDGES = [0, 100, 300, np.inf]
LT_DIST_NAMES = ["<100", "100-300", ">=300"]
FREQ_EDGES, FREQ_NAMES = BAND_EDGES, ["<0.3 GHz", "0.3-1 GHz", "1-3 GHz", "3-6 GHz", "6-10 GHz"]
DIST_EDGES = [0, 2, 5, 10, 30, 100, 300, np.inf]
DIST_NAMES = ["<2 km", "2-5 km", "5-10 km", "10-30 km", "30-100 km", "100-300 km", ">=300 km"]
A_E_43 = 6371e3 * 4 / 3
C_LIGHT = 299792458.0


def band_of(f, edges, names):
    return pd.cut(f, bins=edges, labels=names, right=True, include_lowest=True).astype(str)


def obstacles(h, step, htx, hrx, f_mhz):
    """Terrain above the straight ray on a 4/3 Earth (the D04 rule): obstructed
    flag, largest Fresnel-Kirchhoff parameter, and the number of separate
    obstacle runs along the profile."""
    n = len(h); d = (n - 1) * step
    zt, zr = h[0] + htx, h[-1] + hrx
    lam = C_LIGHT / (f_mhz * 1e6)
    x = np.arange(1, n - 1) * step
    hh = h[1:n - 1] + x * (d - x) / (2 * A_E_43) - (zt + (zr - zt) * x / d)
    nu = hh * np.sqrt(2 * d / (lam * x * (d - x)))
    above = hh > 0
    runs = int(np.sum(above[1:] & ~above[:-1]) + (1 if above.size and above[0] else 0))
    return bool(above.any()), float(nu.max()), runs


def load():
    L = pd.read_csv(os.path.join(ROOT, "data/links/phase2_links_rev1.csv"))
    LT = pd.read_csv(os.path.join(ROOT, "data/links/longterm_links_rev1.csv"))
    P = pd.read_csv(os.path.join(ROOT, "experiments", TAG, "predictions_phase2.csv"))
    PL = pd.read_csv(os.path.join(ROOT, "experiments", TAG, "predictions_longterm.csv"))
    idx = pd.read_csv(os.path.join(ROOT, "data/profiles/profiles_index_rev1.csv")).set_index("path_id")
    cache = {}

    def prof(pid):
        if pid not in cache:
            r = idx.loc[pid]
            h = np.loadtxt(os.path.join(ROOT, "data/profiles", r.dataset, pid + ".csv"), skiprows=1)
            cache[pid] = (h.astype(float), float(r.spacing_m))
        return cache[pid]
    return L, LT, P, PL, prof


def classify(T, prof, percentages, stored_prefix):
    """Run the transcribed stock core on every row; check it against the stored
    baseline columns; return the geometry table."""
    rows, worst = [], 0.0
    for r in T.itertuples(index=False):
        h, sp = prof(r.path_id)
        o = S.run_row(h, sp, r.htx_m, r.hrx_m, r.f_mhz, int(r.climate), r.N_0, int(r.pol), percentages)
        stored = np.array([getattr(r, stored_prefix + t) for t in (["50"] if len(percentages) == 1 else P_TAGS)], float)
        worst = max(worst, float(np.nanmax(np.abs(np.asarray(o["lb"]) - stored))))
        obs, nu, nobs = obstacles(h, sp, r.htx_m, r.hrx_m, r.f_mhz)
        rows.append((r.link_id, o["propmode"], o["mode_code"], o["delta_h"], obs, nu, nobs, o["d_sML"]))
    G = pd.DataFrame(rows, columns=["link_id", "propmode", "mode_code", "delta_h", "obstructed",
                                    "nu_max", "n_obstacles", "d_sML"])
    G["n_horizons"] = np.where(G.mode_code == 0, 0, np.where(G.mode_code.isin([5, 6]), 1, 2))
    return G, worst


# ---------------- scoring (replica of eval/score_rev1.m) ----------------
def _codes(x):
    u, c = np.unique(np.asarray(x), return_inverse=True)
    return c, u


class Part:
    def __init__(self, e, path, cell, grp, src, rid):
        self.e = np.asarray(e, float)
        self.pc, self.pu = _codes(path)
        self.cc, self.cu = _codes(cell)
        self.gc, self.gu = _codes(grp)
        self.w = 1.0 / np.bincount(self.pc)[self.pc]
        self.ncell, self.npath = len(self.cu), len(self.pu)
        self.pg = np.zeros(self.npath, int); self.pg[self.pc] = self.gc
        self.src, self.rid = src, np.asarray(rid)

    def mean_cell_rms(self, e, mult):
        w = self.w * mult[self.pc]
        den = np.bincount(self.cc, weights=w, minlength=self.ncell)
        num = np.bincount(self.cc, weights=w * e * e, minlength=self.ncell)
        ok = den > 0
        return float(np.sqrt(num[ok] / den[ok]).mean())


def build_parts(P2, LTt, screen=None):
    use = ((P2.censored == 0) & np.isfinite(P2.var_lb_50)).values
    d = P2[use]
    parts = {"p2": [Part(d.var_lb_50 - d.meas_lb_db, d.path_id, d["set"] + "|" + d.band,
                         d["set"], "p2", np.flatnonzero(use))]}
    T = LTt[~LTt.link_id.isin(screen)] if screen is not None else LTt
    rid = T.index.values
    lev, shp = [], []
    for p, t in zip(P_SCORED, ["1", "10", "50", "90", "99"]):
        pr, me = T["var_lb_" + t].values, T["meas_lb_" + t].values
        k = np.isfinite(pr) & np.isfinite(me)
        lev.append(Part(pr[k] - me[k], T.path_id.values[k], T.cellname.values[k], T.fold.values[k], "lt", rid[k]))
        if p != 50:
            pr0, me0 = T["var_lb_50"].values, T["meas_lb_50"].values
            k2 = k & np.isfinite(pr0) & np.isfinite(me0)
            shp.append(Part((pr[k2] - pr0[k2]) - (me[k2] - me0[k2]), T.path_id.values[k2],
                            T.cellname.values[k2], T.fold.values[k2], "lt", rid[k2]))
    parts["lev"], parts["shp"] = lev, shp
    return parts


def composite(parts, mods=None, mult=None):
    out = []
    for key in ("p2", "lev", "shp"):
        vals = []
        for i, pt in enumerate(parts[key]):
            e = pt.e if mods is None else mods[key][i]
            m = np.ones(pt.npath) if mult is None else mult[key][i]
            vals.append(pt.mean_cell_rms(e, m))
        out.append(float(np.mean(vals)))
    return float(np.mean(out)), out


def part_mask(pt, mp2, mlt):
    return (mp2 if pt.src == "p2" else mlt)[pt.rid]


def wstats(pt, m, mult):
    w = pt.w * mult[pt.pc]
    if m.sum() == 0 or w[m].sum() == 0:
        return np.nan, np.nan
    e, ww = pt.e[m], w[m]
    return float((ww * e).sum() / ww.sum()), float(np.sqrt((ww * e * e).sum() / ww.sum()))


def counterfactual(parts, mp2, mlt, kind, floor=None, mult=None):
    mods = {}
    for key in ("p2", "lev", "shp"):
        lst = []
        for i, pt in enumerate(parts[key]):
            e = pt.e.copy(); m = part_mask(pt, mp2, mlt)
            if m.any():
                mu = np.ones(pt.npath) if mult is None else mult[key][i]
                if kind == "perfect":
                    e[m] = 0.0
                elif kind == "bias":
                    mn, _ = wstats(pt, m, mu)
                    if np.isfinite(mn):
                        e[m] = e[m] - mn
                elif kind == "floor":
                    _, rr = wstats(pt, m, mu)
                    if np.isfinite(rr) and rr > floor:
                        e[m] = e[m] * (floor / rr)
            lst.append(e)
        mods[key] = lst
    return mods


def make_mult(parts, rng):
    """Paths resampled with replacement within each Phase 2 site and each
    long-term fold (eval/paired_gain_rev1.m)."""
    cnt = {}
    for src, keys in (("p2", ["p2"]), ("lt", ["lev", "shp"])):
        names, grps = [], []
        for k in keys:
            for pt in parts[k]:
                names.append(pt.pu); grps.append(pt.gu[pt.pg])
        allnames, allgrp = np.concatenate(names), np.concatenate(grps)
        u, ix = np.unique(allnames, return_index=True)
        g = allgrp[ix]; d = {}
        for gv in np.unique(g):
            ids = u[g == gv]
            c = np.bincount(rng.integers(0, len(ids), len(ids)), minlength=len(ids))
            d.update(dict(zip(ids, c)))
        cnt[src] = d
    return {key: [np.array([cnt[pt.src].get(n, 0) for n in pt.pu], float) for pt in parts[key]]
            for key in ("p2", "lev", "shp")}


def main():
    L, LT, P, PL, prof = load()
    G2, w2 = classify(L, prof, [50.0], "itm_lb_")
    GL, wl = classify(LT, prof, P_ALL, "itm_lb_")
    print("transcribed stock core vs stored baseline: Phase 2 %.1e dB, long-term %.1e dB" % (w2, wl))

    P2 = L.merge(P[["link_id", "var_lb_50"]], on="link_id").merge(G2, on="link_id")
    LTt = LT.merge(PL[["link_id"] + ["var_lb_" + t for t in P_TAGS]], on="link_id").merge(GL, on="link_id")
    P2["band"] = band_of(P2.f_mhz, BAND_EDGES, BAND_NAMES)
    LTt["cellname"] = (band_of(LTt.f_mhz, LT_BAND_EDGES, LT_BAND_NAMES) + "|"
                       + band_of(LTt.d_km, LT_DIST_EDGES, LT_DIST_NAMES))
    MODE = {1: "line of sight", 2: "diffraction", 3: "troposcatter"}
    for T in (P2, LTt):
        T["mode"] = T.propmode.map(MODE)
        T["hor_bin"] = T.n_horizons.map({0: "0 horizons", 1: "1 horizon", 2: "2 horizons"})
        T["obs_bin"] = T.n_obstacles.map(lambda n: "0" if n == 0 else "1" if n == 1 else "2" if n == 2 else "3" if n == 3 else "4+")
        T["freq_cls"] = band_of(T.f_mhz, FREQ_EDGES, FREQ_NAMES)
        T["dist_cls"] = band_of(T.d_km, DIST_EDGES, DIST_NAMES)
    P2["site"] = P2["set"]; LTt["site"] = "(long-term)"
    P2["siting_lbl"] = P2.siting.map({"O": "open", "C": "concealed", "A": "undocumented"})
    LTt["siting_lbl"] = "(long-term)"

    screen = set(pd.read_csv(os.path.join(ROOT, "data/links/longterm_screen_rev1.csv")).link_id)
    PF, PFS = build_parts(P2, LTt), build_parts(P2, LTt, screen)
    base, base_parts = composite(PF); base_s, _ = composite(PFS)
    print("composite %.3f (parts: Phase 2 cell %.3f, long-term level %.3f, shape %.3f); screened %.3f on %d links"
          % (base, base_parts[0], base_parts[1], base_parts[2], base_s, len(screen)))

    dims = [("site", "Site"), ("siting_lbl", "Siting"), ("mode", "ITM mode"), ("hor_bin", "Profile horizons"),
            ("obs_bin", "Profile obstacles"), ("dist_cls", "Distance"), ("freq_cls", "Frequency")]
    classes = []
    for col, label in dims:
        for v in sorted(set(P2[col].astype(str)) | set(LTt[col].astype(str))):
            classes.append((label, v, (P2[col].astype(str) == v).values, (LTt[col].astype(str) == v).values))
    for s in ["R1", "R2", "R3", "VA"]:
        for m in ["line of sight", "diffraction", "troposcatter"]:
            classes.append(("Site x mode", f"{s} / {m}",
                            ((P2.site == s) & (P2["mode"] == m)).values, np.zeros(len(LTt), bool)))
    for name, mp2, mlt in [
            ("VA open, terrain-clear", ((P2.site == "VA") & (P2.siting == "O") & (~P2.obstructed)).values, np.zeros(len(LTt), bool)),
            ("R1+R3 terrain-obstructed", (P2.site.isin(["R1", "R3"]) & P2.obstructed).values, np.zeros(len(LTt), bool)),
            ("all terrain-clear (Phase 2)", (~P2.obstructed).values, np.zeros(len(LTt), bool)),
            ("all terrain-obstructed (Phase 2)", P2.obstructed.values, np.zeros(len(LTt), bool)),
            ("above 3 GHz (Phase 2)", (P2.f_mhz > 3000).values, np.zeros(len(LTt), bool)),
            ("long-term beyond 100 km", np.zeros(len(P2), bool), (LTt.d_km >= 100).values)]:
        classes.append(("Target", name, mp2, mlt))

    p2p, lev50 = PF["p2"][0], PF["lev"][2]
    one2, one5 = np.ones(p2p.npath), np.ones(lev50.npath)
    recs = []
    for label, v, mp2, mlt in classes:
        m2, m5 = part_mask(p2p, mp2, mlt), part_mask(lev50, mp2, mlt)
        mean2, rms2 = wstats(p2p, m2, one2)
        mean5, rms5 = wstats(lev50, m5, one5)
        cm = (P2.censored == 1).values & mp2
        viol = float(np.mean(P2.var_lb_50.values[cm] < P2.meas_lb_db.values[cm]) * 100) if cm.sum() else np.nan
        r = dict(dim=label, cls=v, n_p2=int(m2.sum()), n_lt=int(m5.sum()),
                 wshare_p2=float((p2p.w * m2).sum() / p2p.w.sum()),
                 wshare_lt=float((lev50.w * m5).sum() / lev50.w.sum()),
                 mean_p2=mean2, rms_p2=rms2, mean_lt=mean5, rms_lt=rms5,
                 n_censored=int(cm.sum()), cens_viol_pct=viol)
        for kind, fl in [("perfect", None), ("bias", None)] + [(k, f) for k, f in FLOORS.items()]:
            k = "floor" if kind.startswith("floor") else kind
            r[kind] = base - composite(PF, mods=counterfactual(PF, mp2, mlt, k, floor=fl))[0]
            r[kind + "_scr"] = base_s - composite(PFS, mods=counterfactual(PFS, mp2, mlt, k, floor=fl))[0]
        _, pp = composite(PF, mods=counterfactual(PF, mp2, mlt, "perfect"))
        r["d_p2"], r["d_lev"], r["d_shp"] = (base_parts[0] - pp[0], base_parts[1] - pp[1], base_parts[2] - pp[2])
        recs.append(r)

    rng = np.random.default_rng(SEED)
    kinds = ["perfect", "bias"] + list(FLOORS)
    boot = {k: np.zeros((NBOOT, len(classes))) for k in kinds}
    for b in range(NBOOT):
        mu = make_mult(PF, rng)
        b0 = composite(PF, mult=mu)[0]
        for j, (_, _, mp2, mlt) in enumerate(classes):
            for kind in kinds:
                k = "floor" if kind.startswith("floor") else kind
                fl = FLOORS.get(kind)
                boot[kind][b, j] = b0 - composite(PF, mods=counterfactual(PF, mp2, mlt, k, floor=fl, mult=mu), mult=mu)[0]
    H = pd.DataFrame(recs)
    for k in kinds:
        H[k + "_lo"] = np.percentile(boot[k], 2.5, axis=0)
        H[k + "_hi"] = np.percentile(boot[k], 97.5, axis=0)
    out = os.path.join(HERE, "headroom_classes_rev1.csv")
    H.round(4).to_csv(out, index=False)
    with pd.option_context("display.width", 250, "display.max_rows", 200):
        print(H[["dim", "cls", "n_p2", "n_lt", "wshare_p2", "mean_p2", "rms_p2", "mean_lt", "rms_lt",
                 "n_censored", "cens_viol_pct", "perfect", "perfect_lo", "bias", "bias_lo", "floor5",
                 "d_p2", "d_lev", "d_shp"]].round(2).to_string(index=False))
    print("written:", out)


if __name__ == "__main__":
    main()
