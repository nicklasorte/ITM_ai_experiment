"""Scalar Fresnel half-plane smoke only; exp(-i omega t), unit incident field."""
import csv
import math
import numbers
import platform
import warnings
import numpy as np
import scipy
from scipy.integrate import quad, IntegrationWarning
from scipy.special import erfc


def validate(v):
    if isinstance(v, (bool, np.bool_)) or not isinstance(v, numbers.Real):
        raise ValueError('v must be a real scalar')
    v = float(v)
    if not math.isfinite(v) or abs(v) > 8:
        raise ValueError('supported domain: finite v in [-8,8]')
    return v


def oracle(v):
    v = validate(v)
    return complex(.5 * erfc((1-1j)*v*math.sqrt(math.pi)/2))


def wave(v):
    v = validate(v)
    with warnings.catch_warnings():
        warnings.simplefilter('error', IntegrationWarning)
        vals = [quad(lambda t: f(math.pi*t*t/2), 0, v,
                     epsabs=1e-12, epsrel=1e-12, limit=200)
                for f in (math.cos, math.sin)]
    if any(not math.isfinite(x) or not math.isfinite(e) or e > 1e-10
           for x,e in vals):
        raise ArithmeticError('quadrature error budget exceeded')
    return .5-(1-1j)*complex(vals[0][0], vals[1][0])/2


def asymptotic(v, second=False):
    v = validate(v)
    if abs(v)<2:
        return None
    # Endpoint integration by parts; next term is -i/(pi v^2).
    tail = (1+1j)*np.exp(1j*math.pi*v*v/2)/(2*math.pi*abs(v))
    if second:
        tail *= 1-1j/(math.pi*v*v)
    return complex(tail if v>0 else 1-tail)


def require(ok, message):
    if not ok:
        raise AssertionError(message)


def run(path='fresnel_cases_rev2.csv'):
    print(platform.python_version(), np.__version__, scipy.__version__)
    methods = {'wave':wave, 'leading':asymptotic,
               'two_term':lambda v: asymptotic(v, True)}
    rows=[]
    require(abs(oracle(0)-.5)<1e-14,'midpoint')
    for v in np.linspace(-8,8,65):
        ref=oracle(v)
        require(abs(ref+oracle(-v)-1)<1e-13,'complement')
        for name,fn in methods.items():
            z=fn(v)
            if z is None:
                rows.append([name,v,'unsupported','',''])
                continue
            require(math.isfinite(abs(z)) and abs(z)>0,'invalid field')
            rows.append([name,v,'supported',abs(z-ref),-20*math.log10(abs(z)/abs(ref))])
    # Regression ceilings, not scientific acceptance or extrapolation bounds.
    for name,count,field,loss in [('wave',65,1e-10,1e-8),('leading',50,.009,.12),('two_term',50,.002,.15)]:
        a=[r for r in rows if r[0]==name and r[2]=='supported']
        require(len(a)==count,'coverage '+name)
        require(max(r[3] for r in a)<=field,'field '+name)
        require(max(abs(r[4]) for r in a)<=loss,'loss '+name)
        print(name,len(a),max(r[3] for r in a),max(abs(r[4]) for r in a))
    for bad in (float('nan'),float('inf'),-9,9,True,'2',2j,[2]):
        for fn in [oracle,*methods.values()]:
            try: fn(bad)
            except ValueError: continue
            raise AssertionError('invalid input accepted')
    for fn in (methods['leading'],methods['two_term']):
        require(fn(1.999) is None and fn(-1.999) is None,'transition')
        require(fn(2) is not None and fn(-2) is not None,'boundary')
    with open(path,'w',newline='') as f:
        w=csv.writer(f); w.writerow(['method','v','status','absolute_field_error','signed_loss_error_db']); w.writerows(rows)

if __name__=='__main__':
    run()
