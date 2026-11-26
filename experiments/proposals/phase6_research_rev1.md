# Phase 6 research notes: sources read for phase plan rev 6

Planner: Claude Fable 5.2, 2026-11-26. Written for
[phase_plan_rev6.md](phase_plan_rev6.md), from the prompt in
[fable_prompt_phase6_rev1.md](fable_prompt_phase6_rev1.md). No model run, no
scored run, no lockbox data. Sources are paraphrased.

How to read this file: every statement about a source carries a register
ID (V = read in the source itself, U = seen only in a search result or an
abstract). The plan relies on V sources only.

## Main findings

1. **An unused public measurement set is already in the repo's raw
   archive.** `data/raw/its_phase2.zip` holds a fifth Phase 2 site, R4, "from
   within a woods" (V1, V2): one receiver site in a grove of cottonwood
   trees about 18 m high, 36 open transmitter sites, six frequencies from
   230 to 9190 MHz, receiver heights from 1 to 24 m in 1 m steps, measured once with leaves
   on and once with leaves off. It is one site, 7.4 km from R1. The builder reads only R1,
   R2, R3 and VA, and nothing else in the repo refers to R4. It isn't a
   Tier B set. This planner read its description, parameter and path
   files, and the height, season and path-name columns of its data file,
   but no measured value.
2. **OT Report 75-74 documents why its period comparisons can't carry a
   propagation claim** (V3): the equipment was modified between the two
   Graham Mountain periods, the weather was dry in both, and the authors
   judged that the few wide period differences probably weren't real
   changes in propagation. At Hunter Liggett the authors found no
   consistent difference between periods and frequent tuning failures.
3. **OT 75-74 also explains B32's large under-prediction at Eglin** (V3):
   with terrain-only profiles many Eglin paths are within line of sight,
   but trees block them. The authors got a median difference near zero at
   VHF only after treating nearby tree stands as obstacles and capping the
   horizon elevation angle at the critical angle of a forest slab.
4. **The 0.2 dB jumps under profile rounding have a likely cause in the
   code** (V6): ITM's terrain analysis truncates quotients of a distance
   by the profile spacing to an integer index, in several places. A
   quotient that sits on an integer flips with a change in the last bit of
   the spacing.

## Q1. Low antennas and near-ground propagation at VHF and UHF

- OT 75-74 (V3) is the main public measurement source for antennas at
  0.35 m in these bands. Its findings, on its own 210 paths: time
  variability on a short path is small (within-hour variance well under
  1 dB; at VHF, day-to-day changes usually under 5 or 6 dB, with somewhat
  more at UHF that the authors think may be instrumental), but path-to-path
  differences of 40 to 45 dB at one path length are common, which the
  authors attribute to small foreground obstacles partly blocking launch
  and reception (section 8).
- The authors conclude that the Longley-Rice area model, with an allowance
  for forest, is adequate for antennas at or near ground level, and that
  the point-to-point methods of Rice et al. (1967) estimate too much loss
  on short diffraction paths over smooth terrain (sections 5.3.1, 7 and 8).
- They cite an empirical correction from earlier low-antenna work, an
  added loss of 10 log10(d_Ls/d_L) when a horizon distance d_L is under a
  third of the smooth-earth distance d_Ls. They don't apply it at Eglin,
  because it was built for terrain obstacles, not woods (section 5.3.3).
  Its original source wasn't opened here: the report that carries it
  compares models on Tier B sets.
- Ground constants matter most for the lowest antennas at VHF (the
  antennas were vertical monopoles, Appendix A): the authors cite an earlier report in which
  changing relative permittivity from 4 to 24 lowers loss by about 15 dB
  at 170 MHz between zero-height antennas over smooth earth, and by more
  than 10 dB with one antenna at 1 m; the sensitivity is much smaller at
  the higher frequency (section 7). That cited report wasn't read (U5).
- NTIA TR-07-449 (U1, abstract only) sets out needs for a short-range
  model: 1 m to 2 km, 150 to 3000 MHz, antennas 1 to 3 m, including the
  surface wave and mutual coupling.
