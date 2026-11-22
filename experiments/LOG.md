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

### 601-delta-cascaded-isolated-afo-bounded
- Date: 2026-11-21. Batch B06. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_cascaded_isolated_afo";` and `cfg.diffraction_bound = "itm_troposcatter_line";`
- Rationale: an isolated second or third ridge costs its own diffraction loss; one equivalent edge can't carry it, and R2's no-signal rows are multi-ridge paths.
- Predicted (from B06.md, before the run): R2 no-signal rows violated 0–1 / 2 / 3 / 4+ edges: 60–75 / 15–25 / 20–40 / 10–35 %. R2 measured mean error −3 to +3 dB overall; on 3 and 4+ edge rows it moves up by 3–10 dB from 502. Censored 36–44 %. Phase 2 cell 12.5–14.5. Long-term level 14–17. Composite 11.0–12.5; screened 9.5–11.0. Battery: pass.
- Result: composite 13.35 dB (stock 16.02); screened 11.85 (13.4); Phase 2 cell 14.2 (18.3); long-term level 20.7 (24.6); shape 5.1 (5.2). Site RMS R1 12.4 (mean +6.2), R2 19.5 (mean +3.8), R3 9.1 (mean +5.9), VA 11.8 (mean -0.6). Censored 25.8 % (stock 28.0 %). Max change from stock 65.1 dB. Paired gain +2.67 (95 % +1.49 to +3.50); screened +1.54 (+0.83 to +2.20).
- Physics battery: PASS.
- By edge count:
  - edges 0-1: dead rows violated 68.3 % of 41; measured-row mean error -9.1 dB
  - edges 2: 22.5 % of 204; +0.4 dB
  - edges 3: 7.2 % of 376; +17.0 dB
  - edges 4+: 5.2 % of 563; +12.9 dB
- Acceptance rule (FRAMEWORK.md): battery PASS; composite gain +2.7 and screened gain +1.5 (each at least 0.3); both paired intervals above zero; no site RMS worse by more than 0.5 dB (R3 9.1 vs 9.0, others better); censored 25.8 % (at most 29.0 %); no new free parameters. Every gate passes.
- Decision (after the reviewer pass, 3 of 3): reject; not merged. Originally held: B06.md required the three-reviewer pass on A_fo (possible double counting with the obstruction loss) before any `_afo` run is kept. On the Pareto front; beats stock ITM on all four archive objectives (cell 14.2 vs 18.3, level 20.7 vs 24.6, shape 5.1 vs 5.2, censored 25.8 vs 28.0 %). Branch `exp/601-delta-cascaded-isolated-afo-bounded` holds the two switch lines. 603, 604, 602, and 605 were not run (the plan says to hand back).
- Predictions: held: battery pass; composite gain over stock with the interval above zero; 0-1 edge dead rows 68 % (predicted 60-75); 2 edges 22.5 % (15-25). Missed: composite 13.4 (predicted 11.0-12.5); censored 25.8 % (predicted 36-44, passes the gate); R2 mean +3.8 (predicted -3 to +3, slightly above); 3 edges 7.2 % (predicted 20-40) and 4+ edges 5.2 % (10-35), both lower than predicted; Phase 2 cell 14.2 (12.5-14.5 held); long-term level 20.7 (predicted 14-17).
- Worker note: R1 and R3 means are +6.2 and +5.9 dB (the variant predicts more loss than measured on average at those sites), and 3 and 4+ edge measured rows are +17 and +13 dB high. The variant is now pessimistic where 502 was optimistic; the planner should check whether that trade is physical.

### 603-delta-bullington-afo-bounded
- Date: 2026-11-21. Batch B06. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_bullington_afo";` and `cfg.diffraction_bound = "itm_troposcatter_line";`
- Rationale: 502 with the bound and no new edge term; separates the bound from the edges.
- Predicted (from B06.md, before the run): Phase 2 within 0.2 dB of 502 (cell 12.7–13.1; R2 mean −6.5 to −5.5). Long-term level 13.5–15.5. Censored 47–49 %. Composite 10.6–11.3; screened 9.2–9.8. By-edge table as 502 within 3 points. Battery: pass.
- Result: composite 11.17 dB (stock 16.02); screened 9.67; Phase 2 cell 12.7; long-term level 15.6; shape 5.1. Site RMS R1 10.2 (mean +2.5), R2 16.8 (mean -6.0), R3 7.9 (mean +4.6), VA 12.1 (mean -4.2). Censored 49.6 %. Paired gain +4.86 (95 % +3.34 to +5.72); screened +3.73 (+2.59 to +4.48).
- Physics battery: PASS.
- By edge count:
  - edges 0-1: dead rows violated  68.3 % of   41; measured-row mean error   -9.7 dB
  - edges   2: dead rows violated  23.5 % of  204; measured-row mean error   -7.6 dB
  - edges   3: dead rows violated  44.9 % of  376; measured-row mean error   +2.4 dB
  - edges  4+: dead rows violated  49.9 % of  563; measured-row mean error   -4.4 dB
- Decision: reject (censored 49.6%); on the Pareto front, same cell as 502 (502 stays elite).
- Predictions: Held: Phase 2 within 0.2 dB of 502 (cell 12.7); R2 mean -6.0; composite 11.2 (10.6-11.3); screened 9.7 (9.2-9.8); by-edge table identical to 502; battery pass. Missed: long-term level 15.6 (predicted 13.5-15.5, just above); censored 49.6 % (predicted 47-49). The bound rarely binds below 502's level, so it changes almost nothing here.
- Run after the hand-back, with Nick's approval (2026-11-21), as one batch job (`experiments/batches/b06_run_rest_rev1.m`); Mac defaults restored afterward (MD5 e9b334fa5d68c11e0159ace40f027ae4).

### 604-delta-cascaded-isolated-bounded
- Date: 2026-11-21. Batch B06. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_cascaded_isolated";` and `cfg.diffraction_bound = "itm_troposcatter_line";` (control, no A_fo)
- Rationale: the new edge term without A_fo; with 601 it prices A_fo on the new base.
- Predicted (from B06.md, before the run): censored 50–60 %; R2 measured mean −9 to −4 dB; 0–1 edge no-signal rows 95–100 % violated; 3 and 4+ edge rows 30–55 %. Composite 11.5–13.0; screened 10.0–11.5. Battery: pass.
- Result: composite 12.78 dB (stock 16.02); screened 11.43; Phase 2 cell 14.1; long-term level 19.1; shape 5.2. Site RMS R1 11.0 (mean +2.2), R2 19.4 (mean -1.4), R3 6.8 (mean +0.4), VA 13.7 (mean -5.2). Censored 31.5 %. Paired gain +3.25 (95 % +1.98 to +4.20); screened +1.97 (+1.28 to +2.62).
- Physics battery: PASS.
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of   41; measured-row mean error  -14.9 dB
  - edges   2: dead rows violated  29.9 % of  204; measured-row mean error   -4.9 dB
  - edges   3: dead rows violated  14.9 % of  376; measured-row mean error  +11.5 dB
  - edges  4+: dead rows violated  11.7 % of  563; measured-row mean error   +7.5 dB
- Decision: reject (censored 31.5% > 29.0%); cell elite and on the Pareto front: arc/604-delta-cascaded-isolated-bounded.
- Predictions: Held: R2 mean -1.4 is outside (predicted -9 to -4); 0-1 edge rows 100 % (95-100, held); battery pass. Missed: censored 31.5 % (predicted 50-60, much lower); 3 and 4+ edge rows 14.9 and 11.7 % (predicted 30-55, lower); composite 12.8 (11.5-13.0, held); screened 11.4 (10.0-11.5, held).
- Run after the hand-back, with Nick's approval (2026-11-21), as one batch job (`experiments/batches/b06_run_rest_rev1.m`); Mac defaults restored afterward (MD5 e9b334fa5d68c11e0159ace40f027ae4).

### 602-delta-cascaded-isolated-afo
- Date: 2026-11-21. Batch B06. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_cascaded_isolated_afo";` (`cfg.diffraction_bound = "none";`) (control, no bound)
- Rationale: prices the bound on the new edge term.
- Predicted (from B06.md, before the run): Phase 2 and the by-edge table within 1 point of 601. Long-term level 20–28. Composite 13–16. Battery: pass.
- Result: composite 18.61 dB (stock 16.02); screened 17.39; Phase 2 cell 15.0; long-term level 35.7; shape 5.1. Site RMS R1 15.3 (mean +7.9), R2 19.5 (mean +3.9), R3 9.1 (mean +5.9), VA 12.3 (mean +0.8). Censored 20.1 %. Paired gain -2.58 (95 % -4.50 to -1.39); screened -3.99 (-5.35 to -2.96).
- Physics battery: PASS.
- By edge count:
  - edges 0-1: dead rows violated  68.3 % of   41; measured-row mean error   -9.1 dB
  - edges   2: dead rows violated  22.5 % of  204; measured-row mean error   +0.5 dB
  - edges   3: dead rows violated   7.2 % of  376; measured-row mean error  +17.0 dB
  - edges  4+: dead rows violated   5.2 % of  563; measured-row mean error  +12.9 dB
- Decision: reject (composite worse than stock; LT level 35.7); on the Pareto front (lowest censored, 20.1%), same cell as 601.
- Predictions: Held: Phase 2 and by-edge table within 1 point of 601 (identical by-edge rows); battery pass. Missed: long-term level 35.7 (predicted 20-28); composite 18.6 (predicted 13-16). The bound is necessary.
- Run after the hand-back, with Nick's approval (2026-11-21), as one batch job (`experiments/batches/b06_run_rest_rev1.m`); Mac defaults restored afterward (MD5 e9b334fa5d68c11e0159ace40f027ae4).

