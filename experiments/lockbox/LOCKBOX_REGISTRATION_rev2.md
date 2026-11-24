# Lockbox registration, rev 2

Written by Claude Opus 5.5 on 2026-11-24, before any lockbox number exists.
It replaces [rev 1](LOCKBOX_REGISTRATION_rev1.md) after the pre-lockbox
review (section 8). The model is unchanged: rev 2 changes text only.
The agent has not read, and doesn't read, lockbox data or metrics.

Items marked **Nick confirms** are choices for Nick, proposed here. Nick
confirms them, or changes them, before he scores. After that, nothing in this
file changes.

## 1. Frozen model

| Item | Value |
| --- | --- |
| Best run | `707-cascaded-isolated-clutter-at-r` (the only keep) |
| `best` branch commit | `2baa02b26bc3288269d45d3f69934ac864b5325a` (main `e76ca9d` plus 707's five switch lines) |
| `itm_variant/` git tree on `best` | `87f2b757ef211a8e12aabf05b4bc998bf1d79d76` (all 18 files; replaces rev 1's three MD5s, which still match) |
| matlab_itm | `9bd6a4e` (pinned in `eval/itm_exp_paths_rev1.m`) |
| Evaluator | main `aff00bf` (PR #11 merged; report-only fields; composite unchanged) |

This file lives on main, not on `best`; `best` holds only the model. If
`git rev-parse 2baa02b:itm_variant` doesn't print the tree hash above, this
registration is void.

**What the lockbox tests.** Lockbox rows carry no siting flag, so the
P.2108-1 terminal clutter term is zero on them. On every development row
without siting "C", 707 and 604 (`604-delta-cascaded-isolated-bounded`) give
identical predictions. So the lockbox tests 707's diffraction and bound
(604's configuration, which failed the development censored gate at 31.5 %),
not its clutter term. The clutter term stays unvalidated by the lockbox.

## 2. Panel: how each model is run

Each run's `metrics.json` must show the commit and `cfg.overrides` below.
`ITMEXP_OVERRIDES` must be unset in the MATLAB session.

| Model | Role | Commit | Settings |
| --- | --- | --- | --- |
| 707 | The result | `best` 2baa02b | Defaults (they are 707's), no overrides |
| Stock ITM | Baseline | matlab_itm 9bd6a4e | The `itm_lb_*` columns from public `itm_p2p_rev1`, not the variant |
| R02 | Recalibration baseline | main `e76ca9d` | Defaults (stock switches) with `time_minus_scale` = 0.8 from `experiments/R02-constrained-recalibration/params_by_fold.csv` |
| R03 | Continuous comparator | `best` 2baa02b | `{"diffraction":"delta_bullington"}` |
| P.452, P.2001 | Fixed references, report-only | as in each set's link file | Only where the set's link file carries them. Nick has seen these models' lockbox results before (FRAMEWORK.md, lockbox caveat) |

R02 isn't run from `best`: there, the defaults are 707 and `cal` can't be
overridden, so R02 would run as 707 plus 0.8. At 50 % time R02 equals stock
by construction, so on single-percentile sets it is a check, not a
comparison.

## 3. Run conditions

- Profiles: 30 m, `data/export_profiles_rev1`, transmitter first.
- Every lockbox row passes `cfg.row` with `set` = "" (or siting not "C").
  Without `cfg.row`, `clutter_terminal` stops with an error (correct). With
  siting "C", the clutter term would switch on and the run wouldn't match
  section 1.
- Fixed inputs as `eval/settings_rev1.m`; climate and N_0 from each set.
- `eval/` has no lockbox runner. Nick records the MD5 of the scorer he runs
  in the LOG entry with the result.

## 4. Primary endpoint and decision rule (Nick confirms)

- Results are per set and never pooled across sets.
- Primary metric per set: RMS error at 50 %, 707 minus stock ITM, by path,
  with a paired path bootstrap 95 % interval. Where a set has three or more
  sites, a site-cluster bootstrap is reported beside it (path resampling
  ignores site correlation, so its interval is too narrow).
- 707 **confirms** on a set if the point estimate meets the set's
  prediction in section 5 and the path interval excludes zero in that
  direction. It **fails** if the interval excludes zero the other way.
  Otherwise the set is **inconclusive**.
- **Amendment, 2026-11-24, before any lockbox number (Nick's decision).** A
  dry run on 400 development rows showed that the rule above calls a
  larger-than-predicted win inconclusive (gain 6.55 dB, interval −10.0 to
  −3.3, against a predicted 1 to 6 dB). The rule now reads: 707
  **confirms** if the path interval excludes zero in 707's favour and, for
  the VHF set, 707's mean error is between −4 and +4 dB. It **fails** if the
  interval excludes zero the other way. Otherwise it is **inconclusive**.
  Whether the gain fell inside section 5's predicted range is reported
  beside the verdict as a calibration check, not as part of it.
- Everything else in section 6 is secondary and reported without a verdict.
  There are about 3 sets × 3 comparisons × several strata, with no
  multiplicity control; secondary differences aren't claims.

## 5. Predictions (development data only)

| Set | Prediction | Evidence (open rows, uncensored) |
| --- | --- | --- |
| ITS low antenna (230, 416 MHz, antennas under 3 m) | 707 beats stock on RMS. The size depends on terrain roughness: about 1 dB on moderate terrain, 5 dB or more on mountainous terrain. Pooled point gain between 1 and 6 dB | Lower antenna 3 m or under, 150 MHz to 1 GHz, siting not "C" (1,454 rows): pooled stock 14.3, 707 10.1. By site: R1 11.0 to 8.5 at 230 MHz but 9.6 to 9.7 at 410; R3 8.6 to 7.5 and 7.8 to 7.1; R2 22.8 to 13.0 and 23.9 to 13.3. Development has no row with both antennas under 3 m (one terminal is always 6.6 m or higher) |
| ITS Phase 1 VHF (20 to 100 MHz) | 707 beats stock on RMS by 1 to 4 dB, and its mean error is between −4 and +4 dB | Long-term rows under 100 MHz at 50 % (159): stock RMS 11.3, mean −2.6; 707 RMS 8.3, mean −2.8. Phase 2 VA 76 MHz points the other way (707 +6.7 / 9.6, stock −1.2 / 9.3), but 192 of those 452 rows are siting "C" and VA is censored-heavy. Rev 1's prediction used only VA and is withdrawn |
| ITS Phase 1 VHF | R03's RMS is within 1 dB of 707's | 76 MHz: R03's ancestor 703 7.9 against 707 9.6; long-term not computed for R03 |
| ITS low antenna | R03's RMS is within 1 dB of 707's. If R03 wins and the set has no censored rows, that reopens the censored-gate question (decision 5); it doesn't settle it | With the clutter term off, the censored share is the only thing that selected 707 over R03 in development |
| DBSG3 Table VI-2 | Report-only: location medians, not point-to-point; no verdict | — |
| All sets | R02 within 0.5 dB of stock at 50 % | By construction |

Inputs outside the development range: both antennas under 3 m (none in
development); 20 to 40 MHz (a few long-term rows from 40 MHz, none in
Phase 2 below 76 MHz). The battery sweeps run from 50 MHz with 10 m
antennas. The delta path has no frequency-specific branch, so these inputs
won't fail; they are untested.

## 6. Secondary metrics, per set

Unchanged from rev 1, section 4: RMS and mean by band and stratum, the
composite parts that apply, the E2 censored figures if a set has censored
rows, and each model against stock and against 707 (paired path bootstrap,
95 %).

## 7. Known defects, stated before the result

1. **Principal-edge jump** (P.526-11 three-edge cascade): up to 30.6 dB for
   a 0.05 m change in antenna height on R2-020 T1 and T2. 1801 removes it
   but adds 1.08 censored points (limit 1.0), so it isn't frozen (B18).
2. **Height inversion** from the P.452-18 smooth surface: up to 4.5 dB on a
   few R1 paths. No public fix found.
3. **Troposcatter-line bound has no published source** (a design choice).
   It extends ITM's scatter line, fitted at d_ML + 200 and + 400 km, back to
   paths just past the horizon. It binds on 1,345 Phase 2 rows (49 to
   125 km), lowering loss by a median of 12.9 dB, up to 54.6 dB (measured
   as 601 against 602, the bounded and unbounded pair). It
   flattens height gain: the receiver sweep over a 40 m ridge changes by
   +0.2 dB in every bounded run, against −23.3 dB for stock. 707 is 9 to 16
   dB optimistic at R2 from 1,846 to 9,190 MHz.
4. **"Battery pass" is partial.** `height_gain_real` (707: 27.0 dB over the
   limit) and `continuity_pointwise` became report-only after 707 was kept.
5. **Delta replaces A_ref on line-of-sight paths too.** Any `delta_*` form
   replaces ITM's reference attenuation on every point-to-point path, so 707
   also drops ITM's terrain-roughness line-of-sight behaviour.
   `cfg.diffraction_region` does nothing in this configuration.
6. **Band bias.** Uncensored Phase 2 mean error, 707 against stock: VA 76
   MHz +6.9 / −1.4; R1 230 MHz +4.1 / −1.7; R1 410 MHz +6.2 / +1.3; R3 230
   MHz +2.4 / −1.2. Long-term VHF doesn't show it (section 5).
7. **Censored rise at R2.** Pooled censored violations fell (28.0 % to
   22.8 %), but R2 rose from 6.8 % to 14.7 %; part of R2's RMS gain is
   predicting too little loss. VA's fall comes from the clutter term, which
   is off on the lockbox.
8. **Clear terrain above 3 GHz** is about 13.6 dB optimistic for every
   archived model: clutter 30 m terrain can't show.

## 8. Review before scoring (done 2026-11-24)

Three independent reviewer sessions and one Fable read on 2baa02b. None
found a blocker in the model code. Findings two or more reported, and where
they went:

| Finding | Reported by | Action |
| --- | --- | --- |
| Lockbox tests the 604 configuration; low-antenna evidence mixed in "C" rows | R1, R2, Fable | Section 1 and section 5, evidence recomputed on open rows |
| R02 would run as 707 plus 0.8 from `best`; `params_exp.m` header says defaults are stock | R1, R3, Fable | Section 2 |
| No primary endpoint or decision rule | R2, Fable | Section 4 (Nick confirms) |
| Troposcatter bound unsourced, flattens height gain | R1, R3 | Defect 3 |
| Lockbox scorer and `cfg.row` not pinned | R1, R3 | Section 3 |
| VHF prediction left out contradicting evidence | R2, R3 | Section 5 and defect 6 |
| Inputs outside development range and battery | R1, R3 | Section 5 |
| R2 censored rise hidden by pooling | R2, Fable | Defect 7 |
| Only 3 of 18 files pinned | R2, Fable | Section 1, tree hash |

Single-reviewer findings, recorded:

- The search drew hypotheses from `docs/WORKING_PAPER_FINDINGS.md`, a summary
  of a comparison on these lockbox sets (R1). So the lockbox reads as
  validation, not a blind test.
- 1801 was ruled out on a point estimate, about 2 rows over the repair
  limit, without an interval (R2). Nick to say whether that stands.
- 1804 ran at 99 % with 500 draws; FRAMEWORK.md asks for 2,000 above
  97.5 % (R2). The outcome isn't affected.
- `reviewer_criteria_rev1.md` and program.md state an older acceptance rule
  than FRAMEWORK.md (R2).
- The isolation weight measures clearance from the antenna line, not the
  obstacle line of P.526-16 section 2.5; the cascade follows a superseded
  edition (P.526-11); the write-up says "ITM with a modified cascade" (R1,
  R3, Fable).
- The P.2108-1 clutter term is the link closest to fitting the development
  set (Fable).

## 9. Before Nick scores

1. **Done.** Nick confirmed sections 4 and 5 as written on 2026-11-24
   (13:40 ET), and confirmed that the 1801 ruling stands (707 stays the
   frozen model; 1801 is a recorded near-miss). This file is now frozen.
2. Nick scores the panel once, as in sections 2 and 3, and records the
   result and the scorer MD5 in the LOG, whatever it shows.
