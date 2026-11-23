"""Stock ITM v1.4 point-to-point core, transcribed to Python for row classification.

Line-by-line transcription of itm_variant/itm_p2p_core_exp.m at cfg defaults
(every submodel switch "itm", every cal scale 1), which that file states is
bit-identical to nicklasorte/matlab_itm private/itm_p2p_core.m at commit
9bd6a4e. Used only to read out, per row, the quantities the MATLAB core
computes internally and does not store: propagation mode, horizon distances,
effective heights and delta_h. Validated against the stored itm_lb_50 /
itm_lb_<p> columns; no model is changed and no score is produced here.
"""
import math
import numpy as np

# ---- C arithmetic helpers (MAX/MIN keep a NaN in the second argument) ----
def c_max(a, b):
    return a if a > b else b

def c_min(a, b):
    return a if a < b else b

def c_sqrt(x):
    return math.sqrt(x) if x >= 0 else float('nan')

def c_log10(x):
    return math.log10(x) if x > 0 else float('nan')

def c_pow(x, p):
    return x ** p if x >= 0 else float('nan')

def fdim(x, y):
    return max(x - y, 0.0)

def fix(x):
    return math.trunc(x)


def inverse_ccdf(q):
    C_0, C_1, C_2 = 2.515516, 0.802853, 0.010328
    D_1, D_2, D_3 = 1.432788, 0.189269, 0.001308
    x = min(q, 1.0 - q)
    T_x = math.sqrt(-2.0 * math.log(x))
    zeta = ((C_2 * T_x + C_1) * T_x + C_0) / ((((D_3 * T_x + D_2) * T_x + D_1) * T_x) + 1.0)
    return (T_x - zeta) * (1 - 2 * (q > 0.5))


# ---- Terrain processing ----
def linear_least_squares_fit(h, np_pts, xi, d_start, d_end):
    """h: elevations (0-based array), np_pts = pfl(1), xi = pfl(2)."""
    i_start = fix(fdim(d_start / xi, 0.0))
    i_end = np_pts - fix(fdim(np_pts, d_end / xi))
    if i_end <= i_start:
        i_start = fix(fdim(i_start, 1.0))
        i_end = np_pts - fix(fdim(np_pts, i_end + 1.0))
    x_length = i_end - i_start
    mid_shifted_end = i_end - 0.5 * x_length
    y_s = h[i_start]
    y_e = h[i_end]
    inner = h[i_start + 1:i_end]
    m = -0.5 * x_length + np.arange(1, x_length)
    acc_y = np.cumsum(np.concatenate(([0.5 * (y_s + y_e)], inner)))
    acc_s = np.cumsum(np.concatenate(([0.5 * (y_s - y_e) * (-0.5 * x_length)], inner * m)))
    sum_y = acc_y[-1] / x_length
    scaled = acc_s[-1] * 12.0 / ((x_length * x_length + 2.0) * x_length)
    return sum_y - scaled * mid_shifted_end, sum_y + scaled * (np_pts - mid_shifted_end)


def compute_delta_h(h, np_pts, xi, d_start_m, d_end_m):
    x_start = d_start_m / xi
    x_end = d_end_m / xi
    if x_end - x_start < 2.0:
        return 0.0
    p10 = fix(0.1 * (x_end - x_start + 8.0))
    p10 = min(max(4, p10), 25)
    n = 10 * p10 - 5
    p90 = n - p10
    np_s = n - 1
    step = (x_end - x_start) / np_s
    i = fix(x_start)
    x_start = x_start - float(np.float32(i + 1.0))   # C++ casts (i + 1.0) to float
    idx = np.empty(n, dtype=np.int64)
    pos = np.empty(n)
    for j in range(n):
        if x_start > 0.0:
            m = min(math.ceil(x_start), np_pts - 1 - i)
            if m > 0:
                x_start -= m
                i += m
        idx[j] = i
        pos[j] = x_start
        x_start += step
    z_hi = h[idx + 1]
    s = z_hi + (z_hi - h[idx]) * pos
    fit_y1, fit_y2 = linear_least_squares_fit(s, np_s, 1.0, 0.0, np_s)
    fit_y2 = (fit_y2 - fit_y1) / np_s
    fit_line = np.cumsum(np.concatenate(([fit_y1], np.full(n - 1, fit_y2))))
    diffs = s - fit_line
    srt = np.sort(diffs)[::-1]
    delta_h_d = srt[p10 - 1] - srt[p90]
    return delta_h_d / (1.0 - 0.8 * math.exp(-(d_end_m - d_start_m) / 50e3))


