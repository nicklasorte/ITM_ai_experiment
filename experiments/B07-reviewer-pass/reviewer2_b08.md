Verdict: KEEP 707. B08 meets every item on my required-before-keep list, the term now follows P.2108-1 section 3.1, and 707 passes the censored gate without relying on pessimism on concealed rows; two physics gaps remain open (items 2 and 5).

Reviewer 2, follow-up on B08. I worked alone. Scripts are in `/tmp/review_b07_r2/` (`b1.py`–`b3.py`). My port reproduces the logged values: Phase 2 cell 13.247 and 13.220 dB, and censored 22.79 % and 22.30 %, for 707 and 709.

## 1. Base-height correction

- **The code follows the Recommendation.** `clutter_terminal` picks the mobile end before any height is used: the transmitter in R1–R3, the receiver in VA, swapped when `reversed` is set. On concealed rows, `h_m(mobile_end)` becomes max(h, R). A_h is then added at the actual height, and A_h = 0 when h ≥ R.
- **Checked on the outputs.** I define the implied base change as (707 − 604) − A_h at the actual height under "hold3". On concealed rows its mean is:
  - −2.7 dB at R1 and −4.2 dB at R2 (transmitter at 6.6–7.3 m)
  - −4.1 dB at VA 2 m and −0.7 dB at VA 11.7–14.5 m
  - exactly 0 on the 225 VA rows at 15 m

  The base change is the same in 709 (difference 9 × 10⁻¹³ dB), so the frequency rule only changes A_h.
- **No side effects found.** Open and A rows equal 604 exactly (largest difference 0.0 dB), and long-term predictions equal 604 at every percentile (0.0 dB). The bound and the variability now use the raised height, which is consistent with computing the path at R.
- **Small note.** On 23 of the 2,272 concealed rows, raising the antenna to R increases ITM loss by more than 1 dB (largest +4.5 dB at R1). That is possible near two-ray nulls or where the horizon changes, but worth a look.
- **Minor.** The height is raised whenever `terminal_clutter_base = "clutter_height"`, including under `terminal_clutter = "constant"`. That setting isn't used in any B08 run.

## 2. Twin-pair recheck (1,165 uncensored open/concealed pairs)

Concealed-minus-open excess, model minus measured (dB). The terrain difference is removed with 604.

| Site, path | 701 | 707 |
| --- | --- | --- |
| R1 clear | +2.5 | −1.1 |
| R1 obstructed | +9.0 | +5.5 |
| R2 clear | −1.2 | −8.1 (46 pairs) |
| R2 obstructed | +9.8 | +5.5 |
| VA clear | −0.2 | −1.1 |
| VA obstructed | +1.9 | +1.3 |

- **The double count is gone, but about 40 % of the obstructed overshoot was something else.** The remaining 5.5 dB is non-additivity of clutter and terrain shadow. The model's term barely differs between clear and obstructed paths (R1: 14.9 against 16.2 dB), but the measured excess does (16.1 against 10.7 dB).
- **At 0.3–1 GHz** at the R1 and R2 transmitters, the measured excess is 8.6 dB. 701 gave 16.9 dB (8.3 too high) and 707 gives 13.9 dB (5.3 too high).
- **Concealed measured rows:** the mean error falls from +3.4 to +0.4 dB. At VA 2 m it falls from +8.4 to +4.3 dB.

## 3. Required items

- **All 18 vectors: met.** The MATLAB test now checks all 18 valid rows with the R and w_s overrides, plus the 5 error rows. I compared the coded values against the downloaded `HeightGainTerminalCorrectionModelTestData.csv`, and they match.
- **With and without the extension: met.** 707 ("hold3") and 709 ("extend") are both reported, and both are 0.0 dB on open rows. Composite 12.51 against 12.50; censored 22.8 % against 22.3 %.
- **Censored by site: met.** R1 5.7 %, R2 14.7 %, VA 47.5 %.

## 4. Pessimism and the censored gate

- **The share of concealed measured rows more than 10 dB pessimistic falls from 33 % (701) to 24 % (707).** It is still 44 % on R1 obstructed rows, the residual from item 2.
- **The gate pass no longer depends on that pessimism.** I subtracted each site-by-obstruction group's positive mean error from its concealed rows. Censored violations are then 23.9 % for 707 and 23.4 % for 709, both under the 29.0 % gate.
- **Unchanged and still open:** R2 censored is 14.7 % against 6.8 % for stock ITM, all on open rows and inherited from 604. A per-site check would fail; that is Nick's framework decision, not a defect of the clutter term.

## 5. New problems

1. **"hold3" flattens the frequency dependence at the R1 and R2 transmitters.** The term rises 6.7 dB per decade at R1 and 4.4 at R2, against measured 9.8 and 10.7. At 6–10 GHz, 707 is 5.4 dB too low on transmitter twins, while 709 is 0.6 dB too low.

   The justification in `p2108_height_gain_rev1.m` (the extended term exceeds the twin data above 3 GHz) holds at VA (41 pairs; 709 is 5–8 dB too high) but not at R1 and R2 (202 pairs). The data don't decide between the two rules. I prefer 707 only because "hold3" stays inside the Recommendation's validated frequency range; the comment should state the evidence by site.
2. **The archive note is right that 701 stays on the Pareto front.** 701 is the incorrect form, so the front shouldn't be used to choose a parent until it is filtered.
3. **708 confirms that 702's base fails once the double count is removed** (censored 32.5 %; R2 28.0 %). That is consistent with my B07 reading.

## Suggested next experiments

1. **The concealed obstacle as an additional edge in the multi-edge diffraction** (ITU-R P.526-16 section 4), to address the 5.5 dB obstructed overshoot.
2. **An ITU-R P.833-10 vegetation control** at concealed terminals, mainly above 3 GHz, where "hold3" and "extend" disagree by site.
