"""Model-only smoke tests behind the mechanism catalog in headroom_map_rev1.md.

Usage, from the repository root:
    python3 experiments/proposals/headroom_smoke_rev1.py

Runs three candidate line-of-sight and time-variability changes on every
in-scope Phase 2 and long-term row and reports only the change in predicted
loss against stock ITM. No measured loss is read, no score is produced and no
file in itm_variant/ is touched; the variants live here, in the transcription
used by headroom_map_rev1.py, so the sizes quoted in the proposal can be
checked without a MATLAB run.

  M6  rough-surface reflection coefficient exp(-2 (2 pi sigma sin psi / lambda)^2)
      in place of ITM's exp(-min(10, 2 pi sigma sin psi / lambda))
      (Ament 1953, Proc. IRE 41(1); repository literature review rank 10)
  M7  reflected-ray phase from the curved-Earth specular point
      (ITU-R P.530-19 section 6.1.2.3, eq. (121)-(126); research package H02,
      coded in itm_variant/los_phase_curved_rev1.m as cfg.los_phase)
  M16 time variability as two independent legs over a common crest
      (NBS Technical Note 101 section 10.8; research package H03, coded in
      itm_variant/two_leg_quantiles_rev1.m as cfg.time_variability)

The variants here are transcriptions of the MATLAB already in itm_variant/ (M7,
M16) or of the cited paper (M6), run on the stock base. A MATLAB smoke test on
the 707 base is still required before any scored run.
"""
import math, os, sys
import numpy as np
import pandas as pd
from scipy.special import erfc

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get("ITMEXP_ROOT") or os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import itm_stock_py_rev1 as S

P_ALL = [0.01, 0.1, 1, 10, 50, 90, 99, 99.9, 99.99]
A9, THIRD = 9000e3, 1.0 / 3.0


# ---------------- M6: Ament (1953) rough-surface reflection ----------------
def los_ament(d_m, h_e, Z_g, delta_h, M_d, A_d0, d_sML, f_mhz):
    sigma = S.sigma_h_function(S.terrain_roughness(d_m, delta_h))
    wn = f_mhz / 47.7
    sin_psi = (h_e[0] + h_e[1]) / math.sqrt(d_m ** 2 + (h_e[0] + h_e[1]) ** 2)
    g = wn * sigma * sin_psi
    R_e = (sin_psi - Z_g) / (sin_psi + Z_g) * math.exp(-min(20.0, 2.0 * g * g))
    q = R_e.real ** 2 + R_e.imag ** 2
    if q < 0.25 or q < sin_psi:
        R_e = R_e * math.sqrt(sin_psi / q)
    dphi = wn * 2.0 * h_e[0] * h_e[1] / d_m
    if dphi > math.pi / 2.0:
        dphi = math.pi - (math.pi / 2.0) ** 2 / dphi
    rr = complex(math.cos(dphi), -math.sin(dphi)) + R_e
    A_t = -10 * math.log10(rr.real ** 2 + rr.imag ** 2)
    w = 1 / (1 + f_mhz * delta_h / S.c_max(10e3, d_sML))
    return w * A_t + (1 - w) * (M_d * d_m + A_d0)


# ---------------- M7: curved-Earth specular point ----------------
def curved_phase(h1, h2, s, a_e, wn):
    """Transcription of itm_variant/los_phase_curved_rev1.m."""
    if not (h1 > 0 and h2 > 0 and s > 0 and a_e > 0):
        return 0.0
    c = (h1 - h2) / (h1 + h2)
    m = s * s / (4 * a_e * (h1 + h2))
    if m < 1e-9:
        b = c
    else:
        arg = max(-1.0, min(1.0, 1.5 * c * math.sqrt(3 * m / (m + 1) ** 3)))
        b = 2 * math.sqrt((m + 1) / (3 * m)) * math.cos(math.pi / 3 + math.acos(arg) / 3)
    d1, d2 = s * (1 + b) / 2, s * (1 - b) / 2
    u, v = h1 - d1 * d1 / (2 * a_e), h2 - d2 * d2 / (2 * a_e)
    return 0.0 if (u <= 0 or v <= 0) else wn * 2 * u * v / s


