#!/usr/bin/env python3
"""Repository guard for ITM_ai_experiment (rev 1).

Runs in GitHub Actions on every push and pull request, and locally with
    python3 .github/scripts/guard_rev1.py --range <base>..<head>

Checks (each failure is reported; any failure exits 1):
  1. Agent scope: a commit with an `Agent-Role:` trailer may change only
     itm_variant/, experiments/, and results/ (program.md, CLAUDE.md).
  2. Frozen data: data/splits/folds_rev1.csv matches folds_rev1.sha256, and
     every terrain profile CSV matches the SHA-256 in profiles_index_rev1.csv.
  3. Results table: every row of results/results.tsv has the header's field
     count, and experiment IDs are unique.
  4. Restricted names: no tracked text file contains a term from the
     RESTRICTED_TERMS environment variable (comma-separated, set from a
     repository secret so the terms never appear in the repo), matched
     case-insensitively at letter boundaries. Skipped with a
     warning when the variable is empty.
  5. File naming (warning only): new .m files outside private/ folders in
     itm_variant/, eval/, or data/ should carry a _revN or _exp suffix.
"""

import argparse
import csv
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

AGENT_ALLOWED = ("itm_variant/", "experiments/", "results/")
ZERO_SHA = "0" * 40
ROOT = Path(__file__).resolve().parents[2]

failures = []
warnings = []


def git(*args):
    out = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    if out.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed: {out.stderr.strip()}")
    return out.stdout


def commits_in_range(rng):
    base, head = rng.split("..")
    if not base or base == ZERO_SHA:
        return [head]
    return [c for c in git("rev-list", "--no-merges", f"{base}..{head}").split() if c]


def check_agent_scope(rng):
    for sha in commits_in_range(rng):
        trailers = git("log", "-1", "--format=%(trailers:key=Agent-Role,valueonly)", sha).strip()
        if not trailers:
            continue
        files = [f for f in git("show", "--name-only", "--format=", sha).splitlines() if f]
        bad = [f for f in files if not f.startswith(AGENT_ALLOWED)]
        if bad:
            failures.append(
                f"agent commit {sha[:8]} (Agent-Role: {trailers}) changes protected paths: "
                + ", ".join(bad[:10]) + (" ..." if len(bad) > 10 else "")
            )


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def check_frozen_data():
    folds = ROOT / "data/splits/folds_rev1.csv"
    expected = (ROOT / "data/splits/folds_rev1.sha256").read_text().split()[0]
    if sha256(folds) != expected:
        failures.append("data/splits/folds_rev1.csv does not match folds_rev1.sha256")

    index = ROOT / "data/profiles/profiles_index_rev1.csv"
    n = 0
    with open(index, newline="") as f:
        for row in csv.DictReader(f):
            p = ROOT / "data/profiles" / row["dataset"] / f"{row['path_id']}.csv"
            if not p.exists():
                failures.append(f"profile listed in index is missing: {p.relative_to(ROOT)}")
            elif sha256(p) != row["sha256"]:
                failures.append(f"profile hash mismatch: {p.relative_to(ROOT)}")
            n += 1
    on_disk = len(list((ROOT / "data/profiles").glob("*/*.csv")))
    if on_disk != n:
        failures.append(f"profiles on disk ({on_disk}) differ from index rows ({n})")
    return n


def check_results_table():
    lines = (ROOT / "results/results.tsv").read_text().splitlines()
    width = len(lines[0].split("\t"))
    ids = []
    for i, line in enumerate(lines[1:], start=2):
        if not line.strip():
            continue
        fields = line.split("\t")
        if len(fields) != width:
            failures.append(f"results/results.tsv line {i}: {len(fields)} fields, header has {width}")
        ids.append(fields[0])
    dupes = sorted({x for x in ids if ids.count(x) > 1})
    if dupes:
        failures.append("results/results.tsv duplicate IDs: " + ", ".join(dupes))


def check_restricted_names():
    terms = [t.strip().lower() for t in os.environ.get("RESTRICTED_TERMS", "").split(",") if t.strip()]
    if not terms:
        warnings.append("RESTRICTED_TERMS is not set; restricted-name scan skipped")
        return
    # Letter boundaries, not word boundaries: catches snake_case identifiers
    # that contain a term, without matching it inside a longer English word.
    pattern = re.compile(
        "|".join(rf"(?<![a-z]){re.escape(t)}(?![a-z])" for t in terms), re.IGNORECASE
    )
    for idx, rel in enumerate(git("ls-files").splitlines(), start=1):
        if pattern.search(rel):
            failures.append(f"restricted name in a tracked file path (entry {idx} of git ls-files)")
            continue
        p = ROOT / rel
        if p.suffix.lower() in {".zip", ".mat", ".png", ".pdf", ".docx"} or not p.is_file():
            continue
        try:
            text = p.read_text(errors="ignore")
        except OSError:
            continue
        for k, line in enumerate(text.splitlines(), start=1):
            if pattern.search(line):
                # Never print the matched term itself: the log is public.
                failures.append(f"restricted name found: {rel}:{k}")
                break


def check_new_file_names(rng):
    base, head = rng.split("..")
    if not base or base == ZERO_SHA:
        return
    added = git("diff", "--name-only", "--diff-filter=A", base, head).splitlines()
    for f in added:
        if not f.endswith(".m") or "/private/" in f:
            continue
        if not f.startswith(("itm_variant/", "eval/", "data/")):
            continue
        if not re.search(r"(_rev\d+|_exp)\.m$", f):
            warnings.append(f"new MATLAB file without a _revN or _exp suffix: {f}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--range", default="", help="base..head commit range to inspect")
    args = ap.parse_args()

    if args.range:
        check_agent_scope(args.range)
        check_new_file_names(args.range)
    n_profiles = check_frozen_data()
    check_results_table()
    check_restricted_names()

    for w in warnings:
        print(f"::warning::{w}")
    for f in failures:
        print(f"::error::{f}")
    print(f"guard_rev1: {n_profiles} profiles hashed, {len(failures)} failures, {len(warnings)} warnings")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
