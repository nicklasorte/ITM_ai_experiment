# What the model-comparison paper says to fix in ITM

Rev 1, 2026-11-21. Source: Nick's working paper comparing ITM v1.4, ITU-R
P.2001-6, and ITU-R P.452-18 at 3 GHz against public measurements
(`docs/model_comparison/itm_p2001_p452_comparison_working_paper_rev4.docx`
in [nicklasorte/matlab_itm](https://github.com/nicklasorte/matlab_itm),
commit `9bd6a4e`). This note turns its findings into testable hypotheses for
`itm_variant/`, ranked by how much error each could remove. Numbers in
quotes of "the paper" are the paper's; numbers labeled "harness" come from
`eval/` in this repository.

## What the paper found

1. **Line of sight is fine.** On 18 real line-of-sight links ITM and P.2001
   differ by a median of −0.1 dB.
1. **Beyond the horizon ITM predicts far more loss.** Median gap 33 dB on 27
   diffraction links and 37 dB on 15 troposcatter links. P.2001 and P.452
   agree with each other within 0.02 dB at the median.
1. **The cause is how ITM builds diffraction, not its knife-edge formula.**
   ITM evaluates `A_d = w·A_se + (1 − w)·A_k + A_fo` at two distances
   *beyond* the horizons (d₃, d₄), draws a line, and reads the path's loss
   off that line. Removing the horizon knife edges, the smooth-earth term,
   and the clutter term cuts the median gap from 33 dB to −9 dB.
1. **The gap splits into parts.** On 59 real diffraction links, of a mean
   41.5 dB gap: 15.5 dB from a knife edge at *each* horizon versus P.2001's
   single Bullington edge; 14.8 dB from the weighted smooth-earth term ITM
   always adds (P.2001 adds spherical-earth loss only as an excess, median
   0 dB there); 2.3 dB from ITM's clutter term exceeding P.2001's add-on;
   9.1 dB (median 3.6 dB) from extrapolating the line back to the path.
1. **Region choice misfires on rough terrain.** On a 47 km front-range path
   whose actual horizons total 16.3 km, ITM decides the region from the
   smooth-earth horizon of its effective heights (74.1 km) and treats the
   path as line of sight. Its line-of-sight values are then almost entirely
   the extended diffraction line, because the two-ray weight
   `1/(1 + f·Δh/d_sML)` is tiny when Δh is near 1 km. Result: 134 dB above
   free space against P.2001's 64 dB.
1. **The divergence window.** Large gaps fall on rough paths of about 15–150
   km; links are either close (median 8 dB) or far apart (median 44 dB),
   depending on ITM's smooth-earth weight. Western terrain (median Δh 627 m)
   widens the gap to a median 48 dB.
1. **On synthetic ridges, classical multi-edge methods sit in between.** For
   two equal 280 m ridges: Epstein-Peterson 63 dB and Deygout 68 dB above
   free space, P.2001 50 dB, ITM 127 dB.
1. **Measurements put the truth between the models in the mountains.** On 47
   Colorado mountain paths over 15 km (median Δh 697 m, 55 % censored), ITM
   predicts a median 29 dB too much loss and P.2001 17 dB too little.
   P.2001 predicts less loss than the censored bound on 64 % of those
   results, ITM on 0 %.
1. **At small time percentages the ITU models are too optimistic.** At 1 %
   of time over DBSG3 data, mean error −2.4 dB for ITM, −5.7 dB for P.452,
   −6.7 dB for P.2001: their ducting enhances more than was measured.
1. **ITM drifts toward too much loss from 6 to 10 GHz** (mean error by band:
   −1.2 dB at 1–3 GHz, −2.2 dB at 3–6 GHz, rising above 6 GHz).
1. **Clutter near the terminals is missing from all three.** Virginia: all
   models predict too little loss at every distance (median −10.6 dB ITM,
   −13.0 dB P.2001). Paired concealed sites near 3 GHz measured a median
   8.0 dB more loss than the open site next to them, rising from 3.0 dB below
   1 GHz to 10.8 dB above 3 GHz; the models predict almost no difference.
1. **Antennas near the ground: all models predict too little loss** (median
   −16.7 dB ITM on ITS Phase 1, −6.7 dB on the low-antenna set).
1. **A reciprocity flaw.** ITM's terrain-irregularity window ends are
   truncated to whole profile points, so swapping the terminals changes the
   loss on some links (8 asymmetric links in the paper).

## Hypotheses for the variant, ranked

"Beyond recalibration" marks hypotheses that change structure, which the
recalibrated baseline (`eval/cv_calibrate_rev1`) can't reproduce by tuning
constants. Those are where an agent result could beat recalibration.

| Rank | Hypothesis | Change in `itm_p2p_core_exp.m` | Paper evidence | Harness target | Beyond recalibration? |
| --- | --- | --- | --- | --- | --- |
| H1 | Multi-edge diffraction on the actual profile lands between ITM and P.2001, where the measurements are | Replace the knife edge at each horizon with Epstein-Peterson or Deygout over the dominant edges (P.526 multiple isolated edges); test delta-Bullington as the P.2001-like bound | Findings 4, 7, 8 | R2 (28.6 dB RMS, mean +10.6 dB) | Yes |
| H2 | Compute diffraction at the path's own distance, not by extrapolating from d₃ and d₄ | `longley_rice`: evaluate the diffraction terms at d instead of the d₃–d₄ line | Finding 4 (9.1 dB mean) | Diffraction-mode links | Yes |
| H3 | Decide the region from the actual horizons, not the smooth-earth horizon of effective heights | `longley_rice` region test; `line_of_sight_loss` weight | Finding 5 | Rough "line-of-sight" links in R2 and R3 | Yes |
| H4 | Add smooth-earth loss only as an excess over a smooth-profile Bullington loss (delta construction) | `diffraction_loss`: replace `w·A_se + (1 − w)·A_k` | Findings 3, 4 (14.8 dB) | Diffraction-mode links | Yes |
| H5 | Retune the clutter term and the smooth-earth weight | `cfg.cal.afo_scale`, `cfg.cal.w_const` | Findings 4, 6 | All diffraction links | No: this is what the recalibrated baseline does |
| H6 | Keep ITM's enhancement side of the time distribution; don't import ITU ducting wholesale | `variability`; downgrades rank 7 of `LITERATURE_REVIEW.md` | Finding 9 | Long-term level at 1 % and 10 % | Partly |
| H7 | Frequency scaling above 6 GHz (roughness and diffraction terms) | `terrain_roughness`, `sigma_h_function`, Fresnel-scaled roughness | Finding 10 | 6–10 GHz cells | Yes, if structural |
| H8 | Fix the Δh window truncation so the model is reciprocal | `compute_delta_h` window ends | Finding 13 | Physics battery reciprocity | Yes (a correctness fix) |
| H9 | Terminal clutter loss | ITU-R P.2108 at the terminals | Finding 11 | VA (mean −8.1 dB) | Caution, see below |
| H10 | Losses for antennas within a few metres of the ground | `line_of_sight_loss`, effective height | Finding 12 | Phase 2 links with receivers at 1–3 m | Partly |

**Recommended first batch:** H1 (Epstein-Peterson and Deygout variants, plus
delta-Bullington as a bound), H2, and H3, each alone, then the best
combination. Expected effect: large gains in R2 and in diffraction-mode
cells; little change in R1, R3, and VA, which are mostly line of sight.

## Cautions

- **Don't fit clutter to Virginia.** The Virginia bias is site clutter that
  bare-earth profiles can't see. A term tuned to remove it would improve
  the score without improving the physics, and would hurt open sites. A
  clutter term is acceptable only if it uses inputs available in practice
  (for example, a land-cover class) and is tested on held-out regions.
- **The lockbox isn't untouched.** The paper already compared the models on
  ITS Phase 1, the low-antenna set, DBSG3 VI-2, and DBSG3 Table III. The
  agent hasn't seen them, but the humans have. Treat them as validation
  sets; a truly blind test needs data neither has seen.
- **Censored results decide the mountain question.** P.2001's apparent
  accuracy there rests partly on predicting less loss than the bound on 64 %
  of no-signal results; the harness's censored-violation gate keeps a
  P.2001-like swap honest.
