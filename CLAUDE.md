# CLAUDE.md

Instructions for any agent working in this repository. The plan is in
[FRAMEWORK.md](FRAMEWORK.md); the experiment loop is in
[program.md](program.md). Read both before running experiments.

## What this repo is

A sandbox for improving the Irregular Terrain Model (ITM, Longley-Rice)
against measured propagation loss. An agent changes a copy of the MATLAB ITM
core, a read-only evaluator scores it against ITS measurements (Phase 2 at
50 % time, and long-term time distributions), and only changes that improve
the held-out score and pass the physics checks are kept.

## Where to run

- MATLAB R2025b with Mapping Toolbox, on Nick's Mac, through the MATLAB MCP
  server. Repos live in `~/github/`.
- Sibling repos the harness needs: `~/github/matlab_itm` at the pinned
  commit (see `eval/itm_exp_paths_rev1.m`), and, only for rebuilding data,
  `~/github/matlab_itu_p452` and `~/github/itu_p2001`.
- Long jobs (data builds, full evaluations) go through `matlab -batch` in
  the background with a log file, so the MCP session isn't blocked:

  ```bash
  cd ~/github/ITM_ai_experiment
  nohup /Applications/MATLAB_R2025b.app/bin/matlab -batch \
    "addpath eval; run_eval_rev1(Tag=\"001-short-name\")" > experiments/run.log 2>&1 &
  ```

## Commands

```matlab
addpath eval
% Score the current variant (writes experiments/<Tag>/)
run_eval_rev1(Tag="001-short-name");
% Check the untouched variant still matches the baseline exactly
run_eval_rev1(Tag="000-baseline", Parity=true);
% Rebuild profiles after a fresh clone (data/cache is not committed)
addpath data; build_links_rev1(ProfilesOnly=true);
```

## Rules

- Edit only `itm_variant/`, `experiments/`, and `results/`. Never edit
  `eval/`, `data/`, `FRAMEWORK.md`, `program.md`, or this file.
- Never look at lockbox data or ask for lockbox scores.
- The terrain source and profile spacing are fixed. Don't change inputs to
  improve a score.
- Name every model part by its physics and its public source (ITU-R
  Recommendation, NTIA report, journal paper). Don't attribute a change to
  an unpublished or restricted model.
- No invented constants: cite the source in a comment or mark it `TODO`.
- Fail loud with `error()`; never return NaN or skip rows silently.
- Version-suffixed file names (`_rev1`, `_rev2`).
- Commit messages say what changed and the score delta. Nick reviews every
  10 kept changes, and anything leaving the repo.
- Write in plain technical English following the Google developer
  documentation style guide.
