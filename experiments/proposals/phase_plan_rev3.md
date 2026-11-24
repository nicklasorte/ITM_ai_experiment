# Phase plan, rev 3: after B17

Planner: Claude Fable 5.2, 2026-11-24. Requested by Nick. Plan only: no
evaluation was run and no model code changed. Supersedes the "Proposed
sequence" of `phase_plan_rev2.md`; rev 2's protocol sections (P1 to P7)
stand as merged in PR #9.

Every number here comes from finished runs. Reproduce them with
`experiments/batches/hm_ceiling_rev1.py`, `hm_screen_rev1.py` and the new
`hm_frontier_rev1.py` (hybrids, frontier and strata of stored predictions).

## Summary

1. **No repair of the principal-edge jump meets all four terms.** A method
   that's continuous by construction and published is either a single
   equivalent edge (Bullington), which fails the censored gate, or a coupled
   field over every ridge (Vogler, Fresnel-Kirchhoff), which counts the
   ridge that 707's lower branch leaves out and so lifts T1 by an estimated
   2 dB at 230 MHz and 16 dB at 9190 MHz. Section 1 gives the reasoning, the
   coupled design for the record, and the cheapest tests.
2. **The diffraction family barely moves the score. The censored-share gate
   picks 707.** On Phase 2 rows, swapping 707 for Bullington (703) or for
   Deygout without the correction C (708) changes the composite by +0.17
   and −0.20 dB. Under the current screen, the Bullington runs score 0.3 to
   0.7 dB better than 707 on the screened composite, and they fail only on
   the share of censored bounds violated (47 to 55 % against 22.8 %).
3. **B18 is a screen-first batch, and effective height no longer leads.**
   B18 takes the three parameter-free families left through the smoke test
   and the screen, with a two-sided bracket test of the repair. Nothing is
   scored unless the screen leaves it open. The planner's estimate is 0 or 1
   survivors.
4. **Score the lockbox after B18, with the panel and the predictions
   registered first.** One development stratum is a warning: at 76 MHz, 707
   is no better than stock ITM (RMS 9.6 against 9.3 dB, mean +6.7 dB), and
   one lockbox set is 20 to 100 MHz.
5. **Housekeeping found while reading sources:** the code cites ITU-R
   P.452-18 eq. (161)-(167) for the smooth surface. In the P.452-18 Word
   file read on 2026-11-24 those equations are (147)-(153d). The LOG's
   "eq. (166)" is (152c)-(152f) there. A worker should confirm against the
   PDF and correct the comments.

## 1. Repair of the principal-edge jump

### The four terms

1. Continuous by construction, with no fitted width or weight.
2. From a public source.
3. Keeps the secondary-edge loss that the censored gate depends on.
4. Doesn't lift T1's lower branch.

### What the jump is

707 uses the ITU-R P.526-11 §4.4.2 cascade: the principal edge p (largest ν
on the whole path) and one secondary edge on each side of it,
L = J_p + T (L_t + L_r + C), with eq. (50a), (51), (52). On three-ridge
terrain the number of edges counted depends on where p is:

- p is the middle ridge: one ridge on each side, three edges counted.
- p is an end ridge: both other ridges are on one side, two edges counted.

When the largest ν moves between a middle and an end ridge, the count
changes by one whole edge. On R2-020-T1 at 9190 MHz the third ridge (profile
point 172, ν 6.9) is worth 29.7 dB, and the step is 30.0 dB.

Two properties locate the defect:

- **Two edges alone don't jump.** For edges at distances a, b, c (transmitter
  to edge 1, edge 1 to edge 2, edge 2 to receiver), if the full-path
  parameters are equal, ν_1 = ν_2, then the two secondary parameters are
  equal too: ν of edge 2 on the sub-path from edge 1, and ν of edge 1 on the
  sub-path to edge 2, both equal
  k [sqrt((a+b)(b+c)/b) − sqrt(ac/b)], where h_1 = k sqrt(a(b+c)) and
  h_2 = k sqrt((a+b)c). So J_p + T (J_s + C) is the same either way. Checked
  numerically (1,000 random geometries, relative difference 2e-14).
