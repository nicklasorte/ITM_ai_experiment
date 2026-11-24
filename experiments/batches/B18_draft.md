# Batch B18 (draft): screen-first sweep of the parameter-free families left

Planner: Claude Fable 5.2, 2026-11-24. **Draft registration: no code, no
smoke test, no run yet.** Parent: `best` (707). Plan and evidence:
`experiments/proposals/phase_plan_rev3.md`.

This draft becomes the registration (`B18.md`) when Nick approves it and the
steps under "Before the runs" are done. The planner's predictions below are
priors. The smoke test and the screen replace them with numbers before any
scored run, and the batch is committed and pushed again at that point.

## Purpose

Three parameter-free families remain after B17, plus the repair of the
principal-edge jump. This batch takes six candidates through the model-only
smoke test and the history-matching screen. Only a candidate the screen
leaves open is scored. The Bonferroni count stays at k = 5 until then.

## Ceilings (itm-register-batch step 3)

From `python3 experiments/batches/hm_ceiling_rev1.py parts`, for 707:

- Screened composite 9.91 to 8.78 dB if every cell mean were zero: Phase 2
  0.37, long-term level 0.41, long-term shape 0.35.
- Every B18 candidate acts on Phase 2 rows and, for B18a and B18b, on
  long-term rows. A keep on gain needs path-specific information that cuts
  the spread inside cells: the profile's edges (B18a), the profile's fitted
  surface (B18b), the land cover along the profile (B18c).
- Hybrids of stored runs (`hm_frontier_rev1.py hybrid`) bound what a
  different diffraction family can do on Phase 2: +0.17 dB at most. So B18a
  is registered as a repair, not as a gain candidate.

## Candidates

Each candidate is 707's five settings plus one switch. Names and values are
proposals; defaults keep 707's behavior.

### B18a: repair bracket for the principal-edge jump

The defect (LOG, 2026-11-22): the ITU-R P.526-11 §4.4.2 cascade counts two
edges or three depending on which ridge is principal. The two candidates
remove the count change from each side.

**1801, at most two edges.**

- Change: `"diffraction":"delta_cascaded_isolated_one"`. New method
  `"p526_cascaded_isolated_one"`: L = J_p + T (max(L_t, L_r) + C), with
  J_p, T, C and the isolation-weighted secondary losses L_t and L_r exactly
  as in `"p526_cascaded_isolated"` (P.526-11 eq. (50a), (51), (52); P.526-16
  §2.5 for the weights).
- Source: P.526-11 §4.4.2, restricted to one secondary edge. The restriction
  is a design choice with no new constant; the Recommendation counts one on
  each side.
- Rationale: with one secondary edge in total, the loss is the same whichever
  of two tied ridges is principal (phase plan, section 1), so the step
  shrinks to the difference between two secondary losses.
