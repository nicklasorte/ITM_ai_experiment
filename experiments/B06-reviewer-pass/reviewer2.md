# Reviewer 2: A_fo in the delta construction, and run 601

Scripts: `/tmp/review_rev1/work/a1.py`–`a8.py`. "Error" is predicted minus measured, on uncensored rows.

## 1. What A_fo is

- ESSA ERL 79-ITS 67 (Longley and Rice 1968), Annex 3 §3-2, eq. (3.38c), p. 3-12–3-13: a "clutter factor", 5 log10[1 + 10⁻⁵ h_g1 h_g2 f σ_h(d_Ls)], capped at 15 dB. The symbol list (p. 3-17) calls it "an estimate of attenuation due to surface clutter".
- The NTIA Report 82-100 Fortran (`ADIFF`, `AFO=AMIN1(15.,2.171*ALOG(1.+4.77E-4*HG(1)*HG(2)*WN*Q))`) matches code line 676.
- Not verified: the data it was fitted to. Neither source says. Report 82-100 names data only for the weight w: 20–100 MHz low-antenna measurements in Colorado and Ohio, and the 1958–59 TASO TV data. I didn't get Hufford's 1995 memo.
- A_fo is one empirical part of ITM's w-blend, not separate physics, and the only ITM term whose loss rises with h1·h2.

## 2. Double counting

- L_ba already carries an empirical real-terrain correction: Bullington eq. (57), (1 − e^(−L_uc/6))(10 + 0.02 d) at `multi_edge_diffraction_rev1.m:229`, or P.526-11's C = 10 + 0.04 D. P.526-11 labels C only an "empirical correction", with no basis given.
- Where max(·) is inactive (in B04, 77 % of failing rows), that correction stays in full, about 10–12 dB. A_fo, an empirical clutter term from another model's fit, goes on top.
- 601 adds C even when both secondary edges have weight 0 (lines 173–175; header lines 95–96). C was calibrated with unweighted Deygout secondaries.
- The equations can't prove double counting. Item 4 shows A_fo doesn't model what is missing.

## 3. Proportionality test

- **Prediction (before looking):** A_fo sits outside max(·) (lines 798–803), and variability is linear in A_ref (line 1123). So var502 − var401 should equal A_fo on every row and percentile, not only where max(·) is inactive.
- **Result: confirmed.** σ_h backed out of the difference is constant within each path and height pair across frequency, to under 0.35 % (5,547 groups). Range 0.008–13.2 dB; the 15 dB cap is reached only in the long-term set.

| Slice | Error, 401 → 502 | Censored violations, 401 → 502 |
|---|---|---|
| A_fo ≤ 2 dB | −3.2 → −2.0 dB | 82 → 79 % |
| A_fo 6–10 dB | about −7 → +1 dB | 61–65 → 40–43 % |
| R2 | RMS 21.0 → 18.1 | 70.5 → 44.4 % |
| VA | RMS 15.7 → 12.7 | 83.1 → 69.5 % |
| R1 | RMS 10.0 → 10.2 | 22.9 → 12.9 % |
| R3 | RMS 6.1 → 8.0, mean −0.6 → +4.9 (worse) | none censored |
| 1846, 4595, 9190 MHz | — | 39, 100, 61 → 16, 53, 35 % |
| 230, 410 MHz | — | 100 → 100 % |

601 against 502: R2 +7.2 dB on measured rows and +25.6 dB on censored rows; R1 +2.8, VA +3.5, R3 +1.0 dB.

## 4. Frequency and height dependence

- **Frequency:** with path and heights fixed, the slope of 401 error on A_fo is −1.04. It matches on average; 502's residual slope is −0.04.
  - By site: R1 −0.64, R2 −2.72, R3 −0.27, VA −3.46.
  - By siting code: "C" −4.09 (401 mean error −16.1 dB), "O" −0.75 (−2.9 dB). The codes aren't documented in the repo; I read them as cluttered and open.
- **Height, the decisive failure:** with path and frequency fixed, I compared lowest against highest h1·h2 (1,344 pairs, mostly receivers at 1 m against 8 m).
  - Measured loss falls 8.7 dB; 401 falls 3.3 dB; stock ITM 2.4 dB.
  - **502 rises 0.5 dB, the wrong sign.** A_fo adds +3.8 dB.
  - The battery checks only continuity of the receiver-height sweep (`physics_battery_rev1.m:13, 44`), not its direction.

## 5. Decisive ablation

A_fo gets the frequency dependence right and the height dependence backwards. It seems to stand in for a loss near low terminals in clutter, one that grows with f and shrinks with height.

- **Ablation:** 401 with A_fo replaced by a terminal clutter or height-gain loss (ITU-R P.2108 §3.1, or P.452's clutter height-gain). Take the category from public land cover or the siting code; don't fit it.
- **If A_fo is physical**, this run loses to 502.
- **If A_fo is a stand-in**, it keeps 502's frequency slope, restores the measured 1→8 m height gain (about −8.7 dB), and removes 502's R3 bias (+4.9 dB) and "O"-site bias (+2.3 dB).

## 6. Run 601: reject

- **Not discrimination:** on R2 rows with 3 or more edges, 601 is +10 to +23 dB high on measured rows at every frequency, while censored violations there fall to 0–18 %. The dead-against-live AUC rises only from 0.886 to 0.917.
- **Other damage:** R1 and R3 are biased +6.2 and +5.9 dB. R3 RMS is 9.1 against 401's 6.1. Long-term level, independent data, goes from 15.4 (502) to 20.7.
- **The censored gate is cheap:** stock ITM plus a uniform 2.9 dB gives 25.3 % (601: 25.8 %).
- **Mechanism:** three stacked empirical increases (C with zero-weight secondaries, A_fo, the edge sum) and inverted height gain.

## Verdict

- **A_fo:** remove it from the delta forms. Replace it with a terminal clutter or height-gain term, such as P.2108 §3.1, whose height dependence has the measured sign.
- **601:** reject.
- **Next experiment:** 401 plus a P.2108 terminal clutter term in place of A_fo, with a new battery check that loss doesn't rise with receiver height.
