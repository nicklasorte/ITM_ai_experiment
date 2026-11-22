Verdict: HOLD. The formula is coded correctly, but the code applies ITU-R P.2108-1 section 3.1 differently from how the Recommendation says to. That double counts the terminal height loss, and that height loss is what produces about half of the drop in censored violations.

Reviewer 1 of 3, batch B07, 2026-11-21. Scripts are in `/tmp/review_b07_r1/` (Python, ports of the formulas). The scripts reproduce the evaluator's Phase 2 numbers exactly: 701 cell 13.19, censored 21.4 %; 704 cell 13.46, censored 23.1 %. Because folds equal sites in Phase 2 (R1 = 1, R2 = 2, R3 = 3, VA = 4), "by fold" below means "by site". All errors are prediction minus measured, in dB.

## 1. Implementation

- **Formula: correct.** A Python port of eqs. (2a) to (2g) reproduces all 18 valid NTIA/ITS test vectors (`HeightGainTerminalCorrectionModelTestData.csv`, rtn = 0) to within 0.05 dB. The model change (701 minus 604) equals this A_h on every concealed row to within 0.007 dB, and is 0 on O, A, R3, and long-term rows.
- **Mobile end: correct.** In `r1path.txt`, a C path differs from its O twin only in the transmitter coordinates, so the transmitter is the mobile terminal in R1 to R3. In `vapath.txt` the transmitter is fixed, so the receiver is the mobile terminal in VA. The reversed-call swap is tested.
- **Not applied as written (main finding).** P.2108-1 Table 1 and section 3.1 describe A_h as an "end loss correction to be added to basic transmission loss calculated to/from the representative clutter height". The variant runs ITM at the real antenna height (2 m or 6.6 to 7.3 m) and then adds A_h. That counts the low-antenna loss twice: once in ITM and once in A_h. I tested this on the 214 measured VA concealed 2 m rows that have a 15 m row on the same path and frequency. Using 604 at 15 m plus A_h(2 m), as the Recommendation prescribes, gives a mean error of +3.9 dB and an RMS of 10.4 dB. 701 gives +7.6 and 12.2 dB on the same rows.
- **Above 3 GHz.** 28 % of concealed rows are above 3 GHz. Setting the term to 0 above 3 GHz gives a cell RMS of 13.76 and censored 28.1 %. So rows above 3 GHz supply 65 % of 701's cell gain over 604 (0.57 of 0.88 dB) and 6.7 of the 10.1 points of the censored drop. Holding A_h at its 3 GHz value instead gives 13.20 and 21.8 %, so the extend rule adds only 0.01 dB. The real question is whether to apply the term above 3 GHz at all. The measured twins say yes: at R1, concealed paths have 22.1 and 27.2 dB more loss than their open twins at 3 to 6 and 6 to 10 GHz, where P.2108 gives 25.0 and 28.0. The rule is defensible, but it stays a design choice.
- **Documentation error.** B07.md says the code reproduces "all 16" test vectors. The file has 18 valid vectors and 5 error cases. `p2108_height_gain_rev1` fixes R and w_s, so it can take only 6 of them, and `test_p2108_matches_ntia_test_vectors` checks those 6.

## 2. Input mapping

- **A behaves like O.** On the 156 measured A rows that have an O twin, the A row has 3.4 dB more loss than its twin below 0.3 GHz and 0.6 dB more at 0.3 to 1 GHz. For C rows the figures are 8.4 and 11.2 dB. The readme doesn't define A. It appears on 5 R1 paths, each an O-site twin about 100 to 200 m away, which suggests an alternate site. Applying trees to A rows too makes R1 RMS worse (10.7 to 12.0 dB). A mapped to 0 is supported by the data.
- **Trees and urban give identical results.** Table 3 gives both R = 15 m and eq. (2a). Dense urban (R = 20 m) gives cell 13.42 and censored 20.1 %; suburban (R = 10 m) gives cell 13.28 and censored 24.9 %. The data have no field that says whether a site is behind a tree or a building, so R = 15 m is a reasonable middle choice, not a measured one.

## 3. Shape versus level

- **701 versus 704 (paired bootstrap, 500 draws, paths resampled within site).** 701 is better by 0.26 ± 0.12 dB in cell RMS, which is 0.09 ± 0.04 dB composite (95 % interval +0.01 to +0.17). That is distinguishable from zero but under the 0.3 dB threshold. The ~0.5 dB figure in the brief is the unpaired SD against stock ITM; it is the wrong yardstick for this comparison.
- **The shape that helps is frequency only.** Replacing A_h with its mean for each site and band gives 13.21; with its mean for each site and frequency, 13.20. Both match 701 (13.19). So height dependence adds nothing to the score. A within-site shuffle of A_h across concealed rows gives 13.67 ± 0.03 (200 draws), worse than 701 by 16 SD. The frequency ordering is real.
- **Height can be tested only at VA.** The R1 and R2 mobile antenna sits at 6.6 m below 0.91 GHz and 7.3 m from 0.91 GHz up, so its height tracks frequency. At VA, 654 of the 661 receiver rows at 2 m are concealed rows, so low antenna and concealment are confounded. Relative to 604's own height dependence, the data need 5.5 to 11.6 dB more loss at 2 m than at 12 to 14 m. P.2108 adds 12 to 23 dB. 701 leaves VA concealed 2 m rows 6 to 15 dB too pessimistic in every band.
- **The twin test, independent of ITM, supports a frequency rise but a smaller size.** Measured concealed minus open loss (1,159 rows, 78 paths) fits 1.0 + 0.61·A_h. At R1 it rises from 8.4 dB below 0.3 GHz to 27.2 dB at 6 to 10 GHz; P.2108 gives 12.9 to 28.0. At VA's 12 to 14 m receivers the measured difference is 1 to 8 dB; P.2108 gives 1 to 14. In-sample, 0.75·A_h scores 13.15.