- Predicted (planner's prior):
  - B16a sweeps at 9190 MHz: change across the logged switch 0.4 dB on T1
    and 0.2 dB on T2 (from 707's stored edge parameters); largest change
    per 0.05 m under 1 dB at every frequency.
  - Loss falls on rows where 707 counts three edges. Phase 2 composite +0.0
    to +0.2 dB; long-term screened +0.1 to +0.3 dB.
  - Censored violations rise by 6 to 12 points (22.8 % to 29 to 35 %),
    because R2's dead rows with three or more edges are held by the third
    edge. This fails the repair rule.
- Confidence: medium on continuity, medium on the censored direction, low on
  its size.

**1802, three edges whenever three exist.**

- Change: `"diffraction":"delta_cascaded_isolated_tree3"`. New method
  `"p526_cascaded_isolated_tree3"`: the principal edge, the strongest
  secondary edge on either side (largest w J), then the strongest remaining
  candidate among the other side and the two sub-paths the first secondary
  edge creates (the same rule applied once more). L = J_p + T (L_2 + L_3 + C).
- Source: P.526-11 §4.4.2 with Deygout's recursion (IEEE Trans. Antennas
  Propag. 14(4), 1966) to a depth of two on one side. Design choice, no new
  constant.
- Rationale: the upper bracket. If three ridges exist, three are counted at
  every antenna height.
- Predicted (planner's prior): steps of 3 to 10 dB remain where the order of
  two secondary edges changes; T1's rows under 8.85 m gain 15 to 30 dB; R2
  RMS rises by more than 0.5 dB (CERTAIN_HARM); censored violations fall.
- Confidence: medium.

### B18b: heights above the smooth surface in the delta construction

Today the smooth reference path uses ITU-R P.452-18 Attachment 2 §5.1.6.3
(the obstruction-adjusted surface; eq. (151a)-(153d) in the Word file read
on 2026-11-24, cited as (165)-(167) in the code: confirm and correct the
comments). New switch `cfg.smooth_heights`, default `"p452_diffraction"`.

**1803, P.452's antenna-independent surface.**

- Change: `"smooth_heights":"p452_ducting"`. h_st = min(h_st, h_0),
  h_sr = min(h_sr, h_n), with h_st and h_sr from the least-squares fit;
  heights above the surface h_te = h_tg + h_0 − h_st, h_re likewise.
- Source: ITU-R P.452-18 Attachment 2 §5.1.6.2 eq. (146)-(150) and §5.1.6.4
  eq. (154a), (154b), (156). The Recommendation uses these heights for its
  ducting model, not for diffraction (§4.2.3 uses §5.1.6.3), so this is a
  departure the reviewers must rule on.
- Rationale: the surface no longer depends on the antenna heights, so
  raising one antenna can't lower the other's height above it. That's the
  logged height-inversion defect (LOG, 2026-11-21: up to 4.5 dB on 20 rows).
- Registered as a repair candidate. Identical to 707 on rows where no
  terrain rises above the direct ray (the adjustment is inactive there).
- Predicted (planner's prior): the 20 logged inversion rows no longer invert;
  changes confined to obstructed rows, mostly under 3 dB; screen: gain
  CANNOT_PASS, harm not certain; censored within 1 point.
- Confidence: medium.

**1804, ITM's effective heights.**

- Change: `"smooth_heights":"itm_effective"`. The smooth path's heights are
  ITM's own h_e for the actual profile (QuickPfl; Hufford, Longley and
  Kissick, NTIA TR-82-100).
- Rationale: research package M13 in its parameter-free form.
- Predicted (planner's prior): worse than 707. Stock ITM's line-of-sight
  treatment is 0.24 dB worse than 707's on clear rows, and stock is 11 dB
  optimistic on low-antenna rows where 707 is within 2 dB. Screen:
  CERTAIN_HARM or CANNOT_PASS.
- Confidence: medium.

**1805, structural heights.**

- Change: `"smooth_heights":"structural"`. Heights above the smooth surface
  are the antenna heights above local ground (the surface passes through
  both ground points). Source for the idea: Paul (2003), ISART SP-03-401
  (TODO: page and equation).
- Predicted (planner's prior): more loss on low antennas below 1 GHz, where
  707 is already +4 to +6 dB on obstructed rows; R1 worse. Screen:
  CERTAIN_HARM or CANNOT_PASS.
- Confidence: low.

### B18c: representative clutter heights on the profile

**1806, trees as terrain.**

- Change: `"profile_clutter":"p1812_representative"`. For the actual-path
  diffraction only (L_ba), add 15 m to every interior profile sample whose
  NLCD 2001 class is woodland (41, 42, 43, 90: B11's mapping), not to the
  two terminal samples. The smooth surface and L_bs are unchanged. Phase 2
  rows only (`landcover_profile_rev1`, PR #10).
- Source: ITU-R P.1812-7 §3.2.1 (surface profile from representative clutter
  heights; trees/forest 15 m). **TODO before any code:** read the
  Recommendation's own text for the equations, the terminal rule and the
  table. Today the source is a secondary description (arXiv:2501.11708).
- Rationale: canopy raises the diffracting surface. The added loss grows
  with frequency, as the missing loss at R2 and VA does (B06 reviewers:
  about 13 dB per decade there, 0 to 3 at R1 and R3; forest share of profile
  samples: VA 60 %, R2 53 %, R1 18 %, R3 1.5 %).
- An end with the P.2108 terminal clutter term (concealed) is already
  computed at 15 m, so the wall beside it is at antenna height.
- Predicted (planner's prior): open terminals in forest pixels sit behind a
  15 m wall 30 m away, as in B11 and B17. Median change at R2 and VA open
  rows +10 to +20 dB; screen CERTAIN_HARM. If so, vegetation on class data
  is closed, and data PR D2 isn't requested.
- Confidence: medium.

### Combined repair (only if both parts stay open)

**1807** = 1801 + 1803. The real-path height-gain check reports one worst
excess, which today covers both defects (27.0 dB from the edge switch, about
4.5 dB from the inversion), so only the combination can bring it under the
1 dB limit.

## Before the runs (planner and worker)

1. Nick approves this draft.
2. Code in `itm_variant/` only, each switch with a default that reproduces
   707: two methods in `multi_edge_diffraction_rev1.m`, `cfg.smooth_heights`,
   `cfg.profile_clutter`. Tests for each: hand-computed cases, reversal, the
   default equal to 707, an unknown value stops with an error.
3. Test suite passes. Parity at defaults:
   `run_eval_rev1(Tag="000-baseline", Parity=true)` within 1e-9 dB.
4. Smoke test for each candidate with `b17_smoke_rev1.m` (it takes the full
   override string): per-row change against 707, model only.
5. B18a only: the B16a sweeps (`b16a_oracle_rev1.m` pattern) with the new
   method. Report the largest change per 0.05 m at each frequency.
6. Screen each candidate with `hm_screen_rev1.py` and the floor file.
7. Repair candidates only (1801, 1802, 1803, 1807): an exact recount of
   censored violations from the deltas (candidate prediction = 707's stored
   prediction + delta, against the stored bounds). New script
   `b18_censored_recount_rev1.py`. It reads development bounds, as the
   evaluator's gate does, and no other measured value.
8. Replace the priors above with the smoke and screen numbers, rename this
   file `B18.md`, commit and push before any scored run.

## Decision rules (fixed now)

- **Screen says CANNOT_PASS or CERTAIN_HARM:** not run. Recorded as screened
  out with the bound.
- **Gain candidates (1804, 1805, 1806) left open:** scored against 707 under
  the acceptance rule. k = 5 for the first (99 % interval, 2,000 draws), 6
  for the second.
- **Repair candidates (1801, 1802, 1803, 1807):** scored only if all of
  these hold in the model-only steps:
  - the screen doesn't return CERTAIN_HARM;
  - the censored recount is within +1 point of 707;
  - B18a only: the largest change on the B16a sweeps is under 1 dB per
    0.05 m at every frequency.

  Then the repair-keep rule applies: the battery check that 707 fails must
  pass (pointwise continuity, real-path height gain), the lower end of the
  paired interval on the screened composite must be above −0.3 dB, the full
  composite, the sites and the censored share must hold, and three reviewers
  pass it.
- **Bracket conclusion.** If 1801 fails the censored recount and 1802 is
  CERTAIN_HARM (the planner's prior), record: no count-stable form of the
  cascade repairs the jump under the current gates. The defect stays
  documented in 707, and the lockbox proceeds (phase plan, section 5).
- **Stop** and hand back to the planner if a test fails, parity exceeds
  1e-9 dB, a source can't be confirmed for 1806 or 1805, or a smoke test
  shows a non-finite loss.

## Worker tasks that don't change behavior

- Correct the P.452-18 equation numbers in the comments of
  `itm_p2p_core_exp.m` after confirming them against the PDF (the Word file
  gives (147)-(153d) where the code says (161)-(167)). Parity run afterward.
- Add two fields to `info` for the delta forms: the gap between the two
  largest full-path ν, and L_ba with the runner-up as principal. Report
  only; parity must hold.

## What isn't in this batch

- No change to `eval/`, `data/` or FRAMEWORK.md. Evaluator PR E2 (phase
  plan, section 4) is separate and Nick's.
- No fitted parameter.
- The coupled multi-screen engine (phase plan, section 1) isn't built.
