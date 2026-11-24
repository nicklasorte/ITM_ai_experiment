"""B23 contrasts: D23a (height), D23b (clutter factorial statistics), D23c (frequency). Development data only.

Usage: python3 -I experiments/batches/b23_contrasts_rev1.py

Reads the frozen pair registries (hash-checked against provenance_rev1.json), the frozen link
table, the stored 707/000/R02 predictions, the manifest and the MATLAB factorial. Writes
experiments/D23a-height-contrasts/, D23b-clutter-factorial/ and D23c-frequency-contrasts/.
Nothing here changes a model, an input or a score.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
import b23_common_rev1 as C  # noqa: E402
import matplotlib  # noqa: E402
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = C.ROOT
M_DIR = ROOT / "experiments/D23m-metadata-audit"
OUTA, OUTB, OUTC = (ROOT / f"experiments/{n}" for n in ("D23a-height-contrasts", "D23b-clutter-factorial", "D23c-frequency-contrasts"))
for d in (OUTA, OUTB, OUTC):
    d.mkdir(parents=True, exist_ok=True)
INF = math.inf
MODELS = {"707": "var_lb_50", "stock": "itm_lb_50", "R02": "cal_lb_50"}


def die(msg):
    raise SystemExit("B23 contrasts STOP: " + msg)


# ---- Inputs and hash checks --------------------------------------------------------------------
prov = json.load(open(M_DIR / "provenance_rev1.json"))
if C.sha256_file(M_DIR / "pair_registry_rev1.csv") != prov["pair_registry_sha256"]:
    die("pair registry changed after freeze")
if C.sha256_file(M_DIR / "co_pair_registry_rev1.csv") != prov["co_pair_registry_sha256"]:
    die("C/O registry changed after freeze")
if C.sha256_file(M_DIR / "manifest_rev1.csv") != prov["manifest_sha256"]:
    die("manifest changed after freeze")
links = pd.read_csv(ROOT / "data/links/phase2_links_rev1.csv").set_index("link_id")
man = pd.read_csv(M_DIR / "manifest_rev1.csv").set_index("link_id")
out = pd.read_csv(M_DIR / "outcomes_rev1.csv").set_index("link_id")
reg = pd.read_csv(M_DIR / "pair_registry_rev1.csv")
cor = pd.read_csv(M_DIR / "co_pair_registry_rev1.csv")
pp = pd.read_csv(M_DIR / "parent_parts_rev1.csv").set_index("link_id")
fac = pd.read_csv(ROOT / "experiments/D23b-clutter-factorial/factorial_rev1.csv").set_index("link_id")
pred = pd.DataFrame(index=links.index)
p707 = pd.read_csv(ROOT / "experiments/707-cascaded-isolated-clutter-at-r/predictions_phase2.csv").set_index("link_id")
pr02 = pd.read_csv(ROOT / "experiments/R02-constrained-recalibration/predictions_phase2.csv").set_index("link_id")
p000 = pd.read_csv(ROOT / "experiments/000-baseline/predictions_phase2.csv").set_index("link_id")
for nm, df, col in (("707", p707, "var_lb_50"), ("R02", pr02, "cal_lb_50"), ("stock", p000, "itm_lb_50")):
    if df.index.has_duplicates:
        die(f"duplicate keys in {nm} predictions")
    missing = links.index.difference(df.index)
    if len(missing):
        die(f"{nm} predictions miss {len(missing)} links")
    pred[nm] = df.loc[links.index, col]
if (pred.stock - links.itm_lb_50).abs().max() > 1e-12:
    die("stored stock predictions differ from the frozen table")
if not np.isfinite(pred.to_numpy()).all():
    die("non-finite stored prediction")
if abs(pred["707"].to_numpy() - pp.loc[links.index, "loss_707_db"].to_numpy()).max() > 1e-9:
    die("707 stored predictions differ from the MATLAB parity run")
meas_lo, meas_hi = out.lb_lo_db, out.lb_hi_db
detected = links.censored == 0

# ---- Helpers ----------------------------------------------------------------------------------------
def minterval(lid):
    return (float(meas_lo[lid]), float(meas_hi[lid]))


def agg_cell(df, col, extra=None):
    """Equal physical-base weighting, then conditional bootstrap over whole bases."""
    if df.empty:
        return dict(n_pairs=0, n_bases=0, mean=np.nan, lo=np.nan, hi=np.nan, note="no pairs", disp="NONE")
    b = df.groupby("physical_base_id")[col].mean()
    m, lo, hi, n, note = C.boot_interval(b.to_numpy())
    return dict(n_pairs=len(df), n_bases=n, mean=m, lo=lo, hi=hi, note=note, disp=C.disposition(m, lo, hi, n))


def decide(cells, sign=+1, need_site=None):
    """Cross-site decision rule of B23 D23a/D23c. cells: {site: cell dict}. sign=+1 tests a positive effect."""
    el = {s: c for s, c in cells.items() if c["n_bases"] >= 10 and np.isfinite(c["lo"])}
    if not el:
        return "NOT IDENTIFIABLE", "no site has 10 or more independent bases"
    good = [s for s, c in el.items() if c["disp"] == ("POS" if sign > 0 else "NEG")]
    opp = [s for s, c in el.items() if (c["mean"] * sign) <= -1.0]
    imprecise = [s for s, c in el.items() if c["disp"].endswith("-imprecise")]
    reverse = [s for s, c in el.items() if c["disp"] == ("NEG" if sign > 0 else "POS")]
    if len(good) >= 2 and not opp and (need_site is None or any(s in need_site for s in good)):
        return "SUPPORT", f"sites in the predicted direction: {', '.join(good)}"
    if len(reverse) >= 2 and not [s for s in el if (el[s]['mean'] * sign) >= 1.0]:
        return "CONTRADICT", f"sites in the opposite direction: {', '.join(reverse)}"
    if len(el) < 2 and good:
        return "LOCAL", f"one eligible site ({', '.join(el)}) in the predicted direction; cross-site replication not available"
    if good and len(good) == 1:
        return "LOCAL", f"only {good[0]} meets the rule; other eligible sites: {', '.join(s for s in el if s != good[0])}"
    why = "imprecise interval at " + ", ".join(imprecise) if imprecise else "criteria not met"
    return "INCONCLUSIVE", why


def cohort_frames(df):
    return {"strict": df[df.tier == "strict"], "exploratory (strict + limited)": df}


# =============================================================================================================
# D23a: matched-height contrasts
# =============================================================================================================
H = reg[reg.kind.isin(["HGT_RX", "HGT_TX"])].copy()
lo_id, hi_id = H.low_link_id.to_numpy(), H.high_link_id.to_numpy()
H["h_low"] = np.where(H.kind == "HGT_RX", H.low_hrx, H.low_htx)
H["h_high"] = np.where(H.kind == "HGT_RX", H.high_hrx, H.high_htx)
H["span_m"] = H.h_high - H.h_low
H["f_mhz"] = H.low_f_mhz
H["detected_pair"] = (detected.loc[lo_id].to_numpy() & detected.loc[hi_id].to_numpy())
H["meas_dL"] = (meas_lo.loc[hi_id].to_numpy() - meas_lo.loc[lo_id].to_numpy())   # exact where both detected
iv = [C.interval_sub(minterval(h), minterval(l)) for h, l in zip(hi_id, lo_id)]
H["meas_iv_lo"] = [a for a, _ in iv]
H["meas_iv_hi"] = [b for _, b in iv]
H["raw_exact"] = np.isfinite(H.meas_iv_lo) & (H.meas_iv_lo == H.meas_iv_hi)
for m in MODELS:
    H[f"dL_{m}"] = pred[m].loc[hi_id].to_numpy() - pred[m].loc[lo_id].to_numpy()
    H[f"e_{m}"] = H[f"dL_{m}"] - H.meas_dL
for m in ("stock", "R02"):
    H[f"absdiff_{m}_vs_707"] = H[f"e_{m}"].abs() - H["e_707"].abs()
H["sign_concordant_707"] = np.sign(H.dL_707) == np.sign(H.meas_dL)
H["dB_per_m_meas"] = H.meas_dL / H.span_m
H["dB_per_m_707"] = H.dL_707 / H.span_m
H.loc[~H.detected_pair, ["e_707", "e_stock", "e_R02", "absdiff_stock_vs_707", "absdiff_R02_vs_707"]] = np.nan
H.to_csv(OUTA / "pairs_rev1.csv", index=False)

rows = []
strata = {"O blocked-blocked (primary)": lambda d: d[(d.siting == "O") & (d.pair_class == "blocked-blocked")],
          "O clear-clear": lambda d: d[(d.siting == "O") & (d.pair_class == "clear-clear")],
          "O transition": lambda d: d[(d.siting == "O") & (d.pair_class == "transition")],
          "C (all classes, actual heights)": lambda d: d[d.siting == "C"],
          "A (all classes; not verified open)": lambda d: d[d.siting == "A"]}
metrics = [("e_707", "signed 707 contrast error"), ("absdiff_stock_vs_707", "|e_stock|-|e_707|"), ("absdiff_R02_vs_707", "|e_R02|-|e_707|")]
Hd = H[H.detected_pair]
cells_primary = {}
for coh, df in cohort_frames(Hd).items():
    for sname, f in strata.items():
        sub = f(df)
        for site in ["R1", "R2", "R3", "VA"]:
            ss = sub[sub.set == site]
            for col, lab in metrics:
                r = agg_cell(ss, col)
                rows.append(dict(cohort=coh, stratum=sname, set=site, metric=lab, **r))
                if sname.startswith("O blocked") and col == "e_707":
                    cells_primary.setdefault(coh, {})[site] = r
    sub = strata["O blocked-blocked (primary)"](df)
    r = agg_cell(sub.assign(sconc=sub.sign_concordant_707.astype(float)), "sconc")
    rows.append(dict(cohort=coh, stratum="O blocked-blocked (primary)", set="all", metric="sign concordance (fraction)", **r))
SA = pd.DataFrame(rows)
SA.to_csv(OUTA / "site_stats_rev1.csv", index=False)

# Interval consistency (informative bounds), detected or not
Hi = H.copy()
dep = []
for r in Hi.itertuples():
    d = C.violation_depth(r.dL_707, (r.meas_iv_lo, r.meas_iv_hi))
    dep.append(np.nan if d is None else d)
Hi["viol_depth_707"] = dep
Hi["informative"] = Hi.viol_depth_707.notna()
irow = []
for coh, df in cohort_frames(Hi).items():
    for site in ["R1", "R2", "R3", "VA"]:
        s = df[(df.set == site) & (df.siting == "O") & (~df.detected_pair)]
        inf_ = s[s.informative]
        irow.append(dict(cohort=coh, set=site, pairs=len(s), informative=len(inf_), uninformative=len(s) - len(inf_),
                         raw_exact_not_detected=int((s.raw_exact & ~s.detected_pair).sum()),
                         violated=int((inf_.viol_depth_707 > 0).sum()),
                         mean_depth_db=float(inf_.viol_depth_707[inf_.viol_depth_707 > 0].mean()) if (inf_.viol_depth_707 > 0).any() else 0.0))
pd.DataFrame(irow).to_csv(OUTA / "interval_stats_rev1.csv", index=False)

dispA = {coh: decide(cells_primary.get(coh, {}), +1) for coh in cohort_frames(Hd)}
# figure
fig, ax = plt.subplots(figsize=(6, 5))
sub = Hd[(Hd.siting == "O") & (Hd.pair_class == "blocked-blocked")]
for s, g in sub.groupby("set"):
    ax.scatter(g.meas_dL, g.dL_707, s=8, label=f"{s} (n={len(g)})", alpha=0.6)
lim = [min(sub.meas_dL.min(), sub.dL_707.min()) - 2, max(sub.meas_dL.max(), sub.dL_707.max()) + 2] if len(sub) else [-1, 1]
ax.plot(lim, lim, "k-", lw=0.8); ax.set_xlabel("measured L_high - L_low (dB)"); ax.set_ylabel("707 L_high - L_low (dB)")
ax.set_title("D23a: open, blocked-at-both height contrasts (development data)"); ax.legend(fontsize=7)
fig.tight_layout(); fig.savefig(OUTA / "height_response_rev1.png", dpi=130); plt.close(fig)

la = ["D23a: matched-height contrasts (B23). Development data only; not a scored run.", "",
      f"Registered height pairs: {len(H)}; both rows detected (primary exact): {int(H.detected_pair.sum())}; with a censored row: {int((~H.detected_pair).sum())}.",
      "Contrast = L_high - L_low (dB); e = predicted - measured (positive: too little loss reduction).",
      "Provenance tiers: strict = R1 only (see D23m summary). Calibration uncertainty of height contrasts is unquantified, so every directional "
      "statement is provisional (B23 section 3.4).", ""]
for coh in cohort_frames(Hd):
    la += [f"## Cohort: {coh}", "", "Primary stratum: open siting, blocked at both heights; signed 707 contrast error, equal-base mean, 95 % conditional path-bootstrap interval.", "",
           "| Site | pairs | bases | mean e (dB) | interval | status |", "| --- | --- | --- | --- | --- | --- |"]
    for site in ["R1", "R2", "R3", "VA"]:
        c = cells_primary.get(coh, {}).get(site)
        if c is None or c["n_pairs"] == 0:
            la.append(f"| {site} | 0 | 0 | n/a | n/a | no pairs |")
        else:
            iv_s = "n/a" if not np.isfinite(c["lo"]) else f"[{c['lo']:+.2f}, {c['hi']:+.2f}]"
            la.append(f"| {site} | {c['n_pairs']} | {c['n_bases']} | {c['mean']:+.2f} | {iv_s} | {c['disp']} {c['note']} |")
    d, why = dispA[coh]
    la += ["", f"**Disposition ({coh}): {d}**. {why}.", ""]
    for stn in ["O clear-clear", "O transition", "C (all classes, actual heights)"]:
        la.append(f"{stn}:")
        for site in ["R1", "R2", "R3", "VA"]:
            c = SA[(SA.cohort == coh) & (SA.stratum == stn) & (SA.set == site) & (SA.metric == "signed 707 contrast error")]
            if len(c) and c.iloc[0].n_pairs:
                c = c.iloc[0]
                la.append(f"  {site}: {int(c.n_pairs)} pairs, {int(c.n_bases)} bases, mean e {c['mean']:+.2f} dB"
                          + (f" [{c.lo:+.2f}, {c.hi:+.2f}]" if np.isfinite(c.lo) else "") + f" ({c.disp})")
        la.append("")
la += ["Comparators (|e_stock| - |e_707| and |e_R02| - |e_707|; negative favours the comparator) are in site_stats_rev1.csv.",
       "C rows are classified at their actual structural heights; 707 substitutes the clutter height for the mobile terminal (D23b).",
       "A rows are not treated as verified open. No registered B21 comparator exists; none reported.", "",
       "Interval consistency (pairs with a censored row only; informative bounds only; not exact error):", pd.DataFrame(irow).to_string(index=False)]
(OUTA / "summary.txt").write_text("\n".join(la) + "\n")

# =============================================================================================================
# D23b: factorial decomposition and predictive comparison
# =============================================================================================================
F = fac.loc[cor.link_id_c]
Lo_par = pred["707"].loc[cor.link_id_o].to_numpy()
dec = [C.decompose(F.G00.iloc[i], F.G10.iloc[i], F.G01.iloc[i], F.G11.iloc[i], Lo_par[i]) for i in range(len(F))]
D = pd.DataFrame(dec)
if max(D.closure_n.abs().max(), D.closure_n2.abs().max(), D.closure_total.abs().max()) > 1e-9:
    die("factorial closure failed")
D.insert(0, "link_id_c", cor.link_id_c.to_numpy())
D.insert(1, "link_id_o", cor.link_id_o.to_numpy())
for c_ in ("set", "tier", "physical_base_id", "f_mhz"):
    D[c_] = cor[c_].to_numpy()
D["h_m"] = F.h_m.to_numpy(); D["R_m"] = F.R_m.to_numpy(); D["H_m"] = F.H_m.to_numpy(); D["A_h_db"] = F.A_h_db.to_numpy()
D["domain"] = np.where(D.f_mhz > 3000, ">3000 MHz (hold3)", "30-3000 MHz")
D["height_class"] = np.where(D.h_m < D.R_m, "h<R", "h>=R")
D["same_profile"] = cor.same_profile.to_numpy()
# bound/mode changes between cells
D["mode_changes_G00_G10"] = (F.mode_G00.to_numpy() != F.mode_G10.to_numpy())
D["bound_changes_G00_G10"] = (F.bound_G00.to_numpy() != F.bound_G10.to_numpy())
D["par_eq_stored"] = (np.abs(F.PAR.to_numpy() - pred["707"].loc[cor.link_id_c].to_numpy()) < 1e-9)
D.to_csv(OUTB / "decomposition_rev1.csv", index=False)
F.reset_index().to_csv(OUTB / "factorial_cells_copy_rev1.csv", index=False)
os_remove = OUTB / "factorial_cells_copy_rev1.csv"
os_remove.unlink()
nz = lambda s, t=1.0: int((s.abs() >= t).sum())
nrows = len(D)
comp = []
for dom, g in [("all", D)] + list(D.groupby("domain")):
    for hc, gg in [("all", g)] + list(g.groupby("height_class")):
        if len(gg) == 0:
            continue
        comp.append(dict(domain=dom, height_class=hc, rows=len(gg), mean_g=gg.g.mean(), mean_a0=gg.a0.mean(), mean_a1=gg.a1.mean(),
                         mean_i=gg.i.mean(), mean_m=gg.m.mean(), mean_total=gg.total.mean(),
                         rows_abs_g_ge1=nz(gg.g), rows_abs_i_ge1=nz(gg.i), rows_abs_m_ge1=nz(gg.m),
                         rows_g_nonzero=int((gg.g.abs() > 1e-9).sum()), rows_m_nonzero=int((gg.m.abs() > 1e-9).sum())))
COMP = pd.DataFrame(comp)

# ---- Replay of D20c (original grouping and arithmetic) before any new contrast ---------------------------------
Lc = links.loc[cor.link_id_c]; Lo = links.loc[cor.link_id_o]
d707 = pred["707"].loc[cor.link_id_c].to_numpy() - pred["707"].loc[cor.link_id_o].to_numpy()
dm_row = Lc.meas_lb_db.to_numpy() - Lo.meas_lb_db.to_numpy()
both_det = (Lc.censored.to_numpy() == 0) & (Lo.censored.to_numpy() == 0)
if len(cor) != 1400 or int(both_det.sum()) != 1165:
    die(f"D20c replay counts differ: {len(cor)} pairs, {int(both_det.sum())} detected")
const704 = json.load(open(ROOT / "experiments/704-cascaded-isolated-constant/metrics.json"))["cfg"]["terminal_clutter_db"]
rms = lambda x: float(np.sqrt(np.mean(np.square(x))))
replay = dict(n_pairs=len(cor), n_both_detected=int(both_det.sum()), mean_dm=round(float(dm_row[both_det].mean()), 2),
              mean_d707=round(float(d707[both_det].mean()), 2), const704=const704)
txt = (ROOT / "experiments/D20c-paired-clutter/summary.txt").read_text()
for key, val in (("Matched pairs: 1400", True), (f"mean {replay['mean_d707']:.2f}", True), (f"mean {replay['mean_dm']:.2f}", True), (f"704 constant: {const704} dB", True)):
    if key not in txt:
        die(f"D20c replay does not reproduce the recorded summary: missing '{key}'")
site_c = Lc.set.to_numpy()
loso = {}
for s in ["R1", "R2", "VA"]:
    te = both_det & (site_c == s); tr = both_det & (site_c != s)
    cfit = dm_row[tr].mean()
    loso[s] = dict(n=int(te.sum()), rms_p2108=rms(dm_row[te] - d707[te]), rms_refit=rms(dm_row[te] - cfit), rms_704=rms(dm_row[te] - const704), const=float(cfit))
for s in ["R1", "R2", "VA"]:
    line = f"| {s} | {loso[s]['n']} | {loso[s]['rms_p2108']:.2f} | {loso[s]['rms_refit']:.2f} ({loso[s]['const']:.2f}) | {loso[s]['rms_704']:.2f} |"
    if line not in txt:
        die(f"D20c replay: leave-one-site-out row differs: {line}")
replay["loso"] = loso
replay["status"] = "reproduced: counts, means, 704 constant and every leave-one-site-out row match experiments/D20c-paired-clutter/summary.txt"

# ---- Predictive comparison on exact (detected) pairs ------------------------------------------------------------
P = pd.DataFrame(dict(link_id_c=cor.link_id_c.to_numpy(), set=cor.set.to_numpy(), tier=cor.tier.to_numpy(), physical_base_id=cor.physical_base_id.to_numpy(),
                      f_mhz=cor.f_mhz.to_numpy(), domain=D.domain.to_numpy(), height_class=D.height_class.to_numpy(),
                      meas=dm_row, detected=both_det))
P["d_full"] = F.G11.to_numpy() - Lo_par                     # parent total: G11 - L_O,parent
P["d_geom_only"] = F.G10.to_numpy() - Lo_par
P["d_add_only_actual"] = F.G01.to_numpy() - Lo_par           # known double-counting ablation, not a candidate
P["d_none"] = F.G00.to_numpy() - Lo_par
P["d_704"] = const704
P["d_zero"] = 0.0
if np.abs(P.d_full - d707).max() > 1e-9:
    die("G11 - L_O differs from the stored 707 C minus O difference")
Pd = P[P.detected].copy()
# equal-base LOSO constant (revised analysis) and row-mean LOSO constant (replay)
for s in Pd.set.unique():
    tr = Pd[Pd.set != s]
    Pd.loc[Pd.set == s, "d_loso_eqbase"] = tr.groupby("physical_base_id").meas.mean().mean()
    Pd.loc[Pd.set == s, "d_loso_rowmean"] = tr.meas.mean()
cmp_cols = ["d_full", "d_geom_only", "d_add_only_actual", "d_none", "d_704", "d_zero", "d_loso_eqbase"]
for cc in cmp_cols:
    Pd["abs_" + cc] = (Pd[cc] - Pd.meas).abs()
    Pd["sq_" + cc] = (Pd[cc] - Pd.meas) ** 2
Pd.to_csv(OUTB / "pairs_rev1.csv", index=False)

comp_rows = []
cells_b = {}
for coh, df in cohort_frames(Pd).items():
    for dom in ["all", "30-3000 MHz", ">3000 MHz (hold3)"]:
        dd = df if dom == "all" else df[df.domain == dom]
        for site in ["R1", "R2", "VA"]:
            ss = dd[dd.set == site]
            if ss.empty:
                continue
            base_row = dict(cohort=coh, domain=dom, set=site, pairs=len(ss), bases=ss.physical_base_id.nunique())
            for cc in cmp_cols:
                base_row["MAE_" + cc] = ss.groupby("physical_base_id")["abs_" + cc].mean().mean()
            base_row["rowRMS_full"] = rms(ss.d_full - ss.meas)
            base_row["rowRMS_loso_rowmean"] = rms(ss.d_loso_rowmean - ss.meas)
            for ref in ("d_loso_eqbase", "d_zero"):
                dif = ss.assign(delta=ss["abs_" + ref] - ss["abs_d_full"])    # positive: full beats the reference
                r = agg_cell(dif, "delta")
                base_row[f"full_beats_{ref}_mean"] = r["mean"]; base_row[f"full_beats_{ref}_lo"] = r["lo"]; base_row[f"full_beats_{ref}_hi"] = r["hi"]
                base_row[f"full_beats_{ref}_disp"] = r["disp"]
                if dom == "30-3000 MHz" or dom == "all":
                    cells_b.setdefault((coh, dom, ref), {})[site] = r
            comp_rows.append(base_row)
CS = pd.DataFrame(comp_rows)
CS.to_csv(OUTB / "comparison_stats_rev1.csv", index=False)

# censoring intervals for C/O contrasts (informative bounds only), with the full-configuration prediction
civ = []
for r in P.itertuples():
    lc, lo_ = r.link_id_c, cor.link_id_o.iloc[len(civ)]
    iv_ = C.interval_sub(minterval(lc), minterval(lo_))
    civ.append(dict(link_id_c=lc, iv_lo=iv_[0], iv_hi=iv_[1], detected=r.detected, set=r.set, tier=r.tier, f_mhz=r.f_mhz,
                    d_full=r.d_full, d_zero=0.0, d_loso=np.nan))
CI = pd.DataFrame(civ)
for nm in ("d_full", "d_zero"):
    CI["depth_" + nm] = [C.violation_depth(getattr(r, nm), (r.iv_lo, r.iv_hi)) for r in CI.itertuples()]
CI.to_csv(OUTB / "censor_intervals_rev1.csv", index=False)
ci_rows = []
for coh, df in cohort_frames(CI).items():
    for site in ["R1", "R2", "VA"]:
        s = df[(df.set == site) & (~df.detected)]
        for nm in ("d_full", "d_zero"):
            dep = pd.to_numeric(s["depth_" + nm])
            infm = dep.notna()
            ci_rows.append(dict(cohort=coh, set=site, comparator=nm, pairs=len(s), informative=int(infm.sum()), violated=int((dep[infm] > 0).sum()),
                                mean_depth=float(dep[infm][dep[infm] > 0].mean()) if (dep[infm] > 0).any() else 0.0))
CIS = pd.DataFrame(ci_rows)

# figure
fig, ax = plt.subplots(1, 2, figsize=(10, 4))
for k, (lab, col) in enumerate([("g (height substitution)", "g"), ("a0 (additive at h)", "a0"), ("a1 (additive at H)", "a1"), ("i (interaction)", "i"), ("m (baseline mismatch)", "m")]):
    ax[0].boxplot(D[col].to_numpy(), positions=[k], widths=0.5, showfliers=False)
ax[0].set_xticks(range(5)); ax[0].set_xticklabels(["g", "a0", "a1", "i", "m"]); ax[0].set_ylabel("dB"); ax[0].set_title("C rows, all (n=%d)" % len(D))
for dom, g in D.groupby("domain"):
    ax[1].hist(g.g, bins=40, alpha=0.5, label=f"g, {dom}")
ax[1].set_xlabel("g = G10 - G00 (dB)"); ax[1].legend(fontsize=7); ax[1].set_title("Height-substitution effect")
fig.tight_layout(); fig.savefig(OUTB / "component_distribution_rev1.png", dpi=130); plt.close(fig)

# Attribution findings
cnt_g = int((D.g.abs() >= 1).sum()); cnt_m = int((D.m.abs() >= 1).sum()); cnt_i = int((D.i.abs() >= 1).sum())
tot_hltR = int((D.height_class == "h<R").sum())
attrib = dict(rows=nrows, rows_h_lt_R=tot_hltR, rows_abs_g_ge1=cnt_g, rows_abs_m_ge1=cnt_m, rows_abs_i_ge1=cnt_i,
              max_abs_g=float(D.g.abs().max()), max_abs_m=float(D.m.abs().max()), max_abs_i=float(D.i.abs().max()),
              mean_a0=float(D.a0.mean()), mean_a1=float(D.a1.mean()), mean_g=float(D.g.mean()), mean_i=float(D.i.mean()), mean_m=float(D.m.mean()),
              mean_total=float(D.total.mean()))
ex = D.loc[D.g.abs().idxmax()]
lb = ["D23b: factorial clutter/geometry attribution (B23). Development data only; not a scored run.", "",
      "## D20c replay (original grouping and arithmetic, before any new contrast)", "",
      f"{replay['status']}.",
      f"Pairs {replay['n_pairs']}; both detected {replay['n_both_detected']}; measured mean {replay['mean_dm']} dB; 707 predicted mean {replay['mean_d707']} dB; 704 constant {const704} dB.",
      "The original D20c decision is unchanged and is not reopened here.", "",
      "## Attribution (all 1,400 C/O twin pairs; model only, no measurement involved)", "",
      f"Closure of n = g + a1 = g + a0 + i and total = n + m = G11 - L_O holds to 1e-9 dB on every row; G11 equals the parent and the parent equals stored 707 on all {nrows} C rows (MATLAB check, max 5e-13 dB).",
      f"Rows with h < R (height substitution active): {tot_hltR} of {nrows}; with h >= R all four cells coincide.", "",
      COMP.round(2).to_string(index=False), "",
      f"Rows with |g| >= 1 dB: {cnt_g}; |i| >= 1 dB: {cnt_i}; |m| >= 1 dB: {cnt_m}. Largest |g| {attrib['max_abs_g']:.2f} dB, |i| {attrib['max_abs_i']:.2f} dB, |m| {attrib['max_abs_m']:.2f} dB.",
      f"Counterexample to additive-only attribution (largest |g|): {ex.link_id_c}, f = {ex.f_mhz:g} MHz, h = {ex.h_m:g} m, R = {ex.R_m:g} m: g = {ex.g:+.2f} dB, a0 = {ex.a0:+.2f}, a1 = {ex.a1:+.2f}, i = {ex.i:+.2f}, m = {ex.m:+.2f}, total {ex.total:+.2f} dB.",
      "Nonzero i shows nonlinear dependence in the model, not an observed interaction. Raw component differences are not causal final-loss contributions.", "",
      "## Twin facts", "",
      f"Same profile hash in {prov['co_pairs_same_profile_hash']} of {prov['co_pairs']} pairs; different mobile coordinates in {prov['co_pairs_different_mobile_coordinates']}; different listed distance in {prov['co_pairs_different_listed_distance']}. "
      "The twins do not generally share one profile, so m (G00 minus the open parent) includes the twin's own geometry as well as the model baseline.", "",
      "## Predictive comparison on exact (both-detected) pairs", "",
      "MAE is site-balanced: per-base mean of |prediction - measured difference|, then mean over bases. Full = parent configuration; geom-only = G10; "
      "add-only = G01 (known double-counting ablation, not a candidate); none = G00; LOSO = equal-base mean of other sites' exact training contrasts.", "",
      CS[["cohort", "domain", "set", "pairs", "bases", "MAE_d_full", "MAE_d_geom_only", "MAE_d_add_only_actual", "MAE_d_none", "MAE_d_704", "MAE_d_zero", "MAE_d_loso_eqbase", "rowRMS_full", "rowRMS_loso_rowmean"]].round(2).to_string(index=False), "",
      "Full configuration versus the LOSO constant and versus zero (positive = full has the smaller absolute error; equal-base mean, conditional bootstrap):", "",
      CS[["cohort", "domain", "set", "bases", "full_beats_d_loso_eqbase_mean", "full_beats_d_loso_eqbase_lo", "full_beats_d_loso_eqbase_hi", "full_beats_d_loso_eqbase_disp",
          "full_beats_d_zero_mean", "full_beats_d_zero_lo", "full_beats_d_zero_hi", "full_beats_d_zero_disp"]].round(2).to_string(index=False), "",
      "## Censored evidence (pairs with a censored row; informative bounds only)", "", CIS.to_string(index=False), ""]
# decision 2 per cohort: beats both references by >= 1 dB at two eligible sites
dec2 = {}
for coh in cohort_frames(Pd):
    ok_sites, bad = [], []
    for dom in ["all"]:
        sites = set(CS[(CS.cohort == coh) & (CS.domain == dom)].set)
        for s in sites:
            a = cells_b.get((coh, dom, "d_loso_eqbase"), {}).get(s); b = cells_b.get((coh, dom, "d_zero"), {}).get(s)
            if a is None or b is None or a["n_bases"] < 10:
                continue
            if a["disp"] == "POS" and b["disp"] == "POS":
                ok_sites.append(s)
            if a["mean"] <= -1 or b["mean"] <= -1:
                bad.append(s)
    if len(ok_sites) >= 2 and not bad:
        dec2[coh] = ("CONDITIONAL SUPPORT", f"beats both references by >= 1 dB with a positive interval at {', '.join(ok_sites)}")
    elif len(ok_sites) == 1 and not bad:
        dec2[coh] = ("LOCAL", f"only {ok_sites[0]} meets the rule")
    else:
        dec2[coh] = ("INCONCLUSIVE", "rule not met" + (f"; reverse effect at {', '.join(bad)}" if bad else ""))
lb += ["## Decisions (B23 D23b)", "",
       f"1. Attribution: {cnt_g} rows have |g| >= 1 dB and {cnt_m} have |m| >= 1 dB (of {nrows}); each such row is an explicit counterexample to an additive-only reading of the C/O difference. "
       f"{'Counterexamples exist: the twin difference is height substitution plus clutter term plus a model-baseline mismatch, not the P.2108-1 term alone.' if (cnt_g or cnt_m) else 'No row shows a material geometry or mismatch term.'}"]
for coh, (d, why) in dec2.items():
    lb.append(f"2. Predictive evidence, {coh}: **{d}** ({why}). Every above-3 GHz figure is hold3, an extrapolation policy, not source-validated coverage.")
lb.append("3. Censored evidence is listed above and is reported separately; where detected-only support comes with worse informative-bound consistency, treat the result as mixed.")
lb += ["", "Measurement caveat: Part I of ERL 65-ITS 58 estimates an unlogged transmitter impedance change of up to about 2 dB between open and concealed siting; "
       "differential calibration uncertainty for C/O contrasts is therefore at least that large for R1 and unquantified elsewhere, so the 1 dB resolution cannot separate small effects."]
(OUTB / "summary.txt").write_text("\n".join(lb) + "\n")
# attribution note
note = ["# D23b attribution note (for the planner and the normal LOG process)", "",
        "Correction to the D20c interpretation, now measured on the model: the predicted C/O difference is not P.2108-1's A_h alone.",
        "", f"- On {nrows} C/O twin pairs the full configuration equals the stored 707 to 1e-9 dB (G11 = parent). ",
        f"- Mean decomposition (dB): geometry g {attrib['mean_g']:+.2f}; additive at h a0 {attrib['mean_a0']:+.2f}; additive at H a1 {attrib['mean_a1']:+.2f}; interaction i {attrib['mean_i']:+.2f}; baseline mismatch m {attrib['mean_m']:+.2f}; total {attrib['mean_total']:+.2f}.",
        f"- |g| >= 1 dB on {cnt_g} rows, |m| >= 1 dB on {cnt_m} rows.",
        "- m includes the twin's own geometry: the C and O rows have different mobile coordinates and listed distances in most pairs.",
        "- No change to 707, the acceptance gates or the B20 records is proposed."]
(OUTB / "attribution_note_rev1.md").write_text("\n".join(note) + "\n")
json.dump(dict(replay=replay, attribution=attrib, decisions={k: list(v) for k, v in dec2.items()}), open(OUTB / "d23b_results_rev1.json", "w"), indent=1, default=float)

# =============================================================================================================
# D23c: matched-frequency residual contrasts
# =============================================================================================================
Fq = reg[reg.kind.isin(["FRQ_HIGH", "FRQ_LOW"])].copy()
l_, h_ = Fq.low_link_id.to_numpy(), Fq.high_link_id.to_numpy()
Fq["detected_pair"] = (detected.loc[l_].to_numpy() & detected.loc[h_].to_numpy())
Fq["octaves"] = np.log2(Fq.high_f_mhz / Fq.low_f_mhz)
Fq["decades"] = np.log10(Fq.high_f_mhz / Fq.low_f_mhz)
for m in MODELS:
    Fq[f"T_{m}"] = ((meas_lo.loc[h_].to_numpy() - pred[m].loc[h_].to_numpy()) - (meas_lo.loc[l_].to_numpy() - pred[m].loc[l_].to_numpy()))
    Fq[f"slope_{m}"] = Fq[f"T_{m}"] / Fq.decades
Fq.loc[~Fq.detected_pair, [c for c in Fq.columns if c.startswith("T_") or c.startswith("slope_")]] = np.nan
# FSPL cancels: verify with listed versus profile distance
fs_listed = lambda ids_: links.loc[ids_, "fs_db"].to_numpy()
fs_prof = lambda ids_: (32.45 + 20 * np.log10(links.loc[ids_, "f_mhz"].to_numpy()) + 20 * np.log10(man.loc[ids_, "profile_d_km"].to_numpy()))
cancel = np.abs((fs_listed(h_) - fs_prof(h_)) - (fs_listed(l_) - fs_prof(l_)))
if cancel.max() > 1e-9:
    die("FSPL does not cancel in the residual contrast")
# components
for nm, a in (("A_ref_db", "dA_ref"), ("A_s_db", "dA_s"), ("L_ba_db", "dL_ba"), ("L_bs_db", "dL_bs")):
    Fq[a] = pp[nm].loc[h_].to_numpy() - pp[nm].loc[l_].to_numpy()
Fq["bound_low"] = pp.bound_binds.loc[l_].to_numpy(); Fq["bound_high"] = pp.bound_binds.loc[h_].to_numpy()
Fq["bound_changes"] = Fq.bound_low != Fq.bound_high
Fq["mode_low"] = pp.itm_mode.loc[l_].to_numpy(); Fq["mode_high"] = pp.itm_mode.loc[h_].to_numpy()
Fq["fac_g_diff"] = np.nan; Fq["fac_a1_diff"] = np.nan; Fq["fac_i_diff"] = np.nan; Fq["fac_m_diff"] = np.nan
Dk = D.set_index("link_id_c")
for k, r in enumerate(Fq.itertuples()):
    if r.low_link_id in Dk.index and r.high_link_id in Dk.index:
        for nm in ("g", "a1", "i", "m"):
            Fq.iat[k, Fq.columns.get_loc("fac_" + nm + "_diff")] = Dk.loc[r.high_link_id, nm] - Dk.loc[r.low_link_id, nm]
Fq.to_csv(OUTC / "pairs_rev1.csv", index=False)
Fq[["pair_id", "kind", "set", "siting", "pair_class", "dA_ref", "dA_s", "dL_ba", "dL_bs", "bound_low", "bound_high", "bound_changes",
    "mode_low", "mode_high", "fac_g_diff", "fac_a1_diff", "fac_i_diff", "fac_m_diff"]].to_csv(OUTC / "component_contrasts_rev1.csv", index=False)

Fd = Fq[Fq.detected_pair]
rowsC, cells_c = [], {}
fstr = {"O clear-clear (primary)": lambda d: d[(d.siting == "O") & (d.pair_class == "clear-clear")],
        "O blocked-blocked": lambda d: d[(d.siting == "O") & (d.pair_class == "blocked-blocked")],
        "O transition": lambda d: d[(d.siting == "O") & (d.pair_class == "transition")],
        "C": lambda d: d[d.siting == "C"]}
for kind in ["FRQ_HIGH", "FRQ_LOW"]:
    for coh, df in cohort_frames(Fd[Fd.kind == kind]).items():
        for sname, f in fstr.items():
            sub = f(df)
            for site in ["R1", "R2", "R3", "VA"]:
                ss = sub[sub.set == site]
                for m in ("707", "stock", "R02"):
                    r = agg_cell(ss, f"T_{m}")
                    rowsC.append(dict(kind=kind, cohort=coh, stratum=sname, set=site, model=m, **r))
                    if kind == "FRQ_HIGH" and sname.startswith("O clear") and m == "707":
                        cells_c.setdefault(coh, {})[site] = r
SC = pd.DataFrame(rowsC)
SC.to_csv(OUTC / "site_stats_rev1.csv", index=False)
ivr = []
for r in Fq.itertuples():
    meas_iv = C.interval_sub(minterval(r.high_link_id), minterval(r.low_link_id))
    p_dif = (pred["707"][r.high_link_id] - pred["707"][r.low_link_id])
    d_ = C.violation_depth(p_dif, meas_iv)
    ivr.append(dict(pair_id=r.pair_id, set=r.set, kind=r.kind, siting=r.siting, tier=r.tier, informative=d_ is not None,
                    depth_707=np.nan if d_ is None else d_, detected=r.detected_pair))
IVR = pd.DataFrame(ivr)
IVR.groupby(["kind", "set", "siting", "tier"]).agg(pairs=("pair_id", "size"), informative=("informative", "sum")).reset_index().to_csv(OUTC / "interval_stats_rev1.csv", index=False)
dispC = {coh: decide(cells_c.get(coh, {}), +1, need_site={"R2", "VA"}) for coh in cohort_frames(Fd)}

fig, ax = plt.subplots(figsize=(6.5, 4.5))
sub = Fd[(Fd.kind == "FRQ_HIGH") & (Fd.siting == "O") & (Fd.pair_class == "clear-clear")]
data_, labs = [], []
for s, g in sub.groupby("set"):
    data_.append(g.T_707.to_numpy()); labs.append(f"{s}\n(n={len(g)})")
if data_:
    ax.boxplot(data_, tick_labels=labs, showfliers=False)
ax.axhline(0, color="k", lw=0.8); ax.set_ylabel("T = residual(high f) - residual(low f) (dB)")
ax.set_title("D23c: 707 matched high-frequency residual contrast, open, clear at both"); fig.tight_layout()
fig.savefig(OUTC / "frequency_residual_rev1.png", dpi=130); plt.close(fig)

lc = ["D23c: matched-frequency residual contrasts (B23). Development data only; not a scored run.", "",
      f"Registered frequency pairs: {len(Fq)} (high-band {int((Fq.kind == 'FRQ_HIGH').sum())}, low-band {int((Fq.kind == 'FRQ_LOW').sum())}); both rows detected: {int(Fq.detected_pair.sum())}.",
      "T = (measured - predicted at the high frequency) - (measured - predicted at the low frequency); positive = additional high-frequency underprediction. "
      "FSPL cancels (verified with listed versus profile distance, max difference "
      f"{cancel.max():.1e} dB). Primary pair: lowest and highest eligible frequency with equal structural heights, high frequency above 3 GHz and ratio at least 2 (planner-chosen octave rule).", "",
      "Equal-height rule outcome: R1/R2/R3 transmitter height changes from 6.6 m to 7.3 m between 751 and 910 MHz, so primary pairs there span 910 to 9190 MHz only (about 3.3 octaves).", ""]
for coh in cohort_frames(Fd):
    lc += [f"## Cohort: {coh}", "", "Primary: open siting, clear at both frequencies, high band, model 707.", "",
           "| Site | pairs | bases | mean T (dB) | interval | status |", "| --- | --- | --- | --- | --- | --- |"]
    for site in ["R1", "R2", "R3", "VA"]:
        c = cells_c.get(coh, {}).get(site)
        if c is None or c["n_pairs"] == 0:
            lc.append(f"| {site} | 0 | 0 | n/a | n/a | no pairs |")
        else:
            iv_s = "n/a" if not np.isfinite(c["lo"]) else f"[{c['lo']:+.2f}, {c['hi']:+.2f}]"
            lc.append(f"| {site} | {c['n_pairs']} | {c['n_bases']} | {c['mean']:+.2f} | {iv_s} | {c['disp']} {c['note']} |")
    d, why = dispC[coh]
    lc += ["", f"**Disposition ({coh}): {d}**. {why}.", ""]
    for sname in ["O blocked-blocked", "O transition", "C"]:
        lc.append(f"{sname} (high band, 707):")
        for site in ["R1", "R2", "R3", "VA"]:
            c = SC[(SC.kind == "FRQ_HIGH") & (SC.cohort == coh) & (SC.stratum == sname) & (SC.set == site) & (SC.model == "707")]
            if len(c) and c.iloc[0].n_pairs:
                c = c.iloc[0]
                lc.append(f"  {site}: {int(c.n_pairs)} pairs, {int(c.n_bases)} bases, mean T {c['mean']:+.2f} dB" + (f" [{c.lo:+.2f}, {c.hi:+.2f}]" if np.isfinite(c.lo) else "") + f" ({c.disp})")
        lc.append("")
lc += ["Low-band secondary contrasts (both frequencies at most 1 GHz, ratio at least 2) and the stock and R02 models are in site_stats_rev1.csv.", "",
       "## Components (report only; raw differences before clipping are not causal final-loss contributions)", "",
       Fd[(Fd.kind == "FRQ_HIGH") & (Fd.siting == "O")].groupby("set").agg(pairs=("pair_id", "size"), mean_dA_ref=("dA_ref", "mean"), mean_dA_s=("dA_s", "mean"),
                                                                           bound_changes=("bound_changes", "sum")).round(2).to_string(),
       "", "No frequency multiplier or offset is fitted. Where only the exploratory cohort shows a pattern it is labelled exploratory. "
       "An observed pattern alone cannot identify unmodeled clutter or a diffraction mechanism."]
(OUTC / "summary.txt").write_text("\n".join(lc) + "\n")
print("\n".join(la[:30])); print("..."); print("\n".join(lb[:60])); print("..."); print("\n".join(lc[:40]))
json.dump(dict(D23a={k: list(v) for k, v in dispA.items()}, D23c={k: list(v) for k, v in dispC.items()}, D23b={k: list(v) for k, v in dec2.items()}),
          open(ROOT / "experiments/D23m-metadata-audit/dispositions_rev1.json", "w"), indent=1)
