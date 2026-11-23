# Five proposed ITM experiments — independent review

Date: 2026-11-23. Reviewed against `main` at `ed47ac3936d07ad4ab0dbd8afc4cab9bdb3cb888`, including B12–B14 and current LOG. These proposals do not authorize or execute runs. Current model is 707; compare against the current `best` with identical inputs and current screens. The 29.0% overall censored ceiling and existing gates apply. H02/H03 were screened out by B12 history matching (maximum possible gains 0.128 and 0.008 dB); they are not new frozen-data candidates. NLCD clutter additions were tested and rejected. D06 showed P.617 changes the fading tail but introduced distance discontinuities; D06a/b are diagnostics, not keep candidates.

## 1. Fixed-geometry coupled two-screen oracle (H01)

**Question.** Does coupled diffraction past two separated ridges explain path loss or the 707 cascade's principal-edge jump, when the screen locations are held fixed?

**Design.** Select geometries from profile alone before outcomes. On the logged 707 height-sweep path, hold both ridge coordinates fixed across the 18.5–21 m receiver-height sweep; add other eligible two-ridge paths by a frozen rule. Compute the Vogler coupled-field solution and compare against (a) each screen alone and (b) the independent-edge calculation on the same screen coordinates. Report coupled-minus-independent and coupled-minus-single separately. First establish the ideal-screen oracle; only afterward test a terrain-to-screen mapping. Do not assert that coupled fields are always less lossy: TR-26-580 Table 17 has counterexamples to universal ordering.

**Predictions and falsifiers.** The fixed-screen calculation should vary continuously with height and ridge spacing. If it does not reduce the jump or does not match measured contrasts on independently supported paths, the proposed mechanism does not explain the 707 discontinuity. A result from ideal screens alone supports the diffraction calculation, not the terrain selector or a full-model correction.

**Risks/controls.** Thin absorbing screens, small angles and one-dimensional terrain are approximations. Count profile support, censoring and path/site support before proposing model integration. Current 707 and fixed clutter/scatter settings are the parent. Sources: Vogler, NTIA TR-83-124 §§2–3, https://its.ntia.gov/publications/download/83-124_ocr.pdf; NTIA TR-26-580 Table 17, https://its.ntia.gov/publications/download/TR-26-580.pdf.

## 2. P.617 fading-side distribution with a continuous distance transition

**Question.** Can P.617-6 improve the high-loss (fading) side of long-term troposcatter distributions without importing its poor enhancement-side behavior or a step at ITM's mode boundary?

**Design.** D06 found gains at 99% in some 100–300 km and >300 km strata, while 1% worsened; P.617-6 §4 describes the troposcatter distribution primarily above 50%, and §5 treats enhancements separately. Keep 50% exactly at 707 and retain ITM below 50%. Specify a distance-continuous blend before any run: blend weight must be a deterministic function of existing path geometry and equal zero/one at predeclared boundaries. Derive the combination in linear power only if the cited mechanism assumptions support it; otherwise call it an empirical interpolation and do not claim field physics. Freeze transition interval from model geometry, not observed residuals. Test 90%, 99%, and 99.9% across distance/frequency and receiver groups, plus dense sweeps through the ITM mode transition and through blend endpoints.

**Falsifiers.** No tail gain on the same-screen dataset, gain concentrated in artifact-screened records, changed median, or a distance jump above the physics margin rejects the proposal. Report both tail sides separately; an aggregate shape score cannot hide opposite-sign effects.

**Risks/controls.** B14 D06a/b already evaluated discontinuous forms. This is a new continuous formulation only after its exact equation and assumptions are documented. Current refractivity lookup is annual midpoint climatology, not event meteorology. Source: ITU-R P.617-6 (2025), https://www.itu.int/rec/R-REC-P.617-6-202509-I/en.

## 3. Curvature loss for one isolated, resolved crest (H05)

**Question.** Does finite crest radius add a frequency-dependent diffraction term beyond knife-edge loss on paths with one genuinely resolved obstruction?

**Design.** Freeze a geometry-only cohort requiring one isolated crest, original terrain knots on both flanks, documented vertical/horizontal uncertainty, and no unresolved competing reflection. Compare P.526 knife-edge J(ν) with the rounded-obstacle J(ν)+T formulation, using the published equations and a common radius across paired frequencies as the primary analysis. Use per-frequency radii only as sensitivity analyses because a radius that changes with wavelength can create an artificial frequency trend. Preserve detected and censored pairs as interval constraints; never infer a paired frequency difference from two lower bounds. Require replication across independent paths and sites before any full-profile integration.

