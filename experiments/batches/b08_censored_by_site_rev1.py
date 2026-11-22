"""Censored-bound violations by site and siting for logged runs (B08).

Usage, from the repository root:
    python3 experiments/batches/b08_censored_by_site_rev1.py <tag> [<tag> ...]

A censored Phase 2 row stores a lower bound on the loss; a prediction below
it is a violation (FRAMEWORK.md). This reports the violated share by site,
and by site and siting (O, C, A), for each tag and for stock ITM. It reads
only the logged prediction files and data/links/phase2_links_rev1.csv; it
doesn't change any score. Asked for by the B07 reviewer pass, for Nick's
decision on a per-site censored check.
"""
import sys
import pandas as pd

links = pd.read_csv("data/links/phase2_links_rev1.csv")
links = links[["link_id", "set", "siting", "censored", "meas_lb_db", "itm_lb_50"]]


def table(pred_col, df):
    c = df[df.censored == 1].copy()
    c["viol"] = c[pred_col] < c.meas_lb_db
    by_site = c.groupby("set").viol.agg(["sum", "count"])
    by_site["pct"] = 100 * by_site["sum"] / by_site["count"]
    by_siting = c.groupby(["set", "siting"]).viol.agg(["sum", "count"])
    by_siting["pct"] = 100 * by_siting["sum"] / by_siting["count"]
    total = 100 * c.viol.mean()
    return total, by_site, by_siting


def show(name, total, by_site, by_siting):
    print(f"{name}: all sites {total:.1f} %")
    for s, r in by_site.iterrows():
        parts = [f"{g} {int(x['sum'])}/{int(x['count'])}"
                 for (ss, g), x in by_siting.iterrows() if ss == s]
        print(f"  {s:3s} {r.pct:5.1f} %  ({int(r['sum'])} of {int(r['count'])})   " + ", ".join(parts))


first = True
for tag in sys.argv[1:]:
    p = pd.read_csv(f"experiments/{tag}/predictions_phase2.csv")[["link_id", "var_lb_50"]]
    df = links.merge(p, on="link_id", how="inner")
    if len(df) != len(p):
        raise SystemExit(f"{tag}: {len(p) - len(df)} prediction rows have no link metadata")
    if first:
        show("stock ITM", *table("itm_lb_50", df))
        first = False
    show(tag, *table("var_lb_50", df))
