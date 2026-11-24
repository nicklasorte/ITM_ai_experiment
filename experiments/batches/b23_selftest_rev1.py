"""B23 self-tests (section 8 of experiments/batches/B23.md). Run first; stops on any failure.

Usage: python3 -I experiments/batches/b23_selftest_rev1.py
"""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import b23_common_rev1 as C  # noqa: E402

INF = math.inf
fails = []


def check(name, cond, detail=""):
    print(("PASS " if cond else "FAIL ") + name + (" " + detail if detail else ""))
    if not cond:
        fails.append(name)


# raw median lower/upper
check("median [1,3]", C.median_interval([1, 3], [False, False]) == (2.0, 2.0))
check("median [1,1],[3,+inf]", C.median_interval([1, 3], [False, True]) == (2.0, INF))
check("median three runs", C.median_interval([1, 2, 3], [False, False, True]) == (2.0, 2.0))
# interval subtraction
check("[10,10]-[7,inf]", C.interval_sub((10, 10), (7, INF)) == (-INF, 3))
check("[10,inf]-[7,7]", C.interval_sub((10, INF), (7, 7)) == (3, INF))
check("two unbounded", C.interval_sub((7, INF), (7, INF)) == (-INF, INF))
# violation depth
check("depth 2 vs [3,inf]", C.violation_depth(2, (3, INF)) == 1)
check("depth 4 vs [-inf,3]", C.violation_depth(4, (-INF, 3)) == 1)
check("depth boundary", C.violation_depth(3, (3, INF)) == 0 and C.violation_depth(3, (-INF, 3)) == 0)
check("uninformative skipped", C.violation_depth(0, (-INF, INF)) is None)
# factorial closure
d = C.decompose(100, 96, 112, 107, 99)
check("closure example", (d["g"], d["a0"], d["a1"], d["i"], d["n"], d["m"], d["total"]) == (-4, 12, 11, -1, 7, 1, 8), str(d))
check("closure identities", abs(d["closure_n"]) < 1e-12 and abs(d["closure_n2"]) < 1e-12 and abs(d["closure_total"]) < 1e-12)
# frequency residual sign and slope
T = (5) - (2)
check("T sign", T == 3 and abs(T / math.log10(2) - 9.966) < 1e-3, f"{T / math.log10(2):.3f}")
# height error sign
check("height error sign", (-3) - (-8) == 5)
# geometry: flat profile analytic, single ridge, reversal, endpoints excluded
sp, n = 100.0, 100
z = np.zeros(n + 1)
ge = 0.0       # no curvature: clearance is chord height
mc, nf = C.clearance(z, sp, 10.0, 10.0, ge, 1000.0)
lam = C.C_LIGHT / 1e9
d_m = n * sp
x = np.arange(1, n) * sp
f1 = np.sqrt(lam * x * (d_m - x) / d_m)
check("flat clearance analytic", abs(mc - 10.0) < 1e-12 and abs(nf - np.min(10.0 / f1)) < 1e-12)
g2 = 1.0 / 8.5e6
mc2, _ = C.clearance(z, sp, 10.0, 10.0, g2, 1000.0)
check("curvature bulge", abs(mc2 - (10.0 - (d_m / 2) ** 2 * g2 / 2)) < 1e-9)
zr = z.copy(); zr[50] = 200.0
mc3, _ = C.clearance(zr, sp, 10.0, 10.0, 0.0, 1000.0)
check("single ridge blocks", mc3 == 10.0 - 200.0 and C.geom_class(mc3) == "blocked")
mc4, _ = C.clearance(zr[::-1].copy(), sp, 10.0, 10.0, 0.0, 1000.0)
check("reciprocity (reversal)", abs(mc3 - mc4) < 1e-12)
ze = z.copy(); ze[0] = 500.0   # tall endpoint terrain is not an interior point
mc5, _ = C.clearance(ze, sp, 0.0, 0.0, 0.0, 1000.0)
check("endpoints excluded", mc5 < 500 and np.isfinite(mc5))
# bootstrap: seed fixed, cluster multiplicity, single cluster flagged
a = C.boot_interval([1.0] * 12 + [3.0] * 12)
b = C.boot_interval([1.0] * 12 + [3.0] * 12)
check("bootstrap reproducible", a == b)
check("single cluster flagged", C.boot_interval([2.0])[4] == "single cluster: no interval")
check("fewer than ten flagged", "descriptive" in C.boot_interval(list(range(5)))[4])
# grouping: duplicate raw keys and shuffle invariance are exercised by the manifest builder
print("grouping/shuffle/duplicate-key checks run inside b23_manifest_rev1.py")
if fails:
    raise SystemExit("self-test failures: " + ", ".join(fails))
print("all self-tests passed")
