# Greenfield terrestrial propagation model: architecture, adversarial review and revised design

2026-11-26 | Planner | Research proposal, not a production model or registered experiment.
Repository snapshot 2f887feddcff94a3ddf3bc9ba71499f279f9e54d. Scope: individual terrestrial point-to-point propagation loss, not network interference. No frozen inputs, evaluator, model code, or lockbox changes. Working name: PACE (Physics-Aware Channel Engine), provisional.

## 1. Objective and baseline

Build a new model rather than optimize a legacy equation against the same measurements. NTIA ITM covers 20 MHz–20 GHz, with median attenuation and variability [1]. P.2001-6 (Sept 2025, in force) covers 30 MHz–50 GHz; its stated strongest distance range is roughly 3–1000 km [2]. It already combines normal propagation, anomalous propagation, troposcatter and sporadic-E and predicts fades and enhancements [2,3]. The proposal is not novel merely because it has multiple mechanisms. Its potential distinction is a common environmental state, independently verified numerical reference hierarchy, explicit uncertainty and traceable fidelity selection.

Long-term aspirational coverage is 20 MHz–50 GHz, terrestrial paths 1–1000 km, both polarizations and average-year time distribution. This union is not an initial validated domain. First release is narrower: 0.1–10 GHz, 3–100 km, fixed outdoor terminals 0.5–100 m AGL, rural/open terrain, median under specified environmental assumptions; blocked paths only if relevant scatter mechanisms are shown negligible or covered. No short-range urban, ionospheric, duct-dominated or extreme-time claim until validated. These limits are planning targets, not physical cutoffs or established validity.

B32/B33/B34 identify historical geometry/calibration uncertainty, height-domain limitations and a reported 0.197 dB profile serialization discrepancy. Rev5's limited frozen-input headroom is not a universal noise floor. A fresh model needs independent measurements and new validation governance; existing data are development evidence.

## 2. Initial design V0 (before adversarial review)

Use a 3D terrain/landcover/weather scene, fast direct/reflected/diffracted fields, a 2D or 3D parabolic-equation (PE) solver for complex paths, statistical scatter and anomalous channels, and ML surrogates for computational speed. Sample environmental states, combine received power, return a loss CDF and uncertainty. Use adaptive fidelity and calibration to measured paths. Compare with stock ITM, 707 and P.2001. Initial aspiration: one interface covering all terrestrial paths.

This sketch is attractive but underspecified: no unique normalization, no independent separation of mechanisms, no common time law, no concrete reference hierarchy or cost budget.

## 3. Adversarial review of V0

Self-adversarial design review, not independent reviewer sign-off. Each objection below is material.

