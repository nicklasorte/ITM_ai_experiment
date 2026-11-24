# Ten ITM experiments after B20 — revised research plan

Prepared: 2026-11-24. Revision 2 — 2026-11-24: all ten cards rewritten following the red team in section 6 and public-source verification. The current cards and execution plan in sections 2–5 supersede the initial proposal; section 6 remains unchanged as the historical review. Status: **proposed research only**. Reviewed snapshot: [main tree 74d79ff](https://github.com/nicklasorte/ITM_ai_experiment/tree/74d79ffbb68214f30edb8470cb5ef126968ea802). Parent: `best`, 707-cascaded-isolated-clutter-at-r, unless the planner records a subsequent keep. This is a new proposal, not a batch authorization; it does not supersede phase plan rev 4 or the frozen lockbox registration.

## 1. What the evidence says

- 000-baseline: composite 16.0 dB. R02 constrained refit: 15.9 dB. R01 unconstrained refit fails physics and censoring. Kept 707: composite 12.51 dB, screened composite about 9.91 dB, censored violations 22.8%. A new model must beat the actual parent, not just stock.
- B18: count-stable 1801 removed the principal-edge jump but was rejected under the registered censored recount; 1803 created new height defects; 1804 restored height response in the ridge sweep but failed the site gate. Those rulings stand.
- B19: 1901 and 1301 gave identical Phase 2 predictions; the P.452 scatter-line replacement is closed.
- D20a: on ridge40, 707 and 707 without the bound both change by +0.17 dB across a 1–30 m receiver sweep; stock changes by −23.30 dB. Alternate smooth surfaces yield −18.07 dB. The obstruction-adjusted surface is implicated; the log identifies the R1 inversion as a distinct smooth-path two-ray lobing problem. B21 already plans a new smooth-surface candidate; do not duplicate it.
- D20b: C·T accounts for 6%, 20%, 22% of mean reference attenuation across the three bands below 1 GHz. The preregistered one-third criterion failed. Clear-row mean error becomes −6.40 dB above 3 GHz; R2 clear rows above 3 GHz have −29.52 dB mean error (105 rows, not independent paths). Negative error means predicted loss is too low.
- D20c: 1,165 uncensored matched pairs; measured mean concealed-minus-open loss 11.30 dB, predicted 14.00 dB. Measured frequency slope +10.14 dB/decade, predicted +9.41. The full 707 concealed/open prediction beats the training-site refitted constant at R1 and VA but not R2. The existing configuration remains; the predicted difference includes both antenna-height substitution and the additive correction. The result does not validate either term in isolation or extrapolation above 3 GHz.
- B12, B14–B19 close several attractive families on the present data. Do not re-run curved phase alone, independent two-leg time convolution, P.617 fading-side scaling, scatter swaps, blanket NLCD clutter, path vegetation, the resolved-crest proposal, or Vogler as a direct terrain replacement. B16 already established that the edge selector, not the fixed-screen field, causes the jump.

Evidence: [LOG](../LOG.md), [results](../../results/results.tsv), [archive](../../results/archive_rev1.txt), [B18](../batches/B18.md), [B19](../batches/B19.md), [B20](../batches/B20.md), [D20a](../D20a-smooth-surface-terms/summary.txt), [D20b](../D20b-cascade-terms/summary.txt), [D20c](../D20c-paired-clutter/summary.txt), [phase plan rev 4](phase_plan_rev4.md).

## 2. Ranked portfolio — revised

Ranks indicate next-work order, not measured improvement or independent validation. N01–N10 retain their original IDs for traceability. All are proposals only; none authorizes a scored run. The current B21 workflow has precedence.

| Rank | ID | Revised experiment | Stage / disposition |
| --- | --- | --- | --- |
| 1 | N03 | Matched-height loss contrast and metadata audit | Development diagnostic |
| 2 | N05 | Factorial clutter/geometry decomposition with censored contrasts | Development diagnostic; critical correction |
| 3 | N04 | Fixed-cohort frequency residual contrast | Development diagnostic |
| 4 | N02 | Published delta-Bullington reference identity benchmark | Source and numerical audit; conditional candidate |
| 5 | N01 | Coherent smooth-reference field ablation | Hold pending N07 and B21 |
| 6 | N06 | Uniform-grid and sub-grid crest stability | Synthetic numerical diagnostic |
| 7 | N07 | Ground-impedance reference conformance | Prerequisite of N01, not separate scored candidate |
| 8 | N08 | Mechanism-margin conditional shape diagnostic | Parked; B15 closure stands |
| 9 | N09 | Finite-width-screen benchmark and 3-D terrain research | Synthetic research; external-data stage conditional |
| 10 | N10 | Prospective independent validation protocol | Separate research track; plan only |

## 3. Revised experiment cards

### Common registration and reporting contract

Before running any work package, record the exact parent code hash and configuration, source editions, frozen input/evaluator hashes, affected cohorts, estimands, null and positive controls, units, source-derived numerical tolerance, minimum meaningful effect and precision target, and stopping rules. Where a tolerance or threshold requires measurement uncertainty or solver benchmarks not yet available, record it as a registration blocker rather than inventing it. Reproduce stored parent predictions within 1e-9 dB before deriving model deltas; stock parity must satisfy the existing harness. No diagnostic may alter scored inputs or the evaluator. Report counts of rows, unique paths, fixed terminals and receiver groups; stratify screen membership and censoring. Keep diagnostic and scored records separate. The paths named below are proposed outputs under experiments/, not created files.

### N01 — Coherent smooth-reference field ablation

**Disposition:** hold model changes until N07 passes and B21's outcome is known. Target the R1 smooth-reference inversion, not the ridge40 missing height gain. D20a showed the ridge40 smooth increment is zero and the scatter bound does not bind; an amplitude change alone cannot be presumed to restore that gain.

**Hypothesis:** inappropriate coherent reflection in ITM's artificial smooth reference contributes to the R1-005-T5 inversion, distinct from the obstruction-adjusted surface defect. The ITM coefficient is roughness-weighted and empirically rescaled; the phase is compressed and the loss blended in dB. A literal divergence multiplier is an ablation, not automatically an electromagnetic correction.

**Design:** add report-only instrumentation to isolate the smooth-reference invocation of line_of_sight_loss in delta_bullington_reference. Freeze 707's geometry, actual-path calculations, cascade, bound, clutter and variability. Log raw complex reflection, roughness, rescaling, raw and compressed phase, field power, blend weight, A_s, L_bs, positive-part activation and bound status. Compare parent; divergence-only applied at an explicitly declared position relative to rescaling; and independent source-consistent specular-field reference for valid smooth LOS geometry. Do not use the source's reflection magnitude as a complex phase coefficient; derive the complex Fresnel phase with consistent time convention and path lengths. P.530-19 §6.1.2.4.1 eq. (132) gives the divergence factor, and eq. (138) combines reflection factors; §§6.1.2.3–6.1.2.5 define the reflection geometry and limitations [S1]. This is a LOS reference, not permission to apply it to transhorizon links or unknown specular surfaces.

**Tests:** flat-earth limit, zero reflection (unit direct-ray field before blending), reciprocal terminals, valid passive raw interface, grazing cases and synthetic independent height sweeps. Reproduce R1-005-T5 O/A, R2-020, R2-080-T4 and ridge40. D=1 ablation must reproduce 707. Compare actual-path scatter intermediates bitwise or at existing parity tolerance to verify no switch leakage. Treat legitimate multipath lobing and negative excess separately from an artificial-reference defect.

**Prediction/falsifier:** R1 artificial lobing may shrink; it may also grow depending on phase. Clear/clipped paths may be unchanged. Close if B21 resolves the target, the correction is clipped out, the source geometry is incompatible, new R2 defects appear, or N07 reveals no credible physical formulation. Do not treat smoothing as evidence of measured accuracy.

**Deliverable:** proposed N01 field-term sweep, source audit and support/delta table. Only a separately registered source-consistent candidate with applicable repair or gain gates may be scored. No fitted taper or phase threshold.

### N02 — Published delta-Bullington reference identity benchmark

**Disposition:** advance source and identity audit; no scored run yet.

**Hypothesis:** mixing a profile cascade with ITM's full smooth-path attenuation, which contains LOS and scatter behavior, creates a reference mismatch on obstructed paths. A spherical diffraction-only kernel is worth testing for consistency.

**Source correction:** direct inspection of P.526-16 Annex 1 §4.5.2 eq. (66) shows the standard itself uses L_ba + max(L_sph − L_bs, 0) [S2]. This is the positive-part placement in 707; it is not inherently erroneous. The original card's distinction from experiment 402 remains a description of its code, but the repository comment attributing outer clipping to P.526-16 eq. (66) should not be relied on. When L_ba=L_bs=x, this expression equals max(x,L_sph), so it returns L_sph only when L_sph≥x. Test whether any deviation matches the published full method before calling it a defect. P.526-16 §3.2 specifies the spherical calculation including subhorizon distances (10 MHz and above); do not use the beyond-horizon kernel alone on LOS geometry. P.1812-8 is scoped to 30 MHz–6 GHz [S4], not all Phase 2 frequencies.

**Design:** compare three distinct implementations on identical input geometry: (A) 707; (B) hybrid retaining the isolation-weighted actual and smooth cascade but replacing only A_s with P.526 spherical loss; (C) independent full P.526 §§3.2, 4.5.1 and 4.5.2 reference, diagnostic only, including its own prescribed Bullington terms. Check free-space reference, curvature, ground admittance conventions, frequency units, heights and branch rules. Avoid double subtraction of FSPL: spherical excess already refers to free space. Keep outer bound and other model components unchanged in B. Expose the exact circumstances of x>L_sph for both B and C; quantify residual attributable to cascade versus spherical kernel. Do not force identity using an offset.

**Tests:** benchmark §3.2 clearance/horizon behavior and §4.5.2 full-method calculations with independent source implementation or hand/reference cases; smooth constant/linear terrain, terminal reversal, steep profiles, grazing transition, low antenna cases, the three logged height failures, and R2/VA site regression. For zero spherical diffraction loss and positive x, expected output is x, not zero. Compare model-only deltas against archive and B21 to prevent redundant trials.

**Prediction/falsifier:** may remove some artificial smooth-reference lobing, but D20b shows little direct leverage on clear-path underprediction. Close if the benchmark cannot be reproduced, applicability requires an ad hoc switch, the hybrid departs from the justified reference behavior, the target is already addressed by B21, or the support screen and repair route both fail. No claim that a hybrid conforms to P.526.

**Deliverable:** source mapping, independent reference vectors, identity/clipping report, model-only smoke and affected-path headroom if warranted. Source equations inspected; implementation and benchmark remain outstanding.

### N03 — Matched-height loss contrast and eligibility audit

**Disposition:** first development diagnostic. No model modification.

**Hypothesis:** 707's obstructed-path height response differs from measured finite height contrasts, and a physically valid repair should reduce contrast error on independent physical paths. Contrasts cancel common additive calibration offsets only; they do not identify a unique mechanism or establish a universal height derivative.

**Design:** construct a shared outcome-blind metadata manifest for N03–N05 using existing development inputs and historical documentation. Fields: base physical path/site/fixed terminal; f_MHz; structural TX/RX heights; changed end; siting; polarization; antenna/equipment configuration; session or documented stability; terrain ID; measurement type/calibration/detection bound availability; exclusion reason. Do not infer missing hardware equivalence or obstruction from the siting label. Lock eligibility before computing residuals. Within each path/frequency/configuration choose the lowest and highest eligible heights at one end as the primary pair, holding the other end fixed; tie-break by stable recorded ID; overlapping secondary pairs are descriptive. Preserve actual height increments.

**Estimand:** ΔL = L_high − L_low (dB). For model M, e_M = ΔL_M − ΔL_meas. Primary comparison is paired path-level absolute contrast error difference |e_M|−|e_707|, with stock and R02 and B21 if registered. Aggregate repeated frequencies within path before equal-path reporting, and cluster by fixed terminal/site where support permits. Show dB/m only for declared comparable spans; it is not a local derivative. For censored observations use interval subtraction (N05), report lower-bound error and consistency apart from detected-pair errors. Report actual support, sign agreement, height increment distribution, uncertainty and site results. A measured contrast may increase with height due to coherent multipath; do not enforce monotonicity on observations.

**Prediction/falsifier:** obstructed 707 contrasts may underestimate the measured benefit; compare clear controls and keep the distinct R1 inversion separate. Stop on inadequate matching, insufficient precision for a preregistered meaningful contrast, or lack of replication. Single-site results are local. If B21 improves synthetic behavior but not paired measurements, report both.

**Deliverable:** proposed shared eligibility/exclusion manifest, matched-height contrast CSV and report, uncertainty calculation; no new keep criterion. Measurement documentation: NTIA historical archive and TM-19-535 [S5,S6].

### N04 — Fixed-cohort frequency residual contrast

**Disposition:** advance after N03's shared metadata audit.

**Hypothesis:** within identical geometry, clear-path measured-minus-predicted loss rises with frequency on R2/VA; the pattern may distinguish missing attenuation from obstructed-path diffraction scaling.

**Design:** use eligible matched physical paths with identical endpoint heights, siting, polarization and compatible calibrated basic-loss measurements at different frequencies. Predeclare pair spans using metadata availability only; use an eligible lowest/highest pair per configuration as primary, with a nontrivial minimum log-span derived from the measurement uncertainty and declared precision target. Exclude R2 pairs crossing a documented height change unless heights match; publish exclusions. Use the same paired cohort at both frequencies. Define clear-at-both and obstructed-at-both from frozen geometry and effective radius; retain changing-class paths separately. Distinguish geometric direct-ray clearance and normalized Fresnel clearance.

**Estimand:** primary paired residual difference T=(L_meas,2−L_pred,2)−(L_meas,1−L_pred,1) in dB. Secondary slope T/log10(f2/f1), dB/decade. Cross-check using excess-loss slopes: FSPL cancels in their difference. For censored endpoints use interval arithmetic; do not substitute detection bounds as point measurements. Report equal-path clustered contrasts, uncertainty due to calibration/configuration, and sensitivity by band/site. R3 is a comparison, not proof of no mechanism.

**Attribution:** log J terms, C·T cascade correction, smooth increment, bound activation, and terminal-height/clutter effects (N05) at both frequencies. Inspect changes before and after clipping. If a source-grounded ablation is needed, register it as a separate model-only diagnostic with one intervention; do not infer causal contribution from a large component.

**Prediction/falsifier:** positive T on high-frequency clear matched R2/VA; obstructed low-frequency contrast may differ. Stop if effect disappears after height/configuration matching, uncertainty dominates, or no replicated paths/sites support it. No generic frequency multiplier or new fit from this diagnostic.

**Deliverable:** fixed-cohort contrasts, support/exclusion tables and conditional component report. Measurement controls: [S5,S6]; diffraction geometry: [S2].

### N05 — Factorial clutter/geometry decomposition and censored contrast

**Disposition:** advance immediately after common metadata audit. Critical correction to D20c attribution, not to its recorded RMS arithmetic.

**Hypothesis:** the net concealed/open effect includes geometric height substitution, additive P.2108 correction and any nonlinear interaction. Their predictive usefulness may vary by site and frequency. P.2108-1 Annex 1 §3.1 and Table 1 require the base propagation calculation to reference the representative clutter height for terminals below it; the correction covers 0.03–3 GHz [S3]. The 707 implementation follows this height construction; holding the correction at 3 GHz above that range is a repository design choice.

**Design:** reproduce the 1,400 recorded C/O pair matches and their stored predictions before applying stricter N03 metadata eligibility; preserve both populations and account for every exclusion. Inspect the core's height substitution before quick_pfl and final correction before variability. At each concealed row hold metadata and structural height fixed and make diagnostic-only independent interventions on the modeled path height and additive A_h evaluated at the original structural height h. Define H=max(h,R) and G(h_model,A) as final loss through the same bound and variability chain. Four cells:
- G(h,0): actual modeled height, no correction.
- G(H,0): raised modeled height, no correction.
- G(h,A_h): actual modeled height plus correction (known double-counting control, not a candidate).
- G(H,A_h): raised modeled height plus correction (parent reproduction).

Geometry effect = G(H,0)−G(h,0); conditional additive effect = G(H,A_h)−G(H,0); interaction = [G(H,A_h)−G(H,0)]−[G(h,A_h)−G(h,0)]. Geometry plus conditional additive equals total G(H,A_h)−G(h,0). Verify this numerically and compare G(h,0) with matched open prediction. Report A_h before nonlinear processing, mode, horizon, bound, and final loss terms. Keep the parent settings otherwise unchanged. Explicitly distinguish the model decomposition from a causal decomposition of measurements.

**Censoring:** for C and O intervals [lo,hi], measured contrast belongs to [C_lo−O_hi,C_hi−O_lo]. Exact/exact is a point; censored C with detected O gives a lower bound, and detected C with censored O an upper bound. Both right-censored losses generally yield an uninformative contrast. For each prediction report exact-pair RMS, informative-bound violation count/share and magnitude, and uninformative count separately. Distance to an interval is a lower bound on absolute error, not exact error or a likelihood. Do not merge metrics. Fit the training-site constant only on the declared detected training pairs, keep 704's fixed 16.75 dB control distinct, and include zero. Reproduce the original 1,165 exact/235 other pair totals before eligibility exclusions. Split supported 30 MHz–3 GHz and above-3-GHz hold3 strata; estimate within-base/within-height frequency contrasts, not pooled slope alone. Report path-cluster intervals and site-specific results.

**Prediction/falsifier:** parent net difference may remain supported, while additive-only attribution is not. If height/soft-limit effects are negligible on the declared cohort, quantify them instead of assuming they matter. If eligibility or bound information is too weak, report inconclusive. Do not change the term or gates; no claim of independent causal validation.

**Deliverable:** proposed factorial component CSV, interval-consistency report, source-grounded correction note for planner disposition; original D20c records remain intact. See [core](../../itm_variant/itm_p2p_core_exp.m), [D20c script](../batches/b20_d20c_paired_clutter_rev1.py), [S3].

### N06 — Uniform-grid and sub-grid crest stability

**Disposition:** bounded synthetic audit, not a new edge selector.

**Hypothesis:** crest sampling and near-tied ridge selection can produce excess numerical sensitivity beyond physical geometry changes. Do not conflate this with B16's documented height-driven selection jump.

**Design:** two distinct valid PFL families: (A) fixed analytic terrain and endpoints, integer interval count n and uniform spacing d/n; (B) fixed uniform grid with analytic crest translated by a sub-grid offset, labeled geometry sensitivity, not identical terrain. Never construct invalid shifted grids with short endpoint cells. Optional nonuniform or high-resolution reference is external to ITM and not measured truth. Use symmetric and asymmetric near-ties, single sharp crests, broad plateaus, and isolated ridges, with fixed physical heights/frequencies. Sample resolution/crest-position sweep, then terminal reversal. Compare 707, 1801 diagnostic only, and stock; keep 1801 rejected.

**Measures:** edge count/coordinates, ν separation and isolation weights, actual and smooth cascade, positive-part and bound, maximum finite change, convergence rate and reversal error. Define a geometric discretization uncertainty envelope from analytic profiles and independent fine-grid reference before running; derive tolerances from numerical error, not the observed worst jump. For real profiles only non-scoring interpolation/decimation sensitivity, not independent terrain observations or new scored spacing.

**Prediction/falsifier:** near-ties may show excess sensitivity while isolated sharp controls converge. Stop if changes fall within expected geometry error, are explained by known B16 switches, or depend on invalid grids. No empirical smoothing or fitted tie threshold. Source: P.526 geometry and isolated-obstacle concepts [S2], B16.

**Deliverable:** synthetic test matrix, convergence plots, regression cases and disposition; no production code authorization.

### N07 — Ground-impedance reference conformance (N01 prerequisite)

**Disposition:** retain separate ID but execute as part of N01's prerequisite audit; no separate score.

**Hypothesis:** a unit, convention or implementation mismatch in the raw interface coefficient could affect the smooth-reference reflection. Empirical ITM roughness and rescaling are intentional approximations, not bugs merely because they depart from exact Fresnel theory.

**Design:** four layers: raw complex interface; ITM roughness/rescaling; field phase and dB blending; final delta/scatter bound. Compare raw horizontal/vertical coefficients to an independent Fresnel boundary-condition calculation under identical grazing angle, complex sign convention and material parameters. Compare the magnitude to P.530-19 eqs. (127)–(131) in its applicable domain, using consistent S/m, GHz/MHz, relative permittivity and polarization [S1]. The standard supplies magnitude, not complex phase. Compare empirical layers to pinned NTIA ITM [S7], not to raw Fresnel values. Sweep one parameter at a time, then a small factorial within documented ITM-valid conditions; include low conductivity, conducting limit as an analytical reference where appropriate, grazing, near-zero coefficient/denominator handling and finite outputs. Use independent oracle tolerances fixed before testing.

**Prediction/falsifier:** a genuine port discrepancy reproduces on synthetic inputs and stock reference comparison; agreement means close the implementation-error hypothesis. Apply passivity to the raw passive interface under the correct convention, not the final effective reflected/direct field. Do not fit historical soil properties or use new ground constants on scored data. If a distinct approximation improvement is justified, register separately only after N01 source/geometry and headroom checks.

**Deliverable:** coefficient/reference conformance table and numerical edge cases feeding N01; no double-counted candidates.

### N08 — Mechanism-margin conditional shape diagnostic (parked)

**Disposition:** B15 already considered per-percentile diffraction/scatter minimum and soft-minimum. Keep B15 closed. No new atmospheric model authorized here.

**Hypothesis:** independently supported near-tie diffraction/scatter paths have conditional long-term shape error beyond distance/frequency trends, which might indicate a missing joint-mechanism distribution. Aggregate historical loss CDFs do not identify branch marginals or dependence.

**Reopening prerequisites:** new evidence for physically valid component eligibility and a distinct estimand; otherwise park. If approved for diagnostic only, predeclare signed median margin and near-tie strata based on branch validity and uncertainty, not residuals. Match dominant controls by frequency, distance and terrain; count independent receiver groups. Use median-centered losses at nonmedian available percentiles on both sides, with 50% as a parity anchor (not an endpoint). Compare parent and B15's registered per-quantile alternatives as analytical controls without new scores. Estimate a support-specific optimistic ceiling separately from B15's restricted shape correction ceiling.

**Synthetic counterexample:** for a stochastic minimum of independent loss components with CDFs F_D,F_S, F_min=F_D+F_S−F_D F_S; without dependence assumptions the bounds are max(F_D,F_S) and min(1,F_D+F_S). At a shared continuous median, independent minimum CDF is 0.75, so median preservation is not automatic. A physical incoherent-power sum has different loss algebra (−10 log10 of summed linear power factors); B15's soft-minimum is yet another prescription. P.2001-6 [S8] is a source lead for its own model combination, not proof of independence or license to combine incompatible processes.

**Go/no-go:** remain parked unless independent branch statistics or a justified dependence model become available, the conditional shape signal replicates, and a physically derived candidate has sufficient headroom. Do not recenter an arbitrary curve to force median parity. No reopening P.617 or changing the existing gate.

**Deliverable:** if prerequisites are met, conditional diagnostic with uncertainty and explicit identifiability limits; otherwise document parked status.

### N09 — Finite-width-screen and 3-D transverse terrain benchmark

**Disposition:** separate longer-horizon research. Stage A synthetic only; stage B requires new data approval. No scored ITM correction.

**Hypothesis:** centerline-identical geometries with different transverse obstacles can yield different received fields. The sign is not predetermined; side-edge contributions may interfere constructively or destructively.

**Stage A:** start with the published finite-width screen, not a corridor DEM. P.526-16 §5.1 eqs. (71)–(72), printed p. 34, provides distinct minimum-loss and average-loss predictions from the top and side edges; §5.2 provides a further thin-screen/aperture reference [S2]. For edge attenuation factors j_i=10^(J_i/20), reproduce the stated limiting amplitude sum and power sum in their proper statistics. As side-edge contributions tend to zero, both approach the top-edge-only loss. Do not compare a single coherent field sample to the average-loss expression. Record physical units, polarization, screen assumptions and phase/spatial averaging protocol. Use normalized transverse widths relative to first Fresnel radius, with fixed centerline and endpoints. Synthetic screen verification is a prerequisite, not proof that thin screens represent actual terrain.

Next benchmark a validated 3-D solver against free space, a transverse-invariant 2-D limit, and the finite-width screen/statistic above within its applicable geometry; require independent reference or converged solution for phase-resolved comparisons. Document marching-angle validity, absorbing boundaries, grid/step/domain-width convergence and numerical error budget before terrain runs. Vary only transverse ridge width or saddle geometry while keeping longitudinal terrain, terminals, material and frequency fixed. Compare complex field/power using consistent averaging, include negative controls and constructive/destructive cases. Zelley & Constantinou (1999) [S9] provides a peer-reviewed radio-propagation precedent with scaled and field measurements; its accessible abstract is not a reproduced solver benchmark.

**Stage B:** conditional on successful benchmarks and separate approval, propose public contemporaneous corridor terrain with documented resolution/uncertainty, historical mismatch and antenna information. Freeze corridor and solver extent from physics, not the path of least measured residual. Use independent sites. Do not alter centerline profiles or evaluator. No assumption a lateral saddle yields lower loss.

**Prediction/falsifier:** measurable transverse-width effect relative to converged uncertainty; invariant ridge recovers the 2-D limit. Close if benchmark or convergence fails, effect is not resolvable, or data are insufficient. Evidence of missing dimensions is not evidence of a transferable ITM improvement.

**Deliverable:** analytical benchmark vectors, solver selection and convergence plan; later conditional research protocol. No solver execution or corridor acquisition authorized.

### N10 — Prospective independent validation protocol

**Disposition:** separate validation workstream; begin design only. No fieldwork, data acquisition, or model evaluation approved by this document.

**Hypothesis:** physically justified model changes improve prediction on independent paths within a declared population rather than exploiting repeated reuse of historical development sites. A failed replication within that population weakens transfer claims; failure outside the population may reflect domain shift.

**Design:** declare target populations, frequencies, geometries, measurement statistic and eligibility before acquiring outcomes. Freeze one candidate, current parent and stock comparator with hashes. Use independent site/physical-path selection, stratified by clear, obstructed, terminal-clutter and negative-control scenarios. Require calibration and repeatability records, endpoint positions/height and terrain survey uncertainty, polarization, antenna patterns, frequency/session/weather, detection dynamic range and thresholds, basic transmission loss definition and time statistic. Ensure calibration and record provenance are comparable; short spot data do not validate annual time distributions. Use NTIA TM-19-535 [S6] and ITU-R P.311 [S10] as protocol references. Audit potential source overlap by campaign/path metadata without examining existing lockbox outcomes. Keep pilots separate from confirmatory sites.

**Primary endpoint:** paired difference in absolute basic-transmission-loss prediction error (candidate minus parent) on detected observations, aggregated at the physical-path level and with site-clustered uncertainty; require a separately registered non-inferiority criterion for censoring violations, counts and bound magnitudes on all relevant observations. Stock is a fixed secondary comparator. Secondary endpoints: matched height/frequency contrast errors, site-band and tail errors, long-term shape only with compatible long-term records. Specify the meaningful paired effect, precision/confidence target, weighting, multiplicity and missingness before outcomes. Compute sample size using pilot or conservative variance, independent site/path clusters and expected censoring; no unsupported numerical sample-size claim.

**Blinding:** independent custodian holds outcomes, freezes manifests and releases after the analysis plan is signed; evaluate frozen models once. Reuse is development. Preserve the existing lockbox and registration as separate assets. Any new data/evaluator interface requires approval.

**Go/no-go:** no acquisition until sampling frame, resources, calibration plan, independence/overlap check, custodian and precision requirements are approved. Inadequate replication or comparability is a limitation, not a model failure.

**Deliverable:** prospective protocol, feasibility inventory, risk/uncertainty budget and approval decision; no new dataset or experiment result.

## 4. Revised execution and acceptance plan

| Package | Cards | Release criteria |
| --- | --- | --- |
| A | N03 → N05 → N04 | Shared locked metadata manifest; reproduce parent; paired contrasts, censored interval and factorial reports; independent-unit counts; no scored runs |
| B | N02; N07 → N01 | Source references and independent benchmark; B21 disposition; valid geometry, reference identity and context isolation; support/headroom screen |
| C | N06 | Valid uniform PFL; analytic controls, convergence and known-defect differentiation |
| D | N08 | Park until new evidence and distinct estimand; B15 remains closed |
| E | N09, N10 | Separate synthetic research and prospective validation plans; independent approval before solver implementation or data acquisition |

Continue approved B21 without alteration. Package A has the best immediate information value and should not depend on B21 completion. Packages B/C may prepare source or synthetic test plans, but a scored candidate must be registered after comparing against B21/current best. N07 is a prerequisite, not an additional scored trial. Do not run N08 on the current evidence. For N09 and N10 distinguish planning from execution.

**Registration:** use FRAMEWORK.md, program.md, latest approved phase/batch and the actual current parent. Record model-only exact support and deltas; reject duplicates before scoring. A perfect correction confined to exact support gives an optimistic ceiling, not an expected gain. A 0.3 dB improvement in a three-component mean requires 0.9 dB improvement in one component if others are unchanged. Evaluate full and screened objectives separately; the approved phase plan defines the applicable gain/non-inferiority rules, not this arithmetic observation. At the prior reviewed snapshot k=7 was next against 707; re-read results and multiplicity before registering. Preserve all approved site, censoring, physical, screening and parameter-complexity constraints. Do not alter 1801's rejection or make the approved height-defect repair exception general. Use the repository's three independent reviewers for applicable keeps.

**Development versus validation:** repeated inspection of frozen site folds is development, even with training-only coefficient fitting. Cluster comparisons by physical path and shared terminal/site or receiver group as appropriate; report effective support and uncertainty. No tuning on held-out folds or lockbox inspection. No new input, evaluator, implementation or batch approval is granted. Diagnostics never change scoring membership, input hashes or existing results.

**Decision record:** each card produces a pass / fail / inconclusive / redundant / parked disposition with evidence and remaining blockers. Close unidentifiable or duplicate families. Report numerical consistency, physical consistency and prediction accuracy separately. Preserve negative findings.

## 5. Public sources and red-team disposition checks

Public sources retrieved on 2026-11-24. Selected primary-source PDF pages were inspected for the key formulas; no external reference implementation or MATLAB benchmark was executed. Direct references:

- [S1 — ITU-R P.530-19 (09/2025), Annex §§6.1.2.3–6.1.2.5](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.530-19-202509-I%21%21PDF-E.pdf). Rendered printed pp. 44–45 checked: eqs. (127)–(132) and (135)–(138). LOS reflection geometry, divergence, coefficient magnitude and limits. N01/N07.
- [S2 — ITU-R P.526-16 (11/2025)](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.526-16-202511-I%21%21PDF-E.pdf). Rendered printed pp. 15–16, 28, 30 and 34 checked: §3.2, §4.5.1–4.5.2, eq. (66), §5.1 eqs. (71)–(72). N02/N04/N06/N09. Verify remaining numerical branches and reference values at registration.
- [S3 — ITU-R P.2108-1 (09/2021)](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2108-1-202109-I%21%21PDF-E.pdf). Rendered printed pp. 2–3 checked: clutter definition, Table 1 and §3.1 model domain/base-height construction. N05.
- [S4 — ITU-R P.1812-8 (09/2025) scope](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.1812-8-202509-I%21%21SUM-HTM-E.htm). 30 MHz–6 GHz path-specific point-to-area scope; no extrapolation implied. N02.
- [S5 — NTIA ITS legacy propagation archive](https://its.ntia.gov/data/legacy-radio-propagation-data). Historical measurement source; eligibility still requires the underlying metadata. N03/N04/N05.
- [S6 — Hammerschmidt et al., NTIA TM-19-535, Best Practices for Radio Propagation Measurements (2018)](https://its.ntia.gov/publications/details?pub=3211). Official publication abstract and metadata checked, covering system verification and uncertainty. N03/N04/N10.
- [S7 — NTIA reference ITM](https://github.com/NTIA/itm), and [ITU-R P.527](https://www.itu.int/rec/R-REC-P.527). Reference-port/ground-material leads; use the pinned repo baseline rather than assuming current upstream parity. N07.
- [S8 — ITU-R P.2001-6 (09/2025) contents](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I%21%21TOC-HTM-E.htm). Source lead for mechanism combination; exact combination equations and validity not verified here. N08 stays parked.
- [S9 — Zelley & Constantinou, IEEE Transactions on Antennas and Propagation 47(10), 1586–1596 (1999)](https://doi.org/10.1109/8.805904), [university research record](https://research.birmingham.ac.uk/en/publications/a-three-dimensional-parabolic-equation-applied-to-vhfuhf-propagat/). Abstract reports 3-D PE, lateral terrain effects and measurement comparisons; full article/benchmarks not reproduced. N09.
- [S10 — ITU-R P.311 index](https://www.itu.int/rec/R-REC-P.311/en). P.311-20 (09/2026) surfaced in the official catalog search; direct edition page was blocked during retrieval, so verify edition text before protocol registration. N10.

### Red-team closure matrix

| Review finding | Revised response | Status |
| --- | --- | --- |
| N01 field inconsistency | Separate empirical ablation and coherent reference, correct P.530 citation, context isolation | Design addressed; benchmark pending |
| N02 smooth-limit identity | Source verified positive-part formula; full-reference comparison and conditional identity | Design addressed; numerical verification pending |
| N03 height-pair confounding | Outcome-blind manifest, one primary contrast, clustered uncertainty | Design addressed; data support unknown |
| N04 frequency confounding | Identical heights/geometry, fixed cohort, FSPL cancellation cross-check | Design addressed; data support unknown |
| N05 clutter misattribution | Height/term factorial, censor intervals, domain split; P.2108 source checked | Design addressed; diagnostic pending |
| N06 invalid grid | Fixed-endpoint uniform grids and explicit geometry-shift experiment | Design addressed; tests pending |
| N07 empirical versus raw reflection | Separate layers and NTIA parity, merge with N01 | Design addressed; audit pending |
| N08 overlap and dependence | Park; conditional diagnostic only, explicit nonidentifiability | Closed to scored work on current evidence |
| N09 solver validity | P.526 finite-width reference and 3-D convergence plan | Design addressed; benchmark pending |
| N10 independence | Frozen prospective endpoint, cluster precision and custodian | Design addressed; approvals/data pending |

Revision checks: ten IDs retained, ten red-team objections mapped to changed protocols, original review preserved below. The design revisions do not constitute experimental validation or independent reviewer approval. No new MATLAB runs, source-code edits, data joins, eligibility counts, independent reviews or lockbox access were performed. The earlier plan is recoverable at commit [a4ae675](https://github.com/nicklasorte/ITM_ai_experiment/blob/a4ae675fc956a96a7092c9568a83a34f0f185fd4/experiments/proposals/post_b20_ten_experiments_rev1.md); the red-team record at commit [559683c](https://github.com/nicklasorte/ITM_ai_experiment/blob/559683ccdb6fafd1ded47ecfb8248f58f8e845e9/experiments/proposals/post_b20_ten_experiments_rev1.md). Section 6 is historical; where primary-source verification corrected an earlier review interpretation (notably N02), the revised section 3 governs.

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
