"""D23m (B23): metadata manifest, raw-key reconstruction, eligibility tiers, pair registry.

Usage: python3 -I experiments/batches/b23_manifest_rev1.py

Rebuilds the raw-to-frozen mapping of data/build_links_rev1.m from
data/raw/its_phase2.zip (extracted to a temporary directory), checks it against
data/links/phase2_links_rev1.csv on every row (runs, censor flag, link_id, median
to 1e-9 dB), classifies geometry from the frozen profiles, assigns eligibility
tiers from public report provenance, and freezes the pair registry for D23a and
D23c BEFORE any prediction or residual is read. Measured outcomes are written to
a separate file. Development data only. Stops on any mismatch.
"""
import hashlib
import json
import math
import platform
import sys
import tempfile
import zipfile
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
import b23_common_rev1 as C  # noqa: E402

ROOT = C.ROOT
OUT = ROOT / "experiments" / "D23m-metadata-audit"
OUT.mkdir(parents=True, exist_ok=True)
RAW_SHA = "30e611b88b2188aedbe408c04b05e90dd52e35f2512c3bcf6d120142458ac668"

# ---- Provenance of each set (public reports, read 2026-11-24; see summary.txt) -------------
# Documented fields only. "unknown" is not evidence of equivalence (B23 section 3.2).
PROV = {
    "R1": dict(pol_doc="horizontal", pol_src="ERL 65-ITS 58 Pt I, Sec. 2, p. 6 ('horizontal polarization only')",
               cal_src="Pt I Sec. 3, p. 22 (receiver calibrated at start and end of each site's recording)",
               co_note="Pt I Sec. 5, pp. 26-27: unlogged open/concealed transmitter impedance change, estimated <= ~2 dB",
               tier="strict"),
    "R2": dict(pol_doc="not stated in the text read (Pt II defers equipment and procedures to Pt I)",
               pol_src="ERL 65-ITS 58-2, pp. 2-3 refer to Part I", cal_src="by reference to Part I only",
               co_note="no open/concealed error estimate found in text read", tier="limited"),
    "R3": dict(pol_doc="horizontal", pol_src="ERL 65-ITS 58-3, Sec. 2, p. 6 ('horizontal polarization only')",
               cal_src="calibration procedure not found in the text read; Sec. 5 p. 15 omits curves for 'obvious calibration errors'",
               co_note="no open/concealed error estimate; Sec. 2 p. 3: companion sites <= 100 m apart, 'essentially a common terrain profile'",
               tier="limited"),
    "VA": dict(pol_doc="transmitter horizontal; receiver not stated",
               pol_src="NTIA 91-282, Sec. 2.1, p. 7", cal_src="Sec. 2.2 p. 7, Sec. 3 p. 8 (signal-generator calibration; recorders in 5 dB steps)",
               co_note="Hi/Lo receiver heights not defined in the report text read", tier="limited"),
}
TIER_REASON = {"R1": "polarization and calibration documented in the set's own report",
               "R2": "polarization not documented in the text read",
               "R3": "polarization documented; calibration/hardware compatibility not established in the text read",
               "VA": "receiver polarization not documented"}


def die(msg):
    raise SystemExit("B23 manifest STOP: " + msg)


# ---- Frozen inputs ---------------------------------------------------------------------
prov = {"git_head": None, "python": platform.python_version(), "numpy": np.__version__, "pandas": pd.__version__,
        "seed": C.SEED}
import subprocess  # noqa: E402
prov["git_head"] = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
folds_sha = C.sha256_file(ROOT / "data/splits/folds_rev1.csv")
if folds_sha != (ROOT / "data/splits/folds_rev1.sha256").read_text().strip():
    die("folds hash mismatch")
if C.sha256_file(ROOT / "data/raw/its_phase2.zip") != RAW_SHA:
    die("raw archive hash mismatch")
links = pd.read_csv(ROOT / "data/links/phase2_links_rev1.csv")
idx = pd.read_csv(ROOT / "data/profiles/profiles_index_rev1.csv")
idx = idx[idx.dataset == "phase2"].set_index("path_id")
if links.link_id.duplicated().any():
    die("duplicate link_id in frozen table")
