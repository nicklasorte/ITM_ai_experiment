# Agent-driven changes to the Irregular Terrain Model: results through B29

DRAFT for Nick's read. Not for release outside the repo until Nick reviews
it (CLAUDE.md). Planner: Claude Opus 5.5, 2026-11-25. This draft covers
work through B29.

## Summary

An AI agent loop changed a copy of the MATLAB Irregular Terrain Model (ITM,
Longley-Rice) one physically justified part at a time and kept a change
only if it passed the acceptance gates, the physics battery and a reviewer
pass. One change was kept: 707. It lowers the composite error from 16.0 dB
(stock ITM) to 12.5 dB and the censored-bound violations from 28.0 % to
22.8 %, on the development data. Of 35 scored candidates
(`results/results.tsv`, excluding the baseline and the R01, R02 and R03
references; 38 with B29's three), only 707 was kept; several had lower
composites but failed the censored gate. Work after 707 (through B29) found
no further keep. Structural candidates were rejected or closed. Calibrating
707's constants in cross-validation (B29) gave no held-out gain for the
diffraction and line-of-sight constants and +0.11 dB screened for the time
spread, under the 0.3 dB threshold and the 1.0 dB complexity cost. Phase plan rev 5
recommends stopping the search on the frozen inputs. No Tier B (lockbox)
score exists, and all numbers below come from data the search was run on.

## 1. Setup

| Item | Value | Source |
| --- | --- | --- |
| Model | ITM point-to-point, MATLAB port `nicklasorte/matlab_itm` at 9bd6a4e | `experiments/707r-rescore-screen36/summary.txt` |
| Data | ITS Phase 2 spot measurements (sites R1, R2, R3 in Colorado; VA in Virginia), 76 to 9190 MHz; ITS long-term distributions (325 paths) | FRAMEWORK.md (data), `data/SOURCES.md`, `results/results.tsv` row 000 |
| Terrain | Fixed: Phase 2 surveyed profiles resampled to 30 m; long-term paths from USGS 3DEP or Copernicus 30 m | `data/SOURCES.md` |
| Score | Composite of Phase 2 cell-balanced RMS at 50 %, long-term level RMS and long-term shape RMS; also a screened composite with 36 rows left out | `eval/score_rev1.m`, `summary.txt` |
| Acceptance (current rule, from 2026-11-23) | Screened gain ≥ 0.3 dB with the Bonferroni-adjusted paired bootstrap bound above zero; full composite not worse by more than 0.3 dB; no site worse by more than 0.5 dB; censored violations up at most 1 point; physics battery PASS; 0.5 dB per new free parameter; reviewer pass. 707 was kept on 2026-11-21 under the earlier rule and rescored under the current screen. | FRAMEWORK.md, acceptance rule |
| Comparators | Stock ITM; recalibrated stock ITM (R01 unconstrained, R02 constrained); ITU-R P.452 and P.2001 on the same profiles | `results/results.tsv`, `707r-rescore-screen36/metrics.json` |

## 2. The kept change (707)

707 replaces the knife-edge part of ITM's diffraction loss with the delta
construction of ITU-R P.452-18 eq. (38) to (40): L = L_ba + max(A_s − L_bs, 0).

- L_ba is a profile-based obstruction loss on the actual path: the ITU-R
  P.526-11 §4.4.2 cascade, with secondary edges weighted by isolation (ITU-R
  P.526-16 §2.5).
- L_bs is the same loss on the P.452-18 obstruction-adjusted smooth path
  (Attachment 2, §5.1.6.2 to 5.1.6.3).
- A_s is ITM's own smooth-earth loss on that path, in place of P.452's
  spherical-earth term.
- The result is bounded by ITM's troposcatter line. This bound has no
  published source (LOG, phase plan rev 4 decisions).
- ITU-R P.2108-1 §3.1 terminal clutter loss is added at terminals with
  Phase 2 siting code C (mapped to trees and forest, with an assumed
  representative height R = 15 m, a design choice), with the base loss at
  max(h, R), and the height-gain term held at its 3 GHz value above 3 GHz.

Sources: `itm_variant/params_exp.m` comments, `results/results.tsv` row 707,
B21.

Population for every number in the table: the development set scored with
the current screen (`707r-rescore-screen36`). P.452 and P.2001 were scored
on fewer rows: P.452 covers 96.9 % of Phase 2 rows (VA 2,110 of 2,562) and
not all long-term rows or percentages, so their columns aren't like-for-like
with ITM and 707.

| Metric | Stock ITM | 707 | ITU-R P.452 | ITU-R P.2001 |
| --- | --- | --- | --- | --- |
| Composite (dB) | 16.0 | 12.5 | 14.2 | 14.0 |
| Screened composite (dB) | 11.9 | 9.9 | 9.8 | 9.7 |
| Phase 2 path RMS (dB) | 16.2 | 12.6 | 14.8 | 14.0 |
| Site RMS R1 / R2 / R3 / VA (dB) | 13.3 / 28.6 / 9.0 / 15.4 | 10.5 / 18.2 / 6.8 / 12.9 | 9.9 / 19.4 / 6.4 / 15.8 | 10.1 / 19.4 / 6.4 / 14.7 |
| Censored-bound violations | 28.0 % | 22.8 % | 65.6 % | 65.7 % |
| Physics battery | PASS | PASS | n/a | n/a |

What this shows, scoped to the development set:

- 707 has lower error than stock ITM on every error row of the table. Both
  pass the physics battery. 707 fails the report-only height check on real
  paths (worst excess 27.0 dB against a 1 dB limit; `summary.txt`).
- On the rows each model was scored on, 707 has a lower full composite,
  Phase 2 path RMS, R2 and VA RMS, and far fewer censored violations than
  P.452 and P.2001. It is 0.1 to 0.2 dB worse on the screened composite and
  0.4 to 0.6 dB worse at R1 and R3. The coverage difference above limits
  these comparisons.
- Recalibrating stock ITM's six constants without gates (R01) reached a
  12.4 dB composite but failed the censored gate (55.9 %) and the physics
  battery. Under the gates (R02), recalibration reached 15.9 dB. Inferred:
  under the gates, most of 707's gain doesn't come from constants.
- 707 was selected from 35 candidates on this data, so its numbers are
  optimistic as an estimate of error on new data.

## 3. What was ruled out after 707

| Batch or run | What it tested | Outcome | Population |
| --- | --- | --- | --- |
| 711, 712 | P.2108-1 at open terminals by NLCD 2001 class, added to 707 | Rejected (composite worse; site gates failed) | Development set |
| 1301 | P.452-18 troposcatter in place of ITM's, keeping 707's bound | Rejected (composite gain −0.30 dB, 95 % −0.48 to −0.02) | Development set |
| 1901 | P.452-18 troposcatter as the bound | Rejected (screened gain +0.04 dB, under 0.3) | Development set |
| 1804 | ITM effective heights in the smooth reference | Rejected (screened gain −0.59 dB; R2 +4.5 dB) | Development set |
| B21 | Other public smooth-surface constructions (P.1812-8, P.2001-5) | No candidate: they use the same obstruction adjustment as 707 | Source review |
| B23, B24 | Height, clutter and frequency contrast diagnostics and their sensitivities | No candidate | Detected Phase 2 pairs by site and stratum (for example R1 open blocked-blocked height pairs; 1,400 clutter pairs; R1 and VA frequency pairs) |
| B25 | Spherical-earth reference (P.452-18 §4.2.2) | Closed by the screen: cannot pass (screened gain at most +0.11 dB) | Development set (screen); the height-inversion finding is one row, R1-005-T5_O at 230 MHz |
| B27 | Whether 707 and stock ITM bracket the measured height contrast (precondition for the NBS TN 101 height-gain terms) | Outcome C (no bracket), so the height-gain terms weren't tested | R1 open blocked-blocked height pairs (149 pairs, 29 bases, one fixed receiver) |
| B28 | Calibrating 707's constants (diffraction weights, line-of-sight blend, time spread) | No score; fold 4 infeasible under the calibrator's stock-referenced censored rule; no training gain in folds 1 to 3 for two groups, 0.09 to 0.20 dB for the time spread | Training rows, folds 1 to 3 |
| B29 | B28 with the censored rule referenced to 707 (2901 to 2903) | Rejected: 2901 and 2902 gain 0.00 dB; 2903 screened +0.11 dB (99.5 % bound −0.06), long-term shape RMS 5.17 to 4.97 dB | Held-out rows, five-fold cross-validation, development set |
| B30 (D30) | LANDFIRE 2016 vegetation height near the terminals against 707's errors (diagnostic, data proposal item D1) | Outcome B: only R2 shows a resolved negative slope; in-sample RMS gain 0.26 dB | Uncensored siting-O Phase 2 rows (12,570 rows, 400 paths) |

The cell-mean ceiling (`hm_ceiling_rev1.py`) bounds what fixing every cell
mean could do: 1.13 dB on 707's screened composite (9.91 to 8.78), on the
screened development rows.

## 4. Harness lessons

B28 hit two evaluator defects and one rule mismatch, each found only when a
long job failed:

1. A report-only battery field broke the calibrator's constraint loop
   (fixed in PR #14).
2. The calibrator didn't pass row metadata that terminal clutter needs
   (fixed in PR #15).
3. Rule mismatch, not a defect: the calibrator's censored rule references
   stock ITM, while the acceptance rule references the parent. 707 fails the
   stock reference on fold 4 at its own constants. PR #17 added the option
   `CensoredRef="base"`, which B29 used.

PR #16 added a smoke check (`Smoke=true`), a smoke test on the best
variant, and `program.md` rules to run a one-trial check before any long
job.

## 5. Limits

- No Tier B score. The Tier B sets are validation sets, not a blind test,
  because humans have already compared models on them (FRAMEWORK.md,
  lockbox caveat).
- Selection: 38 candidates were scored against these sites (35 through B28, plus B29's three).
- 707's terminal clutter rests on the Phase 2 siting code and an assumed
  15 m clutter height; vegetation height along the paths isn't an input.
- Height contrasts rest on one fixed receiver at R1.

## 6. Next steps

1. Data proposal rev 1 (`experiments/proposals/data_proposal_rev1.md`): a
   LANDFIRE vegetation-height diagnostic first, Ofcom frequency contrasts
   second. Both need Nick's approval.
2. A validation score on the Tier B sets, if Nick chooses to run it.

## Sources

- `results/results.tsv`; `experiments/707r-rescore-screen36/summary.txt`
  and `metrics.json`; `experiments/LOG.md`; batch plans B21 to B29;
  FRAMEWORK.md.
- ITU-R P.452-18, P.526-11, P.526-16, P.2108-1, P.1812-8, P.2001-5.
- NBS Technical Note 101 (Rice, Longley, Norton and Barsis, 1967).
