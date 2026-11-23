# Phase plan, rev 2: after B15

Planner: Claude Fable 5.2, 2026-11-23. Requested by Nick. Supersedes the
"next batch" sections of `headroom_map_rev1.md` and the next-candidate note
in `B14.md`. Analysis only; every number is reproducible with
`experiments/batches/hm_ceiling_rev1.py` and `hm_screen_rev1.py`.

## Summary

1. **The ratchet is close to its ceiling for single, sourced mechanisms.** If
   a change removed the mean error of every score cell perfectly, the screened
   composite would fall from 9.91 to 8.78 dB: 1.13 dB in total, split 0.37
   (Phase 2), 0.41 (long-term level) and 0.35 (long-term shape). A keep needs
   0.3 dB from one change. The other 8.8 dB is spread between paths inside
   cells, which only path-specific information can reduce.
2. **B15 can't pass.** A perfect fading-side variability model gains 0.10 dB;
   a perfect two-sided one gains 0.14 to 0.21 dB on the full composite. Time
   variability is closed as a score lever under the current rule (B15.md).
3. **The protocol now blocks two things it shouldn't.** Known data artifacts
   can veto a keep through the full composite, and a documented physics
   defect in the kept model can't be repaired unless the repair also gains
   0.3 dB. Recommendations P1 and P3 fix both without changing any past
   decision.
4. **Recommended next phase: harden 707, then one score batch with new
   inputs, then the lockbox.** Order: battery PR and repairs (B16), path
   vegetation on two parents (B17), effective height through the screen (B18),
   then freeze and score the lockbox.

## Where the error is (707, development data)

| Part | Full | If every cell mean were zero | Screened | If every cell mean were zero |
| --- | --- | --- | --- | --- |
| Phase 2 level | 13.25 | 12.13 | 13.25 | 12.13 |
| Long-term level | 19.09 | 16.13 | 11.22 | 9.98 |
| Long-term shape | 5.17 | 4.45 | 5.27 | 4.22 |
| Composite | 12.51 | 10.90 | 9.91 | 8.78 |

Reading:

