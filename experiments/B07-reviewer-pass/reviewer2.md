Verdict: HOLD. 701 applies the P.2108-1 correction to ITM loss computed at the antenna's real height, not at the clutter height R that section 3.1 requires, so it counts the terminal height gain twice. The open/concealed twins show this as a 9–10 dB overshoot on obstructed paths.

Reviewer 2 of 3, batch B07. I worked alone in Python from the logged prediction files. Scripts are in `/tmp/review_b07_r2/` (`load.py`, `score.py`, `a1.py`–`a8.py`, `vec.py`). My port of the Phase 2 cell-balanced RMS and the censored-violation rate reproduces the logged values (604: 14.07 dB and 31.5 %; 701: 13.19 dB and 21.4 %; 704: 13.46 dB and 23.1 %). The clutter term changes only Phase 2, so a composite change is the cell change divided by 3. Composite differences below come from that relation.

## 1. Implementation

- **Equations are right.** I ported eq. (2a)–(2g) with R and w_s as free inputs. The port matches all 18 valid rows (`rtn = 0`) of the NTIA/ITS `HeightGainTerminalCorrectionModelTestData.csv` (github.com/NTIA/p2108-test-data) within 0.05 dB. The 701 − 604 difference equals my A_h on every concealed row (largest difference 0.007 dB, from the variability soft limit) and is 0 on every O and A row.
- **The test-vector claim is overstated.** B07.md says the code reproduces "all 16" vectors. The file has 18 valid rows, and the MATLAB test checks only 6. All 6 are at 1.5 GHz and 2 m, so no test vector checks the frequency or height dependence. Also, the NTIA reference returns error 32 for 4 GHz: the reference implementation itself rejects input above 3 GHz.
- **The mobile end is right.** In `r1path.txt`–`r3path.txt`, the receiver coordinates are fixed and the O, C, and A rows differ only in the transmitter coordinates. In `vapath.txt`, the transmitter is fixed. The swap on `reversed` is coded correctly.
- **Departure from the Recommendation (main finding).** P.2108-1 section 3.1 says the basic transmission loss "should be calculated to/from the height of the representative clutter height used" (itu.int, R-REC-P.2108-1-202109). The code calls ITM with the mobile antenna at its real height (6.6–7.3 m in R1 and R2, 2–14.5 m at VA) and then adds A_h. That counts the gain from h to R twice: once inside ITM and once in A_h. In B07.md, the reason given for not using eq. (2b) on open rows (ITM already carries height gain) applies equally to eq. (2a).
- **Above 3 GHz, the extension carries most of the gain.** 28 % of concealed rows are above 3 GHz, with a mean A_h of 24.2 dB against 13.8 dB below 3 GHz. With A_h set to 0 above 3 GHz, the Phase 2 cell is 13.76 (701: 13.19; 604: 14.07) and censored violations are 28.1 %. So the extension supplies 64 % of 701's Phase 2 cell gain over 604 and 6.7 of its 10.1-point censored improvement. Without the extension, 701 still passes the censored gate, by 0.9 points. On physics, the extension is defensible: foliage grows more opaque with frequency, so a knife edge over the canopy fits better at 4.6–9.2 GHz than at VHF. The twin data agree (section 3).

## 2. Input mapping

- **C → trees/forest (R = 15 m).** In Table 3, urban also has R = 15 m and uses eq. (2a), so a "building" reading gives the same numbers. Dense urban (R = 20 m) raises the mean on concealed rows to 21.9 dB and makes the cell worse (13.42 against 13.19; censored 20.1 %). Rural sites from the 1960s don't support dense urban. Neither R = 15 m nor w_s = 27 m was measured at these sites. Section 3.1 assumes a terminal surrounded by clutter, but the readme describes a single obstacle "immediately behind" the terminal.
- **A behaves like O.** A appears on 4 R1 paths that have open twins. The measured A − O excess, after removing the terrain difference, is 3.9 dB below 0.3 GHz and 1.4 dB at 0.3–1 GHz. For comparison, C − O at R1 is 6.7 and 9.2 dB in the same bands. In 604, the mean error on A rows is −1.8 dB, against +3.4 dB for O and −10.4 dB for C. Mapping A to 0 is defensible.
- **Confound at VA.** 654 of the 661 VA rows with a 2 m antenna are concealed. Only 7 open rows are at 2 m. So at VA, siting C is almost the same variable as the 2 m antenna, and no twin pair tests the term at 2 m.

## 3. Shape compared with level

- **Composite:** 701 beats 704 by 0.09 dB. A paired bootstrap of 701 against 704 (paths resampled within site and fold, 300 draws) gives SD 0.039 and a 95 % interval of +0.015 to +0.174. The ~0.5 dB SD in the brief belongs to the gain over stock ITM, which is a different comparison. The difference is real, but it is a third of the 0.3 dB threshold.
- **Where the 0.27 dB cell difference comes from:** VA <0.3 GHz accounts for 0.16 dB (cell RMS 8.98 for 701 against 12.25 for 704). There, the constant adds 16.75 dB to concealed rows at 12–15 m, where the measured twin excess is 0.4–3.5 dB. 704 is better than 701 at R1 above 1 GHz.
- **Ablations (Phase 2 cell):**

  | Variant | Cell (dB) |
  | --- | --- |
  | P.2108 term (701) | 13.19 |
  | Constant 16.75 dB (704) | 13.46 |
  | Per-site constant | 13.41 |
  | Per-band constant | 13.23 |
  | Term shuffled within site (200 draws) | 13.67 ± 0.03 |
  | Term shuffled within site and band | 13.35 |
  | 0.75 × term | 13.15 |

  The frequency dependence carries almost all the shape value; height adds about 0.04 dB.