def find_horizons(h, np_pts, xi, a_e, h_m):
    d_m = np_pts * xi
    z_tx = h[0] + h_m[0]
    z_rx = h[np_pts] + h_m[1]
    theta = [(z_rx - z_tx) / d_m - d_m / (2 * a_e), -(z_rx - z_tx) / d_m - d_m / (2 * a_e)]
    d_hzn = [d_m, d_m]
    if np_pts < 2:
        return theta, d_hzn
    d_tx = np.cumsum(np.full(np_pts - 1, xi))
    d_rx = np.cumsum(np.concatenate(([d_m], np.full(np_pts - 1, -xi))))[1:]
    z = h[1:np_pts]
    a = (z - z_tx) / d_tx - d_tx / (2 * a_e)
    b = -(z_rx - z) / d_rx - d_rx / (2 * a_e)
    i_tx = int(np.argmax(a)); theta_tx = a[i_tx]
    i_rx = int(np.argmax(b)); theta_rx = b[i_rx]
    if theta_tx > theta[0]:
        theta[0] = theta_tx; d_hzn[0] = d_tx[i_tx]
    if theta_rx > theta[1]:
        theta[1] = theta_rx; d_hzn[1] = d_rx[i_rx]
    return theta, d_hzn


def quick_pfl(h, np_pts, xi, gamma_e, h_m):
    d_m = np_pts * xi
    a_e = 1 / gamma_e
    theta_hzn, d_hzn = find_horizons(h, np_pts, xi, a_e, h_m)
    theta_geo = list(theta_hzn)
    d_start = min(15.0 * h_m[0], 0.1 * d_hzn[0])
    d_end = d_m - min(15.0 * h_m[1], 0.1 * d_hzn[1])
    delta_h = compute_delta_h(h, np_pts, xi, d_start, d_end)
    h_e = [0.0, 0.0]
    if d_hzn[0] + d_hzn[1] > 1.5 * d_m:
        fit_tx, fit_rx = linear_least_squares_fit(h, np_pts, xi, d_start, d_end)
        h_e[0] = h_m[0] + fdim(h[0], fit_tx)
        h_e[1] = h_m[1] + fdim(h[np_pts], fit_rx)
        d_hzn = [math.sqrt(2.0 * he * a_e) * math.exp(-0.07 * math.sqrt(delta_h / max(he, 5.0)))
                 for he in h_e]
        combined = d_hzn[0] + d_hzn[1]
        if combined <= d_m:
            h_e = [he * (d_m / combined) ** 2 for he in h_e]
            d_hzn = [math.sqrt(2.0 * he * a_e) * math.exp(-0.07 * math.sqrt(delta_h / max(he, 5.0)))
                     for he in h_e]
        q = [math.sqrt(2.0 * he * a_e) for he in h_e]
        theta_hzn = [(0.65 * delta_h * (q[i] / d_hzn[i] - 1.0) - 2.0 * h_e[i]) / q[i] for i in range(2)]
    else:
        fit_tx, _ = linear_least_squares_fit(h, np_pts, xi, d_start, 0.9 * d_hzn[0])
        h_e[0] = h_m[0] + fdim(h[0], fit_tx)
        _, fit_rx = linear_least_squares_fit(h, np_pts, xi, d_m - 0.9 * d_hzn[1], d_end)
        h_e[1] = h_m[1] + fdim(h[np_pts], fit_rx)
    return theta_hzn, d_hzn, h_e, delta_h, d_m, theta_geo


# ---- Reference attenuation ----
def terrain_roughness(d_m, delta_h):
    return delta_h * (1.0 - 0.8 * math.exp(-d_m / 50e3))

def sigma_h_function(delta_h):
    return 0.78 * delta_h * math.exp(-0.5 * delta_h ** 0.25)

