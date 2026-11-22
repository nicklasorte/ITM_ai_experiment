Verdict: HOLD. The clutter term is coded correctly and the gate pass survives debiasing, but 701 doesn't apply ITU-R P.2108-1 section 3.1 the way the Recommendation says, and the term overstates the height dependence and the loss on terrain-obstructed paths.

Reviewer 3 of 3, batch B07, 2026-11-21. Scripts are in `/tmp/review_b07_r3/` (`q1.py` to `q8.py`). Python ports of the scorer reproduce the logged Phase 2 cell RMS: 604 14.07, 701 13.19, and 704 13.46 dB. Long-term rows are the same in all three runs, so a composite change is the Phase 2 cell change divided by 3. "Twin" means an open path and a concealed path with the same base path, frequency, and heights, where both rows are measured (1,165 row pairs on 78 paths). For each twin, the empirical clutter loss is measured C minus O, less 604's own C minus O difference.

## 1. Implementation

- `p2108_height_gain_rev1` matches eq. (1) and (2a) to (2g) and the NTIA/ITS reference code (`HeightGainTerminalCorrectionModel.cpp`). The test-vector file has 18 valid vectors (`rtn = 0`). A port of the same equations with R and w_s as free inputs reproduces all 18 to 0.05 dB. The unit test checks only the 6 vectors that use the Table 3 R and w_s = 27 m, because the function can't take any other R or w_s. B07.md says "all 16". That claim is wrong.
- In every row, 701 minus 604 equals the Python P.2108 term to within 0.007 dB. The constant in 704 adds 16.75 dB on all 2,272 concealed rows.
- The mobile end is chosen correctly. In R1 to R3, `r*path.txt` fixes the receiver coordinates and the transmitter moves (Xht 6.6 or 7.3 m). In VA, the transmitter is fixed and the receiver moves (2 m, or 11.7 to 15 m). The `reversed` field is set only in the battery's reciprocity call. As a result, the R1 and R2 term depends on frequency only (12.9 dB at 230 MHz to 28.0 dB at 9.19 GHz), and height dependence exists only at VA.
- **Procedure deviation.** Section 3.1 says that A_h "can be added to the basic transmission loss of a path calculated above the clutter, therefore basic transmission loss should be calculated to/from the height of the representative clutter height used." 701 adds A_h to ITM evaluated at the real mobile height (2 m, 6.6 m, or 7.3 m), so the height gain from h to R is counted twice. On VA concealed paths, 604 already puts 3.5 dB more loss on the 2 m antenna than on the high one. An approximate correction subtracts ITM's height gain (about 4.5 dB per decade, from the R1 and R2 receiver sweeps in 604) up to 15 m. With that correction, the Phase 2 cell is 13.13 dB and censored violations are 22.0 %. The effect is small, but the run needs MATLAB, and the Recommendation requires the change.
- **Extend rule.** 28 % of concealed rows are above 3 GHz. Setting A_h to zero above 3 GHz moves the cell from 13.19 to 13.76 dB, so 64 % of 701's gain over 604 comes from those rows. Holding A_h at its 3 GHz value gives 13.20 dB. The growth with frequency above 3 GHz is worth 0.008 dB, so the extrapolation buys nothing. The NTIA reference code rejects f > 3 GHz (test vector at 4 GHz, `rtn = 32`). In the twin data above 3 GHz, the extended term exceeds the measured excess by 5 to 6 dB at R1 (19.0 and 23.0 dB measured against 25.0 and 28.0 dB) and by 6 to 9 dB at VA.

## 2. Input mapping

- The readme supports the mapping. A concealed terminal is "immediately behind a grove of trees or a building," and `A` isn't defined (five R1 paths, 416 rows).
- On twins with a clear path, P.2108 trees/forest matches the measured excess: R1 16.1 measured against 18.6 dB, R2 21.2 against 20.0 dB, and VA 6.2 against 6.0 dB. That supports R = 15 m.
- Urban uses the same R and the same equation, so its results are identical. Dense urban (R = 20 m) gives cell 13.42 and censored 20.1 %. Suburban (R = 10 m) gives 13.28 and 24.9 %. Trees/forest is the best of the three.
- Treat `A` as open. A minus O twins (below 1 GHz) differ by 1 to 4 dB. Treating `A` as trees worsens the cell to 13.57.
- At VA, siting is confounded with receiver height. 654 of the 661 rows at 2 m are concealed, and 95 of the 97 concealed paths have rows at 2 m.

## 3. Shape compared with level

| Concealed-row term on 604 | Phase 2 cell (dB) |
| --- | --- |
| None (604) | 14.07 |
| Within-site shuffle of A_h (200 draws) | 13.67 ± 0.03 (no draw ≤ 13.19) |
| Constant 16.75 dB (704) | 13.46 |
| Best constant (12 to 14 dB) | 13.41 |
| Per-site mean of A_h | 13.41 |
| A_h averaged over heights within set and frequency | 13.20 |
| P.2108 (701) | 13.19 |
| 0.75 × P.2108 | 13.15 |