n_err = int(links.itm_error.notna().sum())
inscope = links[links.itm_error.isna()].copy()    # run_eval_rev1 baseline_ok: rows with a baseline error are out of scope
prov.update(links_sha256=C.sha256_file(ROOT / "data/links/phase2_links_rev1.csv"), folds_sha256=folds_sha,
            raw_zip_sha256=RAW_SHA, profile_index_sha256=C.sha256_file(ROOT / "data/profiles/profiles_index_rev1.csv"),
            n_frozen_rows=len(links), n_baseline_error_rows=n_err, n_inscope=len(inscope))

# ---- Raw reconstruction (mirrors build_phase2 in data/build_links_rev1.m) ------------------------
tmp = Path(tempfile.mkdtemp(prefix="b23_raw_"))
with zipfile.ZipFile(ROOT / "data/raw/its_phase2.zip") as z:
    for nme in z.namelist():
        if nme.startswith("phase_2/") and nme.endswith(".txt"):
            z.extract(nme, tmp)
rawdir = tmp / "phase_2"


def read_set(s):
    va = s == "va"
    pars = np.loadtxt(rawdir / f"{s}pars.txt", skiprows=1)
    P = []
    for ln in (rawdir / f"{s}path.txt").read_text().splitlines()[1:]:
        t = ln.split()
        if not t:
            continue
        if va:
            P.append(dict(path=t[0], site="", xlat=float(t[1]), xlon=float(t[2]), rlat=float(t[3]), rlon=float(t[4]), dist=float(t[5])))
        else:
            P.append(dict(path=t[0], site=t[1], xlat=float(t[2]), xlon=float(t[3]), rlat=float(t[4]), rlon=float(t[5]), dist=float(t[6])))
    D = []
    for ln in (rawdir / f"{s}data.txt").read_text().splitlines()[2:]:
        t = ln.split()
        if not t:
            continue
        if va:
            D.append(dict(path=t[0], run=int(t[1]), siting=t[2], rcvr=int(t[3]), rht=t[4], A=[float(v) for v in t[5:12]]))
        else:
            D.append(dict(path=t[0], run=int(t[1]), siting=t[2], rcvr=0, rht=float(t[3]), A=[float(v) for v in t[4:11]]))
    return pars, pd.DataFrame(P), D


recs, outcomes, raw_unmatched = [], [], []
for s in ["r1", "r2", "r3", "va"]:
    va = s == "va"
    pars, Pp, D = read_set(s)
    F = pars[:, 0]
    keys = list(dict.fromkeys((d["path"], d["siting"]) for d in D))         # unique rows, stable order
    seen_raw = set()
    for pth, site in keys:
        if va:
            ipp = Pp[Pp.path == pth]
        else:
            ipp = Pp[(Pp.path == pth) & (Pp.site == site)]
            if ipp.empty:
                ipp = Pp[Pp.path == pth]
        if ipp.empty:
            raw_unmatched.append((s.upper(), pth, site, "no path-file entry"))
            continue
        ip = ipp.iloc[0]
        path_id = f"P2_{s.upper()}_{pth.replace(chr(39), '_')}_{site}"
        R = [d for d in D if d["path"] == pth and d["siting"] == site]
        if va:
            cfgs = sorted({(d["rcvr"], d["rht"]) for d in R})
        else:
            cfgs = sorted({d["rht"] for d in R})
        for j, f in enumerate(F):
            if j > 0 and f == F[j - 1]:
                continue
            htx = pars[j, 1]
            for c, cf in enumerate(cfgs, start=1):
                if va:
                    rc, rh = cf
                    hrx = pars[j, 4] if rh == "Lo" else pars[j, 1 + rc]
                    sel = [d for d in R if d["rcvr"] == rc and d["rht"] == rh]
                else:
                    rc, rh = 0, cf
                    hrx = rh
                    sel = [d for d in R if d["rht"] == rh]
                a = np.array([d["A"][j] for d in sel])
                runs_idx = np.array([d["run"] for d in sel])
                a = a[a < 999]
                if a.size == 0:
                    raw_unmatched.append((s.upper(), pth, site, f"no valid values at {f:g} MHz cfg {c}"))
                    continue
                flagged = a >= 500
                lowv = np.where(flagged, a - 500, a)
                fs = 32.45 + 20 * math.log10(f) + 20 * math.log10(ip.dist)
                link_id = "%s_f%g_h%g_c%d" % (path_id, f, hrx, c)
                if link_id in seen_raw:
                    die(f"duplicate raw key {link_id}")
                seen_raw.add(link_id)
                lo, hi = C.median_interval(lowv, flagged)
                recs.append(dict(link_id=link_id, set=s.upper(), path_id=path_id, raw_path=pth, raw_site=site, raw_rcvr=rc,
                                 raw_rht=rh, freq_index=j + 1, cfg_index=c, f_mhz=f, htx_m=htx, hrx_m=hrx,
                                 xlat=ip.xlat, xlon=ip.xlon, rlat=ip.rlat, rlon=ip.rlon, listed_dist_km=ip.dist,
                                 n_runs=int(a.size), n_flagged=int(flagged.sum()), censored_raw=int(flagged.any())))
                outcomes.append(dict(link_id=link_id, fs_db=fs, meas_median_db=fs + float(np.median(lowv)),
                                     lb_lo_db=fs + lo, lb_hi_db=(fs + hi) if hi != math.inf else math.inf))
