# Implementation roadmap

This is a proposed order of work. It authorizes no code or experiment.

1. Freeze a proposal manifest with source URLs, edition, profile-selection code description, eligibility thresholds, and the snapshot commit. Hash the manifest before any score is read.
2. Build source-level unit tests for H01, H02, and H05. Build feature-invariance tests for H04 and distribution tests for H03. Run only after approval.
3. Run H01 as a diagnostic oracle and full-profile residual extension. If it cannot meet continuity or its eligible cohort cannot reach the 373-repair bound relative to 502, do not promote it globally.
4. Run H02 phase-only and amplitude-only ablations. Treat signed within-path height contrasts as the primary mechanism outcome.
5. Run H03 shape-only analysis. Require support in at least two receiver groups and a correlation sensitivity before interpreting the result.
6. Run H04's detrending-by-quantile-by-scale factorial controls. Reject any effect that appears only after changing more than one factor without an ablation.
7. Run H05 curvature diagnostics only on profiles meeting source assumptions. If 30 m profiles cannot identify the radius, retain the diagnostic and stop.
8. Apply the repository gates to any candidate that survives mechanism tests. Report against stock ITM and R02. Do not use the lockbox during proposal selection.
9. Before a final claim, validate the frozen candidate on an independent source such as the Ofcom below-6-GHz data, subject to profile and terminal metadata sufficiency. Record any missing input as unresolved.

The preferred first implementation is H02 because it has no new fitted parameter and a direct reciprocal geometry check. H01 has the highest potential information value for the R2 mechanism but carries the greatest representation risk. H03 is valuable for long-term shape and should not be judged by p50 improvement because its design holds the median fixed.
