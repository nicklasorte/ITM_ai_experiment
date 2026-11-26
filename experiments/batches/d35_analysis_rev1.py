#!/usr/bin/env python3
"""B35 (D35) registered analysis: ITS Phase 2 site R4, 707 against stock ITM.

Usage:
    python3 -I d35_analysis_rev1.py --selftest
    python3 -I d35_analysis_rev1.py <repo root> <out dir>

The rule is experiments/batches/B35.md section 3. The real run reads the
measured values in data/raw/its_phase2.zip (phase_2/r4data.txt) and the
committed model predictions in experiments/D35-r4-grove/predictions_rev1.csv
(checked against predictions_rev1.sha256 first). Don't run it on real data
until Nick has decided how R4 is used (phase plan rev 6, decision 1).

Script details that section 3 leaves open, fixed here before any value is
read: slopes use cells that are neither missing nor censored and need at
least 6 of the 11 in-canopy heights; per-frequency and split intervals use
the descriptive generator in the order section 3 lists; bearings are from
the receiver to the transmitter on a sphere.
"""
import csv
import hashlib
import io
import json
import math
import os
import sys
import zipfile

import numpy as np

FREQS = [230, 410, 910, 1846, 4595, 9190]
IN_H = list(range(2, 13))          # in canopy, 11 heights
TOP_H = [21, 22, 23, 24]           # top of tower, 4 heights
E2_FREQS = [230, 410, 910, 1846]
SEASONS = ["S", "W"]               # S leaves on, W leaves off
ARMS = ["stock", "707O", "707C"]
N_BOOT = 2000
SEED_DECIDE = 20261126
SEED_DESC = 20261127
RES_DB = 1.0
FLOOR_PATHS = 20
DROP_SHARE = 0.20
SECTOR = (205.0, 265.0)
P833 = (1.37, 0.42, 2117.5)        # ITU-R P.833-10 eq. (2), St. Petersburg; f in MHz


# ---------- input ----------
def read_measurements(zip_path):
    """{(path, season, h, f): (kind, value)}; kind 'ok', 'cens' (value = bound) or 'miss'."""
    with zipfile.ZipFile(zip_path) as z:
        text = z.read("phase_2/r4data.txt").decode()
    out = {}
    for line in text.splitlines()[1:]:
        t = line.split()
        if not t or t[0].startswith("-"):
            continue
        if len(t) != 9:
            raise SystemExit(f"r4data.txt line without nine fields: {line[:30]}")
        path, season, h = t[0], t[1], int(float(t[2]))
        for f, v in zip(FREQS, t[3:]):
            v = float(v)
            if v >= 999:
                out[(path, season, h, f)] = ("miss", None)
            elif v >= 500:
                out[(path, season, h, f)] = ("cens", v - 500)
            else:
                out[(path, season, h, f)] = ("ok", v)
    return out


def read_predictions(root):
    d = os.path.join(root, "experiments", "D35-r4-grove")
    want = {}
    for line in open(os.path.join(d, "predictions_rev1.sha256")):
        hsh, name = line.split()
        want[name] = hsh
    for name, hsh in want.items():
        got = hashlib.sha256(open(os.path.join(d, name), "rb").read()).hexdigest()
        if got != hsh:
            raise SystemExit(f"{name} doesn't match its committed SHA-256; the predictions must be the committed ones.")
    pred = {}
    for r in csv.DictReader(open(os.path.join(d, "predictions_rev1.csv"))):
        pred[(r["path"], int(float(r["rx_ant_m"])), int(float(r["f_mhz"])))] = {
            "stock": float(r["A_stock_db"]), "707O": float(r["A_707O_db"]), "707C": float(r["A_707C_db"]),
            "mode": int(float(r["mode_707O"]))}
    paths = {}
    for r in csv.DictReader(open(os.path.join(d, "paths_rev1.csv"))):
        paths[r["Path"]] = bearing(float(r["Rlat"]), float(r["Rlon"]), float(r["Xlat"]), float(r["Xlon"]))
    return pred, paths


def bearing(lat1, lon1, lat2, lon2):
    p1, p2, dl = math.radians(lat1), math.radians(lat2), math.radians(lon2 - lon1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(y, x)) + 360) % 360


