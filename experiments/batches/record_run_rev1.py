"""Draft the results.tsv row and LOG entry for one logged run (B09 tooling).

Usage, from the repository root:
    python3 -I experiments/batches/record_run_rev1.py <tag> --plan experiments/batches/B09.md \
        --best <best tag> --tier 2 --decision "reject (censored 31.2 %)" [--write]

Reads experiments/<tag>/summary.txt and metrics.json, the best run's
summary.txt, and the batch plan; runs the three analysis scripts
(violations_by_edges_rev1.py, b07_split_rev1.py, b08_censored_by_site_rev1.py).
Prints the results.tsv row and a LOG entry draft. The draft copies the
plan's Change and Predicted lines for this run and leaves the
prediction check for the worker to fill in, because predictions are free
text. With --write, appends the row to results/results.tsv (it refuses a
second row with the same ID). It never edits LOG.md.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys

ROOT = os.getcwd()
if not os.path.isfile(os.path.join(ROOT, "FRAMEWORK.md")):
    sys.exit("run from the repository root")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def parse_summary(text):
    """Pull the rounded numbers the agent-facing summary prints."""
    def num(pattern):
        m = re.search(pattern, text)
        if not m:
            sys.exit(f"summary.txt: no match for {pattern!r}")
        return float(m.group(1))
    s = {
        "composite": num(r"(?m)^composite\s+([\d.]+) dB"),
        "p2_cell": num(r"phase2 cell-balanced RMS @50%\s+([\d.]+)"),
        "lt_level": num(r"long-term level RMS\s+([\d.]+)"),
        "lt_shape": num(r"long-term shape RMS\s+([\d.]+)"),
        "screened": num(r"composite, screened set\s+([\d.]+)"),
        "worst_cell": num(r"worst cell\s+([\d.]+)"),
        "censored": num(r"censored violations\s+([\d.]+)%"),
    }
    for site in ["R1", "R2", "R3", "VA"]:
        m = re.search(rf"site {site} RMS ([\d.]+)\s+mean ([+-]?[\d.]+)", text)
        if not m:
            sys.exit(f"summary.txt: no line for site {site}")
        s[f"rms_{site}"], s[f"mean_{site}"] = float(m.group(1)), float(m.group(2))
    m = re.search(r"physics battery: (\w+)", text)
    s["physics"] = m.group(1) if m else "NA"
    gains = re.findall(r"(composite|screened) gain\s+([+-][\d.]+) dB\s+\(SD [\d.]+; 95% interval ([+-][\d.]+) to ([+-][\d.]+)\)", text)
    s["gains"] = {g[0]: (g[1], g[2], g[3]) for g in gains}
    return s


def plan_section(plan_text, tag):
    """Return the Change and Predicted text of the plan's section for tag."""
    m = re.search(rf"^### {re.escape(tag)}.*?$(.*?)(?=^### |\Z)", plan_text, re.M | re.S)
    if not m:
        return False, None, None
    body = m.group(1)

    def item(name):
        mm = re.search(rf"^- {name}(?: \([^)]*\))?:(.*?)(?=^- |\Z)", body, re.M | re.S)
        return " ".join(mm.group(1).split()) if mm else None
    return True, item("Change"), item("Predicted")