def fresnel_integral(v2):
    if v2 < 5.76:
        return 6.02 + 9.11 * c_sqrt(v2) - 1.27 * v2
    return 12.953 + 10 * math.log10(v2)

def knife_edge_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn):
    d_ML = d_hzn[0] + d_hzn[1]
    theta_nlos = d_m / a_e - theta_los
    d_nlos = d_m - d_ML
    v_1 = 0.0795775 * (f_mhz / 47.7) * theta_nlos ** 2 * d_hzn[0] * d_nlos / (d_nlos + d_hzn[0])
    v_2 = 0.0795775 * (f_mhz / 47.7) * theta_nlos ** 2 * d_hzn[1] * d_nlos / (d_nlos + d_hzn[1])
    return fresnel_integral(v_1) + fresnel_integral(v_2)

def height_function(x_km, K):
    if x_km < 200.0:
        w = -math.log(K) if K > 0 else float('inf')
        if K < 1e-5 or x_km * w ** 3 > 5495.0:
            result = -117.0
            if x_km > 1.0:
                result += 17.372 * math.log(x_km)
            return result
        return 2.5e-5 * x_km ** 2 / K - 8.686 * w - 15.0
    result = 0.05751 * x_km - 4.343 * math.log(x_km)
    if x_km < 2000:
        w = 0.0134 * x_km * math.exp(-0.005 * x_km)
        result = (1.0 - w) * result + w * (17.372 * math.log(x_km) - 117.0)
    return result

def smooth_earth_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn, h_e, Z_g):
    a_0 = 6370e3
    THIRD = 1.0 / 3.0
    theta_nlos = d_m / a_e - theta_los
    d_ML = d_hzn[0] + d_hzn[1]
    a_m = [(d_m - d_ML) / (d_m / a_e - theta_los), 0.5 * d_hzn[0] ** 2 / h_e[0], 0.5 * d_hzn[1] ** 2 / h_e[1]]
    d_km = [(a_m[0] * theta_nlos) / 1000.0, d_hzn[0] / 1000.0, d_hzn[1] / 1000.0]
    C_0 = [c_pow((4.0 / 3.0) * a_0 / a, THIRD) for a in a_m]
    K = [0.017778 * c * f_mhz ** (-THIRD) / abs(Z_g) for c in C_0]
    B_0 = [1.607 - k for k in K]
    x_km = [0.0, 0.0, 0.0]
    x_km[1] = B_0[1] * C_0[1] ** 2 * f_mhz ** THIRD * d_km[1]
    x_km[2] = B_0[2] * C_0[2] ** 2 * f_mhz ** THIRD * d_km[2]
    x_km[0] = B_0[0] * C_0[0] ** 2 * f_mhz ** THIRD * d_km[0] + x_km[1] + x_km[2]
    F_x_1 = height_function(x_km[1], K[1])
    F_x_2 = height_function(x_km[2], K[2])
    G_x = 0.05751 * x_km[0] - 10.0 * c_log10(x_km[0])
    return G_x - F_x_1 - F_x_2 - 20

def diffraction_loss(d_m, d_hzn, h_e, Z_g, a_e, delta_h, h_m, theta_los, d_sML, f_mhz):
    A_k = knife_edge_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn)
    A_se = smooth_earth_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn, h_e, Z_g)
    sigma_h_d = sigma_h_function(terrain_roughness(d_sML, delta_h))
    A_fo = c_min(15.0, 5 * math.log10(1.0 + 1e-5 * h_m[0] * h_m[1] * f_mhz * sigma_h_d))
    delta_h_d = terrain_roughness(d_m, delta_h)
    q = h_m[0] * h_m[1]
    qk = h_e[0] * h_e[1] - q
    q = q + 10.0
    term1 = math.sqrt(1.0 + qk / q)
    d_ML = d_hzn[0] + d_hzn[1]
    q = (term1 + (-theta_los * a_e + d_ML) / d_m) * c_min(delta_h_d * f_mhz / 47.7, 6283.2)
    w = 25.1 / (25.1 + c_sqrt(q))
    return w * A_se + (1.0 - w) * A_k + A_fo

