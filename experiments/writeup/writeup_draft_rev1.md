# Agent-driven changes to the Irregular Terrain Model: results through B29

DRAFT for Nick's read. Not for release outside the repo until Nick reviews
it (CLAUDE.md). Planner: Claude Opus 5.5, 2026-11-25.

## Summary

An AI agent loop changed a copy of the MATLAB Irregular Terrain Model (ITM,
Longley-Rice) one physically justified part at a time and kept a change
only if it improved the score against ITS measurements and passed a physics
battery. One change was kept: 707. It lowers the composite error from
16.0 dB (stock ITM) to 12.5 dB and the censored-bound violations from
28.0 % to 22.8 %, on the development data. Of 35 scored candidates
(`results/results.tsv`, excluding the baseline and the R01, R02 and R03
references), only 707 was kept.
Later work (B18 to B29) found no further keep: structural candidates were
rejected or closed, and calibrating 707's existing constants found no gain
in training. The search on the frozen inputs is stopped. No lockbox score
exists, and all numbers below come from data the search was run on.

## 1. Setup

| Item | Value | Source |
| --- | --- | --- |
| Model | ITM point-to-point, MATLAB port `nicklasorte/matlab_itm` at 9bd6a4e | `experiments/707r-rescore-screen36/summary.txt` |
| Data | ITS Phase 2 UHF spot measurements (sites R1, R2, R3 in Colorado; VA in Virginia), 230 to 9200 MHz; ITS long-term distributions (325 paths) | `data/SOURCES.md`, `results/results.tsv` row 000 |
| Terrain | Fixed: Phase 2 surveyed profiles resampled to 30 m; long-term paths from USGS 3DEP or Copernicus 30 m | `data/SOURCES.md` |
| Score | Composite of Phase 2 cell-balanced RMS at 50 %, long-term level RMS and long-term shape RMS; also a screened composite with 36 rows left out | `eval/score_rev1.m`, `summary.txt` |
| Acceptance | Screened gain ≥ 0.3 dB with the Bonferroni-adjusted paired bootstrap bound above zero; full composite not worse by more than 0.3 dB; no site worse by more than 0.5 dB; censored violations up at most 1 point; physics battery PASS | FRAMEWORK.md, acceptance rule |
| Comparators | Stock ITM; constrained recalibration of stock ITM (R02); ITU-R P.452 and P.2001 on the same profiles | `results/results.tsv`, `707r-rescore-screen36/metrics.json` |

## 2. The kept change (707)

707 replaces the knife-edge part of ITM's diffraction loss with the delta
construction of ITU-R P.452-18 eq. (38) to (40): L = L_ba + max(A_s − L_bs, 0).
L_ba is a profile-based obstruction loss on the actual path: the ITU-R
P.526-11 §4.4.2 cascade, with secondary edges weighted by isolation (ITU-R
P.526-16 §2.5). L_bs is the same loss on the P.452-18 obstruction-adjusted
smooth path (Attachment 2, §5.1.6.2 to 5.1.6.3). A_s is ITM's own
smooth-earth loss on that path, in place of P.452's spherical-earth term.
707 bounds the result with ITM's troposcatter line and adds ITU-R P.2108-1
§3.1 terminal clutter loss with the base loss at max(h, R). Sources:
`itm_variant/params_exp.m` comments, `results/results.tsv` row 707, B21.

Population for every number in the table: the full development set (Phase 2
and long-term), scored once with the current screen (`707r-rescore-screen36`).

| Metric | Stock ITM | 707 | ITU-R P.452 | ITU-R P.2001 |
| --- | --- | --- | --- | --- |
| Composite (dB) | 16.0 | 12.5 | 14.2 | 14.0 |
| Screened composite (dB) | 11.9 | 9.9 | 9.8 | 9.7 |
| Phase 2 path RMS (dB) | 16.2 | 12.7 | 14.8 | 14.0 |
| Site RMS R1 / R2 / R3 / VA (dB) | 13.3 / 28.6 / 9.0 / 15.4 | 10.5 / 18.2 / 6.8 / 12.9 | 9.9 / 19.4 / 6.4 / 15.8 | 10.1 / 19.4 / 6.4 / 14.7 |
| Censored-bound violations | 28.0 % | 22.8 % | 65.6 % | 65.7 % |
| Physics battery | PASS | PASS | n/a | n/a |