- **Twin test (the cleanest check):** 1,165 uncensored O/C twin pairs, compared at the same frequency and antenna height after removing 604's terrain difference.
  - Frequency slope: at the R1 and R2 transmitters, the measured C − O excess rises 9.8 and 10.7 dB per decade. P.2108 rises 9.4 and 9.3 dB per decade. The regression slope on A_h is 1.06 at R1 and 1.17 at R2. The frequency dependence is supported.
  - Level: P.2108 is too high. At R1 the intercept is −8.5 dB. At the transmitters, the measured excess is 7.2, 8.6, 11.1, 17.4, and 25.0 dB by band (<0.3 to 6–10 GHz), against A_h of 12.9, 16.9, 21.0, 25.0, and 28.0 dB.
  - At VA (antenna 11.7–14.5 m), P.2108 is 1–9 dB too high. At 15 m, both P.2108 and the measurements give about 0.
- **Discrimination:** At VA, P.2108 raises the AUC for separating censored from measured concealed rows from 0.765 to 0.849. A constant can't change it. At R2 the AUC goes from 0.936 to 0.943.

## 4. Stacking and double counting

The twin excess depends on whether the path is obstructed:

| Site | Clear: twin excess / A_h (dB) | Obstructed: twin excess / A_h (dB) |
| --- | --- | --- |
| R1 | 16.1 / 18.6 | 10.7 / 19.7 |
| R2 | 21.2 / 20.0 | 8.0 / 17.8 |
| VA | 6.2 / 6.0 | 3.0 / 4.9 |

P.2108 matches on clear paths and overshoots by 9.0 dB (R1) and 9.8 dB (R2) on obstructed paths. That is the expected signature of the section 1 error. When the loss is computed at h instead of R, the twin difference the model predicts is A_h instead of A_h − G(h→R). The height gain G is largest in the diffraction region. So R1's concealed obstructed error of +11.6 dB is about 6 dB of terrain overshoot (604's R1 open obstructed rows are already +6.3 dB) plus about 5 to 9 dB of double-counted height gain. It isn't only "clutter on top of the multi-edge overshoot", as LOG.md says.

702 brings R1 concealed obstructed rows to +3.3 dB by cancelling offsets. Removing P.526-11's C makes every obstructed class 3–10 dB more optimistic: R2 open obstructed rows go to −9.9 dB, R2 concealed obstructed rows to −20.0 dB, and R1 A obstructed rows to −11.5 dB. Neither base is clearly more physical. 701 is the safer base, but only after the fix in section 1.

## 5. Robustness of the gate pass

- **Not uniform pessimism.** 604 + 7 dB on every row reaches 21.8 % censored at a cell of 14.95. 701 reaches 21.4 % at 13.19.
- **All of the censored gain is on concealed rows.** VA C goes from 69 to 30 % (267 to 116 rows) and R2 C from 60 to 11 %. Open rows are unchanged. R2 open stays at 14.8 %, against 6.3 % for stock ITM: a per-site censored check would flag R2 for 701, as it would for 604.
- **By fold** (701 against stock): fold 1, 5.7 against 13.6 %; fold 2, 14.5 against 6.8 % (worse, from R2 open); fold 4, 42.9 against 78.3 %. Fold 3 has no censored rows.
- **By band:** 3–6 GHz, 23.9 against 33.2 %; 6–10 GHz, 36.4 against 38.0 %.
- **Concealed rows partly turn pessimistic.** The median margin on concealed censored rows goes from −7.5 to +15.2 dB, which is the intended effect. But 33 % of measured concealed rows are now more than 10 dB pessimistic, against 4 % in 604. R1 concealed rows are +6 to +11 dB at every band. R2 concealed rows are still −9 to −43 dB above 0.3 GHz, which is mostly R2's terrain problem: R2 open clear rows are −17 dB, and the R2 twin excess is only 7–14 dB below 6 GHz.

## 6. Errors in LOG.md and B07.md

1. "All 16 NTIA/ITS test vectors": the file has 18 valid rows, and only 6 are tested, all at one frequency and one height (section 1).
2. The instruction in section 3.1 to compute basic loss at R isn't mentioned or followed.
3. LOG 704's reading, "the shape is worth only 0.1 dB", is right in size. But the difference is about 2.3 paired SD, not noise. Also, the frequency dependence is supported by the twin data; it is the level that P.2108 gets wrong.
4. LOG.md attributes the R1 overshoot to stacking on the multi-edge overshoot alone (section 4).
5. Minor: LOG 604 lists "R2 mean −1.4 is outside (predicted −9 to −4)" under "Held".

## Required before keep

1. Re-run 701 per P.2108-1 section 3.1 as written. On concealed rows, compute ITM with the mobile antenna at max(h, R), then add A_h. This adds no new parameter. Report the twin test (clear and obstructed) and the censored rate by site.
2. Add test vectors that vary frequency and height: the 18 valid NTIA rows, with R and w_s exposed as inputs.
3. Report every concealed-term run with and without the extension above 3 GHz.

## Suggested next experiments

1. **701 with the path loss computed at R** (ITU-R P.2108-1 section 3.1). Predicted: the overshoot on obstructed concealed rows falls by 5–9 dB. Censored violations rise, and may cross the gate.
2. **The concealed obstacle as an extra terminal edge inside the multi-edge diffraction**, instead of a loss added on top, so that it doesn't add fully on paths already shadowed by terrain (ITU-R P.526-16 section 4, multiple isolated obstacles).
3. **A vegetation-specific term at the concealed end** as a control on the trees mapping (ITU-R P.833-10 section 2, terrestrial path with one terminal in woodland).
