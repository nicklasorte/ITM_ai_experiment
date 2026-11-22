# H04 — Multi-scale terrain roughness without a new terrain input

Status: proposed design. No implementation or evaluation has occurred.

## Hypothesis

ITM compresses the detrended profile into one interdecile `Δh(d)`. That statistic is appropriate for a path-scale roughness descriptor, but it cannot distinguish one broad ridge from several separated ridges or determine which terrain scale overlaps the first Fresnel zone. A deterministic multi-scale representation could improve the structural loss while retaining the existing model's physical inputs.

NTIA TR-82-100 defines the point-to-point roughness statistic as the 90th minus 10th percentile of elevations about a fitted line. This proposal tests the representation itself. It does not change the terrain, datum, refractivity, effective Earth, or terminal heights.

## Factorial design before scoring

Construct a profile-only feature family at fixed physical-distance windows. Factor A is detrending: the existing least-squares line versus a continuous weighted line whose endpoints and terminal-reference convention are held fixed. Factor B is quantile representation: the existing interdecile range versus a predeclared pair of lower and upper quantile spreads at fixed windows. Factor C is scale: two or three windows tied to the path's first-Fresnel radius at the dominant obstruction, with bounds fixed from the profile and frequency before outcomes are read.

The primary candidate uses a nonnegative weighted combination of the scale spreads in ITM's existing roughness and reflection terms. The weights are fixed from geometry, for example normalized Fresnel-overlap weights, and are not fit to site labels. If the combination requires a fitted coefficient, fit it inside the repository's leave-one-site-out calibration and apply the 0.5 dB-per-parameter rule. Do not silently replace `Δh` in horizon or effective-height calculations in the first experiment. This separates the roughness statistic from the rest of ITM's geometry.

## Falsifiable predictions

The proposed mechanism predicts a residual that changes with the ratio of obstacle separation to Fresnel radius. It should distinguish multi-ridge R2 paths from a single dominant ridge at similar legacy `Δh`, while leaving flat, affine, and slowly varying profiles unchanged after the detrending factor is controlled. It predicts stronger frequency dependence when the same fixed path is evaluated at multiple frequencies. If all effects disappear when A and B are crossed, the single-statistic hypothesis is unsupported.

## Synthetic and measurement tests

Before a score, test flat terrain, affine ramps, a single Gaussian ridge, two equal separated ridges, a broad plateau, noninteger trim endpoints, reversal, and collinear interior refinement. A vertical offset or linear tilt must not change the roughness feature itself. Refining an interior sample without changing the piecewise-linear terrain must not change it. Endpoints, sample spacing, frequency, and the profile hash must be recorded.

For measurements, predeclare the R2 multi-ridge cohort from profile geometry and D03 edge diagnostics without using measured outcomes. Use matched paths at similar distance, frequency band, antenna heights, and legacy `Δh`. Analyze measured and censored rows separately. A candidate must improve the multi-ridge contrast without worsening the single-ridge negative control. Support must be reported by site, frequency, distance, and number of unique profile hashes.

## Limits and stop rules

This is a component experiment. Changing terrain datum can change ITM's atmospheric initialization, so the end-to-end output need not be invariant to altitude even when the roughness feature is. Horizon and integer-window ties can create discontinuities. Stop if the feature is not continuous under endpoint perturbation, if reversal differs beyond the baseline tolerance, or if a gain is confined to rows sharing one profile hash. Do not interpret a successful roughness feature as proof that it represents transverse terrain or clutter.

## Promotion and sources

Run only after approval and only with a new off-by-default switch. Compare stock ITM, R02, and the current eligible parent. Apply the complete validation protocol, including paired path bootstrap, site holdouts, censoring, and screened scoring. The feature can be retained as a diagnostic even if the global gates reject it. Primary source: Hufford, Longley, and Kissick, NTIA TR-82-100, https://its.ntia.gov/publications/download/82-100_ocr.pdf . The Fresnel-scale motivation is ITU-R P.526-16, https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.526-16-202511-I!!PDF-E.pdf .