- **Is there a published model valid below 0.5 m to use as a reference?**
  None was verified. The classical surface-wave theory (Norton; Bullington)
  wasn't read here (U6). ITM's 0.5 m limit stands (B32).

## Q2. Vegetation with a terminal in or under the canopy

- **ITU-R P.833-10** (V4), section 2.1: for one terminal in woodland,
  A_ev = A_m [1 − exp(−d γ / A_m)] (eq. 1), in excess of every other
  mechanism, with A_m = A_1 f^α (eq. 2, f in MHz). Published constants:
  A_1 = 0.18 dB, α = 0.752 (Rio de Janeiro, 900 to 1800 MHz, trees 15 m,
  antenna 2.4 m); 1.15 dB and 0.43 (Mulhouse, 900 to 2200 MHz, trees 15 m,
  antenna 1.6 m); 1.37 dB and 0.42 (St. Petersburg, 105.9 to 2117.5 MHz,
  trees 12 to 16 m, antenna 1.5 m). The Recommendation says A_m depends on
  the species and density of the vegetation, the antenna pattern, and the
  distance between the antenna and the top of the vegetation, and gives no
  rule for them. In the fetched text, section 2.1 covers one terminal in
  woodland and section 2.2 covers both terminals outside; no model for
  both terminals inside, and no lateral wave, was found (the red team
  didn't confirm this absence independently).
- **Slab models and the lateral wave** (V3 for the description; Tamir 1967
  itself U2): OT 75-74 describes the forest as a lossy dielectric slab;
  rays leaving near the critical angle, sin θ_c = ε^(−1/2), excite a
  lateral wave along the tree tops. With ε = 1.012 the critical angle is
  about 110 mrad from the horizontal. The slab picture weakens above about
  100 MHz, where trees act more as separate scatterers.
- **What OT 75-74 did at Eglin** (V3, sections 5.3.2 and 5.3.3): the area
  model's medians were low by about 7, 7 and 3 dB at 172 MHz and 15, 15 and
  11 dB at 410 MHz (10, 3 and 0.3 m receivers). For point-to-point use the
  authors estimated each terminal's distance to a thick stand of trees and
  a horizon slightly below the tree tops, then capped the elevation angle
  at 110 mrad. The median difference was then zero at VHF and about 3 dB
  low at UHF. They quote absorption rates of about 0.1 and 0.2 dB/m at 172
  and 410 MHz for deciduous trees in leaf (from Rice 1971, not read, U7),
  and they reject a clearing-depth formula (Head 1960) because it has no
  antenna-height dependence, while the data show more loss at lower
  heights behind the same woods.
- **Which formulation uses only published constants and fits Eglin?** None
  can be run from the repo's inputs. The authors' own method needs each
  terminal's distance to the tree stand, which the report doesn't
  tabulate. P.833's one-terminal model needs the depth of woodland and
  doesn't cover two terminals in forest. Eglin is already inspected, so it
  could at most illustrate, not test.
- **Where a test is possible:** R4 (Q6). Its receiver moves from inside an 18 m canopy to a few meters above it on each path, in both leaf states, which is the
  P.833 section 2.1 geometry and the geometry of 707's own terminal term
  (ITU-R P.2108-1 section 3.1, already in `itm_variant/`).

## Q3. Seasonal change on fixed paths

- P.833-10 (V4): near 1 GHz, specific attenuation through trees in leaf is
  about 20 % higher than through leafless trees; the Mulhouse measurements
  showed seasonal variations of 2 dB at 900 MHz and 8.5 dB at 2200 MHz.
- OT 75-74 (V3): the program planned wet and dry season visits. Eglin was
  measured once. At Graham the weather was warm and dry in both periods.
  At Hunter Liggett both periods had practically no rain; the measured
  ground constants differ by period at three of four receiver sites
  (median relative permittivity 17, 11 and 16 in February against 10, 8
  and 11 in June at R2, R3 and R4; for R1 the report gives one range, 3.3
  to 4.8 with median 4, not split by period; conductivity medians
  100, 30 and 60 mS/m with a wide range).
- A 2024 ITS paper reports summer and winter clutter loss medians a few dB
  apart at 3.2 and 3.5 GHz in a Boulder suburb (U3, table seen in a search
  excerpt only).
- **Does any source explain opposite-sign height responses by band (B33,
  Graham)?** No. The one source that speaks to those data, OT 75-74,
  points to the equipment: sudden level drops of 10 to 20 dB on single
  antennas, and an equipment change between periods.

## Q4. OT 75-74: equipment, calibration, periods (the metadata audit)

All from V3.

| Item | What the report says | Section |
| --- | --- | --- |
| Sponsor and operator | ARPA; measured by a contractor for the U.S. Army Electronic Proving Ground; analyzed at ITS | 2 |
| Transmitters | 10 packages, about 2 W, 172.5 and 410.5 MHz nominal; quarter-wave monopoles over four ground wires, feed point about 35 cm above ground | App. A |
| Receivers | Same antenna type at 10 m, 3 m and on the ground, one per frequency; spectrum analyzer under computer control | App. A |
| Calibration | Spectrum analyzer calibrated each recording day with a signal generator; loss tolerance about 140 dB at first and about 160 dB after a pre-amplifier was added | App. A |
| Conversion | Recorded power converted to basic transmission loss with corrections for transmitter power, antenna gains and line losses | 2 |
| Percentages | Tables 8 to 11 give the 10, 50 and 90 % values of the cumulative distributions of basic transmission loss; in Table 10 the values rise with the percentage | 6.2, 7.2, Table 10 |
| Data problems | Readings on the skirts of the signal; bandwidth widened from 1 to 3 kHz after Eglin; some erroneous values certain; tuning failures frequent at Hunter Liggett; sudden changes marked questionable | 3, 7.2 |
| Eglin | One visit only; dry season planned for November | 1 |
| Graham periods | Sep-Oct: much of the recording below sensitivity, 25 to 30 measurements at R3 and R4. April: after the equipment was modified, more than 50 per site. Weather warm and very dry in both. Authors: differences of 2 to 5 dB between periods, and the few wide differences probably aren't real changes in propagation | 6, 6.2 |
| Graham R5 | Transmitters moved to a second trail for Oct 16 and 17; not used in April | 6.1 |
| Hunter Liggett periods | Jan-Feb (expected rainy) and May-Jun (expected dry); practically no rain in either. Authors: no consistent difference between periods, large inconsistencies | 7, 7.2 |
| Hunter Liggett T7 | Moved after the first measurements to R1 and R2 | 7.1 |
| Ground constants | Graham: relative permittivity 4 to 15, selected 5 and 10 mS/m. Hunter Liggett: by site and period as in Q3; predictions used 10 and 60 mS/m | 6.1, 7.1, 7 |

Consequences for the repo:

- **B33's Graham results (season shift and the opposite-sign height
  interaction) can't be read as propagation.** The equipment changed
  between the periods and the authors discount the differences.