def run_script(args):
    r = subprocess.run([sys.executable, "-I"] + args, capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        sys.exit(f"{args[0]} failed:\n{r.stderr}")
    return r.stdout.rstrip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tag")
    ap.add_argument("--plan", required=True)
    ap.add_argument("--best", required=True)
    ap.add_argument("--tier", default="2")
    ap.add_argument("--function", default=None, help="results.tsv function column; default: the plan's Change text")
    ap.add_argument("--decision", required=True)
    ap.add_argument("--branch", default=None)
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args()

    run_dir = os.path.join("experiments", a.tag)
    s = parse_summary(read(os.path.join(run_dir, "summary.txt")))
    best = parse_summary(read(os.path.join("experiments", a.best, "summary.txt")))
    metrics = json.loads(read(os.path.join(run_dir, "metrics.json")))
    cfg = metrics.get("cfg", {})
    run_id = a.tag.split("-")[0]
    found, change, predicted = plan_section(read(a.plan), a.tag)
    if not found:
        sys.exit(f"{a.plan} has no section '### {a.tag}'")
    if change is None:
        change = "(no Change line in the plan section)"
    batch = os.path.splitext(os.path.basename(a.plan))[0]
    today = datetime.date.today().isoformat()

    if a.function:
        func = a.function
    else:
        pairs = re.findall(r'cfg\.(\w+)\s*=\s*"?([^";`]+)"?;', change)
        func = ", ".join(f"{k}={v}" for k, v in pairs) if pairs else change.replace("`", "")
    func = func.replace("\t", " ")
    row = [run_id, today, a.branch or f"exp/{a.tag}", a.tier, func, "0",
           f"{s['composite']:.1f}", f"{s['composite'] - best['composite']:+.1f}",
           f"{s['p2_cell']:.1f}", f"{s['lt_level']:.1f}", f"{s['lt_shape']:.1f}", f"{s['worst_cell']:.1f}",
           f"{s['rms_R1']:.1f}", f"{s['rms_R2']:.1f}", f"{s['rms_R3']:.1f}", f"{s['rms_VA']:.1f}",
           f"{s['censored']:.1f}", s["physics"],
           f"{a.decision}; screened {s['screened']:.1f}", ""]
    print("results.tsv row:")
    print("\t".join(row))

    edges = run_script(["experiments/D03-r2-dead-paths/violations_by_edges_rev1.py", a.tag])
    split = run_script(["experiments/batches/b07_split_rev1.py", a.tag])
    cens = run_script(["experiments/batches/b08_censored_by_site_rev1.py", a.tag])
    cens_lines = [l for l in cens.splitlines()]
    # keep only this run's block (the script prints stock ITM first)
    i = next(k for k, l in enumerate(cens_lines) if l.startswith(a.tag))
    cens_run = "\n".join(cens_lines[i:])

    g = s["gains"]
    gain_txt = ""
    if "composite" in g and "screened" in g:
        gain_txt = (f" Paired gain vs {a.best} {g['composite'][0]} (95 % {g['composite'][1]} to {g['composite'][2]});"
                    f" screened {g['screened'][0]} ({g['screened'][1]} to {g['screened'][2]}).")
    switches = ", ".join(f"{k}={cfg[k]}" for k in ["diffraction", "diffraction_bound", "terminal_clutter",
                                                     "terminal_clutter_base", "terminal_clutter_frange"] if k in cfg)
    print("\nLOG draft:")
    print(f"### {a.tag}")
    print(f"- Date: {today}. Batch {batch}. Parent: {a.best}. Tier {a.tier}.")
    print(f"- Change: {change}")
    if cfg.get("overrides"):
        print(f"- Run settings (metrics.json cfg): {switches}; overrides {cfg['overrides']}")
    print(f"- Predicted (from {batch}.md, before the run): {predicted}")
    print(f"- Result: composite {s['composite']:.1f} dB ({a.best} {best['composite']:.1f}); screened {s['screened']:.1f};"
          f" Phase 2 cell {s['p2_cell']:.1f}; long-term level {s['lt_level']:.1f}; shape {s['lt_shape']:.1f}."
          f" Site RMS R1 {s['rms_R1']:.1f} (mean {s['mean_R1']:+.1f}), R2 {s['rms_R2']:.1f} (mean {s['mean_R2']:+.1f}),"
          f" R3 {s['rms_R3']:.1f} (mean {s['mean_R3']:+.1f}), VA {s['rms_VA']:.1f} (mean {s['mean_VA']:+.1f})."
          f" Worst cell {s['worst_cell']:.1f}. Censored {s['censored']:.1f} %.{gain_txt}")
    print(f"- Physics battery: {s['physics']}.")
    print("- Censored by site:")
    for l in cens_run.splitlines()[1:]:
        print(f"  - {l.strip()}")
    print("- By edge count:")
    for l in edges.splitlines()[1:]:
        print(f"  - {l.strip()}")
    print("- Siting split (mean error, dB):")
    for l in split.splitlines()[1:]:
        print(f"  - {' '.join(l.split())}")
    print(f"- Decision: {a.decision}.")
    print("- Predictions: TODO (worker): list each registered prediction as Held or Missed, with the value.")

    if a.write:
        path = "results/results.tsv"
        text = read(path)
        if any(l.split("\t")[0] == run_id for l in text.splitlines()[1:]):
            sys.exit(f"results.tsv already has a row with ID {run_id}; not written")
        header = text.splitlines()[0].split("\t")
        if len(header) != len(row):
            sys.exit(f"row has {len(row)} fields, header {len(header)}")
        with open(path, "a", encoding="utf-8") as f:
            if not text.endswith("\n"):
                f.write("\n")
            f.write("\t".join(row) + "\n")
        print(f"\nappended row {run_id} to {path}")


if __name__ == "__main__":
    main()
