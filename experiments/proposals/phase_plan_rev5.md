# Phase plan, rev 5: after B26

Planner: Claude Fable 5.2, 2026-11-25. Requested by Nick (planner prompt in
[fable_prompt_phase5_rev1.md](fable_prompt_phase5_rev1.md)). Plan only: no model
edits, no scored runs, no lockbox data. `best` stays 707, frozen at 2baa02b.

Read for this plan: CLAUDE.md, FRAMEWORK.md, program.md, phase plan rev 4, the
post-B20 plan, `results/results.tsv`, `results/archive_rev1.txt`, the LOG from
B11 to B26, the headroom map, and B18, B20, B21 and B23 to B26 (B22 is
reserved and has no file).

## 1. Stop or continue

**Stop the scored gain search on the frozen inputs. Keep one gated diagnostic
line (section 2) and wait for the lockbox.**

1. `results/results.tsv` shows five candidates scored against 707 and
   rejected (711, 712, 1301, 1804, 1901; each on all scored Phase 2 and
   long-term rows). The LOG's Bonferroni count is k = 6; the results table
   doesn't identify the sixth. The
   last two scored batches, B18 and B19, gave no keep and no repair, which is
   rev 4's stopping rule and FRAMEWORK.md's lockbox trigger.
2. B20 to B26 emptied the rev 4 queue with no candidate (LOG, "Phase status
   after B24"; B21, B25, B26).
3. A perfect fix of every cell-mean error is worth at most 1.13 dB on the
   screened composite (9.91 to 8.78; all scored rows;
   `hm_ceiling_rev1.py parts`, rerun today). The rest is spread inside cells.

Two limits on that decision:

- program.md's own rule ("three tiers in a row produce no accepted change") is
  met for Tier 2 on 707: every candidate since 707 is logged as tier 2,
  including the catalog's Tier 3 terms (clutter at open terminals, 711 and
  712; path vegetation, B17, screened out). For Tier 1 it's met only on stock
  ITM (R02, 0.1 dB; all scored rows). Nobody has calibrated 707's own constants
  (FRAMEWORK.md roadmap, phase 3). That needs fitted parameters, which this
  plan's bars exclude. Section 5 lists it as a decision for Nick.
- The stop covers gain candidates. It doesn't cover the lockbox, decision 2
  (censored gate), B22's 1801 re-score, or the write-up. Those wait on Nick.

## 2. Mechanisms

**One mechanism meets the bars, with a low prior. No other does.**

### M1. Height-gain terms on the knife-edge legs (rank 1, gated)

- **Physics:** the source says G "represents the effects of reflection" from
  terrain between an antenna and its horizon, for an isolated knife edge that
  forms a common horizon for both antennas. Planner's inference, not the
  source's words: the reflection reduces the field at a low antenna, so the
  loss gains a height dependence at each end.
- **Source:** P. L. Rice, A. G. Longley, K. A. Norton and A. P. Barsis,
  "Transmission Loss Predictions for Tropospheric Communication Circuits," NBS
  Technical Note 101, vol. 1 (rev. 1967), section 7.2:
  - eq. (7.5): A = A(v, 0) − G(h̄1) − G(h̄2);
  - eq. (7.6a) and (7.6b): h̄ = 2.2325 B²(K, b°) (f²/a)^(1/3) h_e, with
    a1 = d_Lt²/(2 h_te) and a2 = d_Lr²/(2 h_re);
  - the conditions: a single knife edge that is the horizon of both
    antennas; more than half of the terrain between an antenna and its
    horizon cuts the first Fresnel ellipse; and, for each G term, terrain
    near the midpoint between the antenna and its horizon is closer to the
    ray than 0.5 √(λ d_L) (distances in km). The source says definite
    criteria aren't available.
  - Read from the 2022 re-typeset copy of volume 1 (first 100,000 characters,
    which cover sections 5 to 7). Not read: figure 7.2 (the curve G(h̄)),
    B(K, b°) in section 8.1, and annex III. **TODO before any code:** a
    closed form for G(h̄) from the source, checked against figure 7.2.
- **Nearest closed attempts, and the difference:**
  - 1804 (ITM effective heights in the smooth reference): changed the surface
    under A_s and L_bs. M1 leaves the surface alone and adds terms to the
    actual-path knife-edge loss, gated by the source's own foreground test.
  - 1803 and B21 (other surfaces), B25 (other kernel): same distinction.
  - Stock ITM: its diffraction terms depend on antenna height, so stock is
    the nearest available proxy. Whether stock's terms match eq. (7.5) isn't
    checked. On B23's height pairs stock's |e| is larger than 707's
    (R1 open blocked-blocked pairs, 29 bases: +3.16 dB [1.98, 4.19]). B23
    didn't report stock's signed error, so it's unknown whether stock
    overshoots or undershoots. Stage A finds out.
- **No fitted constant:** the constants are the source's. The foreground test
  is the source's, used as written.
- **Population it acts on:** rows where one knife edge is the common horizon
  and the terminal foreground meets the source's tests. The count of such
  rows is unknown until stage B. Evidence so far: R1 open blocked-blocked height pairs (149 pairs,
  29 bases, one fixed receiver): 707's contrast error +5.64 dB [3.81, 7.49].
- **Falsifiers, in order:**
  1. Stage A (B27, measurements, no model code): 707 and stock don't bracket
     the measured contrast on that population, or the best blend of the two
     cuts the mean |e| by less than 1 dB. Then close M1.
  2. Stage B (planner writes the code; model only): `hm_screen_rev1.py` says
     CANNOT_PASS or CERTAIN_HARM. Then close M1.
  3. Stage C (one scored run, k = 7): the acceptance rule.