M = pd.DataFrame(recs)
O = pd.DataFrame(outcomes)

# ---- Reconcile with the frozen table (hard fail on any join mismatch) -----------------------------
fz = links.set_index("link_id")
miss_in_raw = sorted(set(links.link_id) - set(M.link_id))
if miss_in_raw:
    die(f"{len(miss_in_raw)} frozen rows not reproduced from the raw archive, e.g. {miss_in_raw[:3]}")
extra = M[~M.link_id.isin(links.link_id)]
M = M[M.link_id.isin(links.link_id)].copy()
O = O[O.link_id.isin(M.link_id)].copy()
M = M.set_index("link_id").loc[links.link_id].reset_index()
O = O.set_index("link_id").loc[links.link_id].reset_index()
J = fz.loc[M.link_id]
chk = dict(
    runs=int((J.runs.to_numpy() != M.n_runs.to_numpy()).sum()),
    censored=int((J.censored.to_numpy() != M.censored_raw.to_numpy()).sum()),
    set=int((J.set.to_numpy() != M.set.to_numpy()).sum()),
    htx=int((np.abs(J.htx_m.to_numpy() - M.htx_m.to_numpy()) > 1e-12).sum()),
    hrx=int((np.abs(J.hrx_m.to_numpy() - M.hrx_m.to_numpy()) > 1e-12).sum()),
    f=int((np.abs(J.f_mhz.to_numpy() - M.f_mhz.to_numpy()) > 1e-12).sum()),
    d_km=int((np.abs(J.d_km.to_numpy() - M.listed_dist_km.to_numpy()) > 1e-12).sum()),
    median=int((np.abs(J.meas_lb_db.to_numpy() - O.meas_median_db.to_numpy()) > 1e-9).sum()),
    fs=int((np.abs(J.fs_db.to_numpy() - O.fs_db.to_numpy()) > 1e-9).sum()),
)
if any(chk.values()):
    die(f"raw reconstruction differs from the frozen table: {chk}")
prov["raw_reconstruction_mismatches"] = chk
prov["raw_rows_reconstructed"] = int(len(recs))
prov["raw_rows_without_frozen_row"] = int(len(extra))

# ---- Manifest fields ------------------------------------------------------------------------------
M["siting"] = J.siting.to_numpy()
M["pol_frozen"] = J.pol.to_numpy()
M["climate"] = J.climate.to_numpy()
M["N_0"] = J.N_0.to_numpy()
M["profile_km"] = J.profile_km.to_numpy()
M["physical_base_id"] = M.path_id.str.rsplit("_", n=1).str[0]
M["fold"] = M.set.map({"R1": 1, "R2": 2, "R3": 3, "VA": 4})
# mobile end (core clutter_terminal): TX in R1-R3, RX in VA
M["mobile_end"] = np.where(M.set == "VA", "RX", "TX")
M["mobile_h_m"] = np.where(M.set == "VA", M.hrx_m, M.htx_m)
M["fixed_h_m"] = np.where(M.set == "VA", M.htx_m, M.hrx_m)
M["fixed_terminal_id"] = np.where(M.set == "VA", M.xlat.map("{:.4f}".format) + "," + M.xlon.map("{:.4f}".format),
                                  M.rlat.map("{:.4f}".format) + "," + M.rlon.map("{:.4f}".format))
