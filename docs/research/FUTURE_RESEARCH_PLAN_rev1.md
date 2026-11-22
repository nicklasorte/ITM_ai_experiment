# Future research plan: physically grounded ITM improvements

Status: **PROPOSED — future work only; not approved for implementation or experiments**  
Prepared: 2026-11-21  
Repository baseline: `000-baseline`  
Scope: research and experiment designs; preserve existing MATLAB implementation, evaluator, datasets, experiment records, and frozen splits.

## Purpose

Investigate physical explanations for systematic errors in the Irregular Terrain Model (Longley–Rice), rather than optimizing only the composite evaluation score. Every candidate must specify a causal mechanism, falsifiable prediction, independent control, and validation strategy before implementation.

## Evidence from existing experiments

- Baseline composite RMS: 16.0 dB; Phase 2 cell RMS: 18.3 dB; long-term level: 24.6 dB; long-term shape: 5.2 dB.
- Unconstrained recalibration R01: 12.4 dB composite, but fails physical and censored-data gates.
- Experiment 601: 13.35 dB and 25.8% censored violations; numerical gates passed, but independent reviewers rejected the physical interpretation.
- Experiment 603: 11.17 dB but 49.6% censored violations; rejected.
- Experiment 604: 12.78 dB but 31.5% censored violations against a 29% gate; rejected.
- B07 introduced siting-aware clutter experiments and identified the need for row-level metadata. Review the *latest* experiment log and PR state before starting new work; the B07 plan may have been superseded.

Primary local evidence: [experiment log](../../experiments/LOG.md), [B07 plan](../../experiments/batches/B07.md), [working-paper findings](../../docs/WORKING_PAPER_FINDINGS.md), [archive](../../results/archive_rev1.txt).

## Ranked future hypothesis portfolio

Priority is a research judgment, **not** a measured performance result. Do not repeat earlier failed variants without stating the distinct mechanism.

| Rank | ID | Falsifiable physical hypothesis | Principal discriminator |
| --- | --- | --- | --- |
| 1 | H01 | Open/concealed matched pairs isolate terminal obstruction from terrain loss | Paired differences across frequency and height |
| 2 | H04 | Sub-profile foreground Fresnel obstruction explains residual loss on nominally open paths | Clearance and path-length stratification |
| 3 | H05 | Multi-edge interaction, not the count of edges alone, explains diffraction overshoot | Ridge spacing relative to Fresnel scales |
| 4 | H06 | Rounded ridges require curvature-sensitive diffraction instead of knife-edge approximations | Curvature and frequency scaling |
| 5 | H09 | Terrain profile sampling uncertainty shifts horizon classification and diffraction loss | Stability under controlled profile perturbations |
| 6 | H02 | Terminal obstruction depends on vegetation/building geometry, not a constant offset | Height and frequency controls |
| 7 | H03 | Clutter correction and empirical A_fo overlap and double-count the same loss | Factorial ablation |
| 8 | H07 | Effective antenna height on sloped terrain distorts regime selection | Structural versus effective height |
| 9 | H08 | Actual terrain horizons outperform smooth-earth regime boundaries in rough terrain | Transition-path stratification |
| 10 | H10 | Diffraction at actual path distance avoids extrapolation bias | Near-horizon continuity |
| 11 | H11 | Terrain irregularity should depend on Fresnel-scale structure | Frequency-conditioned roughness |
| 12 | H12 | Diffraction-to-scatter blending has regime-dependent bias | Transition-distance residuals |
| 13 | H13 | Smooth-earth excess should depend on terrain curvature | Smooth-profile controls |
| 14 | H14 | Obstacle isolation predicts when multi-edge methods overestimate loss | Isolated versus clustered ridges |
| 15 | H15 | Terminal clearance explains low-antenna underprediction | Antenna-height matched strata |
| 16 | H16 | Site-specific morphology explains some Virginia residuals | Siting controls, not site labels |
| 17 | H17 | Ground reflection assumptions affect near-LOS loss | Two-ray and polarization controls |
| 18 | H18 | Effective Earth curvature uncertainty dominates some near-horizon predictions | Refractivity sensitivity |
| 19 | H19 | Long-term variability needs regime-specific treatment | Time-percentile shape and level |
| 20 | H20 | Frequency scaling of diffraction/roughness is misrepresented above 6 GHz | Cross-band transfer |
| 21 | H21 | Open-path attenuation may reflect unrepresented local clutter | Paired open/concealed contrast |
| 22 | H22 | Profile endpoint discretization creates reciprocity errors | Forward/reverse numerical parity |
| 23 | H23 | Smooth-earth weighting creates excess loss on mountainous paths | Matched terrain classes |
| 24 | H24 | A physics-constrained residual correction can transfer across sites | Leave-site-out generalization and ablation |

