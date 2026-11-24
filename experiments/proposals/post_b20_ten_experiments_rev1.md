# Ten ITM experiments after B20

Prepared: 2026-11-24. Status: **proposed research only**. Reviewed snapshot: [main tree 74d79ff](https://github.com/nicklasorte/ITM_ai_experiment/tree/74d79ffbb68214f30edb8470cb5ef126968ea802). Parent: `best`, 707-cascaded-isolated-clutter-at-r, unless the planner records a subsequent keep. This is a new proposal, not a batch authorization; it does not supersede phase plan rev 4 or the frozen lockbox registration.

## 1. What the evidence says

- 000-baseline: composite 16.0 dB. R02 constrained refit: 15.9 dB. R01 unconstrained refit fails physics and censoring. Kept 707: composite 12.51 dB, screened composite about 9.91 dB, censored violations 22.8%. A new model must beat the actual parent, not just stock.
- B18: count-stable 1801 removed the principal-edge jump but was rejected under the registered censored recount; 1803 created new height defects; 1804 restored height response in the ridge sweep but failed the site gate. Those rulings stand.
- B19: 1901 and 1301 gave identical Phase 2 predictions; the P.452 scatter-line replacement is closed.
- D20a: on ridge40, 707 and 707 without the bound both change by +0.17 dB across a 1–30 m receiver sweep; stock changes by −23.30 dB. Alternate smooth surfaces yield −18.07 dB. The obstruction-adjusted surface is implicated; the log identifies the R1 inversion as a distinct smooth-path two-ray lobing problem. B21 already plans a new smooth-surface candidate; do not duplicate it.
- D20b: C·T accounts for 6%, 20%, 22% of mean reference attenuation across the three bands below 1 GHz. The preregistered one-third criterion failed. Clear-row mean error becomes −6.40 dB above 3 GHz; R2 clear rows above 3 GHz have −29.52 dB mean error (105 rows, not independent paths). Negative error means predicted loss is too low.
- D20c: 1,165 uncensored matched pairs; measured mean concealed-minus-open loss 11.30 dB, predicted 14.00 dB. Measured frequency slope +10.14 dB/decade, predicted +9.41. P.2108 beats the training-site refitted constant at R1 and VA but not R2. The existing clutter term remains; the result does not establish causality for every site, nor validate extrapolation above 3 GHz.
- B12, B14–B19 close several attractive families on the present data. Do not re-run curved phase alone, independent two-leg time convolution, P.617 fading-side scaling, scatter swaps, blanket NLCD clutter, path vegetation, the resolved-crest proposal, or Vogler as a direct terrain replacement. B16 already established that the edge selector, not the fixed-screen field, causes the jump.

Evidence: [LOG](../LOG.md), [results](../../results/results.tsv), [archive](../../results/archive_rev1.txt), [B18](../batches/B18.md), [B19](../batches/B19.md), [B20](../batches/B20.md), [D20a](../D20a-smooth-surface-terms/summary.txt), [D20b](../D20b-cascade-terms/summary.txt), [D20c](../D20c-paired-clutter/summary.txt), [phase plan rev 4](phase_plan_rev4.md).

## 2. Ranked portfolio

Rank is a planner judgment of physical leverage, feasibility, novelty against the recorded history, and information gained per unit effort. It is not a prediction of measured score. IDs below are proposal IDs, not assigned run tags.

| Rank | ID | Experiment | Type | Priority |
| --- | --- | --- | --- | --- |
| 1 | N01 | Reflection-amplitude repair of the smooth reference | Conditional model repair | High |
| 2 | N02 | Matched spherical diffraction reference instead of hybrid ITM reference | Conditional model repair | High |
| 3 | N03 | Within-path measured antenna-height response | Diagnostic | High |
| 4 | N04 | Frequency-difference decomposition on matched clear and obstructed links | Diagnostic | High |
| 5 | N05 | Censoring-aware paired clutter validation and applicability test | Diagnostic | High |
| 6 | N06 | Physical edge-selector stability under profile-grid phase | Synthetic diagnostic | Medium |
| 7 | N07 | Ground-reflection polarization and impedance sensitivity | Synthetic diagnostic | Medium |
| 8 | N08 | Joint-mechanism long-term quantile competition | Diagnostic / conditional candidate | Medium |
| 9 | N09 | Off-profile terrain bypass and transverse obstruction | New-data research | Conditional |
| 10 | N10 | Independent modern measurement campaign with height and frequency controls | New-data validation | Conditional |

## 3. Experiment cards

### N01 — Reflection-amplitude repair of the smooth reference

**Mechanism:** D20a separates the flat ridge height response from the R1 inversion. The latter may be an artifact of coherent two-ray lobes in ITM's artificial smooth path, not in the measured path. Curved reflection phase alone (1201) was screened out; reflection amplitude/divergence is a different intervention.

**Design:** Keep 707's L_ba, L_bs, surface, terminal correction and scatter bound fixed. Instrument the smooth-reference call in `delta_bullington_reference` and the reflection coefficient in `line_of_sight_loss`. Compare 707 with a published spherical-earth specular divergence factor applied to the reflected field amplitude, not to dB loss. Retain the original phase and reflection coefficient for the primary isolation test; a separate non-scoring comparison with the source-consistent phase checks whether the hybrid is defensible. Reference P.530-19 Annex 1 §6.1.2.3 (verify formula, geometry and applicability from the source before registration). A physically derived amplitude D must be in [0,1]; do not fit a taper to the R1 path.

**Tests:** flat-earth limit D→1, reciprocal terminals, no reflected field, passive reflection coefficient, smooth-earth grazing cases, dense height sweeps R1-005-T5 O/A, R2-020, R2-080-T4, and ridge40. Distinguish genuine physical lobing from a reference-construction artifact; do not assert that every LOS path must be monotonic in height. Prediction: the artificial inversion shrinks on R1; clear paths with zero delta stay unchanged; R2 and R3 should not incur new inversions. Report per-site and censored deltas; the sign of aggregate gain is unknown.

**Stop:** if the source cannot justify the amplitude change in this artificial geometry, the inversion does not shrink, or the non-inferiority/physics gates fail. Run model-only smoke and history-matching first; no scored run solely because the existing defect is interesting. Distinct from B21's surface change; evaluate on the same parent before considering interaction with B21.

### N02 — Matched spherical diffraction reference

**Mechanism:** 707's delta combines a profile cascade with ITM's full smooth-path reference attenuation (including a LOS/troposcatter construction). A diffraction-only reference may avoid comparing unlike mechanisms, especially on obstructed paths with a synthetic smooth profile that is LOS.

**Design:** Hold the actual/smooth geometry fixed to 707 initially. In the delta construction replace only A_s with the spherical-earth diffraction term from P.526-16 §3, using the same effective radius, terminal heights above the reference surface, frequency and compatible ground impedance. Retain L_ba + max(A_s − L_bs, 0) and the same cascade for both L_ba and L_bs. Convert all terms to excess loss relative to the same free-space reference. This is not a full P.452/P.1812 model and not 402, which changed the placement of the max operation. Source-check the surface assumptions, ground-admittance conventions, and frequency coverage before any implementation; unsupported rows retain the parent only through a registered, continuous applicability rule or the candidate stops.

**Tests:** P.526 smooth-sphere examples; flat/linear profiles where L_ba=L_bs (verify the actual identity and clipping behavior); smooth horizon crossing; reversal; ridge40 and the three real height-defect paths. Predict reduced artificial smooth-reference lobing on obstructed R1, while clear rows remain close to 707; R2 high-frequency and LT effects uncertain. D20b rules out a blanket LOS A_s intervention, so assess obstructed rows only as the target, while testing all rows for regressions.

**Stop:** incompatible source assumptions, discontinuous transition, censored harm, or no identifiable headroom. Do not combine with N01 or B21 until single-change results are recorded. If the planner finds B21 already implements this kernel rather than just a surface, mark N02 redundant and do not run it.

### N03 — Measured antenna-height response rather than absolute loss

**Mechanism:** Height derivatives of loss can isolate geometry defects from a path-specific calibration offset. B18's battery measured model height behavior; it did not establish a cross-site comparison against matched measured height contrasts in the B20 record.

**Design:** Build a development-only table of pairs with identical physical path, frequency, opposite-terminal height, polarization, siting and measurement configuration; only one antenna height changes. Audit the legacy records for metadata and native height precision. Compute ΔL_meas=L(h2)−L(h1) and ΔL_pred for 000, R02, 707, and any registered B21 candidate. Report difference-of-differences, sign agreement, and robust path-cluster intervals; retain censored contrast intervals where available. Separate open, concealed, and A categories; do not infer physical obstruction from labels. Do not assume monotonicity for measured LOS multipath.

**Prediction:** 707 underestimates height benefit in obstructed geometry; a good B21 repair restores measured contrast without adding new R2 errors. R1 inversion cases should be analyzed separately from the smooth-surface defect.

**Stop:** no sufficient paired metadata, no independent replication, or measured contrast uncertainty dominates model differences. Diagnostic only; no new keep gate or fitted height curve. Source: NTIA legacy measurement documentation and NTIA measurement best practices.

### N04 — Matched-frequency excess-loss slope

**Mechanism:** D20b's site-band averages mix paths, heights, and censoring. Frequency differences on the same geometry distinguish diffraction scaling from missing high-frequency attenuation.

**Design:** Match same physical path and terminal heights, siting, polarization and measurement setup across frequencies. For each pair form S=[(L2−FSPL2)−(L1−FSPL1)]/log10(f2/f1), dB/decade, for measured and predicted values. Decompose parent predictions into edge terms, C·T, smooth-reference increment, terminal correction and bound activation. Separate geometric clearance classes using continuous Fresnel clearance and predeclared bands; report paired intervals by path and leave-one-site-out. Explicitly account for documented instrument changes and censoring; do not regress site mean error against frequency and call it a physical law.

**Prediction:** positive measured-minus-predicted excess-loss slopes on clear R2 and VA paths at higher frequencies; lower-frequency obstructed overshoot may have a distinct signature in edge losses rather than C alone. R3 is a negative control for blanket missing-loss corrections.

**Stop:** contrasts disappear under height/polarization matching or occur at only one site, or measurement configuration changes explain them. No frequency multiplier may be proposed from this diagnostic alone. Different from D20b's pooled band regressions and D20c's C/O contrast. Source: P.526 and NTIA Phase 2 records.

### N05 — Censoring-aware paired clutter and validity-domain test

**Mechanism:** D20c supports the P.2108 term overall but excludes 235 pairs with a censored member from its main comparison. It also mixes the in-range and hold-at-3-GHz cases; R2 disagrees with the other sites.

**Design:** Retain the fixed 1,400 matched C/O pairs. Represent each detected loss by its observed value and each censored loss by its known lower bound (plus infinity). Form an interval for the difference: [C_lo−O_hi, C_hi−O_lo]; both-censored pairs with no informative bound remain uninformative. Compare 707, zero and training-only refitted constant by distance to the feasible interval, detected-pair RMS, and direction of violations. Split ≤3 GHz and >3 GHz before looking at candidate outcomes; within the valid range stratify by documented terminal height and clutter type where the records identify it. No new fitting or change to the scoring gate.

**Prediction:** the positive frequency trend persists in the supported domain and the excess R2 error is not explained by the exclusion of censored pairs; the >3 GHz extension may have different behavior. Report separately if the evidence is inconclusive.

**Stop:** interval information is too weak or metadata cannot distinguish building and tree siting. Do not invent a category assignment or change the hold3 behavior based on the same data. This extends D20c rather than repeating its acceptance test. Sources: P.2108-1 §3.1, NTIA/ITS reference implementation, Phase 2 measurement documentation.

### N06 — Edge-selector stability under profile-grid phase

**Mechanism:** B16 established a principal-edge selection jump, but terrain sampling can also change crest ordering or the apparent isolation of adjacent ridges. A geometry-based repair should survive a change of numerical sampling origin.

**Design:** Generate analytic single triangular ridges, two equal ridges, unequal ridges and broad plateaus with known continuous geometry; vary receiver height, frequency, profile sample spacing and interior grid phase while keeping physical endpoints fixed. Compare crest coordinates, selected edge identities, J and isolation weights, and loss across 707, 1801 as a diagnostic-only comparator, and stock. For existing development profiles, use only isolated interpolation/decimation sensitivity outside scoring; do not pretend interpolation creates independent terrain data. Compare forward/reverse orientation using identical physical coordinates.

**Prediction:** unstable edge count or identity explains excess discretization sensitivity near equal ridges; single isolated crests converge. This is not a new Vogler calculation or a revisit of B16b's short-trim roughness estimator. It diagnoses the terrain-to-edge map, not the field solver.

**Stop:** no material instability beyond the expected coarse-profile error, or synthetic findings do not transfer to any development geometry. Keep 1801 rejected; do not choose a selector by measurement residuals. Source: P.526 multi-obstacle methods; B16 fixed-screen result.

### N07 — Ground-reflection polarization and impedance sensitivity

**Mechanism:** The two-ray term and smooth-sphere loss depend on complex ground impedance, incidence angle and polarization. A numerical cancellation or implausible sensitivity in the artificial reference could amplify the height defect. This tests ground-response physics rather than phase-only B12 or N01 divergence.

**Design:** Synthetic tests only. Sweep the documented valid ITM ranges of relative permittivity, conductivity and both polarizations, using the same settings for all model components. Compare complex ground coefficient and loss to Fresnel boundary conditions at identical angles, with limiting dielectric and conducting cases. Record changes in the actual and smooth branches, the delta increment and final attenuation near the ridge40 and smooth-horizon geometries. If a concrete formula discrepancy is identified, register a separate one-change repair. For real data use only existing documented input values, no recalibration or soil-class substitution.

**Prediction:** smooth-reference changes are most visible on grazing geometries; a code mismatch will have a reproducible polarization/impedance signature, whereas a height-construction problem remains even if boundary-condition checks pass. Direction of site-score change is unknown.

**Stop:** agreement within a predeclared numerical tolerance and no meaningful discrepancy; close the implementation hypothesis. Sources: NTIA ITM reference, P.527 ground electrical characteristics and P.530 reflection section.

### N08 — Long-term quantile competition between mechanisms

**Mechanism:** A median minimum or cap followed by one variability curve is not generally equivalent to competition between stochastic diffraction and scatter mechanisms. This can change distribution shape without changing the median. The previous P.617 swaps and independent two-leg convolution do not test the mechanism-competition hypothesis.

**Design:** First use frozen LT development distributions, existing modeled branch geometry and recorded median margin between branches to stratify shape residuals by mechanism dominance and near ties. Compare the measured median-centered 10%, 50%, 90% loss contrasts, plus other available percentiles; cluster by receiver group. Use synthetic marginal distributions to bracket a minimum-loss idealization: for independent branches, F_min(l)=1−(1−F_D(l))(1−F_S(l)); use Fréchet bounds as sensitivity, not an assertion of independence. P.2001 provides a precedent for combining mechanisms; read its actual mechanism-combination rule before proposing any model, and do not conflate minimum loss with incoherent power summation. A candidate must preserve the parent median by construction if justified and keep the Phase 2 median unchanged; otherwise stop.

**Prediction:** shape error concentrates in near-tie paths, rather than merely in distance bins; strong-dominance controls remain unchanged. The prior B15 headroom ceiling for its narrower family remains valid; demonstrate a different attainable ceiling before a score.

**Stop:** insufficient independent near-tie receiver groups, no conditional shape signal, no defensible dependence model, or headroom below the current acceptance requirement. Do not reopen B12/B14/B15 or substitute a P.452 scatter median.

### N09 — Transverse terrain bypass (new data required)

**Mechanism:** A 1-D profile cannot represent a lower saddle beside the great-circle path, transverse ridge width, or lateral diffraction. Apparent excessive diffraction in mountainous paths could be related to these omitted dimensions.

**Design:** Stage A, independent synthetic 2-D terrain surfaces: compare a narrow transverse ridge and a laterally extensive ridge with identical centerline profiles, frequency, heights and material. Use a validated 3-D scalar wave or suitable paraxial solver with a convergence study, boundary controls and published diffraction benchmarks; a 2-D vertical-plane solver cannot answer a transverse question. Stage B, only after separate human approval and documented public terrain provenance: use a corridor DEM for development paths, without changing frozen profiles or evaluator. Predefine corridor width by Fresnel scale and solver domain, not by seeking a low-loss saddle. Test lateral sensitivity without claiming that the historical terrain or vegetation is known. Report uncertainty and differences in model output.

**Prediction:** narrow finite-width obstructions can exhibit different received fields from wide ridges with identical centerlines; conditional reduction of excess predicted loss is plausible in obstructed R2, but a bypass may also introduce interference. Flat, laterally invariant terrain is the negative control.

**Stop:** solver fails benchmark/convergence, transverse information cannot be resolved, or no meaningful contrast. No scored model without approved data interface and independent validation. Distinct from B16's 1-D coupled screens. Source: P.526 diffraction reference cases; solver source and exact benchmark to be selected and verified before registration.

### N10 — Independent campaign with controlled height/frequency pairs (new data required)

**Mechanism:** Historical measurement and DEM mismatch, uncertain crest accuracy, and open-path clutter labels limit what can be identified from the current development data. More iterations on the same measurements risk adapting to the archive.

**Design:** Prepare a prospective validation design, not a data acquisition action. Select independent public or authorized measurements with contemporaneous terrain and surveyed crest geometry; include R2-like obstructed ridges, clear open paths, and matched terminal clutter pairs. Require documented antenna height, antenna patterns/polarization, calibration, dynamic range, frequency, timestamps and detection bounds. Predeclare model configurations and strata before measurement access; use independent site-level sampling and a power/precision calculation based on independent path variance, not repeated frequencies as independent trials. Where possible compare one-height-at-a-time and fixed-height frequency contrasts. An independent custodian should hold outcomes until registration. Keep the existing lockbox untouched; this is a new validation study, not a second blind use of the original lockbox.

**Prediction:** the measured height contrasts and open-path slopes replicate across independent sites if N01–N05 target transferable physics; failure to replicate falsifies generalization, even if historical composite improves.

**Stop:** inadequate calibration, insufficient independent paths, overlap with development/lockbox paths, or lack of authorization. A possible source to assess for suitability (not assumed to meet requirements) is public NTIA/ITS measurement publications; do not download or inspect a candidate lockbox as part of planning. Sources: NTIA measurement best practices and ITU-R P.311.

## 4. Execution order and acceptance

1. Finish the existing registered B21 workflow. N03–N05 are the next cheap development diagnostics, proposed as a single diagnostic batch only after approval; no model changes and no Bonferroni count. N06–N07 are synthetic-only until their checks warrant further action.
2. Choose between N01 and N02 after checking B21's implementation and source applicability. Register each separately. Establish exact stock parity and reproduction of parent stored predictions to 1e-9 dB, unit/reference checks, reciprocity, continuity, height-defect tests and model-only deltas. Run the existing history-matching screen; reject equivalent deltas before scoring (B19 lesson).
3. N08 proceeds only if its diagnostic distinguishes the hypothesis from closed atmospheric families and supports attainable headroom. N09–N10 require separate authorization, data governance and validation design. They cannot modify the frozen evaluation inputs.
4. For any scored run, follow FRAMEWORK.md, program.md and latest approved batch rules; compare against 707/current best, stock, R02 and report R01 for context. At the recorded snapshot the next scored candidate against 707 is k=7; recompute from current history at registration. Do not reset multiplicity because a phase changes. Gain route: screened gain ≥0.3 dB with multiplicity-adjusted interval above zero, full composite degradation ≤0.3 dB, site RMS degradation ≤0.5 dB, current registered censored requirements and physics checks. The phase plan's per-parent censored increase requirement and any fixed ceiling must both be applied where applicable; do not reinterpret them. Repair route only for a registered defect under the approved repair rule, with non-inferiority and three reviewer sessions. The height check approval is specific to that defect. No changing gates after outcomes.
5. Track paired error and path/group bootstrap intervals, level/shape, site×band, censored count/share and violation magnitude separately. Use the existing frozen folds and screening membership. New report-only diagnostics live in experiments/ and never feed site labels or measured outcomes into a production model. No data leakage, lockbox inspection, or tuning on held-out folds. Any fit requires existing cross-validation and registered complexity accounting.
6. Close a family when its mechanism is falsified, source validity fails, or attainable headroom cannot meet the gate. Record the outcome even if negative. No new empirical constants are authorized here.

## 5. Public source starting points and verification

- [ITU-R P.526-16, Propagation by diffraction](https://www.itu.int/rec/R-REC-P.526-16-202511-I) (smooth sphere, multiple obstacles, benchmark geometry).
- [ITU-R P.530-19 contents](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.530-19-202509-I%21%21TOC-HTM-E.htm) (surface reflection, divergence and multipath).
- [ITU-R P.527](https://www.itu.int/rec/R-REC-P.527) (electrical characteristics of the Earth).
- [ITU-R P.2001](https://www.itu.int/rec/R-REC-P.2001) (wide-range terrestrial propagation and combination of mechanisms).
- [ITU-R P.2108](https://www.itu.int/rec/R-REC-P.2108), [NTIA implementation](https://github.com/NTIA/p2108) (terminal correction).
- [NTIA reference ITM](https://github.com/NTIA/itm), [NTIA legacy propagation data](https://its.ntia.gov/data/legacy-radio-propagation-data), [NTIA measurement best practices](https://its.ntia.gov/publications/details?pub=3211), [ITU-R P.311](https://www.itu.int/rec/R-REC-P.311).
- Prior studies within this repo: [B12](../batches/B12.md), [B14](../batches/B14.md), [B15](../batches/B15.md), [B16](../batches/B16.md), [B17](../batches/B17.md), [research review](research_review_2026-11-23.md), [prior future plan](../../docs/research/FUTURE_RESEARCH_PLAN_rev1.md).

These are proposal-level source leads, not a claim that all equations have been independently verified against rendered primary-source pages. The planner must record edition, equation, units, applicability and reference cases before coding. The ten ideas were checked against the repo history through B20, not executed, and have not undergone three independent reviewer sessions. No model, data, evaluator, existing plan, experiment records or lockbox files were changed by this proposal.
