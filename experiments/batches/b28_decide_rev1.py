"""B28 acceptance decision (planner-written, deterministic).

Applies B28.md section 3 checks 1 to 7 to each run in experiments/<tag>/ and
writes experiments/B28-decision/decision_rev1.json and summary.txt.

Usage: python3 -I experiments/batches/b28_decide_rev1.py [--batch B29]
"""
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REF = "707r-rescore-screen36"
RUNS = [  # tag, params, new free parameters, Bonferroni k (B28.md section 2 and 3)
    ("2801-cal707-diffraction", ["w_const", "knife_scale", "afo_scale"], 3, 7),
    ("2802-cal707-los", ["los_w_scale"], 1, 8),
    ("2803-cal707-time", ["time_minus_scale", "time_plus_scale"], 2, 9),
]
# Search ranges copied from eval/cv_calibrate_rev1.m (spec struct)
RANGES = {"w_const": (2.51, 251), "afo_scale": (0, 2), "knife_scale": (0.3, 1.5),
          "los_w_scale": (0.01, 100), "time_minus_scale": (0.3, 3), "time_plus_scale": (0.3, 3)}


def fail(msg):
    print("B28 STOP: " + msg)
    sys.exit(1)


def paired(tag):
    p = os.path.join(ROOT, "experiments", tag, "paired_vs_%s.txt" % REF)
    if not os.path.isfile(p):
        fail("missing " + p)
    t = open(p).read()
    if "2000 draws" not in t:
        fail("%s: paired bootstrap is not 2000 draws" % tag)
    g = lambda pat: float(re.search(pat, t).group(1))
    return {
        "full_gain": g(r"composite gain\s+([+-][\d.]+)"),
        "screened_gain": g(r"screened gain\s+([+-][\d.]+)"),
        # "lower bounds at 99% / 99.5% ... screened <lo99> / <lo995>"
        "screened_lo995": float(re.search(r"screened ([+-][\d.]+) / ([+-][\d.]+)", t).group(2)),
    }


def main():
    batch = "B28"
    if len(sys.argv) == 3 and sys.argv[1] == "--batch":
        batch = sys.argv[2]
    elif len(sys.argv) != 1:
        fail("usage: b28_decide_rev1.py [--batch B29]")
    if batch not in ("B28", "B29"):
        fail("unknown batch " + batch)
    global RUNS
    if batch == "B29":
        RUNS = [(t.replace("28", "29", 1), p, n, k) for t, p, n, k in RUNS]
    ref = json.load(open(os.path.join(ROOT, "experiments", REF, "metrics.json")))["variant"]
    ref_site = {k: v["rms"] for k, v in ref["p2"]["site"].items()}
    ref_cens = ref["p2"]["censored_violation_pct"]
    out, lines = [], ["B28 decision against %s (composite %.2f, censored %.1f %%)" % (REF, ref["composite"], ref_cens), ""]
    for tag, params, npar, k in RUNS:
        d = os.path.join(ROOT, "experiments", tag)
        if not os.path.isdir(d):
            fail("missing " + d)
        m = json.load(open(os.path.join(d, "metrics.json")))
        r = m["recalibrated"]
        if not m.get("constrained"):
            fail(tag + " was not a constrained run")
        want_ref = "base" if batch == "B29" else "stock"
        if m.get("censored_ref", "stock") != want_ref:
            fail("%s: censored_ref is %s, expected %s" % (tag, m.get("censored_ref"), want_ref))
        G = paired(tag)
        site = {s: r["p2"]["site"][s]["rms"] for s in ref_site}
        cens = r["p2"]["censored_violation_pct"]
        rows = list(csv.DictReader(open(os.path.join(d, "params_by_fold.csv"))))
        bound_hits = {}
        for p in params:
            lo, hi = RANGES[p]
            n = sum(1 for row in rows if abs(float(row[p]) - lo) < 1e-6 * max(1, abs(lo)) or abs(float(row[p]) - hi) < 1e-6 * hi)
            bound_hits[p] = n
        moved = {p: sorted({round(float(row[p]), 4) for row in rows}) for p in params}
        checks = {
            "1_screened_lo995_gt0_and_gain_ge_0.3": G["screened_lo995"] > 0 and G["screened_gain"] >= 0.3,
            "2_complexity_gain_ge_%.1f" % (0.5 * npar): G["screened_gain"] >= 0.5 * npar,
            "3_full_composite_not_worse_by_0.3": G["full_gain"] >= -0.3,
            "4_no_site_worse_by_0.5": all(site[s] - ref_site[s] <= 0.5 for s in ref_site),
            "5_censored_le_ref_plus_1": cens <= ref_cens + 1,
            "6_physics_pass": bool(m["physics"]["pass"]),
            "7_bounds_not_majority": all(n <= len(rows) // 2 for n in bound_hits.values()),
        }
        keep = all(checks.values())
        rec = {"tag": tag, "k": k, "params": params, "paired": G, "composite": r["composite"],
               "screened_composite": r.get("screened", {}).get("composite") if isinstance(r.get("screened"), dict) else None,
               "site_rms": site, "site_delta": {s: site[s] - ref_site[s] for s in site},
               "censored_pct": cens, "median_params": m["median_params"], "fold_values": moved,
               "bound_hits": bound_hits, "n_folds": len(rows), "checks": checks, "keep": keep}
        out.append(rec)
        lines += [
            "%s (k = %d; %d new parameters)" % (tag, k, npar),
            "  paired vs %s: full %+.2f, screened %+.2f, screened lo995 %+.2f" % (REF, G["full_gain"], G["screened_gain"], G["screened_lo995"]),
            "  composite %.2f; censored %.1f %%; site RMS delta %s" % (r["composite"], cens, ", ".join("%s %+.2f" % (s, site[s] - ref_site[s]) for s in site)),
            "  fitted by fold: %s; range-bound hits %s" % (moved, bound_hits),
            "  checks: " + ", ".join("%s %s" % (c, "PASS" if v else "FAIL") for c, v in checks.items()),
            "  decision: " + ("KEEP" if keep else "REJECT"),
            "",
        ]
    od = os.path.join(ROOT, "experiments", batch + "-decision")
    os.makedirs(od, exist_ok=True)
    json.dump(out, open(os.path.join(od, "decision_rev1.json"), "w"), indent=1)
    open(os.path.join(od, "summary.txt"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
