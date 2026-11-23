#!/usr/bin/env python3
"""History-matching pre-run screen for the ITM ratchet (planner tool).

Adapted from history matching in climate-model tuning (Craig et al. 1997;
Williamson et al. 2013, 2015): before spending a run, rule out candidates
whose best case can't pass the acceptance gates, using a cheap emulator
with a stated uncertainty, instead of hunting for the single best input.

The emulator here is exact algebra on the parent's per-cell residuals.
For one cell with path weights w (sum W), parent error e and a candidate
change d (candidate prediction minus parent prediction, from a model-only
smoke test), the candidate's weighted mean-square error is

    MSE' = MSE + 2 (m * dbar + c) + q

where m is the parent's weighted mean error, dbar and q are the weighted
mean and mean square of d, and c is the weighted covariance of e and d.
c is the only unknown a smoke test can't give. Cauchy-Schwarz bounds it:
|c| <= s_e * s_d. So each cell's RMS lies in a known interval, and so do
the composite, the screened composite and each site RMS, which are means
or weighted RMS values of cells and rows (eval/score_rev1.m).

Inputs read: the parent's per-row residual (predictions_*.csv of the
parent run, development data only, never lockbox) reduced to cell
aggregates (W, m, s_e), and the candidate's per-row change d, which needs
no measurement. The screen never sees the candidate's error.

Verdicts (FRAMEWORK.md acceptance rule):
  CANNOT_PASS   the largest possible composite or screened gain is under 0.3 dB
  CERTAIN_HARM  some site's RMS rises by more than 0.5 dB even in the best case
  NOT_RULED_OUT anything else: run it

Floors (model discrepancy, Williamson et al. 2015): with --floor, each
cell's RMS can't fall below the floor in results/model_floor_rev1.csv,
which tightens the best case. See experiments/proposals/history_matching_rev1.md.

Usage:
  # validate against a finished run (actual gain is also printed)
  hm_screen_rev1.py --parent experiments/707-... --cand experiments/711-...
  # screen a model-only smoke test before registering a batch
  hm_screen_rev1.py --parent experiments/707-... --delta experiments/batches/<file>.csv
  # parent = stock ITM columns of any run folder
  hm_screen_rev1.py --parent experiments/000-baseline --parent-col itm --cand ... --cand-col var
"""
import argparse
import csv
import math
import os
import sys
from collections import defaultdict

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# eval/settings_rev1.m (read-only copy of the constants; checked by --selftest)
BAND_EDGES = [0, 300, 1000, 3000, 6000, math.inf]
BAND_NAMES = ["<0.3", "0.3-1", "1-3", "3-6", "6-10"]
LT_BAND_EDGES = [0, 300, 1000, 3000, math.inf]
LT_BAND_NAMES = ["<0.3", "0.3-1", "1-3", "3-10"]
LT_DIST_EDGES = [0, 100, 300, math.inf]
LT_DIST_NAMES = ["<100", "100-300", ">=300"]
P_SCORED = ["1", "10", "50", "90", "99"]
SITES = ["R1", "R2", "R3", "VA"]
GAIN_GATE_DB = 0.3      # FRAMEWORK.md acceptance rule
SITE_GATE_DB = 0.5      # FRAMEWORK.md acceptance rule


def disc(x, edges, names):
    """MATLAB discretize with right-open bins (last bin closed)."""
    for i in range(len(edges) - 1):
        if edges[i] <= x < edges[i + 1] or (i == len(edges) - 2 and x == edges[-1]):
            return names[i]
    raise ValueError(f"value {x} outside bins")


def fnum(s):
    try:
        v = float(s)
    except (TypeError, ValueError):
        return math.nan
    return v


