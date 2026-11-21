# Working plan

Rev 1, 2026-11-21. The stages, gates, and decisions between now and a
write-up. [FRAMEWORK.md](../FRAMEWORK.md) holds the design; this file holds
the order of work. The planner updates it at the end of each batch.

## Goal

A defensible headline result: a cited, physics-based change to ITM that
beats both the recalibrated-ITM baseline and P.452 on held-out sites, with
a write-up suitable for ISART or Radio Science
([docs/PUBLICATION_LITERATURE.md](PUBLICATION_LITERATURE.md)).

**Stretch target**, all held-out, all at once:

| Measure | Target | Stock ITM | P.452 |
| --- | --- | --- | --- |
| Phase 2 cell-balanced RMS | ≤ 14.1 dB | 18.3 | 14.1 |
| Censored-bound violations | ≤ 28 % | 28.0 % | 65.6 % |
| Long-term shape RMS | ≤ stock ITM | 5.2 | 9.9 |

P.452 can't meet the censored target, so meeting all three is the headline.

## Where things stand (2026-11-21)

- Stage 0 is done. All 840 profiles are stored as CSV; 325 long-term paths
  (548 distributions) and 515 Phase 2 paths are rebuilt from them and the
  splits are re-frozen.
- Stock-ITM baseline on the full data: composite 16.0 dB (Phase 2 cell 18.3,
  long-term level 24.6, shape 5.2). Parity with the stored baseline holds to
  7 × 10⁻¹³ dB. P.452: 14.2; P.2001: 14.0.
- Recalibration R01 (6 constants, cross-validated, full data): composite
  12.4 dB, but it fails the censored gate (55.9 % violations) and the
  ridge-continuity check. Not a kept variant.
- `guard` CI, `Agent-Role` trailers, the three-reviewer rule, stability
  log, shadow folder, and the experiment archive (Pareto front plus
  MAP-Elites cells) are in place. No agent experiments have run yet.

## Stage 0: finish the data (done 2026-11-21)

1. When extraction finishes, write all profile CSVs and the index, rebuild
   both link tables from the CSVs, and re-freeze the splits.
1. Run `run_eval_rev1(Tag="000-baseline", Parity=true)`; update the README
   and LOG baseline numbers to the full 325-path long-term set.

**Gate:** exact parity, and `guard` passes on the new data.

## Stage 1: define a real gain

1. **Diagnose long-term level (done, D01).** 14 rows on 10 paths are line
   of sight in the 1971 record but blocked on the 30 m profile; ITM errs by
   +51 dB on average there, and every terrain model misses. Without them,
   ITM's level error is 16.9 dB. The rest concentrates at 3–10 GHz (supports
   H7) and on diffraction paths where ITM misses and P.2001 doesn't (B01).
1. **Noise floor.** Bootstrap the composite and each objective over paths
   within site, and report the 95 % interval. Replace the 0.3 dB keep
   threshold (marked `TODO` in FRAMEWORK.md) with the measured value.
1. **R02, constrained recalibration.** Rerun `cv_calibrate_rev1` on the full
   data with the censored and continuity gates in the objective. R02
   becomes the comparator every agent result is reported against.

**Gate:** R02 passes both gates. If it can't, record that as a finding:
retuning alone can't repair ITM without breaking physics.

## Stage 2: batch B01, diffraction

The largest error is diffraction-dominated mountain paths (site R2).
Hypotheses from [docs/WORKING_PAPER_FINDINGS.md](WORKING_PAPER_FINDINGS.md):

- H1: multi-edge diffraction, Deygout or Epstein-Peterson (P.526), with
  delta-Bullington as a bound
- H2: diffraction loss at the path distance, not extrapolated from d3/d4
- H3: the propagation region chosen from the actual horizons

The planner writes `experiments/batches/B01.md`: each experiment's parent
(from `best` or the archive), exact change, P.526 section and equation
numbers, and predicted effect per site. The Haiku worker runs it. After 10
kept changes, three independent reviewers try to break the result.

**Gate:** at least one kept change beats R02 on Phase 2 without raising
censored violations.

## Stage 3: batches chosen by B01's results

- **B02, time variability.** R01's fitted constants say ITM's time spread
  is about 25 % too wide. Test narrower, published curves against the
  long-term shape score, and keep ITM's enhancement side, because the ITU
  models are too optimistic at 1 % (H6).
- **B03, line of sight and smooth earth.** Smooth-earth loss only as an
  excess over the other terms (delta construction, H4), and fix the Δh
  window that breaks reciprocity (H8).
- Parents come from the archive, favoring under-explored cells.

## Stage 4: show it holds up

1. **Ablations:** remove each kept change in turn and report what it bought.
1. **Lockbox:** one scoring run on the sealed set, once.
1. **Shadow run:** the final variant beside stock ITM on one public-input
   study (`experiments/shadow/`).
1. **Write-up:** REFORMS checklist, the R01 and R02 comparison, the
   archive trade-off figure, and the negative results.

## Decisions for Nick

| Decision | Needed by | Options |
| --- | --- | --- |
| Which dataset is the lockbox, given that some candidates have been seen | Stage 4 | See FRAMEWORK.md, Tier B |
| Which public-input study gets the shadow run | Stage 4 | — |
| Keep the censored gate at +1 point over the current best | Stage 1 | R01 shows this gate is what stops optimistic fits |
| How to treat the 14 rows where the record says line of sight but the profile is blocked (D01) | Before B01 | Keep in the frozen set; screen them out by a rule fixed now; or score both and report both |
| Set the `RESTRICTED_TERMS` repository secret | Now | Settings → Secrets and variables → Actions |

## Checks at each stage

- `guard` passes on every push.
- Every number in a LOG entry or the README matches `metrics.json` for that
  run.
- Three-reviewer pass before any result is called kept for the write-up.
- Nick reads any result before it leaves the repository.
