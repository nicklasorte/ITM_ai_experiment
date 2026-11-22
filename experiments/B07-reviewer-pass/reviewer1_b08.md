Verdict: KEEP 707. It now applies ITU-R P.2108-1 section 3.1 the way the Recommendation says, my independent estimate reproduces it exactly, and it passes the censored gate even after its remaining concealed-row pessimism is removed.

Reviewer 1, follow-up on B08, 2026-11-21. Scripts are `/tmp/review_b07_r1/b08_s1.py` to `b08_s3.py`. My Python scoring reproduces the logged values: 707 cell 13.247 and censored 22.79 %; 709 13.220 and 22.30 %; 708 13.847 and 32.52 %.

1. **Implementation: correct.**
   - In `clutter_terminal`, the mobile end is the transmitter in R1 to R3 and the receiver in VA, with `reversed` swapping it. This is fixed before any height is used.
   - `h_m(mobile_end) = max(h, R)` feeds `quick_pfl`, the delta reference, the bound, and the variability calculation. A_h then uses the actual height, and A_h = 0 when h ≥ R.
   - Checks against the prediction files:
     - Open and A rows differ from 604 by exactly 0.0 dB, and long-term rows by 0.0 dB.
     - On the 225 VA concealed rows already at 15 m, the base change is 0.0 dB.
     - On the 214 VA 2 m concealed rows where my B07 report estimated "604 at 15 m plus A_h(2 m)", 707 matches the estimate with a maximum difference of 0.00 dB.
   - The new test checks the reversed call and open rows.
   - **One side effect.** On 26 of 2,272 concealed rows, raising the antenna to R *raises* ITM loss, by up to 4.5 dB. Twenty of these are on one obstructed R1 path (R1-020-T8, 17 km), and six are on long VA paths. This is a non-monotonic height response in the 604 delta/isolated-edge base, not in the clutter code. It is small, but the base should be checked for it.

2. **The double count is gone. A separate overshoot from adding clutter and terrain together remains.**
   - VA concealed 2 m rows (431 measured; path-weighted mean error and RMS, dB):

     | Run | Mean | RMS |
     | --- | --- | --- |
     | 604 | −10.4 | 16.1 |
     | 701 | +7.8 | 13.5 |
     | 707 | +3.9 | 11.8 |

     By band, 707's errors are +5.6, +3.7, +3.9, −2.0, and +7.7 dB; 701's were +8.7 to +14.6.
   - Twin paths, modelled minus measured concealed-minus-open excess (dB):

     | Site and path type | 701 | 707 |
     | --- | --- | --- |
     | R1 clear | +2.5 | −1.1 |
     | R1 obstructed | +9.0 | +5.5 |
     | R2 obstructed | +9.8 | +5.5 |
     | R2 clear (2 paths) | −1.2 | −8.1 |
     | VA obstructed | +1.7 | +1.1 |

     The 5.5 dB left on obstructed paths isn't a double count of height. It comes from adding the clutter term on top of terrain shadow, which the Recommendation doesn't address. The R1 concealed obstructed mean error is +8.1 dB, of which +6.3 dB is the 604 base (open twins have the same error).

3. **The censored pass no longer rests on unphysical pessimism.**
   - My B07 report expected violations to rise from 21.4 %; it did not put a number on the at-R run (0.5·A_h gave 24.6 %). The actual figure is 22.8 %.
   - Violated concealed rows (604 → 701 → 707):
     - VA 2 m: 151 → 44 → 67
     - VA high antenna: 116 → 72 → 76
     - R2: 64 → 12 → 14
     - R1: 6 → 2 → 2
   - Test of the pass: I subtracted every positive measured-row bias from the concealed rows in each site × height × band cell and recounted. 707 still gives 23.3 % (all bias removed, both signs: 22.3 %), under the 29.0 % gate. The pass is now physical: most of the remaining removed violations are R2 and VA high-antenna rows whose measured rows are optimistic or unbiased.

4. **My other required items are met.**
   - Test vectors: the test now runs all 18 valid vectors through the `R_m`/`w_s_m` overrides, plus the 5 error rows. Its file MD5 (dff1d0fe…) matches the NTIA/ITS file I downloaded. I didn't run MATLAB; 33/33 is the worker's report.
   - `"hold3"` is implemented as `f = min(f, 3)` and tested. It scores within 0.01 dB of `"extend"` (709).
   - Censored violations by site are logged for every run (R1 5.7, R2 14.7, VA 47.5 %), and the helper reproduces them.
   - LOG and B07.md corrections: B07.md carries the "18, not 16" correction note. Its line "a MATLAB test of all 18 is still to be added" is now out of date. The older "B07 planned" LOG entry still says "16" with no pointer to the correction.

5. **New or still-open problems** (none blocks the keep):
   - **R2 concealed rows got more optimistic.** By band, errors are −1.9, −12.2, −36.1, −29.9, and −57.0 dB (701: −8.6 to −43.4). `"hold3"` removes most of the R2 term above 3 GHz. This is the right call for staying inside the validated range, but R2 concealed loss is still largely missing.
   - **R2 censored is 14.7 %, against 6.8 % for stock,** all on open rows from the 604 base. A site-by-site gate would still fail at R2. That rule is Nick's call; the keep report should state the R2 figure.
   - **The archive keeps 701 on the Pareto front.** It shows 13.19 / 21.4 %, numbers that come from the incorrect form. Mark 701 as superseded or ineligible so it isn't picked as a parent.
   - **707 versus 709:** keep 707. `"hold3"` stays inside the validated 0.03 to 3 GHz range, and the data can't tell the two rules apart (0.01 dB composite).

Suggested follow-ups:
- Check that loss falls monotonically as the antenna rises on the 604 base, starting with path R1-020-T8 (source: the FRAMEWORK physics battery, height-gain check).
- Test a rule for how clutter combines with terrain shadow on obstructed concealed paths, such as taking the larger of the two terminal obstruction losses instead of their sum. Base it on the ITU-R P.526 treatment of multiple obstacles near one terminal, and register a prediction first.
