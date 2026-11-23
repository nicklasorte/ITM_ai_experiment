# Five ITM experiment recommendations — independent review

Date: 2026-11-23. Reviewed against the current repository history, including B12, B14, B15 and the phase plan. These are recommendations and dispositions, not authorization to run experiments. The current kept parent is 707. Compare future work against the current `best`, with matching data and screening membership.

## 1. Fixed-geometry coupled two-screen oracle (H01) — advance first

**Question.** Does coupled diffraction past two separated ridges explain 707’s large principal-edge jump when ridge locations are held fixed?

**Design.** Freeze the two ridge coordinates from profile geometry before looking at measurements. On the documented R2-020 receiver-height sweep, keep those coordinates fixed over the 18.5–21 m sweep. Compare Vogler’s coupled-field solution with each-screen-alone and independent-edge calculations at the same coordinates. Report coupled-minus-independent and coupled-minus-single separately. Establish continuity and reference behavior before testing any terrain-to-screen selection rule.

**Falsifier and limit.** If the fixed-geometry oracle retains the discontinuity or fails to explain the measured height contrast, this mechanism does not explain the logged jump. Ideal screens test the field calculation; they do not validate the ridge selector or show that real terrain follows thin-screen assumptions. Published examples also refute a universal claim that coupled diffraction is always less lossy than independent edge sums.

**Sources.** Vogler, NTIA TR-83-124 §§2–3, https://its.ntia.gov/publications/download/83-124_ocr.pdf; NTIA TR-26-580 Table 17, https://its.ntia.gov/publications/download/TR-26-580.pdf.

## 2. P.617 fading-side time distribution — close on current data

B15 already specifies continuous P.617 fading-side variants and screens the family against the current gain ceiling. The stored proxy estimates only about +0.10 dB maximum full-composite gain, below the 0.3 dB acceptance threshold; the screened estimate is similarly small. D06 also showed that the enhancement and fading sides behave differently and that naïve switching creates distance discontinuities.

**Recommendation.** Do not build or run this as a current keep attempt. Retain B15’s registered formulation and ceiling calculation as the decision record. A new study would need a distinct mechanism or independent data; renaming the same P.617 correction is not a new experiment.

**Source.** B15, https://github.com/nicklasorte/ITM_ai_experiment/blob/main/experiments/batches/B15.md; ITU-R P.617-6 §4.1, https://www.itu.int/rec/R-REC-P.617-6-202509-I/en.

## 3. Rounded loss from one isolated, resolved crest (H05) — conditional diagnostic

**Question.** Does finite crest radius add a frequency-dependent diffraction increment beyond knife-edge loss for a genuinely resolved, isolated ridge?

**Design.** First count paths with original terrain knots on both flanks, documented elevation and position uncertainty, one isolated crest, and no unresolved competing reflection. Freeze the cohort from geometry alone. Compare P.526’s knife-edge (J(ν)) with rounded-obstacle (J(ν)+T). Use a common radius across paired frequencies as the primary contrast; frequency-specific radius estimates are a sensitivity test because they may create an artificial frequency trend. Treat detected and censored measurements as interval constraints, and require independent path and site replication.

**Falsifier and limit.** If plausible radius uncertainty reverses the predicted increment, or no independent paths meet the resolution rule, the result is inconclusive. A 30 m DEM cannot establish subpixel crest curvature or transverse smoothness. This is a mechanism diagnostic, not a validated replacement for B09’s failed full-profile formulation.

**Sources.** ITU-R P.526-16 §4.2, https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.526-16-202511-I!!PDF-E.pdf; Dougherty and Maloney (1964), https://nvlpubs.nist.gov/nistpubs/jres/68D/jresv68Dn2p239_A1b.pdf.

## 4. Exact path-length terrain roughness audit (H04) — advance as a numerical audit

**Question.** Does ITM’s sampled interdecile roughness change when the same piecewise-linear profile is represented with different collinear sample points?

**Design.** Reproduce the pinned code’s trimming, distance correction, consumer functions, and short-profile rule. Keep the legacy Δh=0 branch for spans with fewer than two profile intervals as a separate control. Cross legacy versus continuous detrending with sample-weighted versus exact path-length-weighted 10th–90th percentiles. For the continuous estimator, use exact segment integrals and the generalized inverse of the path-length CDF, including point masses from flat segments. First test affine/vertical-shift invariance, reversal, collinear vertex insertion and analytic profiles; only then assess held-out prediction changes. Inventory every Δh consumer because existing calibrations use the legacy statistic.

**Falsifier and limit.** If the estimator is already invariant within numerical tolerance, stop. A more stable statistic alone does not establish more accurate propagation.

**Source.** Hufford, Longley and Kissick, NTIA TR-82-100, https://its.ntia.gov/publications/download/82-100_ocr.pdf.

## 5. External curved-Earth reflection height-gain campaign (H02 external) — conditional on new measurements

B12 screened the curved-phase change out as a keep candidate on the frozen dataset: its maximum possible composite gain was +0.128 dB. The historical measurements do not resolve reflection points or surface properties well enough to identify the phase mechanism.

**Design.** Use surveyed smooth reflecting sites with measured dielectric properties and known geometry. Sweep one terminal’s height at fixed frequency and distance; collect calibrated complex field where feasible, otherwise calibrated power with uncertainty. Pre-register flat-phase, curved-phase-only and divergence-amplitude-only predictions. Use independent sites for validation and do not fit a correction to the test sites.

**Falsifier and limit.** The curved-phase mechanism loses if it does not predict signed height contrasts better than flat phase across sites, or if the amplitude-only rival explains the results. Unknown reflector geometry or surface properties make the comparison unidentifiable.

**Sources.** B12 decision, https://github.com/nicklasorte/ITM_ai_experiment/blob/main/experiments/batches/B12.md; ITU-R P.530-19 Annex 1 §6.1.2.3, https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.530-19-202509-I!!PDF-E.pdf; NTIA TR-86-200, https://its.ntia.gov/publications/download/86-200_ocr.pdf.

## Independent review conclusion

Advance H01 as a reference diagnostic and H04 as a numerical audit. Run H05 only if the profile-support count justifies it. Treat the curved-reflection work as a new-data campaign. Close the P.617 current-data keep proposal under B15’s headroom result. No proposal guarantees a score gain.

Before any future run, register the exact parent, inputs, cohort, equations, predictions and stop rules; use current screening membership; apply existing score and physics gates, including the distance-continuity checks from B14. No experiment was executed in preparing this document.
