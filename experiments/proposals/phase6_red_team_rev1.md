# Phase 6 red team: findings on the rev 6 drafts

Red team: a separate agent that didn't see the planner's drafting,
2026-11-26. It was given the three drafts (research notes, phase plan rev
6, B35), the repo and the sources, and was told to break the plan. It
edited no file, read no measured R4 value and no Tier B data, and ran no
model. Its reports are kept as returned (the format is its own). The
planner's dispositions are in [phase_plan_rev6.md](phase_plan_rev6.md).

## Round 1

**1. B35 E2 (canopy contrast) / FAIL**
- REASON: Censoring selects on the outcome, and the group mean is under-specified. In-canopy cells with the most loss are the ones censored, so measured K is biased low and D2 is biased toward "hurts". Section 3 doesn't say whether the model's mean uses the same surviving heights as the measured mean. E2 also has no constant-loss control arm, so "helps" can't separate P.2108 from any added loss.
- EVIDENCE: `phase_2.txt` (500 + bound convention); `r4pars.txt` MaxLb 190 to 220 dB; B35 section 3 "at least half its heights"; D20c had a constant control (LOG 1413), and `terminal_clutter = "constant"` exists in `params_exp.m` line 81.
- SCOPE: E2, E3, and the P.833 comparison.

**2. B35 E1 (primary) / FAIL**
- REASON: Outcome A wouldn't isolate the diffraction change. "Above canopy" is only 3 to 6 m over 18 m trees, so the first Fresnel zone at 230 and 410 MHz still cuts the grove, and neither arm models that. 707 tends to add loss, so it can win on mean |e| by offsetting unmodelled tree loss; B32 logged exactly this ("because it adds loss", LOG B32 entry). The section 4 reason is also wrong in code: 707's smooth-surface change acts on line-of-sight paths (LOG 602 to 607), so the arms aren't identical there.
- EVIDENCE: smooth-earth horizons for 7 m and 22.5 m sum to about 30 km, and 31 of 36 paths are at or under 30.5 km (`r4path.txt`).
- SCOPE: E1 and the write-up claim.

**3. B35 support and "outside" claim / FAIL**
- REASON: One receiver, one grove. The bootstrap over 36 paths measures transmitter-site spread only; for "credible at a wooded terminal", n = 1. R4 is 7.4 km from R1 (coordinates), with the same equipment and years, and one transmitter coordinate matches an R1 path exactly.
- EVIDENCE: `r1path.txt`, `r4path.txt`.
- SCOPE: Plan section 2 item 1, "decision it changes".

**4. B35 confounds not registered / FAIL**
- Grove depth by azimuth: 9 of 36 paths bear 220° to 250° from the receiver, around the 235° deepest direction. Depth is a path-level covariate in K and S that no arm has.
- The fetch summary of OT/TRER 19 said no transmitter sites lie between about 210° and 40°; the coordinates put 13 paths at 220° to 270°. I couldn't reconcile this; treat the summary as unreliable.
- Antenna patterns: 12.5° horns at 4595 and 9190 MHz (OT/TRER 19 Table 1). P.833-10 section 2.1 says A_m also depends on antenna pattern, species and density; the research notes quote only the height dependence.
- E3 confounds leaf state with season on paths up to 50 km (one visit each). Above-canopy S isn't used as a control.
- The cleared shaft is confirmed (foliage removed for antenna travel); "near its top" isn't.
- "No surveyed profiles exist": the zip has no `r4_pfl`, but the report's section 6 wasn't read by the planner or by me.

**5. B35 constants / FAIL (labeling)**
- REASON: Planner-chosen and not labeled: group bounds 2 to 12 m and 21 to 24 m, the 1 dB "resolved" size, the half-heights rule, the 20-path floor, the 2 % and 60 m length checks.
- The 60 m tolerance on the 0.57 km path allows about 0.9 dB of error in A, because L_fs uses the `r4path.txt` distance and the model uses the profile length.
- P.2108's 27 m street width is a Table 2 default applied to a grove.
- "A_m as an upper limit" is unsupported: it is a fitted mean for a 1.5 m antenna in another forest (Mulhouse standard deviation 8.7 dB), and K includes bare-earth height gain, while A_ev is excess to all other mechanisms.

