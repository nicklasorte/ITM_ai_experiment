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

---

## 6. Adversarial review (red team) — 2026-11-24

**Disposition: revise before execution.** Review of all ten proposals against the repository at main commit [a4ae675](https://github.com/nicklasorte/ITM_ai_experiment/tree/a4ae675fc956a96a7092c9568a83a34f0f185fd4), the B20 findings, B12/B15/B16/B18/B19, the headroom map, and selected implementation and diagnostic code. The original proposals above are retained as the record of the initial ideas; the dispositions and additional prerequisites below supersede their suggested order and readiness. This is an adversarial desk review in the same assistant session, not one of the three independent reviewer sessions required for a model keep. No simulations, MATLAB tests, data extraction, or lockbox access occurred.

### 6.1 Executive verdict

None of the ten is ready for a scored model run. The original ranking placed model changes ahead of evidence that the defects matter on measured paths. That ordering is not defensible given B18's failure and the restricted headroom. Several proposals test numerical or physical properties without a plausible keep path; such diagnostics are useful, but must not be marketed as improvements to measured propagation accuracy.

| ID | Severity of principal objection | Review disposition | Revised priority |
| --- | --- | --- | --- |
| N01 | High: incompatible field approximations; weak leverage | Hold; isolate actual smooth-reference field and benchmark first | 5 |
| N02 | High: hybrid delta lacks consistent smooth-path limit | Advance to source/identity audit only; hold scored run | 4 |
| N03 | High: height pairs may not identify the causal effect | Advance to metadata and paired-design audit | 1 |
| N04 | High: frequency/height confounding and censoring | Advance with fixed estimand and matched cohort | 3 |
| N05 | Critical: D20c's attribution is inconsistent with 707's height handling | Advance; correct interpretation and recompute diagnostics | 2 |
| N06 | Moderate: existing sampling interface and idealized tests | Advance as a bounded synthetic regression audit | 6 |
| N07 | High: stock approximation mistaken for a numerical error | Merge with N01's reference audit; no standalone scored candidate | 7 (merged) |
| N08 | High: overlap with closed B15; unidentified joint distribution | Park model proposal; reopen diagnostic only with distinct estimand and headroom | 8 |
| N09 | High: non-identifiability and solver validity | Separate research track; synthetic benchmark first | 9 |
| N10 | High: external validation design lacks primary endpoint and independence plan | Separate validation track; plan now, acquire only with approval | 10 |

Priority numbers rank immediate development work, not scientific importance or predicted improvement. N10 is strategically important despite its low immediate execution priority. B21 remains the approved repair effort; this appendix creates no additional authorization.

### 6.2 Cross-cutting challenges

1. **Repeated reuse of development sites.** Leave-one-site-out fitting prevents a particular coefficient from seeing its test site, but does not make the held-out site's results blind to an agent that has already inspected those sites across many batches. Nested selection, frozen proposal decisions, and independent future measurements are needed to support generalization. Call these development diagnostics, not independent confirmation.
2. **Headroom before mechanism shopping.** The headroom map and B18 identify substantial within-cell error, but small gains from many class-level interventions. Compute affected rows, independent paths, screen inclusion, and a model-only delta vector before proposing a scored candidate. A class-mean correction ceiling is not a mathematical ceiling on arbitrary path-specific physics. A perfect-oracle ceiling confined to the candidate's exact support is an optimistic bound, not expected gain. If only one score component changes, a 0.3 dB composite improvement needs at least a 0.9 dB reduction in that component; inspect full and screened objectives separately.
3. **Repair versus improvement.** A smooth curve, stock-like height response, or numerical identity does not establish measured accuracy. The approved real-path height check applies to the registered height-gain defect; other repairs need an applicable preregistered failing check and review. A repair may not bypass censoring or site non-inferiority. The current 1801 decision and gate rules remain in force.
4. **Censoring and correlation.** Detected-only RMS and censoring violation counts answer different questions. Do not trade them after seeing results. Bootstrap whole physical paths or receiver groups; retain shared fixed-site calibration and repeated measurements in the dependency structure. Report numbers of independent units, not merely rows. Do not treat overlapping pair contrasts as independent observations.
5. **One physical intervention per candidate.** Instrumentation must not change predictions. Freeze settings, source versions, applicability, null controls and all decision criteria before measured-outcome analysis; any source-required coupled change must be explained as one coherent kernel. Test equivalence against archived model-only deltas to avoid a repeat of B19.
6. **Scope and citations.** P.526, P.530 and P.2108 recommendation pages were located; their existence does not validate a hybrid formulation. Source equations, parameter units, validity ranges, reference outputs and uncertainty must still be checked against the actual editions before implementation. Never change frozen inputs, evaluator or acceptance rules from this plan. A new data source or evaluator change is a separate human decision.
7. **Distinguish three notions of improvement.** Numerical robustness, physical-model consistency, and measured prediction accuracy are separate outcomes. Report them in separate columns. A diagnostic may succeed while its associated candidate is rejected.

### 6.3 N01 — Reflection-amplitude repair

**Attack:** The proposed amplitude-only change assumes a physically meaningful coherent field is available inside ITM. It is not enough to insert a P.530 divergence factor into an approximate two-ray loss curve. In [the core](../../itm_variant/itm_p2p_core_exp.m), `line_of_sight_loss` computes a complex reflection coefficient, attenuates it for roughness, rescales it when its squared magnitude is below a threshold, and compresses phase above π/2. It then blends the resulting loss with the diffraction line in dB. This is not an unmodified spherical specular field. Multiplying before the empirical rescaling can partially cancel the intended intervention; multiplying after it is a different hybrid. Weakening reflection may increase or decrease loss depending on phase. D20a's ridge40 smooth increment is already zero at every tested height, so reflection divergence cannot restore the missing height response there unless another part changes. The earlier B12/headroom tests also establish limited leverage for changes to the actual-path reflection term.

**Required revision:** Treat N01 as a source-consistency audit and synthetic experiment first. Log the raw Fresnel coefficient, roughness factor, rescaled coefficient, unclamped and compressed phase, complex field, blending weight, A_s, L_bs, positive-part activation and final bound status. Use three model-only controls: parent; amplitude-only ablation explicitly labeled nonphysical if inconsistent; and a complete source-consistent specular field at the same geometry. The last is a reference control, not automatically a valid ITM replacement. Ensure the switch acts only in the smooth-reference context and cannot leak into the actual-path scatter-line calculation. Use R1 inversion as a reproducer, not a fitting target. Test preregistered independent synthetic obstructions with comparable reference geometry. At D=1 require parent parity; with zero reflection require unit direct-ray field before empirical blending. Do not use a universal monotonicity or no-below-free-space rule for coherent LOS loss.

**Go/no-go:** No candidate unless a source-supported formulation survives both synthetic and real-path model-only sweeps, removes the applicable registered defect without new failures, and passes the actual affected-row/headroom screen or valid repair route. If the correction is clipped out on the target cohort or B21 already resolves the inversion, close it. Merge N07 into this audit. **Residual risk:** the artificial smooth surface may be unsuitable for specular reflection even with correct field physics.

### 6.4 N02 — Matched spherical diffraction reference

**Attack:** This is the most direct model-consistency proposal but not a complete delta-Bullington implementation. The original card implies a smooth-path identity without deriving it. For 707's outer formula, if L_ba=L_bs=x then x+max(A_s−x,0)=max(A_s,x), not necessarily A_s. Therefore a positive-part clamp and an isolation-weighted cascade can prevent recovery of the spherical reference on identical smooth terrain. Replacing only A_s could also erase physically meaningful LOS behavior, or add a step at the applicability boundary. The P.526 spherical Earth prescription and P.452 delta construction have their own geometry, electrical assumptions and reference knife-edge method; borrowing one term does not make 707 compliant with either recommendation.

**Required revision:** Obtain a benchmark implementation of the published full delta method, independent of the candidate. Compare: parent 707; proposed single-kernel replacement; complete published reference (diagnostic only). On smooth identical profiles, check the explicit max identity, determine whether x>A_s occurs, and explain whether that deviation is acceptable or disqualifying. Trace ground admittance normalization, effective radius, heights, frequency domain and FSPL subtraction. Include grazing, below/above horizon, terminal reversal, negative or zero excess where the source permits, steep surface slopes, and stock ITM bounds. Do not hide unsupported rows behind a fitted switch. A complete published model and a hybrid variant must be labeled separately. P.1812's 6 GHz upper range, for example, must not be assumed to cover 9.19 GHz Phase 2 links.

**Go/no-go:** Source/identity audit first; no score if the smooth-limit error is unexplained, applicability is incomplete without a justified continuous construction, or B21 implements the same intervention. D20b's clear-path near-zero increment rules out treating this as a blanket cure for clear-path underprediction. If the hybrid fails the smooth-limit test, do not add an empirical offset to force it. **Residual risk:** even a consistent reference may worsen the measured R2 site and censoring.

### 6.5 N03 — Measured antenna-height response

**Attack:** A within-path contrast cancels only shared additive errors. Moving an antenna can change polarization coupling, near-terminal objects, local scattering, receiver gain, or measurement campaign conditions. Phase 2 hardware/height pair support has not been established. A two-height finite difference is not a derivative; comparisons across unequal height increments can exaggerate one class. An R1 or R2 height sweep selected because 707 fails is not an independent validation set. Repeated pairs sharing a reference height create correlated errors.

**Required revision:** Start with an outcome-blind eligibility table (geometry and metadata only): physical base ID, site/terminal, frequency, both structural heights, changed end, polarization, siting, equipment/configuration, session or documented stability, detection status and available calibration information. Predeclare one primary contrast per path/frequency/configuration (for example a fixed eligible low/high pair selected by metadata alone), and treat additional contrasts as secondary clustered observations. Express errors in both dB for the contrast and, only over declared comparable spans, dB/m. For pairwise censoring use interval subtraction, not the detection bound as a measured value. Use detected-pair absolute contrast error as the primary descriptive estimand with path-cluster paired differences versus 707 and stock/R02; report interval consistency separately. Show the distribution of height increments, counts of eligible paths and effective clusters by site. Calculate attainable precision from an independent pilot or conservative declared variance; without replication across sites, label the result local. Do not use the contrast as a new keep gate.

**Go/no-go:** Advance the eligibility audit now; no empirical mechanism conclusion if hardware/geometry equivalence is uncertain, the estimated interval cannot resolve the effect of interest, or all informative paths come from a single site. A measured contrast inconsistent with 707 can prioritize a model defect but does not identify the smooth-surface cause by itself. **Residual risk:** missing metadata may render the key estimand unavailable.

### 6.6 N04 — Matched-frequency excess-loss slope

**Attack:** Subtracting FSPL removes the nominal 20 log10(f) dependence, not antenna gain calibration errors or changes in equipment and antenna height. The R2 B16 record explicitly identifies a transmitter height change between bands; an unmatched comparison would conflate frequency and height. A frequency-dependent Fresnel classification can also select different physical paths into the clear cohort at each band, manufacturing a slope. Dividing by a small log-frequency interval amplifies uncertainty. Decomposition into capped/clipped dB terms is not a causal decomposition.

**Required revision:** Use a common paired cohort for each declared frequency pair; require identical physical endpoint heights, polarization, siting and compatible calibrated basic-transmission-loss measurements. Predefine frequency-pair spans and report all excluded pairs, including the R2 height change. Define clear-at-both-frequencies and blocked-at-both cohorts using geometry only; report paths that change class separately. For measured-minus-predicted slope, FSPL cancels exactly, so use [(L_meas2−L_pred2)−(L_meas1−L_pred1)]/log10(f2/f1) as an arithmetic cross-check. Propagate both measurement uncertainty and censoring intervals. Prefer a paired endpoint residual contrast in dB as primary, with normalized slope secondary when spans differ. For model attribution log increments before and after bound/positive-part clipping and use controlled ablations; do not interpret raw component magnitude as a causal contribution. R3 is a comparison site, not proof that a mechanism is absent.

**Go/no-go:** Advance only after metadata matching. If the apparent slope vanishes in matched rows, or precision/replication is inadequate, close the frequency-scaling interpretation. Do not propose a generic frequency correction based on this test. **Residual risk:** unresolved time-varying clutter and instrumentation can imitate a frequency effect even on matched geometry.

### 6.7 N05 — Censoring-aware paired clutter: critical correction

**Attack:** The B20 D20c script says that the predicted C/O difference is the clutter term alone and that other terms were checked as identical. Its visible check reports the minimum, mean and maximum of the total difference; it does not compare the underlying path terms. The [core](../../itm_variant/itm_p2p_core_exp.m) instead raises the concealed mobile terminal to max(h,R) before `quick_pfl`, `longley_rice` and the delta/scatter bound calculations when `terminal_clutter_base="clutter_height"`. It adds the P.2108 terminal correction later, before variability and the soft limit. Therefore equal terrain profiles do not imply equal modeled propagation geometry. A positive total difference cannot establish that the additive term alone caused it. The D20c predictive comparison remains a result for the complete 707 configuration; its interpretation as validation of the isolated P.2108 loss term is not warranted. This is a material correction to the original N05 framing and B20 attribution, not a claim that the recorded D20c RMS arithmetic is wrong.

**Required revision:** On the original development pairs, first reproduce stored 707 O/C outputs. Verify same site, physical base, frequency, structural heights, polarization, terrain and compatible calibration; the existing merge uses base/frequency/heights but does not by itself establish every condition. At fixed row geometry perform a report-only factorial decomposition:
- G(h,0): actual height with no terminal correction;
- G(H,0): raised height H=max(h,R), no correction;
- G(h,A): actual height with the same additive A_h (diagnostic control; not the recommended P.2108 construction);
- G(H,A): raised height plus A_h, reproducing the parent.

Here G is the final prediction including the same variability/soft-limit settings; keep row metadata fixed except the explicitly controlled treatment. Geometry contribution is G(H,0)−G(h,0), conditional additive contribution G(H,A)−G(H,0), and total G(H,A)−G(h,0). Their sum must equal the total. Also inspect the interaction (difference of conditional additive contributions) to expose nonlinearity and report A_h before the soft limit. Check whether G(h,0) reproduces the matched O prediction or quantify the discrepancy. No factorial variant is a scored candidate; actual-height-plus-A is the already recognized double-counting control.

For observed contrasts, retain all 1,400 pairs and classify exact, lower-bound-only, upper-bound-only and uninformative two-censored cases. With detected open and censored concealed the difference has a lower bound; with detected concealed and censored open it has an upper bound. The distance of a prediction to an interval is only a lower bound on absolute error and cannot rank models inside that interval. Report exact-pair RMS, informative-bound violation share/magnitude, and uninformative counts separately; do not average them into a fabricated composite likelihood. If using a censored likelihood later, specify and justify the measurement/censoring process first.

Split 30 MHz–3 GHz (the P.2108-1 §3.1 domain used in the implementation) from hold3 above 3 GHz; keep the same support for all comparisons. Estimate within-base, within-height frequency contrasts where eligible, not only pooled slopes. Reproduce both D20c constant controls and distinguish 704's fixed constant from training-site refitted constants; the latter must be fit only within training sites and on declared data. The two-of-three site result has limited external validity.

**Go/no-go:** Highest-priority correction after N03's common metadata audit. If full 707 still beats controls but the additive term alone lacks evidence, report support for the configuration, not standalone validation. If pairing or censoring is uninformative, retain the prior result with caveats and do not change the model. Record any correction to the D20c interpretation through the normal planner process; this appendix does not edit the original records. **Residual risk:** no contemporaneous clutter geometry may exist to isolate the term causally.

### 6.8 N06 — Edge-selector stability under profile-grid phase

**Attack:** ITM's PFL interface requires uniform spacing and fixed endpoints. An arbitrary interior grid shift that preserves both endpoints at fixed spacing is not generally a valid PFL; special short end cells change the model assumptions. Numerical convergence of ideal sampled triangular crests is not equivalent to physical fidelity of a 30 m DEM. Ties at exactly equal analytic crests are a degenerate case that should not dominate the conclusion. A repair of sampling sensitivity does not automatically address B16's height-driven edge switch.

**Required revision:** Use two separable synthetic families: (A) fixed physical endpoints with different integer sample counts, uniform spacing d/n; (B) fixed grid with terrain crest translated by a sub-grid fraction, explicitly a geometry sensitivity test, not identical geometry under a shifted grid. If testing a nonuniform-grid oracle, keep it outside ITM and label it as a different numerical representation. Include analytic sharp/rounded limits where appropriate, asymmetric near-ties and isolated ridges, plus a high-resolution numerical reference that is not claimed as truth. Report maximum finite difference, convergence rate and edge identities rather than just a visually smooth curve. Derive reversal and translation-invariance checks without requiring physical translation invariance on real terrain. Check actual received loss and intermediate L_ba/L_bs/clamp effects. A preregistered geometric uncertainty envelope must distinguish expected sampling error from selector discontinuity; choose it before running.

**Go/no-go:** Bounded synthetic audit only. If findings merely reproduce B16's known selector switch or depend on invalid PFL grids, close. No change to scored terrain spacing, and no resurrection of 1801. **Residual risk:** a smoother selector can suppress real diffraction changes and worsen censored predictions.

### 6.9 N07 — Ground impedance and polarization

**Attack:** A difference between exact Fresnel coefficients and the stock ITM effective coefficient is expected: the implementation contains roughness attenuation and empirical magnitude rescaling. Treating that approximation as a software defect would be a category error. Varying permittivity and conductivity together can hide unit/sign errors; the complex convention and polarization definition must match the NTIA reference. Synthetic sensitivity cannot establish which actual ground parameters apply to historical sites.

**Required revision:** Merge N07 into the N01 prerequisite audit. Separate (1) raw smooth-interface Fresnel calculation, (2) ITM roughness and rescaling, (3) field/loss blending, and (4) delta/scatter effects. Check the raw coefficient against an independent boundary-condition oracle at documented valid incidence angles and ground properties; use the same time-harmonic convention, conductivity units, frequency units and polarization convention. Test the actual stock implementation against the pinned NTIA reference, including zero/near-zero denominator or magnitude handling and finite outputs. Perturb one parameter at a time for attribution, then use a small factorial design to test interactions. The physical passive-interface bound concerns the correct amplitude coefficient under its convention, not an empirical effective field factor or the final path loss. No historical ground-input fitting or substitution.

**Go/no-go:** Only an identifiable code discrepancy against the intended reference, or a separately justified model approximation change with leverage, warrants a future experiment card. If stock parity and intended approximations are reproduced, record the audit and stop. **Residual risk:** exact electromagnetic boundary conditions may be a poor substitute for ITM's empirical effective-ground representation.

### 6.10 N08 — Long-term quantile competition

**Attack:** B15 already proposes per-percentile diffraction/scatter minimum and soft-minimum blending with P.617 fading-side variability. The original N08 understates this overlap. Different names do not create a distinct experiment. Historical aggregate loss CDFs do not identify the simultaneous component marginals or their copula. Even correct independent-minimum algebra cannot show that independence is physically valid. The median of a minimum is generally not the minimum of the medians; subtracting an arbitrary offset to recover the parent median changes the physical prediction. The median-centered 50% contrast is identically zero and contains no information. Also, a model's transhorizon eligibility and branch validity must be checked; an extrapolated scatter line is not an independently observed random process.

**Required revision:** Park the candidate. If reopened, first register a distinct near-tie diagnostic only: predefine physically valid component eligibility, signed median margin, continuous margin strata, and comparison with dominant-mechanism cases matched on distance/frequency/terrain. Assess both sides of the measured median and count independent receiver groups; use a group-clustered interval and compare against B15's own per-quantile rivals without scoring a new variant. For synthetic demonstrations with CDFs F_D and F_S, the independent minimum CDF is F_D+F_S−F_D F_S; without a dependence model its Fréchet bounds are max(F_D,F_S) and min(1,F_D+F_S). At a shared median with independent continuous components, the minimum's CDF is 0.75, demonstrating why median neutrality cannot be assumed. For incoherent power addition the loss expression uses −10 log10 of the sum of linear power factors; it is not the same as the B15 soft-minimum or a stochastic minimum. A physical mechanism-combination rule must specify which operation is intended and why.

**Go/no-go:** Do not implement or score unless the diagnostic shows a replicated residual structure not explained by B15, a valid source supplies or independent data identify dependence/branch statistics, and the exact proposed support has attainable headroom under current gates. A median-preserving transformation must be derived, not imposed. **Residual risk:** mechanism competition may be scientifically plausible but not identifiable from the present archive. Treat B15 as closed, not as an untested opportunity.

### 6.11 N09 — Transverse terrain bypass

**Attack:** This is the strongest conceptual departure from ITM but the weakest immediate scored experiment. Centerline-identical terrain may produce different fields, but the sign and magnitude depend on lateral phase, diffraction, scattering, transverse impedance and antenna patterns. A lower saddle does not guarantee lower received loss because the detour has phase and geometric spreading. A paraxial solver can fail at steep angles, near fields, backward propagation or large lateral departures. A 2-D terrain raster is not a 2-D electromagnetic field; a vertical-plane PE solver cannot test lateral bypass. P.526's usual longitudinal diffraction examples alone cannot certify a 3-D solver.

**Required revision:** Stage A only: define an explicit 3-D propagation domain and boundary conditions; choose a solver with validated wide-angle or full-wave capability appropriate to the synthetic geometry. Benchmark free space, an obstacle invariant across the transverse direction (2-D limit), and a finite-width screen with a published or independently converged analytical/full-wave result. Perform grid, step, absorbing-boundary, domain-width and solver-order convergence checks; bound numerical uncertainty below the target effect before comparing terrain cases. Freeze centerline, terminals, frequency, ground properties, antenna patterns and longitudinal geometry; vary transverse width/saddle as the sole physical factor. Compare complex field and received power with a declared averaging protocol; sweep both constructive and destructive cases. Require a reproducible effect larger than combined numerical and input uncertainty, not just a visually persuasive map.

Stage B is a separate proposal: justify public corridor DEM access, resolution, transverse survey uncertainty, historical mismatch and data interface. No cheapest-detour or minimum-loss search calibrated on measured residuals. Test against multiple independent sites; distinguish evidence of a missing dimension from evidence that a specific 3-D correction improves ITM. No existing evaluator modifications under this appendix.

**Go/no-go:** Synthetic benchmark plan may proceed after approval; no corridor-data experiment until solver/reference validity and governance are resolved. **Residual risk:** even correct 3-D propagation could be impractical over long paths or unidentifiable with historic terrain and antenna records.

### 6.12 N10 — Independent measurements and generalization

**Attack:** A new campaign is not itself a model variant; it is the main means of detecting archive overfitting. Convenience selection of paths, bands and sites that favor the proposed repairs would undermine the test. Public data may overlap existing campaigns or use different loss definitions, time percentages, antenna patterns and detection policies. The claim that a failure to replicate would falsify generalization is too broad: a failed replication in an incompatible domain may identify domain shift, not invalidate the physics.

**Required revision:** Define a target population of paths and an estimand before acquiring outcomes. Use a primary endpoint of paired prediction-error difference between a frozen eligible candidate and frozen stock/current-parent comparator on independent sites, with declared protection against increased censoring violations. Secondary endpoints: measured height contrast, excess-loss frequency contrast, site-band performance and tail error. Align the exact basic transmission loss definition and measurement statistic with the model (short-term samples do not establish annual time percentiles). Plan a stratified site/path sampling design spanning open, obstructed, cluttered and negative-control paths. Count independent sites and paths; power or precision calculations must incorporate clustered variance, anticipated missingness, and detection bounds, not repeated frequencies as independent trials. Fix the effect of interest and required confidence width before reviewing results; if pilot data inform the design, keep pilot sites outside the confirmatory set. Register source provenance, path/measurement overlap exclusions, calibration/traceability, missingness handling, blinding, custodian, and release procedure. Evaluate frozen models once under the registered design, then label any reuse as development.

**Go/no-go:** Prepare a prospective validation protocol and feasibility inventory only; separate approval is required for acquisition, fieldwork or any new evaluator/data interface. No sample-size claim until variance, clustering and precision targets are known. Failure to replicate within a well-matched preregistered population weakens the transfer claim; out-of-domain failure has a different interpretation. **Residual risk:** cost, terrain access, comparable measurement statistics and an independent custodian are not established.

### 6.13 Revised work packages and decision rules

| Work package | Contents | Release condition |
| --- | --- | --- |
| A — Metadata and contrast audit | N03, N05, N04 (common pairing/provenance table first) | Reproduce parent, declare eligibility and estimands, publish support counts and clustered uncertainty; no scoring |
| B — Reference consistency | N02 source/identity benchmark; N01 + N07 joint prerequisite audit | Complete public equation verification, reference cases, context isolation, and exact support screen; no score unless a distinct candidate is registered |
| C — Numerical robustness | N06 synthetic grid/interface tests | Valid PFL geometry, convergence and existing defect differentiation |
| D — Atmospheric research | N08 parked | New distinct estimand, valid joint-mechanism evidence and headroom; B15 remains closed |
| E — External research | N09 synthetic benchmark; N10 independent validation design | Separate human approval, data governance, solver/campaign validation |

Continue the approved B21 work without alteration. Within package A, prioritize the N05 attribution discrepancy after the shared metadata check. Before any package B scored run, check whether B21 removed or altered the target defect; avoid combinations until the incremental effect of each intervention is known.

For future registration, record: exact parent hash and settings; data/evaluator hashes; affected cohorts and denominators; primary contrast and negative controls; numerical/reference tolerances with provenance; minimum scientifically meaningful effect and attainable precision; direction of expected site/censored impact; and the predeclared rejection/repair rule. Use existing multiplicity and censoring gates rather than the review inventing substitutes. Do not count these proposed diagnostics as scored candidates.

**Final reviewer recommendation:** Advance N03–N05 as diagnostics after approval, not as scored experiments. Advance N02 to a source-consistency benchmark and N06 to a limited synthetic check. Hold N01 behind a merged N07 audit and B21's outcome. Park N08. Keep N09 and N10 as distinct longer-horizon research tracks. No model change is approved by this red team.

### 6.14 Review evidence and limits

- Code evidence: [ITM core](../../itm_variant/itm_p2p_core_exp.m), specifically terminal-height substitution, `delta_bullington_reference`, and `line_of_sight_loss`; [P.2108 implementation](../../itm_variant/p2108_height_gain_rev1.m); [D20c script](../batches/b20_d20c_paired_clutter_rev1.py).
- Experiment evidence: [B12](../batches/B12.md), [B15](../batches/B15.md), [B16](../batches/B16.md), [B18](../batches/B18.md), [B19](../batches/B19.md), [B20](../batches/B20.md), [headroom map](headroom_map_rev1.md), [phase plan rev 4](phase_plan_rev4.md).
- Public source entry points checked: [ITU-R P.530-19](https://www.itu.int/rec/R-REC-P.530-19-202509-I), [ITU-R P.526-16](https://www.itu.int/rec/R-REC-P.526-16-202511-I/en), [ITU-R P.2108-1](https://www.itu.int/rec/R-REC-P.2108-1-202109-I/en), [ITU-R P.1812-8 contents](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.1812-8-202509-I%21%21TOC-HTM-E.htm). These are source leads; equation-level verification of new kernels and independent numerical reproduction are outstanding.
- Algebraic checks in this review: the outer positive-part identity in N02; FSPL cancellation in N04; interval subtraction and additive/geometry decomposition in N05; uniform-grid constraint in N06; minimum-CDF bounds and median counterexample in N08. These are analytical checks, not MATLAB runs.
- Limits: no independent reviewer agents available in this session, no new measurement-data joins or estimates of eligible pairs, no headroom calculation for new candidates, no model execution, and no inspection of lockbox data. Rankings and proposed work packages are reviewer judgments, not measured outcomes. Human authorization and the repository's independent review rules remain necessary.
