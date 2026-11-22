# Ranked hypotheses

Date: 2026-11-22. These are prospective hypotheses. Ranks combine physical leverage, novelty relative to experiments 101–506, compatibility with fixed inputs, falsifiability, expected transfer, and implementation risk. A high rank is value of information, not a predicted keep.

| Rank | ID | Hypothesis | Mechanism and source | Primary target | Main falsifier |
|---:|---|---|---|---|---|
| 1 | H01 | Coupled fields from separated ridges are less lossy than independent edge sums | Vogler NTIA TR-83-124 §§2–3; TR-81-86 | R2 multi-ridge bounds and measured rows | Coupled field residual is zero or has wrong sign across matched separations |
| 2 | H02 | ITM's LOS reflected-ray phase should use curved-Earth tangent heights at its virtual anchors | ITU-R P.530-19 Annex 1 §§6.1.2.3–6.1.2.4.1 | LOS high-height contrasts and 3–10 GHz | Phase-only residual is inconsistent across reciprocal height contrasts |
| 3 | H03 | A prominent common ridge reduces long-term fading through two-leg distribution convolution | NBS TN 101 §§7.5, 10.8; Barsis and Kirby 1961 | Long-term shape on obstruction-dominated paths | No shape improvement in independent receiver groups, or dependence invalidates the result |
| 4 | H04 | A single interdecile roughness statistic loses path-scale obstacle structure | NTIA TR-82-100; ITM source | R2 multi-scale residuals | Detrending/quantile changes do not alter mechanism-stratified residuals |
| 5 | H05 | Finite crest curvature adds a rounded-obstacle term after knife-edge loss | ITU-R P.526-16 §4.2; Dougherty and Maloney 1964 | Matched isolated ridge frequency contrasts | Radius estimate is unstable or 30 m profiles cannot identify curvature |
| 6 | H06 | The profile's continuous Fresnel clearance should replace a binary blocked/LOS classification | ITU-R P.526-16 §§2.4–2.5 | Near-grazing paths | Clearance taper fails continuity or is indistinguishable from H01/H05 |
| 7 | H07 | A Vogler-calibrated up-to-six-edge surrogate can preserve coupling at coverage cost | NTIA TR-26-580 | R2 multi-edge paths | Surrogate departs from Vogler oracle beyond declared error |
| 8 | H08 | Epstein–Peterson loss needs a coherent coupling correction for near-grazing edges | Vogler 1981; Epstein–Peterson comparator | R2 measured rows | Correction recreates B05 edge steps |
| 9 | H09 | Smooth-earth attenuation should enter as an excess over a profile-consistent reference | P.526-16 §4.5; P.452-18 §§4.2–4.6 | R2 level and censored bounds | Delta construction remains optimistic after profile coupling |
| 10 | H10 | ITM's diffraction-line extrapolation from `d3,d4` is a source of path-length bias | ITM algorithm; working-paper diagnosis | 15–150 km rough paths | Path-distance anchor has no independent residual pattern |
| 11 | H11 | Actual profile horizons should control propagation-region selection | ITM algorithm; P.526 general path | Obstructed LOS-region rows | Profile classification improves only D01 rows or causes jumps |
| 12 | H12 | Terminal effective-height window should be symmetric under path reversal | ITM source; NTIA algorithm documentation | Reciprocity battery and LOS | Fix has no residual asymmetry or changes unrelated modes |
| 13 | H13 | Rounded-obstacle curvature should be estimated from tangent-ray intersection rather than sampled apex | P.526-16 Fig. 8 and §§4.2.2, 4.2.3 | H05 identifiability | Alternate windows disagree beyond source tolerance |
| 14 | H14 | Terrain roughness requires separate long-scale and Fresnel-scale components | NTIA Δh definition; P.526 Fresnel clearance | R2 frequency-distance interaction | Scale decomposition adds no predeclared explanatory contrast |
| 15 | H15 | P.2001-style clear-air tail shape can transfer only when anchored to ITM's own 10/50/90 values | P.2001-6 Attachment B/E | Long-term tails | Tail changes violate median or censoring constraints |
| 16 | H16 | Diffraction plus Rayleigh scatter must be combined as fields/powers at the correct statistic | NBS TN 101 §9.5 | Crossover rows | Combination shifts p50 or fails asymptotic limits |
| 17 | H17 | Shared atmospheric conditions correlate the two legs of an obstacle path | NBS TN 101 §10.8 | H03 sensitivity | Correlation sensitivity reverses the claim |
| 18 | H18 | Ground divergence changes reflected amplitude independently of phase | ITU-R P.530-19 eq. (132) | H02 rival ablation | Amplitude-only rival explains the signed residual better |
| 19 | H19 | Frequency-dependent surface roughness changes reflection above 3 GHz | Ament 1953; P.530-19 reflection model | LOS high-frequency cells | Required roughness is unavailable from frozen inputs |
| 20 | H20 | Terminal vegetation/clutter explains Virginia bias | ITU-R P.833; P.2108 | VA open/concealed pairs | No public land-cover input or paired support |
| 21 | H21 | Profile aliasing at 30 m creates an identifiable uncertainty envelope | ITM profile requirement; P.526 Fresnel scale | Near-grazing paths | Ensemble spread is below numerical noise or not transferable |
| 22 | H22 | Frequency-dependent obstacle aperture explains within-path gradients | P.526 rounded and Fresnel geometry | Fixed path, multiple frequencies | Gradient is absent after height/polarization pairing |
| 23 | H23 | Climate-conditioned horizon geometry is confounded with existing ITM effective Earth | P.453; P.452 | Long-term transhorizon | Double counting or unavailable path-time refractivity |
| 24 | H24 | A censored likelihood is a better scientific objective than RMS | ITS bounds; repository evaluator | Evaluation methodology | It changes selection without improving physical diagnostics |

## Selection rules

H01–H05 are the detailed proposals. Each has a zero-fitted-parameter primary test, a source-derived diagnostic, a geometry-only eligibility rule frozen before looking at scores, and a path-cluster inference plan. Fixed eligibility thresholds count toward design complexity even when no parameter is fitted. H06–H24 remain reserves until a finalist fails its mechanism test or a required input becomes available.
