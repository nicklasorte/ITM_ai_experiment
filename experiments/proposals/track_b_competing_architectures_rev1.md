# Track B — competing first-principles terrestrial propagation architectures

2026-11-26 | Planner | Snapshot c5edc8014b1c74997509157dd4af21bc678dafe8
Decision: explore multiple architectures before selecting a replacement for ITM or P.2001. Individual-path loss only. Companion: [greenfield PACE proposal](greenfield_propagation_model_rev1.md). PACE is a candidate integration architecture, not the predetermined winner. B35 is registered on the legacy-model track and awaits approval; no R4 measurements inspected. This document registers no executable batch, authorizes no code changes, and makes no performance claim.

## 1. Scientific strategy

Start from Maxwell equations and explicit approximations, not legacy loss equations. First principles do not imply that all environmental constitutive parameters are known or that a deterministic solver can predict annual statistics without data. Separate electromagnetic closure, numerical error, environmental uncertainty and measurement error. Compete on predictive utility at equal input and compute budgets, not complexity or fit to historical data. A simple model that wins is preferred. A reference solver need not be a viable production model. The eight paths below overlap mathematically but differ in representation, computational complexity and unresolved physics. Do not force them into one hybrid before comparison.

Initial common domain: outdoor rural terrestrial paths, 0.1–10 GHz, 3–100 km, terminals 0.5–100 m AGL, both linear polarizations, conditional narrowband transfer with specified geometry/material/refractivity. This is a target, not established validity. Start synthetic at smaller computational domains where reference solutions exist; use nondimensional scaling only when all relevant dimensionless parameters are preserved. Long-term median/time distributions and 20 MHz–50 GHz, 1–1000 km are aspirational. No unsupported extrapolation or automatic low-loss-tail claim. Use SI, e^(-i omega t), passive media with Im(epsilon_complex)>=0 for this convention. For linear isotropic medium, curl E=i omega mu H, curl H=J-i omega epsilon_complex E. Eliminate H to obtain curl(mu^-1 curl E)-omega² epsilon_complex E=i omega J. Specify radiation condition, source, receive functional and boundary conditions. Basic transmission loss is normalized to agreed reference antennas; directional transfer separate. Far-field free-space reference Lfs=20log10(4 pi d/lambda). FSPL is not a universal lower bound.

## 2. Common contract and test harness

Input tiers T0 terrain/climatology, T1 mapped material/corridor, T2 surveyed terminals and contemporaneous fields. Equal-input comparison mandatory; richer-input improvement separate. Each model declares required inputs, supported physics, phase and averaging convention, runtime, memory, numerical convergence, validity and omitted mechanisms. Outputs conditional complex transfer where identifiable, power transfer or conditional distribution otherwise; annual quantiles only after state law validation. Use exact float64 input hashes, geometry/datum/units, environment version and seed. No hidden clamps. Invalid or unsupported outputs retained in coverage denominator; fallback named separately. Independent references not generated solely by competing candidate code.

Common benchmark matrix (proposed):
C01 homogeneous free space, reciprocal antenna references.
C02 PEC and lossy planar ground, Sommerfeld integral reference, null-aware complex error.
C03 single knife edge, rounded edge, double edge, grazing transition; canonical Fresnel and independent numerical reference.
C04 smooth sphere and shadow region; converged independent spherical reference.
C05 homogeneous/constant-gradient/stratified refractivity, duct and mode cutoff; compare analytic modal solution where available.
C06 finite-width ridge and transverse bypass; independent 3D solution at tractable electrical size.
C07 rough surface and random medium with prescribed covariance; ensemble reference, coherent mean and incoherent power separately.
C08 canonical canopy slab with known material/structure, distinguish absorption and scattering.
C09 bistatic volume scattering with known turbulence spectrum; validate angular and energy normalization.
C10 precision, grid, boundary, reciprocity, translation, convergence and exact input roundtrip tests; B33 reported 0.197 dB discrepancy motivates but does not prove a defect.
C11 prospective measured links, independently calibrated and grouped by campaign/terminal; matched input tiers.
C12 runtime and memory scaling versus electrical size, geometry and frequency; report kernel and end-to-end.