def line_of_sight_loss(d_m, h_e, Z_g, delta_h, M_d, A_d0, d_sML, f_mhz):
    sigma_h_d = sigma_h_function(terrain_roughness(d_m, delta_h))
    wn = f_mhz / 47.7
    sin_psi = (h_e[0] + h_e[1]) / math.sqrt(d_m ** 2 + (h_e[0] + h_e[1]) ** 2)
    R_e = (sin_psi - Z_g) / (sin_psi + Z_g) * math.exp(-c_min(10.0, wn * sigma_h_d * sin_psi))
    q = R_e.real ** 2 + R_e.imag ** 2
    if q < 0.25 or q < sin_psi:
        R_e = R_e * math.sqrt(sin_psi / q)
    delta_phi = wn * 2.0 * h_e[0] * h_e[1] / d_m
    if delta_phi > math.pi / 2.0:
        delta_phi = math.pi - (math.pi / 2.0) ** 2 / delta_phi
    rr = complex(math.cos(delta_phi), -math.sin(delta_phi)) + R_e
    A_t = -10 * math.log10(rr.real ** 2 + rr.imag ** 2)
    A_d = M_d * d_m + A_d0
    w = 1 / (1 + f_mhz * delta_h / c_max(10e3, d_sML))
    return w * A_t + (1 - w) * A_d

def f_function(td):
    a = [133.4, 104.6, 71.8]
    b = [0.332e-3, 0.212e-3, 0.157e-3]
    c = [-10, -2.5, 5]
    i = 0 if td <= 10e3 else (1 if td <= 70e3 else 2)
    return a[i] + b[i] * td + c[i] * c_log10(td)

def h0_curve(j, r):
    a = [25.0, 80.0, 177.0, 395.0, 705.0]
    b = [24.0, 45.0, 68.0, 80.0, 105.0]
    return 10 * math.log10(1 + a[j - 1] * (1 / r) ** 4 + b[j - 1] * (1.0 / r) ** 2)

def h0_function(r, eta_s):
    eta_s = c_min(c_max(eta_s, 1), 5)
    i = fix(eta_s)
    q = eta_s - i
    result = h0_curve(i, r)
    if q != 0.0:
        result = (1.0 - q) * result + q * h0_curve(i + 1, r)
    return result

def troposcatter_loss(d_m, theta_hzn, d_hzn, h_e, a_e, N_s, f_mhz, theta_los, h0):
    wn = f_mhz / 47.7
    if h0 > 15.0:
        H_0 = h0
    else:
        ad = d_hzn[0] - d_hzn[1]
        rr = h_e[1] / h_e[0]
        if ad < 0.0:
            ad = -ad; rr = 1.0 / rr
        theta = theta_hzn[0] + theta_hzn[1] + d_m / a_e
        r_1 = 2.0 * wn * theta * h_e[0]
        r_2 = 2.0 * wn * theta * h_e[1]
        if r_1 < 0.2 and r_2 < 0.2:
            return 1001.0, h0
        s = (d_m - ad) / (d_m + ad)
        q = c_min(c_max(0.1, rr / s), 10.0)
        s = c_max(0.1, s)
        h_0_m = (d_m - ad) * (d_m + ad) * theta * 0.25 / d_m
        Z_0, Z_1 = 1.7556e3, 8.0e3
        eta_s = (h_0_m / Z_0) * (1.0 + (0.031 - N_s * 2.32e-3 + N_s ** 2 * 5.67e-6) *
                                 math.exp(-(c_min(1.7, h_0_m / Z_1)) ** 6))
        H_00 = (h0_function(r_1, eta_s) + h0_function(r_2, eta_s)) / 2
        Delta_H_0 = c_min(H_00, 6.0 * (0.6 - c_log10(c_max(eta_s, 1.0))) * c_log10(s) * c_log10(q))
        H_0 = c_max(H_00 + Delta_H_0, 0.0)
        if eta_s < 1.0:
            H_0 = eta_s * H_0 + (1.0 - eta_s) * 10 * c_log10(
                ((1.0 + math.sqrt(2) / r_1) * (1.0 + math.sqrt(2) / r_2)) ** 2 *
                (r_1 + r_2) / (r_1 + r_2 + 2 * math.sqrt(2)))
        if H_0 > 15.0 and h0 >= 0.0:
            H_0 = h0
    h0 = H_0
    th = d_m / a_e - theta_los
    D_0, H = 40e3, 47.7
    A = (f_function(th * d_m) + 10 * c_log10(wn * H * th ** 4)
         - 0.1 * (N_s - 301.0) * math.exp(-th * d_m / D_0) + H_0)
    return A, h0


