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

### 711-nlcd-open-clutter
- Date: 2026-11-22. Batch B11. Parent: 707-cascaded-isolated-clutter-at-r. Tier 2.
- Change: 707's five settings plus `"terminal_clutter_open":"nlcd"`.
- Run settings (metrics.json cfg): diffraction=delta_cascaded_isolated, diffraction_bound=itm_troposcatter_line, terminal_clutter=p2108_height_gain, terminal_clutter_base=clutter_height, terminal_clutter_frange=hold3; overrides {"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3","terminal_clutter_open":"nlcd"}
- Predicted (from B11.md, before the run): R3 mean error rises by 5-7 dB and R3 RMS by more than 0.5 dB (fails the site gate); R1 RMS rises; VA RMS changes by less than 1 dB; composite worse than 707. Censored violations fall (more loss everywhere). Most likely: rejected. Falsifies H20/H21 as specified (pixel class with P.2108 section 3.1) if R3 and R1 worsen while VA barely moves.
- Result: composite 13.3 dB (707-cascaded-isolated-clutter-at-r 12.5); screened 10.7; Phase 2 cell 15.6; long-term level 19.1; shape 5.2. Site RMS R1 13.7 (mean +6.9), R2 19.8 (mean +7.2), R3 11.3 (mean +6.9), VA 12.9 (mean -1.9). Worst cell 28.5. Censored 16.9 %. Paired gain vs 707-cascaded-isolated-clutter-at-r -0.77 (95 % -1.10 to -0.48); screened -0.77 (-1.10 to -0.48).
- Physics battery: PASS.
- Censored by site:
  - R1    5.4 %  (15 of 280)   C 2/6, O 13/274
  - R2    7.5 %  (89 of 1184)   C 14/106, O 75/1078
  - VA   41.5 %  (241 of 581)   C 143/386, O 98/195
- By edge count:
  - edges 0-1: dead rows violated  68.3 % of   41; measured-row mean error   -3.4 dB
  - edges   2: dead rows violated  21.6 % of  204; measured-row mean error   +1.1 dB
  - edges   3: dead rows violated   0.0 % of  376; measured-row mean error  +17.2 dB
  - edges  4+: dead rows violated   3.0 % of  563; measured-row mean error  +18.0 dB
- Siting split (mean error, dB):
  - R1 A clear n 112 mean +8.0 rms 10.5
  - R1 A obstructed n 304 mean +0.7 rms 6.9
  - R1 C clear n 156 mean -2.0 rms 13.1
  - R1 C obstructed n 436 mean +8.1 rms 12.2 censored violated 2 of 6
  - R1 O clear n 1445 mean +1.2 rms 7.1
  - R1 O obstructed n 2036 mean +10.6 rms 16.5 censored violated 13 of 274
  - R2 C clear n 46 mean -26.8 rms 33.4
  - R2 C obstructed n 186 mean -15.9 rms 27.2 censored violated 14 of 106
  - R2 O clear n 355 mean -3.7 rms 24.0
  - R2 O obstructed n 1973 mean +8.8 rms 18.8 censored violated 75 of 1078
  - R3 O clear n 4005 mean +6.1 rms 10.9
  - R3 O obstructed n 1144 mean +9.3 rms 11.9
  - VA C clear n 241 mean -4.7 rms 12.5 censored violated 27 of 27
  - VA C obstructed n 709 mean +3.8 rms 13.1 censored violated 116 of 359
  - VA O clear n 810 mean -7.8 rms 15.1 censored violated 10 of 10
  - VA O obstructed n 802 mean +1.3 rms 11.3 censored violated 88 of 185
- Decision: reject (composite 0.77 dB worse than 707, 95 % -1.10 to -0.48; R3 RMS +4.5 dB fails the site gate; R1 RMS +3.2).
- Predictions: Held: R3 mean +0.4 to +6.9 (rise 5-7), R3 RMS +4.5 (site gate fails); R1 RMS rises (10.5 to 13.7); VA RMS within 1 dB (12.9 to 12.9); composite worse (12.5 to 13.3); censored falls (22.8 to 16.9 %). All held. Archived as `arc/711-nlcd-open-clutter` (Pareto front on censored).
### 712-nlcd-open-forest-only
- Date: 2026-11-22. Batch B11. Parent: 707-cascaded-isolated-clutter-at-r. Tier 2.
- Change: 707's five settings plus `"terminal_clutter_open":"nlcd_forest"` (added after 711; 37 tests pass).
- Run settings (metrics.json cfg): diffraction=delta_cascaded_isolated, diffraction_bound=itm_troposcatter_line, terminal_clutter=p2108_height_gain, terminal_clutter_base=clutter_height, terminal_clutter_frange=hold3; overrides {"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3","terminal_clutter_open":"nlcd_forest"}
- Predicted (from B11.md, before the run): R3 RMS within 0.5 dB of 707 (6.8); R1 RMS 11.8-12.8 and R2 RMS 19.0-19.6, both more than 0.5 dB worse than 707 (site gate fails); VA RMS within 0.5 dB of 12.9; Phase 2 cell 14.4-15.2; composite 12.8-13.1, worse than 707; censored 18-21 %. Most likely: rejected, which would leave no form of the NLCD point-class test that helps VA without hurting R1 or R2.
- Result: composite 12.9 dB (707-cascaded-isolated-clutter-at-r 12.5); screened 10.3; Phase 2 cell 14.4; long-term level 19.1; shape 5.2. Site RMS R1 13.2 (mean +5.9), R2 19.9 (mean +5.4), R3 6.7 (mean +0.7), VA 12.9 (mean -2.0). Worst cell 30.1. Censored 17.5 %. Paired gain vs 707-cascaded-isolated-clutter-at-r -0.38 (95 % -0.61 to -0.16); screened -0.38 (-0.61 to -0.16).
- Physics battery: PASS.
- Censored by site:
  - R1    5.4 %  (15 of 280)   C 2/6, O 13/274
  - R2    8.4 %  (99 of 1184)   C 14/106, O 85/1078
  - VA   42.0 %  (244 of 581)   C 143/386, O 101/195
- By edge count:
  - edges 0-1: dead rows violated  68.3 % of   41; measured-row mean error   -4.7 dB
  - edges   2: dead rows violated  23.5 % of  204; measured-row mean error   -2.0 dB
  - edges   3: dead rows violated   0.0 % of  376; measured-row mean error  +16.5 dB
  - edges  4+: dead rows violated   4.1 % of  563; measured-row mean error  +14.9 dB
- Siting split (mean error, dB):
  - R1 A clear n 112 mean +0.1 rms 5.0
  - R1 A obstructed n 304 mean -2.5 rms 6.2
  - R1 C clear n 156 mean -2.0 rms 13.1
  - R1 C obstructed n 436 mean +8.1 rms 12.2 censored violated 2 of 6
  - R1 O clear n 1445 mean +0.6 rms 6.9
  - R1 O obstructed n 2036 mean +9.7 rms 16.2 censored violated 13 of 274
  - R2 C clear n 46 mean -26.8 rms 33.4
  - R2 C obstructed n 186 mean -15.9 rms 27.2 censored violated 14 of 106
  - R2 O clear n 355 mean -6.3 rms 28.1
  - R2 O obstructed n 1973 mean +7.0 rms 18.5 censored violated 85 of 1078
  - R3 O clear n 4005 mean -1.0 rms 5.6
  - R3 O obstructed n 1144 mean +6.7 rms 9.0
  - VA C clear n 241 mean -4.7 rms 12.5 censored violated 27 of 27
  - VA C obstructed n 709 mean +3.8 rms 13.1 censored violated 116 of 359
  - VA O clear n 810 mean -8.0 rms 15.2 censored violated 10 of 10
  - VA O obstructed n 802 mean +1.2 rms 11.4 censored violated 91 of 185
