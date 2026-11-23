---
name: itm-register-batch
description: Plan an ITM_ai_experiment batch and register its predictions before any run (smoke test, history-matching screen, Bnn.md, commit, push). Use when asked to plan, register or set up a new batch.
---

# Register an ITM_ai_experiment batch

Role: planner. Repo: `~/github/ITM_ai_experiment`. Read CLAUDE.md,
FRAMEWORK.md and program.md first; they win over this skill.

Predictions must be committed and pushed before any evaluator run. A batch
whose predictions were written after a score was seen isn't a valid test.

## Steps

1. **Find the parent.** Read the latest LOG entries and `results/results.tsv`.
   The parent is `best`, currently 707
   (`Best="707-cascaded-isolated-clutter-at-r"`) unless the LOG says
   otherwise. Read the parent's `experiments/<tag>/summary.txt` for site
   means and RMS.
2. **Pick hypotheses.** Use `experiments/proposals/` (research package
   H01–H21, the headroom map when it exists). Each experiment needs:
   - a public source with section and equation numbers
   - one sentence of physical rationale
   - the switch or code change, with defaults that keep stock behaviour
3. **Code, if needed.** Edit only `itm_variant/`. Add a switch in
   `params_exp.m` with a default that reproduces the parent. Add a test in
   `itm_variant/tests/test_diffraction_rev1.m`. Run the suite; every test
   must pass. Version-suffix new files (`_rev1`).
4. **Parity.** At default settings the variant must match the stored
   baseline within 1e-9 dB on every Phase 2 and long-term row. Use
   `run_eval_rev1(Tag="000-baseline", Parity=true)` as a batch job, or the
   interactive check in B12.md if the queue is down.
5. **Smoke test (model only).** Use the `itm-smoke-test` skill. Never read
   a measured-loss column in this step.
6. **History-matching screen.** Run:

   ```bash
   python3 experiments/batches/hm_screen_rev1.py \
     --parent experiments/<parent-tag> --delta experiments/batches/<deltas>.csv \
     --floor results/model_floor_rev1.csv
   ```

   - CANNOT_PASS or CERTAIN_HARM: don't run it. Record it in the plan as
     screened out, with the bound.
   - NOT_RULED_OUT: carry the central estimate and the required ρ into the
     predictions. If the required ρ is above about 0.5 against 707, explain
     why the change would line up with the current error that strongly.
7. **Write `experiments/batches/Bnn.md`.** Follow `B12.md`:
   - Purpose, Code, Checks before the runs, Smoke test, Screen, Logged
     evidence, Experiments.
   - For each experiment: `Change (launcher overrides):` line with the full
     JSON, `Source:`, numeric `Predicted:` values per site and for
     composite, screened gain and censored violations, and `Confidence:`.
   - Record any deviation from a proposal's text before any score.
8. **Commit and push.** Stage only `itm_variant/`, `experiments/` and
   `results/`. Run
   `python3 .github/scripts/guard_rev1.py --range <base>..HEAD`. Commit
   message: what changed and "score delta: none", then the
   `Agent-Role: planner` trailer. Push to `main`.

## Stop and report instead of guessing when

- a test fails or parity exceeds 1e-9 dB
- a source can't be found for a constant (mark it `TODO` and don't run)
- the change would need an edit to `eval/` or `data/` (that's a PR for Nick)
