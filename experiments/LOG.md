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

### B02 summary (planner and worker)
- Date: 2026-11-21. Planner and worker: Claude Opus 5.5.
- Kept: none. Best stays `000-baseline`.
- Learned: the continuity fix works mechanically (both settings pass the
  battery), but extending the profile-based loss into ITM's line-of-sight
  region lowers loss on half of all Phase 2 rows by about 10 dB and doubles
  censored violations. The sampling-artifact fix (`"ep_isolated"`) is sound
  and stays available.
- For B03: get continuity at d_sML without changing line-of-sight-region
  paths. Options, none built yet: (a) on the transhorizon side, phase the
  profile-based loss in from ITM's value at d_sML to its full value at d_3,
  using only ITM's own anchor distances; (b) apply the profile-based loss
  only as a cap that can lower ITM's diffraction loss by no more than ITM's
  own knife-edge part; (c) treat the 30 % censored outcome of 101 as the
  real limit and move to the Virginia question, which needs inputs other
  than bare-earth profiles.

### B03 summary
- Date: 2026-11-21. Kept: none. Best stays `000-baseline`.
- After B01–B03 (eight structural runs): every change that lowers ITM's
  diffraction loss enough to fix the R2 bias (mean +10.6 dB) also predicts
  less loss than the measured bound on more no-signal results, mostly at
  Virginia and R2. The one setting that passes every physics check (phased
  Bullington) gains 0.13 dB. Diffraction edge choice alone doesn't clear
  the gates.

### B03 planned (planner note)
- Date: 2026-11-21. Planner: Claude Opus 5.5. Plan: `experiments/batches/B03.md`.
- New: `cfg.diffraction_region = "transhorizon_phased"`, linear phase-in
  between ITM's own d_sML and d_3 (no new constant). Parity at defaults
  unchanged (the default value is `"transhorizon"`).
- Battery code check: only Bullington passes with phasing; the
  Epstein-Peterson variants fail the rough-terrain sweep by 2.7–9.8 dB
  beyond the 1 dB margin, next to ITM's own region flips on that profile.

### 301-bullington-phased
- Date: 2026-11-21. Batch B03. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "bullington";` and `cfg.diffraction_region = "transhorizon_phased";`
- Rationale: 104's single equivalent edge, made continuous at ITM's line-of-sight boundary, with less change on paths just beyond it.
- Predicted (from B03.md, before the run): composite 15.75–16.0; screened 13.3–13.5; R2 RMS 26.5–28 (mean +9 to +10); R1, R3, VA within 0.5 dB of stock; censored 28.3–29.2 %; physics pass. Likely rejected on the 0.3 dB threshold or the paired check.
- Result: composite 15.90 dB (stock 16.02; R02 15.93; 104 15.72); screened 13.42; Phase 2 cell 17.69; long-term level 24.86; shape 5.16. Site RMS R1 13.4 (mean +2.5), R2 26.5 (mean +8.9), R3 8.9 (mean +0.2), VA 15.0 (mean -7.4). Censored 29.4 %. Paired gain over stock +0.13 dB (95 % -0.17 to +0.55), screened -0.02 (-0.28 to +0.43).
- Physics battery: PASS.
- Decision: reject (gain under 0.3 dB and not distinguishable from zero; censored 29.4 % > 29.0 %). Not archived: 104 dominates it in the same cell.
- Predictions: composite, screened, R2 RMS, other sites, and physics held; censored 29.4 % was just above the predicted 28.3–29.2 %. Rejection predicted.
- Planner analysis: phasing removed the line-of-sight-boundary jump without changing the censored rate (29.4 %, the same as 104), so the extra violations come from paths well beyond d_3, not from paths near the boundary. Phasing also gave up most of 104's gain (long-term level 24.9 against 24.4).

### 201-ep-isolated-blocked
- Date: 2026-11-21. Batch B02. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "ep_isolated";` and `cfg.diffraction_region = "blocked_paths";`
- Rationale: 101's mechanism, with the sampling artifact removed and the loss continuous at ITM's line-of-sight boundary.
- Predicted (from B02.md, before the run): the artifact removal adds loss back on ridge tops between samples, and the extension changes blocked line-of-sight-region paths (direction uncertain). Net: less gain than 101. Composite 15.4–15.9; R2 RMS 26–28 (mean +8 to +10); R1, R3, VA within 1.0 dB of stock; censored 28.5–31 %. Physics battery: pass. About even odds of clearing every gate; the censored gate and the 0.3 dB screened-gain threshold are the likely failures.
- Result: composite 13.75 dB (stock 16.02; R02 15.93); screened 11.89; Phase 2 cell 15.21; long-term level 20.88; shape 5.16. Site RMS R1 11.0 (mean -4.5), R2 21.6 (mean -9.1), R3 6.8 (mean -2.3), VA 16.5 (mean -11.1). Censored 56.0 %. paired gain over stock +2.28 dB (95 % +1.33 to +3.00), screened +1.51 (+0.98 to +2.12).
- Physics battery: PASS.
- Decision: reject (censored 56.0 % > 29.0 %; VA 1.1 dB worse). On the Pareto front and its cell's elite: kept as `arc/201-ep-isolated-blocked`.
- Predictions: wrong. Predicted composite 15.4–15.9 and censored 28.5–31 %; got 13.7 and 56.0 %. R2 mean error flipped from +10.6 to −9.1.
- Planner analysis: against 101, 9,294 of 16,805 Phase 2 rows changed, by a median −10 dB (R2 2,652 rows, R1 1,274 lowered by more than 10 dB). The cause is `"blocked_paths"`: ITM puts many blocked low-antenna paths in its line-of-sight region, and re-anchoring their line through the variant value feeds them ITM's smooth-earth term extrapolated to distances below d_3, where it has no meaning. The extension buys continuity at the cost of the R01 pattern: optimism on dead paths.

