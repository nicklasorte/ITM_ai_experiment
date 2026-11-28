# Agent-driven changes to the Irregular Terrain Model: results through B39

DRAFT for Nick's read. Not for release outside the repo until Nick reviews
it (CLAUDE.md). Planner: Claude Opus 5.5, 2026-11-25; rev 2 2026-11-28.
This draft covers work through B39. Rev 1 (through B32) is kept for the
record.

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
spread, under the 0.3 dB threshold and the 1.0 dB complexity cost. Phase
plans rev 5 and rev 6 recommended stopping the scored search on the frozen
inputs, and Nick accepted the stop on 2026-11-28. B33 to B39 were
diagnostics. They found where 707's remaining errors sit, but no change
worth scoring (section 3b). One outside test used
data the search never saw (OT Report 75-74, B31 and B32): on the change in loss
from a 3 m to a 10 m receiver, 707 was no better than stock ITM. No Tier B
(lockbox) score exists; apart from section 3a (B31, B32), all numbers below
come from data the search was run on.

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
| B32 (D32) | 707 against stock ITM on measured height contrasts from OT Report 75-74 (data proposal item D3; outside data) | Outcome C: no 3 m to 10 m stratum favors 707, one favors stock | OT 75-74 paths with both heights measured, 10 table-by-band strata (18 to 39 paths each) |

The cell-mean ceiling (`hm_ceiling_rev1.py`) bounds what fixing every cell
mean could do: 1.13 dB on 707's screened composite (9.91 to 8.78), on the
screened development rows.

## 3a. Outside test: OT Report 75-74 (B31, B32)

OT Report 75-74 (Longley and Hufford, 1975, public ITS report) gives 50 %
basic transmission loss on 210 sensor paths at 172.5 and 410.5 MHz, with
transmitters 0.35 m above ground and receivers at 10, 3 and 0.35 m, at
Eglin AFB, Graham Mountain and Hunter Liggett. The search never used it. B31
digitized Tables 7 to 11 (every path read twice) and located the terminals
from the site maps. B32 compared each model's height contrast with the
measured one, under a rule registered before any model run.

- ITM accepts antenna heights from 0.5 m (NTIA `ValidateInputs.cpp`), so
  both models used 0.5 m for the 0.35 m antennas. Nick chose this
  amendment before any loss was computed; only the 3 m to 10 m contrast
  decided. Each model was rerun with the receiver at 0.7 and 1.0 m;
  extrapolating that height dependence down to 0.35 m (an assumption, not
  a model run) puts the receiver part of the clamp at a median 0.07 to
  0.26 dB of the low-antenna contrast.
- 3 m to 10 m contrast, 10 table-by-band strata: no clear difference, and
  one stratum (Graham, later season, VHF) favors stock ITM;
  mean absolute errors are 2.7 to 5.5 dB for both. Two seasons share
  paths at Graham and at Hunter Liggett, so the strata aren't independent.
- Not deciding, and carrying the 0.5 m height offsets for both models:
  both models predict far less loss than measured at Eglin's forested paths
  (mean errors of −14 to −30 dB). Across all five tables at 172.5 MHz, 707's
  absolute error is 2.5 to 5.5 dB lower than stock ITM's at every height,
  because 707 adds loss where both under-predict; at 410.5 MHz neither model
  is consistently lower.

## 3b. Diagnostics after the outside test (B33 to B39)

None of these is scored. Each has a registered rule, and each was checked
by a fresh reviewer.