- **B33's Hunter Liggett shift has one documented candidate cause that ITM
  represents, ground constants, but the fit is poor.** The report says the
  sensitivity is largest at the lowest antenna and much smaller at UHF,
  while B33's resolved shifts are at 10 m in both bands; the authors saw
  no consistent period difference; and R1's constants aren't given by
  period, so it isn't a clean control. The red team cut a proposed
  stratification on this, and the plan drops it.
- Later ITS reports that reuse or correct this data: none found (searched
  the ITS publication pages; not exhaustive).

## Q5. ITM's discontinuities under tiny profile changes

Read in the repo's port, `itm_variant/itm_p2p_core_exp.m`, which follows
the NTIA code function by function (V6). The NTIA source itself, TN 101
and TR-82-100 weren't opened for this question (U8).

- `linear_least_squares_fit`: `i_start = fix(fdim(d_start / pfl(2), 0))`
  and `i_end = np − fix(fdim(np, d_end / pfl(2)))` (lines 592 and 593).
  The fit window for the effective heights starts and ends at a truncated
  quotient of a distance by the spacing.
- `compute_delta_h`: `x_start = d_start / xi`, `i = fix(x_start)` and
  `p10 = fix(0.1 (x_end − x_start + 8))` (lines 543 and 559).
- Line 239: `q = fix(d_m − d_hzn(1) − d_hzn(2))` truncates a distance in
  meters, not a spacing quotient; it's listed for completeness.