def make_los_curved(a_cell):
    def f(d_m, h_e, Z_g, delta_h, M_d, A_d0, d_sML, f_mhz):
        sigma = S.sigma_h_function(S.terrain_roughness(d_m, delta_h))
        wn = f_mhz / 47.7
        sin_psi = (h_e[0] + h_e[1]) / math.sqrt(d_m ** 2 + (h_e[0] + h_e[1]) ** 2)
        R_e = (sin_psi - Z_g) / (sin_psi + Z_g) * math.exp(-S.c_min(10.0, wn * sigma * sin_psi))
        q = R_e.real ** 2 + R_e.imag ** 2
        if q < 0.25 or q < sin_psi:
            R_e = R_e * math.sqrt(sin_psi / q)
        dphi = curved_phase(h_e[0], h_e[1], d_m, a_cell[0], wn)
        if dphi > math.pi / 2.0:
            dphi = math.pi - (math.pi / 2.0) ** 2 / dphi
        rr = complex(math.cos(dphi), -math.sin(dphi)) + R_e
        A_t = -10 * math.log10(rr.real ** 2 + rr.imag ** 2)
        w = 1 / (1 + f_mhz * delta_h / S.c_max(10e3, d_sML))
        return w * A_t + (1 - w) * (M_d * d_m + A_d0)
    return f


# ---------------- M16: two legs over a common crest ----------------
def two_leg_quantiles(z, Y1fun, Y2fun):
    """Transcription of itm_variant/two_leg_quantiles_rev1.m."""
    Zg = np.linspace(-7.5, 7.5, 1201)
    w = np.exp(-Zg ** 2 / 2); w /= w.sum()
    y1, y2 = Y1fun(Zg), Y2fun(Zg)
    Smat = y1[:, None] + y2[None, :]
    W = w[:, None] * w[None, :]
    k = np.argsort(Smat.ravel())
    s, Wk = Smat.ravel()[k], W.ravel()[k]
    F = np.cumsum(Wk) - Wk / 2
    F, iu = np.unique(F, return_index=True)
    return np.interp(0.5 * erfc(-np.asarray(z) / np.sqrt(2)), F, s[iu])


def two_leg_geometry(h, xi, h_m, a_e, f_mhz):
    """Transcription of two_leg_geometry in itm_variant/itm_p2p_core_exp.m."""
    npp = len(h) - 1
    if npp < 3:
        return None
    x = np.arange(npp + 1) * xi; D = x[-1]
    zt, zr = h[0] + h_m[0], h[-1] + h_m[1]
    k = np.arange(1, npp + 1)
    it = k[np.argmax((h[k] - zt) / x[k] - x[k] / (2 * a_e))]
    with np.errstate(divide="ignore"):
        ir = k[np.argmax((h[k] - zr) / (D - x[k]) - (D - x[k]) / (2 * a_e))]
    if it != ir:
        return None
    ic = it; xc = x[ic]
    if (h[ic] - zt) / xc - xc / (2 * a_e) <= (zr - zt) / D - D / (2 * a_e):
        return None
    lam = 299.792458 / f_mhz
    zs = h + x * (D - x) / (2 * a_e)
    u = np.inf
    legs = [np.arange(0, ic + 1), np.arange(ic, npp + 1)]
    ends = [(zt, zs[ic]), (zs[ic], zr)]
    for j in range(2):
        ii = legs[j]; xa, xb = x[ii[0]], x[ii[-1]]; Lg = xb - xa; inr = ii[1:-1]
        if len(inr) == 0:
            continue
        t = x[inr] - xa
        ray = ends[j][0] + (ends[j][1] - ends[j][0]) * t / Lg
        u = min(u, float(np.min((ray - zs[inr]) / np.sqrt(lam * t * (Lg - t) / Lg))))
    hc = h[ic] - (zt * (D - xc) + zr * xc) / D
    u = min(u, hc / math.sqrt(lam * xc * (D - xc) / D))
    up = max(0.0, u)
    he = np.zeros((2, 2))
    hs = [[h_m[0], 0.0], [0.0, h_m[1]]]
    for j in range(2):
        ii = legs[j]
        p = np.polyfit(x[ii], h[ii], 1)
        he[j] = [hs[j][0] + max(0.0, h[ii[0]] - np.polyval(p, x[ii[0]])),
                 hs[j][1] + max(0.0, h[ii[-1]] - np.polyval(p, x[ii[-1]]))]
    return dict(w=up * up / (1 + up * up), len=[xc, D - xc], he=he)