- **Headroom method:** stage B's per-row change through `b17_smoke_rev1.m`,
  then `hm_screen_rev1.py --parent experiments/707-cascaded-isolated-clutter-at-r
  --delta <csv>`, with and without `--floor`.
- **Prior (stated before any result):** stage A outcome A 40 %; stage B open
  given A 25 %; a keep given both under 20 %. Reasons for the low prior:
  - 707 is already pessimistic on these rows (R1 open obstructed rows, mean
    error +7.5 dB, 2,036 rows; R3 +6.4 dB, 1,144 rows; headroom map). If G
    is negative for low antennas, M1 adds loss where 707 has too much. The
    sign of G comes from the reviewer's low-resolution look at figure 7.2,
    not from a formula.
  - The repair route is closed to it: 707's `height_gain_real` failure
    (27.0 dB) comes from the principal-edge jump, which M1 doesn't touch.

### Considered and excluded

| Idea | Why it doesn't meet the bars | Population of the evidence |
| --- | --- | --- |
| Another smooth surface | Every public construction is 707's, 1803 or 1804 (B21) | Source texts |
| Another smooth-path kernel | B25: screened gain at most +0.11 dB | All scored rows |
| Smooth-reference reflection (N01) | B25's kernel has no reflection and rises the same way | One row: R1-005-T5_O, 230 MHz |
| Multi-edge forms (Bullington, Deygout, Epstein-Peterson, cylinders, Vogler) | Scored or screened: R03 screened +0.27 dB [−0.14, +0.73] with 58 % censored violations; the rest in B01 to B09, B16, B18 | All scored rows |
| Sub-path (Fresnel) loss on clear paths | D04: 2 to 3 dB against 10 to 28 dB errors, and the VA sign is reversed | VA and R2 open clear rows |
| Vegetation or canopy | 711, 712 rejected; B17 and 1806 CERTAIN_HARM; the fitting P.833 forms need canopy height, which isn't an input | All scored rows |
| Troposcatter or time variability | B13, B14, B15, B19 closed | Long-term rows |
| Terrain-height uncertainty in the knife-edge loss | No public vertical accuracy for the profiles (B16c), so its one constant has no source | 12 survey profiles |
| Calibrating 707's constants | Needs fitted parameters; excluded by this plan's bars (section 5) | Not run |

## 3. Batch

[B27](../batches/B27.md): stage A of M1. One script on B23's frozen pair
table, no model code, no scored run, k stays 6. The worker can run it as
written. Stages B and C are outlined there and need a planner.

## 4. What evidence would change the ranking

| Evidence | What it would change | Who |
| --- | --- | --- |
| Lockbox score, then decision 2 | Whether 707's gain transfers; whether 1801 and the forms without C (702, 708) can be kept. This matters more than any item in section 2. | Nick |
| Height and frequency contrasts with documented calibration at more than one fixed terminal per site (post-B20 plan N10) | B23's strict cohort is R1, one receiver. A second strict site would turn "inconclusive" into a result, for or against M1. | Nick (approval), then a protocol |
| Canopy height along the profiles (public, dated) | Reopens vegetation with the P.833 forms that fit an open terminal | Nick (data decision) |
| Documented vertical accuracy of the Phase 2 profiles | Sources the constant for terrain-uncertainty averaging | Nick (data) |
| A new P.452, P.1812 or P.2001 revision, or an NTIA report, with a different surface | Reopens R1 (B21) | Public sources |

## 5. Decisions for Nick

1. **Accept the stop** for gain candidates on the frozen inputs, with B27 as
   the one open line? Recommended: yes.
2. **Tier 1 on 707's structure** (FRAMEWORK.md roadmap phase 3: fit 707's
   constants in cross-validation, 0.5 dB per parameter). It's the one tier
   never run on 707. It adds fitted parameters, and R01 showed that a free
   fit buys score with censored violations (55.9 %). Recommended: decide after
   the lockbox; if yes, with the censored and continuity gates inside the
   objective, as R02 did.
3. **Start the write-up** (roadmap phase 5) once the lockbox is scored.
   Results that leave the repo need your read first.

## Not done

- No model code and no run on measurements. B27's script was tested on
  synthetic pairs only; its dry run reproduced B23's published cell (+5.64 dB,
  29 bases) and computed nothing new.
- TN 101 section 8.1 and annex III weren't read. Figure 7.2 was seen only by
  the reviewer, at low resolution. Volume 1 beyond
  the first 100,000 characters wasn't read.
- The prior in section 2 is a judgment, not a computed number.
- No independent check that the list of closed attempts is complete beyond
  `results/results.tsv`, the archive, the LOG from B11 on, and B18 to B26.

## Sources

- NBS Technical Note 101, vol. 1, sections 5.2, 6.3, 7.1 and 7.2:
  <https://its.ntia.gov/publications/details?pub=2726>; re-typeset copy read:
  <https://udel.edu/~mm/itm/lr1.pdf>.
- Repo records: `results/results.tsv`, `results/archive_rev1.txt`,
  `experiments/LOG.md`, `experiments/batches/B18.md`, `B20.md`, `B21.md` and
  `B23.md` to `B26.md`,
  `experiments/proposals/headroom_map_rev1.md`,
  `experiments/D23a-height-contrasts/site_stats_rev1.csv`.