Each benchmark includes exact geometry, reference uncertainty, source/license, solver settings, supported outputs, predetermined metric, tolerances and independent verifier. Analytic and numerical references can disagree; resolve before using as teacher. No single solver is universal ground truth. Test cases are frozen before candidate evaluation; separate public development cases and newly generated blind-by-procedure challenge cases. Never use existing repository lockbox. No score/k change.

## 3. Eight candidate research paths (initial ideas and adversarial revisions)

### B1 — Wave-equation marching (PACE surface candidate)

V0: solve scalar Helmholtz with forward parabolic approximation over terrain and atmosphere; wide-angle/3D for difficult paths.
Physics: E=u exp(ik0 x); scalar Helmholtz gives u_xx+2ik0 u_x+u_zz+k0²(n²-1)u=0 in 2D. Dropping u_xx gives narrow-angle PE. Split-step Fourier or finite difference, impedance boundary, terrain-following or staircase with convergence. Wide-angle square-root operator approximated by Padé; derive sign/branch and stability. Use vector/polarization extensions only after scalar verification.
Hypothesis: wave representation handles shadow, refraction and interference more consistently than independent empirical mechanism curves.
Red team: one-way approximation misses backscatter; terrain staircasing and absorbing boundary artifacts; scalar polarization; 2D ignores lateral bypass; launch/receive normalization and curvature double counting; cost grows with frequency and domain. A perfect conditional field is not a median.
V1: independent scalar reference first; C01/C02/C05 then C03/C04; narrow-angle domain explicit; 2D/3D comparison C06, no generalization from small domains. Curvature once. Verify grid and boundary convergence and absolute field error near nulls. Candidate for conditional surface transfer, not full replacement until scatter/time validated.
Kill: cannot meet convergence/normalization on canonical cases or runtime cannot meet reference role budget. Keep as reference only if accurate but slow.
Resources: MATLAB FFT/sparse linear algebra; later optimized implementation. Source leads: Tappert PE, Levy Parabolic Equation Methods for Electromagnetic Wave Propagation (2000), ITU-R P.834.

### B2 — Geometrical optics and uniform diffraction

V0: trace 3D direct, reflected, refracted and diffracted rays; sum fields.
Physics: eikonal |grad S|²=n², transport div(A² grad S)=0 for scalar lossless ray away from caustics; phase k0 S. Fresnel boundary, uniform geometrical theory of diffraction (UTD) transition functions, ray tubes and material attenuation. Multiple reflections only with controlled truncation.
Hypothesis: high-frequency asymptotic representation provides fast engineering predictions and interpretable paths.
Red team: rays diverge at caustics, disappear in deep shadow, miss creeping waves, repeated paths double count, search incomplete, rough surfaces not specular, coherent phase unknowable at DEM accuracy. Low frequencies violate high-frequency assumptions.
V1: restrict to validated electrical size/curvature and angle domains; uniform transition kernels and smooth sphere benchmark; explicit ray completeness/error diagnostics; compare phase only when geometry supports it, otherwise average under documented phase distribution. No summing UTD and another total diffraction model. C01–C04, C06. Use C02 exact integral reference for near-ground limitations.
Kill: discontinuity or missed dominant path under preregistered geometry perturbations; if 3D search cost exceeds budget, retain 2D/limited ray candidate only.
Resources: computational geometry, ray tracing, UTD source verification (Kouyoumjian and Pathak 1974).

### B3 — Surface integral / boundary-element electromagnetic model