### 202-p526-double-edge-blocked
- Date: 2026-11-21. Batch B02. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "p526_double_edge";` and `cfg.diffraction_region = "blocked_paths";`
- Rationale: the Recommendation's own two-edge method adds the separation correction Lc for strongly shadowed isolated edge pairs.
- Predicted (from B02.md, before the run): same as 201 on most paths; slightly more loss on isolated pairs that both exceed 15 dB. Composite 0.0–0.3 dB above 201; censored 0–1 point below 201. Physics battery: pass.
- Result: composite 13.75 dB; screened 11.90; same site scores and censored rate as 201 (56.0 %). paired gain over stock +2.27 dB (95 % +1.32 to +2.99), screened +1.50 (+0.96 to +2.12).
- Physics battery: PASS.
- Decision: reject (censored; VA). On the front and its cell's elite: kept as `arc/202-p526-double-edge-blocked`.
- Predictions: composite 0.0–0.3 above 201 held (+0.04); the Lc correction rarely applies (few isolated pairs above 15 dB each). Censored predicted 0–1 point below 201; equal.

### B02 planned (planner note)
- Date: 2026-11-21. Planner: Claude Opus 5.5.
- Plan: `experiments/batches/B02.md`, experiments 201–202.
- Diagnosis of 101: the continuity step sits at ITM's d_sML (mode 1 to 2);
  37 of 42 new censored violations are at Virginia (median margin 1.3 dB);
  Epstein-Peterson drops about 10 dB when a ridge top falls between two
  samples, so part of 101's mountain gain may be a sampling artifact.
- New code: `"ep_isolated"` (P.526-16 section 2.5 isolation criterion),
  `"p526_double_edge"` (P.526-16 section 4.3), and
  `cfg.diffraction_region = "blocked_paths"` (continuity at d_sML). Tests
  12 of 12 pass; parity 6.8 × 10⁻¹³ dB; both scheduled settings pass the
  physics battery (planner code check, no measurements read).
- The first version of the new test expected Epstein-Peterson to add loss
  on a split ridge top; it fails because the loss drops instead. Test and
  documentation corrected before any run.

### B01 worker summary
- Date: 2026-11-21. Worker run by Claude Opus 5.5 (the plan names Haiku;
  Nick had Opus selected). Experiments 101–105 run as planned; 106 not run.
- Kept: none. Best stays `000-baseline`.
- Stopped and handed back to the planner: 106's parent rule needs one of
  101–103 to pass physics, and none did (B01.md stop condition).
- Archive: `arc/104-bullington` (front, cell elite) and
  `arc/105-profile-horizon-region` (front) kept as branches.
- Harness note: `paired_gain_rev1` prints "not distinguishable from zero"
  also when the whole interval is below zero (102, 103, 105). The decision
  isn't affected, since the rule needs the interval above zero, but the
  wording should say "worse" in that case. Not changed by the worker.

### 101-ep-two-horizon
- Date: 2026-11-21. Batch B01. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "epstein_peterson";`
- Rationale: the same two horizon obstacles ITM uses, but with each edge's own geometry at the path distance instead of a line extrapolated from 20 km or more beyond the horizons.
- Predicted (from B01.md, before the run): R2 mean error falls from +10.6 to between +3 and +8 dB, R2 RMS to 24–27. R1, R3, and VA RMS move by less than 0.5 dB. Phase 2 cell 16.5–17.8. Long-term level 21–24, with the D01 Sutton Coldfield rows (LT2116) at least 20 dB lower. Shape within ±0.1. Composite 14.5–15.6. Censored violations rise to 30–40 %; this is the most likely reason for rejection. Continuity: possible step where a sweep crosses from the line-of-sight region to transhorizon.
- Result: composite 15.27 dB (stock 16.02; R02 15.93); screened 12.99 (13.40); Phase 2 cell 17.70; long-term level 23.02; shape 5.16. Site RMS R1 13.2 (mean +2.3), R2 26.0 (mean +8.9), R3 8.9 (mean +0.1), VA 15.5 (mean -8.4). Censored 30.0 %. paired gain over stock +0.76 dB (95 % +0.29 to +1.13), screened +0.41 (+0.18 to +0.66).
- Physics battery: FAIL. Distance-sweep continuity: ridge step 20.7 dB (stock 8.0), rough 35.7 dB (stock 33.0).
- Decision: reject (physics; censored 30.0 % > 29.0 %). Not in the archive (physics fail).
- Predictions: composite, Phase 2 cell, R2 RMS, long-term level, shape, the other sites, and censored all landed in their predicted ranges; R2 mean +8.9 was just above the +3 to +8 range. The predicted continuity risk happened.
- Note for the planner: the largest gain in the batch, held back only by the step where a sweep enters the transhorizon region. The switch applies only to transhorizon paths, so the loss jumps at the region boundary.