What this shows, scoped to the development set:

- 707 is better than stock ITM on every row of the table.
- 707 is better than P.452 and P.2001 on the full composite, Phase 2 path
  RMS, R2, VA and censored violations. It is slightly worse on the screened
  composite (by 0.1 to 0.2 dB) and at R1 and R3 (by 0.4 to 0.6 dB).
- R02, stock ITM with its time-spread constant recalibrated under the same
  gates, scores 15.9 dB composite (results.tsv row R02), so most of 707's
  gain doesn't come from constants.
- The 707 result was selected from many candidates on this data, so it is
  optimistic as an estimate of error on new data.

## 3. What was ruled out after 707

| Batch | What it tested | Outcome | Population |
| --- | --- | --- | --- |
| 711, 712 | Alternatives to parts of 707 | Rejected (composite worse; site gates failed) | Full development set |
| 1301, 1901 | ITU-R P.452-18 troposcatter bound | Rejected (gain under the 0.3 dB threshold) | Full development set |
| 1804 | ITM effective heights in the smooth reference | Rejected (screened gain −0.59 dB; R2 +4.5 dB) | Full development set |
| B21 | Other public smooth-surface constructions (P.1812-8, P.2001-5) | No candidate: they use the same obstruction adjustment as 707 | Source review |
| B23 to B27 | Height-contrast diagnostics and the NBS TN 101 height-gain terms | No candidate; 707 and stock ITM don't bracket the measured height contrast | R1 open blocked-blocked height pairs (149 pairs, 29 bases, one fixed receiver) |
| B25 | Spherical-earth reference (P.452-18 §4.2.2) | No candidate | One row (R1-005-T5_O, 230 MHz) plus by-set summaries |
| B28 | Calibrating 707's constants (diffraction weights, line-of-sight blend, time spread) | No score; fold 4 infeasible under the calibrator's stock-referenced censored rule; no training gain in folds 1 to 3 for two groups, 0.09 to 0.20 dB for the time spread | Training rows, folds 1 to 3 |
| B29 | B28 with the censored rule referenced to 707 | TODO: fill in after the run | TODO |

The cell-mean ceiling (`hm_ceiling_rev1.py`) bounds what any change that
fixes cell means can do: 1.13 dB on the screened composite (9.91 to 8.78),
on the full development set.

## 4. Harness lessons

Three evaluator defects surfaced in B28, each found only when a long job
failed:

1. A report-only battery field broke the calibrator's constraint loop
   (fixed in PR #14).
2. The calibrator didn't pass row metadata that terminal clutter needs
   (PR #15).
3. The calibrator's censored rule referenced stock ITM, which a kept variant
   can fail by construction (PR #17, option `CensoredRef`).

PR #16 added a smoke check (`Smoke=true`), a smoke test on the best
variant, and `program.md` rules to run a one-trial check before any long
job.

## 5. Limits

- No lockbox score: Tier B sets were never scored, so there is no blind
  estimate of error on new data.
- Selection: 35 candidates were scored against these sites; 707's numbers
  are the best of those.
- Vegetation is known only as a land-cover class (NLCD 2001), decades after
  the 1960s measurements.
- Height contrasts rest on one fixed receiver at R1.

## 6. Next steps

1. Data proposal rev 1 (`experiments/proposals/data_proposal_rev1.md`):
   a LANDFIRE vegetation-height diagnostic first, Ofcom frequency contrasts
   second. Both need Nick's approval.
2. A blind score on the Tier B sets, if Nick chooses to run it.

## Sources

- `results/results.tsv`; `experiments/707r-rescore-screen36/summary.txt`
  and `metrics.json`; `experiments/LOG.md`; batch plans B21 to B29.
- ITU-R P.452-18, P.2108-1, P.1812-8, P.2001-5.
- NBS Technical Note 101 (Rice, Longley, Norton and Barsis, 1967).