def longley_rice(theta_hzn, f_mhz, Z_g, d_hzn, h_e, gamma_e, N_s, delta_h, h_m, d_m):
    a_e = 1 / gamma_e
    d_hzn_s = [math.sqrt(2.0 * he * a_e) for he in h_e]
    d_sML = d_hzn_s[0] + d_hzn_s[1]
    d_ML = d_hzn[0] + d_hzn[1]
    theta_los = -c_max(theta_hzn[0] + theta_hzn[1], -d_ML / a_e)
    d_3 = c_max(d_sML, d_ML + 5.0 * (a_e ** 2 / f_mhz) ** (1.0 / 3.0))
    d_4 = d_3 + 10.0 * (a_e ** 2 / f_mhz) ** (1.0 / 3.0)
    A_3 = diffraction_loss(d_3, d_hzn, h_e, Z_g, a_e, delta_h, h_m, theta_los, d_sML, f_mhz)
    A_4 = diffraction_loss(d_4, d_hzn, h_e, Z_g, a_e, delta_h, h_m, theta_los, d_sML, f_mhz)
    M_d = (A_4 - A_3) / (d_4 - d_3)
    A_d0 = A_3 - M_d * d_3
    out = dict(d_sML=d_sML, d_ML=d_ML, theta_los=theta_los, M_d=M_d, A_d0=A_d0, d_x=float('nan'))
    if d_m < d_sML:
        A_sML = d_sML * M_d + A_d0
        d_0 = 0.04 * f_mhz * h_e[0] * h_e[1]
        if A_d0 >= 0.0:
            d_0 = c_min(d_0, 0.5 * d_ML)
            d_1 = d_0 + 0.25 * (d_ML - d_0)
        else:
            d_1 = c_max(-A_d0 / M_d, 0.25 * d_ML)
        A_1 = line_of_sight_loss(d_1, h_e, Z_g, delta_h, M_d, A_d0, d_sML, f_mhz)
        flag = False
        kHat_1 = kHat_2 = 0.0
        if d_0 < d_1:
            A_0 = line_of_sight_loss(d_0, h_e, Z_g, delta_h, M_d, A_d0, d_sML, f_mhz)
            q = math.log(d_sML / d_0)
            kHat_2 = c_max(0.0, ((d_sML - d_0) * (A_1 - A_0) - (d_1 - d_0) * (A_sML - A_0)) /
                           ((d_sML - d_0) * math.log(d_1 / d_0) - (d_1 - d_0) * q))
            flag = A_d0 > 0.0 or kHat_2 > 0.0
            if flag:
                kHat_1 = (A_sML - A_0 - kHat_2 * q) / (d_sML - d_0)
                if kHat_1 < 0.0:
                    kHat_1 = 0.0
                    kHat_2 = fdim(A_sML, A_0) / q
                    if kHat_2 == 0.0:
                        kHat_1 = M_d
        if not flag:
            kHat_1 = fdim(A_sML, A_1) / (d_sML - d_1)
            kHat_2 = 0.0
            if kHat_1 == 0.0:
                kHat_1 = M_d
        A_o = A_sML - kHat_1 * d_sML - kHat_2 * math.log(d_sML)
        A_ref = A_o + kHat_1 * d_m + kHat_2 * math.log(d_m)
        propmode = 1
    else:
        d_5 = d_ML + 200e3
        d_6 = d_ML + 400e3
        A_6, h0 = troposcatter_loss(d_6, theta_hzn, d_hzn, h_e, a_e, N_s, f_mhz, theta_los, -1)
        A_5, _ = troposcatter_loss(d_5, theta_hzn, d_hzn, h_e, a_e, N_s, f_mhz, theta_los, h0)
        if A_5 < 1000.0:
            M_s = (A_6 - A_5) / 200e3
            d_x = c_max(c_max(d_sML, d_ML + 1.088 * (a_e ** 2 / f_mhz) ** (1.0 / 3.0) * math.log(f_mhz)),
                        (A_5 - A_d0 - M_s * d_5) / (M_d - M_s))
            A_s0 = (M_d - M_s) * d_x + A_d0
        else:
            M_s, A_s0, d_x = M_d, A_d0, 10e6
        out['d_x'] = d_x
        if d_m > d_x:
            A_ref = M_s * d_m + A_s0
            propmode = 3
        else:
            A_ref = M_d * d_m + A_d0
            propmode = 2
    out['A_ref'] = c_max(A_ref, 0.0)
    out['propmode'] = propmode
    return out