# ---------- group values ----------
def group_value(meas, path, season, f, heights):
    """Return (value, reason); reason in ok, missing, censored, bound."""
    cells = [meas[(path, season, h, f)] for h in heights]
    if any(k == "miss" for k, _ in cells):
        return None, "missing"
    ok = sorted(v for k, v in cells if k == "ok")
    bounds = [v for k, v in cells if k == "cens"]
    n = len(cells)
    # censored cells rank above every uncensored cell
    if n % 2:
        m = n // 2                       # 0-based median position
        if m >= len(ok):
            return None, "censored"
        med_cells = [ok[m]]
    else:
        m1, m2 = n // 2 - 1, n // 2
        if m2 >= len(ok):
            return None, "censored"
        med_cells = [ok[m1], ok[m2]]
    if bounds and max(med_cells) > min(bounds):
        return None, "bound"
    return float(np.mean(med_cells)), "ok"


def model_group(pred, path, f, heights, arm):
    v = sorted(pred[(path, h, f)][arm] for h in heights)
    n = len(v)
    return v[n // 2] if n % 2 else 0.5 * (v[n // 2 - 1] + v[n // 2])


# ---------- bootstrap ----------
def boot_mean(paths_sorted, cell_path, values, idx):
    """Means of values over resampled paths; idx is (N_BOOT, n_paths) indices into paths_sorted."""
    pos = {p: i for i, p in enumerate(paths_sorted)}
    by = [[] for _ in paths_sorted]
    for p, v in zip(cell_path, values):
        by[pos[p]].append(v)
    s = np.array([sum(b) for b in by])
    c = np.array([len(b) for b in by])
    num = s[idx].sum(axis=1)
    den = c[idx].sum(axis=1)
    if np.any(den == 0):
        raise SystemExit("A bootstrap draw has no cells; the support is too small for this interval.")
    return num / den


def summarize(paths_sorted, cell_path, values, rng, over="all"):
    """over="all": draws over every path in paths_sorted (the two deciding intervals, B35 section 3).
    over="support": draws over the sorted paths that have cells (every descriptive interval)."""
    values = np.asarray(values, float)
    if over == "support":
        paths_sorted = sorted(set(cell_path))
    n = max(len(paths_sorted), 1)
    idx = rng.integers(0, n, size=(N_BOOT, n))   # drawn even when empty, so later intervals keep their draws
    if len(values) == 0:
        return {"n_cells": 0, "n_paths": 0, "mean": None, "lo95": None, "hi95": None, "resolved": False}
    b = boot_mean(paths_sorted, cell_path, values, idx)
    lo, hi = np.percentile(b, [2.5, 97.5])
    m = float(values.mean())
    return {"n_cells": int(len(values)), "n_paths": len(set(cell_path)), "mean": m, "lo95": float(lo),
            "hi95": float(hi), "resolved": bool(abs(m) >= RES_DB and (lo > 0 or hi < 0))}


# ---------- analysis ----------
def analyse(meas, pred, bearings):
    paths = sorted(bearings)
    support = []
    gv = {}       # (path, season, f, group) -> measured value
    for p in paths:
        for s in SEASONS:
            for f in FREQS:
                for g, hs in (("in", IN_H), ("top", TOP_H)):
                    v, why = group_value(meas, p, s, f, hs)
                    gv[(p, s, f, g)] = v
                    support.append({"path": p, "season": s, "f_mhz": f, "group": g, "reason": why})

    rng_d = np.random.default_rng(SEED_DECIDE)
    rng_x = np.random.default_rng(SEED_DESC)

    # E1 cells: top group, season W
    e1_cells = {f: [(p, gv[(p, "W", f, "top")]) for p in paths if gv[(p, "W", f, "top")] is not None] for f in FREQS}
    floored = [f for f in FREQS if len({p for p, _ in e1_cells[f]}) < FLOOR_PATHS]
    pooled_f = [f for f in FREQS if f not in floored]
    cp, d1v, es, e7 = [], [], [], []
    for f in pooled_f:
        for p, meas_v in e1_cells[f]:
            s_ = model_group(pred, p, f, TOP_H, "stock") - meas_v
            o_ = model_group(pred, p, f, TOP_H, "707O") - meas_v
            cp.append(p); d1v.append(abs(o_) - abs(s_)); es.append(s_); e7.append(o_)
    n_attempt = len(pooled_f) * len(paths)
    drop1 = 1 - len(d1v) / n_attempt if n_attempt else 1.0
    D1 = summarize(paths, cp, d1v, rng_d)
    m_s = float(np.mean(es)) if es else None
    m_7 = float(np.mean(e7)) if e7 else None
    if drop1 > DROP_SHARE or not d1v:
        e1_out = "descriptive (no label)"
    elif D1["resolved"] and D1["mean"] < 0:
        e1_out = "A by added loss" if (m_s < -RES_DB and m_7 > m_s) else "A"
    elif D1["resolved"] and D1["mean"] > 0:
        e1_out = "B"
    else:
        e1_out = "C"

    # E2 cells: K = A(in) - A(top), 230-1846 MHz, both seasons
    def e2_cells(freqs, seasons, sel=lambda p: True):
        cp2, dv, e7c, e7o = [], [], [], []
        att = 0
        for f in freqs:
            for s in seasons:
                for p in paths:
                    if not sel(p):
                        continue
                    att += 1
                    a, b = gv[(p, s, f, "in")], gv[(p, s, f, "top")]
                    if a is None or b is None:
                        continue
                    km = a - b
                    kc = model_group(pred, p, f, IN_H, "707C") - model_group(pred, p, f, TOP_H, "707C")
                    ko = model_group(pred, p, f, IN_H, "707O") - model_group(pred, p, f, TOP_H, "707O")
                    cp2.append(p); dv.append(abs(kc - km) - abs(ko - km)); e7c.append(kc - km); e7o.append(ko - km)
        return cp2, dv, e7c, e7o, att
    cp2, d2v, e7c, e7o, att2 = e2_cells(E2_FREQS, SEASONS)
    drop2 = 1 - len(d2v) / att2 if att2 else 1.0
    D2 = summarize(paths, cp2, d2v, rng_d)
    if drop2 > DROP_SHARE or not d2v:
        e2_out = "descriptive (no label)"
    elif D2["resolved"] and D2["mean"] < 0:
        e2_out = "kept term better than ITM's own height gain"
    elif D2["resolved"] and D2["mean"] > 0:
        e2_out = "worse"
    else:
        e2_out = "no clear effect"

    # ---- descriptive, generator 2, in the registered order
    e1_rows = []
    for f in FREQS:
        cpf, dvf, esf, e7f = [], [], [], []
        for p, mv in e1_cells[f]:
            s_ = model_group(pred, p, f, TOP_H, "stock") - mv
            o_ = model_group(pred, p, f, TOP_H, "707O") - mv
            cpf.append(p); dvf.append(abs(o_) - abs(s_)); esf.append(s_); e7f.append(o_)
        r = summarize(paths, cpf, dvf, rng_x, over="support")
        r.update({"f_mhz": f, "floored": f in floored, "mean_e_stock": float(np.mean(esf)) if esf else None,
                  "mean_e_707O": float(np.mean(e7f)) if e7f else None,
                  "share_identical": float(np.mean([abs(a - b) < 0.01 for a, b in zip(esf, e7f)])) if esf else None})
        e1_rows.append(r)
    # E1, season S, pooled over the same frequencies (descriptive)
    cps, dvs = [], []
    for f in pooled_f:
        for p in paths:
            mv = gv[(p, "S", f, "top")]
            if mv is None:
                continue
            cps.append(p)
            dvs.append(abs(model_group(pred, p, f, TOP_H, "707O") - mv) - abs(model_group(pred, p, f, TOP_H, "stock") - mv))
    r = summarize(paths, cps, dvs, rng_x, over="support")
    r.update({"f_mhz": "pooled, season S", "floored": None, "mean_e_stock": None, "mean_e_707O": None,
              "share_identical": None})
    e1_rows.append(r)
    modes = {"line_of_sight": 0, "single_horizon": 0, "double_horizon": 0}
    for f in pooled_f:
        for p, _ in e1_cells[f]:
            for h in TOP_H:
                m = pred[(p, h, f)]["mode"]
                modes["line_of_sight" if m < 4 else "single_horizon" if m < 8 else "double_horizon"] += 1
    e2_rows = []
    in_sector = lambda p: SECTOR[0] <= bearings[p] <= SECTOR[1]
    splits = [("4595 MHz", [4595], SEASONS, lambda p: True), ("9190 MHz", [9190], SEASONS, lambda p: True),
              ("leaves on", E2_FREQS, ["S"], lambda p: True), ("leaves off", E2_FREQS, ["W"], lambda p: True),
              ("sector 205-265", E2_FREQS, SEASONS, in_sector),
              ("other bearings", E2_FREQS, SEASONS, lambda p: not in_sector(p))]
    for name, fr, se, sel in splits:
        c, dv, ec, eo, _ = e2_cells(fr, se, sel)
        r = summarize(paths, c, dv, rng_x, over="support")
        r.update({"split": name, "mean_e_707C": float(np.mean(ec)) if ec else None,
                  "mean_e_707O": float(np.mean(eo)) if eo else None})
        e2_rows.append(r)
    e3_rows = []
    for f in FREQS:
        for g in ("in", "top", "diff"):
            c, v = [], []
            for p in paths:
                if g == "diff":
                    xs = [gv[(p, "S", f, "in")], gv[(p, "W", f, "in")], gv[(p, "S", f, "top")], gv[(p, "W", f, "top")]]
                    if None in xs:
                        continue
                    c.append(p); v.append((xs[0] - xs[1]) - (xs[2] - xs[3]))
                else:
                    a, b = gv[(p, "S", f, g)], gv[(p, "W", f, g)]
                    if a is None or b is None:
                        continue
                    c.append(p); v.append(a - b)
            r = summarize(paths, c, v, rng_x, over="support")
            r.update({"f_mhz": f, "group": g})
            e3_rows.append(r)
    slopes = []
    for f in FREQS:
        for s in SEASONS:
            ms, arm_s = [], {a: [] for a in ARMS}
            for p in paths:
                pts = [(h, meas[(p, s, h, f)][1]) for h in IN_H if meas[(p, s, h, f)][0] == "ok"]
                if len(pts) >= 6:
                    hh, vv = zip(*pts)
                    ms.append(np.polyfit(hh, vv, 1)[0])
                    for a in ARMS:                          # same paths and heights as the measured slope
                        arm_s[a].append(np.polyfit(hh, [pred[(p, h, f)][a] for h in hh], 1)[0])
            slopes.append({"f_mhz": f, "season": s, "n_paths_measured": len(ms),
                           "slope_measured": float(np.mean(ms)) if ms else None,
                           **{f"slope_{a}": (float(np.mean(arm_s[a])) if arm_s[a] else None) for a in ARMS}})
    scale = []
    for f in E2_FREQS:
        k = [gv[(p, s, f, "in")] - gv[(p, s, f, "top")] for p in paths for s in SEASONS
             if gv[(p, s, f, "in")] is not None and gv[(p, s, f, "top")] is not None]
        scale.append({"f_mhz": f, "mean_K_measured": float(np.mean(k)) if k else None,
                      "p833_Am_db": P833[0] * f ** P833[1]})

    counts = {}
    for row in support:
        k = (row["group"], row["f_mhz"], row["season"])
        c = counts.setdefault(k, {"group": k[0], "f_mhz": k[1], "season": k[2], "groups": 0, "ok": 0,
                                  "dropped_missing": 0, "dropped_censored": 0, "dropped_bound": 0,
                                  "cells_missing": 0, "cells_censored": 0})
        c["groups"] += 1
        c["ok" if row["reason"] == "ok" else "dropped_" + row["reason"]] += 1
        for h in (IN_H if k[0] == "in" else TOP_H):
            kind = meas[(row["path"], k[2], h, k[1])][0]
            c["cells_missing"] += kind == "miss"
            c["cells_censored"] += kind == "cens"
    support = list(counts.values())
    decision = {"E1": {"outcome": e1_out, "D1": D1, "mean_e_stock": m_s, "mean_e_707O": m_7,
                       "floored_freqs": floored, "drop_share": drop1, "modes_707O_top": modes},
                "E2": {"outcome": e2_out, "D2": D2, "mean_e_707C": float(np.mean(e7c)) if e7c else None,
                       "mean_e_707O": float(np.mean(e7o)) if e7o else None, "drop_share": drop2},
                "seeds": [SEED_DECIDE, SEED_DESC], "n_boot": N_BOOT}
    return decision, e1_rows, e2_rows, e3_rows, slopes, support, scale


# ---------- self-test ----------
def synth(rng, e1="C", e2="none", shift=0.0, censor_top=0, censor_top_frac=0.0, censor_in_frac=0.0,
          floor9190=False):
    """Synthetic R4-like data (36 paths). Returns meas, pred, bearings."""
    paths = [f"P{i:02d}" for i in range(36)]
    bearings = {p: (i * 10.0) % 360 for i, p in enumerate(paths)}
    meas, pred = {}, {}
    for i, p in enumerate(paths):
        base = rng.normal(20, 5)
        for f in FREQS:
            for h in range(1, 25):
                canopy = 8.0 if h <= 12 else 4.0                       # measured tree loss; some remains at the top
                truth = base + 0.002 * f - 0.3 * h + canopy
                m0 = truth - canopy                                    # the models know no trees
                if e1 == "A":
                    stock = m0 + 8.0 + rng.normal(0, 0.3)              # over-predicts at the top by 4 dB
                    o = m0 + 4.0 + rng.normal(0, 0.3)                  # 707-O right at the top
                elif e1 == "Aadd":
                    stock = m0 + rng.normal(0, 0.3)                    # under-predicts at the top by 4 dB
                    o = m0 + 3.0                                       # closer only by adding loss
                elif e1 == "Amixed":
                    stock = m0 + (-2.0 if i % 2 == 0 else 7.0)         # errors -6 or +3 at the top: mean -1.5
                    o = m0 + 2.0                                       # error -2 everywhere: closer, and below stock's mean
                elif e1 == "small":
                    stock = m0 + 4.5 + rng.normal(0, 0.05)             # over by 0.5 dB
                    o = m0 + 4.0 + rng.normal(0, 0.05)                 # exact: better by 0.5 dB, under the 1 dB size
                elif e1 == "B":
                    stock = m0 + 4.0 + rng.normal(0, 0.3)              # right at the top
                    o = m0 + 10.0                                      # 707 overshoots
                else:
                    stock = m0 + rng.normal(0, 0.3)
                    o = m0 + rng.normal(0, 0.3)                        # same as stock
                if floor9190 and f == 9190:
                    o = m0 + 40.0                                      # 707 terrible at a floored frequency
                if e2 == "good":
                    c = o + (4.0 if h <= 12 else 0)                    # term matches the in-canopy excess
                elif e2 == "good_hf_bad":
                    c = o + ((4.0 if f <= 1846 else 40.0) if h <= 12 else 0)
                elif e2 == "bad":
                    c = o + (25.0 if h <= 12 else 0)                   # term far too large
                else:
                    c = o
                pred[(p, h, f)] = {"stock": stock, "707O": o, "707C": c, "mode": 0}
                for s in SEASONS:
                    v = truth + (shift if (s == "S" and h <= 12) else 0.0) + rng.normal(0, 0.2)
                    kind = "ok"
                    if censor_top and h in TOP_H[-censor_top:]:
                        kind = "cens"
                    if s == "W" and h in TOP_H[-2:] and i < round(censor_top_frac * 36):
                        kind = "cens"
                    if h in IN_H[-6:] and i < round(censor_in_frac * 36):
                        kind = "cens"
                    if floor9190 and f == 9190 and h in TOP_H[-2:] and i < 20:
                        kind = "cens"
                    meas[(p, s, h, f)] = (kind, v + (100.0 if kind == "cens" else 0.0))
    return meas, pred, bearings


def independent_ci(cell_path, values, paths, draws):
    """Bootstrap interval written without the analysis code: draws come from default_rng(20261126)."""
    pos = {p: i for i, p in enumerate(sorted(paths))}
    b = []
    for row in draws:
        num = den = 0.0
        for k in row:
            for cp, v in zip(cell_path, values):
                if pos[cp] == k:
                    num += v; den += 1
        b.append(num / den)
    return np.percentile(b, [2.5, 97.5])


def selftest():
    rng = np.random.default_rng(7)
    def check(cond, msg):
        if not cond:
            raise SystemExit("Self-test failed: " + msg)
    cases = [("A", "A"), ("Aadd", "A by added loss"), ("Amixed", "A"), ("small", "C"), ("B", "B"), ("C", "C")]
    for e1, want in cases:
        dec = analyse(*synth(rng, e1=e1))[0]
        print(f"self-test E1 {e1}: {dec['E1']['outcome']}")
        check(dec["E1"]["outcome"] == want, f"E1 {e1} gave {dec['E1']['outcome']}, expected {want}")
    for e2, want in (("good", "kept term better than ITM's own height gain"), ("bad", "worse"),
                     ("none", "no clear effect"), ("good_hf_bad", "kept term better than ITM's own height gain")):
        dec = analyse(*synth(rng, e1="C", e2=e2))[0]
        print(f"self-test E2 {e2}: {dec['E2']['outcome']}")
        check(dec["E2"]["outcome"] == want, f"E2 {e2} gave {dec['E2']['outcome']}")
    dec = analyse(*synth(rng, e1="A", censor_top_frac=0.25))[0]
    print(f"self-test E1 25 % of paths censored at the top: {dec['E1']['outcome']}, drop {dec['E1']['drop_share']:.2f}")
    check(dec["E1"]["outcome"] == "descriptive (no label)" and 0.2 < dec["E1"]["drop_share"] < 0.3, "20 % rule (E1)")
    dec = analyse(*synth(rng, e1="C", e2="good", censor_in_frac=0.25))[0]
    print(f"self-test E2 25 % censored in canopy: {dec['E2']['outcome']}, drop {dec['E2']['drop_share']:.2f}")
    check(dec["E2"]["outcome"] == "descriptive (no label)" and 0.2 < dec["E2"]["drop_share"] < 0.3, "20 % rule (E2)")
    dec = analyse(*synth(rng, e1="A", floor9190=True))[0]
    print(f"self-test floored 9190 MHz: floored {dec['E1']['floored_freqs']}, outcome {dec['E1']['outcome']}")
    check(dec["E1"]["floored_freqs"] == [9190] and dec["E1"]["outcome"] == "A", "20-path floor")
    out = analyse(*synth(rng, shift=3.0))
    e3 = [r for r in out[3] if r["group"] == "diff" and r["f_mhz"] == 910][0]
    print(f"self-test E3 planted 3 dB: diff mean {e3['mean']:.2f}, resolved {e3['resolved']}")
    check(e3["resolved"] and 2.5 < e3["mean"] < 3.5, "E3 shift")
    sec = [r for r in out[2] if r["split"] == "sector 205-265"][0]
    check(sec["n_paths"] == 6, f"sector split has {sec['n_paths']} paths, expected 6")
    # bootstrap draws: seed, shape and order, against an independent computation
    meas, pred, b = synth(rng, e1="Aadd", e2="good")
    dec = analyse(meas, pred, b)[0]
    paths = sorted(b)
    g = np.random.default_rng(20261126)
    d1_draws = g.integers(0, 36, size=(2000, 36)); d2_draws = g.integers(0, 36, size=(2000, 36))
    cp, v = [], []
    for f in FREQS:
        for p in paths:
            mv, _ = group_value(meas, p, "W", f, TOP_H)
            cp.append(p)
            v.append(abs(model_group(pred, p, f, TOP_H, "707O") - mv) - abs(model_group(pred, p, f, TOP_H, "stock") - mv))
    ref = dec["E1"]["D1"]
    lo, hi = independent_ci(cp, v, paths, d1_draws)
    print(f"self-test D1 interval: analysis [{ref['lo95']:.4f}, {ref['hi95']:.4f}], independent [{lo:.4f}, {hi:.4f}]")
    check(abs(ref["lo95"] - lo) < 1e-9 and abs(ref["hi95"] - hi) < 1e-9, "D1 bootstrap (seed, shape or order)")
    cp, v = [], []
    for f in E2_FREQS:
        for s in SEASONS:
            for p in paths:
                a, _ = group_value(meas, p, s, f, IN_H); t, _ = group_value(meas, p, s, f, TOP_H)
                km = a - t
                kc = model_group(pred, p, f, IN_H, "707C") - model_group(pred, p, f, TOP_H, "707C")
                ko = model_group(pred, p, f, IN_H, "707O") - model_group(pred, p, f, TOP_H, "707O")
                cp.append(p); v.append(abs(kc - km) - abs(ko - km))
    lo, hi = independent_ci(cp, v, paths, d2_draws)
    ref = dec["E2"]["D2"]
    print(f"self-test D2 interval: analysis [{ref['lo95']:.4f}, {ref['hi95']:.4f}], independent [{lo:.4f}, {hi:.4f}]")
    check(abs(ref["lo95"] - lo) < 1e-9 and abs(ref["hi95"] - hi) < 1e-9, "D2 bootstrap (seed, shape or order)")
    # group-value rules
    m = {("p", "S", h, 230): ("ok", float(h)) for h in IN_H}
    m[("p", "S", 2, 230)] = ("cens", 50.0)
    v_, why = group_value(m, "p", "S", 230, IN_H)
    check(why == "ok" and v_ == 8.0, f"one censored cell of 11 gave {v_}, {why}")
    for h in IN_H[:6]:
        m[("p", "S", h, 230)] = ("cens", 50.0)
    check(group_value(m, "p", "S", 230, IN_H)[1] == "censored", "six censored cells of 11 kept")
    m = {("p", "S", h, 230): ("ok", float(h)) for h in IN_H}
    m[("p", "S", 5, 230)] = ("miss", None)
    check(group_value(m, "p", "S", 230, IN_H)[1] == "missing", "missing height kept")
    m = {("p", "S", h, 230): ("ok", float(h)) for h in IN_H}
    m[("p", "S", 12, 230)] = ("cens", 3.0)       # bound below the median cell (7)
    check(group_value(m, "p", "S", 230, IN_H)[1] == "bound", "bound below median kept")
    m = {("p", "S", h, 230): ("ok", float(h)) for h in TOP_H}
    m[("p", "S", 24, 230)] = ("cens", 99.0)
    v_, why = group_value(m, "p", "S", 230, TOP_H)
    check(why == "ok" and v_ == 22.5, f"one censored cell of 4 gave {v_}, {why}")
    m[("p", "S", 23, 230)] = ("cens", 99.0)
    check(group_value(m, "p", "S", 230, TOP_H)[1] == "censored", "two censored cells of 4 kept")
    print("SELF-TEST PASS")


def write_csv(path, rows):
    if not rows:
        return
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        for r in rows:
            w.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in r.items()})


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--selftest":
        selftest()
        return
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    root, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    pred, bearings = read_predictions(root)
    meas = read_measurements(os.path.join(root, "data", "raw", "its_phase2.zip"))
    if len(bearings) != 36 or sum(SECTOR[0] <= b <= SECTOR[1] for b in bearings.values()) != 12:
        raise SystemExit("Expected 36 paths with 12 in the 205-265 degree sector (B35.md); hand back.")
    dec, e1, e2, e3, slopes, support, scale = analyse(meas, pred, bearings)
    if len(dec["E1"]["floored_freqs"]) > 2:
        raise SystemExit(f"More than two frequencies under the 20-path floor ({dec['E1']['floored_freqs']}); hand back (B35.md section 5).")
    write_csv(os.path.join(out, "e1_rev1.csv"), e1)
    write_csv(os.path.join(out, "e2_rev1.csv"), e2)
    write_csv(os.path.join(out, "e3_rev1.csv"), e3)
    write_csv(os.path.join(out, "slopes_rev1.csv"), slopes)
    write_csv(os.path.join(out, "support_rev1.csv"), support)
    write_csv(os.path.join(out, "p833_scale_rev1.csv"), scale)
    json.dump(dec, open(os.path.join(out, "decision_rev1.json"), "w"), indent=2)
    print(json.dumps(dec, indent=2))


if __name__ == "__main__":
    main()
