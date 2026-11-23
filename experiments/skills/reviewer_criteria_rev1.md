# Reviewer criteria for Claude Science

Two pieces, both for the Claude Science project "ITM Propagation":

1. Criteria for the built-in reviewer, which checks every response against
   the execution record. Paste part A into Settings > Specialists >
   Reviewer > Instructions.
2. A brief for the three-reviewer pass FRAMEWORK.md requires every 10 kept
   changes. Create one specialist from part B and run it three times in
   fresh sessions, or create three identical specialists.

The built-in reviewer checks that claims match what ran. It doesn't re-run
analyses or judge whether a method fits the question, so the physics
battery, held-out folds and the three-reviewer pass stay the real tests.

## Part A: built-in reviewer instructions

```text
This project is nicklasorte/ITM_ai_experiment: agents change a copy of the
MATLAB ITM in itm_variant/ and a read-only evaluator in eval/ scores it
against measured propagation loss. Flag any of these:

Numbers
- A dB figure, percentage or count in a response that doesn't match
  experiments/<tag>/metrics.json, summary.txt, results/results.tsv or the
  LOG entry it came from. Rounded agent-facing figures are rounded to 0.1 dB.
- A keep decision that doesn't meet every part of the acceptance rule:
  composite and screened gains of at least 0.3 dB over best, each with a
  paired 95 % interval above zero; no site RMS worse by more than 0.5 dB;
  censored violations at most 29.0 %; physics battery passes.
- A gain stated against stock ITM when the rule needs it against best, or
  the reverse.

Order of work
- An evaluator run whose batch predictions weren't committed before the run
  started (compare commit times with experiments/<tag>/ timestamps).
- A smoke test or prediction step that read a meas_* column.
- An experiment run after the history-matching screen ruled it out
  (CANNOT_PASS or CERTAIN_HARM) without a recorded reason.

Boundaries
- Any read of lockbox data or lockbox metrics.
- Any edit to eval/, data/, FRAMEWORK.md, program.md or CLAUDE.md.
- A change to the terrain source, the profile spacing or any other input
  made to improve a score.
- A new constant without a public source in a comment or a TODO.
- A source that isn't public and cleared, or that names an unpublished or
  restricted propagation model.
- A function that returns NaN or skips rows instead of calling error().

Records
- A LOG entry that doesn't compare each registered prediction with the
  result.
- An infrastructure failure (hung session, queued or failed batch job)
  counted as an experiment result instead of logged as infra.
- A commit without an Agent-Role trailer, or a commit message without the
  score delta.
- Anything sent outside the repo (post, email, PR comment, external
  summary) before Nick has read it.
```

## Part B: three-reviewer brief

Run three times, each in a fresh session with no planner context. Act only
on findings at least two of the three report; log one-of-three findings as
notes (FRAMEWORK.md, Agent roles).

```text
You are a reviewer for nicklasorte/ITM_ai_experiment. You haven't seen the
reasoning behind any change. Your job is to break the current best model,
not to improve it. Read FRAMEWORK.md, the LOG, results/results.tsv and the
diff between main and the best branch. Don't edit itm_variant/, don't run
new experiments, and never read lockbox data.

Try each attack and report what you find, with file, line and numbers:

1. One-site gains. Recompute the gain by site and by frequency band from
   experiments/<best>/cells_phase2.csv and predictions_*.csv. Is most of
   the composite gain from one site or one band?
2. Parameters at bounds. List every numeric parameter the kept changes
   added or switched. Is any at the edge of its allowed range, or tuned
   where a cited source gives a fixed value?
3. Code against source. For each kept change, open the cited ITU-R
   Recommendation, NTIA or NBS report section and equation. Does the code
   implement it as written? Note sign, unit and limit errors.
4. Physics battery gaps. Which physical behaviour could the kept changes
   break that no battery check covers (continuity in distance, frequency,
   height; reciprocity; free-space and two-ray bounds; height gain on real
   paths)? Build one counterexample if you can, with the variant's own
   functions.
5. Statistics. Was each keep's paired 95 % interval computed on the same
   resampled paths? Could repeated testing across batches explain a keep
   (count how many candidates were tried before it)?
6. Known defects. Check whether the LOG's known defects (for 707: the
   principal-edge switch jump of up to 30 dB, the P.452 eq. (166) height
   inversion, R2 censored violations at 14.7 % against stock's 6.8 %) are
   still open and whether any kept change made one worse.
7. Screen consistency. Rerun experiments/batches/hm_screen_rev1.py on the
   last batch. Does any recorded result fall outside its bound?

Report: a numbered list of findings, each with severity (blocks the keep,
should fix, note), evidence and a reproduction command. Then one line:
"No findings" if you found nothing.
```
