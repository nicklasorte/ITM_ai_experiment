# H02 — Curved-Earth phase at ITM's LOS anchors

Status: proposed design. No implementation or evaluation has occurred.

## Hypothesis

ITM's line-of-sight term uses effective heights and an effective-Earth horizon, but its reflected-ray phase contains the flat-Earth product `h1*h2`. At ITM's synthetic LOS anchors, replace that product with the heights above the curved-Earth tangent geometry. The phase-only intervention should change signed height contrasts while preserving ITM's reference loss, roughness factor, and final variability map.

P.530-19 Annex 1 §6.1.2.3, equations (121)–(126), constructs reflection geometry from path curvature and Fresnel clearance. Equation (132) supplies a separate Earth-divergence factor. These are primary design sources, not a claim that P.530 is an ITM replacement.

## Implementable formulation

At each existing LOS anchor `s` passed to `line_of_sight_loss`, set `R=1/gamma_e`. Solve by bracketed bisection for `x` in `(0,s)`

`h1 - x^2/(2R) = h2 - (s-x)^2/(2R)`.

Let `u=h1-x^2/(2R)` and `v=h2-(s-x)^2/(2R)`. For the reflected-ray phase, use

`phi_curved = (f_MHz/47.7) * 2*u*v/s`.

Retain the stock coefficient, reflection coefficient, roughness attenuation, and `d_sML` blend. Apply the change only to the phase argument, and only where the current code evaluates the two-ray LOS term. If `u` or `v` is nonpositive, use a zero-phase tangent continuation at the smooth horizon and record the condition. Do not introduce a new fitted coefficient. Keep `cfg.line_of_sight="itm"` as the off state and increment the variant version.

The formula has a reciprocal solve and a flat-Earth limit. With equal terminal heights at half the smooth horizon, the curved-to-flat phase ratio is `9/16`. These are hand checks before any score is read. The divergence-factor rival is a separate ablation using P.530 eq. (132) on the stock reflected amplitude with phase unchanged.

## Identification cohort and predictions

Predeclare paths with ITM LOS mode, finite positive effective heights, and at least two receiver-height observations at the same path and frequency. Stratify by frequency band and effective-height ratio. Compare signed within-path height contrasts, keeping censored observations as inequalities. The phase hypothesis predicts a frequency- and height-dependent residual that changes sign with the reflection phase. It predicts little change on transhorizon rows and zero response in the flat-Earth limit. A global score gain is not required for mechanism support, but promotion requires the repository gates and a leave-one-site-out gain.

Use the 465 Virginia open/concealed profile-matched pairs only as a negative control for terrain-only changes. A treatment can differ between open and concealed terminals because the terminal environment is not an input. Reversing an identical input must preserve the forward/reverse result within the physics tolerance.

## Tests and kill criteria

Before measurements, test flat terrain, reciprocal reversal, equal-height half-horizon geometry, `R→∞`, `u=v=0`, frequency sweep, and continuity across the zero-phase continuation. Compare phase-only and amplitude-only ablations. Stop if the branch changes transhorizon output, creates a phase or height discontinuity, violates the two-ray lower bound, or requires a fitted coefficient. Stop the scientific claim if height-contrast signs are not reproducible in at least two receiver groups.

## Acceptance and provenance

Run only after approval, against stock ITM, R02, and the current eligible parent using frozen folds. Apply `docs/research/validation_protocol_rev1.md`, including the 0.3 dB primary and screened gains, paired 95% lower bounds above zero, no site RMS increase over 0.5 dB, and no more than one percentage point increase in censored violations. Report the signed mechanism result even if the score fails. Sources: P.530-19 https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.530-19-202509-I!!PDF-E.pdf ; Hufford 1985 memo https://its.ntia.gov/media/50675/hufford_1985_memo.pdf .