| ID | Failure mode | Consequence | Required change |
|---|---|---|---|
| R01 | PE and ray/diffraction predict overlapping fields | double counting, impossible channel | one surface-field solver per state; replace, never add overlapping solver predictions |
| R02 | add dB or combine marginal quantiles | false time tails | joint state simulation and linear-power/coherent rules with phase provenance |
| R03 | atmospheric climatology not actual path conditions | rare duct events invented or omitted | distinguish snapshots vs annual distribution, calibrated regional state generator and abstention |
| R04 | 2D PE misses transverse terrain and backscatter | biased blocked paths | explicit 2D limitations, 3D reference cases, no universal truth claim |
| R05 | PE paraxial approximation and polarization issues | incorrect steep-angle/near-field outputs | angular/domain flags, wide-angle and independent Maxwell reference |
| R06 | near-ground antennas and terrain datum unknown | fitted physics absorbs measurement error | reference planes, surveyed electrical centers, source manifests, uncertainty |
| R07 | empirical scatter extrapolation (P.2001-5 caution [2]) | unphysical short-distance scatter | domain masks, overlap verification, independent scatter validation |
| R08 | arbitrary mechanism transition or gate | discontinuities, reciprocity failure | reciprocal invariant classifier, compare matched solver solutions; abstain on disagreement |
| R09 | ML shortcut learns site identity or legacy model error | leakage, poor transfer | surrogate only reference solver initially; geographic/campaign splits, OOD checks |
| R10 | accurate median but unsafe low-loss tail | interference planning error | separate lower-tail metrics and coverage; no tail release without evidence |
| R11 | deterministic solver not real-world truth | numerical accuracy mistaken for predictive skill | reference hierarchy and independent calibrated field campaigns |
| R12 | shared terminals treated as iid | narrow uncertainty | terminal/campaign grouping, measurement likelihood and censoring |
| R13 | sub-ULP rounding triggers branch jumps | irreproducible outputs | canonical lossless inputs, explicit tie policies, boundary regression tests |
| R14 | millions of expensive PE calls | unusable production model | fixed benchmark workloads and cost/error cascade with documented fallback |
| R15 | extra inputs unavailable | biased availability and false precision | distinct input tiers and missingness-specific validation; no silent imputation |
| R16 | model fitted to previous evaluation history | benchmark contamination | separate development/validation and independently managed prospective test |
| R17 | passive propagation incorrectly bounded by FSPL | valid focusing rejected | energy/reciprocity tests on reference system; FSPL is not universal lower bound |
| R18 | rain, clutter, foliage added after already modeled geometry | repeated attenuation | mechanism ownership ledger and path-specific integrals |
| R19 | unsupported 20 MHz–50 GHz universal scope | expensive unfinishable program | staged narrow MVP; explicit unsupported status |
| R20 | complex model beats baseline only on average | localized harms hidden | paired site/band/regime guardrails and runtime comparison, no claim of replacement without all gates |

Verdict: reject V0 as implementation specification. Keep the objective and replace architecture with V1 below.

## 4. Revised design V1 — bounded, state-conditioned, multifidelity

### 4.1 Input and output contract

PathRequest: frequency Hz; two WGS84 geodetic coordinates, electrical center height with datum and AGL/AMSL semantics; polarization pair; observation bandwidth and averaging convention if coherent channel requested; model intent (snapshot or climatology); supplied or requested time quantiles p in (0,1); terrain profile or corridor with horizontal/vertical CRS, source edition, units, spacing and error; ground complex permittivity or conductivity; optional weather/refractivity field with timestamp/coverage; optional vegetation/building descriptors; uncertainty metadata. Use physical SI internally. Separate e^(+jwt) versus e^(-jwt) convention in field solver; verify sign of conductivity term. Store exact float64 binary values, input hashes, version and seed. Reject malformed geometry rather than clamp silently.

Three input tiers: T0 terrain and climatology, T1 mapped land/ground with uncertainty, T2 contemporaneous measured environmental fields and surveyed terminals. T0 does not pretend to know site-specific instantaneous phase or weather. Tier-specific calibration and validation. Snapshot returns conditional loss, not annual quantile; climatology returns annual time distribution only after validated weather/time model. Spatial variability and model epistemic uncertainty separate from time variability.

PathResult: basic transmission loss for agreed idealized reference antennas or directional link transfer as separate API, quantile convention explicitly nonexceedance; median, supported percentiles, uncertainty interval for each prediction, mechanism/fidelity flags, input coverage, diagnostic geometry, numerical error estimate, model discrepancy estimate, provenance and status {valid, limited, unsupported, numerical_failure}. No numeric result for unsupported requested quantity; optional baseline fallback named separately, never labeled PACE. Antenna gains and feeder loss not silently included. For directional transfer, patterns applied at departure/arrival directions, not a blanket gain when multipath matters.

### 4.2 Common environmental state