## Five implementation-ready research specifications

These are **proposals for future implementation**, not authorization to change code or run experiments. For each, write a pre-registered experiment card with explicit inputs, equations and source editions, predicted signs by site and band, null controls, physical bounds, and stopping criteria.

### H01 — Paired-site differential clutter

**Mechanism:** Terminal obstruction can differ between open and concealed measurements while the path's terrain remains unchanged.  
**Prediction:** Concealed-minus-open loss is positive in matched pairs and exhibits frequency and antenna-height structure that an equal-mean constant offset cannot reproduce.  
**Inputs:** Existing Phase 2 matched-pair IDs and siting codes; require row metadata. Do not infer siting from identical terrain profiles.  
**Design:** Compare baseline, no-clutter, published P.2108 terminal correction within its valid range, and a non-fitted constant-loss control; stratify by site, frequency, height, and pair. Separate extension beyond 3 GHz as a labeled extrapolation sensitivity.  
**Falsification:** Paired differences do not exhibit the proposed physical dependence, or the constant control performs as well on held-out pairs.  
**Risks:** The C category conflates buildings and trees; correlated measurements; out-of-range P.2108 use.  
**Gate:** Verify all published test vectors, including the previously noted 18-row/6-row discrepancy; review B07 results before implementation.

### H04 — Foreground Fresnel clearance

**Mechanism:** Terrain sampled at 30 m may miss obstructions near terminals, including on paths coded open.  
**Prediction:** Underpredicted loss concentrates where the first Fresnel-zone clearance is small, with stronger sensitivity at higher frequency.  
**Inputs:** Frozen terrain profiles, endpoint geometry, frequency, heights. Do not substitute higher-resolution terrain into scored evaluation.  
**Design:** Compute diagnostic Fresnel clearance from existing inputs, compare with residuals on open paths, then propose a bounded geometry-derived correction only if diagnostic associations survive site-level holdout. Include flat and unobstructed controls.  
**Falsification:** Residuals show no clearance relationship after conditioning on distance and frequency, or the correction worsens LOS controls.  
**Risks:** Terrain resolution cannot reveal unseen vegetation/buildings; avoid treating inferred obstacles as observed facts.

### H05 — Multi-edge interaction correction

**Mechanism:** Closely spaced ridges do not always behave as independent knife edges; adding full losses can overpredict attenuation.  
**Prediction:** Error in multi-edge variants depends on normalized ridge spacing and Fresnel overlap, not just edge count.  
**Inputs:** Frozen profile, dominant ridge locations/heights, frequency, horizon geometry.  
**Design:** Compare the existing isolated-edge model with a geometry-based overlap correction; use single-edge, widely separated multi-edge, and symmetric-ridge synthetic controls. Preserve nonnegative diffraction excess where required and reciprocity. Compare against published multi-edge reference calculations before any scoring.  
**Falsification:** No conditional error reduction by overlap class or physical battery failures.  
**Risks:** Ad hoc overlap weights and double-counting empirical corrections; no measurement-fit constants without a training-only fit and independent holdout.

