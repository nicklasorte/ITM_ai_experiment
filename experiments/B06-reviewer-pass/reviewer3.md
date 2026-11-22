# Reviewer 3: A_fo and 601

Scripts: `/tmp/review_rev1/r3/`. My cell RMS reproduces the stored 18.32, 14.22, 12.85, and 14.19 dB. Controls 602–605 weren't present.

## 1. What A_fo is
- I verified the formula and its name in Hufford's ITM algorithm document (ITS): A_diff = (1 − w)A_k + wA_r + A_fo, called a "clutter factor". Its constants convert exactly to the code at `itm_p2p_core_exp.m:676`.
- Not verified: A_fo's source data. NTIA 82-100 §4 (p. 15) cites 20–600 MHz data (Barsis–Miles 1965, Johnson 1967, TASO) for w, not A_fo. I didn't read ERL 79-ITS 67.
- A_fo grows with h1·h2, unlike terminal clutter loss (ITU-R P.2108): it's an empirical terrain-irregularity excess.

## 2. Double counting
- A_s: no double count. On the smooth path Δh = 0, so σ_h = 0 and A_fo = 0.
- L_ba: Bullington eq. (57) adds (1 − e^(−L_uc/6))(10 + 0.02d), median R1 8.9, R2 10.4, VA 8.5 dB (estimated from D03's ν_bull). It's P.526's empirical real-terrain excess, the job A_fo does in ITM, where the knife edge has no such correction. 502 has both: an overlap of purpose, not of algebra.
- 601 stacks three such terms: isolation-weighted secondary edges, C = 10 + 0.04D (`multi_edge_diffraction_rev1.m:173`), and A_fo.

## 3. Pre-registered test (`prereg.txt`)
- Correction to the brief: A_fo is added outside the max() (`:798-803`), so 502 − 401 = A_fo on every row except where the variability soft limit (`:1126`) acts.
- Result: corr = 0.999994, residual −0.004 ± 0.010 dB (−0.013 where 401's excess loss is negative). Held.

Where the 502 − 401 gain falls (path-weighted RMS on measured rows / censored violation %):

| Site | 401 | 502 | 601 | Stock |
|---|---|---|---|---|
| R1 | 10.0 / 22.9 | 10.4 / 12.9 | 12.1 / 7.1 | 13.0 / 13.6 |
| R2 | 20.3 / 70.5 | 17.5 / 44.4 | 20.0 / 11.0 | 29.9 / 6.8 |
| R3 | 6.4 / – | 7.9 / – | 9.1 / – | 9.0 / – |
| VA | 15.1 / 83.1 | 12.0 / 69.5 | 12.0 / 64.9 | 15.4 / 78.3 |

- The gain is all on R2 and VA. A_fo makes R1 and R3 worse: R3's bias goes from −1.0 to +4.6 dB, rising to +6.2 above 2.5 GHz.
- 388 of the 416 censored rows that 502 fixes are on R2 and VA.
- RMS gains grow with A_fo (0 to 4.9 dB by bin), but A_fo and the R2 and VA error both rise with frequency.
- 502 loses on long-term level (15.0 to 15.4). Its composite gain comes from Phase 2 alone.

## 4. Frequency dependence (same path and heights, 2,025 groups)
Median slope of the missing loss (measured − 401) against A_fo's slope, in dB/decade:

| Site | Missing loss | A_fo |
|---|---|---|
| R2 | 13.2 | 4.9 |
| VA | 12.2 | 4.0 |
| R1 | 2.1 | 4.7 |
| R3 | 0.2 | 4.8 |

- Slopes are uncorrelated (r −0.07 to 0.24); across paths within site × band, A_fo doesn't predict 401's error (r ≈ 0; −0.1 to −0.5 on R2).
- **No match.**

## 5. Decisive ablation
Offline, 20 shuffles of A_fo between paths within site × band (keeps only band means):

| Variant | Phase 2 cell (dB) | Censored |
|---|---|---|
| Shuffled A_fo | 12.79 ± 0.02 | 47.4 % |
| Band-mean A_fo (frequency only) | 12.87 | 47.8 % |
| Real A_fo (502) | 12.85 | 47.2 % |

- The per-path physics in A_fo (σ_h, h1·h2) is worth nothing here.
- A_fo stands in for a site-dependent excess loss of about 12 dB/decade on R2 and VA:
  - R2: separated ridges, consistent with D03.
  - VA: plausibly vegetation or terminal clutter, which no bare-earth term carries (ITU-R P.833, P.2108).
- It's not a too-small eq. (57) correction: R1 and R3 need no extra loss.

## 6. Is 601's gain physical?
- **Not only "more loss everywhere".**
  - 502 shifted up by a constant to 601's mean bias (+3.1 dB) gets 39.0 % censored at row RMS 12.3. 601 gets 25.8 % at 12.9.
  - The R2 AUC (dead against measured rows) rises from 0.887 to 0.916.
  - On R2, 601 adds a median 25 dB to dead rows against 14–15 dB to 3- and 4+-edge measured rows.
- **But it overshoots.** On 3- and 4+-edge measured rows (881 rows) the error is +17.0 and +12.9 dB, against +2.4 and −4.4 in 502.
- **R1 and R3 means come mostly from A_fo.** 601 minus A_fo (an approximate 604; exact unless the bound binds) gives:
  - R3 bias +0.4 dB.
  - Phase 2 cell 14.04, better than 601's 14.19.
  - Censored 37.4 %. This is an upper limit for 604, but it's above the 29 % gate.
- **Long-term level:** 20.7 against 15.4 for 502 (+9.2 dB bias under 100 km).
- **Recommendation: hold, don't keep.**

## Verdict
- **A_fo:** remove. Replace it with explicit, separately tested terms: the multi-edge loss for R2, and P.2108 or P.833 terminal or vegetation loss for VA (Tier C). Don't keep a term that scores the same as its own shuffle.
- **601:** hold. Its multi-edge discrimination is real, but its gate pass depends on A_fo, it overshoots 3+ edges by 13–17 dB, and its long-term level is 5.3 dB worse than 502.
- **Next experiment:** run 604 (601 without A_fo, bounded) alongside the shuffled-A_fo control. If 604 is close to 37 % censored, the missing loss is site-specific and not an ITM terrain term.