**6. Stop decision / PARTIAL**
- REASON: Stopping the scored search is supported (B29, rev 5). The strongest counter-evidence is against "continue with B35": FRAMEWORK's phase 4 trigger (human Tier B run, after B18) has already fired and is still pending. R4 is the only untouched in-range set, and an agent run spends it. Option (b), human-run, preserves more.
- SCOPE: Plan sections 1 and 5.

**7. Plan item 2, Hunter Liggett stratification / FAIL**
- REASON: Post hoc on inspected data and already strained. Section 7 says ground-constant sensitivity is largest at the lowest antenna and much smaller at UHF, but B33's resolved shift is at 10 m in both bands. The authors report no consistent period difference and frequent tuning failures (section 7.2).
- "R1's permittivity didn't change" is an inference: page 61 gives R1 one range (3.3 to 4.8, median 4), not split by period.
- The Graham closure is supported (pages 42 to 45).

**8. Blinding / PARTIAL**
- No repo file or commit outside the raw zip exposes R4 values (`git log -S`, grep). Blinding is by convention only: the zip is committed (41db450), B35 and both proposals are still untracked, and the worker's parser reads the full file.

**9. Citations / PARTIAL**
- PASS, OT 75-74 as page images: pages 1 to 3, 38 to 45, 59 to 62, 70 to 73, A1 to A3 match the draft (sponsor, 0.35 m, 1 to 3 kHz, 110 mrad, 7/7/3 and 15/15/11 dB, 0 and 3 dB, Head, d_Ls/d_L, Graham and Hunter Liggett periods, ground constants, Table 10 order, 140 and 160 dB).
- Flags: "Tables 7 to 11" (Q4) cites Table 7, which is outside the pages the register lists; the plan says 8 to 11. The small time variability is stated for VHF only. "Vertical polarization" isn't in the page 70 text.
- PASS, P.833-10: eq. (1) and (2), the three constant sets, the 20 % figure, 2 and 8.5 dB. "No both-terminals model, no lateral wave" not confirmed.
- PASS, R4 archive: 36 paths, 1,728 lines, 864 per season, 72 per height, 6.6 and 7.3 m. `r4pars.txt` repeats the 9190 row; B35 doesn't say so.
- PASS, code: lines 239, 543, 559, 592, 593. Line 239 truncates metres, not a spacing quotient. The `reversed` swap is at line 1580, outside the 1533 to 1575 range the register says was read.
- Loss convention: correct in substance, but `build_links_rev1.m` line 231 is the long-term block; Phase 2 is lines 172 and 185.

**10. 707-C arm, R4 unused, duplicates / PASS**
- Set "R4", siting "C", reversed true gives end 2, trees and forest, base at max(h, 15 m), hold3. No other code branches on the set name with 707's switches.
- R4 is unused: the builder loops r1, r2, r3, va (line 113); other "R4" hits are VA receiver labels, OT 75-74 receivers, and proposal IDs. matlab_itm wasn't available to check.
- E2 repeats the D20c and D23b question at a new site; it isn't a relabeled closed attempt.

**11. Worker executability / PARTIAL**
- `d32_run_models_rev1.m` is a usable template. Gaps a Haiku worker would have to improvise: the duplicate pars row, the height subset for model means, the 999 code against "blank" (all 1,728 lines have nine fields), the cell definition for D1, and tie handling.

**Cut first:** the Hunter Liggett stratification in item 2 (four receivers, post hoc, pattern already strained). Keep the Graham closure as a note.

## Round 2

Given the updated files and the round-1 dispositions.