Let X be fixed geometry and measured metadata, Z be a realization of environmental conditions, theta be uncertain model parameters. Distinguish Z(time) from uncertainty about X/theta. Use one joint Z per path prediction: refractivity profile N(s,z), ground state, precipitation, vegetation moisture and small-scale phase state where defined. n=1+10^-6 N. For a snapshot, condition on observed Z and its uncertainty. For climatology, fit a documented state distribution conditional on region, season and terrain, using time weights and matching temporal resolution. No independent random draws for mechanisms affected by common weather unless validated. Outer epistemic scenarios and inner aleatory states; do not flatten them into a single annual distribution. Surface gradient alone cannot identify elevated ducts. Frequency-dependent material loss and absorption require source-based limits.

### 4.3 Surface field engine

A. Free-space reference: Lfs=20 log10(4 pi d/lambda), d>0, far-field reference. Analytic direct + reflected fields on planar impedance boundary; Fresnel convention and path phase verified against independent solution. Receiver polarization projection and antenna reference normalization explicit. Coherent sum only where phase reference, averaging and bandwidth justify it. Perfect ground and free-space limiting cases. 
B. Fast terrain engine: source-based multiple-edge diffraction/UTD or validated approximation; smooth spherical Earth benchmark. Direct/reflected/diffracted contributions must come from a consistent asymptotic representation, not overlapping total predictions. Uniform transition treatment at shadow boundaries; no generic smooth blending of losses.
C. Reference field engine: wide-angle 2D PE over impedance terrain, with range-dependent refractivity, then selective 3D PE or independent full-wave small-scale reference. Candidate scalar narrow-angle equation under e^(-i omega t) and forward carrier e^(ik0 x): 2ik0 du/dx + d²u/dz² + k0²(n²-1)u=0, obtained by dropping d²u/dx² from scalar Helmholtz. This is not the final wide-angle solver or vector Maxwell solution. Derive actual discretization, impedance boundary, coordinate transformation, launch and receiver extraction before coding. Curvature handled once (physical spherical geometry or documented flattening transformation). PE cannot serve as universal reference for backward/steep/3D scattering. Use convergence in range, height, transverse extent and absorbing boundaries. Select one surface solver per state; compare cheaper tier to reference on identical state, not as an added path.

### 4.4 Additional propagation mechanisms

- Troposcatter: separately validated power-transfer model on common atmospheric state where small-scale turbulence not already included in surface solver. Use bistatic scatter volume, frequency, turbulence statistics and terminal geometry with source-supported parameterization; no extrapolation outside validated angular/distance support. P.617 and P.2001-6 attachment E are research baselines, not adopted formulas yet.
- Ducting and refractive enhancement: if PE includes refractive profile, duct propagation belongs to surface solution; do not add P.452/P.2001 anomalous channel on the same state. A climatology-only surrogate for that solution is an alternative, not extra power. Require independent low-loss event observations before release.
- Sporadic-E: separate ionospheric mechanism only after frequency, distance and regional occurrence validation; outside MVP.
- Gas and rain: apply complex attenuation along each actual modeled trajectory or within solver medium, not blindly add a ground-path scalar to scatter. For gamma in dB/km, path attenuation integral gamma ds; field magnitude factor 10^(-A/20). Reference P.676/P.838; verify equations and domains before implementation.
- Clutter/vegetation: local geometry/material layer or a residual attenuation model for unresolved features, never both on same feature without documented partition. P.2108/P.833 references. No arbitrary canopy height subtraction. Urban multiple scattering outside MVP.

Mechanism ownership ledger for each state records covered physics, solver and omitted channels; if an omitted channel could matter and no bound exists, output limited/unsupported, not a confident number.

### 4.5 Combine at the receiver, then compute statistics

Normalize complex voltage transfer H to a consistent power-wave reference so G=|H|² is dimensionless power ratio under stated reference conditions. If mutually coherent resolved mechanisms, G=|sum H_m|²; for demonstrably incoherent averaged components, G=sum E|H_m|² (plus coherent group powers), not sum losses in dB. If correlations unknown, do not assume incoherence for instantaneous predictions; for two deterministic magnitudes a,b the coherent power range is [(a-b)²,(a+b)²], illustrating phase uncertainty, not annual probabilities. No unvalidated phase model. Use reference-plane normalization appropriate to solver; loss L=-10 log10 G. Handle exact null as infinite loss or receiver-floor censoring with explicit status, never arbitrary finite clamp.