V0: solve terrain interactions from equivalent surface currents using Green functions rather than marching.
Physics: boundary integral formulation of Maxwell with outgoing Green kernel exp(ikr)/(4 pi r) in homogeneous background, surface equivalent currents and impedance or dielectric interface. Full vector reference on finite domains; fast multipole or hierarchical matrix acceleration only after dense reference.
Hypothesis: independent full-wave reference can resolve backscatter, rounded edges and transverse terrain, exposing approximations in B1/B2.
Red team: dense matrix O(N²) storage and naive solve O(N³), mesh resolution tied to wavelength, enormous electrical size of real terrain, truncation of infinite ground, ill-conditioning/internal resonances, impedance approximation, heterogeneous atmosphere invalidates simple Green kernel. Cannot promise 100 km full-wave simulation.
V1: reference-only initial role; finite canonical objects, planar half-space Green function or documented truncation, mesh refinement and independent analytic checks. C02/C03/C06/C08. Scale via dimensionless similarity only with matching material and geometry parameters. Use combined-field or appropriate formulation to address resonance after source verification. No production candidate until cost evidence.
Kill: independent convergence fails or reference uncertainty larger than model differences. Never extrapolate small-domain accuracy to real paths.
Resources: verified open-source BEM/FEM reference subject to license and availability; numerical EM specialist. Source leads: Harrington Field Computation by Moment Methods; Chew Waves and Fields in Inhomogeneous Media.

### B4 — Modal and spectral propagation

V0: expand field in vertical eigenmodes of stratified atmosphere/ground; propagate modal amplitudes.
Physics: scalar stratified Helmholtz with E=phi(z)exp(i beta x), phi''+[k0² n(z)²-beta²]phi=0, impedance boundary and outgoing/decaying conditions. Discrete guided modes plus radiation continuum; range-dependent coupled modes where adiabatic assumption fails.
Hypothesis: ducting, surface waves and long-distance refractive channels can be represented compactly without dense PE grids.
Red team: range-independent assumption breaks over terrain, leaky modes and continuum omitted, nonorthogonal lossy modes, mode cutoff singularities, incomplete eigenbasis, poor representation of sharp terrain, climatological ducts unknown.
V1: stratified canonical C05/C02 reference first; include radiation continuum or explicitly bound omission; compare transfer with B1 and analytic slab/half-space cases; coupled-mode extension only if validated. Treat as specialized candidate for stratified/coastal paths, not universal terrain model. No annual duct frequency without observations.
Kill: modal truncation cannot converge or mode transitions unstable; retain analytic benchmark role if useful.
Resources: eigenvalue solvers, quadrature; waveguide theory, Sommerfeld integrals, P.834 reference leads.

### B5 — Radiative transfer and scattering transport

V0: solve directional electromagnetic energy transport through turbulent atmosphere and vegetation.
Physics: stationary transport s_hat dot grad I = -kappa_ext I + integral kappa_s(s',s) I(s') dOmega' + Q, where I is directional intensity, extinction inverse length, scattering kernel inverse length per steradian, and integral of kernel constrained by scattering coefficient. Absorption nonnegative; scattering conserves energy in closed nonabsorbing medium. Polarized extension uses Stokes vector and phase matrix.
Hypothesis: statistically averaged diffuse/scatter power is more physical than fixed empirical scatter/clutter terms.
Red team: intensity equation loses phase and interference; transport assumptions fail for correlated coherent structures, turbulence spectrum and canopy parameters unavailable, small-angle scattering double counts coherent refractive field, normalization to receiver aperture difficult, expensive angular quadrature.
V1: separate coherent field from diffuse power using explicitly derived closure, not arbitrary addition. Validate single scattering C09, slab C08 and conservation; restrict to ensemble/bandwidth averaging that removes coherence. Compare to measured scatter/vegetation only with material and environmental provenance. No standalone coherent median model.
Kill: energy normalization or independent scattering reference fails, or parameter uncertainty dominates signal. Retain only validated diffuse mechanism.
Resources: deterministic discrete ordinates or Monte Carlo transport; Chandrasekhar Radiative Transfer; Ishimaru Wave Propagation and Scattering in Random Media; P.617/P.833 as baselines, not governing equations.