- **The jump is a third-ridge effect.** It comes only from the rule "one
  secondary edge per side".

### Why no published design meets the four terms

The following table lists each design against the terms.

| Design | Source | Continuous by construction | Term 3 (censored) | Term 4 (T1 lower branch) | Evidence |
| --- | --- | --- | --- | --- | --- |
| Single equivalent edge (delta-Bullington) | ITU-R P.526-16 §4.5; P.452-18 §4.2 | Yes | **No**: 55.0 % violated (703); using it on the rows with 4+ obstacles alone takes the overall share from 22.8 to 44.2 % | Yes | Runs 401, 402, 703; `hm_frontier_rev1.py hybrid` |
| Coupled field over all ridges (Vogler N edges, or a Fresnel-Kirchhoff march) | NTIA TR-83-124; Whitteker 1990 (TODO: confirm the reference) | Yes for a fixed edge set; a ridge-selection rule brings steps back | **Unlikely**: knife edges without an empirical correction are 17 to 22 dB optimistic on rows with 0 to 2 edges (501, 505) | **No**: counts ridge 172 | B16a; estimate below |
| Field over every profile sample (absorbing-terrain split step) | Same, plus the parabolic-equation literature (TODO: references) | Yes, strictly: no selection at all | Unknown; same concern as above | **No** | Not built |
| Cascade capped at two edges (principal plus one secondary) | P.526-11 §4.4.2, modified | No, but the step shrinks to the difference of two secondary losses (0.2 to 0.4 dB on the R2-020 switches, by hand) | **No** (planner's estimate): rows with 3+ edges lose one edge; violations rise 6 to 12 points | Yes | Bracket test 1801 |
| Cascade that always counts three edges | P.526-11 §4.4.2, modified | No | Yes | **No**: T1's lower branch gains ridge 172 (+15 to +30 dB) | B16 stage 2; bracket test 1802 |
| Blends of the two branches | None | Only with a width, or with the step moved (B16 stage 2) | — | No | B16 stage 2 |

The terms conflict in pairs:

- **Terms 1 and 2 with term 3.** The only published methods that are
  continuous without a selection step are Bullington and the coupled field.
  Bullington loses the multi-edge loss. The coupled field has no empirical
  correction, and the cascade's C = 10 + 0.04 D (10.8 dB at 20 km) is what
  holds the few-edge censored rows.
- **Term 1 with term 4.** A continuous multi-edge method counts every
  obstructing ridge at every antenna height. On T1 that's three ridges, so it
  sits near 102 dB at 9190 MHz below the switch (coupled pair 72.7 dB plus
  29.7 dB for ridge 172; B16a's coupling terms are under 0.6 dB), against
  85.9 dB for 707's lower branch: +16 dB. At 230 MHz the same estimate is
  about +2 dB. T1's detected rows are already 4 to 14 dB below the lower
  branch.

Term 4 also deserves a caution. T1's level is one path of 45 at R2, where
the mean error is −0.2 dB and the RMS 18 dB. The contrast across the switch
is the defect evidence. The level of one path isn't a fair requirement of a
general method, and a repair should be judged by the repair-keep rule
(non-inferior on the screened composite, sites and censored share).

### The coupled design, specified for the record

Not recommended to build before the tests below. If Nick wants a physics
reference later, this is the design.

- **Field.** N thin absorbing screens at ranges x_1 < ... < x_N with tops
  h_m, on a flat Earth with the bulge x (d − x) / (2 a_e) added to each top
  (P.526-11 eq. (49a)), as B16a did. The paraxial Fresnel-Kirchhoff step
  from screen m to m + 1, Δx = x_{m+1} − x_m, is
  u_{m+1}(z) = sqrt(i / (λ Δx)) ∫ from h_m to ∞ of
  u_m(z′) exp(−i k (z − z′)² / (2 Δx)) dz′.
  The loss is −20 log10 |u(z_r) / u_free(z_r)|. For N screens this repeated
  integral should equal Vogler's attenuation function (NTIA TR-83-124
  §§2-3). That equality is a test, not an assumption: the engine must
  reproduce `vogler_two_screen_rev1` and the Vogler values of NTIA TR-26-580
  Table 17.
- **Numerics.** Uniform height grid Δz ≤ λ / (2 θ_max), a fast Fourier
  transform per step (the free-space propagator exp(−i p² Δx / (2 k)) in the
  vertical wavenumber p), field set to zero below each screen top, an
  absorbing taper at the top of the grid. Screens at every profile sample
  need no ridge rule, so continuity is strict.
- **Gate tests.** The B16a sweeps (R2-020 T1 and T2, 1 to 40 m in 0.05 m
  steps, seven frequencies): largest change under 1 dB per 0.05 m. The
  battery's pointwise continuity check at 1, 50 and 99 %. Reversal exact.
  Loss change under 0.5 dB when every profile interval is split in two
  (B16b's refinement test).
- **Cost (estimates, not measured).** Work is samples × M log M, with
  M = window / Δz. Phase 2 at 9190 MHz: 670 samples and M of about 2^14 give
  about 0.3 s a row; the longest profile (3,511 samples) about 1.4 s. All
  16,805 rows, actual and smooth profile: 1 to 3 hours on one worker, 10 to
  25 minutes on eight. Long-term: 34,000 samples and, at 1,000 km, a bulge
  of 14.7 km in the window, so M reaches 2^17 to 2^18 above 3 GHz: several
  minutes for each of the worst links. 442 of the 548 links are under
  1 GHz and take seconds. Total 1 to 3 hours on eight workers.
- **Known limit.** A transform-based march resolves loss to roughly 100 to
  140 dB below free space before round-off and the top taper dominate
  (TODO: measure against the two-screen function at high loss). Beyond
  that, the troposcatter bound must be the binding term, or the function
  must stop with an error.
- **Falsifier.** If the smoke test through the screen shows certain harm at
  a site, or the exact recount of censored violations rises by more than
  1 point, complete knife-edge physics on these profiles isn't non-inferior
  to the empirical cascade, and the repair is closed under the current
  gates.

### Cheapest decisive tests of the conclusion

1. **Done in this plan, from stored runs.** The hybrid and frontier tables
   in section 2: Bullington fails only the censored share, and on Phase 2
   the family choice moves the composite by 0.2 dB or less.
2. **B18a, the bracket test (about 3 hours, model only).** Two parameter-free
   variants of the cascade that remove the count change from each side:
   always at most two edges (1801), and three edges whenever three exist
   (1802). Smoke test, the B16a sweeps, the screen, and an exact recount of
   censored violations from the deltas. If 1801 fails the censored recount
   and 1802 shows certain harm, every count-stable repair is bracketed out.
3. **Three-screen check on T1 (half a day, only if B18a leaves doubt).** The
   coupled loss over points 172, 624 and 650 on the B16a sweep. If it's
   above 707's lower branch at heights under 8.85 m, term 4 fails for every
   complete coupled method.

### What to do about the defect

- **Recommended for this phase:** keep 707, record the defect with its
  footprint (102 row-ends on 8 paths under a 10 m height change, 75 % on
  R2-020 T1 and T2), and add two report-only fields to the model's `info`
  output so a study can see when it's near a switch: the gap between the two
  largest ν, and the loss with the runner-up as principal. No behavior
  change; parity must hold.
- **The alternative** is to change family to delta-Bullington, which is
  continuous and is ITU-R's current method. Under today's rule it's
  rejected on censored share. Whether that gate should count violations or
  weigh them by depth is Nick's decision (section 4, E2). Don't change it
  before the lockbox: a rule changed after seeing which model it favors
  isn't a test.

## 2. Where the score is: stored-run evidence

### Hybrids: 707 with another run on one class of rows

The following table shows the composite gain when 707's Phase 2 predictions
are replaced by another stored run's on rows with a given number of terrain
obstacles. Positive is better than 707.

| Rows replaced | Stock ITM | 708 (Deygout, no C) | 703 (Bullington) | Overall censored share with 703 on those rows |
| --- | --- | --- | --- | --- |
| 0 obstacles (7,207 rows) | −0.24 | −0.05 | +0.03 | 22.8 % |
| 1 obstacle (2,482) | −0.25 | −0.09 | +0.05 | 24.1 % |
| 2 obstacles (1,913) | −0.20 | −0.12 | +0.02 | 26.4 % |
| 3 obstacles (1,186) | −0.23 | −0.03 | −0.05 | 28.8 % |
| 4+ obstacles (4,017) | −1.00 | +0.10 | +0.12 | 44.2 % |
| All Phase 2 rows | −1.69 | −0.20 | +0.17 | 55.0 % |

The following table shows the same for long-term links by distance, full
and screened.

| Links replaced | 708, full / screened | 703, full / screened |
| --- | --- | --- |
| Under 100 km (72 links) | +0.37 / +0.18 | +0.41 / +0.36 |
| 100 to 300 km (335) | +0.14 / +0.12 | +0.34 / +0.02 |
| 300 km and beyond (141) | +0.33 / 0.00 | +0.62 / −0.24 |
| All long-term links | +0.83 / +0.30 | +1.37 / +0.14 |

Reading:

- **Phase 2 is flat in the diffraction family.** No class gains more than
  0.12 dB from a different published method. 707's place doesn't rest on
  Phase 2 accuracy.
- **Stock ITM's line-of-sight treatment is worse than 707's** on rows the
  terrain leaves clear (−0.24 dB), with every site worse. That counts
  against ITM's own effective heights as a lead.
- **The long-term gain of the other families is mostly in the 36 screened
  links.** Under the screened composite, the best long-term swap is worth
  0.30 dB, at the gate, and it comes with a Phase 2 loss and a censored
  failure.

### Frontier: stored runs under the current screen

The following table scores each stored run with the 36-link screen. "With
bounds" adds the 2,045 censored rows to the Phase 2 part, each scored as a
lower bound (error min(0, predicted − bound)).

| Run | Screened composite | Phase 2 cell RMS | Phase 2 with bounds | Censored violated | Mean depth of a violation | Screened composite with bounds |
| --- | --- | --- | --- | --- | --- | --- |
| 707 (best) | 9.91 | 13.25 | 12.09 | 22.8 % | 17.4 dB | 9.53 |
| 708 Deygout isolated, no C | 9.81 | 13.85 | 12.92 | 32.5 % | 18.7 dB | 9.50 |
| 703 delta-Bullington | 9.60 | 12.73 | 11.90 | 55.0 % | 14.0 dB | 9.32 |
| 502 delta-Bullington + A_fo | 9.19 | 12.85 | 12.19 | 47.2 % | 14.8 dB | 8.97 |
| 603 as 502, bounded | 9.23 | 12.74 | 12.11 | 49.6 % | 14.5 dB | 9.02 |
| Stock ITM | 11.9 | 18.32 | 16.46 | 28.0 % | 18.9 dB | — |

Reading:

- **707 isn't the best-scoring structure in the archive.** 703 is 0.31 dB
  and 502 is 0.72 dB better on the screened composite. They were rejected
  for censored share (and 502's A_fo by the B06 reviewers, for good
  reasons: no data basis, wrong height direction).
- **Scored as bounds, the censored rows change the gaps, not the order.**
  With bounds, 703 leads 707 by 0.21 dB and 502 by 0.56 dB. 707's
  violations are few and deep (17.4 dB on average; 59 % of them at VA).
  Bullington's are many and shallower.
- **703 still fails a site gate.** VA is 0.6 to 0.7 dB worse than 707 with
  or without bounds. So even under a depth-weighted rule, 703 as built
  isn't a clean replacement.

### Strata nearest the lockbox

The following table compares 707 and stock ITM on the development strata
that resemble the lockbox sets (VHF, and antennas at or under 3 m). Values
are mean / RMS error in dB on detected rows.

| Band | Lower antenna | Terrain | Rows | 707 | Stock ITM |
| --- | --- | --- | --- | --- | --- |
| Under 150 MHz (76 MHz, VA only) | At or under 3 m | Obstructed | 80 | +4.2 / 9.0 | −11.7 / 17.8 |
| Under 150 MHz | Over 3 m | Clear | 142 | +6.8 / 9.0 | +1.9 / 6.7 |
| Under 150 MHz | Over 3 m | Obstructed | 214 | +7.3 / 10.0 | +0.4 / 6.8 |
| 150 to 300 MHz | At or under 3 m | Clear | 189 | −1.0 / 8.3 | −11.2 / 14.9 |
| 150 to 300 MHz | At or under 3 m | Obstructed | 325 | +5.8 / 10.9 | −7.5 / 18.2 |
| 300 to 1000 MHz | At or under 3 m | Clear | 538 | −2.1 / 8.5 | −11.1 / 16.8 |
| 300 to 1000 MHz | At or under 3 m | Obstructed | 772 | +4.0 / 12.3 | −8.2 / 21.2 |
| Over 3 GHz | Over 3 m | Clear | 1,673 | −13.6 / 19.7 | −14.5 / 20.9 |

Reading:

- **Low antennas: 707 is far better than stock** (RMS 8 to 12 dB against 15
  to 21 dB). That's the lockbox's low-antenna set in miniature.
- **76 MHz with antennas over 3 m: 707 is worse than stock** (RMS 9.0 to
  10.0 against 6.7 to 6.8 dB, mean +7 dB). Over all 452 rows at 76 MHz: 707
  +6.7 / 9.6, stock −1.2 / 9.3, 708 +7.2 / 9.7, 703 +2.3 / 7.9. The
  correction C isn't the cause (708 has none); the multi-edge sum is. The
  lockbox's Phase 1 set is 20 to 100 MHz.
- **The largest block of error is unchanged by any run:** clear terrain,
  antennas over 3 m, above 3 GHz, 13.6 dB optimistic. It's consistent with
  clutter the 30 m terrain can't show.

## 3. Ranked plan

Ceilings are from `hm_ceiling_rev1.py parts` (screened composite 9.91 to
8.78 if every cell mean were zero: Phase 2 0.37, long-term level 0.41,
shape 0.35) and the headroom map classes.

### Batches

| Order | Batch | What | Ceiling | Screen verdict it needs | Planner's chance of a keep |
| --- | --- | --- | --- | --- | --- |
| 1 | **B18a** repair bracket (1801, 1802) | Count-stable cascades, model only | Repair: no gain needed | Not CERTAIN_HARM, and the censored recount within +1 point | 5 % (1801), under 5 % (1802) |
| 1 | **B18b** smooth-reference heights (1803 to 1805) | The heights above the smooth surface in the delta construction: P.452-18 §5.1.6.4 (also repairs the height inversion), ITM's effective heights, structural heights | Phase 2 cell means 0.37; line-of-sight class bias-only 0.11, perfect 4.18 screened | NOT_RULED_OUT with required ρ at or under 0.5; 1803 as a repair: not CERTAIN_HARM | 10 % together |
| 1 | **B18c** clutter heights on the profile (1806) | ITU-R P.1812-7 §3.2.1: add the representative clutter height (15 m for trees) to woodland samples, terminals excepted, and diffract over that surface | Terrain-clear class 0.87 at a 5 dB floor; VA cell means 0.19 | NOT_RULED_OUT and no site CERTAIN_HARM | 8 % |
| 2 | **B19**, only if B18 leaves a candidate open | Score the survivors against 707 (k = 5, 99 %, 2,000 draws; then k = 6); three reviewers for a repair | — | — | — |
| 3 | **Lockbox** | Section 5 | — | — | — |
| Later, optional | Coupled multi-screen reference | Section 1; a diagnostic, not a keep candidate | — | — | 10 % non-inferior |

Why this order:

- **Effective height no longer leads.** Rev 2 ranked it third on the size of
  the line-of-sight class. The hybrids show stock ITM's line-of-sight
  treatment, which includes ITM's effective heights, is 0.24 dB worse than
  707's on clear rows, and 707's low-antenna strata are within 2 dB of
  unbiased. The family stays in B18 because three parameter-free forms cost
  one switch and a smoke test each, and 1803 would repair a logged defect.
- **B18c is the last published vegetation method on class data.** B11
  (terminal clutter) and B17 (P.833 eq. (1)) both failed on open terminals
  in forest pixels. P.1812's surface profile puts a 15 m wall 30 m from
  those terminals, so the same failure is likely. One smoke test settles
  it. An outside study of P.1812-7 found fine-resolution clutter
  over-predicts loss (median error 13.7 dB at 10 m against 2.7 dB at 100 m).
- **Everything in B18 is model only until the screen leaves it open,** so the
  Bonferroni count stays at k = 5 unless something is worth scoring.

### Closed, in addition to rev 2's list

- Woodland loss along the ray on NLCD classes (B17). A fitted scale on that
  term isn't ruled out by the screen (best zero-correlation estimate
  +0.09 dB at a scale of 0.1; 0.3 dB needs ρ of 0.32 or more at a scale of
  0.2), but it has no source and a fitted parameter must buy 0.5 dB.
- Rounded crest (B16c), roughness estimator (B16b: no model change).
- A parameter-free continuous selector for the cascade (B16 stage 2;
  section 1).
- Height inversion "not fixable from a public source" (headroom map M14) is
  **reopened** as 1803: P.452-18 defines a second, antenna-independent set
  of smooth-surface heights in §5.1.6.4, eq. (154a)-(156). Using it for the
  diffraction reference departs from §4.2.3, so the reviewers decide whether
  it counts as sourced.

## 4. Evaluator and data PRs

The following table lists what's worth asking Nick for, in order.

| PR | What | Unlocks | Ceiling | Recommendation |
| --- | --- | --- | --- | --- |
| **E2** (eval/, report-only) | In every summary: Phase 2 cell RMS with censored rows as bounds, mean depth of a violation, and for the two real-path battery checks the number of row-ends over the limit with the paths | A decision on the censored gate from numbers; repair keeps judged defect by defect (today one worst-case figure covers both defects) | None; measurement only | **Ask now.** Changes no decision |
| **D1** (data/) antenna heights for dropped long-term rows | FRAMEWORK.md's TODO: 376 long-term rows lack antenna heights in the archive; OT/TRER 16 may list them | Up to 69 % more long-term rows; smaller few-link cells (one cell has 7 rows and a +9.0 dB mean) | No gain by itself | After the lockbox. It changes the development set, so the baseline and 707 need rescoring |
| **D2** (data/) canopy height along the Phase 2 profiles (LANDFIRE existing vegetation height) | P.1812-7 §3.2.2 surface profile, or P.833-10 §3.1 with canopy geometry | Terrain-clear class 0.87 at a 5 dB floor; VA open clear 0.42 | **Only if 1806 is NOT_RULED_OUT.** A 30 m layer can't show a road clearing, the canopy is 50 years newer than the measurements, and the outside study found canopy-height data didn't reliably beat the class default |
| **D3** refractivity gradient for ducting | PR #7 already has dN at path midpoints; P.452-18 §4.4 also needs β0 | Enhancement side of the shape part: 0.25 to 0.36 screened if perfect | Not now (rev 2 rank 4, about 5 %) |

## 5. Lockbox

**Recommendation: score it once, right after B18 closes** (and after B19 if
B18 leaves a candidate open). The framework's trigger is already met. The
remaining leads are each at or under 10 %, with ceilings near the 0.3 dB
gate, so more search is worth less than one honest held-out number.

What must be true first:

1. **Freeze.** The `best` commit and the `params_exp.m` MD5 go in the LOG.
   No model edit after that.
2. **Register the panel.** FRAMEWORK.md names `best`, stock ITM and R02.
   Add one continuous comparator, declared now: delta-Bullington with 707's
   bound and clutter settings (reference run R03 on the development set
   first; it's not a keep candidate). The lockbox can be scored only once,
   and section 2 shows the 707-or-Bullington question turns on a rule, so
   it's the comparison most worth a held-out answer. Nick's decision.
3. **Register the metrics.** The composite parts that apply to each set, RMS
   and mean by set and band, and, if a set has censored results, both the
   share violated and the RMS with bounds.
4. **Register the predictions** (planner, from section 2):
   - Low-antenna set (230 and 416 MHz, antennas under 3 m): 707 beats stock
     ITM by 4 dB RMS or more.
   - Phase 1 VHF (20 to 100 MHz): 707 doesn't beat stock ITM; 707's mean
     error is positive (too much loss) by 3 dB or more.
   - DBSG3: no prediction (location medians; a different quantity).
5. **Row inputs.** Lockbox rows have no siting flag, so the terminal clutter
   term is zero there, as on long-term rows. Profiles are built at 30 m by
   the same builder.
6. **Review.** The three-reviewer pass on the frozen model, and one Fable
   read of the whole kept chain (one keep: 707).
7. **Known-defect statement.** The principal-edge jump and its footprint,
   the height inversion, and the VHF pessimism, written before the result.

After the lockbox, this phase ends. The write-up reports the lockbox
figures as the result and the development figures as the search record.

## 6. Decisions for Nick

1. **Repair:** accept that the principal-edge jump stays in 707 through the
   lockbox, documented and flagged in `info`, unless B18a surprises?
2. **B18:** run the screen-first batch in `experiments/batches/B18_draft.md`?
3. **E2:** open the report-only evaluator PR?
4. **Lockbox:** score after B18, with a Bullington comparator (R03) in the
   panel and the predictions above registered first?
5. **Censored gate:** leave it as it is through the lockbox (recommended),
   and revisit share against depth afterward with E2's numbers?
6. **D2 (canopy height):** hold unless 1806 survives the screen?

## Sources

- ITU-R P.526-11 §4.4.2; P.526-16 §2.5, §4.1, §4.3, §4.5 (as cited in
  `itm_variant/multi_edge_diffraction_rev1.m`).
- ITU-R P.452-18 (10/2023), Word file read 2026-11-24: §4.2.3 eq. (38)-(40);
  Attachment 2 §5.1.6.2 eq. (146)-(150), §5.1.6.3 eq. (151a)-(153d),
  §5.1.6.4 eq. (154a)-(157).
- ITU-R P.1812-7 §3.2.1 and §3.2.2, as described in Châteauvert, Ethier and
  Florea, "Estimating Rural Path Loss with ITU-R P.1812-7: Impact of
  Geospatial Inputs," arXiv:2501.11708 (default heights: trees/forest 15 m).
  TODO: read the Recommendation's own text before any code.
- L. E. Vogler, NTIA TR-83-124; NTIA TR-26-580 Tables 12 and 17.
- J. H. Whitteker, "Fresnel-Kirchhoff theory applied to terrain diffraction
  problems," Radio Science 25(5), 1990. TODO: confirm volume and pages.
- Repo records: LOG entries 501, 502, 505, 603, 703, 707, 708, B06 reviewer
  pass, B16, B17; `headroom_map_rev1.md`.

## Reproduce

```bash
python3 experiments/batches/hm_frontier_rev1.py hybrid
python3 experiments/batches/hm_frontier_rev1.py frontier
python3 experiments/batches/hm_frontier_rev1.py strata
python3 experiments/batches/hm_ceiling_rev1.py parts
```