- Decision: reject (composite 0.38 dB worse than 707, 95 % -0.61 to -0.16; R1 RMS +2.7 and R2 RMS +1.7 dB fail the site gate).
- Predictions: Held: R3 RMS within 0.5 dB (6.7); VA RMS within 0.5 dB (12.9); Phase 2 cell 14.4 (14.4-15.2); composite 12.9 (12.8-13.1), worse than 707; site gate fails. Missed: R1 RMS 13.2 (predicted 11.8-12.8, worse than predicted); R2 RMS 19.9 (19.0-19.6, worse); censored 17.5 % (18-21, lower). Archived as `arc/712-nlcd-open-forest-only` (Pareto front on censored).
### B11 worker summary
- Date: 2026-11-22. Runs 711 and 712, each through the parallel launcher with overrides, scored against 707. No errors, no infra events; runs 32 s each. Both pass the battery; the report-only height check shows 26.0 dB for both (inherited from the 604 base).
- **Neither is kept.** 711 (all NLCD classes): composite 13.3 dB, 0.77 worse than 707; R3 RMS 6.8 to 11.3 and R1 10.5 to 13.7 fail the site gate. 712 (forest only): composite 12.9, 0.38 worse; R3 holds (6.7) but R1 (13.2) and R2 (19.9) fail.
- **VA, the target, doesn't move**: RMS 12.9 in both; VA open clear mean error -7.8 and -8.0 dB against about -9 in 707. Terminal clutter at the pixel doesn't explain the VA open-path bias: most VA open receivers are at 12 m, close to the 15 m clutter height, where P.2108-1 section 3.1 adds little, while the low R1 and R2 mobile antennas (2 to 7 m) take 14-18 dB where they're flagged forest.
- R2's open clear bias drops (-17 to -3.7 and -6.3 dB), but almost all of it is on the two D04 data-problem paths (R2-005-T7, R2-020-T10).
- Conclusion for H20/H21: rejected as specified (NLCD point class with P.2108-1 section 3.1 at the mobile terminal), in both forms. What remains open for VA is clutter along the path rather than at the terminal (for example ITU-R P.833 vegetation over a path section), which needs land cover sampled along each profile; not planned until a source and an identifiable test exist.
- Records written with `record_run_rev1.py` (rows appended by the script; the worker added the prediction checks). The script now also accepts "Change (...)" lines.


### Lockbox prepared (2026-11-24)
- `best` rebuilt on main e76ca9d and frozen: commit 2baa02b, `params_exp.m` MD5 1a122bfbe9796e9ae9dee920c8962dff. Registration: `experiments/lockbox/LOCKBOX_REGISTRATION_rev1.md` (panel 707, stock ITM, R02, R03; metrics; predictions; known defects). Before Nick scores: three reviewers on the frozen model and one Fable read.
- Evaluator PR #11 (E2, report-only) opened; checked on 707 with a scratch run (composite unchanged; bounds RMS 12.09, violation depth 17.4 dB, 119 row-ends on 10 paths, 263 continuity steps).