### 102-deygout-three-edge
- Date: 2026-11-21. Batch B01. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "deygout";`
- Rationale: the principal obstruction and one edge on each side capture multi-ridge mountain paths that two horizon edges miss or double count.
- Predicted (from B01.md, before the run): loss at or above 101 on multi-ridge paths, so R2 mean error between +4 and +9 dB and R2 RMS 24–27; other sites within 0.5 dB. Long-term level 21–24. Censored 29–38 %. Composite 14.6–15.7.
- Result: composite 16.76 dB; screened 14.37; Phase 2 cell 17.86; long-term level 27.24; shape 5.16. Site RMS R1 13.5 (mean +3.2), R2 27.5 (mean +10.0), R3 8.9 (mean +0.2), VA 14.8 (mean -7.0). Censored 24.5 %. paired gain over stock -0.74 dB (95 % -1.32 to +0.15), screened -0.97 (-1.41 to -0.16).
- Physics battery: FAIL (continuity, rough distance sweep).
- Decision: reject (score worse; physics).
- Predictions: wrong on long-term level (predicted 21–24, got 27.2) and censored (predicted 29–38 %, got 24.5 %); composite outside range. Deygout adds loss on long paths, where more than three edges contribute.

### 103-p526-cascaded
- Date: 2026-11-21. Batch B01. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "p526_cascaded";`
- Rationale: Deygout's three edges with the ITU-R empirical correction, which adds up to 10 + 0.04·D dB when the principal edge is strong.
- Predicted (from B01.md, before the run): the highest loss of 101–103, so the smallest gain and the smallest censored increase: R2 mean error +7 to +11 dB, R2 RMS 26–29, censored 28–33 %, composite 15.2–16.1. The one most likely to pass the censored gate and the least likely to clear 0.3 dB.
- Result: composite 19.04 dB; screened 16.49; Phase 2 cell 18.76; long-term level 33.22; shape 5.16. Site RMS R1 14.6 (mean +4.5), R2 30.2 (mean +12.0), R3 9.2 (mean +0.4), VA 14.5 (mean -5.3). Censored 21.2 %. paired gain over stock -3.01 dB (95 % -3.71 to -1.64), screened -3.09 (-3.82 to -1.68).
- Physics battery: FAIL (continuity, rough distance sweep).
- Decision: reject (score much worse; physics).
- Predictions: direction right (highest loss, lowest censored) but the size far larger; composite predicted 15.2–16.1, got 19.0. The correction term (10 + 0.04 D dB) dominates on long paths.

