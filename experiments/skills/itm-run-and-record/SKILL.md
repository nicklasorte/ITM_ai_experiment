---
name: itm-run-and-record
description: Run a registered ITM_ai_experiment batch, apply the acceptance rule, and record results (launch, collect, decide, record_run, LOG, branches, rebuild best, push). Use when asked to run a batch whose predictions are already pushed.
---

# Run and record a registered batch

Role: worker. Run the plan in `experiments/batches/Bnn.md` exactly as
written. Hand back to the planner on any error or ambiguity.

## Before launching

1. `git pull`. Confirm the commit that registers this batch's predictions is
   on `origin/main`. If it isn't, stop: the batch isn't registered.
2. Run the `itm-batch-health` skill.
3. Skip any experiment the plan marks screened out (CANNOT_PASS or
   CERTAIN_HARM).

## Physics battery

Run the batch's battery script (pattern: `experiments/batches/b12_battery_rev1.m`)
as a batch job. A setting that fails any check except the report-only
`height_gain_real` is rejected without scoring. Record that and continue
with the others.

## Runs

```matlab
addpath(fullfile(root, 'experiments', 'batches'));
jobs = launch_runs_rev1(["<id>-<name>" ...], ["<overrides JSON>" ...], "<best tag>");
done = collect_runs_rev1(jobs);   % call again until it returns true
```

Use the tags and override JSON from the plan's `Change (launcher
overrides):` lines, character for character.

## Decide (FRAMEWORK.md acceptance rule)

Keep only if all of these hold:

- composite and screened gains over `best` of at least 0.3 dB, each with a
  paired 95 % interval above zero
- no site RMS worse than `best` by more than 0.5 dB
- censored violations at most 29.0 %, reported by site
- physics battery passes

Anything else is a reject. Never round a near-miss up.

## Record

1. For each run:

   ```bash
   python3 -I experiments/batches/record_run_rev1.py <tag> \
     --plan experiments/batches/Bnn.md --best <best tag> --decision "<keep|reject (reason)>" --write
   ```

2. Write the LOG entry from the draft. Compare every registered prediction
   with the result, number by number: held, or missed by how much.
3. Append the batch's row to `results/batch_stability.tsv` and the
   planner's short analysis to `Bnn.md`.
4. **Branches.** A kept run goes to `exp/NNN`; a rejected run goes to
   `arc/NNN`.
5. **If a run is kept:**
   - Rebuild `best` as `main` plus the kept switch lines. Set each line by
     name, and don't cherry-pick.
   - Note in the LOG that the three-reviewer pass is due if this is the
     10th keep since the last pass.
6. Run `python3 .github/scripts/guard_rev1.py --range <base>..HEAD`. Commit
   with what changed and the score delta, then the `Agent-Role: worker`
   trailer. Push.

## Report back

For each run, give:

- composite and screened gain against `best`
- the four site RMS and mean values, and censored violations by site
- the decision and its reason
- how each prediction held up
- commit hashes and anything that stopped the run

Results leave the repo only after Nick reads them.