### R03-delta-bullington-clutter-at-r
- Date: 2026-11-24. Batch B18. Parent: 707-cascaded-isolated-clutter-at-r. Tier 2.
- Change: `{"diffraction":"delta_bullington","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}`
- Run settings (metrics.json cfg): diffraction=delta_bullington, diffraction_bound=itm_troposcatter_line, terminal_clutter=p2108_height_gain, terminal_clutter_base=clutter_height, terminal_clutter_frange=hold3; overrides {"diffraction":"delta_bullington","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}
- Predicted (from B18.md, before the run): screened composite about 9.6; censored violations about 55 %.
- Result: composite 11.0 dB (707-cascaded-isolated-clutter-at-r 12.5); screened 9.6; Phase 2 cell 12.9; long-term level 15.0; shape 5.2. Site RMS R1 8.8 (mean +0.3), R2 17.9 (mean -10.0), R3 6.4 (mean -1.0), VA 13.5 (mean -6.9). Worst cell 28.6. Censored 58.0 %. Paired gain vs 707-cascaded-isolated-clutter-at-r +1.50 (95 % +0.42 to +2.03); screened +0.27 (-0.14 to +0.73).
- Physics battery: PASS.
- Censored by site:
  - R1   22.9 %  (64 of 280)   C 6/6, O 58/274
  - R2   65.9 %  (780 of 1184)   C 51/106, O 729/1078
  - VA   59.0 %  (343 of 581)   C 191/386, O 152/195
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of   41; measured-row mean error  -13.6 dB
  - edges   2: dead rows violated  49.0 % of  204; measured-row mean error  -12.9 dB
  - edges   3: dead rows violated  50.3 % of  376; measured-row mean error   -1.4 dB
  - edges  4+: dead rows violated  79.9 % of  563; measured-row mean error   -9.7 dB
- Siting split (mean error, dB):
  - R1 A clear n 112 mean -0.1 rms 4.9
  - R1 A obstructed n 304 mean -3.5 rms 6.9
  - R1 C clear n 156 mean -2.4 rms 13.1
  - R1 C obstructed n 436 mean +3.2 rms 9.7 censored violated 6 of 6
  - R1 O clear n 1445 mean -0.9 rms 5.8
  - R1 O obstructed n 2036 mean +0.9 rms 9.0 censored violated 58 of 274
  - R2 C clear n 46 mean -26.8 rms 33.4
  - R2 C obstructed n 186 mean -19.3 rms 27.0 censored violated 51 of 106
  - R2 O clear n 355 mean -17.0 rms 26.2
  - R2 O obstructed n 1973 mean -8.1 rms 16.2 censored violated 729 of 1078
  - R3 O clear n 4005 mean -1.6 rms 5.6
  - R3 O obstructed n 1144 mean +2.9 rms 7.7
  - VA C clear n 241 mean -6.2 rms 12.7 censored violated 27 of 27
  - VA C obstructed n 709 mean -2.4 rms 12.1 censored violated 164 of 359
  - VA O clear n 810 mean -9.5 rms 15.7 censored violated 10 of 10
  - VA O obstructed n 802 mean -6.0 rms 12.3 censored violated 142 of 185
- Decision: reference (lockbox comparator; not a keep candidate; censored 58.0 %).
- Predictions: Held: screened 9.6 (about 9.6). Missed: censored 58.0 % (about 55 %).

appended row R03 to results/results.tsv

### B18 worker summary (2026-11-24)
- One scored run (1804), rejected; six candidates out before scoring (B18.md). No keep. No infra retries.
- B18 ends without a keep. Per decision 4 (Nick, 2026-11-24), the lockbox comes next: freeze `best` (707), register the panel (707, stock ITM, R02, and a delta-Bullington comparator R03), metrics and predictions, then Nick scores it once.
- The one open finding for Nick: 1801 removes the principal-edge jump and is within 2 censored rows of the repair rule. The rule stands; it isn't kept.

### 1804-itm-effective-heights
- Date: 2026-11-24. Batch B18. Parent: 707-cascaded-isolated-clutter-at-r. Tier 2.
- Change: `{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3","smooth_heights":"itm_effective"}`
- Run settings (metrics.json cfg): diffraction=delta_cascaded_isolated, diffraction_bound=itm_troposcatter_line, terminal_clutter=p2108_height_gain, terminal_clutter_base=clutter_height, terminal_clutter_frange=hold3; overrides {"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3","smooth_heights":"itm_effective"}
- Predicted (from B18.md, before the run): composite gain −0.4 dB (screened interval −1.50 to +1.18, emulator mean −0.44); censored violations 21.7 %; site RMS intervals R1 8.3 to 13.9, R2 11.0 to 26.1, R3 5.6 to 8.0, VA 9.9 to 15.4. Most likely rejected on gain.
- Result: composite 13.4 dB (707-cascaded-isolated-clutter-at-r 12.5); screened 10.5; Phase 2 cell 14.5; long-term level 20.4; shape 5.2. Site RMS R1 11.6 (mean +5.2), R2 22.7 (mean +3.4), R3 7.0 (mean +0.4), VA 13.1 (mean -1.6). Worst cell 29.1. Censored 21.7 %. Paired gain vs 707-cascaded-isolated-clutter-at-r -0.88 (95 % -1.23 to -0.45); screened -0.59 (-0.94 to -0.30).
- Physics battery: PASS.
- Censored by site:
  - R1    5.7 %  (16 of 280)   C 2/6, O 14/274
  - R2   14.6 %  (173 of 1184)   C 14/106, O 159/1078
  - VA   43.7 %  (254 of 581)   C 129/386, O 125/195
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of   41; measured-row mean error  -12.7 dB
  - edges   2: dead rows violated  29.9 % of  204; measured-row mean error   -3.5 dB
  - edges   3: dead rows violated   4.3 % of  376; measured-row mean error  +22.6 dB
  - edges  4+: dead rows violated   9.8 % of  563; measured-row mean error  +11.3 dB
- Siting split (mean error, dB):
  - R1 A clear n 112 mean +0.1 rms 5.0
  - R1 A obstructed n 304 mean -1.3 rms 6.0
  - R1 C clear n 156 mean -2.0 rms 13.1
  - R1 C obstructed n 436 mean +8.7 rms 12.6 censored violated 2 of 6
  - R1 O clear n 1445 mean -0.6 rms 5.8
  - R1 O obstructed n 2036 mean +8.1 rms 13.4 censored violated 14 of 274
  - R2 C clear n 46 mean -26.8 rms 33.4
  - R2 C obstructed n 186 mean -14.4 rms 27.5 censored violated 14 of 106
  - R2 O clear n 355 mean -17.0 rms 26.1
  - R2 O obstructed n 1973 mean +4.4 rms 21.7 censored violated 159 of 1078
  - R3 O clear n 4005 mean -1.4 rms 5.7
  - R3 O obstructed n 1144 mean +6.9 rms 9.8
  - VA C clear n 241 mean -4.7 rms 12.5 censored violated 27 of 27
  - VA C obstructed n 709 mean +5.7 rms 13.8 censored violated 102 of 359
  - VA O clear n 810 mean -8.9 rms 15.6 censored violated 10 of 10
  - VA O obstructed n 802 mean +1.6 rms 10.9 censored violated 115 of 185
- Decision: reject (screened gain -0.59 dB, 95 % -0.94 to -0.30; R2 RMS +4.5 dB fails the site gate).
- Predictions: Held: composite gain negative (-0.88; screened -0.59, inside the screen's interval -1.50 to +1.18, near its mean -0.44); censored 21.7 % (21.7, exact recount); site RMS inside every interval (R1 11.6 in 8.3-13.9, R2 22.7 in 11.0-26.1, R3 7.0 in 5.6-8.0, VA 13.1 in 9.9-15.4); rejected on gain. Bonferroni k = 5 (99 % lower bound on the screened gain -1.02).
- Reading: ITM's effective heights in the delta construction help nowhere: R2 +4.5 dB RMS (open clear rows -17.0 dB mean), R1 +1.1. Effective height (M13) is closed in its parameter-free forms (1804 here, 1805 screened out).

appended row 1804 to results/results.tsv

### B18 model-only stage (2026-11-24; registered before any scored run)
- Planner and worker: Claude Opus 5.5, from Fable's draft (approved by Nick). Details: `experiments/batches/B18.md`.
- Code (default off; 47 tests; parity 6.8e-13 dB): `"p526_cascaded_isolated_one"`, `"_tree3"`, `"_rival"` (multi_edge), `cfg.smooth_heights`, `cfg.profile_clutter` (ITU-R P.1812-8 section 3.2.1 eq. (1d), Table 2, read from the ITU Word file), and report-only `info.edge_switch` (gap between the two largest nu, loss with the runner-up as principal). P.452-18 equation numbers in comments corrected to (147)-(153d), checked against the PDF.
- Results: 1801 (one secondary edge) removes the jump (R2-020 steps 30.6 to 0.5 dB; real-path height failures 119 row-ends on 10 paths to 29 on 3) but adds 22 violated censored rows, +1.08 points: 0.08 over the repair rule, so not scored. 1802 fails the battery; 1803 and 1807 create new height failures (30.7 dB on R2-080-T4); 1805 and 1806 CERTAIN_HARM. 1804 (ITM effective heights) is open and goes to scoring at k = 5 (screened interval -1.50 to +1.18, emulator mean -0.44; censored 21.7 %).
- Priors that missed: 1801's censored cost (prior +6 to +12 points; actual +1.08), 1802's continuity (prior 3-10 dB steps; actual under 0.5 on R2-020, but it fails elsewhere), 1803 as a repair (it isn't).

### Decisions from Nick after phase plan rev 3 (2026-11-24)
- "All approved": (1) the principal-edge jump stays in 707 through the lockbox, documented, with report-only fields in `info`; (2) run B18 as drafted, screen first; (3) open the report-only evaluator PR E2; (4) score the lockbox after B18, with a delta-Bullington comparator (R03) added to the panel and predictions registered first; (5) the censored gate stays as it is until after the lockbox; (6) hold the canopy-height data PR unless 1806 survives the screen.

### Phase plan rev 3 and B18 draft (planner note, 2026-11-24)
- Planner: Claude Fable 5.2. Plan only: no code, no runs. `experiments/proposals/phase_plan_rev3.md`, `experiments/batches/B18_draft.md`, tool `experiments/batches/hm_frontier_rev1.py` (hybrids, frontier and strata of stored runs).
- Repair of the principal-edge jump: no design meets all four terms. Published methods that are continuous by construction are Bullington (fails the censored gate, 55.0 %) or a coupled field over every ridge (counts ridge 172 on T1: an estimated +2 dB at 230 MHz to +16 dB at 9190 MHz over 707's lower branch; knife edges without an empirical correction are 17-22 dB optimistic on rows with 0-2 edges, runs 501 and 505). Two-edge cascades don't jump (identity checked numerically); the jump is the one-secondary-per-side rule on a third ridge.
- Stored-run hybrids: on Phase 2, replacing 707 by 703 (Bullington) or 708 (Deygout, no C) changes the composite by +0.17 and -0.20 dB; stock ITM on terrain-clear rows is 0.24 dB worse. Under the 36-link screen 703 is 0.31 dB and 502 is 0.72 dB better than 707 on the screened composite; both fail the censored share. With censored rows scored as bounds, 703 still leads 707 by 0.21 dB but VA is 0.7 dB worse.
- Lockbox-like strata: antennas at or under 3 m, 707 RMS 8-12 dB against stock 15-21 dB; at 76 MHz (VA, 452 rows) 707 +6.7 / 9.6 against stock -1.2 / 9.3.
- B18 draft: screen-first, six model-only candidates (1801 two-edge cascade, 1802 three-edge cascade, 1803 P.452-18 section 5.1.6.4 heights, 1804 ITM effective heights, 1805 structural heights, 1806 P.1812-7 clutter heights on the profile). Nothing scored unless the screen leaves it open. Effective height no longer leads.
- Recommended: lockbox right after B18, with the panel (707, stock, R02, plus a Bullington comparator R03), metrics and predictions registered first.
- Citation check: the code cites P.452-18 eq. (161)-(167) for the smooth surface; the P.452-18 Word file read today numbers them (147)-(153d), and section 5.1.6.4 is (154a)-(157). To confirm against the PDF and correct in comments.
- Rationale for B18, one sentence each: 1801/1802 bracket the count change that makes the jump; 1803 makes the smooth surface independent of the antennas; 1804/1805 test the two other height definitions; 1806 treats canopy as raised terrain.

### B16 stage 2 and B17 (2026-11-24; nothing scored)
- Planner and worker: Claude Opus 5.5. Nick asked for both ("Do both").
- B16 stage 2, principal-edge repair: three parameter-free selectors considered (most-loss decomposition, least-loss of two ridges, J-weighted blend). The first contradicts T1's detected rows (they sit on 707's lower branch); the second is degenerate (P.526-11's T shrinks secondaries under a weak principal); the third was prototyped on the B16a sweeps and still jumps 14-16 dB on T2. No candidate registered; prototype removed. Details in B16.md.
- B17, woodland along the path: `cfg.path_vegetation = "p833_eq1"` (P.833-10 §2.1 eq. (1), Table 1; NLCD along the profile from PR #10), default off. Tests 45/45, parity 6.8e-13 dB. Smoke: median +20 to +22 dB on R2 and VA open rows. History-matching screen: CERTAIN_HARM for 1701 (on 707) and 1702 (on 708); VA RMS rises at least 6.5 and 4.4 dB in the best case. Not run. Reason: eq. (1) is for a terminal inside woodland; open Phase 2 terminals need §3.1/§3.2 and canopy height, which NLCD classes don't give. Details in B17.md.
- Bonferroni count unchanged (no candidate scored; next against 707 is k = 5).
- Lockbox trigger: B16 and B17 both ended without a scored keep candidate. If they count as "two batches without a keep", the lockbox is due now. Nick's call.
- Decision (Nick, 2026-11-24): no lockbox for now. Next: a Fable planning session on the principal-edge repair and the phase ahead.

### B16: oracle, roughness audit, crest eligibility (2026-11-23; no scored run)
- Planner and worker: Claude Opus 5.5. Registered in `experiments/batches/B16.md` before the runs; results there.
- New functions (not wired into the model): `itm_variant/vogler_two_screen_rev1.m` (Vogler N = 2, NTIA TR-83-124) and `faddeeva_w_rev1.m` (Weideman 1994). Reproduce NTIA TR-26-580 Table 17 cases 21-25 to 0.001 dB; SciPy recomputation of the sweeps agrees to 2e-11 dB. 44 tests pass.
- B16a: on R2-020 T1 and T2 the coupled field over the two ridges 707 switches between changes by 0.02 dB across the switch, where 707 steps 15-31 dB. Coupled minus independent is the spacing term (under 0.6 dB). T1's detected rows show no step (measured contrast -5.1 to +2.8 dB; 707 predicts +11.6 to +23.9). The step is 707's edge selection. Next: register a repair with a continuous secondary-edge selector, gated on these sweeps.
- B16b: legacy delta h depends on sample spacing on trims under 242 intervals (81 of 515 paths; up to 11.7 m, 5.1 %); reversal and tilt invariant. Continuous form invariant, a few percent from legacy. No model change (fixed 30 m spacing; legacy calibration).
- B16c: 12 survey profiles at 5 sites pass the geometry rules, but no header documents vertical accuracy; under the most favorable map-accuracy reading only 2 profiles qualify. Diagnostic not run.
- Infra: first B16a launch stopped on the transmitter height (6.6 m below 910 MHz, 7.3 m above); fixed and rerun. First oracle run failed its own reversal check (0.065 dB at nu = -5): the edge order was ill-conditioned; the function now integrates over the more obstructing edge first, with a regression test.
- Lockbox trigger: B16 registered no keep candidate. Whether a diagnostic-only batch counts toward "two consecutive batches without a keep" is Nick's call; the planner's reading is that it doesn't.

### PRs #8, #9, #10 merged (Nick, 2026-11-23)
- From now on: the screened composite decides keeps and the full composite
  must do no harm; the paired interval is at 1 − 0.05/k (next candidate
  against 707: k = 5, 99 %); repair keeps are allowed for logged defects;
  lockbox after B18 or two empty batches. The battery reports pointwise
  continuity at 1/50/99 % (report-only). NLCD along Phase 2 profiles is a
  frozen input.
- `best` rebuilt on main b4a7f3c; Mac working copy synced (MD5 checked).
- Next: B16 (repairs: H01 oracle, roughness audit, crest eligibility count),
  then B17 (path vegetation).

### PRs opened after the phase plan (planner note, 2026-11-23)
- PR #8 (eval, report-only): pointwise continuity at 1/50/99 % and 99 % /
  99.5 % paired bounds. Scratch run: stock 0.00 dB; 707 has new steps where
  stock is smooth, 21.9 dB at 50 % (rough distance sweep, 12 km) and 23.2 dB
  at 1 % (40 km), hidden today by stock's 33 dB step elsewhere; D06a's
  tail-only steps (6.5 dB at 1 %) show up too.
- PR #9 (FRAMEWORK.md): screened composite decides with the full composite
  held to no harm; Bonferroni level; repair keeps; lockbox trigger.
- PR #10 (data): NLCD 2001 class at all 688,564 Phase 2 profile samples
  (forest share of samples: VA 60 %, R2 53 %, R1 18 %, R3 1.5 %). Infra: one
  unreadable MRLC response on the first build; the builder now retries.
- Nick's five reviewed experiments (`research_review_2026-11-23.md`, through
  e80ddfc) folded into the phase plan: H01 oracle (B16a), H04 roughness
  audit (B16b), H05 eligibility count (B16c); P.617 closed; H02 external.

### Decisions from Nick after the phase plan (2026-11-23)
- "Do what you recommend": B15 recorded as screened out by ceiling (not built).
- Protocol recommendations P1 (screened gate, full composite held to no harm),
  P2 (Bonferroni level), P3 (repair keeps), P4 (pointwise and tail continuity)
  and P7 (end of phase, lockbox trigger) go to Nick as PRs, because agents
  don't edit FRAMEWORK.md or eval/. Until they merge, the current rule applies.
- B17 input: data/ PR for NLCD along the Phase 2 profiles.

### B15 planned and ruled out by ceiling; phase plan rev 2 (planner note, 2026-11-23)
- Planner: Claude Fable 5.2. No code, no runs. `experiments/batches/B15.md`,
  `experiments/proposals/phase_plan_rev2.md`, tool `experiments/batches/hm_ceiling_rev1.py`.
- B15 design: 707's troposcatter bound applied at each time percentage, with
  the scatter component fading by P.617-6 eq. (6) above 50 % (1501), and the
  P.452-18 eq. (64) form as a rival (1502). Median unchanged in 1501; no
  region switch; step inventory and checks in B15.md.
- Ceiling: a perfect fix of every fading-side shape bias gains 0.07-0.10 dB
  (screened 0.11-0.12); both sides 0.14-0.21 (screened 0.36-0.48). 707 with
  D06a's fading side scores +0.12 (screened +0.01). Registered: both rejected
  on gain; recommended not to build. Time variability is closed as a score
  lever under the current rule.
- Cell-mean ceiling for everything: screened composite 9.91 to 8.78 if every
  cell mean were zero (Phase 2 0.37, level 0.41, shape 0.35). The rest is
  spread inside cells.
- Correction: B14.md and the D06 summary given to Nick said ITM predicts too
  little fading at 99 %. The sign was read backwards: ITM predicts too much fading
  beyond 100 km (shape error +1.1 to +4.0 dB by cell), and P.617-6's narrower
  spread helps at 100-300 km but is too narrow beyond 300 km above 1 GHz.
- Coupling loss checked and closed: the raw long-term file has antenna gains
  on 93 of 1,114 rows, 1 of the 548 scored rows.
- Protocol recommendations for Nick (phase plan): gate on the screened
  composite with the full composite held to no harm; Bonferroni level for
  the paired interval; a repair-keep class for logged physics defects;
  pointwise and tail continuity in the battery (report-only PR); an
  end-of-phase rule and lockbox trigger.

### D06 run: P.617-6 troposcatter distribution (diagnostic, 2026-11-23)
- PR #7 merged (a7ad22d): dN at path midpoints.
- D06a (time distribution, mode 3): composite 12.5, gain −0.01 dB; screened
  +0.22; LT shape 5.17 to 5.25. D06b (plus median): composite 12.0, gain
  +0.51 (95 % −0.09 to +0.75), screened −0.07; LT level 19.1 to 17.5.
  Phase 2, sites, censored unchanged. Not keep candidates (tail continuity).
- D06b's gain is in the 36 screened-out artifact links. D06a improves the
  fading side (99 % shape RMS 6.77 to 5.50 dB at 100-300 km) and worsens the
  enhancement side (1 % shape mean −1.5 to +4.6 dB), consistent with P.617-6
  §4 covering p > 50 % and §5 covering enhancements.
- Predictions: central estimates too pessimistic (effective ρ 0.39 and
  0.51, the highest yet on 707); both results inside the screen intervals.
- Next candidate (not registered): P.617-6 on the fading side only, combined
  with ITM's diffraction loss by power sum (P.452-18 eq. 64 style) so there's
  no region switch.

### B14 registered as diagnostic D06 (planner note, 2026-11-23)
- ITU-R P.617-6 §4.1 troposcatter time distribution (eqs. 1-7b, read from the
  rendered PDF) behind `cfg.time_variability = "p617" | "p617_transhorizon"`
  and `cfg.troposcatter = "p617"`, long-term rows only; 42 tests pass;
  smoke tests and screen in `experiments/batches/B14.md`.
- Needs dN at path midpoints: PR #7 (data), awaiting Nick.
- Physics finding: the tails step where the P.617 deviate starts to apply
  (4-5 dB above stock's largest step at ITM's troposcatter changeover; 1.5 dB
  at the horizon for the transhorizon form). The frozen battery checks 50 %
  only and passes. Registered as diagnostic, not keep candidates; proposed a
  report-only tail-continuity check for the battery.

### 1301-p452-troposcatter
- Date: 2026-11-23. Batch B13. Parent: 707-cascaded-isolated-clutter-at-r. Tier 2.
- Change: `{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3","troposcatter":"p452_45"}`
- Run settings (metrics.json cfg): diffraction=delta_cascaded_isolated, diffraction_bound=itm_troposcatter_line, terminal_clutter=p2108_height_gain, terminal_clutter_base=clutter_height, terminal_clutter_frange=hold3; overrides {"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3","troposcatter":"p452_45"}
- Predicted (from B13.md, before the run): - Composite 12.7 dB (gain −0.2), inside −0.93 to +0.64 dB; screened gain between −0.6 and +0.7 dB. - Long-term level 19.8 (range 17.6 to 21.5); shape 5.2, unchanged to within 0.01 dB. - Phase 2 cell 13.25 (range 12.8 to 13.6). - Site RMS: R1 between 9.0 and 11.7, most likely a small gain (its transhorizon rows lose 1.7-2.0 dB of predicted loss, and R1 is pessimistic, mean +4.1); R2 and R3 unchanged; VA between 12.5 and 13.3. - Censored violations 22.8 % ± 1.5 points: R1 and VA rows get less loss (more violations possible), R2 rows more loss (fewer). - Physics battery passes. - **Most likely: rejected,** on the composite gain (central estimate −0.23 dB). A keep needs the change to line up with 707's long-term error at ρ ≈ 0.64.
- Result: composite 12.8 dB (707-cascaded-isolated-clutter-at-r 12.5); screened 9.9; Phase 2 cell 13.2; long-term level 20.1; shape 5.2. Site RMS R1 10.2 (mean +3.7), R2 18.2 (mean -0.2), R3 6.8 (mean +0.4), VA 12.9 (mean -2.9). Worst cell 29.0. Censored 23.5 %. Paired gain vs 707-cascaded-isolated-clutter-at-r -0.30 (95 % -0.48 to -0.02); screened +0.04 (-0.08 to +0.15).
- Physics battery: PASS.
- Censored by site:
  - R1    5.7 %  (16 of 280)   C 2/6, O 14/274
  - R2   14.7 %  (174 of 1184)   C 14/106, O 160/1078
  - VA   50.1 %  (291 of 581)   C 143/386, O 148/195
- By edge count:
  - edges 0-1: dead rows violated 100.0 % of   41; measured-row mean error  -13.0 dB
  - edges   2: dead rows violated  29.9 % of  204; measured-row mean error   -4.9 dB
  - edges   3: dead rows violated   4.3 % of  376; measured-row mean error  +13.0 dB
  - edges  4+: dead rows violated   9.9 % of  563; measured-row mean error   +7.7 dB
- Siting split (mean error, dB):
  - R1 A clear n 112 mean +0.1 rms 5.0
  - R1 A obstructed n 304 mean -2.5 rms 6.2
  - R1 C clear n 156 mean -2.0 rms 13.1
  - R1 C obstructed n 436 mean +8.1 rms 12.2 censored violated 2 of 6
  - R1 O clear n 1445 mean -0.6 rms 5.8
  - R1 O obstructed n 2036 mean +5.7 rms 10.9 censored violated 14 of 274
  - R2 C clear n 46 mean -26.8 rms 33.4
  - R2 C obstructed n 186 mean -15.9 rms 27.2 censored violated 14 of 106
  - R2 O clear n 355 mean -17.0 rms 26.1
  - R2 O obstructed n 1973 mean +0.9 rms 16.6 censored violated 160 of 1078
  - R3 O clear n 4005 mean -1.4 rms 5.7
  - R3 O obstructed n 1144 mean +6.7 rms 9.0
  - VA C clear n 241 mean -4.7 rms 12.5 censored violated 27 of 27
  - VA C obstructed n 709 mean +3.9 rms 13.1 censored violated 116 of 359
  - VA O clear n 810 mean -8.9 rms 15.6 censored violated 10 of 10
  - VA O obstructed n 802 mean -0.4 rms 10.7 censored violated 138 of 185
- Decision: reject (composite gain -0.30 dB, 95% -0.48 to -0.02).
- Predictions (B13.md), held or missed:
  - Composite 12.7 (gain −0.2): missed by 0.1, actual 12.8 (−0.30), inside the screen interval −0.93 to +0.64.
  - Screened gain −0.6 to +0.7: held, +0.04.
  - Long-term level 19.8 (17.6 to 21.5): held within range, actual 20.1.
  - Shape unchanged: held, 5.2.
  - Phase 2 cell 13.25 (12.8 to 13.6): held, 13.2.
  - R1 small gain (9.0 to 11.7): held, 10.5 to 10.2.
  - R2, R3 unchanged: held. VA 12.5 to 13.3: held, 12.9.
  - Censored 22.8 % ± 1.5: held, 23.5 %.
  - Battery passes: held. Most likely rejected: held.
- Screen check: actual gain −0.30 inside −0.93 to +0.64; central estimate −0.23; effective ρ −0.10 (needed 0.64).
- Where the loss came from: the 36 screened-out long-term links (707 mean error +24.9 dB, RMS 36.4) get 2.4 dB more loss (RMS 38.7). On the other 512 links the 50 % RMS moves 9.37 to 9.48 dB and the mean −1.43 to −0.96 dB.
- What it tells us: swapping ITM's troposcatter attenuation for P.452-18 eq. (45) inside ITM's line structure doesn't line up with 707's long-term error. It adds about 1 dB of loss on troposcatter paths, where 707 is already roughly unbiased once the screened links are out. The headroom in the troposcatter class is spread, not level, so a different median isn't the lever; the time distribution and path-to-path spread are.

### B13 registered (planner note, 2026-11-23)
- 1301-p452-troposcatter: ITU-R P.452-18 eq. (45) as ITM's scatter
  attenuation on 707's base; plan, smoke test, screen and predictions in
  `experiments/batches/B13.md`. Screen: NOT_RULED_OUT (composite gain −0.93 to
  +0.64 dB, central −0.23, ρ needed 0.64). Battery passes. Predicted: most
  likely rejected.
- 707 rescored on the 36-link screen as `707r-rescore-screen36`: composite
  12.5 (unchanged), screened 9.9 dB (was 11.2 on the 14-link list); stock
  screened 11.9 (was 13.4). Use these when comparing screened figures with
  runs after PR #5. Not a results.tsv row: no model change.
- `params_exp.m` placeholder switches (`effective_height`,
  `effective_height_alpha`, `variability`) now stop with an error when set.
- Infra, 2026-11-22: batch queue stuck (jobs 198-200); working again on
  2026-11-23 (test job 201 finished).

### Tooling: history-matching screen, model floor, repo skills (2026-11-22)
- `experiments/batches/hm_screen_rev1.py` bounds the composite, screened
  and site changes of a candidate from its model-only deltas and the
  parent's per-cell residuals (method: `experiments/proposals/history_matching_rev1.md`).
  It reproduces 707's composite exactly (12.505 dB).
- Retrospective check on 36 past runs (`results/hm_screen_retro_rev1.tsv`):
  every actual gain is inside its interval; 4 runs come out CANNOT_PASS
  (501, 503, 602, 709) and all 4 were real rejections; no run that would
  have passed is screened out. B11 isn't ruled out by the bound (it failed
  by harm), but the central estimate predicted it: 711 −0.84 dB (actual
  −0.77), 712 −0.33 (actual −0.38).
- B12 screened from the smoke-test deltas: largest possible gain 0.128 dB
  (1201) and 0.008 dB (1202). Both can't pass. Nick approved on 2026-11-23:
  recorded as screened out, not run; H02 and H03 closed on this data.
- `experiments/batches/model_floor_rev1.py` writes `results/model_floor_rev1.csv`:
  the Bayes error of the fixed inputs, from the 21 long-term groups with
  identical inputs. It allows a composite as low as 0.33 dB, so it doesn't
  limit progress; Phase 2 has no identical-input rows.
- Four repo skills and the reviewer criteria are in `experiments/skills/`.

### B12 registered (planner note, 2026-11-22)
- 1201 (curved-Earth reflection phase, H02) and 1202 (two-leg time
  variability, H03); plan and predictions in `experiments/batches/B12.md`,
  commit 5d77508. Parity 6.8e-13 dB; 39 tests pass. Not run: the Mac batch
  queue stopped starting jobs (infra), and the screen above later showed
  neither can pass.

### PR #4 changed to report-only (2026-11-22)
- Nick's decision: the real-path height-gain check is report-only. It's recorded in metrics.json (`physics.checks.height_gain_real`: worst excess, row, 1 dB limit, `within_limit`) and printed in every run summary, but it doesn't affect the battery's pass. Reason: 707 fails it (27.0 dB, principal-edge switch) and every experiment built on 707 would inherit the failure; it becomes a gate once a multi-edge method without the jump exists (package H01).
- Re-checked from a scratch copy of the PR #6 branch (which includes PR #4): battery passes for stock (excess 0.0 dB), 707 (27.0 dB) and 711 (26.0 dB).
- Merge plan: PR #6 (contains #4) and PR #5. After merging, the worker pulls on the Mac, checks eval/ and data/ MD5s, rescores 000-baseline and 707 against the new screen, then runs B11.

### B11 planned (planner note): NLCD land cover, battery PR, screen PR
- Date: 2026-11-22. Planner: Claude Opus 5.5. Plan `experiments/batches/B11.md`, predictions registered before any scored run.
- PR #4 (eval/): real-path height-gain check relative to stock. Stock passes at 0 dB; 707 fails at 27.0 dB (principal-edge switch); every current delta form fails (Bullington 4.2 dB, from P.452 eq. (166)).
- PR #5 (data/): long-term screen adds a terminal-geometry rule (terminal horizon within 0.5 km above 50 mrad); 22 links on 14 paths added to the existing 14; recovers 7 of D01's 14 rows without the record's LOS flag; thresholds chosen after seeing three outliers (stated in the builder).
- PR #6 (data/ + eval/, built on PR #4): NLCD 2001 land cover at all 1,030 Phase 2 terminal rows via the MRLC WCS (builder `data/build_landcover_rev1.m`, about 2 minutes), and `cfg.row.path_id` for every row. Mobile-terminal forest within 100 m: R1 11 %, R2 48 %, R3 2 %, VA 32 %; developed: R1 11 %, R2 6 %, R3 39 %, VA 10 %. 143 of 515 mobile pixels changed cover since 1985.
- Variant: `cfg.terminal_clutter_open = "nlcd"` with `landcover_lookup_rev1.m`; 37 tests pass; parity 6.8e-13 dB. The planner had guessed R1 and R3 would barely change; the extraction shows R3 is largely developed, so the fixed mapping adds clutter there. Smoke test and logged site means predict 711 fails on R3 and R1.

### Research package added (2026-11-22)
- Nick's ITM research package (11 Markdown files: README, five research documents, proposals H01–H05) added unchanged under `experiments/proposals/itm_research_package_rev1/`, with a planner status note `STATUS_rev1.md` that marks what is out of date (written at B05: stock parent, 502 arithmetic, A_fo) and maps each item to work done. Planner's order for next batches: H02 and H03 in parallel, then H01 as an oracle against 707's cascade, then H05.

### Finding: principal-edge switch discontinuity in the kept model (707)
- Date: 2026-11-22. Model only. Found while prototyping the real-path height-gain battery check Nick approved.
- Prototype (scratch, not in eval/): on all 16,805 Phase 2 rows, raise each antenna by 10 m; record the change in loss for 707 and for stock ITM. Stock adds more than 1 dB on 6,799 row-ends (max 25.4 dB): two-ray interference in line of sight makes "loss must not rise with height" invalid on real paths, so the check has to be relative to stock. Relative to stock, 707 adds more than 2 dB beyond stock's change (and more than 1 dB) on 102 row-ends on 8 paths, 75 % of them on P2_R2_R2-020-T1_O and -T2_O; worst variant-minus-stock 51.7 dB.
- Cause, on P2_R2_R2-020-T2_O at 9.19 GHz (20.1 km, terrain 126 m above the antenna line): raising the receiver from 18.5 to 21 m switches the P.526-11 section 4.4.2 principal edge from the ridge near the receiver (point 668, nu 15.6) to a mid-path ridge (point 289, nu 14.2). Before the switch the method counts one secondary edge per side and never sees point 289; after it, both neighbours count at full isolation weight. L_ba jumps from 83.1 to 112.6 dB for a 2.5 m change. This is the three-edge cascade as written, not a coding error, and it is not physical.
- Why the battery misses it: the synthetic height sweep has one ridge; the rough distance sweep tolerates large steps because stock ITM itself steps 33 dB there (707: 32.5 dB).
- Consequence: a real-path height check relative to stock would fail 707. The eval/ PR states this so Nick can decide what it means for the keep.

### Decisions from Nick after B10 (2026-11-22)
- Land cover: add a public land-cover input (USGS NLCD) for a terminal clutter test on open paths (VA). Input change approved; it goes in as a data/ PR for Nick to merge, with source, edition, and build script recorded.
- Censored gate: stays overall. Every run reports censored violations by site (b08_censored_by_site_rev1.py); no per-site gate.
- Battery: open an eval/ PR adding a height-gain check on real paths (catches the P.452 eq. (166) inversion that the synthetic ridge misses).
- Long-term screen: propose a data/ PR adding a terminal-geometry rule (terminal horizon within 0.5 km at more than 50 mrad) to data/links/longterm_screen_rev1.csv.

### B10 planner note: long-term level and shape (D05); no model change
- Date: 2026-11-22. Planner and worker: Claude Opus 5.5. Research plan H12 and H19. No scored run.
- Diagnostic `experiments/D05-longterm/` on 707 (summary.txt has the tables). 707's long-term level score (19.1, cell-balanced) comes from the small >= 1.5 GHz cells, and those from a few links: three paths carry 68-75 % of each cell's squared error. Most already sit in the long-term screen ("record LOS; 30 m profile blocked"); the large unscreened ones (LT2241, LT2246, LT2233) have the terminal tens of metres below a ridge 90-450 m away in the profile, a coordinates-versus-terrain artifact at mountaintop relay sites.
- H12: no transition bias once those links are set aside. H19: ITM's time spread is too narrow below 100 km and too wide beyond 300 km at 1 %; every published reference model is worse on shape, so there is no sourced replacement.
- Decision: no B10 experiment. The remaining long-term gains need data decisions (a screen rule for terminal-geometry artifacts: data/, Nick) or a sourced variability model (none found).

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

## 2026-11-24: pre-lockbox review; registration rev 2

- PR #11 (E2, report-only) merged by Nick's approval (aff00bf). Guard flagged
  only the expected protected-path changes.
- Three independent reviewer sessions and one Fable read on `best` 2baa02b.
  No blocker in the model code. Findings two or more reported all concern
  the registration text, so the model stays frozen.
- [Registration rev 2](lockbox/LOCKBOX_REGISTRATION_rev2.md) replaces rev 1:
  - It states that the lockbox tests 707's diffraction and bound (the 604
    configuration, verified identical on all non-C rows), not its clutter term.
  - Run commits and settings per model (R02 from e76ca9d), and `cfg.row`
    conditions.
  - It adds a proposed primary endpoint and decision rule, for Nick to confirm.
  - Low-antenna evidence recomputed on open rows: pooled 14.3 to 10.1 dB,
    mostly from R2.
  - The VHF prediction is replaced: long-term rows below 100 MHz favour 707
    (RMS 8.3 against 11.3).
  - Five known defects added; the whole `itm_variant/` tree is pinned.
- Next: Nick confirms rev 2 sections 4 and 5, then scores once.

## 2026-11-24: rev 2 confirmed; lockbox scorer ready

- Nick confirmed registration rev 2 sections 4 and 5 as written, and that
  the 1801 ruling stands.
- [score_lockbox_rev1.m](lockbox/score_lockbox_rev1.m) runs one panel model per
  call. It checks the commit and the overrides, and forces `cfg.row.set` to empty.
- [summarize_lockbox_rev1.py](lockbox/summarize_lockbox_rev1.py) applies
  section 4's rule.
- Dry run on 400 development rows without clutter (`TestOnly`):
  - 707 matched its stored predictions to 0.0 dB.
  - R02 matched stock ITM to 1e-12 dB.
- The dry run showed that section 4 would call a larger-than-predicted win
  inconclusive. Nick amended the rule before any lockbox number: the
  direction of the interval decides, and the predicted range is reported as
  a calibration check.
- Clean clones for scoring made on the Mac: `ITM_lockbox_best` (2baa02b) and
  `ITM_lockbox_r02` (e76ca9d).
- [LOCKBOX_RUN_rev1.md](lockbox/LOCKBOX_RUN_rev1.md) has the steps.
- Next: Nick scores the panel and records the result.

## 2026-11-24: B19 registered (P.452-18 troposcatter bound at the path)

- One candidate, 1901. It replaces 707's unsourced troposcatter-line bound
  with P.452-18 eq. (45) evaluated at each path's own d and θ, at 100 MHz
  and above.
- Code, test (48 of 48 pass), smoke test and screen are done.
- Screen verdict: NOT_RULED_OUT. Composite −0.92 to +0.64 dB, emulator mean
  −0.23; passing needs ρ 0.64.
- Censored recount: 23.5 % (+0.7 points), within the limit.
- Predictions are in [B19.md](batches/B19.md), pushed before any score.
- `best` and the lockbox registration stay frozen.

## 2026-11-24: B19 closed without a keep (1901 rejected)

- Screened gain +0.04 dB (95 % −0.08 to +0.15), composite −0.29 dB.
  Censored violations 23.5 %; battery PASS. 8 of 9 predictions held.
- Found after the run: 1901 is identical to 1301 on every Phase 2 row.
  P.452-18 eq. (45) attenuation is linear in d, so the extrapolated line was
  exact. The extrapolation was never the issue.
- Defect 3's height-gain flattening remains in 707, 1301 and 1901 (ridge
  sweep +0.17 dB against stock's −23.3). It's a property of any scatter cap
  at short transhorizon distances; recorded for the next phase.
- `best` (707) and the lockbox registration are unchanged. Bonferroni count
  against 707 is now k = 6.

## 2026-11-24: next phase planned (phase plan rev 4, B20 draft)

- Planned by Opus 5.5 (the prompt asked for Fable). Plan only.
- [Phase plan rev 4](proposals/phase_plan_rev4.md) aims to make every part
  of 707 defensible without losing score.
- **Proposed correction to registration rev 2, defect 3** (pending Nick,
  decision 1): the height-gain flattening isn't caused by the troposcatter
  bound.
  - The ridge sweep is +0.17 to +0.19 dB in all 15 runs that report it,
    across three diffraction methods and two bounds.
  - Only 1804 (different smooth-surface heights) restores it (−18.1 dB).
  - 1901's bound doesn't bind on that sweep.
  - The P.452-18 obstruction-adjusted smooth surface is the leading suspect.
    The registration stays frozen.
- [B20](batches/B20.md): three diagnostics, no scored runs:
  - D20a: which term flattens height gain.
  - D20b: whether the cascade correction C drives the obstructed-row
    overshoot.
  - D20c: whether P.2108-1 beats a constant on 1,400 matched open and
    concealed pairs.
- Bonferroni k doesn't reset; the next scored candidate against 707 is k = 7.

## 2026-11-24: phase plan rev 4 decisions (Nick: "Do all the things you recommend")

1. **Correction to registration rev 2, defect 3, recorded here.** The
   registration file itself stays frozen.
   - The height-gain flattening (ridge sweep +0.17 dB against stock's
     −23.3) isn't caused by the troposcatter bound.
   - It's flat in all 15 runs that report it, across three diffraction
     methods and two bounds. 1901's bound doesn't bind on that sweep.
   - Only 1804, which changed the smooth-surface heights, restores it
     (−18.1 dB).
   - The leading suspect is the P.452-18 obstruction-adjusted smooth
     surface. D20a tests it.
   - Defect 3 otherwise stands: the bound has no published source.
2. **Censored gate:** unchanged until Nick has scored the lockbox; decide
   then.
3. **Per-site censored reporting:** approved as an evaluator PR, report-only.
4. **Repair rule, height-gain defect only:** the report-only real-path
   height check (`height_gain_real`; 707: 27.0 dB over its 1 dB limit)
   counts as the battery check that shows best failing. Fixed before B21.
5. **B20 approved** and promoted from draft.

## 2026-11-24: B20 closed (three diagnostics, no scored runs)

- **D20a:** the height-gain flattening comes from the P.452-18
  obstruction-adjusted smooth surface. It puts low antennas tens of metres
  above it (65 m on the ridge sweep), which clips the smooth-earth term to
  zero and leaves the knife-edge loss alone. The bound never binds. Any
  other surface restores 78 % of stock's height gain. The R1 inversion is a
  separate mechanism: A_s two-ray lobing on the smooth path.
- **D20b:** the error rises with the cascade correction C·T below 1 GHz, but
  C·T is only 6 to 22 % of the loss, so the rule says C isn't the driver.
  Clear rows get near free-space loss and are optimistic, more so with
  frequency.
- **D20c:** P.2108-1 is supported on 1,165 paired concealed-minus-open
  differences: it beats a refitted constant at R1 and VA, and the frequency
  slope matches (+9.4 against +10.1 dB per decade). It overpredicts by
  2.7 dB on average and loses at R2.
- Report-only code: `info.delta_parts` and the cascade terms. 707
  reproduced to 1e-9 dB on every row.
- **B21:** one smooth-surface candidate (phase plan R1), to be registered
  after the planner checks its source.
- PR #12 (per-site censored reporting) is open; merging it needs Nick.

## 2026-11-24: correction to D20c's interpretation

- ChatGPT's post-B20 review (N05, `proposals/post_b20_ten_experiments_rev1.md`)
  found an error in D20c, confirmed in the code.
- With `terminal_clutter_base = "clutter_height"`, a concealed terminal's
  whole path runs with the antenna at max(h, R) before the P.2108-1 term
  A_h is added. So 707's concealed-minus-open difference is a height change
  plus A_h, not "the clutter term alone".
- D20c's script said the other terms were checked as identical; that check
  was never run, and the claim was wrong.
- D20c's numbers stand. They support 707's full concealed-terminal treatment,
  not A_h in isolation.
- B20.md and the script docstring are corrected. D23b (B23, not yet
  approved) separates the two parts.

## 2026-11-24: B23 executed (Package A diagnostics, no scored runs)

- Nick approved B23 ("Run b23"). Development data only; 0 scored, 0 kept;
  no model, evaluator or data change; no lockbox data.
- **Checks:** all section 8 self-tests pass. The raw archive reproduces all
  16,805 frozen rows exactly. 707 reproduces on every row to 5e-13 dB, info
  on/off is identical, the stock baseline matches, and N_s matches the core.
  The D20c arithmetic replays exactly. The factorial closes to 1e-9 dB.
- **Provenance:** only R1 is strict (horizontal polarization and calibration
  documented in its report). R2, R3 and VA are limited. The R1 report
  estimates up to about 2 dB of unlogged open/concealed impedance change.
- **D23a (height):** INCONCLUSIVE on the registered precision rule. 707
  underestimates the measured loss reduction from raising the fixed antenna
  on obstructed open paths: R1 +5.6 dB [+3.8, +7.5], R2 +3.1 [+0.6, +5.7],
  R3 +1.7 [+0.2, +2.8] (R2 and R3 exploratory). No interval is narrower
  than the 1 dB half-width rule.
- **D23b (clutter):** the C/O difference is not the P.2108-1 term alone. On
  1,400 twin pairs: geometry g -2.3 dB, additive +14.8, interaction 0.0,
  baseline mismatch +2.0 (twins are different terminals), total +14.5.
  |g| >= 1 dB on 870 rows. Predictive support is INCONCLUSIVE: strict R1
  has 7 bases; exploratory VA beats a refitted constant by 6.4 dB but not
  zero.
- **D23c (frequency):** INCONCLUSIVE on precision. T = +3.9 dB at R1
  [+0.8, +7.3] and +4.6 at VA, near zero at R3; no frequency term fitted.
- Details and the handoff table: `experiments/batches/B23.md` Results.
  Self-run checks only; no independent reviewer ran. Results that leave the
  repo need Nick's read first.
- **Next:** B21 (smooth-surface candidate) stays next. D23a is directional
  evidence to weigh when judging it, not a repair gate.

## B21: smooth-surface candidate (closed, no candidate)

- No scored run; k stays 6. The next scored candidate against 707 is k = 7.
- Checked the phase plan's open item against the public texts. ITU-R
  P.1812-8 Attachment 1 eq. (88c)-(88f) and ITU-R P.2001-5 eq. (35d)-(35f)
  apply the same obstruction adjustment as P.452-18 eq. (153), which 707
  uses. Dropping it is 1803; replacing the surface with ITM heights is
  1804. Both are closed.
- No public source offers a third construction, so R1 stays on hold. Text
  extraction of both PDFs was garbled in places; equation numbers come from
  a reading of the text.
- Details: `experiments/batches/B21.md`.
- **Next (needs Nick):** hold R1, and run one diagnostic on R4 (line-of-sight
  A_s) or register R2 before the next candidate.

## B24: registered B23 sensitivities (diagnostic, 0 scored)

- Clearance >= 0.6 cuts D23c R1 from +3.94 to +1.25 dB (11 bases, NULL); VA +4.61 to +2.79.
- VA across 7 fixed terminals: +3.06 to +5.68; bootstrap over terminals [0.96, 9.95].
- A 2 dB calibration error would remove the D23c R1 lower bound; the note is documented for R1 C/O only.
- Censored pairs don't reverse the D23a direction. All dispositions unchanged or weaker.
- Details: `experiments/batches/B24.md`, `experiments/D24-sensitivities/`.

## Phase status after B24 (no run)

- The phase plan rev 4 candidate queue is empty under its own registered rules:
  R1 has no sourced construction (B21); R2 and R4 failed their B20 rule-out tests
  (C is 6 to 22 % of A_ref; clear-row |A_s - L_bs| is about 0 dB); R3 is done (D20c,
  D23b); R6 is merged as PR #12 (report only).
- B22 (repairs) is the phase's closing batch. Its only live item, the 1801 re-score,
  waits on decision 2 (censored gate), which waits on Nick scoring the lockbox.
- No agent action can move the phase until the lockbox is scored. k stays 6.
- Mac checkout: at f5bb3bf with 19 uncommitted local changes, including
  `eval/run_eval_rev1.m` and `eval/score_rev1.m`, which PR #12 also changes. Not
  pulled; Nick resolves those before the next scored run.

## B25: spherical-earth reference in the delta construction (N02; 0 scored)

- Replacing 707's smooth-path A_s with ITU-R P.452-18 §4.2.2 L_dsph (option
  `smooth_reference = "p452_spherical"`, off by default) moves 1.7 % of Phase 2 rows by
  more than 1 dB. The screen says CANNOT_PASS (screened gain at most +0.11 dB). Closed.
- Finding, on one row (R1-005-T5_O, 230 MHz, transmitter 1 to 30 m): the inversion is not ITM
  two-ray lobing, as B20 D20a said; L_dsph rises the same way. The receiver's height above the
  obstruction-adjusted surface falls from 4.59 m to its 1 m floor as the transmitter rises, which
  fits the trend but not each step. Other rows are untested.
- Kernel transcription matches the oracle-tested P.452 port to 1.8e-14 dB; 707 parity holds;
  two fresh reviewers, findings applied. Details: `experiments/batches/B25.md`, `experiments/D25-spherical-reference/`.

## B26: N07 and N01 disposition (planner note, 0 scored)

- N01 closed for its primary target (one row, R1-005-T5_O 230 MHz): B25's no-reflection
  kernel rises the same way, so a reflection ablation can't remove that rise. Other named
  rows are parked, untested. N07 is parked with it.
- Post-B20 plan Packages A and B are finished; C can't yield a candidate; D is parked; E needs
  approval. Next: phase plan rev 5. Details: `experiments/batches/B26.md`.

## Phase plan rev 5 and B27 registered (planner note; no run)

- Planner: Claude Fable 5.2. [Phase plan rev 5](proposals/phase_plan_rev5.md): stop the scored
  gain search on the frozen inputs. Basis: five rejected candidates against 707 in
  `results.tsv` (all scored rows); no keep or repair in B18 and B19; an empty rev 4 queue;
  a cell-mean ceiling of 1.13 dB screened (all scored rows).
- One mechanism meets the bars, with a low prior: the height-gain terms of NBS TN 101 vol. 1
  section 7.2, eq. (7.5) to (7.6b). Its closed form for G isn't read yet (TODO).
- [B27](batches/B27.md) registered, not run: D27a tests whether 707 and stock ITM bracket the
  measured height contrast (population: R1 open blocked-blocked detected height pairs). The
  script ran on synthetic pairs only. k stays 6.
- One fresh reviewer checked claims, the citation and the rule; ten findings applied.
- For Nick: accept the stop; decide on Tier 1 calibration of 707's constants after the lockbox.

## B27: height-contrast bracket (D27a; 0 scored)

- Population: R1 open blocked-blocked detected height pairs, 149 pairs, 29 bases, one fixed receiver.
- e_707 +5.64 [+3.81, +7.49]; e_stock +10.43 [+8.96, +12.12]; bracket share 0.10.
- Blend ceiling 0.00 dB at w = 0.00 (in sample, optimistic; not a model; can't go below zero by construction).
- Outcome C: the equal-base signed errors have the same sign; hand back to the planner (section 4). k stays 6.
- Check 6 (fresh reviewer) reproduced the deciding cell and outcome C from the pair table; reporting fixes applied. M1 stays closed.
- Details: `experiments/batches/B27.md`, `experiments/D27-height-bracket/`.

## B28 registered: Tier 1 calibration of 707's constants (planner note; not run)

- Nick, 2026-11-25: "Ignore the lockbox all together. Just keep going." The lockbox gate on roadmap phase 3 is removed; the censored gate is unchanged.
- Three constrained cross-validated calibrations of 707 (eval/cv_calibrate_rev1, as R02), one constant group each: 2801 diffraction weighting (w_const, knife_scale, afo_scale; k = 7), 2802 line-of-sight blend (los_w_scale; k = 8), 2803 time spread (time_minus_scale, time_plus_scale; k = 9). Decided on screened `lo995` against 707r-rescore-screen36, plus the complexity cost of 0.5 dB per new parameter.
- Rationale, one sentence each: 707 replaced the knife-edge term the diffraction weights were fitted for; 707 changed what the line-of-sight blend joins; 707 changed the median the time spreads sit on.
- Predictions: no keep (2801 75 %, 2802 90 %, 2803 90 %). Details: `experiments/batches/B28.md`.

## B28 blocked: cv_calibrate constraint loop breaks on a report-only battery field (no score)

- Mac evaluator files synced to `main` (they were older committed versions; no local edits). Parity run `2800-707-parity`: +0.00 dB paired gain against 707r-rescore-screen36 on both composites.
- 2801 to 2803 stopped in fold 1 with `itmexp:infeasible`. Cause: `continuity_pointwise` (report-only, added in 2f0692b on 2026-11-23) matches the constraint loop's `continuity_` prefix but has no `variant_max_step_db`, so every trial throws. Not a model result; k stays 6.
- Fix proposed by PR (skip `report_only` checks in the constraint); waits for Nick, since `eval/` is frozen.
- PR #14 merged (afe4b23); reruns 2801 to 2803 (jobs 263 to 265) still stopped in fold 1. Second cause: `cv_calibrate_rev1`'s `predict` never passed `cfg.row`, which 707's terminal clutter requires, so every trial threw. Fix proposed in PR #15; a scratch copy with it gave feasible fold-1 trials (training composite 12.41 dB). Still no score; k stays 6.

## B28 closed: constrained calibration can't fit 707 (0 scored)

- After PR #15 (fb78249), jobs 269 to 271 fitted folds 1 to 3, then stopped in fold 4 with `itmexp:infeasible`. Cause: the harness constraint holds training-fold censored violations to stock ITM + 1 point. With VA held out, the training censored rows are R1 and R2, where 707 is 12.98 % against stock's 8.06 % (limit 9.06 %), even at ITM's constants. The excess is at R2. Population: training-fold censored Phase 2 rows (`experiments/B28-calibration-attempt/fold_censored_rev1.csv`).
- Folds 1 to 3, training rows only (not held out): 2801 and 2802 match each other in every fold (12.41, 11.05, 13.15 dB), inferred equal to ITM's constants; 2803 is 0.09 to 0.20 dB lower. No held-out predictions were written; k stays 6.
- A rerun would need the constraint to reference the parent's own training rate + 1 point (FRAMEWORK.md acceptance rule) instead of stock ITM, a frozen `eval/` change for Nick. The planner expects no keep even then.
- Fresh reviewer: all numbers reproduced; nine wording, scope and "Not done" findings applied.

## Pre-launch checks (PR #16, open)

- Nick approved three changes from the B28 lessons. PR #16 adds `Smoke=true` to `eval/cv_calibrate_rev1.m` (one constrained trial per fold at the base constants, no search, no files), `eval/tests/test_cv_calibrate_smoke_rev1.m`, and three `program.md` rules (smoke check before a constrained calibration, one short trial before any long batch job, smoke test after any `eval/` change). The loop-graph-workflow skill edit was shown on a review card.
- Test on 707r-rescore-screen36 passed (148 s, no files written): folds 1 to 3 and 5 feasible, fold 4 censored margin +3.92. This confirms B28's inferred fold 2 and 3 values at ITM's constants.
