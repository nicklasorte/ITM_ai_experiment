# Phase plan, rev 6: after B33

Planner: Claude Fable 5.2, 2026-11-26, from the prompt in
[fable_prompt_phase6_rev1.md](fable_prompt_phase6_rev1.md). Plan only: no
model edit, no model run, no scored run, no lockbox data. `best` stays 707;
k stays 9. The sources behind every statement are in
[phase6_research_rev1.md](phase6_research_rev1.md) (IDs V1 to V6 there).

Read for this plan: CLAUDE.md, FRAMEWORK.md, program.md, phase plan rev 5,
the data proposal, the post-B32 proposals (revision 2 and its red-team
appendix), `results/results.tsv`, `results/batch_stability.tsv`, the LOG
from B27 on, B27 to B34, and the write-up draft.

## 1. Stop or continue

**Stop the scored search on the frozen inputs. One out-of-sample check
that the research found is ready to run if Nick releases the data (section
2, item 1).**

1. Rev 5 already stopped the search for structural candidates, and the one
   tier it left open is now closed: calibrating 707's own constants gave no
   held-out gain (B29: 2901 and 2902 +0.00 dB, 2903 +0.11 dB screened with
   lo995 −0.06; held-out rows, five-fold cross-validation, all scored
   development rows).
2. The headroom is small: a perfect fix of every cell mean is worth at most
   1.13 dB on the screened composite (rev 5; all scored rows).
3. The one outside comparison so far showed no advantage for 707 on height
   contrasts (B32: 10 table-by-band strata of OT 75-74 paths with both
   heights measured; no stratum favored 707 and one favored stock).
   program.md's rule, three tiers in a row with no accepted change, is met
   on 707: Tier 2 and Tier 3 terms through B19 (rev 5), and Tier 1 in B29.

The stop covers scored gain candidates. It doesn't cover validation of
707, B34, the write-up or any Tier B score.

## 2. Ranked items

No new scored mechanism meets the bars. One diagnostic does (item 1).
Items 2 and 3 are the planner's notes for B34, each tied to a decision.

### 1. R4, receiver in a grove of trees: an out-of-sample check of 707 at one site (B35)

- **What:** the fifth ITS Phase 2 site, already in `data/raw/its_phase2.zip`
  and never read by the builder: 36 paths, six frequencies from 230 to
  9190 MHz, receiver heights 1 to 24 m in and just above an 18 m
  cottonwood grove, leaves on and leaves off (V1; OT/TRER 19, V2). Not
  Tier B. Neither the planner nor the red team has read a measured value.
- **Physics and source:** 707 (ITU-R P.452-18 eq. (38) to (40) with the
  P.526 cascade, and its smooth-surface change) against stock ITM at the
  top of the tower; the size of 707's terminal term (ITU-R P.2108-1
  section 3.1, eq. (2a) to (2g), V5) on the in-canopy minus top-of-tower
  contrast; the change between the leaf-on and leaf-off visits.
- **Nearest closed attempts, and the difference:** B32 (outside height
  contrasts; vertical polarization, antennas the model can't represent,
  clutter term untested by construction). R4 is horizontally polarized
  like the development data, all heights are inside ITM's range, and the
  clutter term acts. D20c and D23b asked the clutter-size question on
  development twins; B35 asks it at a new site. 711, 712, B17 and B30
  searched for vegetation terms; B35 adds no term and tests the kept one.
- **No constant is fitted or added.** 707 runs as kept, with its 15 m
  representative height, not the grove's 18 m.
