# Agent program

This file tells the agent how to run ITM experiments. Only Nick edits this
file. The full rationale is in [FRAMEWORK.md](FRAMEWORK.md).

## Your job

Reduce the composite score (FRAMEWORK.md, Score): the mean of the Phase 2
cell-balanced RMS error at 50 % time and the long-term level and shape
errors over time percentage. Do it by making physically justified changes to
`itm_variant/itm_p2p_core_exp.m` and `itm_variant/params_exp.m`. Start with
the ranked submodel swaps in `docs/LITERATURE_REVIEW.md` Part 3.

## What you can and can't touch

- You can edit only `itm_variant/`, `experiments/`, and `results/`.
- Don't edit `eval/`, `data/`, `FRAMEWORK.md`, or this file.
- Don't look for, read, or ask about lockbox data.
- Inputs are fixed: terrain source, profile spacing, ground constants,
  climate, and refractivity. Change the model, not the inputs.
- Name each part by its physics and public source.

## Each experiment

1. Read `results/results.tsv` and the last 20 entries in
   `experiments/LOG.md`. Don't repeat a rejected idea unless you state what
   is different.
1. Pick the cell (site × band) with the most remaining squared error, and
   pick a hypothesis from the change catalog in `FRAMEWORK.md` that targets
   it. Work the tiers in order.
1. Before editing, write the log entry: ID, tier, function, the physical
   rationale in one sentence, and the predicted effect on each site.
1. Create the branch `exp/NNN-short-name` from `best`, or from one of the
   top three kept variants.
1. Make one change. Keep it small. Name any new constant in `params_exp.m`
   with a comment citing its source or marked `TODO`.
1. Run `run_eval_rev1(Tag="NNN-short-name")` in MATLAB R2025b on Nick's
   Mac (see CLAUDE.md for the background command). Read
   `experiments/NNN-short-name/summary.txt`. If the physics battery fails,
   fix or abandon the change; don't weaken the battery.
1. Apply the acceptance rule in `FRAMEWORK.md`. Keep: merge into `best`.
   Reject: discard the branch.
1. Append the row to `results/results.tsv` and finish the log entry,
   including whether the prediction came true.

## Rules

- Simpler wins. A small gain that adds complexity isn't worth it.
- If you can't explain why a change works physically, don't keep it.
- Never tune on held-out folds. Fitted parameters are fit on the training
  sites of each fold only.
- Fail loud: use `error()` for unexpected conditions, never silent NaN.
- Stop and report when three tiers in a row produce no accepted change, or
  when every cell is within 1 dB of the noise floor.
- After every 10 accepted changes, stop for the independent reviewer agent
  (FRAMEWORK.md, Agent roles). Fix or revert what it finds before going on.
- Worker agents follow the current batch plan in `experiments/batches/`
  exactly. If a step fails, a spec is ambiguous, or the code needs more than
  the plan says, stop and hand back to the planner instead of improvising.