M["fixed_terminal_id"] = M.set + ":" + M.fixed_terminal_id
M["mobile_lat"] = np.where(M.set == "VA", M.rlat, M.xlat)
M["mobile_lon"] = np.where(M.set == "VA", M.rlon, M.xlon)
M["pol_documented"] = M.set.map({k: v["pol_doc"] for k, v in PROV.items()})
M["tier"] = M.set.map({k: v["tier"] for k, v in PROV.items()})
M["tier_reason"] = M.set.map(TIER_REASON)
M["prov_pol_source"] = M.set.map({k: v["pol_src"] for k, v in PROV.items()})
M["in_scope"] = ~M.link_id.isin(links[links.itm_error.notna()].link_id)

# profile hash check and geometry
geo = {}
phash = {}
for pid in sorted(M.path_id.unique()):
    fpath = ROOT / "data/profiles/phase2" / f"{pid}.csv"
    if not fpath.exists():
        die(f"profile missing for {pid}")
    h = C.sha256_file(fpath)
    if h != idx.loc[pid, "sha256"]:
        die(f"profile hash mismatch for {pid}")
    phash[pid] = h
    z = np.loadtxt(fpath, skiprows=1)
    geo[pid] = (z, float(idx.loc[pid, "spacing_m"]))
M["profile_sha256"] = M.path_id.map(phash)
rows = []
for r in M.itertuples():
    z, sp = geo[r.path_id]
    ge, Ns, hsys = C.effective_curvature(z, sp, r.N_0)
    mc, nf = C.clearance(z, sp, r.htx_m, r.hrx_m, ge, r.f_mhz)
    rows.append((ge, Ns, hsys, (len(z) - 1) * sp / 1000, mc, nf, C.geom_class(mc)))
G = pd.DataFrame(rows, columns=["gamma_e", "N_s", "h_sys_m", "profile_d_km", "min_clear_m", "min_clear_f1", "geom_class"])
for c in G.columns:
    M[c] = G[c].to_numpy()
M["clear_f1_ge_0p6"] = M.min_clear_f1 >= 0.6

# ---- Exclusion counts ----------------------------------------------------------------------------------
excl = [("frozen rows", len(links)), ("baseline-error rows (out of scope, as run_eval_rev1)", n_err),
        ("raw (path,siting,config,frequency) rows with no frozen row", len(extra))]
for k, v in pd.Series([u[3].split(" at ")[0] for u in raw_unmatched]).value_counts().items():
    excl.append((f"raw combinations skipped by the builder: {k}", int(v)))
pd.DataFrame(excl, columns=["item", "count"]).to_csv(OUT / "exclusion_counts_rev1.csv", index=False)

# ---- Pair registry (metadata only; no prediction or residual read) --------------------------------------
Ms = M[M.in_scope].copy()
registry = []


def add_pair(kind, lo_r, hi_r, why):
    registry.append(dict(kind=kind, pair_id=f"{kind}|{lo_r.link_id}|{hi_r.link_id}", set=lo_r.set, tier=lo_r.tier,
                         siting=lo_r.siting, physical_base_id=lo_r.physical_base_id, fixed_terminal_id=lo_r.fixed_terminal_id,
                         low_link_id=lo_r.link_id, high_link_id=hi_r.link_id,
                         low_f_mhz=lo_r.f_mhz, high_f_mhz=hi_r.f_mhz,
                         low_htx=lo_r.htx_m, high_htx=hi_r.htx_m, low_hrx=lo_r.hrx_m, high_hrx=hi_r.hrx_m,
                         low_class=lo_r.geom_class, high_class=hi_r.geom_class,
                         pair_class=(lo_r.geom_class + "-" + hi_r.geom_class if lo_r.geom_class == hi_r.geom_class else "transition"),
                         low_min_clear_f1=lo_r.min_clear_f1, high_min_clear_f1=hi_r.min_clear_f1, selection=why))