### B6 — Stochastic wave / random-medium model

V0: solve wave equation across realizations of unresolved terrain, material and refractivity, estimate conditional loss distribution.
Physics: n(x,z,t)=n_bar+delta n with documented covariance/spectrum and boundary perturbations; solve B1 or independent reference for each realization. Conditional ensemble distribution of G=|H|²; separate epistemic scenarios from aleatory states. Weak fluctuation approximations (Rytov/Born) only within verified regimes.
Hypothesis: model distributions from physical randomness rather than fixed time-variability curves.
Red team: covariance nonidentifiable from sparse loss data; arbitrary random fields generate arbitrary tails; correlated temporal states, strong scattering invalidates weak approximation, expensive nested simulation; geometry uncertainty not time variability; cannot infer annual distributions from synthetic random draws.
V1: C07 with known synthetic random law and independent ensemble solution; compare coherent mean, variance and quantiles with convergence; then independently observed environmental state distributions. Separate snapshot conditional ensemble from annual time weighting. Report effective independent events, no rare-tail claim from raw sample count. Use common random numbers for candidate comparisons, independent seeds for verification.
Kill: state law cannot be identified or validated, or conditional distributions fail calibration. Retain uncertainty sensitivity only, not annual prediction.
Resources: random-field simulation, uncertainty quantification, atmospheric observations. Source leads: Tatarskii wave propagation in turbulent medium, Ishimaru, P.453.

### B7 — Reduced-order physics / asymptotic engineering model

V0: derive compact equations from nondimensional wave physics and canonical solutions, not ITM fit.
Physics: use dimensionless Fresnel clearance nu=h sqrt(2(d1+d2)/(lambda d1 d2)), electrical roughness k sigma_h, normalized curvature and impedance, slope/angle and lateral-width ratios. Derive asymptotic limits, matched approximations or reduced basis from verified reference solutions. No universal additive dB terms; preserve appropriate transfer normalization and reciprocal invariants.
Hypothesis: small interpretable kernel can match high-fidelity reference within engineering tolerance at orders-of-magnitude lower cost.
Red team: dimensionless descriptors discard terrain ordering and phase, nonunique mapping from descriptors to loss, fitted transition constants hide empirical bias, training on reference inherits reference error, overfitting synthetic geometry.
V1: begin with one canonical class (single/rounded edge or smooth sphere), prove limiting behavior and quantify approximation error; compare two profiles with identical descriptors but different ordering as adversarial collision test. Add features only if physically justified and independent reference improves. C01–C04/C10. Hold-out geometry families, not random rows. Do not force one universal equation; abstain outside support.
Kill: descriptor collisions exceed error budget or no compact model meets reference accuracy. Retain full geometry solver instead.
Resources: asymptotics, approximation theory, reduced-basis/SVD, dimensional analysis. Source leads: P.526 canonical reference, Keller GTD, uniform asymptotic literature.

### B8 — Scientific machine learning / neural operators

V0: learn mapping from geometry/material/refractivity fields to electromagnetic transfer, constrained by PDE.
Physics: train operator approximating verified B1/B3 solutions; complex field or power target with normalization, PDE/boundary residual where meaningful. Fourier neural operator, DeepONet or reduced-basis surrogate alternatives. No direct ITM-label imitation.
Hypothesis: amortized numerical solution can provide fast transfer prediction for repeated geometry classes.
Red team: PDE residual not proof of correct solution, spectral bias misses high-frequency oscillations/nulls, OOD terrain/weather, data generation cost, reference bias, architecture overkill, nonphysical reciprocity/energy, poor rare-tail generalization.
V1: defer until teacher verified; compete against B7 and interpolation baseline at same reference training budget; geometry-family and frequency-block splits, exact input tier, no site IDs, uncertainty/OOD abstention. Predict conditional transfer only; no direct annual tail or measured residual fit initially. Test C01/C02/C03/C05/C10 and C12. Report training cost and break-even number of predictions. Reciprocity by construction where valid, test independently.
Kill: no meaningful accuracy/runtime Pareto improvement over B7/interpolation or unreliable OOD coverage. No neural model solely for novelty.
Resources: approved compute and reference dataset; Li et al. Fourier Neural Operator (2021), Lu et al. DeepONet (2021) as research leads, not validated propagation implementations.