def variability_two_leg(z_T, z_S, h_e, delta_h, f_mhz, d_m, A_ref, climate, leg):
    c = climate - 1
    wn = f_mhz / 47.7
    d_ex = math.sqrt(2 * A9 * h_e[0]) + math.sqrt(2 * A9 * h_e[1]) + (575.7e12 / wn) ** THIRD
    d_e = 130e3 * d_m / d_ex if d_m < d_ex else 130e3 + d_m - d_ex
    sigma_S = 5.0 + 3.0 * math.exp(-d_e / 100e3)
    V_med = S._curve(*S._ALL_YEAR[:, c], d_e)
    q = math.log(0.133 * wn)
    gm = S._BFM1[c] + S._BFM2[c] / ((S._BFM3[c] * q) ** 2 + 1.0)
    gp = S._BFP1[c] + S._BFP2[c] / ((S._BFP3[c] * q) ** 2 + 1.0)

    def sig(Z, de):
        sm = S._curve(S._BSM1[c], S._BSM2[c], S._XSM1[c], S._XSM2[c], S._XSM3[c], de) * gm
        sp = S._curve(S._BSP1[c], S._BSP2[c], S._XSP1[c], S._XSP2[c], S._XSP3[c], de) * gp
        sTD = S._C_D[c] * sp
        Z = np.asarray(Z, float)
        return (sm * (Z < 0) + sp * ((Z >= 0) & (Z <= S._Z_D[c]))
                + (sTD + (sp - sTD) * S._Z_D[c] / np.maximum(Z, S._Z_D[c])) * (Z > S._Z_D[c]))

    z_T = np.asarray(z_T, float)
    Y_T = sig(z_T, d_e) * z_T
    if leg is not None and leg["w"] > 0 and np.any(z_T != 0):
        de = []
        for j in range(2):
            dexj = (math.sqrt(2 * A9 * leg["he"][j][0]) + math.sqrt(2 * A9 * leg["he"][j][1])
                    + (575.7e12 / wn) ** THIRD)
            de.append(130e3 * leg["len"][j] / dexj if leg["len"][j] < dexj else 130e3 + leg["len"][j] - dexj)
        zz = np.concatenate([z_T, [0.0]])
        Yc = two_leg_quantiles(zz, lambda Z: sig(Z, de[0]) * Z, lambda Z: sig(Z, de[1]) * Z)
        Y_T = (1 - leg["w"]) * Y_T + leg["w"] * (Yc[:-1] - Yc[-1])
    Y_S = np.sqrt(sigma_S ** 2 + Y_T ** 2 / (7.8 + z_S ** 2)) * z_S
    res = A_ref - V_med - Y_T - Y_S
    return np.where(res < 0, res * (29.0 - res) / (29.0 - 10.0 * res), res)