### H06 — Rounded-ridge transition

**Mechanism:** Knife-edge diffraction can misrepresent broad or rounded terrain crests.  
**Prediction:** Curvature-sensitive methods improve broad-ridge paths while converging to the sharp-edge limit for narrow ridges.  
**Inputs:** Existing profile samples and deterministic curvature estimator.  
**Design:** Derive ridge radius and its uncertainty from frozen samples; compare sharp-edge, rounded-obstacle, and smooth-earth limiting cases. Use ITU-R P.526 equations only after checking the exact current edition and their applicability.  
**Falsification:** No improvement in pre-defined rounded-ridge strata or failure to recover sharp-edge limits.  
**Risks:** 30 m sampling creates unstable curvature estimates; enforce an uncertainty/eligibility gate.

### H09 — Terrain-resolution uncertainty

**Mechanism:** Discretization of a fixed terrain profile can create unstable horizon and diffraction classifications.  
**Prediction:** Paths with near-grazing horizons have larger prediction sensitivity than paths with robust clearance.  
**Inputs:** Existing 30 m profiles only; no new terrain tiles or altered scored inputs.  
**Design:** Conduct *future diagnostic* perturbation/sampling sensitivity in a separate non-scoring analysis, then define a robust physical transition rule without altering the dataset. Track reciprocity, continuity, and uncertainty by path class.  
**Falsification:** Sensitivity does not predict residual structure or the proposed transition is less stable.  
**Risks:** Perturbations are not observed terrain uncertainty; do not claim that sensitivity proves real-world geometry.

## Research and verification requirements

1. Verify formulas and applicable frequency/distance/height ranges against primary sources: ITU-R P.526, P.452, P.2001, P.2108; Longley–Rice/NTIA technical reports; and published multi-edge diffraction studies. Record edition, section, equation, URL, and access date.
2. Before coding, compare each hypothesis with all prior experiment IDs and B07 outcomes. Distinguish genuine new mechanisms from rejected variations.
3. Pre-register expected directional changes by site, frequency, terrain class, and censoring status. Include negative controls and at least one prediction that can disprove the hypothesis.
4. Maintain frozen splits and untouched lockbox data. No data leakage, site-specific tuning, or fitting on held-out folds.
5. Apply the existing physics battery, site-wise error, paired confidence intervals, censored-bound checks, screened composite, and baseline/R02 comparisons. A good aggregate score does not override physical failure.
6. Require independent adversarial scientific review of each shortlisted model before implementation and human approval before publication.
7. Record citation uncertainties and unresolved physical assumptions. Do not describe literature-derived methods as verified until equations are checked against the original text.

## Execution order and approval gate

**Stage 0 — literature and provenance:** verify primary sources and latest repo/PR history; complete adversarial review.  
**Stage 1 — non-scoring diagnostics:** paired-site and geometry stratification, synthetic physical reference cases; propose only, do not run under this plan.  
**Stage 2 — implementation proposals:** write exact MATLAB function-level changes, unit tests, expected effects, and stop rules for H01/H04/H05/H06/H09.  
**Stage 3 — authorization:** request Nick's approval before modifying MATLAB, evaluator, datasets, or running any experiment.  
**Stage 4 — evaluation (future, separately authorized):** execute one controlled experiment at a time and report every result, including failures.

**Current decision:** Store this document as a future plan only. It does not supersede `FRAMEWORK.md`, `program.md`, B07, or the current experiment history.

## Sources

- [Repository framework](../../FRAMEWORK.md)
- [Experiment log](../../experiments/LOG.md)
- [B07 plan](../../experiments/batches/B07.md)
- [Working-paper findings](../../docs/WORKING_PAPER_FINDINGS.md)
- [Literature review](../../docs/LITERATURE_REVIEW.md)
- [ITU-R recommendations portal](https://www.itu.int/rec/R-REC-P/en)
- [NTIA/ITS publications](https://its.ntia.gov/publications/)
