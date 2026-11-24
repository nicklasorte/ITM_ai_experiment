#!/usr/bin/env python3
"""B16a: independent recomputation of the coupled two-screen loss with SciPy.

Usage:  python3 -I experiments/batches/b16a_crosscheck_rev1.py experiments/B16a-vogler-oracle

For every 10th sweep row of each sweep_*.csv, recomputes Vogler's N = 2
attenuation (NTIA TR-83-124; Radio Science 17(6), 1982) from the stored
screen coordinates with scipy.special.wofz and scipy.integrate.quad, a
separate implementation from itm_variant/vogler_two_screen_rev1.m (Weideman
Faddeeva, MATLAB integral), and reports the largest difference.
"""
import csv
import glob
import math
import os
import sys

import numpy as np
from scipy.integrate import quad
from scipy.special import wofz


def vogler2(x, z, f_mhz):
    lam = 299.792458 / f_mhz
    k = 2 * math.pi / lam
    r = np.diff(x)
    s = np.diff(z) / r
    th = [s[0] - s[1], s[1] - s[2]]
    al = math.sqrt(r[0] * r[2] / ((r[0] + r[1]) * (r[1] + r[2])))
    b = [th[0] * np.sqrt(1j * k * r[0] * r[1] / (2 * (r[0] + r[1]))),
         th[1] * np.sqrt(1j * k * r[1] * r[2] / (2 * (r[1] + r[2])))]
    b1, b2 = (b[0], b[1]) if b[0].real >= b[1].real else (b[1], b[0])
    C = math.sqrt(r[1] * sum(r) / ((r[0] + r[1]) * (r[1] + r[2])))

    def g(t):
        zz = b2 - al * t
        e = -t * t - 2 * b1 * t
        if zz.real >= 0:
            return np.exp(e) * wofz(1j * zz)
        return 2 * np.exp(e + zz * zz) - np.exp(e) * wofz(-1j * zz)

    T = math.sqrt(80 / (1 - al * al)) + 2 * abs(b1.real) + 2 * abs(b2.real) / max(al, 1e-3)
    pts = [min(T, q / max(abs(b1), 1.0)) for q in (1, 3, 10, 30)]
    re = quad(lambda t: g(t).real, 0, T, epsabs=1e-15, epsrel=1e-11, limit=2000, points=pts)[0]
    im = quad(lambda t: g(t).imag, 0, T, epsabs=1e-15, epsrel=1e-11, limit=2000, points=pts)[0]
    return -20 * math.log10(abs(C / (2 * math.sqrt(math.pi)) * (re + 1j * im)))


def main(d):
    worst = 0.0
    n = 0
    for fn in sorted(glob.glob(os.path.join(d, "sweep_*.csv"))):
        rows = list(csv.DictReader(open(fn)))
        for i, r in enumerate(rows):
            if i % 10:
                continue
            x = [0.0, float(r["x_s1_m"]), float(r["x_s2_m"]), float(r["d_m"])]
            z = [float(r["z_tx_m"]), float(r["z_s1_m"]), float(r["z_s2_m"]), float(r["z_rx_m"])]
            L = vogler2(x, z, float(r["f_mhz"]))
            dif = abs(L - float(r["L_coupled_db"]))
            worst = max(worst, dif)
            n += 1
    msg = "SciPy cross-check: %d sweep points, largest |MATLAB - SciPy| = %.2e dB" % (n, worst)
    print(msg)
    with open(os.path.join(d, "crosscheck.txt"), "w") as f:
        f.write(msg + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