def main():
    L = pd.read_csv(os.path.join(ROOT, "data/links/phase2_links_rev1.csv"))
    LT = pd.read_csv(os.path.join(ROOT, "data/links/longterm_links_rev1.csv"))
    idx = pd.read_csv(os.path.join(ROOT, "data/profiles/profiles_index_rev1.csv")).set_index("path_id")
    cache = {}

    def prof(pid):
        if pid not in cache:
            r = idx.loc[pid]
            cache[pid] = (np.loadtxt(os.path.join(ROOT, "data/profiles", r.dataset, pid + ".csv"),
                                     skiprows=1).astype(float), float(r.spacing_m))
        return cache[pid]

    a_cell = [8.5e6]
    orig_los, orig_lr = S.line_of_sight_loss, S.longley_rice

    def lr_capture(theta, f, Zg, dh, he, ge, Ns, dhm, hm, dm):
        a_cell[0] = 1 / ge
        return orig_lr(theta, f, Zg, dh, he, ge, Ns, dhm, hm, dm)

    def sweep(T, p, losfun, capture=False):
        S.line_of_sight_loss = losfun
        if capture:
            S.longley_rice = lr_capture
        out = np.empty((len(T), len(p)))
        for i, r in enumerate(T.itertuples(index=False)):
            h, sp = prof(r.path_id)
            out[i] = S.run_row(h, sp, r.htx_m, r.hrx_m, r.f_mhz, int(r.climate), r.N_0, int(r.pol), p)["lb"]
        S.line_of_sight_loss, S.longley_rice = orig_los, orig_lr
        return out

    band = pd.cut(L.f_mhz, [0, 300, 1000, 3000, 6000, np.inf],
                  labels=["<0.3", "0.3-1", "1-3", "3-6", "6-10"]).astype(str)
    base = sweep(L, [50.0], orig_los)[:, 0]
    for name, fn, cap in (("M6 Ament rough-surface reflection", los_ament, False),
                          ("M7 curved-Earth specular phase", make_los_curved(a_cell), True)):
        d = sweep(L, [50.0], fn, cap)[:, 0] - base
        hi = np.abs(d[L.f_mhz.values > 3000])
        print("%s, Phase 2: mean %+.2f dB; %d of %d rows move > 0.1 dB; above 3 GHz max |change| %.2f dB"
              % (name, d.mean(), (np.abs(d) > 0.1).sum(), len(d), hi.max()))
        print("  band means:", ", ".join("%s %+.2f" % (b, d[(band == b).values].mean())
                                         for b in ["<0.3", "0.3-1", "1-3", "3-6", "6-10"]))

    baseL = sweep(LT, P_ALL, orig_los)
    dL = sweep(LT, P_ALL, make_los_curved(a_cell), True) - baseL
    print("M7, long-term: %d of %d links move > 0.1 dB at any percentage; mean %+.2f dB"
          % ((np.abs(dL) > 0.1).any(1).sum(), len(LT), dL.mean()))

    zT = np.array([S.inverse_ccdf(p / 100) for p in P_ALL])
    zS = S.inverse_ccdf(0.5)
    ds = np.zeros((len(LT), len(P_ALL)))
    ws = []
    for i, r in enumerate(LT.itertuples(index=False)):
        h, sp = prof(r.path_id)
        o = S.run_row(h, sp, r.htx_m, r.hrx_m, r.f_mhz, int(r.climate), r.N_0, int(r.pol), P_ALL)
        a_e = 1 / (157e-9 * (1 - 0.04665 * math.exp(o["N_s"] / 179.3)))
        leg = two_leg_geometry(h, sp, [r.htx_m, r.hrx_m], a_e, r.f_mhz)
        ws.append(0.0 if leg is None else leg["w"])
        if leg is None or leg["w"] == 0:
            continue
        L0 = np.asarray(o["lb"])
        A_fs = L0 - S.variability(zT, zS, o["h_e"], o["delta_h"], r.f_mhz, o["d_m"], o["A_ref"], int(r.climate))
        L1 = variability_two_leg(zT, zS, o["h_e"], o["delta_h"], r.f_mhz, o["d_m"], o["A_ref"],
                                 int(r.climate), leg) + A_fs
        ds[i] = (L1 - L1[4]) - (L0 - L0[4])
    ws = np.array(ws)
    fired = ws > 0
    print("M16 two-leg time variability: fires on %d of %d long-term links; median blend weight %.2f"
          % (fired.sum(), len(ws), np.median(ws[fired]) if fired.any() else 0.0))
    print("  change in predicted spread L_p - L_50, over the links that fire:")
    for j, p in enumerate(P_ALL):
        if p == 50:
            continue
        print("    %6s %%: mean %+.2f dB, range %+.2f to %+.2f"
              % (p, ds[fired, j].mean(), ds[fired, j].min(), ds[fired, j].max()))


if __name__ == "__main__":
    main()