## 4. Cross-cutting red team and program revisions

| Objection | Revision / release condition |
|---|---|
| Eight tracks duplicate work | shared contract and canonical cases; B3 reference, B5/B6 specialized, B8 deferred; only B1/B2/B7 initial engineering competitors |
| All derive from Maxwell but closures differ | publish approximation and mechanism ownership ledger; no automatic physical correctness |
| Reference solvers share same defect | analytic plus independent discretization and implementation; source verification |
| Conditional transfer mislabeled median | separate API and validated environmental/measurement averaging |
| Data-rich model unfairly wins | compare T0 equal inputs, T1/T2 incremental value and availability |
| Unsupported outputs excluded to improve score | fixed denominator, coverage and failure metrics; compare common support plus all-request utility |
| Low-loss tails unsafe | independent long-duration observations, event dependence, tail-specific calibration and release |
| Phase impossible with terrain uncertainty | propagate epistemic phase uncertainty, use documented power averaging; no exact phase claim |
| Numerical continuity misapplied | distinguish physical nulls from representation-dependent branch jumps; complex absolute error near null |
| Model selection overfits challenge cases | frozen development/challenge split, new prospective test, no existing lockbox |
| Correlated measurements treated as independent | campaign/terminal grouping, censor likelihood, independent groups and uncertainty |
| Cost measured on tiny examples | electrical-size scaling, named hardware, full workload, I/O and fallback |
| Architecture selection arbitrary | Pareto gates, no weighted score chosen after results; simpler wins |
| Greenfield program conflicts with existing repo | proposals only now; explicit owner approval for new module and benchmark; no changes to legacy track |
| Source literature not checked | verify exact editions/equations/benchmarks before registration; no claim of novelty |
| No independent red team | label self-adversarial review; separate EM, statistics and numerical reviewers before implementation release |

## 5. Portfolio and decision gates

Initial resource allocation (planner recommendation, not budget commitment): B1 30%, B2 25%, B7 25%, B3/B4 reference 20%; B5/B6 later after conditional surface validation, B8 after teacher and data. Percentages sum 100. Do not fund eight full production implementations. Reference roles evaluated on accuracy/convergence, not production speed. 
Phase 0: common contract, independent analytic references C01/C02, synthetic geometry generator and exact serialization. Register separately.
Phase 1: B1/B2/B7 minimal prototypes on C01–C04, B3/B4 small reference cases. No measured fitting. Stop failing candidates early.
Phase 2: C05/C06/C10, independent challenge geometries and numerical cost scaling. Select nondominated engineering candidates, retain reference tools. No hybrid until evidence shows complementary domain strengths.
Phase 3: C11 prospective median measurement pilot; B5/B6 only for observed missing mechanisms, B8 only after teacher passes. Separate conditional/annual validation.
Phase 4: C09/C07/C08 and long-duration state calibration; time quantiles and tail release only if supported.
Phase 5: optimized implementation, independent verification and documentation. Replacement decision per domain, not all-or-nothing.

Proposed preregistration gates: analytic loss agreement <=0.01 dB well-conditioned, complex absolute error near null with normalization-specific threshold; canonical numerical reference <=0.25 dB typical target subject to reference uncertainty and convergence; 95% of held-out reference cases <=1 dB with worst cases and coverage reported; prospective median paired RMSE improvement >=0.5 dB versus best eligible baseline with grouped uncertainty excluding zero and prespecified adequately supported strata no >0.5 dB harm. These are planner thresholds, not standards. Define exact statistical estimands, sample size, multiplicity and failure handling before runs. If no model meets gates, report negative result. Runtime aspirational fast tier median <=1 ms and p95 <=5 ms per kernel path on named CPU, plus end-to-end and reference solver cost; not required of reference-only tools. Report Pareto front across accuracy, coverage, compute, input availability and calibration. No averaging away unsafe strata.