**Falsifiers.** The curvature increment fails if its sign/magnitude is not robust to measurement uncertainty, common-radius controls remove the apparent effect, or no independent paths meet resolution criteria. No support means unresolved, not a null physical effect.

**Risks/controls.** A 30 m DEM cannot establish subpixel crest curvature, transverse smoothness or absence of out-of-plane reflections. This is a diagnostic; B09's failed full P.526-16 cascade does not validate a different integration. Source: ITU-R P.526-16 §4.2, https://www.itu.int/rec/R-REC-P.526-16-202511-I!!PDF-E.pdf; Dougherty and Maloney (1964), https://nvlpubs.nist.gov/nistpubs/jres/68D/jresv68Dn2p239_A1b.pdf.

## 4. Exact path-length terrain roughness estimator audit (H04)

**Question.** Does ITM's sampled interdecile roughness depend on profile sampling when the underlying piecewise-linear terrain is unchanged?

**Design.** Reproduce the pinned code's trim, short-profile rule, distance correction and consumers first. The legacy short-span rule that returns Δh=0 when fewer than two intervals remain must be retained as a separate stratum/control. Compare legacy versus continuous least-squares detrending crossed with sample-weighted versus exact path-length-weighted 10th–90th percentiles (2×2). Use exact integrals over piecewise-linear segments; define quantiles as generalized inverses of the path-length CDF, including flat-segment point masses. Before connecting to loss, test affine invariance, vertical-shift invariance, reversal, collinear vertex insertion and analytic synthetic profiles. Then test on held-out paths with all consumers of Δh inventoried; calibration was fitted to the legacy statistic and may no longer apply.

**Falsifiers.** If Δh is invariant to representation within tolerance, or changes do not explain held-out residuals after matching geometry, stop before changing ITM. Numerical invariance alone is not a propagation improvement.

**Risks/controls.** This is an estimator audit, not a claim that a new multiscale feature has physical authority. Do not alter terrain source, profile spacing, evaluator or data. Source: NTIA TR-82-100, https://its.ntia.gov/publications/download/82-100_ocr.pdf.

## 5. External paired height-gain study of curved-Earth reflection phase (H02 external)

**Question.** Does curved-Earth specular geometry predict measured height-dependent two-ray changes better than the flat-Earth phase and a divergence-amplitude rival?

**Design.** H02's code exists behind a switch, but B12 screened the effect out on current measurements: 2,571 of 16,805 Phase 2 rows changed, with maximum possible composite gain +0.128 dB. Do not resubmit it as a frozen-data scoring experiment. Instead, acquire a new paired campaign at surveyed, smooth reflecting sites with known dielectric properties and reflection points. Sweep one terminal's height at fixed frequency and distance, record complex field or calibrated received power with uncertainty, and collect reciprocal configurations. Pre-register flat-phase, curved-phase-only, and divergence-amplitude-only predictions; do not fit a correction on the test sites. Require independently held-out sites and report where the spherical small-angle approximation fails.

**Falsifiers.** Curved phase loses if it does not predict signed height contrasts better than flat phase across sites, or if the divergence-only rival explains the effect. Missing surface/antenna characterization makes the mechanism unidentified.

**Risks/controls.** Existing historical spot records lack reflection-point and surface characterization; the frozen data cannot answer this question. Sources: ITU-R P.530-19 Annex 1 §6.1.2.3, https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.530-19-202509-I!!PDF-E.pdf; NTIA TR-86-200, https://its.ntia.gov/publications/download/86-200_ocr.pdf.

## Independent reviewer disposition

The reviewer checked the current experiment log, B12, B14 and the prior proposal drafts. The review rejected two tempting but invalid carryovers: (1) H02 and H03 as new scored experiments on the current data, because B12's pre-run screen proved they cannot clear the gain gate; and (2) NLCD terminal clutter as untested, because 711 already worsened the composite and was rejected. H01 is narrowed to a fixed-geometry oracle to isolate field coupling from an arbitrary ridge selector. H05 is diagnostic until native profile support establishes curvature. H04 is limited to a reproducible numerical audit and must retain the short-span branch. P.617 is conditional: D06 supports asymmetric tails, but the follow-up must first state a source-justified, continuous transition and test its boundary. H02 survives only as an external measurement study. No reviewer found grounds to promise a score gain. No experiment was executed in preparing this review.

## Repository controls

Register exact parent, switch overrides, cohort rule, equations, predictions and stop criteria in the batch plan before any run. Compare with current `best` using identical data and current screening membership. Apply the present physics battery plus the 1%/99% distance continuity checks described in B14; report the known real-path height-sweep issue. Do not edit MATLAB, evaluator, dataset, or historical result records as part of this proposal.