# ---- Variability (mdvar 13, broadcast) ----
_ALL_YEAR = np.array([
    [-9.67, -0.62, 1.26, -9.21, -0.62, -0.39, 3.15],
    [12.7, 9.19, 15.5, 9.05, 9.19, 2.86, 857.9],
    [144.9e3, 228.9e3, 262.6e3, 84.1e3, 228.9e3, 141.7e3, 2222.e3],
    [190.3e3, 205.2e3, 185.2e3, 101.1e3, 205.2e3, 315.9e3, 164.8e3],
    [133.8e3, 143.6e3, 99.8e3, 98.6e3, 143.6e3, 167.4e3, 116.3e3]])
_BSM1 = [2.13, 2.66, 6.11, 1.98, 2.68, 6.86, 8.51]
_BSM2 = [159.5, 7.67, 6.65, 13.11, 7.16, 10.38, 169.8]
_XSM1 = [762.2e3, 100.4e3, 138.2e3, 139.1e3, 93.7e3, 187.8e3, 609.8e3]
_XSM2 = [123.6e3, 172.5e3, 242.2e3, 132.7e3, 186.8e3, 169.6e3, 119.9e3]
_XSM3 = [94.5e3, 136.4e3, 178.6e3, 193.5e3, 133.5e3, 108.9e3, 106.6e3]
_BSP1 = [2.11, 6.87, 10.08, 3.68, 4.75, 8.58, 8.43]
_BSP2 = [102.3, 15.53, 9.60, 159.3, 8.12, 13.97, 8.19]
_XSP1 = [636.9e3, 138.7e3, 165.3e3, 464.4e3, 93.2e3, 216.0e3, 136.2e3]
_XSP2 = [134.8e3, 143.7e3, 225.7e3, 93.1e3, 135.9e3, 152.0e3, 188.5e3]
_XSP3 = [95.6e3, 98.6e3, 129.7e3, 94.2e3, 113.4e3, 122.7e3, 122.9e3]
_C_D = [1.224, 0.801, 1.380, 1.000, 1.224, 1.518, 1.518]
_Z_D = [1.282, 2.161, 1.282, 20.0, 1.282, 1.282, 1.282]
_BFM1 = [1.0, 1.0, 1.0, 1.0, 0.92, 1.0, 1.0]
_BFM2 = [0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0]
_BFM3 = [0.0, 0.0, 0.0, 0.0, 1.77, 0.0, 0.0]
_BFP1 = [1.0, 0.93, 1.0, 0.93, 0.93, 1.0, 1.0]
_BFP2 = [0.0, 0.31, 0.0, 0.19, 0.31, 0.0, 0.0]
_BFP3 = [0.0, 2.00, 0.0, 1.79, 2.00, 0.0, 0.0]


def _curve(c1, c2, x1, x2, x3, d_e):
    return (c1 + c2 / (1.0 + ((d_e - x2) / x3) ** 2)) * ((d_e / x1) ** 2) / (1.0 + ((d_e / x1) ** 2))