### 605-delta-p526-cascaded-bounded
- Date: 2026-11-21. Batch B06. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_p526_cascaded";` and `cfg.diffraction_bound = "itm_troposcatter_line";` (mechanism test)
- Rationale: 503 was the only run under the censored gate (26.8 %) and lost on long-term level (30.6); with the bound, it shows how much of that result was the long paths.
- Predicted (from B06.md, before the run): censored 27–31 %; R2 measured mean +2 to +3.5 dB; long-term level 18–24; composite 13–15; screened 11.5–13.5. By-edge table as 503 within 3 points. Battery: fail as listed (can't be kept).
- Result: composite 13.44 dB (stock 16.02); screened 11.73; Phase 2 cell 15.0; long-term level 20.2; shape 5.2. Site RMS R1 11.6 (mean +5.0), R2 21.3 (mean +2.7), R3 8.0 (mean +2.0), VA 13.8 (mean -6.2). Censored 28.9 %. Paired gain +2.59 (95 % +1.58 to +3.36); screened +1.67 (+1.05 to +2.24).
- Physics battery: FAIL.
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of   41; measured-row mean error  -13.4 dB
  - edges   2: dead rows violated  23.5 % of  204; measured-row mean error   -0.3 dB
  - edges   3: dead rows violated  14.4 % of  376; measured-row mean error  +14.6 dB
  - edges  4+: dead rows violated   0.0 % of  563; measured-row mean error  +19.5 dB
- Decision: reject (physics fail, as listed).
- Predictions: Held: censored 28.9 % (27-31); R2 mean +2.7 (+2 to +3.5); long-term level 20.2 (18-24); composite 13.4 (13-15); screened 11.7 (11.5-13.5); by-edge table identical to 503; battery fail as listed.
- Run after the hand-back, with Nick's approval (2026-11-21), as one batch job (`experiments/batches/b06_run_rest_rev1.m`); Mac defaults restored afterward (MD5 e9b334fa5d68c11e0159ace40f027ae4).

### 707-cascaded-isolated-clutter-at-r
- Date: 2026-11-21. Batch B08. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_cascaded_isolated";`, `cfg.diffraction_bound = "itm_troposcatter_line";`, `cfg.terminal_clutter = "p2108_height_gain";`, `cfg.terminal_clutter_base = "clutter_height";`, `cfg.terminal_clutter_frange = "hold3";`
- Source: ITU-R P.2108-1 section 3.1 and Table 1 (A_h added to loss computed with the terminal at R; eq. (2a)-(2g)); B06 sources for the rest. No free parameters.
- Rationale: 701 as the Recommendation says, without the double count found by the B07 reviewers.
- Result: composite 12.51 dB (stock 16.02); screened 11.2; Phase 2 cell 13.2; long-term level 19.1; shape 5.2. Site RMS R1 10.5 (mean +4.1), R2 18.2 (mean -0.2), R3 6.8 (mean +0.4), VA 12.9 (mean -2.9). Worst cell 29.0. Censored 22.8 %. Paired gain +3.52 (95 % +2.30 to +4.41); screened +2.24 (+1.59 to +2.85).
- Physics battery: PASS.
- Censored by site (stock in brackets): R1 5.7 % [13.6], R2 14.7 % [6.8], VA 47.5 % [78.3]. Concealed violated: R1 2/6, R2 14/106, VA 143/386 (701: 2, 12, 116).
- Concealed mean error (701 in brackets): R1 clear -2.0 [+1.7], obstructed +8.1 [+11.6]; R2 clear -26.8 [-19.9], obstructed -15.9 [-11.5]; VA clear -4.7 [-2.6], obstructed +3.8 [+6.2]. VA concealed obstructed RMS 13.1 [14.4]. Open and `A` rows identical to 604.
- By edge count, R2 dead rows violated: 100.0 / 29.9 / 4.3 / 9.9 %.
- Gates: passes every gate. **Held**; back to the three B07 reviewers for their required-before-keep items (2 of 3 to keep).
- Predictions: Held: concealed means R1 obstructed +8.1 (+7 to +10), VA obstructed +3.8 (+2 to +5), VA clear -4.7 (-4 to -7), R2 obstructed -15.9 (-14 to -17); open rows equal to 604; censored 22.8 (22-26), VA 47.5 (45-52); Phase 2 cell 13.2 (13.0-13.4); LT 19.1; composite 12.5 (12.3-12.6); screened 11.2 (10.9-11.3); battery pass. Missed narrowly: R2 censored 14.7 (15-16); R1 censored 5.7 (6-8).
- Reading: removing the double count lowers concealed loss by 3.5 dB on average and costs 1.4 points of censored (21.4 to 22.8 %): 27 of the 29 added violations at VA, 2 on R2 concealed rows; composite and Phase 2 cell are unchanged to 0.06 dB. 701's extra pessimism bought censored passes but no accuracy.

### 709-cascaded-isolated-clutter-at-r-extend
- Date: 2026-11-21. Batch B08. Parent: 000-baseline. Tier 2.
- Change: as 707 but `cfg.terminal_clutter_frange = "extend";`
- Result: composite 12.50; screened 11.1; Phase 2 cell 13.2; long-term level 19.1. Site RMS R1 10.5, R2 18.1, R3 6.8, VA 12.9. Worst cell 28.4. Censored 22.3 % (R1 5.7, R2 14.7, VA 45.8). Paired gain +3.53 (+2.30 to +4.42); screened +2.25 (+1.60 to +2.87). Battery PASS.
- Concealed mean error: R1 obstructed +9.1; VA obstructed +4.0; VA clear -4.1; R2 obstructed -15.4.
- Gates: passes every gate. Held with 707 as the with-extension report.
- Predictions: Held: composite within 0.15 dB of 707 (0.01); censored 22.3 (21-25), at or below 707; battery pass.
- Reading: the rule above 3 GHz changes the composite by 0.01 dB and censored by 0.5 points; the data don't distinguish "extend" from "hold3", so the B08 default is "hold3" (no extrapolation beyond the validated range).

### 708-deygout-isolated-clutter-at-r
- Date: 2026-11-21. Batch B08. Parent: 000-baseline. Tier 2.
- Change: as 707 but `cfg.diffraction = "delta_deygout_isolated";`
- Result: composite 11.87; screened 10.7; Phase 2 cell 13.8; long-term level 16.6. Site RMS R1 10.1 (mean -1.4), R2 19.1 (mean -9.9), R3 6.6 (mean -2.4), VA 13.7 (mean -4.5). Worst cell 32.0. Censored 32.5 % (R1 11.8, R2 28.0, VA 51.8). Paired gain +4.15 (+2.63 to +5.23); screened +2.67 (+1.68 to +3.44). Battery PASS.
- Concealed mean error: R1 obstructed +0.3; R2 obstructed -23.3; VA obstructed +1.6. R2 open obstructed -9.9 (as 702).
- Decision: reject (censored 32.5 %). Not on the Pareto front (702 dominates it), so not archived.
- Predictions: Held: composite 11.9 (11.6-12.0); censored 32.5 (31-35); R2 open obstructed -9.9.

### Diagnostic: antenna height inversion in the kept model (B08 reviewers 1 and 3)
- Date: 2026-11-21. Model only (no measurements read). Settings: 707's diffraction and bound, clutter off.
- Scan of the 936 R1-R3 concealed rows with the mobile antenna below 15 m: raising it to 15 m adds loss on 20 rows in the 604 base (max 4.5 dB): 14 on P2_R1_R1-020-T8_C (3.0 dB at 230 MHz, 4.0-4.5 dB from 410 MHz to 9.2 GHz) and 6 on P2_R1_R1-010-T6_C at 9.2 GHz (0.5-2.2 dB). Stock ITM adds loss on 210 of the same rows, by at most 1.8 dB. ITM classes all 20 as line of sight at both heights.
- Cause, traced on R1-020-T8 at 910 MHz: the obstruction loss falls with height as it should (L_ba 37.27 to 36.33 dB; L_bs 0 at both). The rise is in ITM's smooth-path reference A_s: P.452-18 eq. (166c)-(166f) lower the smooth surface by h_obs split between the ends by a_t and a_r; raising the transmitter from 6.6 to 15 m changes h_obs (18.2 to 16.5 m) and the split, so the smooth surface under the receiver rises 1.4 m (h_sr 1576.9 to 1578.3 m) and the receiver's height above it falls from 13.1 to 11.7 m, which raises A_s. This is P.452 as written combined with ITM's line-of-sight loss on the smooth path, not a coding defect.
- Why the battery misses it: the synthetic height-gain check sweeps the receiver on a symmetric ridge, where the smooth-surface split doesn't move against the swept terminal. A real-path height-gain check would catch it; that is an eval/ change for Nick.
- No change made. Candidate for a later batch: hold the smooth surface fixed from terrain alone (P.452 eq. (163)-(164) without the antenna-dependent eq. (166)) only if a published method supports it (TODO: check P.452-18 and P.1812 text before proposing).

### B09 planner note: open clear paths (D04) and P.526-16 section 4.4 (abandoned at the battery)
- Date: 2026-11-21. Planner and worker: Claude Opus 5.5. Targets from the research plan (docs/research/FUTURE_RESEARCH_PLAN_rev1.md): H04 + H21, then H05. No scored run.
- D04 (`experiments/D04-open-clear-paths/`, diagnostic on 707): H04 not supported (VA sign reversed; knife-edge size 2-3 dB against 10-28 dB errors). R2's open clear bias is two paths (95 % of its squared error). VA's is broad and rises with frequency, consistent with unmodelled clutter (H21), not testable without a land-cover input (Nick's call; a site identifier isn't allowed, H16).
- H05 candidate: ITU-R P.526-16 (11/2025) section 4.4, multiple isolated cylinders, read from the ITU PDF pages (eq. (44)-(48), Attachment 1 eq. (107)-(116), Attachment 2 eq. (124)-(129)); implemented with zero-radius cylinders as `"p526_cylinders_knife"` / `"delta_p526_cylinders_knife"`. Checks: single spike = J(nu); two spikes = J1 + J2 + eq. (39) L_c (C_N reduces to L_c exactly); line of sight = J(-C_F sqrt 2); single-hill grazing transition continuous (step < 0.6 dB); reciprocal to 1e-6 dB. Tests 36 of 36.
- Battery with 707's other settings: FAIL. Rough-terrain distance sweep step 64.9 dB (stock 33.0), with 59 steps over 15 dB between 2 and 150 km; all other checks pass (frequency step 0.46 vs 0.98 dB, receiver height 0.46 vs 1.57, ridge distance 6.6 vs 8.0, height-gain net -0.29 dB, reciprocity 6.8e-8 dB). Mechanism: every ridge that joins the stretched string adds at least J(0) = 6 dB, while each line-of-sight section counts only its single most intruding sub-path obstruction, so on multi-ridge terrain several near-grazing ridges enter the sum together as the path length changes. Loss also reaches 284 dB at 42 km at 3 GHz (cascaded: 188-220 dB). Decision: abandon before scoring (program.md: fix or abandon; any fix would depart from the Recommendation). Code kept, not default.
- Rounded cylinders (H06) not implemented: eq. (122) as printed (Earth-curvature term -d_pq/a_e) gives a negative radius on a smooth Earth, so it waits for a check against independent reference code (TODO).
- Where this leaves H05: within published methods, the P.526-11 cascaded form with isolation-weighted edges (707) remains the best compromise found; the no-C forms (705, 708) and Bullington (703) fail the censored gate, and section 4.4 fails continuity.

### Tooling: parallel runs and run records (before B09)
- Date: 2026-11-21. Asked for by Nick to cut batch time. No scored run; no score change.
- `params_exp.m` reads optional per-run overrides from the environment variable `ITMEXP_OVERRIDES` (a JSON object of existing switch fields; `version`, `cal`, and unknown fields, wrong types, or bad JSON fail loud). The raw text is stored in `cfg.overrides`, which goes into `metrics.json`. Unset, every value is unchanged (new test `test_params_overrides`; 34 of 34 tests pass). Default `params_exp.m` MD5 now 1d2804dc4b525a84b21577c3cf9e78d2.
- `experiments/batches/launch_runs_rev1.m` submits one `run_eval_rev1` batch job per experiment, each with its own overrides, 5 s apart; it checks every override and refuses an existing tag first. `collect_runs_rev1.m` waits up to 60 s per call, prints each summary and any error, and rebuilds the archive once when all are done (parallel runs each refresh it and can race). The worker no longer edits or restores `params_exp.m`.
- Check: 707 and 708 rerun in parallel under scratch tags reproduce the logged Phase 2 predictions exactly (max difference 0 dB on every row); two runs took 1 min 43 s from first submit, against about 2 min 50 s in sequence. Local cluster: 8 workers. The scratch runs, and the B08 parity run that had entered the archive CSV, were moved to `_to_delete/scratch_runs/` on the Mac and the archive rebuilt without them.
- `experiments/batches/record_run_rev1.py <tag> --plan <B..md> --best <tag> --decision "..." [--write]` drafts the results.tsv row from `summary.txt` and the LOG entry (plan Change and Predicted lines, results, censored by site, by-edge, siting split); `--write` appends the row and refuses a duplicate ID. The worker still writes the prediction check. Checked on 707: the row matches the logged one.
- Worker procedure from B09: settings go in the launcher's override strings, not in `params_exp.m`; runs in a batch go in parallel unless the plan says one run depends on another.

### KEEP 707-cascaded-isolated-clutter-at-r (first keep)
- Date: 2026-11-21. Follow-up reviews by the three B07 reviewers: KEEP 707, KEEP 707, KEEP 707 (3 of 3). Reports: `experiments/B07-reviewer-pass/reviewer1_b08.md`, `reviewer2_b08.md`, `reviewer3_b08.md`.
- Merged into `best` (new branch, created from `exp/707-cascaded-isolated-clutter-at-r`: main plus the five switch lines). Main keeps stock defaults, so the parity check in CLAUDE.md still applies to main. Next batches branch from `best` and score with `Best="707-cascaded-isolated-clutter-at-r"`.
- Headline (held-out, full data): composite 12.51 dB against stock 16.02; screened 11.2 against 13.4; Phase 2 cell 13.25 against 18.3; long-term level 19.1 against 24.6; long-term shape 5.2 (unchanged); censored 22.8 % against 28.0 %. Site RMS R1 10.5 (13.3), R2 18.2 (28.6), R3 6.8 (9.0), VA 12.9 (15.4). No free parameters.
- What the model is: stock ITM with (1) the knife-edge part of the transhorizon diffraction replaced by a delta construction (ITU-R P.452-18 eq. 38-40 form, ITM's smooth-earth term as the spherical reference) using the ITU-R P.526-11 section 4.4.2 cascaded method with secondary edges weighted by the P.526-16 section 2.5 isolation criterion; (2) the loss bounded by ITM's own troposcatter line; (3) ITM's A_fo clutter factor removed from that construction (B06 reviewer pass); (4) ITU-R P.2108-1 section 3.1 terminal clutter at concealed Phase 2 mobile terminals, with the path computed at the clutter height R = 15 m and A_h held at its 3 GHz value above 3 GHz.
- Reviewer agreement (3 of 3): the term follows P.2108-1 section 3.1 and Table 1; open, `A`, and long-term rows equal 604 exactly; the censored pass survives removing concealed-row pessimism (23.3, 23.9, 24.2 %); prefer 707 over 709 (0.01 dB apart; 707 stays inside the validated 3 GHz range).
- Known limits, recorded with the keep (all three or two of three):
  - R2 censored 14.7 % against 6.8 % for stock, all on open rows from the 604 base. A per-site censored check is Nick's framework decision.
  - On terrain-obstructed open/concealed twin paths the term exceeds the measured excess by about 5.5 dB at R1 and R2 (701: 9 to 10 dB): clutter and terrain shadow don't simply add, and P.2108 doesn't address that case.
  - At VA the concealed 2 m vs high-antenna difference is 14.9 dB against 10.6 dB measured: P.2108's own height shape.
  - "hold3" flattens the concealed frequency slope at R1 and R2 (about 4 to 7 dB per decade against 10 to 11 measured); R2 concealed rows got more optimistic above 3 GHz.
  - On 26 concealed rows (6 paths, mostly R1-020-T8) raising the mobile antenna adds up to 4.5 dB, from the 604 multi-edge construction, not the B08 change; the synthetic height-gain battery check doesn't catch it (two of three).
  - Against 604, the clutter term gains 0.27 dB composite; it earns its place mainly on the censored gate and on physics. 707 and 701 can't be told apart on Phase 2 cell RMS (paired -0.06 +/- 0.14 dB).
- Archive: 701 is superseded by 707 (it is the double-counted form) and must not be used as a parent, though `results/archive_rev1.txt` still lists it on the Pareto front; see `results/superseded_rev1.txt`.

### B08 worker summary
- Date: 2026-11-21. Three runs in plan order (707, 709, 708); no errors, no infra events; every run under 2 minutes; open rows match 604 or 705 exactly. Mac `params_exp.m` restored to the defaults (MD5 e445ee80afe8fc350b047dfcf7d21bdb).
- **707 passes every gate and is held** for the three B07 reviewers to check their required-before-keep items: composite 12.5, censored 22.8 %, battery PASS, no free parameters, term applied as P.2108-1 section 3.1 says. 709 (with "extend") also passes and differs by 0.01 dB. 708 fails censored (32.5 %).
- Every registered prediction held except two per-site censored ranges, missed by under 0.5 points.
- Archive note: no B08 run is on the Pareto front, because 701's double count gives it slightly lower Phase 2 cell RMS (13.19 vs 13.25) and censored (21.4 vs 22.8 %). The archive ranks by score, not by physics; 701 stays on the front though it is the incorrect form.
- Still open: R2 censored 14.7 % against stock's 6.8 % (inherited from 604, all on open rows); open clear paths at R2 (-17 dB) and VA (-9 dB); R1 concealed obstructed +8.1 dB.

### B08 planned (planner note)
- Date: 2026-11-21. Planner: Claude Opus 5.5. Plan: `experiments/batches/B08.md`, registered before any scored run. Answers the B07 reviewers' required-before-keep list: base loss at max(h, R) per ITU-R P.2108-1 section 3.1 and Table 1 (`cfg.terminal_clutter_base = "clutter_height"`), A_h held at 3 GHz above 3 GHz (`"hold3"`) with an `"extend"` run beside it, censored by site (`b08_censored_by_site_rev1.py`), and a MATLAB test of all 18 NTIA/ITS vectors.
- Tests 33 of 33. Parity at defaults 6.8e-13 dB. Battery passes for both B08 settings. Default `params_exp.m` MD5 now e445ee80afe8fc350b047dfcf7d21bdb.
- Smoke (model only): the corrected term lowers concealed-row loss by 3.5 dB on average against 701 (1.4 to 3.8 dB below 3 GHz; 5.6 to 9.1 dB above 3 GHz with "hold3").
- Runs: 707 (604 base, corrected term), 709 (707 with "extend"), 708 (705 base, corrected term). A run that passes every gate goes back to the three B07 reviewers.

### B07 reviewer pass on 701 and 704 (three independent reviewers, 2-of-3 rule)
- Date: 2026-11-21. Reports: `experiments/B07-reviewer-pass/reviewer1.md`, `reviewer2.md`, `reviewer3.md`. Verdicts: HOLD, HOLD, HOLD (3 of 3). **701 and 704 stay held; neither is kept.**
- Agreed by all three, with numbers in the reports:
  - **701 applies P.2108-1 section 3.1 to the wrong base loss.** The Recommendation adds A_h to basic transmission loss "calculated to/from the height of the representative clutter height used" (section 3.1 and Table 1; checked against the PDF by the worker), and A_h = 0 when h >= R. 701 runs ITM at the real mobile height (2 to 14.5 m) and then adds A_h, so the gain from h up to R = 15 m is counted twice. On open/concealed twin paths, P.2108 matches the measured concealed-minus-open excess on clear paths (within 2.5 dB) but overshoots obstructed paths by 9 to 10 dB; VA 2 m concealed rows are 6 to 15 dB too pessimistic.
  - **The frequency shape is supported; the height shape isn't.** Measured concealed-minus-open excess rises 9.8 to 10.7 dB per decade (P.2108 about 9.4). Averaging A_h over heights within site and band loses nothing (Phase 2 cell 13.20 vs 13.19); shuffling it within site costs 0.48 dB.
  - **701 beats 704 by 0.09 dB composite** in a paired bootstrap (SD about 0.04; 95 % interval +0.01 to +0.17): real but well under the 0.3 dB keep threshold. The ~0.5 dB SD in the brief was the unpaired SD against stock. 704's 16.75 dB is the P.2108 mean, so 704 isn't an independent model and can't be kept on its own.
  - **Rows above 3 GHz carry about 64-65 % of 701's gain,** but the "extend" rule itself adds nothing: holding A_h at its 3 GHz value scores the same (13.20 vs 13.19). The NTIA/ITS reference code rejects input above 3 GHz.
  - **The censored gate pass comes entirely from concealed rows** (violated 67.7 % to 26.1 %; open rows unchanged). Reviewer 1: about half of the 207 removed violations are VA 2 m concealed rows that are now about 8 dB too pessimistic (the double count). Reviewer 3: removing the concealed-group pessimism still leaves 23.0 %, under the gate. R2 censored is 14.5 % against 6.8 % for stock (inherited from 604), so a per-site check would fail.
  - **Inputs:** mapping C to trees/forest (R = 15 m) is the best category (urban identical; dense urban 13.42, suburban 13.28); A behaves like O on twin paths (A minus O 0.6 to 3.9 dB, C minus O 6.7 to 11 dB); mobile end correct. At VA, concealed siting is confounded with the 2 m receiver (654 of 661 2 m rows are concealed).
  - **Clutter and terrain shadow don't add simply:** measured concealed excess is smaller on obstructed paths (R1 16.1 clear vs 10.7 obstructed; R2 21.2 vs 8.0). 702's +3.3 dB on R1 concealed obstructed rows comes from offsetting errors, not better physics.
- Record corrections:
  - The NTIA/ITS file has 18 valid height-gain test vectors, not 16; the unit test checks 6. Reviewers' ports match all 18 within 0.05 dB. Correction noted in B07.md.
  - The 704 reading above credits "frequency and height" shape; the reviewers show the shape gain is frequency alone.
  - The 701 note attributes the R1 concealed obstructed overshoot (+11.6 dB) to stacking on 604's multi-edge overshoot. About 6.3 dB is that; about 5.5 dB is P.2108 above the measured excess, mostly from the double count.
- Required before any keep (all three): rerun 701 with ITM evaluated at max(h, R) at the concealed mobile end, then add A_h (no new parameter); report censored violations by site; report the run with A_h held at its 3 GHz value above 3 GHz; add a MATLAB test of all 18 NTIA vectors. Reviewer 3's rough port estimates the corrected run at Phase 2 cell 13.13 and censored 22.0 %, which needs a MATLAB rerun.
- Suggested next experiments: 701 with the base loss at R (all three); 702's base with the corrected term (reviewer 1); the concealed obstacle as an extra edge inside the multi-edge sum, per P.526-16 section 4 (reviewer 2); a vegetation control per ITU-R P.833-10 (reviewers 1 and 2).
- For Nick: the per-site censored check (R2 at 14.5 % vs 6.8 %) is again the open framework decision.

### 701-cascaded-isolated-clutter
- Date: 2026-11-21. Batch B07. Parent: 000-baseline (best). Tier 2. Runs after PR #3 merged (evaluator passes `cfg.row`); Mac `eval/` MD5s match the tested scratch copy.
- Change: `cfg.diffraction = "delta_cascaded_isolated";`, `cfg.diffraction_bound = "itm_troposcatter_line";`, `cfg.terminal_clutter = "p2108_height_gain";`
- Source: ITU-R P.2108-1 section 3.1 eq. (2a)-(2g) at the mobile terminal of concealed (`C`) Phase 2 rows, trees/forest (R = 15 m); B06 sources for the rest. No free parameters.
- Result: composite 12.49 dB (stock 16.02); screened 11.1; Phase 2 cell 13.2; long-term level 19.1; shape 5.2. Site RMS R1 10.7 (mean +4.5), R2 17.7 (mean +0.2), R3 6.8 (mean +0.4), VA 13.1 (mean -2.3). Worst cell 27.4. Censored 21.4 %. Paired gain +3.54 (95 % +2.32 to +4.44); screened +2.26 (+1.62 to +2.86).
- Physics battery: PASS (merged PR #2 battery, with the height-gain check).
- By edge count (604 in brackets), R2 dead rows violated: 0-1 100.0 % [100.0]; 2 29.9 % [29.9]; 3 4.3 % [14.9]; 4+ 9.6 % [11.7]. Measured-row mean error: -12.2, -4.9, +13.3, +7.8 dB.
- Siting split, concealed mean error (604 in brackets): R1 C clear +1.7 [-16.9], obstructed +11.6 [-8.1]; R2 C clear -19.9 [-39.9], obstructed -11.5 [-29.4]; VA C clear -2.6 [-14.7], obstructed +6.2 [-4.9]. Open and `A` rows identical to 604, as designed. VA concealed censored violated 116 of 386 [267].
- Gates: battery pass; composite and screened gains above 0.3 dB with intervals above zero; no site worse than stock; censored 21.4 % <= 29.0 %; no new free parameters. **Passes every gate; held for the reviewer pass** (B07.md: siting input, C to trees/forest mapping, and the extension above 3 GHz are design choices).
- Predictions: Held: composite 12.5 (12.3-12.7); screened 11.1 (10.9-11.3); censored 21.4 (19-25); VA concealed violations 116 (80-160); Phase 2 cell 13.2 (13.0-13.8); LT level 19.1; concealed means R1 +9.0 (+4 to +10), R2 -13.2 (-20 to -8), VA +4.0 (0 to +8); site means R1 +4.5, R2 +0.2, R3 +0.4; R3 RMS 6.8 unchanged; battery pass. Missed: VA mean -2.3 (-2 to +0.5); VA RMS 13.1 (11-12.5); R2 by-edge, 2-edge rows unchanged (predicted 2-6 points lower) and 3-edge rows 10.6 points lower (more than predicted).
- Note: R1 concealed obstructed rows overshoot (+11.6 dB): the clutter term stacks on 604's multi-edge overshoot there (R1 open obstructed is already +6.3).

### 704-cascaded-isolated-constant (control)
- Date: 2026-11-21. Batch B07. Parent: 000-baseline. Tier 2.
- Change: as 701 but `cfg.terminal_clutter = "constant";` and `cfg.terminal_clutter_db = 16.75;` (the P.2108 term's mean on the 2,272 concealed rows, computed from the model, not fitted to measurements).
- Result: composite 12.58 dB; screened 11.2; Phase 2 cell 13.5; long-term level 19.1; shape 5.2. Site RMS R1 10.7 (mean +4.2), R2 18.0 (mean +0.1), R3 6.8 (mean +0.4), VA 14.0 (mean -0.7). Worst cell 28.7. Censored 23.1 %. Paired gain +3.45 (95 % +2.25 to +4.33); screened +2.17 (+1.53 to +2.77).
- Physics battery: PASS.
- Siting split, concealed mean error: R1 C clear -0.2, obstructed +8.7; R2 C clear -23.2, obstructed -12.6; VA C clear +2.0, obstructed +11.8.
- Gates: passes every gate. Held with 701 as its control for the reviewer pass.
- Predictions: Held: composite within 0.4 dB of 701 and worse (+0.09); VA RMS 0.5-1.5 dB worse (+0.9); censored within 3 points (+1.7); battery pass.
- Reading: the P.2108 frequency and height shape is worth only 0.1 dB of composite and 0.3 dB of Phase 2 cell RMS over a constant of the same mean. It does better at VA (RMS 13.1 vs 14.0): the constant overshoots VA concealed obstructed rows by 11.8 dB. Most of 701's gain over 604 is the level of the concealed-site loss.

### 702-deygout-isolated-clutter
- Date: 2026-11-21. Batch B07. Parent: 000-baseline. Tier 2.
- Change: `cfg.diffraction = "delta_deygout_isolated";`, bound, `cfg.terminal_clutter = "p2108_height_gain";`
- Result: composite 11.83 dB; screened 10.7; Phase 2 cell 13.7; long-term level 16.6; shape 5.2. Site RMS R1 10.1 (mean -1.1), R2 18.7 (mean -9.6), R3 6.6 (mean -2.4), VA 13.8 (mean -4.0). Worst cell 30.9. Censored 29.7 %. Paired gain +4.20 (95 % +2.68 to +5.26); screened +2.71 (+1.73 to +3.49).
- Physics battery: PASS. R3 RMS 6.6, unchanged from 705 (clutter inert on R3).
- By edge count, R2 dead rows violated: 100.0 / 36.3 / 21.0 / 19.7 %; measured-row mean error -18.9 / -15.6 / +1.2 / -3.0 dB.
- Siting split: R1 C obstructed +3.3; R2 C obstructed -20.0; VA C obstructed +3.7; R2 O obstructed -9.9 (280 of 1,078 censored violated).
- Decision: reject (censored 29.7 % > 29.0 %, by 0.7 points). Lowest composite of any run that keeps censored near stock. Pareto front, cell elite; archived as `arc/702-deygout-isolated-clutter`.
- Predictions: Held: R2 3 and 4+ edge rows +1.2/-3.0 (-3 to +3); censored 29.7 (28-40); LT level 16.6 (15-18); composite 11.8 (11.8-12.6); screened 10.7 (10.5-11.3); battery pass. Missed: R2 open obstructed -9.9 (-8 to -3); R2 open violations 280 (300-600).

### 703-bullington-clutter (control)
- Date: 2026-11-21. Batch B07. Parent: 000-baseline. Tier 2.
- Change: `cfg.diffraction = "delta_bullington";`, bound, `cfg.terminal_clutter = "p2108_height_gain";`
- Result: composite 10.96 dB; screened 9.7; Phase 2 cell 12.7; long-term level 15.0; shape 5.2. Site RMS R1 8.9 (mean +0.7), R2 17.4 (mean -9.7), R3 6.4 (mean -1.0), VA 13.5 (mean -6.3). Worst cell 27.0. Censored 55.0 %. Paired gain +5.06 (95 % +3.21 to +5.99); screened +3.70 (+2.34 to +4.56).
- Physics battery: PASS.
- By edge count, R2 dead rows violated: 100.0 / 49.0 / 44.4 / 79.2 %; measured-row mean error -12.8 / -12.9 / -1.3 / -9.6 dB. R2 open obstructed censored violated 729 of 1,078.
- Decision: reject (censored 55.0 %). Lowest composite in the archive. Pareto front, cell elite; archived as `arc/703-bullington-clutter`.
- Predictions: Held: censored 55.0 (48-58); LT level 15.0 (14.5-15.5); composite 11.0 (10.8-11.5); screened 9.7 (9.5-10.2); battery pass. Missed: Phase 2 cell 12.7 (13.0-13.6, better than predicted).

### 706-bullington-uc-clutter
- Date: 2026-11-21. Batch B07. Parent: 000-baseline. Tier 2.
- Change: `cfg.diffraction = "delta_bullington_uc";`, bound, `cfg.terminal_clutter = "p2108_height_gain";`
- Result: composite 11.84 dB; screened 10.9; Phase 2 cell 15.7; long-term level 14.6; shape 5.2. Site RMS R1 11.3 (mean -4.8), R2 23.6 (mean -18.9), R3 7.9 (mean -3.9), VA 15.1 (mean -9.2). Worst cell 32.0. Censored 82.8 %. Paired gain +4.19 (95 % +2.10 to +5.31); screened +2.45 (+1.13 to +3.39).
- Physics battery: PASS.
- By edge count, R2 dead rows violated: 100.0 / 100.0 / 90.7 / 99.3 %. R2 open obstructed censored violated 1,078 of 1,078.
- Decision: reject (censored 82.8 %). Pareto front (best long-term level, 14.6), cell elite; archived as `arc/706-bullington-uc-clutter`.
- Predictions: Held: composite 11.8 (10.8-12.0); battery pass. Missed: censored 82.8 (58-70): without eq. (57) the single-edge form is optimistic on every obstructed class.

### B07 worker summary
- Date: 2026-11-21. All six runs. 705 ran first, before PR #3 was merged (the 705-only case); 701, 704, 702, 703, 706 ran after the merge, in plan order. One infra event: the MCP call that launched 706 timed out waiting for a reply; the batch job had started (job 186) and finished normally, so it was not relaunched and no retry was needed. Mac `params_exp.m` restored to the defaults (MD5 8b0f92c53f7791f59aa7e57b5cbfb4ea). No stop condition hit: no errors, battery results as tabled, R3 RMS unchanged in the clutter runs that have a no-clutter twin (701 vs 604, 702 vs 705), every run under 2 minutes.
- **701 passes every gate and is held** for the three-reviewer pass: composite 12.5, screened 11.1, censored 21.4 % (stock 28.0 %), battery PASS with the height-gain check, no free parameters. **704 (constant control) also passes** and is held with it.
- Rejected on the censored gate: 705 (39.7 %), 702 (29.7 %, composite 11.8), 703 (55.0 %, composite 11.0), 706 (82.8 %). 702, 703, 706 archived; 705 is no longer on the front (702 beats it on all four objectives) but its archive branch stays.
- Reading:
  - The concealed-site term does what it was planned to do: concealed-row bias at VA and R1 moves from -5 to -17 dB to about -3 to +12 dB, and VA concealed censored violations fall from 267 to 116, without touching open rows.
  - The P.2108 shape barely beats a constant of the same mean (704: 0.1 dB composite, 0.9 dB VA RMS). The data support "concealed sites have about 17 dB more loss"; they only weakly support the frequency and height shape.
  - Removing P.526-11's C (702) fixes the multi-edge overshoot on open obstructed paths and gives the best composite under about 30 % censored, but it misses the gate by 0.7 points; R2 open obstructed rows become 10 dB optimistic.
  - R1 concealed obstructed rows overshoot by 11.6 dB in 701: the clutter term stacks on the remaining multi-edge overshoot there. 702 brings them to +3.3.
  - Still open, untouched by any B07 change: R2 open clear paths (-17 dB) and VA open clear paths (-9 dB).
- Archive note: the MAP-Elites cell key doesn't include `cfg.terminal_clutter`, so 701 replaces 604 as the elite of the `delta_cascaded_isolated` cell instead of opening a new cell. That is an evaluator matter, not changed here.

### 705-deygout-isolated
- Date: 2026-11-21. Batch B07. Parent: 000-baseline (best). Tier 2. Run before PR #3 is merged (the 705-only case in B07.md); 701-704 and 706 wait for it.
- Change: `cfg.diffraction = "delta_deygout_isolated";` and `cfg.diffraction_bound = "itm_troposcatter_line";`
- Rationale: prices P.526-11's empirical C = 10 + 0.04 D alone against 604 (same isolation-weighted edges, no C or T).
- Predicted (from B07.md, before the run): censored 38-48 %; R2 measured 3 and 4+ edge rows -3 to +3; long-term level 15-18; composite 12.0-12.8; screened 10.6-11.6. Battery: pass.
- Result: composite 12.32 dB (stock 16.02); screened 11.2; Phase 2 cell 15.2; long-term level 16.6; shape 5.2. Site RMS R1 11.8 (mean -3.3), R2 21.0 (mean -11.2), R3 6.6 (mean -2.4), VA 14.9 (mean -7.0). Worst cell 34.6. Censored 39.7 %. Paired gain +3.70 (95 % +2.11 to +4.87); screened +2.21 (+1.29 to +3.03).
- Physics battery: PASS (main's `eval/`). Also checked with PR #2's battery from the scratch copy: PASS, height-gain net change +0.19 dB (stock -23.30).
- By edge count (604 in brackets):
  - edges 0-1: dead rows violated 100.0 % of 41 [100.0]; measured-row mean error -21.6 dB [-14.9]
  - edges   2: dead rows violated  36.3 % of 204 [29.9]; measured-row mean error -15.6 dB [-4.9]
  - edges   3: dead rows violated  35.9 % of 376 [14.9]; measured-row mean error  -0.6 dB [+11.5]
  - edges  4+: dead rows violated  21.8 % of 563 [11.7]; measured-row mean error  -3.3 dB [+7.5]
- Siting split, mean error (604 in brackets): R1 O obstructed -1.0 [+6.3]; R2 O obstructed -9.9 [+0.9]; R3 O obstructed -2.5 [+6.7]; VA O obstructed -3.7 [-0.4]; R1 C obstructed -16.4 [-8.1]; R2 C obstructed -37.8 [-29.4]; VA C obstructed -7.4 [-4.9]; open clear paths R2 -17.7 [-17.0], VA -9.5 [-8.9].
- Decision: reject (censored 39.7 % > 29.0 %). On the Pareto front and its cell's elite, so archived as `arc/705-deygout-isolated`.
- Predictions: Held: censored 39.7 (38-48); R2 3-edge rows -0.6 (-3 to +3); long-term level 16.6 (15-18); composite 12.3 (12.0-12.8); screened 11.2 (10.6-11.6); battery pass. Missed narrowly: R2 4+ edge rows -3.3 (-3 to +3).
- What it tells us: removing C fixes the multi-edge overshoot on open obstructed paths (R1, R3 near zero; R2 3+ edge rows near zero) but moves every class about 3-10 dB more optimistic, which raises censored violations. The concealed rows carry most of the new optimism, which is what the clutter term in 702 is for.
- Mac defaults restored afterward (MD5 8b0f92c53f7791f59aa7e57b5cbfb4ea).

### B07 planned (planner note)
- Date: 2026-11-21. Planner: Claude Opus 5.5. Plan: `experiments/batches/B07.md`. No scored run yet.
- Siting codes from the Phase 2 readme: `O` open (clear foreground at the mobile terminal), `C` concealed (immediately behind a grove of trees or a building), `A` undefined. Mobile terminal: transmitter in R1-R3, receiver in VA. Mapping `C` → P.2108 trees/forest; `O` and `A` → 0.
- New code, no free parameters: ITU-R P.2108-1 section 3.1 (`p2108_height_gain_rev1`; matches the NTIA/ITS test vectors; corrected later: 18 valid vectors, of which B07 tested 6, all 18 tested from B08), applied above 3 GHz by a documented "extend" rule (design choice); `cfg.terminal_clutter` with a constant-offset control; `"deygout_isolated"` and `"bullington_uc"` (no P.526-11 C, no eq. (57)) and their delta forms. Tests 31 of 31. Parity at defaults 5.0e-13 dB (long-term), 6.8e-13 dB (Phase 2 sample). Default `params_exp.m` MD5 now 8b0f92c53f7791f59aa7e57b5cbfb4ea.
- Blocker: 71 of 108 concealed paths share a terrain profile with their open twin, so the variant needs the row's siting from the evaluator (`cfg.row`). Nick approved that `eval/` change; it is PR #3 (stacked on PR #2), checked from a scratch copy on the Mac (parity 6.8e-13 dB; battery with clutter passes). Until it is merged only experiment 705 can run; the clutter settings error by design.
- Battery (code only, with PR #2's height-gain check): all four diffraction settings pass.
- Logged-run evidence (604): concealed rows 5-40 dB too optimistic, worse at high frequency; open clear paths at R2 (-17 dB) and VA (-9 dB) also too optimistic, which clutter can't reach.
- A three-reviewer pass is required before any keep.

### Decisions from Nick after the B06 reviewer pass
- Date: 2026-11-21.
- Scope: the team is open to changing, removing, or adding any part of ITM.
- Terminal clutter input: B07 may map the existing Phase 2 `siting` column (C, O) to an ITU-R P.2108 clutter category. No new data source.
- Physics battery: add a height-gain check (net loss change over the 1-30 m receiver sweep must not exceed max(stock, 0) + 1 dB). Proposed as PR #2 (branch `battery-height-gain-rev1`) because agent commits can't edit `eval/`; it takes effect when Nick merges it. On the sweep, both `_afo` forms fail it (+5.9 and +5.8 dB) and the forms without A_fo pass (+0.2 dB).
- Housekeeping: the remote branch `exp/601-delta-cascaded-isolated-afo-bounded` couldn't be deleted from this session (HTTP 403); the same commit is on `arc/601-delta-cascaded-isolated-afo-bounded`.

### B06 reviewer pass on A_fo, 502, and 601 (three independent reviewers, 2-of-3 rule)
- Date: 2026-11-21. Three fresh agents, same brief (B06.md), no shared work. Reports: `experiments/B06-reviewer-pass/reviewer1.md`, `reviewer2.md`, `reviewer3.md`. The reviewers worked from 401, 502, and 601; the controls 602-605 finished after they started.
- Agreed (3 of 3):
  1. **Remove A_fo from the delta forms.** Its source (Longley and Rice 1968, ESSA ERL 79-ITS 67, eq. (3.38c); Hufford's ITM algorithm paper) calls it a "clutter factor" and gives no data basis. It grows with h1 h2, the opposite of terminal clutter loss.
  2. **601 is not kept.** Two say hold, one says reject; all three say don't merge. Decision: reject. It stays on the Pareto front.
  3. The brief was wrong on one point: A_fo sits outside the max(·), so 502 - 401 equals A_fo on every row (checked on 16,805 rows to 0.007 dB), not only where the max(·) is inactive.
  4. A_fo's frequency shape doesn't match the missing loss. The loss 401 misses rises about 13 dB per decade at R2 and VA and 0-3 dB per decade at R1 and R3; A_fo rises about 4.4 dB per decade everywhere.
  5. A_fo's gain is all at R2 and VA (388 of the 416 censored rows it fixes). R3 gets worse (RMS 6.1 to 8.0 dB, mean -0.6 to +4.6 dB).
  6. The delta forms stack empirical allowances for real terrain that were fitted without each other: Bullington eq. (57) or P.526-11 eq. (51) C, plus A_fo, plus (601) the secondary edges.
  7. A_fo is a stand-in for a site-specific loss near the terminals that rises with frequency (likely vegetation or clutter). The proposed replacement is a published terminal clutter term (ITU-R P.2108; P.833 for vegetation), with the equations read before coding.
- Agreed (2 of 3):
  8. Most of A_fo's value is a level offset. A constant 5.46 dB on 401 gets 80 % of its RMS gain, and shuffling A_fo between paths within a site gets 64-100 % (reviewers 1 and 3).
  9. 601's multi-edge gain within an edge count is close to a uniform shift. The censored gate is cheap to pass with uniform pessimism: stock ITM plus 2.9 dB reaches 25.3 % (reviewers 1 and 2; reviewer 3 finds it partly real: AUC 0.887 to 0.916 and better than a constant shift of 502).
- Single-reviewer findings, recorded but not acted on:
  - Reviewer 2: with path and frequency fixed, raising h1 h2 (receiver 1 m to 8 m) lowers measured loss by 8.7 dB; 401 lowers it 3.3 dB, stock ITM 2.4 dB, and 502 *raises* it 0.5 dB. The physics battery checks only for jumps on the height sweep, not direction.
  - Reviewer 1: the missing frequency slope at R2 and VA is about the same on clear and obstructed paths, so it isn't diffraction. Reviewer 3 instead ties R2's part to separated ridges (D03).
  - Reviewer 1: a per-site clutter category may count as changing inputs, which the rules forbid; ask Nick.
- The controls agree: 604 (601 without A_fo) composite 12.8, censored 31.5 %, R3 mean +0.4 dB.
- Actions: 601 rejected. A_fo is not used in further delta forms unless a later run replaces it with a cited term. The next batch tests the replacement and the empirical-correction stacking. Two decisions go to Nick (framework items the agents can't edit): a height-direction battery check, and whether a terminal clutter category from the existing `siting` column or public land cover is an allowed input.

### B06 worker summary
- Date: 2026-11-21. One run (601) of five. 601 passes every gate and uses A_fo, so it is held for the reviewer pass (B06.md) and the batch is handed back; 603, 604, 602, and 605 were not run. No infra retries. Mac `params_exp.m` restored to the defaults (MD5 e9b334fa5d68c11e0159ace40f027ae4).
- 601: composite 13.35, screened 11.85, censored 25.8 %, battery PASS, paired gains +2.67 and +1.54 (intervals above zero), no site worse by more than 0.1 dB. First structural run to beat stock ITM on all four archive objectives.
- Controls run after the hand-back (Nick approved): 603 (502 + bound) is 502 within 0.1 dB, censored 49.6 %. 604 (601 without A_fo) composite 12.8, screened 11.4, censored 31.5 % (2.5 points over the gate), battery PASS. 602 (601 without the bound) composite 18.6, long-term level 35.7: the bound is necessary. 605 (503 + bound) composite 13.4, censored 28.9 %, battery FAIL.
- Reading: on the new edge term, A_fo costs 0.6 dB of composite and buys 5.7 points of censored (31.5 -> 25.8 %), mostly on R2's 0-1 edge rows (100 -> 68 % violated). The three-reviewer pass on A_fo and 601 is running.

### B06 planned (planner note)
- Date: 2026-11-21. Planner: Claude Fable 5.2. Plan: `experiments/batches/B06.md`. No scored run yet.
- 501's blow-up: unbounded stacking of grazing edges, not a code defect. On LT_LT1804 (1,028 km, 417 MHz) `string_ep` finds 56 obstructions, 40 of them under 8 dB each (median ν 0.14), and sums 472 dB; Bullington gives 83, Deygout 123, P.526-11 cascaded 174. Every delta form also lacks a troposcatter limit on L_a.
- 503 and 504's battery steps traced to two artifacts, both from points with no valley before the principal edge: the neighboring sample of a split top (18.5 dB step) and the ground beside the principal edge (11.9 dB step on flat terrain).
- New code, no free parameters: `"p526_cascaded_isolated"` (P.526-11 section 4.4.2 with secondary edges weighted by isolation, P.526-16 section 2.5); `cfg.diffraction_bound` (`"itm_troposcatter_line"`, `"itm_troposcatter"`); delta forms `"delta_cascaded_isolated"` and `"delta_cascaded_isolated_afo"`. Tests 27 of 27. Parity at defaults 5.0e-13 dB (548 long-term links). `params_exp.m` default MD5 is now e9b334fa5d68c11e0159ace40f027ae4 (one new switch line).
- Battery (code only): the new edge term passes with and without A_fo and with the line bound; the region form of the bound steps 15 dB on the frequency sweep and isn't scheduled.
- Smoke (model against stock ITM, no measurements): without the bound, 52 long-term links are more than 50 dB above stock with the new edge term; with the line bound, none.
- Plan updates that would go in docs/PLAN_rev1.md (the guard blocks planner edits there): Stage 2 structural search continues with B06; the reviewer pass on 502's A_fo (possible double counting with L_a) is requested and must finish before any `_afo` run is merged; the rounded-obstacle term (P.526-16 section 4.2) stays unbuilt until the equations are read from the Recommendation.
- Control "A_fo added to 506" can't be run as asked: 506 already contains A_fo (the non-delta switches keep ITM's `w A_se + A_fo`).

### B05 worker summary
- Date: 2026-11-21. Six runs (501-506), none kept. Four failed the physics battery as the plan listed (501, 503, 504, 506); two passed the battery and failed the censored gate (502 at 47.2 %, 505 at 91.3 %). 502 and 505 are new Pareto-front members, kept as `arc/` branches. No infra retries. Parameters file on the Mac restored to the defaults; MD5 c494457ec3b988caaf9d4a7666f5e2da matches the repo.
- Main results for the planner:
  1. Counting ridges removes the optimism: 501 drops 4+ edge dead-row violations from 81 % (401) to 21 %, and 504 to 4 %, but unbounded edge sums give 100-600 dB on 500-1,000 km paths.
  2. A_fo is a main cause of the delta construction's optimism: 502 cuts censored from 67.6 % to 47.2 % and has the best composite (11.1) with the battery passing.
  3. Without Bullington's eq. (57) correction (505) the delta construction predicts too little loss almost everywhere (censored 91 %).
  4. Bullington on blocked paths alone (506) keeps censored at 35 %.
- Open question: 501's long-term blow-up looks like unbounded edge stacking, not a coding defect; the planner should confirm.

### B05 planned (planner note)
- Date: 2026-11-21. Planner: Claude Fable 5.2. Plan: `experiments/batches/B05.md`,
  experiments 501–506.
- New: `"string_ep"` (stretched-string obstructions, P.526-16 section 4.4
  eq. (44), merged by a Fresnel-clearance test; Epstein-Peterson sum), the
  delta construction with any obstruction method, and the
  `"delta_bullington_afo"` control. Tests 21 of 21 pass; parity
  6.8 × 10⁻¹³ dB.
- Battery code check: `delta_ep_isolated` and `delta_bullington_afo` pass;
  the three multi-edge delta settings and Bullington with `blocked_paths`
  fail continuity, because each counted edge adds at least 6 dB. They're
  scheduled as mechanism tests and can't be kept.
- By-edge-count evidence from existing runs: 401 is too low on R2's measured
  rows at every edge count (−15.6 dB on 0–1 edge rows, −9.9 dB on 4+), so
  edge counting is one of two candidate mechanisms; the other is a loss
  term common to all R2 paths (502 tests ITM's A_fo).
- Not built: the rounded-obstacle term of P.526-16 section 4.2 (the
  extraction of eq. (34)–(36) was inconsistent; needs the PDF).

### 501-delta-string-ep
- Date: 2026-11-21. Batch B05. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_string_ep";`
- Rationale: separated ridges each cost a diffraction loss; one equivalent edge can't represent several.
- Predicted (from B05.md, before the run): R2 dead rows violated: 4+ edges from 81 % to 30–60 %, 3 edges from 63 % to 30–55 %, 0–1 edges unchanged (100 %). R2 measured mean error from −11.3 to between −7 and −2 dB; on 3-edge measured rows it moves from −3 to positive (worse). Censored overall 45–60 % (VA stays near 83 %). Long-term level 15–19. Composite 11.5–13.5. Battery: fail as listed.
- Result: composite 27.96 dB (stock 16.02); screened 27.1; Phase 2 cell 16.5; long-term level 62.2; shape 5.2. Site RMS R1 14.6 (mean -3.4), R2 21.8 (mean -10.7), R3 6.9 (mean -3.3), VA 16.5 (mean -7.8). Censored 35.6 %. Max change from stock 410 dB. Paired gain -11.94 (95 % -15.70 to -7.93).
- Physics battery: FAIL (as listed).
- By edge count (violations_by_edges_rev1.py):
  - edges 0-1: dead rows violated 100.0 % of 41; measured-row mean error -22.2 dB
  - edges 2: 36.3 % of 204; -16.9 dB
  - edges 3: 31.6 % of 376; -0.5 dB
  - edges 4+: 20.8 % of 563; -1.5 dB
- Decision: reject (battery fail; composite and long-term level far worse). Not archive-eligible.
- Predictions: held: battery fail; 0-1 edges 100 %; 3 edges 63 -> 32 % (predicted 30-55). Missed: 4+ edges 81 -> 21 % (predicted 30-60, better than predicted); R2 mean -10.7 (predicted -7 to -2); 3-edge measured mean -0.5, not positive; censored 35.6 % (predicted 45-60); long-term level 62.2 (predicted 15-19); composite 28.0 (predicted 11.5-13.5).
- Worker note: 128 of 548 long-term rows are more than 50 dB above stock, up to 661 dB (LT1804_0577, 1,028 km, 417 MHz; stock 252, measured 253). Epstein-Peterson sums every merged obstruction on 500-1,000 km paths, so loss grows without bound with path length. This is the mechanism, not a coding defect as far as the worker can tell; the planner should check.

### 502-delta-bullington-afo
- Date: 2026-11-21. Batch B05. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_bullington_afo";` (control)
- Rationale: the smooth-path ITM call drops A_fo, a loss of up to 15 dB that stock ITM applies to every diffraction path.
- Predicted (from B05.md, before the run): 3–10 dB more loss on most R2 rows. R2 measured mean error from −11.3 to between −8 and −3 dB; 0–1 edge dead rows violated from 100 % to 70–95 %; censored overall 55–65 %. Composite 11.0–12.0. Battery: pass.
- Result: composite 11.13 dB (stock 16.02; R02 15.93; P.452 14.18; P.2001 13.97); screened 9.6; Phase 2 cell 12.9; long-term level 15.4; shape 5.1. Site RMS R1 10.6 (mean +2.8), R2 16.8 (mean -6.0), R3 7.9 (mean +4.6), VA 12.1 (mean -4.0). Censored 47.2 %. Paired gain +4.89 (95 % +3.36 to +5.79); screened +3.75 (+2.59 to +4.51).
- Physics battery: PASS.
- By edge count:
  - edges 0-1: dead rows violated 68.3 % of 41; measured-row mean error -9.7 dB
  - edges 2: 23.5 % of 204; -7.6 dB
  - edges 3: 44.9 % of 376; +2.4 dB
  - edges 4+: 49.9 % of 563; -4.4 dB
- Decision: reject (censored 47.2 % > 29.0 %). On the Pareto front and its cell's elite: kept as `arc/502-delta-bullington-afo`. Best composite of any run so far; beats P.452 and P.2001 on all four archive objectives.
- Predictions: held: composite 11.0-12.0 (11.1); R2 mean -8 to -3 (-6.0); battery pass. Missed: 0-1 edge dead rows 100 -> 68 % (predicted 70-95, just below); censored 47.2 % (predicted 55-65).
- Flag for the planner (the plan asked for this): censored fell below 50 %, so ITM's dropped A_fo term is a main cause of the optimism of 401. Restoring it cut composite by 0.3 dB, censored by 20 points versus 401 and the 0-1 edge violations from 100 % to 68 %.

### 503-delta-p526-cascaded
- Date: 2026-11-21. Batch B05. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_p526_cascaded";`
- Rationale: Deygout's three edges with the ITU-R correction, the method ITU-R used before delta-Bullington.
- Predicted (from B05.md, before the run): more loss than 501 on long paths. Censored 35–55 %; R2 measured mean error −5 to +3 dB; long-term level 17–24; composite 12.5–15. Battery: fail as listed.
- Result: composite 17.0 dB; screened 15.5; Phase 2 cell 15.1; long-term level 30.6; shape 5.2. Site RMS R1 12.1 (mean +5.4), R2 21.3 (mean +2.7), R3 8.0 (mean +2.0), VA 13.8 (mean -6.2). Censored 26.8 %. Paired gain -0.94 (95 % -2.63 to +0.12).
- Physics battery: FAIL (as listed).
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of 41; measured-row mean error -13.4 dB
  - edges 2: 23.5 % of 204; -0.3 dB
  - edges 3: 14.4 % of 376; +14.6 dB
  - edges 4+: 0.0 % of 563; +19.5 dB
- Decision: reject (battery fail; composite above stock).
- Predictions: held: battery fail; R2 mean error (+2.7, in -5 to +3); more loss than 501 on long paths is not directly comparable (501 stacks unbounded loss on 500 km paths). Missed: censored 26.8 % (predicted 35-55); long-term level 30.6 (predicted 17-24); composite 17.0 (predicted 12.5-15).

### 504-delta-deygout
- Date: 2026-11-21. Batch B05. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_deygout";`
- Rationale: 503 without the empirical correction, to separate the edge count from the correction.
- Predicted (from B05.md, before the run): between 501 and 503. Censored 40–60 %; composite 12–14. If 504 has clearly fewer violations than 501 on 0–1 and 2-edge rows, the shoulders-of-one-top artifact is the reason. Battery: fail as listed.
- Result: composite 13.0 dB; screened 11.6; Phase 2 cell 14.7; long-term level 19.0; shape 5.2. Site RMS R1 10.3 (mean +0.1), R2 20.5 (mean -6.9), R3 6.4 (mean +0.1), VA 15.5 (mean -9.5). Censored 36.6 %. Paired gain +3.07 (95 % +1.20 to +4.24); screened +1.84 (+0.45 to +2.72).
- Physics battery: FAIL (as listed).
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of 41; measured-row mean error -19.5 dB
  - edges 2: 23.5 % of 204; -11.0 dB
  - edges 3: 35.6 % of 376; +2.6 dB
  - edges 4+: 3.9 % of 563; +8.7 dB
- Decision: reject (battery fail).
- Predictions: held: composite 12-14 (13.0); battery fail. Missed: censored 36.6 % (predicted 40-60, just below); not between 501 and 503 (503 composite 17.0, 501 28.0, 504 13.0). Shoulder artifact check: 504 vs 501 on 2-edge rows 23.5 % vs 36.3 % violated, on 0-1 edge rows both 100 %. Mixed: some support for the artifact on 2-edge rows only.

### 505-delta-ep-isolated
- Date: 2026-11-21. Batch B05. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_ep_isolated";`
- Rationale: the two-horizon-edge method that passes the battery; its strict isolation test merges most pairs, so it mostly tests the delta construction without Bullington's eq. (57) correction.
- Predicted (from B05.md, before the run): close to 401. Composite 11.4–12.2; censored 62–72 %. Battery: pass.
- Result: composite 12.38 dB; screened 11.8; Phase 2 cell 18.0; long-term level 14.0; shape 5.2. Site RMS R1 13.8 (mean -7.4), R2 27.5 (mean -22.8), R3 8.0 (mean -4.1), VA 17.7 (mean -12.8). Censored 91.3 %. Paired gain +3.62 (95 % +1.24 to +4.88); screened +1.61 (+0.08 to +2.66).
- Physics battery: PASS.
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of 41; measured-row mean error -22.2 dB
  - edges 2: 80.9 % of 204; -21.4 dB
  - edges 3: 100.0 % of 376; -18.9 dB
  - edges 4+: 100.0 % of 563; -25.4 dB
- Decision: reject (censored 91.3 % > 29.0 %; Phase 2 cell 18.0 only 0.3 dB better than stock). On the Pareto front (best long-term level, 14.0) and its cell's elite: kept as `arc/505-delta-ep-isolated`.
- Predictions: held: battery pass. Missed: composite 12.4 (predicted 11.4-12.2, just above); censored 91.3 % (predicted 62-72). Without Bullington's eq. (57) correction the delta construction is far more optimistic than 401 (R2 mean -22.8 dB).

### 506-bullington-blocked-paths
- Date: 2026-11-21. Batch B05. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "bullington";` and `cfg.diffraction_region = "blocked_paths";` (control)
- Rationale: reach ITM's blocked line-of-sight-region paths with Bullington but without the delta construction.
- Predicted (from B05.md, before the run): like 201 (56 %): censored 45–60 %, R2 measured mean error −6 to −10 dB. Battery: fail as listed (by 0.3 dB over the margin).
- Result: composite 14.60 dB; screened 12.4; Phase 2 cell 15.1; long-term level 23.6; shape 5.2. Site RMS R1 10.6 (mean +0.7), R2 21.8 (mean +0.6), R3 7.7 (mean -0.5), VA 14.5 (mean -7.3). Censored 35.2 %. Paired gain +1.43 (95 % +0.87 to +2.01); screened +1.00 (+0.56 to +1.62).
- Physics battery: FAIL (as listed).
- By edge count:
  - edges 0-1: dead rows violated 68.3 % of 41; measured-row mean error -10.1 dB
  - edges 2: 17.2 % of 204; -2.3 dB
  - edges 3: 17.6 % of 376; +18.9 dB
  - edges 4+: 16.9 % of 563; +4.9 dB
- Decision: reject (battery fail). Not archive-eligible.
- Predictions: held: battery fail. Missed: censored 35.2 % (predicted 45-60, like 201's 56 %); R2 mean +0.6 (predicted -6 to -10). Bullington on blocked paths alone keeps censored near 35 %, well below the delta constructions.

### D03-r2-dead-paths (diagnostic, no model change)
- Date: 2026-11-21.
- Question: what separates R2's 1,184 no-signal rows from its 2,560 measured
  rows, which every model that fits the measured rows lands on?
- Method: `experiments/D03-r2-dead-paths/r2_dead_paths_rev1.py`. Geometry
  from the 30 m CSV profiles on a 4/3 earth: obstruction height above the
  antenna ray, Bullington ν (P.526-16 eq. (49)–(55)), Deygout edges with
  ν > 0 to depth 3 (P.526-11 section 4.4.2), and the spread between the
  outermost edges. Compared within bins of the delta-Bullington (401)
  predicted loss, so the model's own estimate is held fixed.
- Finding: at the same predicted loss, the share of dead rows rises steeply
  with the number of separate edges. Predicted 160–173 dB: 2 % dead with one
  edge, 51 % with four or more. 173–188 dB: 13 % against 82 %. Dead rows are
  long (median 50 km against 10 km), deeply obstructed (452 m against 63 m),
  and their edges are spread out (17 km against 30 m, effectively one
  ridge). 30 of 45 R2 paths have both dead and measured rows; on those, the
  dead rows are the higher frequencies (median 1,846 against 751 MHz) at
  the same antenna heights.
- Interpretation: the delta construction's single equivalent edge
  underweights paths with several separated ridges, which is where the
  no-signal results sit. A multi-edge obstruction loss inside the delta
  construction (Deygout, Epstein-Peterson with the isolation test, or the
  P.526 cascaded method in place of L_ba) is the hypothesis this points to.
  In B01 those methods added too much loss because they sat inside ITM's
  extrapolated knife-edge structure; inside the delta construction they
  replace only the obstruction term.
- Caveat: edge count is confounded with distance and frequency; the binned
  comparison controls for predicted loss, not for every covariate.

### B04 summary (corrected after the reviewer pass)
- Date: 2026-11-21. Kept: none. Best stays `000-baseline`.
- ITM with delta-Bullington reference attenuation (401) has composite
  11.5 dB against P.452 14.2 and P.2001 14.0, and passes the physics
  battery. The edge is in the long-term terms (level 15.0 against 18.5 and
  21.2; shape 5.2 against 9.9 and 6.6). On Phase 2 it does not beat the ITU
  models (cell 14.2 against 14.1 for both). The recalibrated ITM R01, which
  fails the gates, scores 12.4.
- It predicts signal on 71 % of R2's no-signal rows (P.452 67 %, P.2001
  68 %, stock ITM 7 %). On censored rows its predictions correlate with
  P.2001 at r = 0.995 (stock ITM 0.80).
- Cause, as corrected: replacing ITM's loss on blocked paths, including the
  ones ITM puts in its line-of-sight region, with an obstruction-only loss.
  Three results show it: 201 and 202 reach 56 % censored with no delta
  construction, only by extending the profile-based loss to those paths;
  free space plus L_ba alone reaches 74 %; and in 401 the smooth-earth term
  max(A_s − L_bs, 0) is about zero on the failing rows (77 % within ±1 dB of
  free space plus L_ba). Not yet separated: dropping ITM's clutter term A_fo
  (up to 15 dB) and its smooth-earth weight, which the smooth-path ITM call
  also does. The first version of this entry blamed the smooth-earth step;
  that was wrong.
- Together with D03, this places the R2 dead paths where a single equivalent
  edge underweights several separated ridges.

### B04 reviewer pass (three independent reviewers, 2-of-3 rule)
- Date: 2026-11-21. Reviewers: fresh agent sessions with no planner
  context, read-only, Python on the stored files.
- All three reported. Agreed by at least two (acted on):
  - The headline numbers (composite, censored rates by site, 96.5 %
    overlap, 12.9 dB median margin) recompute exactly from the raw files.
  - The 96.5 % overlap is weak evidence: stock ITM's violations already sit
    94 % inside P.2001's, and naive models (site-shifted ITM, random picks)
    give 71–95 %. The row-level correlation (r = 0.995) is the real evidence.
  - 104 is not a fair control for "Bullington alone": it replaced only the
    (1 − w) knife-edge share, only on transhorizon paths, and left 57 % of
    censored rows unchanged. The smooth-surface attribution was refuted.
  - The reading of censored rows as lower bounds is correct (the stored
    value is free space plus the median of exact values and lower bounds).
  - No transcription bug in `delta_bullington_reference` (eq. (161)–(167),
    both forms, the heights passed to the smooth ITM call).
  - Reaching ITM's blocked line-of-sight-region paths explains most of the
    jump (201, 202 already reach 56 %); dropping ITM's clutter term A_fo and
    smooth-earth weight in the smooth-path call is an untested contributor.
  - Missing controls: Bullington with `diffraction_region = "blocked_paths"`;
    delta with the actual Δh (keeping A_fo); delta with ITM's effective
    heights.
- Noted by one (logged, not acted on):
  - P.452 is scored on 14,308 Phase 2 rows against 14,760 for the others.
  - On R2, 401 lowers loss by 41 dB on censored rows against 21 dB on
    measured rows.
  - `delta_bullington_reference` ignores `cfg.diffraction_region`; the cfg
    doesn't record that.
  - 39 censored rows on clear-path profiles are violated by every model,
    which points to a terrain or data limit.
  - Ablations not run: delta without eq. (166), A_s with the actual Δh, and
    delta only beyond the horizon.

### B04 planned (planner note)
- Date: 2026-11-21. Planner: Claude Opus 5.5. Plan: `experiments/batches/B04.md`.
- New: `"delta_bullington"` (P.452-18 eq. (38)–(40) form) and
  `"delta_bullington_p526"` (P.526-16 eq. (66) form), with ITM's own
  smooth-earth reference standing in for the spherical-earth loss. Smooth
  surface per P.452-18 eq. (161)–(167), checked against
  `nicklasorte/matlab_itu_p452`.
- Tests 15 of 15 pass; both forms pass the battery; parity 6.8 × 10⁻¹³ dB.
- A first test expected a ridge on flat terrain to add more than 10 dB; it
  adds 3.4 dB because of obstacle gain (ITM's smooth-earth loss on that path
  is 37 dB, the ridge's knife edge about 29 dB). Test corrected before any run.

### 401-delta-bullington-p452
- Date: 2026-11-21. Batch B04. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_bullington";`
- Rationale: blocked paths get their obstruction loss from the actual profile, and smooth-earth loss only as an excess over the smooth-profile Bullington loss.
- Predicted (from B04.md, before the run): R2 mean −2 to +6 dB, R2 RMS 20–26; R1, R3 move up to 2 dB; VA 0–2 dB worse; long-term level 19–24; composite 13.5–15.5; censored 30–45 % (likely rejection).
- Result: composite 11.46 dB (stock 16.02; R02 15.93; P.452 14.18; P.2001 13.97); screened 10.19; Phase 2 cell 14.22; long-term level 14.98; shape 5.17. Site RMS R1 10.2 (mean -1.5), R2 19.5 (mean -11.3), R3 6.4 (mean -1.0), VA 15.2 (mean -9.3). Censored 67.6 %. Paired gain over stock +4.57 dB (95 % +2.70 to +5.62), screened +3.21 (+1.82 to +4.17).
- Physics battery: PASS.
- Decision: reject (censored 67.6 % > 29.0 %; R2 mean error now −11.3 dB). On the Pareto front and its cell's elite: kept as `arc/401-delta-bullington-p452`.
- Predictions: direction right, size wrong. Composite predicted 13.5–15.5, got 11.5; long-term level predicted 19–24, got 15.0; censored predicted 30–45 %, got 67.6 %; R2 mean predicted −2 to +6, got −11.3.
- Planner analysis (key finding): 401 reproduces the ITU models' censored failure pattern almost exactly. Censored violations by site: R2 71 % (P.452 67 %, P.2001 68 %, stock ITM 7 %), VA 83 % (83, 82, 78), R1 23 % (23, 23, 14); 97 % of 401's violations are also P.2001 violations; median margin 12.9 dB. With B01's 104 result (single-edge Bullington alone kept censored at 29.4 %), this places the ITU models' optimism on R2's dead paths in the delta construction itself: the obstruction-adjusted smooth surface lifts the effective antenna heights and shrinks the smooth-earth loss.

### 402-delta-bullington-p526
- Date: 2026-11-21. Batch B04. Parent: 000-baseline (best). Tier 2.
- Change: `cfg.diffraction = "delta_bullington_p526";`
- Rationale: the Recommendation's own form, which lets a negative smooth-earth excess lower the obstruction loss.
- Predicted (from B04.md, before the run): loss at or below 401 everywhere; composite similar or slightly lower; censored 1–5 points above 401.
- Result: composite 11.52 dB (stock 16.02; R02 15.93; P.452 14.18; P.2001 13.97); screened 10.23; Phase 2 cell 14.29; long-term level 15.09; shape 5.17. Site RMS R1 10.3 (mean -1.6), R2 19.5 (mean -11.3), R3 6.5 (mean -1.1), VA 15.4 (mean -9.4). Censored 68.2 %. Paired gain over stock +4.51 dB (95 % +2.62 to +5.57), screened +3.17 (+1.78 to +4.10).
- Physics battery: PASS.
- Decision: reject (censored 68.2 %). Its cell's elite: kept as `arc/402-delta-bullington-p526`.
- Predictions: loss at or below 401 and censored 1–5 points higher held at the low end (+0.6 points); composite equal.

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