## 4. Stacking and double counting

- **R1 concealed obstructed rows (+11.6 dB) add up from two sources.** The 604 base already overshoots on the open twins of these paths (+6.3). P.2108 also exceeds the measured concealed-minus-open loss on these paths (19.7 versus 14.2 dB, or +5.5). 6.3 + 5.5 ≈ 11.8. The 702 base removes the first part: R1 open obstructed −1.0 and concealed obstructed +3.3.
- **Overlap with terrain diffraction is small.** At R1, the measured concealed-minus-open loss is about the same on clear and obstructed paths (15.3 and 14.2 dB). It is lower on obstructed paths at R2 (13.4 versus 20.8) and VA (3.1 versus 6.2), but those comparisons rest on only 2 clear paths at R2 and 11 at VA.
- **702 is the better physical base, but it fails the gate.** It uses one source per loss, and open obstructed rows sit near zero at R1, R3, and VA. It fails the censored gate (29.7 %) on R2 open rows (26.0 % violated, against 6.3 % for stock).

## 5. Robustness of the gate pass

- **By site, the censored result is mixed.** Violations: R1 5.7 % (stock 13.6 %), VA 42.9 % (78.3 %), but R2 14.5 % (6.8 %). The R2 increase comes from the 604 base, so a censored check run site by site would fail at R2.
- **By band, 701 beats stock in every band.** Violations: 25.0, 7.8, 10.7, 23.9, and 36.4 %.
- **Where the 207 removed violations come from (644 down to 437):**
  - 107 are VA concealed 2 m rows, where measured rows show 701 is about 8 dB too pessimistic.
  - 52 are R2 concealed rows, where measured rows are still 9 to 43 dB too optimistic. These are physical: real missing loss.
  - 44 are VA concealed high-antenna rows, where measured rows show about 0 dB bias.
  - 4 are R1 concealed rows.

  About half of the pass therefore rests on the double-counted height loss. That is targeted, not uniform, pessimism. For comparison, a uniform +8 dB on 604 gives 20.6 %. Running 0.5·A_h instead still gives 24.6 %, so a correctly applied term will probably still pass, but this hasn't been run.

## 6. Errors in LOG.md and B07.md

1. B07.md: "all 16 NTIA/ITS published test vectors". The file has 18 valid vectors; the code can take 6, and the test checks 6.
1. B07.md and the 701 entry: the term is said to be applied per P.2108-1 section 3.1, but it skips the Recommendation's step of computing loss "to/from the representative clutter height".
1. 704 reading, "frequency and height shape": the gain comes from frequency alone; the height dependence is neutral overall and too steep at VA.
1. The 701 note blames the R1 overshoot on stacking with the multi-edge base only. About half of it is P.2108 being larger than the measured concealed-minus-open loss.
1. 704 isn't an independent model. Its 16.75 dB is the mean of the P.2108 term, so KEEP 704 INSTEAD isn't an option under the rule against invented constants.

## Required before keep

1. Apply section 3.1 as written. On concealed rows, run ITM with the mobile terminal height set to max(h, R), then add A_h(h). Rerun 701 under all gates and report censored violations by site. This is the Recommendation's own procedure, not an input change.
1. Correct the test-vector claim in B07.md, or let the function take R and w_s so it can run all 18 vectors.

## Suggested next experiments

1. **707: 701 with section 3.1 applied at R as written.** Source: ITU-R P.2108-1, Table 1 and section 3.1. Prediction: VA concealed 2 m bias falls by about 4 dB, R1 concealed bias falls, and censored violations rise from 21.4 %.
1. **708: 702 diffraction plus the corrected clutter term.** One source per loss. Sources: Deygout (1966) and ITU-R P.2108-1 section 3.1. Gives a clean test of whether 702's R2 open-row optimism alone sinks it.
1. **Cross-check above 3 GHz.** Compare the extended eq. (2a) with the ITU-R P.833 one-terminal-in-woodland excess loss, and with the P.2108-1 section 3.2 median (31.4 dB at 4.6 GHz, 32.9 dB at 9.2 GHz). Diagnostic only, for the 28 % of concealed rows above 3 GHz.
