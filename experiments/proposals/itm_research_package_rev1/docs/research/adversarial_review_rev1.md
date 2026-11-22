# Adversarial review

This review was conducted as an independent desk pass over the repository snapshot, experiment log, source equations, and proposal mechanisms. It found several conditions that can invalidate an apparently successful experiment.

## Reachability and score leakage

Run 502 has 966 violations among 2,045 censored bounds. The repository ceiling permits at most 593 violations, so a proposal that retains 502 outside a restricted cohort must repair at least 373 of its current violations net of new violations. Count this before any implementation. A local mechanism result can be scientifically interesting and still be unable to pass the global gate.

The 502 branch is a diagnostic parent, not the eligible best. All promotion comparisons use stock ITM as the current eligible parent and R02 as the constrained recalibration comparator. A proposal cannot select paths using scores, censored outcomes, or post hoc residuals.

## Mechanism-specific challenges

- H01 can recreate B05's edge steps if two-screen eligibility is binary. The full-profile extension must taper to zero on affine profiles and remain continuous under ridge separation, coalescence, reversal, and frequency sweeps. Vogler's coupled field is an oracle for a declared screen cohort, not proof that a 1-D profile contains the true 3-D field.
- H02 uses P.530's known reflecting-area construction at ITM's virtual anchors. That extrapolation is a hybrid. Its signed effect depends on phase. The phase-only intervention must retain stock amplitude and be compared with a separate divergence-amplitude rival.
- H03 requires independent legs for the TN101 convolution. Shared weather, refractivity, and receiver conditions can correlate them. The convolved sum must be recentered at its own median because medians do not add in general. The p50 prediction and censored classification must remain unchanged.
- H04 risks hiding an integer-window or endpoint bug inside a new roughness statistic. Detrending, quantile rule, and scale must be factorially separated. A roughness-feature invariant does not imply an invariant full ITM loss because altitude affects atmospheric initialization.
- H05 requires P.526's isolation, Fresnel-clearance, and reflection assumptions. A 30 m one-dimensional profile cannot establish transverse clearance, surface dielectric properties, or sub-sample crest shape. P.526's printed curvature formula has a branch join near 4 and source text that calls the radius aggregation a median while the displayed equation is an arithmetic mean. Verify the PDF and record the convention.

## Shared statistical threats

Rows from one path and repeated frequencies are correlated. Bootstrap paths nested within site or receiver group. Distinguish 513 site/siting IDs, 426 nominal paths, 444 profile hashes, and raw rows. P.452 has incomplete row and percentile coverage and cannot be treated as a paired score for all ITM rows.

Censored values are lower bounds. Use strict violation `prediction < bound`, retain uncensored RMS separately, and never impute a censored value as exact. Report the count and denominator with every violation percentage.

## Kill conditions

Stop a proposal if its source formula is not reproduced in synthetic limits, if the implementation needs a hand-tuned offset, if the physics battery fails, if a feature is unsupported in the profile cohort, or if its apparent gain is confined to one profile hash or one receiver group. Keep a negative result as a documented mechanism test. Do not combine proposals until each individual mechanism has passed its source and identifiability checks.