def read_csv(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def path_weights(ids):
    n = defaultdict(int)
    for i in ids:
        n[i] += 1
    return np.array([1.0 / n[i] for i in ids])


def screen_ids():
    rows = read_csv(os.path.join(ROOT, "data", "links", "longterm_screen_rev1.csv"))
    if not rows:
        sys.exit("error: screen list is empty")
    return {r["link_id"] for r in rows}


class Groups:
    """Rows of one score component, grouped into cells, with path weights."""

    def __init__(self, keys, cells, pids, err, delta):
        self.keys, self.cells = keys, np.array(cells)
        self.w = path_weights(pids)
        self.e = np.asarray(err, float)
        self.d = np.asarray(delta, float)

    def cell_stats(self):
        out = {}
        for c in sorted(set(self.cells)):
            k = self.cells == c
            w, e, d = self.w[k], self.e[k], self.d[k]
            W = w.sum()
            m = (w * e).sum() / W
            mse = (w * e * e).sum() / W
            s_e = math.sqrt(max(mse - m * m, 0.0))
            dbar = (w * d).sum() / W
            q = (w * d * d).sum() / W
            s_d = math.sqrt(max(q - dbar * dbar, 0.0))
            c_true = (w * (e - m) * (d - dbar)).sum() / W   # only for validation output
            base = mse + 2 * m * dbar + q
            lo = max(base - 2 * s_e * s_d, 0.0)
            hi = base + 2 * s_e * s_d
            out[c] = dict(W=W, n=int(k.sum()), m=m, rms=math.sqrt(mse), s_e=s_e, dbar=dbar,
                          q=q, s_d=s_d, mid=math.sqrt(max(base, 0.0)),
                          lo=math.sqrt(lo), hi=math.sqrt(hi),
                          actual=math.sqrt(max(base + 2 * c_true, 0.0)))
        return out


def build(parent_dir, pcol, cand_dir=None, ccol="var", delta_csv=None, drop_screen=False):
    """Return dict of component -> list of Groups, plus site Groups."""
    p2 = read_csv(os.path.join(parent_dir, "predictions_phase2.csv"))
    lt = read_csv(os.path.join(parent_dir, "predictions_longterm.csv"))
    if cand_dir:
        c2 = {r["link_id"]: r for r in read_csv(os.path.join(cand_dir, "predictions_phase2.csv"))}
        cl = {r["link_id"]: r for r in read_csv(os.path.join(cand_dir, "predictions_longterm.csv"))}
        get2 = lambda r: fnum(c2[r["link_id"]][f"{ccol}_lb_50"]) - fnum(r[f"{pcol}_lb_50"])
        getl = lambda r, t: fnum(cl[r["link_id"]][f"{ccol}_lb_{t}"]) - fnum(r[f"{pcol}_lb_{t}"])
        missing = [r["link_id"] for r in p2 if r["link_id"] not in c2] + \
                  [r["link_id"] for r in lt if r["link_id"] not in cl]
    else:
        D = {r["link_id"]: r for r in read_csv(delta_csv)}
        get2 = lambda r: fnum(D[r["link_id"]]["d_50"])
        getl = lambda r, t: fnum(D[r["link_id"]][f"d_{t}"])
        missing = [r["link_id"] for r in p2 + lt if r["link_id"] not in D]
    if missing:
        sys.exit(f"error: {len(missing)} parent rows have no candidate change, e.g. {missing[:3]}")

    comps = {}
    # Phase 2: uncensored rows with finite prediction
    rows = [r for r in p2 if r["censored"] in ("0", "false", "False") and math.isfinite(fnum(r[f"{pcol}_lb_50"]))]
    err = [fnum(r[f"{pcol}_lb_50"]) - fnum(r["meas_lb_db"]) for r in rows]
    dl = [get2(r) for r in rows]
    if not all(math.isfinite(x) for x in dl):
        sys.exit("error: non-finite Phase 2 change")
    cells = [r["set"] + "|" + disc(fnum(r["f_mhz"]), BAND_EDGES, BAND_NAMES) for r in rows]
    pids = [r["path_id"] for r in rows]
    comps["p2"] = [Groups(None, cells, pids, err, dl)]
    sites = {s: Groups(None, [s] * sum(1 for r in rows if r["set"] == s),
                       [p for p, r in zip(pids, rows) if r["set"] == s],
                       [e for e, r in zip(err, rows) if r["set"] == s],
                       [x for x, r in zip(dl, rows) if r["set"] == s]) for s in SITES}
    # sites use weights over the site's own rows, as score_rev1 does (path weights from all
    # uncensored rows); recompute to match: weights come from the full uncensored set.
    wfull = path_weights(pids)
    for s in SITES:
        k = np.array([r["set"] == s for r in rows])
        sites[s].w = wfull[k]
    comps["p2"][0].w = wfull

    # Long-term
    if drop_screen:
        drop = screen_ids()
        lt = [r for r in lt if r["link_id"] not in drop]
    cell_of = lambda r: disc(fnum(r["f_mhz"]), LT_BAND_EDGES, LT_BAND_NAMES) + "|" + \
        disc(fnum(r["d_km"]), LT_DIST_EDGES, LT_DIST_NAMES)
    lv, sh = [], []
    for t in P_SCORED:
        k = [r for r in lt if math.isfinite(fnum(r[f"{pcol}_lb_{t}"])) and math.isfinite(fnum(r[f"meas_lb_{t}"]))]
        lv.append(Groups(t, [cell_of(r) for r in k], [r["path_id"] for r in k],
                         [fnum(r[f"{pcol}_lb_{t}"]) - fnum(r[f"meas_lb_{t}"]) for r in k],
                         [getl(r, t) for r in k]))
        if t != "50":
            k2 = [r for r in k if math.isfinite(fnum(r[f"{pcol}_lb_50"])) and math.isfinite(fnum(r["meas_lb_50"]))]
            es = [(fnum(r[f"{pcol}_lb_{t}"]) - fnum(r[f"{pcol}_lb_50"])) - (fnum(r[f"meas_lb_{t}"]) - fnum(r["meas_lb_50"])) for r in k2]
            ds = [getl(r, t) - getl(r, "50") for r in k2]
            sh.append(Groups(t, [cell_of(r) for r in k2], [r["path_id"] for r in k2], es, ds))
    comps["lt_level"], comps["lt_shape"] = lv, sh
    return comps, sites


def load_floor(path):
    if not path:
        return {}
    out = {}
    for r in read_csv(path):
        out[(r["component"], r["cell"])] = fnum(r["floor_db"])
    return out


def summarize(comps, sites, floor):
    res = {}
    for name, groups in comps.items():
        per = {k: [] for k in ("rms", "lo", "mid", "hi", "actual")}
        for g in groups:
            st = g.cell_stats()
            if floor:
                comp_key = name if name == "p2" else f"{name}_{g.keys}"
                for c, s in st.items():
                    f = floor.get((comp_key, c))
                    if f is not None and math.isfinite(f):
                        s["lo"] = max(s["lo"], min(f, s["rms"]))
                        s["mid"] = max(s["mid"], min(f, s["rms"]))
            for k in per:
                per[k].append(np.mean([s[k] for s in st.values()]))
        res[name] = {k: float(np.mean(v)) for k, v in per.items()}
    comp = {k: float(np.mean([res[n][k] for n in ("p2", "lt_level", "lt_shape")])) for k in ("rms", "lo", "mid", "hi", "actual")}
    site = {}
    for s, g in sites.items():
        W = g.w.sum()
        m = (g.w * g.e).sum() / W
        mse = (g.w * g.e ** 2).sum() / W
        s_e = math.sqrt(max(mse - m * m, 0))
        dbar = (g.w * g.d).sum() / W
        q = (g.w * g.d ** 2).sum() / W
        s_d = math.sqrt(max(q - dbar * dbar, 0))
        c = (g.w * (g.e - m) * (g.d - dbar)).sum() / W
        base = mse + 2 * m * dbar + q
        site[s] = dict(rms=math.sqrt(mse), lo=math.sqrt(max(base - 2 * s_e * s_d, 0)),
                       hi=math.sqrt(base + 2 * s_e * s_d), actual=math.sqrt(max(base + 2 * c, 0)))
    return res, comp, site


def gain_at_rho(comps, rho, floor):
    """Composite gain if every cell's change correlates with its parent error at -rho.

    rho = 1 is the best case (the bound), rho = 0 the emulator mean, and the rho
    that gives a 0.3 dB gain is the correlation a change needs to pass the gate.
    """
    parts, base_parts = [], []
    for name in ("p2", "lt_level", "lt_shape"):
        vals, bvals = [], []
        for g in comps[name]:
            st = g.cell_stats()
            comp_key = name if name == "p2" else f"{name}_{g.keys}"
            cell_new = []
            for c, x in st.items():
                b = x["q"] + 2 * x["m"] * x["dbar"] + x["rms"] ** 2
                r = math.sqrt(max(b - 2 * rho * x["s_e"] * x["s_d"], 0.0))
                f = floor.get((comp_key, c)) if floor else None
                if f is not None and math.isfinite(f):
                    r = max(r, min(f, x["rms"]))
                cell_new.append(r)
            vals.append(np.mean(cell_new))
            bvals.append(np.mean([x["rms"] for x in st.values()]))
        parts.append(np.mean(vals)); base_parts.append(np.mean(bvals))
    return float(np.mean(base_parts) - np.mean(parts))


def solve_rho(comps, target, floor):
    """Smallest rho in [-1, 1] whose gain reaches target; inf if even rho = 1 falls short."""
    if gain_at_rho(comps, 1.0, floor) < target:
        return math.inf
    lo, hi = -1.0, 1.0
    if gain_at_rho(comps, lo, floor) >= target:
        return lo
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if gain_at_rho(comps, mid, floor) >= target:
            hi = mid
        else:
            lo = mid
    return hi


def verdict(comp, scr, site):
    max_gain = min(comp["rms"] - comp["lo"], scr["rms"] - scr["lo"])
    worst_site_best_case = max(s["lo"] - s["rms"] for s in site.values())
    if worst_site_best_case > SITE_GATE_DB:
        return "CERTAIN_HARM", max_gain, worst_site_best_case
    if max_gain < GAIN_GATE_DB:
        return "CANNOT_PASS", max_gain, worst_site_best_case
    return "NOT_RULED_OUT", max_gain, worst_site_best_case


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--parent", required=True)
    ap.add_argument("--parent-col", default="var")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--cand")
    g.add_argument("--delta")
    ap.add_argument("--cand-col", default="var")
    ap.add_argument("--floor", help="results/model_floor_rev1.csv")
    ap.add_argument("--tsv", action="store_true", help="one-line TSV output")
    a = ap.parse_args()
    floor = load_floor(a.floor)
    comps, sites = build(a.parent, a.parent_col, a.cand, a.cand_col, a.delta)
    res, comp, site = summarize(comps, sites, floor)
    comps_s, sites_s = build(a.parent, a.parent_col, a.cand, a.cand_col, a.delta, drop_screen=True)
    _, scr, _ = summarize(comps_s, sites_s, floor)
    v, max_gain, worst = verdict(comp, scr, site)
    actual = a.cand is not None
    rho_req = max(solve_rho(comps, GAIN_GATE_DB, floor), solve_rho(comps_s, GAIN_GATE_DB, floor))
    rho_eff = solve_rho(comps, comp["rms"] - comp["actual"], floor) if actual else math.nan
    if a.tsv:
        print("\t".join(str(x) for x in [os.path.basename(a.cand or a.delta), v, f"{comp['rms']:.3f}",
              f"{comp['rms'] - comp['hi']:.3f}", f"{comp['rms'] - comp['mid']:.3f}", f"{comp['rms'] - comp['lo']:.3f}",
              f"{comp['rms'] - comp['actual']:.3f}" if actual else "", f"{scr['rms'] - scr['lo']:.3f}",
              f"{scr['rms'] - scr['actual']:.3f}" if actual else "", f"{worst:.3f}", f"{rho_req:.3f}", f"{rho_eff:.3f}",
              " ".join(f"{s}:{site[s]['actual'] - site[s]['rms']:+.2f}" for s in SITES) if actual else ""]))
        return
    print(f"parent composite {comp['rms']:.3f} dB (screened {scr['rms']:.3f})")
    for n in ("p2", "lt_level", "lt_shape"):
        r = res[n]
        print(f"  {n:9s} parent {r['rms']:.3f}  candidate interval [{r['lo']:.3f}, {r['hi']:.3f}]  emulator mean {r['mid']:.3f}"
              + (f"  actual {r['actual']:.3f}" if actual else ""))
    print(f"composite gain interval [{comp['rms'] - comp['hi']:+.3f}, {comp['rms'] - comp['lo']:+.3f}] dB, emulator mean {comp['rms'] - comp['mid']:+.3f}"
          + (f", actual {comp['rms'] - comp['actual']:+.3f}" if actual else ""))
    print(f"screened gain interval  [{scr['rms'] - scr['hi']:+.3f}, {scr['rms'] - scr['lo']:+.3f}] dB"
          + (f", actual {scr['rms'] - scr['actual']:+.3f}" if actual else ""))
    for s in SITES:
        x = site[s]
        print(f"  site {s} RMS {x['rms']:.2f} -> [{x['lo']:.2f}, {x['hi']:.2f}]" + (f", actual {x['actual']:.2f}" if actual else ""))
    print(f"correlation needed to pass the gain gate: rho = {rho_req:.2f}" + (f"; this run's effective rho = {rho_eff:.2f}" if actual else ""))
    print(f"verdict: {v} (largest possible gain {max_gain:.3f} dB; smallest possible worst-site rise {worst:+.3f} dB)")


if __name__ == "__main__":
    main()
