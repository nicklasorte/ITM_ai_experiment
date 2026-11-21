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
- Long jobs (data builds, full evaluations) run as a MATLAB `batch` job, so
  the MCP session stays free. Don't use `system()` or `!` from the MCP
  session: shell calls there have hung. Use MATLAB's own `gitrepo`, `pull`,
  and `commit` for git.

  ```matlab
  root = fullfile(getenv('HOME'), 'github', 'ITM_ai_experiment');
  j = batch(@run_eval_rev1, 1, {"Tag", "001-short-name"}, 'CurrentFolder', root, ...
      'AdditionalPaths', {fullfile(root, 'eval')}, 'CaptureDiary', true, 'AutoAddClientPath', false, 'AutoAttachFiles', false);
  % later: j.State, j.Tasks(1).Diary, fetchOutputs(j)
  ```

## Commands

```matlab
addpath eval
% Score the current variant (writes experiments/<Tag>/)
run_eval_rev1(Tag="001-short-name");
% Check the untouched variant still matches the baseline exactly
run_eval_rev1(Tag="000-baseline", Parity=true);
% Terrain comes from data/profiles/*.csv (one file per profile); no tiles
% or cache are needed after a fresh clone.
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
- Agent commits end with an `Agent-Role: planner|worker|reviewer` trailer.
  The `guard` CI workflow rejects agent commits outside the editable
  folders, changed frozen data, a malformed `results.tsv`, or restricted
  names. Run it locally with
  `python3 .github/scripts/guard_rev1.py --range <base>..HEAD`.
- Retry an infrastructure failure (hung session, failed batch job, terrain
  download error) once and log it as `infra`; it isn't an experiment result.
- Commit messages say what changed and the score delta. No human review step
  runs inside the loop; three independent reviewer agents check every 10
  kept changes. Results that leave the repo get Nick's read first.
- Roles (FRAMEWORK.md, Agent roles): a planner (Opus or Fable) writes batch
  plans in `experiments/batches/`; a worker (Haiku) executes them exactly and
  hands back on any error or ambiguity.
- Write in plain technical English following the Google developer
  documentation style guide.