## 6. First proposed work packages (not registered)

TB0: shared schema and analytic test oracle, free-space/planar cases, complex transfer normalization, coherent/incoherent composition, exact roundtrip and synthetic null tests. Independent analytic derivation and test reviewer.
TB1: three-way shootout B1/B2/B7 on single edge and smooth ground; same geometry, materials and reference; B3 small independent benchmark. Preregister electrical-size range and grid convergence; no training on challenge cases.
TB2: stratified atmosphere B1/B4, mode cutoff and duct reference, no annual claims.
TB3: transverse ridge B1/B2/B3, compare 2D and 3D and descriptor collisions.
TB4: random-medium/scatter B5/B6 conditional distributions, known synthetic state law first.
TB5: B8 surrogate vs B7 and interpolation after teacher verification.
TB6: prospective measurement and independent validation protocol, no acquisition or lockbox access without approval.

Each package has a planner, worker and independent reviewer; proposed roles EM theorist, numerical analyst, atmospheric scientist, measurement engineer, statistician and adversarial reviewer. No simulated independent agents. Repository module proposal under experiments/ only after owner approval; legacy evaluator untouched. MATLAB reference prototype where available, Python analytic/test harness feasible without Mac, compiled optimization later. No new branch or experiment in this turn.

## 7. Source register and verification status

Foundational research leads, not freshly retrieved or equation-verified in this turn: Maxwell equations and scalar Helmholtz derivations above; J. B. Keller, Geometrical Theory of Diffraction (1962); Kouyoumjian and Pathak, A uniform geometrical theory of diffraction for an edge in a perfectly conducting surface (1974); M. Levy, Parabolic Equation Methods for Electromagnetic Wave Propagation (2000); R. Harrington, Field Computation by Moment Methods; W. C. Chew, Waves and Fields in Inhomogeneous Media; S. Chandrasekhar, Radiative Transfer; A. Ishimaru, Wave Propagation and Scattering in Random Media; V. Tatarskii, wave propagation in turbulent media; Li et al., Fourier Neural Operator for Parametric Partial Differential Equations (2021); Lu et al., Learning nonlinear operators via DeepONet (2021). Verify bibliographic details, editions, licensing and exact formulas before implementation. Public baseline links: https://github.com/NTIA/itm ; https://www.itu.int/rec/R-REC-P.2001 ; https://www.itu.int/rec/R-REC-P.526 ; https://www.itu.int/rec/R-REC-P.834 ; https://www.itu.int/rec/R-REC-P.453 ; https://www.itu.int/rec/R-REC-P.617 ; https://www.itu.int/rec/R-REC-P.833 . Prior PACE proposal contains baseline context; do not treat prior unverified citations as checked. No fresh literature search or numerical benchmark performed in this turn.

## 8. Final recommendation and checks

Do not choose a winner now. Build TB0 then compare B1/B2/B7 under identical conditions, with B3/B4 as independent reference roles. B5/B6 address unresolved statistical physics; B8 is an optional acceleration layer, not the starting point. If a hybrid emerges, mechanism ownership and fidelity selection must be demonstrated, not assumed. Algebraic checks: Maxwell curl signs consistent with e^(-i omega t); PE reduction follows dropping u_xx; transport coefficients inverse length; Fresnel parameter dimensionless; allocation totals 100%. These are self-checks, not executed benchmarks. Self-adversarial review only; independent review and human approval before external use. Scope, rankings, budgets and thresholds are planner choices. No model code, frozen inputs, scores or lockbox touched. 