- The callers pass distances such as a tenth of a horizon distance. A
  horizon distance is a whole number of spacings, so when the horizon
  index is a multiple of 10 the quotient is an integer up to rounding, and
  a change in the last bit of the spacing moves the truncation by one
  sample. B33 measured a spacing difference of 3.6e-14 m between the CSV
  and the fresh profile on the path it examined.
- **Hypothesis for B34's D34c (untested):** the 12 discrepant rows are
  rows where such a quotient lands on an integer. It predicts that
  substituting only the spacing, not the elevations, reproduces the jump.
  The port follows the NTIA code, and B33 saw the jump in stock ITM as
  well as 707, so it isn't a 707 defect; the NTIA source itself wasn't
  opened to confirm the same truncations there.

## Q6. Public, non-lockbox measurement sets

| Set | What it has | Access | Status |
| --- | --- | --- | --- |
| **ITS Phase 2, R4, grove of trees** (V1, V2) | 36 paths, 0.5 to 50 km; 230, 410, 910, 1846, 4595, 9190 MHz; horizontal polarization; transmitter 6.6 or 7.3 m; receiver 1 to 24 m in 1 m steps in and above an 18 m cottonwood grove; leaves on (Aug-Sep 1966) and off (Nov 1966 to Mar 1967) on the same paths; terminal coordinates; 1,728 data lines of six frequencies each | In the repo: `data/raw/its_phase2.zip` (`r4pars.txt`, `r4path.txt`, `r4data.txt`); report public | No surveyed profile files, so profiles must be sampled as for the long-term paths. Unused |
| OT 75-74 (V3) | 210 paths, used in B31 to B33 | In the repo | Inspected |
| Hufford et al. 1982, wideband measurements in forests (U4) | Forest paths, wideband | Public report | Title and abstract page only; contents not verified |
| Tan and Stratton 2000, VHF path loss in a deciduous forest (U9) | 410 to 4700 m paths, several polarizations | Public report | Search excerpt only |
| ITS mobile clutter measurements at 1.7 GHz (U10) | Drive tests | Papers public; data access not established | Not verified |
| Ofcom frequency contrasts (data proposal D2) | | Blocked by a human check only Nick can clear | Parked |
| ITS Phase 1 VHF, ITS low antenna (ERL 134), DBSG3 | | Listed on the ITS legacy data page | **Tier B: not opened** |

