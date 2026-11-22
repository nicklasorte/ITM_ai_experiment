# Reviewer 1: A_fo in the delta forms, and experiment 601

Method: Python on the 000, 401, 502, and 601 prediction files, `phase2_links_rev1.csv`, and D03's `rows_rev1.csv`. I recomputed A_fo for every row by porting `quick_pfl`, `compute_delta_h`, and the A_fo formula (`itm_p2p_core_exp.m:676`, `:798-802`). Controls 602 to 605 weren't present. Scripts: `/tmp/review_rev1/py/`.

## 1. What A_fo is

- [Longley and Rice 1968, ERL 79-ITS 67](https://its.ntia.gov/publications/download/ERL%2079-ITS%2067.pdf), eq. (3.38c): a "clutter factor", "an estimate of attenuation due to surface clutter".
- [Hufford, ITM 1.2.2 algorithm](https://its.ntia.gov/publications/download/HuffordITMalgWhitePaper.pdf), eq. (4.10): the same label, with no derivation.
- [NTIA 82-100](https://its.ntia.gov/publications/download/82-100_ocr.pdf): code only. Its formula is identical to the repo's.
- Not verified: the data A_fo was fitted to. None of the three names it.
- Against a clutter reading: A_fo grows with h1·h2, but clutter loss falls as antennas rise.

## 2. Is anything counted twice?

- **L_ba and A_fo:** no. Stock ITM also adds A_fo on top of its obstruction term A_k.
- **Eq. (57) and A_fo:** yes, by design. Both are empirical excess loss over an ideal knife edge, each fitted without the other. On obstructed rows they stack 8.4 to 11.2 dB (eq. (57)) plus 4.3 to 7.5 dB (A_fo). R1 and R3 pay for it: in 502, R3 rows with 1 or 2 edges are +9.5 and +10.9 dB high.
- **The max(·):** L_bs's eq. (57) term cancels L_ba's only while the max(·) is active, and B04 found it near 0 on the failing rows. A_fo sits outside the max(·) and never cancels.
- **601 stacks three terms:** C = 10 + 0.04 D, the weighted secondary edges, and A_fo.

## 3. The 502 − 401 test, and where the gains are

- **Prediction:** A_fo is added after the max(·) (`:793-802`), so 502 − 401 = A_fo on every row. The brief's "where the max(·) is inactive" is too narrow.
- **Result:** equal on all 16,805 rows, to within 0.007 dB.
- **Sites:** 502 vs 401 changes summed squared error by R2 −293k dB², VA −219k, R1 +22k, R3 +134k. R3 RMS goes from 6.1 to 8.0 dB.
- **Censored rows:** 502 fixes 416 that 401 violated (309 on R2, 79 on VA). Their mean A_fo is 8.8 dB, against 5.5 overall. Violations drop by 3 points in the 1 to 3 dB A_fo bin and 29 to 31 points above 9 dB. That follows from censored rows being high-frequency.
- **Frequency:** the gains are at 1,846 MHz and above. Rows from 230 to 910 MHz get slightly worse.

## 4. Frequency dependence

On rows that share a path and heights, the pooled slope is d(e401)/d(A_fo) = −0.98. That hides very different sites:

| Site | Slope vs A_fo | 401 missing loss (dB/decade) | A_fo slope (dB/decade) |
| --- | --- | --- | --- |
| R3 | −0.26 | 1.2 | about 4.4 |
| R1 | −0.65 | 2.6 | about 4.4 |
| R2 | −2.75 | 12.9 | about 4.4 |
| VA | −3.52 | 13.5 | about 4.4 |

The slopes don't match. A_fo is too steep for R1 and R3 and too shallow for R2 and VA.

## 5. Decisive ablation

- **Done offline (row-level):** a constant 5.46 dB on 401 gets 80 % of A_fo's RMS gain (RMS 11.97 vs 11.78 dB; 401 is 12.76). A_fo shuffled within each site gets 64 %.
- **On R2 and VA, the missing slope is the same on clear rows (0 edges) and obstructed rows:** 14.1 vs 12.5 and 17.4 vs 12.4 dB/decade. Diffraction can't explain loss on clear paths.
- **Reading:** A_fo stands in for site-specific loss at the terminals that rises with frequency (likely vegetation on R2 and VA), plus a level offset. It doesn't stand in for rounded obstacles or missing edges.
- **Decisive scored run:** compare 401 + A_fo, 401 + a site-blind constant, and 401 + a published terminal clutter term (ITU-R P.2108 §3.2 or P.833; TODO until read), each scored on clear and obstructed rows. If A_fo doesn't beat the constant on obstructed rows, it isn't physical here.

## 6. 601

- **Overall it isn't a uniform shift.** Against 502 it adds +3.1 dB on measured rows and +17.4 dB on censored rows. Shifted −2 dB, it reaches 28.9 % censored at RMS 12.5. 502 needs +8 dB, and RMS 14.6, for 28 %.
- **Within an edge class it is a shift.** Shift 502 by the same mean:

  | R2 class | Censored (shifted 502 / 601) | RMS, dB (shifted 502 / 601) |
  | --- | --- | --- |
  | 3 edges | 6.4 % / 7.2 % | 21.7 / 23.9 |
  | 4+ edges | 4.1 % / 5.2 % | 18.0 / 19.1 |

  The edge term adds scatter (error SD 13.5 to 16.9 dB). Its gain is "add about 15 dB to multi-edge paths", which leaves measured rows +13 to +17 dB high. Stock ITM makes the same trade.
- **R1 and R3 bias:** about 4 dB of R3's +5.9 dB mean comes from A_fo on clear rows. R1 and R3 rows with 1 to 3 edges run +9 to +17 dB high. Long-term level is 20.7, against 15.4 for 502.
- **Without A_fo**, 601 has about 37 % censored violations (approximate, because the bound isn't linear). That fails the gate.

## Verdict

- **A_fo:** remove it from the delta forms. Replace it with a published terminal clutter term, but escalate to Nick first, because a site clutter input may count as an input change.
- **601:** hold, don't merge. Its pass rests on a site-blind offset plus a multi-edge overshoot.
- **Next experiment:** the three-way ablation in section 5, run with 604.
