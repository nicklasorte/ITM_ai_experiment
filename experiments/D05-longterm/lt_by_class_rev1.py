"""D05: where does long-term level error come from? (research plan H12, H19)

Usage, from the repository root:
    python3 -I experiments/D05-longterm/lt_by_class_rev1.py <tag> [<tag> ...]

For each tag and for stock ITM, reports the mean and RMS of (prediction -
measured) at 50 % time by distance class (< 100, 100-300, >= 300 km, as in
FRAMEWORK.md) and frequency band, and the shape error (L_p - L_50) at 1 %
and 99 %. Reads only logged prediction files; changes no score.
"""
import csv, math, sys, collections

def cls(d):
    return '<100' if d < 100 else '100-300' if d < 300 else '>=300'

def band(f):
    return '<150' if f < 150 else '150-500' if f < 500 else '500-1500' if f < 1500 else '>=1500'

def stats(v):
    return (sum(v) / len(v), math.sqrt(sum(x * x for x in v) / len(v)), len(v)) if v else (float('nan'),) * 2 + (0,)

def report(name, rows, col):
    g = collections.defaultdict(list); gs1 = collections.defaultdict(list); gs99 = collections.defaultdict(list)
    for r in rows:
        try:
            m50 = float(r['meas_lb_50']); p50 = float(r[f'{col}_lb_50'])
        except ValueError:
            continue
        if math.isnan(m50) or math.isnan(p50):
            continue
        k = (cls(float(r['d_km'])), band(float(r['f_mhz'])))
        g[k].append(p50 - m50)
        for q, gg in (('1', gs1), ('99', gs99)):
            mq = float(r[f'meas_lb_{q}']); pq = float(r[f'{col}_lb_{q}'])
            if not (math.isnan(mq) or math.isnan(pq)):
                gg[k].append((pq - p50) - (mq - m50))
    print(name)
    for k in sorted(g, key=lambda k: (['<100', '100-300', '>=300'].index(k[0]), k[1])):
        m, r, n = stats(g[k]); s1 = stats(gs1[k]); s99 = stats(gs99[k])
        print(f"  {k[0]:8s} {k[1]:9s} n {n:4d}  L50 mean {m:+6.1f} rms {r:5.1f}   shape@1% mean {s1[0]:+5.1f}  shape@99% mean {s99[0]:+5.1f}")
    allv = [x for v in g.values() for x in v]
    m, r, n = stats(allv)
    print(f"  all                n {n:4d}  L50 mean {m:+6.1f} rms {r:5.1f}")

first = True
for tag in sys.argv[1:]:
    rows = list(csv.DictReader(open(f'experiments/{tag}/predictions_longterm.csv')))
    if first:
        report('stock ITM', rows, 'itm'); first = False
    report(tag, rows, 'var')