- **Phase 2.** The five R2 cells run 13 to 29 dB RMS with almost no bias
  left (spread 12 to 25 dB): R2 is path-to-path scatter (D03's dead paths).
  VA is the one site with usable bias: −4.8 to −11.8 dB from 0.3 to 10 GHz
  (too little predicted loss), worth 0.19 dB of composite if removed. R1 has
  +5 to +6 dB below 1 GHz, worth 0.06 dB.
- **Long-term level, screened.** Ten of twelve cells are within 2.5 dB of
  unbiased with 8 to 11 dB of spread. Two cells carry bias: 0.3-1 GHz beyond
  300 km (−8.4 dB, 38 rows) and 3-10 GHz under 100 km (+9.0 dB, 7 rows).
- **Long-term shape.** See B15.md: bias ceiling 0.24 dB of composite on both
  sides together.
- **The 36 screened links** carry 7.9 dB of the full long-term level score
  (19.09 against 11.22). They decide what the full composite does.

## Protocol review

### P1. Make the screened composite the gate; hold the full composite to "no harm"

- **Problem.** The acceptance rule needs 0.3 dB with a clear interval on
  both composites. The 36 screened links are documented artifacts
  (record says line of sight, 30 m profile is blocked; or the terminal sits
  below a ridge within 0.5 km). They can't earn a keep, which is right. But
  they can veto one: they hold 41 % of the full long-term level score, so a
  change that's neutral or good on the 512 real links fails if it moves the
  artifacts the wrong way.
- **Evidence.** 1301: full −0.30 dB, screened +0.04; all of the harm was on
  the 36 links. D06b: full +0.51, screened −0.07; all of the gain was on the
  36 links. In both, the full composite measured the artifacts.
- **Recommendation.** Gate on the screened composite (gain ≥ 0.3 dB, interval
  above zero). Require the full composite not to get worse by more than
  0.3 dB. Keep reporting both.
- **Effect on past decisions.** None. Every rejection in `results.tsv` rests
  on the censored gate, the battery, a site gate, the reviewers, or a
  screened composite that was also worse; 707 passes both.
- **Who decides.** Nick (FRAMEWORK.md, acceptance rule 3 and 6).

### P2. Multiple testing: tighten the interval as candidates accumulate

- **Count.** `results.tsv` has 37 scored rows and one keep. Since 707, four
  keep candidates have been scored on it (709, 711, 712, 1301), plus two
  diagnostics and four candidates screened out before running.
- **707 itself is safe.** Its gain over stock is 3.5 dB against a paired SD
  of 0.1 to 0.2 dB. Selection among about 30 candidates could inflate that by
  a few tenths of a dB, not more. The lockbox is the only unbiased figure.
- **The risk is the next marginal keep.** Each candidate has about a 2.5 %
  chance of clearing a 95 % interval by luck. Over k candidates that's
  1 − 0.975^k: 12 % at k = 5, 22 % at k = 10.
- **Recommendation.** Use a paired interval at level 1 − 0.05/k, where k is
  the number of keep candidates scored since the last keep, counting the
  current one (Bonferroni). Candidates the history-matching screen or a
  ceiling rules out aren't scored, so they don't count; diagnostics don't
  count. The next candidate is k = 5: a 99 % interval. This needs one more
  argument in `paired_gain_rev1` (eval/ PR) or 2,000 bootstrap draws for a
  stable 99.5 % bound.
- **Who decides.** Nick.

### P3. Add a "repair keep" for documented physics defects

- **Problem.** 707 has two recorded defects: the principal-edge switch (a
  loss jump of up to 30 dB for a 2.5 m height change, P.526-11 cascade as
  written) and the antenna-height inversion from P.452 eq. (166). A fix
  acts on few rows, so it can't gain 0.3 dB, so the ratchet can never accept
  it. The model that leaves the repo keeps defects we know about.
- **Recommendation.** A change is kept as a repair if all of these hold:
  1. It removes a defect logged before the batch, shown by a battery check
     that `best` fails and the change passes.
  2. It's non-inferior: the lower end of the paired interval is above
     −0.3 dB on the screened composite, no site is worse by more than
     0.5 dB, and censored violations don't rise by more than 1 point.
  3. It adds no free parameter and has a public source.
  4. The three-reviewer pass runs on every repair keep, not every tenth.
- **Why this matters for use.** A 30 dB jump is what an opposing technical
  filer would lead with. A model without it, at the same score, is worth
  more than 0.3 dB.
- **Who decides.** Nick (FRAMEWORK.md, acceptance rule).

### P4. Battery: compare steps pointwise, and check the tails

- **Gap 1.** The continuity check passes if the variant's largest step is no
  more than 1 dB above stock's largest step. Stock steps 33 dB on the rough
  profile, so a new 30 dB step anywhere else passes. That's how 707's
  principal-edge jump got through.
- **Gap 2.** Every sweep is at 50 % time. B14 was the first batch to change
  only the tails; its 4 to 5 dB tail steps passed.
- **Recommendation (eval/ PR, report-only first, as PR #4 was).**
  1. Pointwise rule: at each step of each sweep,
     |ΔL_variant| ≤ |ΔL_stock| + 1 dB.
  2. Run the distance sweeps at 1 % and 99 % as well as 50 %.
  3. Print both in the summary; don't gate until Nick has seen what 707
     scores on them.
- **Who decides.** Nick. I can draft the PR.

### P5. The 36-link screen: keep it, and stop extending it

- The screen rules were fixed before the experiments that used them, both are
  geometric (no measured loss), and the list is hash-checked. D06b shows the
  screen doing its job.
- Don't add rules. The remaining large-error links (for example LT_LT2242 and
  LT_LT2237 at +28 dB under 25 km) have no pre-registered geometric reason
  to exclude, and a third rule chosen after seeing errors would be tuning
  the data.
- **No change recommended.**

### P6. Make the ceiling check part of registration

- Before a batch is planned, the planner states the family's ceiling: the
  perfect-bias gain for the cells it acts on (`hm_ceiling_rev1.py`) and, where
  it brings path-specific information, the argument for why it could beat
  that. B15 would have been stopped before design.
- This is planner practice (the `itm-register-batch` skill), not a framework
  change. I'll add the step to the skill.

### P7. Define the end of the phase now

- **Proposed rule.** After B18, or after two consecutive batches in which no
  candidate passes the screen and the gate, freeze `best`. Nick scores the
  lockbox once, on `best`, stock ITM and R01.
- The write-up reports the lockbox figures as the result and the development
  figures as the search record.
- **Who decides.** Nick.

## Research agenda after B15, ranked

Ceilings are from the headroom map (perfect, and with a 5 dB floor) and the
cell-bias oracle above. "ρ needed" is the history-matching screen's required
correlation with 707's error; diffraction replacements against stock reached
0.5 to 0.8, and changes on 707 have reached 0.39 and 0.51 at best (D06).

| Rank | Lead | Ceiling | What it needs | Chance of a keep | Why this rank |
| --- | --- | --- | --- | --- | --- |
| 1 | Repairs to 707: principal-edge jump, height inversion | Score-neutral; R1+R3 obstructed rows hold 0.62 dB at most | P3 and P4 decided; a design per defect | About 40 % under P3; under 10 % under the gain rule | Highest value per unit of risk; removes the weakest point of the kept model |
| 2 | Vegetation along the path on terrain-clear rows (M11) | 0.87 dB at a 5 dB floor; VA bias alone 0.19 dB | `data/` PR: NLCD along each Phase 2 profile; ITU-R P.833 primary text | About 25 % | Right sign on the rows that are 6.4 dB optimistic and break every censored bound; the only lead with new path-specific input |
| 2b | The same term on the no-C Deygout parent (708) | 708 scores 0.63 dB better than 707 but fails the censored gate (32.5 %) | The M11 term; one extra run | About 15 % | A loss-adding term on clear rows is what that family lacks; needs censored violations down by 3.5 points |
| 3 | Effective antenna height (M13) | Line-of-sight class: 3.65 dB perfect, 4.18 screened, the largest class | Code for `cfg.effective_height`; parameter-free forms first | About 15 % | Big class, but bias-only gain is 0.11 dB, and a fitted blend must buy 0.5 dB |
| 4 | Enhancement side: ducting and layer reflection (M15) | 0.07 to 0.12 dB full; 0.25 to 0.36 screened | P1 decided; P.452-18 or P.2001-6 anomalous-propagation text | About 5 % | Can only pass if P1 is adopted, and only if nearly perfect |
| — | Closed | | | | See below |

### Closed leads (don't retry without new information)

- **Time variability, both sides** (H03, H19, P.617-6): ceiling 0.10 dB on
  the fading side, 0.21 both sides (B12, D06, B15).
- **Troposcatter median** (P.452-18 eq. 45, P.617-6 eqs. 4-5): no alignment
  with 707's error on real links (1301, D06b).
- **Aperture-to-medium coupling loss** (P.617-6 eq. 3): the raw long-term
  file has antenna gain columns (`Xgn`, `Rgn`), but they're filled on 93 of
  1,114 raw rows and on 1 of the 548 scored rows. Checked 2026-11-23 against
  `data/raw/longterm.zip`; TODO: confirm the row matching if anyone reopens
  this.
- **Line-of-sight reflection** (H02, Ament): 0.128 dB at most (B12, headroom
  map).
- **Terminal clutter from land cover at open terminals** (711, 712).
- **P.526-16 §4.4 cylinders** (B09): fails continuity.

## Fit with the independent review of 2026-11-23

Nick added `research_review_2026-11-23.md` (five proposals) while this plan
was being written. How each one sits against the ceilings:

| Review item | Disposition here |
| --- | --- |
| 1. Fixed-geometry coupled two-screen oracle (H01, Vogler) | Adopt as the first step of B16's principal-edge repair. Its staging is right: prove the ideal-screen calculation is continuous on the logged R2-020 height sweep before any terrain-to-screen mapping. It's a repair, so it needs P3 to be keepable. |
| 2. P.617 fading side with a continuous transition | Answered by B15.md. The design there meets the review's conditions (median exactly 707, ITM below 50 %, no mode switch, equation stated before any run). The review's own falsifiers are already met from stored runs: the same-screen gain is +0.01 dB, the full-composite gain (+0.12) sits in the artifact links, and the ceiling for any fading-side model is 0.10 dB. Recommend closing it without a build. |
| 3. Curvature loss for one isolated crest (H05) | Diagnostic only, as the review says. Low priority for score: a rounded crest adds loss on obstructed rows, where 707 is already pessimistic at R1 and R3. Worth doing only if a cohort of resolved single-crest paths exists; count them first. |
| 4. Roughness estimator audit (H04) | Fits the hardening phase: a model-only numerical audit with invariance tests. No score claim. Run it alongside B16, since sampling invariance is a defensibility property like continuity. |
| 5. External height-gain campaign (H02 external) | Outside this repo's data; Nick's call. Nothing here depends on it. |

The review's repository controls ask for the 1 % and 99 % continuity checks
from B14. P4 above makes them part of the battery, with the pointwise rule.

## Proposed sequence

1. **Decisions from Nick** (below). Nothing else starts until P3 and P4 are
   answered, because they define what B16 is.
2. **Eval PR E1** (P4), report-only. Then score 707 on it: the baseline for
   repairs.
3. **B16, repairs.** One design per defect, each with a source:
   - Principal-edge jump: start with the review's fixed-geometry coupled
     two-screen oracle (Vogler, NTIA TR-83-124) on the logged R2-020 height
     sweep; the rival is a continuous weighting of the P.526-11 secondary
     edges. Only a form that's continuous on R2-020 T1 and T2 goes forward.
   - Roughness estimator audit (review item 4), model only.
   - Height inversion: fix the smooth surface from terrain alone (P.452-18
     eqs. 163-164 without the antenna-dependent eq. 166), only if the
     P.452-18 or P.1812 text supports it (TODO in the LOG).
4. **Data PR for B17**: NLCD class at every profile sample of the 515 Phase 2
   paths, with the builder, as PR #6 did for terminals.
5. **B17, path vegetation** on 707 and on 708, screened first. (702 has the
   double-counted clutter term that 701 had, so it isn't a valid parent.)
6. **B18, effective height**, parameter-free forms swept through the screen;
   run only what it doesn't rule out.
7. **Freeze and lockbox** (P7).

## Decisions for Nick

1. **B15:** record 1501 and 1502 as screened out by ceiling, or run 1501 once
   as diagnostic D07?
2. **P1:** gate on the screened composite, with the full composite held to no
   harm?
3. **P2:** Bonferroni level for the paired interval?
4. **P3:** allow repair keeps?
5. **P4:** open the report-only battery PR?
6. **P7:** adopt the end-of-phase rule and the lockbox trigger?
7. **B17 input:** approve a `data/` PR for NLCD along Phase 2 profiles?