def sel_height(df):
    # D23a: group by base, siting, frequency, unchanged endpoint height, polarization; vary one end only
    n_amb = 0
    for (base, site, f), g in df.groupby(["physical_base_id", "siting", "f_mhz"], sort=True):
        # Candidate changed ends: RX (fixed terminal in R1-R3; mobile in VA) or TX
        for end, other in (("hrx_m", "htx_m"), ("htx_m", "hrx_m")):
            extra_keys = ["raw_rcvr"] if g.set.iloc[0] == "VA" else []
            for _, gg in g.groupby([other, "pol_frozen"] + extra_keys):
                hs = sorted(gg[end].unique())
                if len(hs) < 2:
                    continue
                lo_h, hi_h = hs[0], hs[-1]
                a, b = gg[gg[end] == lo_h], gg[gg[end] == hi_h]
                if len(a) != 1 or len(b) != 1:
                    n_amb += 1
                    continue                       # ambiguous: duplicate configuration at one height; excluded
                ra, rb = a.iloc[0], b.iloc[0]
                add_pair(f"HGT_{end[1:3].upper()}", ra, rb, f"lowest/highest {end}")
    return n_amb


def sel_freq(df, high_min=3000.0, band="high"):
    for (base, site), g in df.groupby(["physical_base_id", "siting"], sort=True):
        extra_keys = ["raw_rcvr", "raw_rht"] if g.set.iloc[0] == "VA" else ["hrx_m"]
        keys = ["htx_m", "hrx_m", "pol_frozen"] + (["raw_rcvr"] if g.set.iloc[0] == "VA" else [])
        for _, gg in g.groupby(keys):
            gg = gg.sort_values("f_mhz")
            if band == "high":
                cand = gg[gg.f_mhz > 0]
                lo_r, hi_r = cand.iloc[0], cand.iloc[-1]
                if not (hi_r.f_mhz > high_min and hi_r.f_mhz / lo_r.f_mhz >= 2):
                    continue
            else:
                cand = gg[gg.f_mhz <= 1000]
                if len(cand) < 2:
                    continue
                lo_r, hi_r = cand.iloc[0], cand.iloc[-1]
                if hi_r.f_mhz / lo_r.f_mhz < 2:
                    continue
            if gg.f_mhz.duplicated().any():
                continue                           # ambiguous duplicate frequency in a group
            add_pair("FRQ_" + band.upper(), lo_r, hi_r, "lowest/highest eligible frequency, equal heights")


n_amb = sel_height(Ms)
sel_freq(Ms, band="high")
sel_freq(Ms, band="low")
Rg = pd.DataFrame(registry)

# D23b registry: original D20c C/O twin pairs (replay) from metadata only
Cx = Ms[Ms.siting == "C"].set_index(["physical_base_id", "f_mhz", "htx_m", "hrx_m"])
Ox = Ms[Ms.siting == "O"].set_index(["physical_base_id", "f_mhz", "htx_m", "hrx_m"])
co = Cx.join(Ox, lsuffix="_c", rsuffix="_o", how="inner").reset_index()
if co.duplicated(["physical_base_id", "f_mhz", "htx_m", "hrx_m"]).any():
    die("C/O pairs are not one-to-one")
CO = pd.DataFrame(dict(pair_id="CO|" + co.link_id_c + "|" + co.link_id_o, set=co.set_c, tier=co.tier_c,
                       physical_base_id=co.physical_base_id, fixed_terminal_id=co.fixed_terminal_id_c,
                       link_id_c=co.link_id_c, link_id_o=co.link_id_o, f_mhz=co.f_mhz, htx_m=co.htx_m, hrx_m=co.hrx_m,
                       mobile_h_m=co.mobile_h_c if "mobile_h_c" in co else co.mobile_h_m_c,
                       profile_c=co.profile_sha256_c, profile_o=co.profile_sha256_o,
                       same_profile=co.profile_sha256_c == co.profile_sha256_o,
                       mobile_lat_c=co.mobile_lat_c, mobile_lon_c=co.mobile_lon_c,
                       mobile_lat_o=co.mobile_lat_o, mobile_lon_o=co.mobile_lon_o,
                       dist_c=co.listed_dist_km_c, dist_o=co.listed_dist_km_o, profile_km_c=co.profile_km_c,
                       profile_km_o=co.profile_km_o))
# independent checks required by section 5: the twins' profiles and distances are recorded, not assumed shared
prov["co_pairs"] = int(len(CO))
prov["co_pairs_same_profile_hash"] = int(CO.same_profile.sum())
prov["co_pairs_different_mobile_coordinates"] = int(((CO.mobile_lat_c != CO.mobile_lat_o) | (CO.mobile_lon_c != CO.mobile_lon_o)).sum())
prov["co_pairs_different_listed_distance"] = int((CO.dist_c != CO.dist_o).sum())

