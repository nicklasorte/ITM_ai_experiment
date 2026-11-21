# Experiment log

Write each entry before the run, then complete it after. Newest at the
bottom.

## Template

```text
### NNN-short-name
- Date:
- Tier: 0 | 1 | 2 | 3 | 4
- Function(s) touched:
- Rationale (one sentence, physical):
- Predicted effect: which sites/bands improve, which don't change
- New free parameters: N (names, bounds, source)
- Result: score_cv X dB (Δ vs best), worst cell, per-site RMS, censored violations
- Physics battery: pass | fail (which check)
- Decision: keep | reject
- Prediction came true? yes | partly | no, and what that tells us
```

## Entries

### 000-baseline
- Date: 2026-11-21
- Tier: none
- Function(s) touched: none (variant at params_exp defaults; core copied from
  `nicklasorte/matlab_itm` private/itm_p2p_core.m at `9bd6a4e`)
- Rationale: reference point; proves the harness reproduces the baseline
- Result (`run_eval_rev1(Tag="000-baseline", Datasets="phase2", Parity=true)`,
  MATLAB R2025b on Nick's Mac, 5 s):
  - Phase 2 cell-balanced RMS 18.3 dB; row RMS 16.74 dB (matches the
    earlier matlab_itm comparison exactly); worst cell 39.6 dB
  - Site RMS (path-weighted): R1 13.3, R2 28.6, R3 9.0, VA 15.4 dB; site
    mean error R1 +2.6, R2 +10.6, R3 +0.2, VA −8.1 dB
  - References on the same links: P.452 and P.2001 cell 14.1 dB, row RMS
    12.7 and 12.6 dB
  - Censored-bound violations: ITM 28.0 %, P.452 65.6 %, P.2001 65.7 %. The
    references predict less loss than the measured lower bound on two thirds
    of the no-signal results, so part of their RMS edge is optimism on dead
    paths. A swap taken from them must not import that.
  - Variant vs stored baseline: 6.3 × 10⁻¹³ dB (parity passes)
- Physics battery: pass
- Rerun on the full data (2026-11-21, 840 profiles from CSV, 325 long-term
  paths, 548 distributions; `Parity=true`, difference 6.8 × 10⁻¹³ dB):
  - Composite 16.0 dB; Phase 2 cell 18.3; long-term level 24.6; long-term
    shape 5.2 dB. Physics battery passes.
  - P.452: composite 14.2 (Phase 2 14.1, level 18.5, shape 9.9). P.2001:
    14.0 (14.1, 21.2, 6.6). Censored violations unchanged (ITM 28.0 %).
  - Long-term level error rose from 17.6 dB on the 132 US paths to 24.6 dB
    on all 325. To diagnose in Stage 1 (by region, distance, and frequency)
    before any change targets it.
- Terrain: profiles for every path are stored as CSV; terrain tiles were
  sampled one path at a time and deleted after each profile (about 0.4 GB
  per path).
- Splits re-frozen with the full long-term set (hash `06d9f440607a`).
- Decision: baseline

### D01-longterm-level (diagnostic, no model change)
- Date: 2026-11-21
- Question: why is stock ITM's long-term level error 24.6 dB on all 325
  paths, against 17.6 dB on the 132 US paths?
- Method: `experiments/D01-longterm-level/diagnose_lt_level_rev1.py`
  replicates the `score_rev1` level metric exactly (24.60, 18.53, 21.21 dB
  for ITM, P.452, P.2001) and breaks it down. It also checks each path's
  30 m profile for a clear 4/3-earth ray between the antennas and compares
  that with the path type in the 1971 record (Longley, Reasoner, and Fuller,
  OT/TRER 16).
- Finding 1, geometry mismatch: 14 rows on 10 paths are line of sight in the
  record but blocked on the 30 m profile (by 1 to 158 m). ITM's p50 error on
  them averages +51 dB (RMS 74); P.2001 also misses (RMS 42). On the 63 rows
  where record and profile agree, ITM RMS is 9.3 dB. Likely cause: terminal
  coordinates in the record, often mountain sites (Cheyenne Mountain, Hakone,
  Seburiyama), landing off the site on the DEM. This is an input problem
  every terrain model shares, not ITM physics.
- Sensitivity: without those 14 rows (2.6 % of rows), ITM level is 16.9 dB,
  P.452 14.9, P.2001 17.5. The set is unchanged; this only sizes the effect.
- Finding 2, high frequency: the 3–10 GHz cells hold most of the remaining
  error. ITM mean error +25 to +34 dB and RMS 51–56 dB at under 300 km,
  against P.2001 RMS 24–37. Japan (65 rows, mostly 7.3 GHz) is the largest
  regional contributor (ITM RMS 39.6, P.2001 34.2). Supports H7 (frequency
  scaling above 6 GHz), but confounded with mountain-site geometry.
- Finding 3, ITM-specific diffraction misses: the largest errors where
  P.2001 is within 25 dB are Sutton Coldfield to Green Hailey (UK, 121.5 km,
  58–495 MHz, 3–5 m receiver, 85–103 m obstruction): ITM +69 to +88 dB,
  P.2001 +9 to +24 dB. Same signature at Feldberg (D) and Rokko (J). These
  are diffraction-dominated paths, the target of batch B01 (H1, H2).
- Decision for Nick: how to treat the 14 mismatched rows (keep, screen, or
  report both). Until then the frozen set stays as is, and no experiment may
  claim a gain that comes mainly from those rows.

### R01-recalibrated-itm
- Date: 2026-11-21 (full data; supersedes the interim run below)
- Tier: 1 (recalibration by a conventional optimizer; no agent)
- Method: as R01i, on all 325 long-term paths (`cv_calibrate_rev1`, bayesopt,
  40 evaluations per fold, 5 folds).
- New free parameters: 6
- Result (out-of-fold): composite 12.4 dB (stock ITM 16.0); Phase 2 cell
  14.5 (18.3); long-term level 17.6 (24.6); long-term shape 5.0 (5.2). Site
  RMS: R1 11.9 (13.3), R2 18.6 (28.6), R3 7.7 (9.0), VA 17.4 (15.4).
- Median fitted constants: w_const 2.83 (ITM 25.1), afo_scale 1.78,
  knife_scale 0.63, los_w_scale 46.9, time_minus_scale 0.98, time_plus_scale
  0.79. Direction matches the interim run: much smaller smooth-earth weight
  constant, a knife-edge term about 37 % smaller, and a narrower upper-side
  time spread. The lower-side spread no longer shrinks.
- Censored-bound violations: 55.9 % (stock ITM 28.0 %) — fails the gate.
- Physics battery at the median constants: FAIL — single-ridge distance
  sweep step 21.4 dB (stock ITM 8.0 dB).
- Decision: not a kept variant. Retuning alone cuts the composite by 3.7 dB,
  but censored violations double and VA gets worse (15.4 → 17.4), so part of
  the gain comes from predicting less loss than the measured bound on dead
  paths. R02 adds the censored and continuity gates to the objective.

### R01i-recalibrated-itm-interim
- Date: 2026-11-21
- Tier: 1 (recalibration by a conventional optimizer; no agent)
- Function(s) touched: none structurally; constants in `cfg.cal` (smooth-earth
  weight constant 25.1; scales on A_fo, the double knife edge, the
  line-of-sight blend, and both sides of the time spread)
- Rationale: the honest comparator for any agent result
  (docs/PUBLICATION_LITERATURE.md §2)
- Method: `eval/cv_calibrate_rev1`, bayesopt, 40 evaluations per fold, 5 folds
  (Phase 2 by site; long-term by receiver group); out-of-fold predictions
  scored with `score_rev1`. Interim data: long-term set is the 132 US paths.
- New free parameters: 6
- Result (out-of-fold): composite 12.1 dB (baseline 13.9); Phase 2 cell 14.5
  (18.3); long-term level 16.6 (17.6); long-term shape 5.2 (5.9). Site RMS:
  R1 11.7 (13.3), R2 19.1 (28.6; mean −7.5, was +10.6), R3 8.6 (9.0), VA
  16.1 (15.4).
- Fitted constants are consistent across folds: w_const 5.3–8.7 (ITM 25.1),
  afo_scale 1.88–1.98 (near the upper bound of 2), knife_scale 0.62–0.75,
  time scales 0.62–0.80 (narrower spread than ITM).
- Censored-bound violations: 55.6 % (baseline 28.0 %) — fails the gate.
- Physics battery at the median constants: FAIL — single-ridge distance sweep
  step 19.1 dB (baseline 8.0 dB).
- Decision: not a kept variant. Reported as the recalibration baseline.
- What it tells us: retuning alone closes most of the Phase 2 gap to P.452
  and P.2001, but by shrinking the knife-edge term and predicting
  optimistically on dead paths, as P.2001 does. The time spread wants to be
  about 25 % narrower. Next: a constrained recalibration (censored and
  continuity gates inside the objective), rerun on the full long-term set.