For each state j compute G_j and L_j. Weighted CDF F_L(l)=sum w_j 1[L_j<=l], weights nonnegative sum one; q_p=inf{l:F_L(l)>=p}. p=0.01 means low loss not exceeded 1% of time (not exceedance). No minimum of marginal quantiles or addition of dB quantiles. If band/time averaging requested, define statistic on power before conversion; different averaging produces different quantities. Monte Carlo percentile uncertainty from effective sample size/dependence, not draw count alone. At p=0.001, 10000 independent draws yield 10 expected lower-tail events; inadequate for robust tail claim. Importance sampling only with validated state distribution, likelihood weights and independent diagnostics; otherwise unsupported. Annual outputs require seasonal weighting, sampling design and calibration. No claim that time tails derived from median-only measurements.

### 4.6 Fidelity selection and computational strategy

F0 analytic reference, F1 fast terrain, F2 2D wide-angle PE, F3 selective 3D or small-domain independent numerical solver. This is a fidelity ladder, not a path-loss blend. Classifier uses reciprocal path features, Fresnel clearance, normalized roughness, terrain lateral variability, refractivity and angular range, with thresholds derived from preregistered reference-validation data. Use a deterministic symmetric input canonicalization with polarization/reference conventions; test endpoint reversal. For overlap zones compare solver errors against independent reference; disagreement beyond approved tolerance means escalate or no answer. Do not force continuity by smoothing away real interference nulls. Require convergence and reproducibility for same exact inputs; controlled perturbations characterize near-boundary sensitivity. Cache only exact input+state+version keys; vectorize fast kernels. Train optional surrogate on reference solutions within validated support with independent geometry split and error bound; no site IDs, no unrestricted empirical residual model initially. A surrogate cannot improve physical truth beyond its teacher without new evidence.

### 4.7 Calibration, data, and uncertainty

Use a measurement contract: transmitter accepted/reference power, receiver calibration, antenna pattern/height, coordinates, frequency/bandwidth, averaging, timestamps, censoring floor, environmental provenance and uncertainty. Treat uncertain calibration as nuisance effect with independently constrained prior; no correction inferred from same target alone. Censored observation likelihood (for lower-bound loss b, Pr(L>=b)), not imputed loss=b. Campaign/terminal grouped splits; leave-region and leave-band tests; held-out timing blocks. Historical Phase2/OT75-74 and inspected results are development only. New independently managed prospective data required; never access repository lockbox. Report within-domain conditional loss distribution, epistemic uncertainty for quantile, and numerical discretization separately. Calibrate interval coverage on held-out campaigns, not pooled rows. If only a few independent groups, report descriptive not generalization. Never force monotonic loss versus height or frequency where coherent physics allows local reversals.

## 5. Validation contract and staged release gates

All targets below are proposed engineering acceptance criteria to be agreed before outcomes, not established standards. Baselines stock ITM pinned version, 707, P.2001-6 with its official components and reference examples, and applicable P.452/P.526 diagnostics; compare only equivalent statistic/domain. Do not assume repository sibling P.2001 is current. Fair input parity T0 and separate richer-input comparisons. No change to existing evaluator; new prototype benchmark approved separately.

