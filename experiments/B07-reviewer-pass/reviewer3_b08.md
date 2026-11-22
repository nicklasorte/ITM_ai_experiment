Verdict: KEEP 707. B08 met every item I listed as required before keep, the term now follows ITU-R P.2108-1 section 3.1 as written, and the censored gate still passes after debiasing.

Reviewer 3, follow-up on batch B08, 2026-11-21. Scripts: `/tmp/review_b07_r3/b08.py`, with the B07 scripts beside it. Twins are open and concealed rows with the same base path, frequency, and heights, both measured.

## 1. Base-height implementation

- The code applies the Recommendation as written. Section 3.1 and Table 1 add A_h to loss "calculated to/from the representative clutter height used," with A_h = 0 for h ≥ R. I checked this against the itu.int PDF. `clutter_terminal` picks the mobile end from `cfg.row` before any height is used (transmitter in R1 to R3, receiver in VA, swapped when `reversed` is set). `h_m(mobile_end) = max(h, R)` then feeds `quick_pfl`, the delta reference, and the bound. A_h is evaluated at the actual height.
- `h_tx_m` and `h_rx_m` appear only in input validation, so nothing downstream uses the unraised heights.
- **Side effects: none on open rows, long-term rows, or high antennas.** In 707, open and `A` rows equal 604 exactly (max difference 0.0 dB). 708's open and `A` rows equal 705. Long-term predictions in 707 and 709 equal 604's. The 225 concealed rows with the mobile antenna at 15 m are unchanged.
- **Implied ITM change from raising the mobile antenna** (707 − 604 − A_h, mean by band):
  - R1: −2.5 to −2.9 dB.
  - R2: −2.8 dB below 0.3 GHz, growing to −6.1 dB at 6 to 10 GHz.
  - VA: −1.6 to −2.9 dB on average, reaching −25 dB on some rows at 2 m.
- **New, small:** on 26 obstructed rows (6 paths, 20 of them on R1-020-T8), raising the antenna *adds* up to 4.5 dB, and the amount barely depends on frequency. That pattern points at the delta and secondary-edge construction inherited from 604, not at the B08 change. It doesn't block a keep, but it is a height-direction defect that the synthetic height-gain battery check doesn't catch.
- Tests: all 18 valid NTIA/ITS vectors are checked through the `R_m` and `w_s_m` overrides, and so are the 5 error rows. The `hold3` and base-height tests cover a reversed call and an open row.

## 2. 707 against my estimate, and the B07 diagnostics

- **Score:** cell 13.25 dB and censored 22.8 %, against my estimate of 13.13 and 22.0 %. My Python port reproduces 707's cell (13.247) and 709's (13.220). My estimate assumed less height gain from ITM than ITM actually gives, and it left out `hold3`.
- **Paired path bootstraps:** 701 − 707 is −0.06 ± 0.14 dB on the cell, so the two can't be told apart. 604 − 707 is +0.81 ± 0.31 dB (95 % interval +0.26 to +1.41). That is only 0.27 dB on the composite, so the clutter term earns its place mainly on the censored gate and on physics, not on RMS.
- **VA, 2 m minus high antenna, concealed paths (426 pairs):**

  | Source | Difference |
  | --- | --- |
  | Measured | 10.6 dB |
  | 604 | 3.5 dB |
  | 701 | 18.4 dB |
  | 707 | 14.9 dB |

  The double count is gone. What remains comes from P.2108's own height shape, which is still about 1.4 times the measured value. VA concealed rows at 2 m now run −2.0 to +7.7 dB by band, down from +5.7 to +14.6 in 701.
- **Twin overshoot on obstructed paths** (P.2108 term minus measured excess): R1 +5.5 dB and R2 +5.5 dB, down from about +9 to +10 in 701; VA +1.3 dB. On clear twins the term is −1.1 dB at R1 and VA, and −8.1 dB at R2 (only 2 paths). Clutter loss and terrain shadow still don't simply add, but the error is now half its B07 size.

## 3. Required items

| Item | Met? |
| --- | --- |
| Rerun with the base loss at R | Yes: 707 |
| `hold3` above 3 GHz | Yes: the 707 default. 709 (`extend`) differs by 0.01 dB composite and 0.5 points censored |
| Test vectors | Yes: 18 valid vectors plus 5 error rows. B07.md carries a correction note |
| LOG corrections | Yes, in the "B07 reviewer pass" entry (704 shape reading, R1 overshoot attribution) |
| R2 censored recorded for Nick | Yes: R2 is 14.7 % against 6.8 % for stock, all on open rows (160 of 1,078, the same as 604), and the decision is listed for Nick |

## 4. Gate after debiasing

- After the same debiasing as before (each pessimistic concealed group shifted to zero measured-row bias), censored violations are 24.2 % for 707 and 23.8 % for 709. Both stay under 29.0 %.
- The pessimistic concealed groups are R1 obstructed (+8.1 dB), VA high-antenna obstructed (+2.0), and VA 2 m obstructed (+5.9).
- By site, against stock: R1 5.7 % (13.6), R2 14.7 % (6.8), VA 47.5 % (78.3).

## 5. Anything new that is wrong

1. The 707 LOG reading says the 1.4-point censored cost is "all at VA." It is 27 of 29 rows: VA concealed went from 116 to 143 violations and R2 concealed from 12 to 14.
1. The rows above, where raising the antenna adds loss, need a height-direction check on real profiles. This is the same gap B06 reviewer 2 reported.
1. The archive keeps 701 on the Pareto front even though 701 is the incorrect form. The LOG already says so. Mark 701 as superseded so a later planner doesn't pick it.

The remaining physics work (obstructed overshoot of about 5.5 dB, VA height shape) is for later batches. It doesn't block a keep. My earlier suggestions still apply: the clutter obstacle as an edge per P.526-16 section 4, and P.452-17 section 4.5.