- A paired path bootstrap (300 draws, within site) gives 704 minus 701 of +0.26 ± 0.12 dB on the cell, 95 % interval +0.02 to +0.50. On the composite, that's 0.09 ± 0.04 dB. The roughly 0.5 dB SD in the brief belongs to the gain over stock ITM, not to this paired difference. The shape gain can be told apart from zero, but it's far below the 0.3 dB threshold.
- **The frequency slope is real.** Twin slopes are 9.8 dB per decade at R1 and 10.7 at R2, against 9.4 and 9.3 for P.2108. At VA, the twin slope is 3.6, against 7.5 for P.2108.
- **The height dependence isn't supported.** Averaging A_h over heights loses nothing. On VA concealed paths, the measured loss at 2 m exceeds the loss at the high antenna by 10.6 dB. 604 gives 3.5 dB, P.2108 adds 15.0 dB, and 701 gives 18.4 dB. VA concealed rows at 2 m are now +5.7 to +14.6 dB pessimistic in every band, and the high rows are −3.8 to +4.4 dB.
- In 701, the level is about 25 % too high: 0.75 × A_h scores better, and concealed measured rows have a mean error of +3.4 dB.

## 4. Stacking and double counting

- The twin excess falls when the path is obstructed: R1 16.1 dB clear and 10.7 dB obstructed, R2 21.2 and 8.0 dB, VA 6.2 and 3.0 dB. P.2108 adds the same loss either way, so it overshoots obstructed twins by 9.0 dB at R1 and 9.8 dB at R2. The 604 terrain difference has already been removed from these numbers, so this overshoot doesn't come from P.526-11's C. A terminal that terrain already shadows loses less to nearby clutter. The LOG note that the R1 concealed obstructed overshoot (+11.6 dB) is "stack on 604's multi-edge overshoot" is only part of the story.
- 702 brings R1 concealed obstructed rows to +3.3 dB by making every open obstructed class optimistic (R1 −2.4, R2 −9.9, VA −3.7 dB) and pushing censored violations to 29.7 %. One overshoot is offsetting the other. That isn't a fix.
- 701 is the better base: open rows don't change, and censored violations stay under the gate. Neither base handles the interaction between clutter and terrain.

## 5. Robustness of the gate pass

| Censored violated (%) | n | Stock | 604 | 701 | 704 | 702 |
| --- | --- | --- | --- | --- | --- | --- |
| R1 (fold 1) | 280 | 13.6 | 7.1 | 5.7 | 7.1 | 11.8 |
| R2 (fold 2) | 1,184 | 6.8 | 18.9 | 14.5 | 14.5 | 25.8 |
| VA (fold 4) | 581 | 78.3 | 68.8 | 42.9 | 48.4 | 46.3 |
| Concealed | 498 | 66.7 | 67.7 | 26.1 | 33.3 | 33.7 |
| Open and A | 1,547 | 15.6 | 19.8 | 19.8 | 19.8 | 28.4 |

- Every frequency band is at or below stock. The whole censored gain comes from concealed rows.
- R2 has twice the stock rate (14.5 % against 6.8 %). 604's diffraction caused that, but a per-site check would fail 701.
- Uniform pessimism also passes the gate cheaply: 604 + 2 dB on every row gives 26.4 % censored and a better cell (13.98).
- 701's pass has a physical basis. If each pessimistic concealed group (set × siting × VA height × obstruction) is shifted to zero measured-row bias, censored violations are still 23.0 %. Of the 151 VA concealed censored rows that 701 fixes, 107 are at 2 m, where measured rows are about 8 dB pessimistic. Part of the VA fix is therefore overshoot, but the gate holds without it.

## 6. Errors in LOG.md and B07.md

1. B07.md says the code reproduces "all 16" NTIA/ITS test vectors. The file has 18 valid vectors, and the test checks 6.
1. B07.md doesn't mention the section 3.1 requirement to compute the base loss at height R. The planner applied that reasoning to eq. (2b) but not to eq. (2a).
1. LOG 704's reading ("weakly support the frequency and height shape") should say that the frequency slope matches the twins and the height dependence is overstated about two times.
1. LOG 701's note puts the R1 overshoot on stacking with C. The twin data show that clutter and terrain shadow don't add.
1. The B07 worker summary doesn't say that 701's composite gain over 604 is 0.29 dB, under the 0.3 dB threshold (paired cell gain 0.85 ± 0.44 dB). The clutter term earns its place on the censored gate, not on RMS.

## Required before keep

1. Rerun 701 with ITM evaluated at the mobile height raised to R = 15 m on concealed rows, as ITU-R P.2108-1 section 3.1 says. Keep it only if every gate still passes (approximate result: cell 13.13, censored 22.0 %).
1. Replace "extend" with A_h held at its 3 GHz value above 3 GHz. That gives the same score (13.20 against 13.19 dB) without going outside the validated range, and it matches the NTIA reference code.
1. Correct the test-vector claim and the two LOG readings above. Record that R2 censored violations are twice stock, so Nick can decide on a per-site check.

## Suggested next experiments

1. **Clutter as an edge, not an add-on.** Put the clutter obstacle (height R, about w_s from the mobile terminal) into the existing isolation-weighted multi-edge construction, so it counts fully only where terrain doesn't already shadow the terminal. Sources: Deygout (1966); ITU-R P.526-16 section 4.5. Target: the 9 to 10 dB obstructed overshoot.
1. **ITU-R P.452-17 section 4.5 clutter loss** (trees, nominal height and distance from its clutter table) as the alternative published term. It moves the terminal to the clutter height in the profile by construction, and its frequency factor gives an independent check of the slope.
1. **Diagnostic on VA height gain at 2 m.** Measured 10.6 dB, ITM 3.5 dB. Compare it with the ITU-R P.833-10 terminal-in-woodland model before any height-dependent clutter term goes further.