- **Falsifiers:** E1 outcome B (stock closer at the top of the tower); E2
  "worse" (P.2108's height gain below 15 m fits the canopy contrast worse
  than ITM's own).
- **Headroom estimate:** not applicable; nothing is scored.
- **Population:** R4 cells that pass the exclusions. One receiver in one
  grove, 7.4 km from R1, same equipment and years: for wooded terminals in
  general n is 1, and it isn't independent of the development data.
- **What it can't show (red team):** the top of the tower is 3 to 6 m
  above the trees, so neither arm's level error is free of tree loss, and
  707 can look closer only because it adds loss. B35 fixes a reading rule
  for that case. The contrast compares P.2108's height gain below 15 m with ITM's own,
  by size, not by shape with height.
- **Decision it changes:** the write-up's wording. Whatever the outcome,
  the write-up reports it beside 707's development numbers as a one-site
  check: outcome A read as support only under B35's reading rule; B or "worse"
  reported as a failure to transfer at this site.
- **Prior:** in B35 section 4.

### 2. B34's season closure, with the report's own metadata (D34a)

B34 is registered by another planner and not run. Its first gate is the
metadata this research read in OT 75-74 (V3). The planner's notes to
whoever runs B34, not edits to it:

- **Graham:** close the period contrasts as not identifiable. The
  equipment was modified between the periods, the weather was dry in
  both, and the authors discount the wide differences (sections 6 and
  6.2). B33's Graham height-by-season interaction shouldn't be read as
  propagation.
- **Hunter Liggett:** the authors report no consistent period difference
  and frequent tuning failures (section 7.2). The report gives measured
  ground constants by receiver site (section 7.1), but a stratified test
  on them was cut after the red team: it would be post hoc on inspected
  data with four receivers, R1's constants aren't given by period, and the
  expected pattern (largest at the lowest antenna, small at UHF) already
  disagrees with B33's shifts at 10 m in both bands. Record the constants
  in D34a's metadata file and make no claim from them.
- **Percentile convention:** Tables 8 to 11 list values of cumulative
  distributions of basic transmission loss, and Table 10's values rise
  with the percentage (sections 6.2 and 7.2), so B33's reading stands.
- **Decision it changes:** B33's period shifts are reported as not
  identifiable (Graham: documented equipment change; Hunter Liggett: no
  documented cause, data-quality problems), not as a season effect.

### 3. B34's profile-rounding diagnostic, with a code-level hypothesis (D34c)

ITM truncates distance-over-spacing quotients to integer indices in
`linear_least_squares_fit` and `compute_delta_h` (V6, lines 543, 559, 592,
593). This is an untested hypothesis from reading the code. A quotient that sits on an integer flips with the last bit of the
spacing. Recommendation for D34c: test spacing-only substitution first,
and tabulate, for each discrepant row, the quotients at those lines. If
confirmed, the finding is a property of ITM as published, not of 707, and
the practical rule is the one B33 already adopted: keep profiles in
memory or in a lossless file. **Decision it changes:** whether a
tolerance of about 0.2 dB must be stated for any comparison that
round-trips profiles through text.

### Considered and excluded

| Idea | Why it doesn't meet the bars | Population of the evidence |
| --- | --- | --- |
| Tree stands as obstacles near low terminals, capped at the forest critical angle (OT 75-74 section 5.3.3) | Needs each terminal's distance to the stand; no frozen input has it; the development data has no low-antenna-in-forest stratum | Eglin, 40 paths, inspected |
| P.833-10 section 2.1 as a new scored term | Closed on the development data (B17 CERTAIN_HARM; 711, 712 rejected; B30 outcome B); needs woodland depth | All scored rows |
| Ground constants by site | Inputs are frozen (program.md). The planner expects little sensitivity at horizontal polarization, which is untested here | Development rows (all horizontally polarized) |
| A model valid below 0.5 m | No verified public source | Source review |
| X02, X04, X05, X07 to X10 (revision 2) | Each waits on a gate its own card names (map bounds, comparable statistic, survey, solver, data); none is cheaper or more decisive than R4 | Proposal cards |

## 3. Batch

[B35](../batches/B35.md): R4, with its rule, reading rule and predictions
registered before any measured value was read. It needs decision 1 below.
The prompt named B34 for this file; B34 was taken the same day.

## 4. What would change the ranking

| Evidence | What it would change | Who |
| --- | --- | --- |
| R4's outcome | How the write-up words 707's transfer to one more site | B35 or Nick |
| A Tier B score | Still the strongest test of transfer | Nick |
| A public set with low antennas in forest and documented terminal surroundings | Would make the tree-obstacle mechanism testable | Public sources |
| Ofcom data (D2) | Frequency contrasts on outside paths | Nick clears the human check |

## 5. Decisions for Nick

1. **What to do with R4.** It is the only untouched public set found that
   sits inside ITM's input range, and any one-shot use spends it, whoever
   runs it. FRAMEWORK.md's trigger for the human Tier B run has fired and
   that run is still pending. Options:
   - (a) Run B35 as registered, agent-run. The rule and reading rule are
     fixed, and no value has been read.
   - (b) Hold R4 as a human-run set beside Tier B, scored once by you.
     The red team prefers this: it keeps the agent away from the last
     untouched in-range set.
   - (c) Leave it unused.
   The planner's view: (b) if you plan to run Tier B yourself soon, since
   the two runs fit together; otherwise (a), because a registered run that
   happens is worth more than a held set that waits. Also say whether your
   working paper already scored R4; if so it is a validation set, as the
   Tier B caveat says. **Status, 2026-11-28: open.** Checked in
   `matlab_itm`: its Phase 2 comparison (`docs/model_comparison/
   compare_its_phase2_rev1.m`) leaves R4 out because R4 has no profiles,
   so those scripts never scored it. Whether any other work of Nick's did
   is still his to say.
2. **Accept the stop** for scored candidates, as in rev 5? Recommended:
   yes. **Status: accepted by Nick, 2026-11-28** ("Do what you
   recommend", after the planner recommended yes).
3. **Write-up:** after B35 and B34, finish the draft with the outside
   tests in one section. It still needs your read before it leaves the
   repo.

## Not done

- No measured R4 value was read, so B35's counts of usable cells are
  unknown; its stop conditions and drop rule cover that.
- OT/TRER 19 was read through a fetched summary of the first 100,000 of
  191,827 characters (sections 1 to 5). One statement in that summary
  contradicts the path coordinates (research notes, Q6), so the report
  needs a page-level reread before B35's results are written up. Its
  profile section and its appendix on polarization tests weren't read.
- The NTIA ITM source, TN 101 and TR-82-100 weren't opened for the
  truncation question; the port was.
- Sources marked U in the research notes weren't verified and carry no
  weight here.
- B34 wasn't edited or run.
- Whether matlab_itm's own comparison scripts ever read R4 wasn't checked
  (that repo wasn't available to the planner or the red team).

## Red-team disposition

Findings are in [phase6_red_team_rev1.md](phase6_red_team_rev1.md).

### Round 1

| # | Finding | Disposition | Reason and what changed |
| --- | --- | --- | --- |
| 1 | E2: censoring selects on the outcome; group mean under-specified; no constant control | Accepted, control partly | Group values are now medians over fixed heights with censored cells ranked highest; a group is dropped when half or more of its cells are censored (round 2 adds two more drop conditions), and drops are counted. The model uses the same heights. A constant control can't differ from the term on a median contrast, so B35 now says E2 tests the term's size, not its shape, and reports height slopes separately. |
| 2 | E1 doesn't isolate the diffraction change; 707 can win by adding loss; the stated reason was wrong in code | Accepted | E1 is now "level at the top of the tower", primary on leaves-off cells, with a reading rule fixed in advance for "closer by added loss". The prediction's reason is corrected. |
| 3 | One receiver, one grove; not independent of R1 | Accepted | Stated as a limit in B35 section 1 and in the plan; the title and the "decision it changes" no longer say "outside test of 707" without "one site". |
| 4 | Unregistered confounds: grove depth by bearing, antenna patterns, leaf state mixed with season, shaft wording, profile claim; fetch summary unreliable on sectors | Accepted | Bearing sector split registered (12 and 24 paths); horns noted at the two top frequencies; E3 renamed "change between visits" with an in-canopy minus top-of-tower difference; wording fixed; the summary's conflict recorded under Not done. |
| 5 | Planner-chosen values unlabeled; 60 m tolerance; street width; "upper limit" | Accepted | Values listed as planner-chosen; the 60 m allowance removed (2 % for every path, no widening); street width labeled as inherited; P.833 A_m kept "for scale only". |
| 6 | Stop supported; an agent run spends the only untouched in-range set; option (b) preserves more | Partly accepted | The stop stands. Decision 1 now sets out the cost and the red team's preference. The planner doesn't accept that a human run spends the set less than an agent run; the difference is who is trusted to hold it. |
| 7 | Hunter Liggett stratification is post hoc and already strained; R1 "didn't change" is an inference | Accepted | Cut from item 2; research notes corrected. Graham closure kept. |
| 8 | Blinding is by convention only | Accepted | B35 section 1 says so; the worker must not print values before the predictions are pushed. |
| 9 | Citation flags: Table 7; VHF-only time variability; "vertical polarization" not on page 70; P.833 absences unconfirmed; line 239; line range; builder line numbers; duplicate pars row | Accepted | Each corrected in the research notes and B35. |
| 10 | 707-C arm, R4 unused, no duplicate | No change needed | |
| 11 | Worker gaps: duplicate pars row, height subset, 999 code, cell definition, ties | Accepted | Each specified in B35 sections 2, 3 and 5. |

### Round 2

| # | Finding | Disposition | Reason and what changed |
| --- | --- | --- | --- |
| 1 | E2's text was false in code: 707-C replaces ITM's height gain below 15 m with the P.2108 term | Accepted | B35 now describes both arms from the code (lines 89 to 94, 208 to 212) and labels D2 as P.2108's height gain against ITM's own, not term against none. Plan wording follows. |
| 2 | Header said two rounds before round 2 existed | Accepted | True once this round's fixes went in; the header says so. |
| 3 | E1 reading rule: no margin, pooled signs, "bracket zero" case, floor case | Accepted | Rule restated on two numbers with a 1 dB margin and no undefined case; signed errors reported by frequency; a frequency under the floor leaves pooled D1. |
| 4 | Censored cell not always above uncensored ones (bound is 5 dB conservative); missing-height drops and the 20 % rule | Accepted | Extra drop condition added; the two kinds of drop are counted separately and both count toward the 20 % rule. The strict "no height missing" rule stays, and its cost in cells is unknown until step 6. |
| 5 | Bootstrap not pinned for an independent rerun | Accepted | Generator, seeds and draw order fixed in B35. |
| 6 | Planner-chosen list incomplete; 13 against 14 paths | Accepted | List extended; count corrected. |
| 7 | Smoke check, builder lines, bearing count, distance to R1, shared transmitter position | No change needed | Confirmed by the red team. |

### Still open after two rounds

- Nick's decision 1 on R4.
- A page-level reread of OT/TRER 19 (the fetched summary has one known
  error).
- Whether matlab_itm's scripts or Nick's working paper ever scored R4.
- How many cells the strict missing-height rule costs; known only at
  B35 step 6.
- The red team's point that an agent run spends the last untouched
  in-range set stands as a disagreement on who should hold it; Nick
  decides.