### 104-bullington
- Date: 2026-11-21. Batch B01. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "bullington";`
- Rationale: a single equivalent edge is the low-loss end of the knife-edge family and the core of the P.452 and P.2001 diffraction models, so it shows how much of their Phase 2 advantage this substitution explains.
- Predicted (from B01.md, before the run): R2 mean error between −2 and +5 dB; Phase 2 cell 15–17; censored above 40 %, failing the gate. If censored stays under 33 %, tell the planner: the references' optimism then comes from elsewhere.
- Result: composite 15.72 dB; screened 13.46; Phase 2 cell 17.61; long-term level 24.42; shape 5.16. Site RMS R1 13.4 (mean +2.6), R2 26.2 (mean +8.7), R3 8.9 (mean +0.2), VA 14.9 (mean -7.3). Censored 29.4 %. paired gain over stock +0.31 dB (95 % -0.16 to +0.82), screened -0.06 (-0.35 to +0.40).
- Physics battery: PASS.
- Decision: reject (censored 29.4 % > 29.0 %; neither paired interval above zero; screened composite not improved). On the Pareto front and the elite of its cell, so kept as branch `arc/104-bullington`.
- Predictions: wrong. R2 mean error predicted −2 to +5, got +8.7; censored predicted above 40 %, got 29.4 %.
- Flag for the planner (B01.md asked for it): censored stayed under 33 %, so the references' optimism on dead paths doesn't come from single-edge diffraction; it comes from elsewhere in P.452 and P.2001.

### 105-profile-horizon-region
- Date: 2026-11-21. Batch B01. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.line_of_sight = "profile_horizons";` (diffraction stays `"itm"`)
- Rationale: a path whose terrain blocks the direct ray isn't a two-ray path, whatever the smooth-earth horizons of the effective heights say.
- Predicted (from B01.md, before the run): affects only blocked paths that ITM places in its line-of-sight region. Composite within ±0.4 of stock; R2 and R3 move by less than 1.5 dB RMS in either direction; long-term nearly unchanged. Real chance of a continuity failure, because a path changes formula the moment terrain touches the ray. Not expected to be kept alone; it is here to price the region change before combining it.
- Result: composite 16.57 dB; screened 13.95; Phase 2 cell 19.61; long-term level 24.89; shape 5.16. Site RMS R1 15.3 (mean +5.7), R2 30.3 (mean +15.6), R3 10.7 (mean +1.6), VA 15.7 (mean -6.8). Censored 26.6 %. paired gain over stock -0.54 dB (95 % -0.71 to -0.38), screened -0.55 (-0.73 to -0.38).
- Physics battery: PASS.
- Decision: reject (score worse; R1 and R3 worse by more than 0.5 dB). On the Pareto front (lowest censored rate), so kept as branch `arc/105-profile-horizon-region`.
- Predictions: wrong in size. Predicted composite within ±0.4 and R2, R3 within 1.5 dB; got −0.5 composite, R2 +1.7, R3 +1.7, R1 +2.0. Moving blocked paths to ITM's transhorizon formulas adds loss everywhere; the predicted continuity failure didn't happen.

### B01 planned (planner note)
- Date: 2026-11-21. Planner: Claude Fable 5.2.
- Plan: `experiments/batches/B01.md`, experiments 101–106 (H1, H2, H3).
- New code: `itm_variant/multi_edge_diffraction_rev1.m` (Epstein-Peterson
  over the two horizon obstacles, Deygout three-edge, ITU-R P.526-11
  cascaded, ITU-R P.526-16 Bullington) and switch handling in
  `itm_p2p_core_exp.m`. Tests: 9 of 9 pass
  (`itm_variant/tests/test_diffraction_rev1.m`), including the J(ν)
  approximation against the exact Fresnel integral and Bullington rewritten
  in the Recommendation's own units. Parity at default switches:
  6.8 × 10⁻¹³ dB.
