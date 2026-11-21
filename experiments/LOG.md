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
- Long-term set: not yet scored. The full build was stopped because
  worldwide 30 m terrain for 325 paths would exceed the Mac's free disk
  (25 GB free; 14.9 GB downloaded in 20 minutes). Decision pending.
- Splits note: `data/splits/folds_rev1.csv` currently holds 3 long-term test
  paths from a trial build; it will be re-frozen with the full long-term set.
- Decision: baseline

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