| Gate | Test | Proposed requirement |
|---|---|---|
| G0 | free-space/planar analytic | loss agreement 0.01 dB where well-conditioned; compare complex transfer near nulls using absolute field error |
| G1 | edge/sphere/stratified canonical solutions | 0.25 dB typical target with source reference uncertainty; convergence and no hidden failures |
| G2 | solver tier overlap | 95% of preregistered reference cases within 1 dB, report worst and failures; no automatic extension beyond tested support |
| G3 | numerical invariance | bitwise input roundtrip and repeatability within platform tolerance; reciprocity on symmetric reciprocal media and reference planes; trace near ties |
| G4 | independent median measurements | paired RMSE improvement >=0.5 dB versus best eligible baseline with grouped uncertainty excluding zero; no site/band harm >0.5 dB on prespecified adequately supported strata |
| G5 | annual distribution | calibrated q10/q50/q90 first, pinball loss and interval coverage; q1/q99 only with sufficient independent time events; q0.1/q99.9 separate release |
| G6 | low-loss safety | report signed error, overprediction of loss, conditional tail calibration and worst groups; preagree risk-specific limits, no median-only release as sharing tail model |
| G7 | runtime | target T0 fast tier median <=1 ms/kernel path and p95 <=5 ms on named CPU workload, excluding I/O; report separately end-to-end, fallback frequency, memory and throughput. No promised performance |
| G8 | audit | independent numerical verifier, independent measurement/statistics reviewer, documented reproducible release and limits |

Use paired difference and block resampling with adequate independent campaigns, report uncertainty and multiplicity policy. If independent data insufficient, stop at reference prototype. Negative results valid. Pinball score rho_p(e)=e(p-1[e<0]), e=observed loss−predicted quantile. Use censored scoring/likelihood only with documented observation process. No ad hoc tail exceptions after outcomes.

## 6. Implementation architecture and roadmap

Pure functional kernel independent of GIS IO. Suggested MATLAB reference prototype (existing R2025b environment), portable compiled implementation only after numerical reference passes. Separate packages: schema/units, geometry, material/atmosphere, surface_analytic, diffraction, pe_reference, scatter, state_sampler, channel_combiner, quantiles, diagnostics, validation. Data adapters outside kernel; binaries and data hashes; deterministic seed hierarchy; structured errors. No production edits to current repo. New experimental module only after approval; obey module/repo governance. Pseudocode:

    validate(request)
    scene = build_scene(request)
    for epistemic_scenario in approved_scenarios:
        for state, weight in conditional_states(scene):
            tier = select_validated_fidelity(scene, state)
            surface = solve_surface_once(tier, scene, state)
            channels = add_only_nonoverlapping_validated_channels(surface, state)
            transfer = combine_with_declared_coherence(channels)
            record_loss_and_status(transfer, weight)
        summarize_supported_quantiles()
    return provenance_uncertainty_and_coverage()

Do not discard invalid states and renormalize: report probability mass affected, bound quantiles where possible or mark unsupported.

Milestones: M0 contract and reference cases (2–4 weeks indicative); M1 fast deterministic surface prototype (4–8 weeks); M2 independently verified PE reference and tier selector (8–16 weeks); M3 scatter/clutter and measured median validation (data dependent, months); M4 annual environmental state generator and time quantiles (months to years); M5 scalable implementation and independent validation. Estimates assume small dedicated team and access to approved data; not commitments. Stop/replan after each gate. No tail replacement claim at M1/M2.

## 7. First experiments (proposed, unregistered)

E01 canonical free-space/impedance two-ray complex transfer, null-aware metric, reference-plane and reciprocity checks. Stop on mismatch, no fit.
E02 single-edge, double-edge, smooth sphere and shadow-boundary grid/ULP perturbations; reference P.526 plus independent numerical cases. Use B33/D34c lessons; trace first divergence. Stop if reference uncertainty or convergence dominates.
E03 scalar PE homogeneous and constant-gradient benchmark; compare analytic solution then independent wide-angle/stratified cases; test absorbing boundary and grid. No field data scoring before G1.
E04 paired 2D vs 3D transverse ridge cases with prescribed widths; identify 2D applicability boundaries against converged 3D reference. No proposed empirical bypass coefficient.
E05 state-conditioned channel combination synthetic tests: coherent cancellation, incoherent power, correlated states, quantile ordering, invalid-state mass. Compare analytic finite distributions; reject if quantiles combined incorrectly.
E06 fast solver error/fidelity classifier on held-out synthetic geometries, symmetric features and out-of-domain flags. No site leakage.
E07 independent contemporary measurement design: crossed terrain, frequency, height and regional regimes, survey/calibration, repeated times, independent terminal groups; size from pilot between-group variance and precision target, not row count.
E08 benchmark performance after accuracy gates, named hardware and workloads; compare same precision and domain.
E09 climatology snapshot-to-annual test on independent long-duration links; verify state coverage and time weighting before rare tails.
E10 independently validated scatter-domain transition; check short-angle cases and overlap with surface field; no reusing B19/B29 as proof.