- Finding: H2 as first written (evaluate ITM's own diffraction formulas at
  the path distance) is degenerate; ITM's double knife edge is zero-valued
  at d = d_L1 + d_L2. H1 and H2 are tested together through profile-based
  knife-edge loss at the path distance.
- Equation numbers were checked against text extractions of ITU-R P.526-16
  and P.526-11. The extraction garbled some symbols in eq. (31), (49), and
  (55); the coded forms match the standard expressions and the independent
  checks in the tests, but a read against the PDFs is still owed.
- Not built: delta-Bullington (needs the spherical-earth model, P.526-16
  section 3.2). Deferred to B02 if censored violations block B01.

### R02-constrained-recalibration
- Date: 2026-11-21
- Tier: 1 (recalibration by a conventional optimizer; no agent)
- Method: `cv_calibrate_rev1(Tag="R02-constrained-recalibration",
  MaxEvals=120, Constrained=true)`. Same six constants and folds as R01, with
  two coupled constraints on every trial, evaluated without held-out data:
  training censored violations within 1 point of stock ITM, and every
  physics-battery check within its margin. Start points: ITM's constants
  plus each constant moved alone (×0.5/×2 for log-scaled, ×0.8/×1.2
  otherwise). 109–112 of 120 trials per fold were feasible. Runtime 995 s.
- Result (out-of-fold): composite 15.93 dB (stock ITM 16.02); Phase 2 cell
  18.32 (unchanged); long-term level 24.39 (24.60); long-term shape 5.09
  (5.16). Screened composite 13.34 (stock 13.40). Censored violations 28.0 %
  (unchanged). Physics battery at the fitted constants: pass.
- Fitted constants, identical on all five folds: every structural constant
  stays at ITM's value (w_const 25.1, afo_scale, knife_scale, and
  los_w_scale 1); only the lower-side time spread narrows
  (time_minus_scale 0.8).
- Selection check: a separate run tuning only the two time-spread constants
  (15 trials per fold, all feasible) reached composite 15.92 dB with
  time_minus_scale 0.74–0.84 and time_plus_scale 0.82–0.90, so the
  feasible-best selection works and R02 found the same optimum.
- Free parameters: the archive counts six because six were searched; one
  moved.
- Decision: the recalibration baseline every agent result is compared to.
- What it tells us: under the censored and continuity gates, retuning ITM's
  constants buys 0.1 dB. Every structural constant change that passes the
  gates makes the score worse. The 3.7 dB from the unconstrained retune (R01)
  came from changes that break physics and predict optimistically on dead
  paths. Gains have to come from structure, not constants.

### D02-noise-floor (diagnostic, no model change)
- Date: 2026-11-21
- Question: how large must a score change be to be real?
- Method: `experiments/D02-noise-floor/noise_floor_rev1.py` replicates
  `score_rev1` exactly (composite matches to 4e-15 dB), then draws 500
  bootstrap samples of paths, with replacement, within each Phase 2 site and
  each long-term fold.
- Path-sampling spread of a single model's composite: SD 1.1 dB (stock ITM),
  1.2–1.4 dB (P.2001, P.452), 0.6 dB (R01).
- Paired differences, same resampled paths for both models: R01 − ITM
  −3.3 ± 0.6 dB; P.2001 − ITM −2.2 ± 1.0 dB; P.452 − P.2001 +0.2 ± 0.3 dB,
  95 % interval −0.3 to +0.7, so the two ITU models aren't distinguishable.
- Implication: for two similar models the paired SD is about 0.3 dB, so the
  fixed 0.3 dB keep threshold is about one SD — too loose on its own.
  Proposed: keep a change only if the 95 % paired-bootstrap interval of its
  gain over the current best excludes zero, as well as meeting 0.3 dB. To be
  built into `eval/` before batch B01.
- Screened composite (14 rows left out, D01): ITM 13.4, P.452 12.9, P.2001
  12.7, R01 10.9 dB.

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