R4 caveats, from V1 and V2: one receiver site; 7.4 km from R1, on the
same plains, with the same equipment and years, and one transmitter
position shared with an R1 path, so it isn't independent of the
development data; all transmitter sites open; the grove's depth isn't
given in numbers (the tower stands near the edge of the largest tree
cluster, and 235° true is the direction of greatest tree depth; 12 of the
36 paths bear within 30° of it); foliage was removed where the antennas
travel; the two highest frequencies used horn antennas of about 12.5°
beamwidth (the red team's reading of Table 1). The fetched summary of the
report also said no transmitter sites lie between about 210° and 40°
true, which the coordinates contradict (14 paths bear 220° to 270°), so
that summary isn't fully reliable, and the report should be reread at the
page level before B35's results are written up. Whether Nick's
working paper ever scored R4 is unknown to this planner.

## Q7. Mechanisms ITM omits, with a public source

- **Tree stands as obstacles near low terminals, with a critical-angle
  cap** (V3, section 5.3.3). Nearest closed attempts: B18 (representative
  clutter heights on the profile, not at the terminals), 711 and 712
  (P.2108 at open terminals by land-cover class), B17 (P.833 along the
  rays), B30 (canopy height against 707's errors). It differs in putting
  the obstacle at a terminal inside forest. It needs each terminal's
  distance to the stand, which no frozen input has, and the development
  data has no low-antenna-in-forest stratum, so it can't be scored there.
- **A terminal inside a canopy of known height** (V4 section 2.1; 707's
  P.2108 term). Not new physics for the repo; new is a place to test it
  out of sample (R4).
- Nothing else met the bar of a named mechanism with a verified public
  source that differs from every closed attempt.

## Source register

### Verified (read in the source)

| ID | Source | What was read | Supports |
| --- | --- | --- | --- |
| V1 | ITS legacy radio propagation data, Phase 2 archive `phase_2.zip`, as `data/raw/its_phase2.zip`; <https://its.ntia.gov/data/legacy-radio-propagation-data/> | `phase_2.txt` in full; `r4pars.txt` in full; `r4path.txt` (first rows and line count); `r4data.txt` header, and its path, season and height columns only | R4 exists, its layout, counts, coordinates, heights and seasons |
| V2 | McQuate, Harman and McClanahan, OT/TRER 19, 1971, "Tabulations of propagation data over irregular terrain in the 230 to 9200 MHz frequency range, Part 4: Receiver site in grove of trees"; <https://its.ntia.gov/publications/download/OT-TRER-19.pdf> | Sections 1 to 5 (site, equipment, procedure, presentation), through a fetch limited to those sections; the first 100,000 of 191,827 characters; no data tabulation read | Grove, tree height, tower, heights, frequencies, polarization, seasons, open transmitter sites |
| V3 | Longley and Hufford, OT Report 75-74, 1975; <https://its.ntia.gov/publications/download/OT-75-74.pdf> (SHA-256 in B31) | Printed pages 1 to 4, 38 to 45, 58 to 62 (with Table 10), 70 to 73 and A1 to A3, as page images; the red team rechecked most of them | Q1 to Q4 |
| V4 | Recommendation ITU-R P.833-10 (09/2021); <https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.833-10-202109-I!!PDF-E.pdf> | Section 2.1, eq. (1) and (2) and the listed constants, through a fetch of the PDF text; Figure 2 values not readable | Q2, Q3 |
| V5 | Recommendation ITU-R P.2108-1 section 3.1, as implemented and checked against NTIA test vectors in `itm_variant/p2108_height_gain_rev1.m` | The function header and equations in the repo; the Recommendation itself wasn't reopened today | 707's terminal term |
| V6 | `itm_variant/itm_p2p_core_exp.m` (port of NTIA ITM v1.4 at matlab_itm 9bd6a4e) | Lines 84 to 95, 208 to 212, 239, 536 to 596, 1533 to 1582 | Q5; how 707 picks the clutter end |

### Unverified (search result, abstract or citation only; not relied on)

| ID | Source | Seen |
| --- | --- | --- |
| U1 | DeMinco, NTIA TR-07-449, 2007 | Abstract page |
| U2 | Tamir, IEEE Trans. AP-15, 1967; Dence and Tamir, ECOM-2940; Tamir, ECOM-3443 | Abstracts and contents pages |
| U3 | Kozma et al., URSI 2024, seasonal clutter loss | Search excerpt |
| U4 | Hufford, Hubbard, Pratt, Adams, Paulson and Sass, CECOM-82-CS029-F, 1982 | Title and abstract page |
| U5 | Longley 1972, cited in OT 75-74 section 7 | Citation only |
| U6 | Norton; Bullington (surface wave, minimum effective antenna height) | Not opened |
| U7 | Rice 1971; Head 1960 | Cited in OT 75-74 only |
| U8 | NTIA ITM C++ source; NBS TN 101; NTIA TR-82-100 (for Q5) | Not opened today (a fetch of the NTIA repository needed an approval nobody was there to give) |
| U9 | Tan and Stratton, ARL-TR-2156, 2000 | Search excerpt |
| U10 | Kozma, Behm and McKenna, IEEE EMC 2022 | Abstract |
| U11 | Weissberger, ECAC modified exponential decay model, 1982 | Search excerpt |

### Not opened on purpose

Hause, Kimmett and Harman, ERL 134 (the Tier B low-antenna set), the Phase 1
VHF tabulations, and Longley and Reasoner 1970 (ERL 148), which compares
models on those sets.