First registration should bundle E01/E05 as inexpensive contract checks, then E02/E03. E04+ require independent reference and compute. No new scored experiments authorized by this proposal.

## 8. Red-team closure and residual risk

R01–R03 resolved in architecture via exclusive surface ownership, state-conditioned composition, separate time/epistemic distributions; empirical joint state model still absent. R04–R08 addressed by bounded fidelity, channel domains and provenance; numerical references not yet run. R09–R12 addressed by scoped surrogate, independent groups and separate tail validation; data not acquired. R13–R15 addressed by binary provenance, cost gate and input tiers; no performance measurement. R16–R20 addressed by prospective test, correct physical limits, ownership ledger and staged release; independent verification outstanding. All are design mitigations, not demonstrated closure. A physically interpretable model may still lose to ITM/P.2001 due to incomplete inputs and uncertain statistics. If a simpler model wins independent tests, retain simpler model. No universal replacement claim until domain-specific evidence.

## 9. Public references and verification status

[1] NTIA ITS ITM official overview https://its.ntia.gov/software/itm/ and https://github.com/NTIA/itm — scope and mechanisms checked.
[2] ITU-R P.2001-6 (09/2025) https://www.itu.int/rec/R-REC-P.2001 — status, applicability and P.2001-5 historical caution checked; [PDF](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I%21%21PDF-E.pdf) introduction checked in extracted text.
[3] P.2001-6 table of contents https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I%21%21TOC-HTM-E.htm — mechanism structure checked. P.2001-4 Attachment J https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-4-202109-S%21%21PDF-E.pdf — earlier mechanism-correlation discussion checked, not assumed current equations.
[4] Research reference leads (not equation-verified this turn): ITU-R P.526 diffraction https://www.itu.int/rec/R-REC-P.526 ; P.453 refractivity https://www.itu.int/rec/R-REC-P.453 ; P.834 refraction https://www.itu.int/rec/R-REC-P.834 ; P.617 scatter https://www.itu.int/rec/R-REC-P.617 ; P.676 gases https://www.itu.int/rec/R-REC-P.676 ; P.838 rain https://www.itu.int/rec/R-REC-P.838 ; P.2108 clutter https://www.itu.int/rec/R-REC-P.2108 ; P.833 vegetation https://www.itu.int/rec/R-REC-P.833 ; P.452 https://www.itu.int/rec/R-REC-P.452 . Verify exact editions, equations and reference test cases before implementation. PE literature search/independent benchmarks required; no selected solver claimed validated.
[5] Repository B33, B34, phase plan rev5 and post-B34 recommendations, internal development context.

## 10. Checks and recommendation

Analytical sanity: two equal coherent amplitudes a produce power 4a² in phase or zero out of phase; incoherent mean 2a². A 10 dB attenuation is 0.1 power and sqrt(0.1) field ratio. The scalar PE sign follows the stated carrier convention. Quantile nonexceedance definition explicit. These are algebraic checks, not executed numerical benchmarks. No independent agent, MATLAB, field validation or tests run. Proposed name, domain, milestones, thresholds and architecture are planner decisions. Human review before external use. Start with reference kernels and state composition, not ML or a full all-domain PE. Build the smallest independently verified model and expand only when evidence supports it.