def variability(z_T, z_S, h_e, delta_h, f_mhz, d_m, A_ref, climate, mdvar=13):
    """Broadcast mode (mdvar 13): plus10 -> sigma_L = 0, Y_R = Y_T."""
    c = climate - 1
    a_9000 = 9000e3
    THIRD = 1.0 / 3.0
    wn = f_mhz / 47.7
    d_ex = math.sqrt(2 * a_9000 * h_e[0]) + math.sqrt(2 * a_9000 * h_e[1]) + (575.7e12 / wn) ** THIRD
    d_e = 130e3 * d_m / d_ex if d_m < d_ex else 130e3 + d_m - d_ex
    assert mdvar == 13
    sigma_S = 5.0 + 3.0 * math.exp(-d_e / 100e3)
    V_med = _curve(*_ALL_YEAR[:, c], d_e)
    sigma_L = 0.0
    Y_L = 0.0
    q = math.log(0.133 * wn)
    g_minus = _BFM1[c] + _BFM2[c] / ((_BFM3[c] * q) ** 2 + 1.0)
    g_plus = _BFP1[c] + _BFP2[c] / ((_BFP3[c] * q) ** 2 + 1.0)
    s_minus = _curve(_BSM1[c], _BSM2[c], _XSM1[c], _XSM2[c], _XSM3[c], d_e) * g_minus
    s_plus = _curve(_BSP1[c], _BSP2[c], _XSP1[c], _XSP2[c], _XSP3[c], d_e) * g_plus
    sigma_TD = _C_D[c] * s_plus
    tgtd = (s_plus - sigma_TD) * _Z_D[c]
    z_T = np.asarray(z_T, dtype=float)
    lower = z_T < 0.0
    upper = z_T > _Z_D[c]
    middle = ~(lower | upper)
    sigma_T = (s_minus * lower + s_plus * middle
               + (sigma_TD + tgtd / np.maximum(z_T, _Z_D[c])) * upper)
    Y_T = sigma_T * z_T
    Y_S_temp = sigma_S ** 2 + Y_T ** 2 / (7.8 + z_S ** 2) + Y_L ** 2 / (24.0 + z_S ** 2)
    Y_R = Y_T + Y_L
    Y_S = np.sqrt(Y_S_temp) * z_S
    result = A_ref - V_med - Y_R - Y_S
    neg = result < 0.0
    result = np.where(neg, result * (29.0 - result) / (29.0 - 10.0 * result), result)
    return result


def run_row(h, spacing_m, htx, hrx, f_mhz, climate, N_0, pol, reliability,
            epsilon=25.0, sigma=0.02, confidence=50.0, location=50.0, mdvar=13):
    """One link. h: elevation array (metres, tx first). Returns loss(es) and geometry."""
    np_pts = len(h) - 1
    xi = spacing_m
    p10 = fix(0.1 * np_pts)
    h_sys = np.cumsum(h[p10:np_pts - p10 + 1])[-1] / (np_pts - 2 * p10 + 1)
    gamma_a = 157e-9
    N_s = N_0 if h_sys == 0.0 else N_0 * math.exp(-h_sys / 9460.0)
    gamma_e = gamma_a * (1.0 - 0.04665 * math.exp(N_s / 179.3))
    ep_r = complex(epsilon, 18000 * sigma / f_mhz)
    Z_g = np.sqrt(ep_r - 1.0)
    if pol == 1:
        Z_g = Z_g / ep_r
    h_m = [htx, hrx]
    theta_hzn, d_hzn, h_e, delta_h, d_m, theta_geo = quick_pfl(h, np_pts, xi, gamma_e, h_m)
    L = longley_rice(theta_hzn, f_mhz, Z_g, d_hzn, h_e, gamma_e, N_s, delta_h, h_m, d_m)
    z_T = np.array([inverse_ccdf(r / 100.0) for r in np.atleast_1d(reliability)])
    z_S = inverse_ccdf(confidence / 100.0)
    V = variability(z_T, z_S, h_e, delta_h, f_mhz, d_m, L['A_ref'], climate, mdvar)
    A_fs = 32.45 + 20.0 * math.log10(f_mhz) + 20.0 * math.log10(d_m / 1000.0)
    q = fix(d_m - d_hzn[0] - d_hzn[1])
    mode_code = 0 if q < 0 else 4 + 4 * (q > 0) + 1 + (L['propmode'] == 3)
    return dict(lb=V + A_fs, propmode=L['propmode'], mode_code=mode_code,
                d_hzn=d_hzn, h_e=h_e, delta_h=delta_h, d_m=d_m, theta_hzn=theta_hzn,
                d_sML=L['d_sML'], d_ML=L['d_ML'], d_x=L['d_x'], A_ref=L['A_ref'], N_s=N_s)
