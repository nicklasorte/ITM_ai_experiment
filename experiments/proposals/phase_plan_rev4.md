# Phase plan, rev 4: after B19

Planner: Claude Opus 5.5 (the prompt asked for Fable; this session ran on
Opus), 2026-11-24. Requested by Nick ("Let's move onto the next phase").
Plan only: no runs, no model edits.

`best` stays 707, frozen at 2baa02b for the lockbox, which Nick hasn't
scored yet. The lockbox scores 707 whatever this phase finds. Development
data only.

## Summary

- **Phase goal:** make every part of 707 physically defensible without
  losing score. A keep in this phase is either a gain under the acceptance
  rule or a repair under the repair rule. Score gains are secondary: the
  remaining bias ceiling is small (screened composite 9.91 → 8.78 at
  best), and the largest known errors are defects, not offsets.
- **A correction to the record (new in this plan).** The height-gain
  flattening isn't caused by the troposcatter bound, as registration rev 2's
  defect 3 says (taken from one reviewer). In every stored run that reports
  the ridge sweep, the receiver sweep over a 40 m ridge stays flat:
  - +0.17 to +0.19 dB in 15 runs, across three diffraction methods
    (cascade, Deygout, Bullington) and two bounds (ITM's line, P.452 at d);
  - −18.1 dB in 1804, the only run that changed the smooth-surface heights
    (ITM's effective heights), against −23.3 dB for stock;
  - by hand, 1901's bound doesn't bind on that sweep (troposcatter
    attenuation about 64 dB against about 40 dB of knife-edge loss), yet
    1901 is as flat as 707.

  The likely mechanism is the P.452-18 obstruction-adjusted smooth surface
  (Attachment 2 eq. (151a)–(152f)). It's referenced to the line between the
  antennas, so it rises with them and cancels L_ba's height gain in
  L_ba + max(A_s − L_bs, 0). **Problems 1 and 3 may be one mechanism**,
  but that's a hypothesis: dropping the adjustment altogether (1803) didn't
  repair the R1 inversion and created new 30.7 dB height failures on
  R2-080-T4 (B18). So the surface choice alone isn't the fix; D20a finds
  which term carries the flattening. The registration stays frozen; the
  correction goes in the LOG (decision 1).
- **Problem 5 is diffraction overshoot, not line of sight.** In 1901's
  record output, the pessimism sits on rows the profile shows obstructed:
  R1 open-obstructed +5.7 dB, R3 open-obstructed +6.7, R1
  concealed-obstructed +8.1. Clear rows are slightly optimistic (−0.6 to
  −1.4). The frequency-independent cascade correction C = 10 + 0.04 D
  (P.526-11 §4.4.2) is the leading suspect. It's also what holds the
  few-edge censored rows (phase plan rev 3, section 1).
- **Problems 2, 5 and 7 meet at the censored gate.** 1801 (jump removed)
  and the Deygout runs without C (702: composite 11.8) fail only the
  censored share. Whether to change that gate after the lockbox is a
  decision for Nick (decision 2), not a model question.
- **First batch (B20): three diagnostics, no scored candidate.** Each
  settles one mechanism and decides which B21 candidate is worth running.

## 1. Ranked hypotheses

Rank reflects the chance of a keep or repair and the cost to test. "Rule
out" says what result closes the hypothesis.

### R1. Smooth-surface height construction (problems 1 and 3)

- **Source:** ITU-R P.452-18 Attachment 2 §5.1.6.2–5.1.6.3, eq.
  (147)–(153d), as 707 uses it. Alternatives in public sources:
  - P.452-18 §5.1.6.4 eq. (154a)–(156) (antenna-independent surface; 1803);
  - ITU-R P.1812-8 Attachment 1 §5.6, which fits the surface to terrain
    heights only (TODO: confirm whether P.1812 applies the obstruction
    adjustment; check eq. (83)–(89d) against the PDF);
  - ITM's effective heights (NTIA TR-82-100; 1804).
- **Physics:** the obstruction adjustment lowers the surface by
  h_obs·a/(a_t + a_r), where h_obs is measured from the line joining the
  antennas. Raising an antenna lowers h_obs, raises the surface, and gives
  the antenna a smaller height above it than its real rise. L_bs and A_s
  then fall almost as fast as L_ba, so the delta stays flat.
- **Expected effect:** height gain restored (ridge sweep near stock's
  −23 dB). R1 inversion paths fixed (up to 4.5 dB). Small score change,
  sign unknown: 1804 changed the same term and lost 0.59 dB screened, with
  R2 4.5 dB worse.
- **Ceiling:** not a cell bias; acts path by path on obstructed rows.
- **Risk:** 1803 (antenna-independent surface) didn't repair the R1
  inversion and added 30.7 dB failures on R2-080-T4; 1804 failed the site
  gate. A surface that fixes height gain may break R2, and the inversion
  may need a separate fix.
- **Rule out:** D20a shows the ridge sweep stays flat with every public
  surface, or that the flatness comes from another term.
- **Rank 1** because one diagnostic decides it and it would close two of the
  three structural defects.

### R2. Cascade correction C on obstructed rows (problem 5)

- **Source:** P.526-11 §4.4.2 eq. (50a), (51), (52), as 707 uses it.
  Public alternatives:
  - P.526-16 §4.5.1 Bullington with its eq. (57) correction (R03 family);
  - P.526-16 §4.4 multiple isolated cylinders (B09 form);
  - Deygout without C (702, 705).
- **Physics:** C = 10 + 0.04 D (D in km) is added in full whatever the
  frequency, while the edge losses J(ν) shrink at low frequency. At VHF and
  low UHF, C becomes a large share of the predicted loss. That fits the
  band pattern (VA 76 MHz +6.9 dB, R1 230 MHz +4.1, R1 410 MHz +6.2,
  uncensored).
- **Expected effect:** if C drives the overshoot, a form without it
  improves R1, R3 and VA obstructed rows by 3 to 6 dB, but raises censored
  violations (702: 29.7 %, 705: 39.7 %, against 707's 22.8 %).
- **Ceiling:** the obstructed-against-clear split is inside cells, so the
  cell-mean ceiling (+0.37 Phase 2) understates it. D20b measures it.
- **Risk:** under the current share gate, any form without C fails.
- **Rule out:** D20b shows the overshoot doesn't scale with C's share, or
  is as large on rows where C is small.
- **Rank 2**, conditional on decision 2 for its keep path.

### R3. Terminal clutter validity (problem 4)

- **Source:** ITU-R P.2108-1 §3.1, as 707 uses it. Test design: research
  plan H01 (paired open/concealed differential).
- **Physics:** concealed-minus-open loss at the same terrain, frequency and
  heights isolates the terminal obstruction. P.2108-1 predicts a frequency
  and height dependence; a constant offset (704) predicts none.
- **Expected effect:** none on score (diagnostic). It decides whether the
  clutter term is physics or a fitted offset. Fable's read called it the
  link closest to fitting the development set.
- **Data:** 1,400 matched C/O pairs (same base path, frequency and
  heights).
- **Rule out (the term):** P.2108-1 doesn't beat the constant control on
  paired differences at held-out pairs. Then the clutter term is recorded
  as an empirical offset, and the write-up says so.
- **Rank 3:** cheap and decisive, no score at stake.

### R4. Line-of-sight A_s without terrain roughness (problem 6)

- **Source:** the delta construction's A_s is ITM run on the smooth path,
  where Δh = 0, so ITM's line-of-sight weighting puts all weight on the
  two-ray term (w = 1). P.452-18's own delta method uses its spherical-earth
  diffraction L_dsph, which has no two-ray term (TODO: confirm P.452-18
  §4.2.2 and its equation numbers against the PDF before coding).
- **Physics:** on rough line-of-sight terrain the reflected ray is diffuse.
  A smooth-path two-ray term overstates interference loss near grazing.
- **Expected effect:** small. Clear rows are already slightly optimistic,
  so removing two-ray loss may make them worse.
- **Risk:** a step where the path changes between clear and obstructed;
  clear-row optimism grows.
- **Rule out:** D20b's clear-row tables show A_s contributes under 1 dB on
  clear rows.
- **Rank 4.**

### R5. Principal-edge jump (problem 2)

- Nick ruled that 1801's rejection stands. No published continuous design
  meets the four terms of phase plan rev 3, section 1. Nothing new is
  proposed.
- If decision 2 replaces the share gate with the bounds-as-RMS figure (E2,
  PR #11), 1801 is re-scored as a repair under the new gate.
- **Rank 5** (blocked on decision 2).

### R6. R2 censored rise (problem 7)

- Not a model hypothesis: the pooled gate hides a site-level change
  (6.8 % → 14.7 %). Proposed evaluator PR, report-only first: censored
  share and bounds-as-RMS by site, with a per-site limit (decision 3).
- **Rank 6** (evaluator, Nick's approval).

### Closed (don't re-propose)

- P.452 troposcatter in any form (B13, B19).
- Path vegetation from land cover (B17, B18).
- ITM effective and structural heights *as the scored change* (1803 to
  1806). R1 reopens the smooth surface only because the height-gain
  diagnosis changed; a candidate must differ from 1803 and 1804 in
  mechanism, not just in surface choice.
- The Vogler oracle as a model (B16).
- The model-to-model comparison's remaining leads (B19 note).

## 2. How the rules apply

- **Acceptance rule (gains):** unchanged from FRAMEWORK.md. Screened gain at
  least 0.3 dB with the Bonferroni interval above zero; full composite no
  worse than 0.3 dB; no site worse by more than 0.5 dB; censored share up
  by at most 1 point.
- **Repair rule:** a defect logged before the batch, a battery check that
  shows best failing and the change passing, non-inferior on screened
  (lower bound above −0.3 dB), composite, sites and censored, parameter-free
  and sourced, three reviewers.
  - The height-gain defect has no failing battery check today: the ridge
    sweep passes because its limit is max(stock change, 0) + 1 dB. A repair
    under R1 needs the report-only real-path height check
    (`height_gain_real`, 707: 27.0 dB over) as its "best failing" check.
    That check is report-only, so decision 4 asks whether it counts.
- **Bonferroni:** k doesn't reset for a new phase. It counts candidates
  scored against the current best (707). The next scored candidate is
  k = 7: level 1 − 0.05/7 = 99.29 %, decided on the 99.5 % lower bound
  (`lo995`), 2,000 draws. k resets only when `best` changes.
- **Diagnostics** (D-series) aren't candidates and don't count toward k.
  They read development measurements, which FRAMEWORK.md allows for
  diagnostics, and never lockbox data.

## 3. Batches

| Batch | Content | Scored runs | Depends on |
| --- | --- | --- | --- |
| B20 | D20a smooth-surface decomposition; D20b cascade-term decomposition; D20c paired clutter validation | 0 | — |
| B21 | Up to two candidates chosen by B20's pre-registered decision rules (R1 surface, R2 correction or R4 A_s) | 1 to 2 | B20, decision 2 for R2 |
| B22 | Repairs: 1801 re-score if the gate changes; R1 repair if B21's candidate is non-inferior | 0 to 2 | Decisions 2 and 4 |

## 4. Stopping rule

The phase ends at the first of:
- B22 closes;
- two consecutive scored batches with neither a keep nor a repair;
- a keep that changes `best`. A new best then gets its own reviewer pass
  and lockbox registration. The lockbox sets will have been used once for
  707, so a second use is validation, not a blind test, and the
  registration says so.

## 5. Decisions for Nick

**Decided 2026-11-24** ("Do all the things you recommend"): 1 yes;
2 deferred until after the lockbox is scored; 3 yes; 4 yes, for the
height-gain defect only; 5 approved.

1. **Record the defect-3 correction in the LOG?** The registration stays
   frozen; the LOG entry says the flattening comes from the smooth surface,
   with the evidence above. Recommended: yes.
2. **Censored gate after the lockbox.** Keep the pooled share (status quo),
   or decide on the bounds-as-RMS figure from PR #11, or add a per-site
   limit. This decides whether R2, R5 and 1801 can be kept. Recommended:
   decide after you've scored the lockbox, not before.
3. **Per-site censored reporting PR** (report-only first). Recommended: yes.
4. **Can the report-only real-path height check count as the "best failing"
   check for a repair?** Without it, no height-gain repair can qualify
   under the repair rule. Recommended: yes, for this defect only, stated
   before B21.
5. **Approve B20 as drafted** (three diagnostics, no scored runs).

## Sources

- ITU-R P.452-18 (2023), Attachment 2 §5.1.6, eq. (147)–(156); §4.2
  (delta-Bullington); §4.2.2 (TODO: confirm equation numbers).
- ITU-R P.526-11 (2009) §4.4.2, eq. (50a)–(52); ITU-R P.526-16 §4.4,
  §4.5.1 eq. (49)–(57).
- ITU-R P.1812-8 Attachment 1 §5.6 (TODO: confirm).
- ITU-R P.2108-1 (2021) §3.1.
- G. A. Hufford, A. G. Longley and W. A. Kissick, "A Guide to the Use of
  the ITS Irregular Terrain Model in the Area Prediction Mode," NTIA
  Report 82-100, 1982 (effective heights).
- Repo records: `experiments/LOG.md`, `results/results.tsv`, run
  `metrics.json` files (ridge sweep values), `experiments/batches/B16.md`
  to `B19.md`, `experiments/proposals/phase_plan_rev3.md`,
  `docs/research/FUTURE_RESEARCH_PLAN_rev1.md` (H01).