| Batch | Question | Finding | Population |
| --- | --- | --- | --- |
| B33 | Do OT 75-74's seasons, quantile widths and transmitter height change B32's reading? | The measured loss shifts between seasons on unchanged paths (4 of 8 strata resolved, 1.4 to 2.2 dB); both models predict no seasonal change, by construction. The 0.5 m clamp is minor except at Eglin. | OT 75-74 paths (B32's) |
| B34 (D34c) | Why does a CSV round trip of a profile change ITM's loss? | An integer truncation in ITM's effective-height fit makes loss depend on how the profile spacing is stored: ±20 ULP moves stock ITM by up to 0.36 dB. It's in the stock source too. No patch. | 840 B32 rows |
| B36 | Does a 2D parabolic-equation (PE) reference, from terrain physics alone, fit better than 707? | Outcome N: better than 707 at R1 (−1.65 dB), not resolved at VA. A fresh review then found three defects in the PE, each pushing it toward too little loss. | Gentle open paths at or below 1 GHz: R1 1,427 rows (one receiver site), VA 243 |
| B37 | Which part of 707 adds loss over stock on those R1 rows? | The multi-edge cascade in place of Bullington adds 2.18 of 707's 2.54 dB over stock, where 707 already predicts too much loss. PE repairs stopped at the wide-angle test, which the terrain method can't pass. | B36's R1 rows (model only) |
| B38 | Inside the cascade; land cover at the edges and in the first Fresnel zone | The cascade's secondary edges carry the R1 excess (+2.25 dB; about +9.7 dB on R1's diffraction-mode rows). Forest share in the first Fresnel zone goes with missing loss at R2 and R3 (outcome F−, but it needs R3, whose slope is extrapolated). | B36's R1 rows (model only); 9,501 siting-O uncensored rows |
| B39 | Are the secondary edges a defect? Does canopy height (LANDFIRE EVH) in the Fresnel zone repeat B38? | The secondary edges are mostly separate obstacles that the isolation test counts by design, so there's no defect to repair. With canopy height, the association holds at R2 only (about 10 dB per 10 % of the path), so the outcome is none. | B36's R1 rows (model only); all 12,570 siting-O uncensored rows |

What these leave (planner's reading):

- **R1:** 707 predicts too much loss on gentle open paths, from secondary
  edges that the cascade counts by design. Changing that would trade a
  published construction for a fit to one receiver site.
- **R2,** where 707's error is largest: paths whose first Fresnel zone has
  canopy reaching into it have more loss than 707 predicts. A
  Fresnel-weighted vegetation term is the one physics lead left, and it's
  backed by one site.
- What has paid off overall:
  `experiments/proposals/what_paid_off_rev1.md`.

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
job. In B32 the one-trial check found ITM's 0.5 m height limit before any
result existed, so the rule could be amended without seeing outcomes.

From B36 to B39, the fresh reviewer changed every results section:

- B36: the PE's range average was one point on most rows.
- B37: the registration got a switch's scope wrong.
- B38: the forest outcome depended on one site with extrapolated
  slopes.
- B39: a "separated" finding was partly built into the method.

Two habits came out of this and were proposed for the loop-graph-workflow
skill: check every assumption about the code before registering, and
commit tests before the code they test.

## 5. Limits

- No Tier B score. The Tier B sets are validation sets, not a blind test,
  because humans have already compared models on them (FRAMEWORK.md,
  lockbox caveat).
- Selection: 38 candidates were scored against these sites (35 through B28, plus B29's three). B33 to B39 read the same development data many more times, as diagnostics.
- 707's terminal clutter rests on the Phase 2 siting code and an assumed
  15 m clutter height; vegetation height along the paths isn't an input.
  LANDFIRE canopy height (B30, B39) is from 2016, decades after the
  measurements.
- The PE reference (B36, B37) is valid only on gentle paths at or below
  1 GHz, with a narrow-angle terrain method.
- Height contrasts in the development data rest on one fixed receiver at
  R1. The outside test (B32) adds three areas at VHF and UHF, but ITM can't
  represent its 0.35 m antennas.

## 6. Next steps

1. The scored search is stopped (Nick, 2026-11-28). Reopening it for one
   candidate, such as a Fresnel-weighted vegetation term from a published
   model screened first, would be Nick's call.
2. R4 (ITS Phase 2's grove site) is now used: B35 ran on 2026-11-28 as
   an agent run (Nick's decision 1 (a)). At the tower top, 707 was no
   better than stock (outcome C; worse at 230 MHz). Inside the grove,
   ITM's own height gain was about 12 dB short and P.2108's slightly over,
   but that comparison is descriptive because 29.5 % of cells were
   dropped. Details: `experiments/batches/B35.md` section 6.
3. A validation score on the Tier B sets, if Nick chooses to run it.
4. Data proposal item D2 (Ofcom frequency contrasts) waits on a human check
   on Ofcom's site that only Nick can clear.

## Sources

- `results/results.tsv`; `experiments/707r-rescore-screen36/summary.txt`
  and `metrics.json`; `experiments/LOG.md`; batch plans B21 to B32;
  `experiments/D32-ot7574-heights/`; batch plans B33 to B39 and their
  `experiments/D3x-*` folders; FRAMEWORK.md.
- ITU-R P.452-18, P.526-11, P.526-16, P.2108-1, P.1812-8, P.2001-5.
- NBS Technical Note 101 (Rice, Longley, Norton and Barsis, 1967).
- OT Report 75-74 (Longley and Hufford, 1975).
