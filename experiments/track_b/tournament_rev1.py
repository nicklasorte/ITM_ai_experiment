"""Synthetic scalar paraxial knife-edge tournament; no measured data."""
import math
import numpy as np
from scipy.special import erfc
from scipy.integrate import quad


def oracle(v):
    # Fresnel half-plane, normalized unobstructed field; exp(-i omega t).
    return complex(0.5 * erfc((1-1j)*v*math.sqrt(math.pi)/2))


def wave(v):
    # Independent real quadrature from the edge midpoint, not erfc.
    a = quad(lambda t: math.cos(math.pi*t*t/2), 0, v, epsabs=1e-11)[0]
    b = quad(lambda t: math.sin(math.pi*t*t/2), 0, v, epsabs=1e-11)[0]
    return 0.5 - (1-1j)*(a+1j*b)/2


def ray(v):
    # Leading endpoint asymptotic; deliberately abstain near transition.
    if abs(v) < 2:
        return None
    tail = (1+1j)*np.exp(1j*math.pi*v*v/2)/(2*math.pi*abs(v))
    return complex(tail if v > 0 else 1-tail)


def reduced(v):
    # First two terms of endpoint asymptotic, same domain as ray.
    if abs(v) < 2:
        return None
    tail = (1+1j)*np.exp(1j*math.pi*v*v/2)/(2*math.pi*abs(v))
    tail *= 1-1j/(math.pi*v*v)
    return complex(tail if v > 0 else 1-tail)


def main():
    assert abs(oracle(0)-0.5)<1e-14
    for v in np.linspace(-8,8,65):
        assert abs(oracle(v)+oracle(-v)-1)<1e-13
        assert abs(wave(v)-oracle(v))<1e-10
    for name, fn in [('wave',wave),('ray',ray),('reduced',reduced)]:
        errors=[]; db=[]
        for v in np.linspace(-8,8,65):
            z=fn(float(v)); ref=oracle(v)
            if z is None: continue
            errors.append(abs(z-ref)); db.append(abs(20*math.log10(abs(z)/abs(ref))))
        print(f'{name}: coverage={len(errors)}/65 max_field={max(errors):.8g} max_db={max(db):.8g}')

if __name__=='__main__': main()
