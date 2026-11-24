"""Shared helpers for B23 (Package A diagnostics). Development data only.

Interval arithmetic, violation depth, factorial closure, residual contrasts,
geometry classification and the base-clustered bootstrap, as registered in
experiments/batches/B23.md sections 3.3-3.5 and 8. Report-only: nothing here
changes a model, an input or a score.
"""
import hashlib
import math
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SEED = 20261124
C_LIGHT = 299792458.0          # m/s, declared for this report-only diagnostic (B23 section 3.5)
GAMMA_A = 157e-9               # ITM gamma_a, itm_p2p_core_exp.m initialize_point_to_point
INF = math.inf


def sha256_file(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


# ---- Intervals (section 3.3) -------------------------------------------------
def median_interval(runs, flagged):
    """Interval of the run median. runs: values after subtracting the 500 marker;
    flagged: True where the run was censored (value is then a lower bound)."""
    runs = np.asarray(runs, float)
    flagged = np.asarray(flagged, bool)
    lo = np.median(runs)
    up = np.where(flagged, np.inf, runs)
    # even-count convention of MATLAB median: mean of the two middle values; inf stays inf
    s = np.sort(up)
    n = len(s)
    hi = s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2
    return float(lo), float(hi)


def interval_sub(x, y):
    """[x_lo - y_hi, x_hi - y_lo] with extended-real endpoints; never inf - inf as a number."""
    xl, xh = x
    yl, yh = y
    lo = -INF if (xl == -INF or yh == INF) else xl - yh
    hi = INF if (xh == INF or yl == -INF) else xh - yl
    return lo, hi


def violation_depth(pred, iv):
    """max(l - p, p - u, 0) over finite endpoints; None for an uninformative interval."""
    lo, hi = iv
    if lo == -INF and hi == INF:
        return None
    d = 0.0
    if lo != -INF:
        d = max(d, lo - pred)
    if hi != INF:
        d = max(d, pred - hi)
    return d


# ---- Factorial closure (section 5) ---------------------------------------------
def decompose(G00, G10, G01, G11, L_O):
    g = G10 - G00
    a0 = G01 - G00
    a1 = G11 - G10
    i = a1 - a0
    n = G11 - G00
    m = G00 - L_O
    return dict(g=g, a0=a0, a1=a1, i=i, n=n, m=m, total=n + m,
                closure_n=n - (g + a1), closure_n2=n - (g + a0 + i), closure_total=(n + m) - (G11 - L_O))


# ---- Geometry (section 3.5) ------------------------------------------------------
def effective_curvature(z, spacing_m, N_0):
    """gamma_e from the ITM initialisation: terrain-averaged system height over the
    middle 80 percent of the profile, N_s = N_0 exp(-h_sys/9460), gamma_e = gamma_a (1 - 0.04665 exp(N_s/179.3))."""
    npts = len(z) - 1
    p10 = int(0.1 * npts)
    h_sys = float(np.sum(z[p10:npts - p10 + 1]) / (npts - 2 * p10 + 1))
    N_s = N_0 if h_sys == 0.0 else N_0 * math.exp(-h_sys / 9460.0)
    gamma_e = GAMMA_A * (1.0 - 0.04665 * math.exp(N_s / 179.3))
    return gamma_e, N_s, h_sys


def clearance(z, spacing_m, h_tx, h_rx, gamma_e, f_mhz):
    """Interior direct-ray clearance (m) and normalised first-Fresnel clearance.
    clearance(x) = chord(x) - terrain(x) - x (d - x) / (2 a_e), endpoints excluded."""
    npts = len(z) - 1
    d = npts * spacing_m
    x = np.arange(1, npts) * spacing_m
    zt, zr = z[0] + h_tx, z[-1] + h_rx
    chord = zt + (zr - zt) * x / d
    clr = chord - z[1:-1] - x * (d - x) * gamma_e / 2.0
    lam = C_LIGHT / (f_mhz * 1e6)
    F1 = np.sqrt(lam * x * (d - x) / d)
    return float(np.min(clr)), float(np.min(clr / F1))


def geom_class(min_clr):
    return "blocked" if min_clr <= 0 else "clear"


# ---- Contrast statistics (section 3.4) --------------------------------------------------
def base_means(df, col, base_col="physical_base_id"):
    """Equal physical-base weighting: average repeated configuration contrasts within each base."""
    return df.groupby(base_col)[col].mean()


def boot_interval(vals, n_boot=2000, seed=SEED):
    """Percentile 95 % interval of the mean over whole bases (clusters). Returns
    (mean, lo, hi, n_bases, note)."""
    v = np.asarray(vals, float)
    v = v[np.isfinite(v)]
    n = len(v)
    if n == 0:
        return (math.nan, math.nan, math.nan, 0, "no data")
    if n == 1:
        return (float(v[0]), math.nan, math.nan, 1, "single cluster: no interval")
    rng = np.random.default_rng(seed)
    idx = rng.integers(0, n, size=(n_boot, n))
    bm = v[idx].mean(axis=1)
    lo, hi = np.percentile(bm, [2.5, 97.5])
    note = "descriptive only (<10 bases)" if n < 10 else ""
    return (float(v.mean()), float(lo), float(hi), n, note)


def disposition(mean, lo, hi, n, resolution=1.0, half_width_max=1.0):
    """Sign/magnitude statement for one site cell; precision rule of section 3.4."""
    if n < 10 or not np.isfinite(lo):
        return "DESCRIPTIVE"
    hw = (hi - lo) / 2
    if lo > 0 and mean >= resolution:
        return "POS" + ("" if hw <= half_width_max else "-imprecise")
    if hi < 0 and mean <= -resolution:
        return "NEG" + ("" if hw <= half_width_max else "-imprecise")
    return "NULL"