# Grouping tests (section 8): shuffle invariance and an injected duplicate
sh = Ms.sample(frac=1.0, random_state=1).reset_index(drop=True)
bak = list(registry)
registry.clear()
sel_height(sh); sel_freq(sh, band="high"); sel_freq(sh, band="low")
Rg2 = pd.DataFrame(registry)
registry.clear(); registry.extend(bak)
if set(Rg2.pair_id) != set(Rg.pair_id):
    die("pair selection depends on row order")
dupe = pd.concat([Ms, Ms.iloc[[0]]], ignore_index=True)
if dupe.link_id.duplicated().sum() != 1:
    die("duplicate injection test failed")
prov["selection_shuffle_invariant"] = True
prov["height_groups_excluded_ambiguous"] = int(n_amb)

# ---- Write ------------------------------------------------------------------------------------------------
man_cols = [c for c in M.columns if c not in ("xlat", "xlon", "rlat", "rlon", "listed_dist_km")]
M[man_cols + ["xlat", "xlon", "rlat", "rlon", "listed_dist_km"]].to_csv(OUT / "manifest_rev1.csv", index=False)
O.to_csv(OUT / "outcomes_rev1.csv", index=False)           # outcome fields kept apart from the manifest
M[["link_id", "set", "raw_path", "raw_site", "raw_rcvr", "raw_rht", "freq_index", "cfg_index", "n_runs", "n_flagged"]].to_csv(
    OUT / "raw_run_map_rev1.csv", index=False)
Rg.to_csv(OUT / "pair_registry_rev1.csv", index=False)
CO.to_csv(OUT / "co_pair_registry_rev1.csv", index=False)
reg_sha = C.sha256_file(OUT / "pair_registry_rev1.csv")
prov["pair_registry_sha256"] = reg_sha
prov["co_pair_registry_sha256"] = C.sha256_file(OUT / "co_pair_registry_rev1.csv")
prov["manifest_sha256"] = C.sha256_file(OUT / "manifest_rev1.csv")
prov["tiers"] = {k: dict(tier=v["tier"], polarization=v["pol_doc"], polarization_source=v["pol_src"],
                         calibration=v["cal_src"], co_note=v["co_note"]) for k, v in PROV.items()}
prov["profiles_hashed"] = len(phash)
(OUT / "provenance_rev1.json").write_text(json.dumps(prov, indent=1, default=str))

cnt = Rg.groupby(["kind", "set", "tier", "siting"]).size().rename("pairs").reset_index()
lines = ["D23m: metadata audit and pair registry (B23)", "",
         f"Frozen rows {len(links)}; in scope {len(inscope)} (baseline-error rows excluded: {n_err}).",
         f"Raw reconstruction: {len(recs)} rows rebuilt; frozen rows reproduced {len(M)} of {len(links)}; mismatches {chk}.",
         f"Raw (path,siting,config,frequency) rows with no frozen row: {len(extra)}.",
         f"Profiles hashed and matched to the index: {len(phash)}.", "",
         "## Provenance tiers (fixed before outcomes)", ""]
for k, v in PROV.items():
    lines.append(f"- {k}: **{v['tier']}**. Polarization: {v['pol_doc']} [{v['pol_src']}]. Calibration: {v['cal_src']}. {v['co_note']}.")
lines += ["", "Strict needs documented polarization and calibration in the set's own report; only R1 meets it. Limited keeps the "
          "frozen-input match but leaves a historical comparability field unknown. Text of each report was read only to "
          "its first 100,000 characters; R2/R3/VA fields reported as 'not found' are 'not found in the text read'.", "",
          "## Twin facts (C/O pairs)", "",
          f"C/O pairs: {len(CO)}; same profile hash: {prov['co_pairs_same_profile_hash']}; "
          f"different mobile coordinates: {prov['co_pairs_different_mobile_coordinates']}; different listed distance: {prov['co_pairs_different_listed_distance']}.", "",
          "## Registered pairs", "", cnt.to_string(index=False), "",
          f"Ambiguous height groups excluded: {n_amb}. Pair selection is invariant to row order.",
          f"Pair registry SHA-256: {reg_sha}"]
(OUT / "summary.txt").write_text("\n".join(lines) + "\n")
print("\n".join(lines))