**1. B35 E2 text, section 3 / FAIL (new)**
- REASON: "K includes the bare-earth height gain ... which both 707 arms model the same way" is false in code. 707-C computes the whole path with the receiver at max(h, 15 m), so below 15 m it removes ITM's own height gain and substitutes A_h. D2 therefore compares "P.2108 A_h" against "ITM height gain from h to 15 m", not "term" against "none". 707-O's signed e doesn't isolate "the first part".
- EVIDENCE: `itm_variant/itm_p2p_core_exp.m` lines 89 to 94 and 208 to 212. Model K difference is about A_h(7 m) − [A_O(7 m) − A_O(15 m)].
- SCOPE: E2 labels ("better than none"), plan item 1 falsifier wording.

**2. B35 header and status / FAIL (new)**
- REASON: B35 says "after two red-team rounds" and "Status: registered", but the disposition table holds round 1 only and round 2 is this report.
- SCOPE: B35 lines 5 to 12; plan section 3.

**3. E1 reading rule / PARTIAL (new)**
- Decidable from registered outputs (mean signed error per arm). Flaws: the sign test has no margin or interval, so a stock mean of +0.1 dB flips "added loss" to "support"; signs are pooled over six frequencies and can hide opposite signs by band; "bracket zero" (stock −10, 707 +0.5 dB) is still added loss yet reads as support; exactly zero is undefined.
- If a frequency falls under the 20-path floor it is "descriptive", but B35 doesn't say whether it leaves the pooled D1.

**4. Group value / PARTIAL (new)**
- Well defined for 11 heights (sixth value; exists with 5 or fewer censored) and 4 heights (exists with 1 or fewer censored); consistent with "half or more".
- Bias: the censor bound is "maximum observable less 5 dB" (`phase_2.txt`), so an uncensored cell can exceed a censored cell's bound by up to 5 dB. "Censored ranks highest" then isn't guaranteed. Add: drop when the median cell exceeds the smallest censored bound in the group.
- "No height missing": one 999 in 11 heights drops the cell. Undefined whether missing-dropped groups count toward the 20 % rule. Not exploitable (fixed in advance), but it may cost many cells.

**5. D2 and bootstrap / PARTIAL (new)**
- Cells and pairing are specified. Not pinned: the generator type, whether per-frequency D1 intervals consume draws, and order within an endpoint. Fine for a same-script rerun, not for an independent one.

**6. Disposition audit / PASS with two gaps**
- Findings 1 to 4 and 6 to 11: changes are in the files and address the findings. Finding 6's partial rejection is argument, not evidence, and is labeled so.
- Finding 5: the 20 % drop threshold, 2,000 draws and 0.01 dB aren't in the planner-chosen list.
- Finding 4: notes say 13 paths at 220° to 270°; I count 14 inclusive (one at 270.0°, one at 220.1°). Trivial.

**7. Requested checks / PASS**
- (d) Smoke check true. At 15 m and above A_h = 0 and the height is unchanged; 707-O has `mobile_end` 0. Below 15 m, nu is always positive, so the nu ≤ −0.78 branch is unreachable and A_h is never zero (about 2.1 dB at 14 m, 230 MHz; about 12.5 dB at 7 m). The net difference also includes the base-height change (item 1).
- (e) True: line 153 `if j > 1 && F(j) == F(j - 1), continue, end`. Lines 137 to 139, 169 to 172 also match.
- (f) True: 12 paths at 205° to 265° from the receiver.
- (g) True: 7.36 km; R4-050-T1 equals R1-050-T1's transmitter.
- Coordinates agree with listed distances within 0.1 %, so the 2 % check is safe.
- No new wrong citation or duplicate of a closed attempt found.

**Blocks registration:** items 1 and 2. Item 3 (margin on the sign, and the floor case) should be fixed first too; it's cheap.

**Still open:** items 4 and 5; page-level reread of OT/TRER 19; whether matlab_itm or Nick's working paper scored R4; Nick's decision 1.
