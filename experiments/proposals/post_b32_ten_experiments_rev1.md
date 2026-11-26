# Ten new ITM research experiments after B32

Planner proposal, 2026-11-26. Snapshot [f233546](https://github.com/nicklasorte/ITM_ai_experiment/tree/f2335462dd678b90757e30c4f448ed045db1c40c). Not a batch registration or authorization to run. Parent 707, evaluated as 707r-rescore-screen36. Follow CLAUDE.md, FRAMEWORK.md and program.md; no lockbox examination, no changes to frozen data/evaluator, no production code or scored runs in this delivery.

## Evidence and strategy

Read B21, B23–B32, phase plan rev 5, LOG, archive, headroom map, data proposal and previous N01–N10 headings; earlier experiment history remains binding. B23/B24 contrasts are inconclusive; B25 spherical reference fails headroom and does not remove the R1 inversion; B26 closes reflection for that target; B27 M1 bracket fails (707 +5.64 dB and stock +10.43 dB on R1 blocked height pairs, bracket share 0.10). B29 scores three candidates, zero keeps, k=9: two groups effectively inactive; time scales screened gain 0.11 dB, lo995 -0.06 dB. B30 vegetation proxy fails registered cross-site rule; only R2 has resolved negative slope, pooled slope-only improvement 0.26 dB in sample; modern canopy is not historical canopy. B31 digitized 210 paths; B32 C_hi 3–10 m contrasts on 130 pairs, no stratum favors 707, one favors stock, outcome C. 0.35 m TX is outside official ITM domain; both models used 0.5 m and low-height contrast is descriptive. B32 follow-up varied receiver height only; transmitter-offset sensitivity and season-paired analysis remain undone. No claim that B32 disproves 707's overall value.

The next portfolio attacks input uncertainty, physical identifiability and independent measurements instead of searching more constants. Headroom on existing inputs is limited; rev 5's perfect cell-mean fix is only 1.13 dB screened (9.91 to 8.78); this is not a universal irreducible-error bound. Do not reopen B21, B25, M1, B29 or B30 merely because another formulation sounds plausible. No proposed item duplicates N01–N10: new cards are narrower interventions or new estimands, not another grid-phase, height/frequency contrast, ground impedance, transverse bypass or generic field campaign. Some extend earlier work; explicitly labeled.

## Ranked portfolio

| Rank | ID | Study | Type | Cost | Prior |
|---|---|---|---|---|---|
| 1 | X01 | Season-paired loss and height interaction | stored data | low | high information |
| 2 | X02 | Geolocation uncertainty propagation | model-only | medium | high information |
| 3 | X03 | Joint transmitter clamp sensitivity | model-only | low | medium |
| 4 | X04 | Historical sensor area-mode comparison | independent diagnostic | medium | medium |
| 5 | X05 | Local foreground resolution benchmark | new input, conditional | medium | medium |
| 6 | X06 | Quantile width versus seasonal median mixture | stored data diagnostic | low | medium |
| 7 | X07 | Ground/surface datum consistency | new input audit | medium | medium |
| 8 | X08 | Finite ground-screen and antenna coupling | reference experiment | high | conditional |
| 9 | X09 | Atmospheric absorption residual fingerprint | source-gated diagnostic | medium | low |
| 10 | X10 | Matched-path refractivity-profile sensitivity | source-gated diagnostic | medium/high | conditional |

Prior means qualitative value of information, not probability of passing a score gate.

## Shared protocol

Register each diagnostic in a new BNN file only after checking live IDs and approvals. Pin current model, raw archives, source hashes and settings; reproduce 707 stored predictions to 1e-9 dB when full-precision inputs are identical, or document serialization tolerance before seeing outcomes (D32 CSV parity 3e-7 dB). Use same support for all comparisons, link keys not row order. No lockbox files, including Tier B Phase 1, low antenna set and DBSG3; verify new measurement identity against published exclusion names without opening protected files. D31/D32 are now inspected research data, not fresh holdout. Source licensing/availability and acquisition require approval. No fitted constants, post hoc site gates, or score changes. Any candidate requires sourced formula/domain, analytical and reference reproduction, physics checks, headroom screen including site/censor constraints, and separate registration. Next k is 10 if parent/count unchanged; verify live count and supported bootstrap confidence resolution, do not invent a quantile. Apply current FRAMEWORK gates and complexity penalty. All suggested diagnostic 1 dB thresholds are planning resolutions not score rules. Report uncertainty, coverage, null findings, failed checks, exact versions and no-run exclusions.

Use physical path/terminal clusters, not rows, for 2,000 paired bootstrap draws (seed 20261126); show site-level effects and leave-one-terminal-out where possible. Shared terminals/seasons imply dependence; conditional intervals do not establish generalization. Minimum 10 bases per reported deciding stratum and two distinct terminal groups where feasible; otherwise descriptive. Require a directional interval and effect ≥1 dB for a provisional material dB signal, not proof. For new data register calibration and geometry uncertainty first. All signs use predicted minus measured unless specified.

## X01 — Season-paired loss and height interaction

**Hypothesis:** static terrain and antenna height cannot account for season-dependent attenuation on unchanged paths; changing median may alias height response. B32 explicitly left season pairing undone. Unlike B30, no modern vegetation proxy is used.

**Method:** use OT 75-74 Tables 8/9 and 10/11 from D31, confirm season labels, unchanged terminal identity, distance, frequency, hardware and height from original report. Within each physical path define S(h,f)=L_season2(h,f)-L_season1(h,f); interaction J=S(3m,f)-S(10m,f). Also report S at 0.35 m as measured only, no model extrapolation. Freeze common detected, unflagged support, report bounds separately. Preserve season pairing in resampling; separate Graham and Hunter Liggett and frequency. Static model predicts zero seasonal contrast when inputs identical; verify, do not treat changed configuration as season. Compare J and S to documented repeatability/calibration, not to presumed foliage sign.

**Prediction:** some nonzero S; J may differ by frequency but no directional claim until season definitions checked. **Falsifier:** intervals consistent with zero within 1 dB resolution or calibration explains differences; if hardware/season metadata inadequate mark not identifiable. No vegetation correction from these already-inspected data. Output season_pairs_rev1.csv, cluster_summary_rev1.csv, provenance, summary. Source OT 75-74 and P.833-10 §2.1 seasonal context (not a numerical correction).

## X02 — Geolocation uncertainty propagation

**Hypothesis:** B31 map-derived positions can change terrain obstruction enough to confound B32 model differences. Distinct from N06 sub-grid sampling: physical endpoints move within independently justified uncertainty.

**Method:** reconstruct map scale/graticule and tabulated-distance constraints, preserve shared terminal positions and distance rounding intervals. Use map-only and adjusted solutions, explicitly enumerate T7a/b ambiguity and underdetermined R5; construct feasible coordinate sets from documented map error, not residuals. Prioritize all B32 deciding paths; draw reproducible joint terminal perturbations (start 128 feasible draws, double to 256 for convergence; if no probability model, treat as scenario envelope not Monte Carlo confidence). Sample terrain with same source/resolution, recompute profile distance, clearance, horizon, C_hi for both models; do not reselect paths on loss. Hold TX clamp and other inputs fixed. Distinguish geometry uncertainty from DEM error. Compare differences in paired absolute contrast errors to original B32.

**Prediction:** ambiguous locations and near-grazing paths show wider envelopes. **Stop:** if all supported scenarios preserve stratum decision and shift paired contrast MAE <1 dB, deprioritize location as explanation; if signs flip, qualify B32 but do not reverse registration. No feasible bounds means report unknown. Costs: fresh profile access/MATLAB approval. Output terminal_scenarios, geometry_checks, contrast_envelopes. Source B31 map reconstruction and NTIA ITM PFL definition.

## X03 — Joint low-transmitter height sensitivity

**Hypothesis:** B32's 0.5 m transmitter clamp affects C_hi differently from a receiver-only clamp because foreground geometry interacts with both ends. No run below official 0.5 m bound.

**Method:** B32 same paths, frequencies and 3/10 m receivers, TX height 0.5, 0.7, 1.0 m; also 0.5, 0.7, 1.0 m RX cells as secondary reproducing prior follow-up. Compute C_hi(t)=L(t,3)-L(t,10); finite mixed difference C_hi(t)-C_hi(0.5) and model difference. Use no extrapolation to 0.35 m for decisions; optional slope extrapolation labeled unsupported model sensitivity, not bound. Split by measured foreground type from report, not residual sign. Check reciprocity on synthetic metadata-free cases and parity at 0.5 m. Distinct from D32 receiver sweep and N03 observational contrast.

**Prediction:** modest or heterogeneous interaction; no justified inference below 0.5 m. **Stop:** changes <1 dB for 90% of deciding paths across supported heights diminish concern within that domain only. Larger changes motivate a separate low-height reference, not loosening ITM validation. Output factorial_height_rev1.csv and sensitivity summary. Source official NTIA/itm input bounds, B32 §6b.

## X04 — Historical area-mode comparator

**Hypothesis:** the area-mode short-path interpolation may outperform P2P for sensor-path variability where terminal foreground is undersampled. OT 75-74 conclusions explicitly discuss area mode for low antennas. This is a comparator, not another diffraction kernel.

**Method:** source-check historical Longley-Rice area-mode method and its parameter definitions, reproduce a published example first. Use pinned stock ITM area mode at supported heights, with documented siting criteria and independently computed terrain irregularity (not fit to loss). Compare P2P stock and 707 at same distance, effective time/location/situation definitions and C_hi support. Area prediction is a population statistic; do not interpret an area median as exact point-specific loss. Where appropriate compare distribution quantiles across same length/terrain cohorts rather than individual residual. Report both area and P2P predictions; use no score gate.

**Prediction:** area comparator may improve population median in flat low-antenna settings but lose path discrimination. **Falsifier:** no improvement in population contrast or incompatible statistic/siting definitions; close rather than optimize siting class. No change to 707. Output area_reference_checks, matched_population_summary. Source OT 75-74 conclusions; NTIA/itm area-mode input definitions; historical implementation identity must be checked.

## X05 — Terminal foreground microtopography

**Hypothesis:** bare-earth terrain within the immediate antenna foreground, unresolved by 30 m sampling, changes low-height diffraction and explains a portion of sensor-path scatter. Unlike N06 synthetic grid phase and B30 canopy height, test actual fine terrain with fixed surveyed endpoints.

**Method:** obtain approved high-resolution bare-earth lidar DTM for a new contemporary measurement cohort with known terminal coordinates and AGL reference; historical B32 may be a sensitivity-only pilot if positional uncertainty smaller than foreground feature scale. Compare native DTM to coarsened same-source 30 m representation (not different epoch/product). Use uniform grids at native and coarsened spacing; do not splice PFL nonuniformly. Separate endpoint elevation changes from interior foreground changes via controlled diagnostic copies with same absolute antenna elevation; document any invalid effective height and stop. Compute first-Fresnel blockage and matched loss deltas; no new model formula. Validate against surveyed profile or independent elevations. Assess whole path and first/last Fresnel-zone-relevant segment using a rule fixed from geometry.

**Prediction:** largest sensitivity at low antennas/near-grazing paths; modern terrain is not historical truth. **Gate:** new DTM must show consistent independently measured geometry improvement and material paired accuracy improvement on ≥2 terminal groups; otherwise close. No data acquisition authorized here. Output provenance and profile comparison, coverage/error table. Source USGS 3DEP product specifications (verify edition), ITM PFL requirements, OT 75-74 conclusions.

## X06 — Seasonal mixing versus within-season time variability

**Hypothesis:** a broad pooled time distribution can arise from median shifts between regimes rather than heavier within-regime tails; changing ITM time scales globally (B29) cannot distinguish them. Different from N08 competition between propagation mechanisms.

**Method:** OT 75-74 10/50/90% values, paired seasons with identical configs; verify quantile order, definitions, sample duration, and censor flags. Define W=L90-L10, skew contrast K=L90+L10-2L50 and median shift S. Compute seasonal differences of W and K, use matched clusters and compare within-season widths with |S|. Quantiles alone cannot identify pooled CDF: do not average quantiles or construct a purported observed mixture. If raw timestamps are available from a separately approved new non-lockbox campaign, compare empirical pooled CDF with duration-weighted mixture F(x)=sum w_s F_s(x); leave season out for predictive assessment. Synthetic two-state distributions test code only.

**Prediction:** median shifts may be comparable to within-season width in some cohorts; not a claim about annual distributions. **Stop:** no resolved shifts or season definition/coverage inadequate; no time-scale candidate. Output quantile_pairs, width_skew_report, optional empirical mixture validation. Source OT 75-74 measurement discussion; B29.

## X07 — Terrain vertical datum and antenna reference audit

**Hypothesis:** inconsistent endpoint height reference or mixing DSM and bare-earth DTM can produce artificial clearance errors. Unlike X05, test metadata/reference system rather than spatial resolution, particularly long-term modern profile sources.

**Method:** enumerate development profile source/product, vertical datum, ellipsoidal vs orthometric convention, surface vs bare-earth semantics, survey AGL reference and geoid conversion availability. Reconcile endpoint heights with independently documented station survey where available. Synthetic invariance: common constant elevation offset should leave geometric clearance invariant; full ITM may change because sea-level refractivity is reduced using elevation, so isolate that path and predict change from source before testing. Source-verified conversion only, never subtract a guessed canopy. Compare identical-location alternate representations in diagnostic copies, no frozen replacements; report terrain-only and refractivity effects.

**Prediction:** mixed reference errors localized rather than a global offset. **Stop:** no documented mismatch or no independent reference, no adjustment. If verified mismatches and material impacts, prepare data correction proposal for owner review; no candidate credit for changed inputs. Output datum_manifest, invariance_checks, discrepancy ledger. Source USGS 3DEP and Copernicus DEM product handbooks (specific versions and equations TODO), pinned ITM refractivity initialization.

## X08 — Low-antenna installation and finite ground-screen reference

**Hypothesis:** nominal basic loss estimates for near-ground antennas may include install-dependent radiation/coupling effects not captured by antenna height alone. Distinct from N07 planar Fresnel reflection: antenna current distribution and finite ground-screen geometry.

**Method:** recover historical antenna design, gain calibration, mounting, orientation, ground-screen dimensions and soil description from OT 75-74 appendices; if unknown no retrospective correction. Build a separate full-wave method-of-moments benchmark (published NEC formulation or independently verified solver), finite wire/ground screen over specified homogeneous lossy halfspace; verify mesh convergence, free-space pattern, reciprocity and accepted/radiated power balance. At 172.5/410.5 MHz sweep supported source-defined dimensions from documented installation; a numerical 0.35 m antenna geometry is allowed in Maxwell solver, not ITM. Compare realized gain versus elevation under consistent normalization; separate propagation from antenna mismatch to prevent double counting. Validate first against independent measured antenna pattern, not path-loss residual.

**Prediction:** installation changes can affect apparent height contrasts; direction not known. **Stop:** missing geometry or no verified solver/antenna benchmark; no correction to historic basic loss. New measurement approval required. Output solver settings, convergence, gain patterns, uncertainty. Source OT 75-74 antenna appendix (details TODO); NEC documentation source lead requiring verification.

## X09 — Atmospheric gaseous absorption fingerprint

**Hypothesis:** frequency- and distance-dependent absorption can contribute to high-frequency residuals on sufficiently long paths; cannot explain a general site offset. Distinct from B23 frequency contrast and P.617 scatter changes.

**Method:** audit whether measured basic loss and current variants/reference models include gaseous absorption. Source-check ITU-R P.676 current version, equations, units and domain; calculate diagnostic gamma_o+gamma_w (dB/km) for specified documented pressure/temperature/humidity and path integration consistent with propagation regime. Start with clear terrestrial paths only; do not apply surface gas attenuation blindly to scatter or high-altitude segments. Use independently documented atmospheric climatology, no fit; evaluate paired high/low frequencies with same geometry and calibrated support; compare upper plausible physical absorption to residual difference and headroom. If measurements/inputs inadequate, synthetic domain screen only. No blanket correction to 707.

**Prediction:** small at most Phase 2 distances/frequencies below 10 GHz; likely cannot pass score headroom. **Stop:** physically bounded maximum contribution insufficient for 1 dB on relevant support or headroom CANNOT_PASS; no candidate. Output source_domain_checks, absorption_envelope, residual comparison. Source ITU-R P.676 official recommendation (equation-level verification TODO). Low priority negative-control mechanism.

## X10 — Matched-path refractivity-profile sensitivity

**Hypothesis:** vertical refractivity structure can change individual terrestrial path loss in ways not captured by ITM's effective curvature and surface refractivity. This is not a repeat of B14's climatological refractivity input substitution or B29's time-spread calibration: the target is the error from reducing a measured vertical profile to scalar inputs.

**Method:** source-check B14 and the earlier scatter and variability experiments before registration. Use a new approved non-lockbox measurement campaign with individual calibrated path-loss observations, timestamps, antenna geometry and representative contemporaneous atmospheric soundings. First reproduce a published stratified-atmosphere reference case with a validated two-dimensional parabolic-equation solver, including homogeneous atmosphere and constant-gradient controls. Use identical terrain, frequency, polarization and boundary assumptions for a full measured refractivity profile and its source-defined constant-gradient approximation. Compare their predicted loss difference with stock ITM and 707 residuals on the same individual paths. Separate solver differences from the atmospheric intervention using the within-solver contrast. Verify grid/domain convergence, atmospheric profile representativeness, and consistent antenna normalization; do not infer ducting from surface refractivity alone. Restrict to solver-valid forward-propagation geometry; no extrapolation to unsupported scatter regimes.

**Prediction:** material sensitivity on some long, low-elevation paths under strong vertical gradients, little sensitivity under near-standard conditions. **Falsifier:** no material within-solver effect, no reproducible improvement on independent terminal groups, or atmospheric uncertainty exceeds the predicted effect. Require at least 1 dB paired improvement with a directional cluster interval on two independent terminal groups for further investigation; this is a diagnostic threshold, not a score gate. If suitable contemporaneous measurements are unavailable, stop at synthetic reference validation. No new fitted parameters or production changes. Output atmospheric_provenance, solver_reference_checks, paired_path_loss and uncertainty report. Source leads: ITU-R P.453 (radio refractive index), P.834 (tropospheric refraction), and published parabolic-equation benchmark literature; exact versions, equations and solver applicability require verification before execution.

## Execution sequence and decision gates

Package F: X01, X06 from existing D31 data; run in one metadata-first registration with common seasonal support but distinct estimands. X03 next on Mac, no new data. Package G: X02 after geolocation bounds and profile access approved; X04 after reference reproduction. Package H: X05 and X07 require independent input provenance/approval; X08 requires solver/install reference, X09 requires source domain and leverage screen, X10 requires individual path measurements with contemporaneous atmospheric profiles. Do not run all ten merely to fill a quota. If F yields no informative contrasts and G shows robustness, stop historical low-height mining. If a new mechanism is sourced and can pass headroom, register a single candidate, not a parameter sweep. All ten remain proposals.

## Public source register and verification

Inspected official NTIA [OT Report 75-74](https://www.its.ntia.gov/publications/download/OT-75-74.pdf) search extract (conclusions, printed p.72): short low-height paths show large location variability, foreground obstacles matter, area mode and forest attenuation discussed. Original table/appendix details must be checked before execution. [NTIA ITM](https://github.com/NTIA/itm) official README search extract confirms 0.5–3000 m structural heights, 20–20000 MHz, PFL and area input definitions. [ITU-R P.833-10](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.833-10-202109-I%21%21PDF-E.pdf) search extract §2.1 examples report differing seasonal effects; do not transfer their coefficients. P.676, P.453, P.834, parabolic-equation benchmark literature, USGS 3DEP, Copernicus DEM and NEC documentation are source leads, not verified equation-level specifications. No source text copied beyond short paraphrase. Repository sources linked by path above; consult pinned snapshot, not stale local files.

## Adversarial planning checks and limitations

- X01/X06 share evidence and cannot be counted as independent confirmations; seasonal changes may reflect instrumentation, not vegetation.
- X02 feasible location envelope depends on documented bounds; least-squares distance fit is not independent position verification.
- X03 cannot establish behavior below ITM's validity boundary; X04 area statistics may not be comparable to P2P.
- X05/X07 overlap only at endpoint geometry; one tests resolution, other reference consistency. Historical modern terrain mismatch cannot prove past error.
- X08 would double-count antenna gain unless measurement normalization is verified; X09 may be too weak; X10 may lack representative contemporaneous atmospheric profiles.
- No independent reviewer agent or numerical execution in this planning turn. Public literature access was limited to retrieved excerpts; exact equations, licenses and raw metadata are prerequisites. Thresholds and ranking are planner decisions, not findings. No lockbox access, no MATLAB runs, no experiment execution. Human and independent technical review before public scientific claims.


---

## Adversarial review — 2026-11-26

Reviewer: ChatGPT, adversarial pass against the proposal and current repository snapshot [304eef5](https://github.com/nicklasorte/ITM_ai_experiment/tree/304eef5784a5a93ae672f29cdbf11af8da7e297c). Original cards preserved. Recommendations below supersede their proposed release criteria only after planner disposition; this appendix does not register or authorize execution. Scope is individual-path loss, not interference aggregation.

### Executive verdict

The portfolio is mostly diagnostic, not ten candidate model improvements. That distinction is essential after B21/B25/B27 closures and B29's failed recalibration. A result that establishes sensitivity, a data defect, or a limitation of the measurement statistic does not establish a transferable correction. Do not claim new independent validation using D31/D32 after inspecting their outcomes. B32 outcome C is failure to establish superiority under its registered rule, not equivalence. The original proposal's 130-pair wording requires clarification: the B32 registered hi counts sum to 325 table-band observations (39+37+35+18+33+39+31+31+34+28); repeated seasons and bands are not independent physical paths. 130 is the nominal distinct non-R5 paths across the three areas (40+40+40=120, plus 10 R5 if included gives 130), not a verified count of eligible deciding pairs. Recompute distinct eligible physical IDs before quoting support. B14 is a P.617 time-distribution diagnostic using refractivity maps from PR #7, not simply a scalar refractivity substitution experiment. Correct both descriptions at revision.

### X01 — Seasonal contrasts: major revision, advance jointly with X06

**Attack:** equal printed distances do not establish identical antenna placement, soil moisture, hardware or calibration. B31 explicitly reports Hunter Liggett T7's two positions, uncertain assignment, and Graham R5 only in Table 8. Two periods per area cannot identify a seasonal causal effect, and Arizona and California periods do not represent the same season contrast. A static prediction of zero is a null for unchanged inputs, not a physical prediction of invariant atmosphere or ground.

**Required revision:** define named period contrasts (Graham Sep/Oct 1973 versus Apr 1974; Hunter Liggett Jan/Feb versus May/Jun 1974), not a pooled leaf-on/off effect. Exclude R5; exclude T7 from primary analysis until identity is verified, report inclusion sensitivity. Lock exact path-band-height keys, source flags and measurement statistic. Primary median contrast at 3 and 10 m and difference-in-differences J; require all four cells for J. Common additive period calibration cancels in J only if shared across heights; frequency-dependent or height-specific calibration does not. Report median shifts separately from J, include detected-only and informative censor bounds; questionable/uncertain values excluded primary. Use terminal-level crossed dependence sensitivity, not independent path counts. Do not call an interval crossing zero a falsification: equivalence requires the entire uncertainty interval within ±1 dB including calibration, otherwise inconclusive. No vegetation correction. **Release:** metadata and period comparability audit first; low-cost diagnostic if feasible.

### X02 — Geolocation uncertainty: major revision, high priority conditional

**Attack:** B31's 100 m prior is planner-selected, not measured position uncertainty. A distance fit constrains relative geometry but permits translation/rotation and correlated distortions. Graham R5 has 10 distances for 11 terminals; zero adjusted misfit is by construction. Hunter Liggett's two T7 assignments differ in misfit by only 0.024 km, below most printed distance precision. A finite random sample cannot certify all feasible locations; 128 versus 256 draws cannot establish extrema.

**Required revision:** distinguish map registration error (shared translation, rotation, scale), digitization error, and distance rounding; derive constraints from original map pixels and graticule, not residual loss. Use geodesic distances and correct rounding intervals per printed precision. Enumerate both T7 assignments and keep R5 descriptive. Jointly perturb terminals, share scenarios across seasons, bands and both models. Use deterministic boundary scenarios plus space-filling interior designs; if claiming extrema, use validated bounds or optimization with explicit residual gap, otherwise call results sampled envelopes. Report absolute path-loss and C_hi sensitivity, paired model error difference, changes in horizon and clearance, and invalid-profile coverage. Freeze profile source and sampling; do not mix terrain epochs. Reproduce B32 baseline with exact original settings. **Release:** map uncertainty audit before any profile run; no probability statement without a justified distribution. A rank reversal weakens interpretation of B32, does not invalidate its registered outcome.

### X03 — TX clamp: advance as bounded sensitivity, not correction

**Attack:** the proposed sweep moves upward from 0.5 m, away from the measured 0.35 m. Smooth behavior above the bound cannot constrain behavior below it. Near-ground diffraction, interference and mode switches may be nonlinear. The common TX offset does not necessarily cancel in C_hi; B32's statement that it mostly cancels is untested. The 90% rule can conceal a small but decisive subset.

**Required revision:** compute both models' C_hi(t), mixed difference relative to 0.5 m, and paired absolute contrast-error difference on fixed B32 support. Report per-stratum and per-terminal worst cases and sign reversals, not just 90% coverage. Reproduce receiver-only sweep separately; distinguish TX-only from a full factorial, which needs every crossed height combination. No slope extrapolation to 0.35 m, even as a suggested correction. Check reciprocity only for symmetric metadata and physical settings; no imposed monotonicity on coherent propagation. Retain actual measured height and modeled height in output. **Release:** low-cost Mac diagnostic after baseline parity. Small changes establish local supported-domain robustness only; large changes motivate X08 or new supported-height measurements.

### X04 — Area-mode comparator: hold until statistic and reference audit

**Attack:** area mode estimates a distribution across locations and situations, not a specific profile. A population median at each height is not the median of paired height differences; subtracting two marginal quantiles does not identify their joint contrast. Deriving delta-h from each measured path and then evaluating it as an area prediction can undermine the population interpretation. OT 75-74's historical method may differ from current ITM implementation.

**Required revision:** reproduce a published area-mode example with the correct version, units, siting criteria, variability mode and quantile convention. Define homogeneous distance/terrain/siting populations before outcomes, compute delta-h independently using the source-prescribed terrain sampling, and use compatible location/time statistics. Compare marginal observed loss distributions at each supported height against area predictions, with the same population and sampling weights. Do not score individual path errors or claim paired C_hi superiority from marginal quantiles; paired contrast remains a separate P2P endpoint. If historical and modern implementations differ, label separate comparators. **Release:** source/benchmark only until compatible observations established. No replacement of P2P 707 based on area statistics.

### X05 — Foreground microtopography: conditional high-value research

**Attack:** higher resolution is not automatically more accurate. Lidar ground classification, interpolation, vegetation, survey datum and terminal position error can dominate low-height clearance. Coarsening changes endpoint ground elevation, delta-h and horizon together. A fine PFL may violate the pinned implementation's numerical assumptions or alter edge selection without physical improvement. Modern terrain cannot establish 1970s foreground geometry.

**Required revision:** use a contemporary surveyed cohort, with documented DTM accuracy and independent check points. Specify anti-alias/coarsening operator, grid origin, interpolation and fixed-endpoint uniform PFL; compare same source/epoch. Separate fixed absolute antenna elevation versus fixed structural AGL experiments, and reject invalid heights rather than clipping. Compute whole-profile and foreground-only controlled differences with smooth transitions defined before outcomes; retain actual profiles and report all changed model intermediates. Include flat and surveyed single-obstacle controls and convergence checks across supported spacing. Require independently verified geometry improvement first, then paired loss-error improvement with uncertainty and replication. A 30 m product's error is not equivalent to an artificial 30 m resample. **Release:** no historical fine-terrain claim; conditional on new input approval and surveyed positions. Distinguish data improvement from model improvement.

### X06 — Seasonal variability: merge with X01, restrict estimand

**Attack:** B31 records 10/50/90 percent values but the original table convention must be checked (exceedance versus non-exceedance). W and K can be wrong in sign or interpretation if labels are reversed. Three quantiles do not identify a distribution or mixture; different distributions share these quantiles. A between-period median shift is not a within-period temporal variance component. Holding out a season with unknown future mixture weights does not validate an annual prediction.

**Required revision:** confirm loss percentile orientation from original report, convert to increasing CDF quantiles q10≤q50≤q90, flag violations without silently sorting. W=q90−q10; K=q90+q10−2q50 is a quantile asymmetry statistic, not moment skewness. Use six valid cells per period pair for width/asymmetry contrasts; report missing and censored support, no averaging of quantiles. Report |S| relative to W descriptively; no decomposition of variance or annual CDF from tables. With future raw synchronized time series for each individual path, define target duration weights and autocorrelation-aware blocks; empirical mixture identity is descriptive, prediction requires independent periods and known weights. **Release:** one shared metadata and analysis registration with X01; do not count two confirmations from same evidence. No reopening B29 time-scale family on this evidence.

### X07 — Datum/reference audit: promote metadata stage, no model candidate

**Attack:** a common vertical offset preserves chord clearance at fixed curvature, but ITM's elevation-dependent refractivity and effective radius can change; a blanket invariance test on final loss is wrong. Orthometric/ellipsoidal differences are spatially varying; DSM versus DTM is a surface-definition difference, not a datum transformation. Antenna AGL, center of radiation, structure height and terrain cell elevation are distinct.

**Required revision:** inventory product edition, vertical reference, geoid model, units, coordinate reference system, ground/surface semantics and station survey reference. Distinguish documented mismatch from unknown. Source-check the pinned refractivity initialization and independently calculate expected change for constant elevation offset; test geometry at fixed curvature separately from full core. Apply only documented geoid conversion (with sign and units verified); no inferred canopy subtraction. Compare against independent surveyed endpoints and propagate transformation uncertainty. **Release:** inexpensive metadata audit now, numerical tests only on verified discrepancies. Any frozen-data correction requires separate approval and rebaseline, not credit as a 707 improvement.

### X08 — Antenna installation: park pending normalization and benchmark

**Attack:** B32 identifies quarter-wave vertical monopoles; finite screen dimensions, feed and installation details are not established by the proposal. A monopole's pattern and impedance depend on ground, feed and geometry; realized gain includes mismatch, while basic transmission loss uses a defined antenna reference. Applying gain corrections to already normalized basic loss can double count. Near-field mutual coupling cannot generally be represented by two far-field gains.

**Required revision:** first audit OT 75-74 Appendix A and measurement calibration equations; establish exactly what gains, cable losses and mismatch were removed, and what remains in reported basic loss. Verify screen/ground geometry, soil and antenna electrical length at both frequencies. If unavailable, no retrospective correction. For a new reference experiment specify source-supported solver, lossy-ground formulation, feed, accepted power, radiation efficiency, polarization and near/far-field validity. Benchmark free-space dipole and ideal conducting-plane monopole plus independent lossy-ground reference, convergence and energy balance. Separate accepted-power gain from realized gain; compare independent measured installation patterns before path-loss application. **Release:** documentation audit only; solver and measurement campaign parked pending approval and reference. Not an ITM sub-0.5 m workaround.

### X09 — Gaseous absorption: cheap physical ceiling, then likely close

**Attack:** the expected magnitude below 10 GHz may be too small, and B32 VHF/UHF short paths are not the target. The source recommendation is not yet equation-verified. A surface-specific attenuation times full path distance is not valid for arbitrary scatter geometry; some reference predictions may already include gas loss. A 1 dB per-path threshold is not a composite headroom bound.

**Required revision:** verify current P.676 method, units, pressure/temperature/water-vapour domain and existing loss accounting. Restrict first to supported clear terrestrial paths; calculate a conservative source-grounded attenuation envelope from documented atmospheric ranges and path lengths, not fitted weather. Compare maximum physically possible signed correction on exact support against existing history-matching and censor/site gates. Keep per-path diagnostic resolution separate from score ceiling. If upper envelope cannot support meaningful effect or score gate, close without MATLAB candidate. If data insufficient, synthetic domain screen only. **Release:** source/ceiling audit; no new atmospheric dataset unless ceiling warrants it.

### X10 — Vertical refractivity profile: park pending independent measurements

**Attack:** a single sounding may not represent the entire path or measurement time; surface gradients do not determine elevated ducts. A constant-gradient approximation can differ from ITM's scalar curvature convention; comparing a PE prediction with ITM confounds terrain, boundary conditions, launch field, polarization and atmospheric treatment. B14 used P.617 scatter distributions with map inputs; do not misdescribe its mechanism. A deterministic snapshot is not an annual loss percentile.

**Required revision:** define refractivity N and modified refractivity M consistently with earth curvature; avoid double counting curvature in flattened-earth PE. Source-check P.453/P.834 and solver formulation, units and validity. Benchmark homogeneous, constant-gradient and independently published stratified cases; verify range/height step, absorbing boundary, launch normalization, ground impedance and convergence. Use matched within-solver full-profile versus scalar-reference contrast, with the scalar derived by a fixed source-supported rule, not tuned to measured loss. Require representative contemporaneous profiles along path or justified horizontal homogeneity, uncertainty ensembles, independent terminal groups and calibrated time-matched individual-path observations. Compare paired absolute error of the two PE cases first; ITM comparisons secondary. Do not treat PE agreement as a transferable ITM correction or annual statistic. **Release:** park observational stage until approved data and benchmark exist; synthetic source study only if separately registered.

### Cross-cutting statistical and governance requirements

- Shared TX and RX create crossed dependence; ordinary path bootstrap is conditional on sampled terminals. Report terminal counts, crossed-cluster or conservative terminal-block sensitivity, and site-level results. Two groups do not support reliable population-level confidence intervals; use descriptive results where cluster count is small. Repeated periods and bands are not independent replication.
- Distinguish equivalence (interval contained in a preregistered practical margin), directional support, inconclusive, and not identifiable. A failed significance test is not falsification. Specify calibration/geometry uncertainty and multiplicity for deciding endpoints before outcomes.
- Separate measurement error, input uncertainty, numerical error, physical model discrepancy and score headroom. A diagnostic improvement on already inspected D31/D32 is development evidence. New independent confirmation must be prospectively frozen and approved; never inspect lockbox.
- Verify current parent, count k, frozen hashes, source versions and local evaluator parity before registration. Do not assume 2,000 bootstrap draws resolve the required extreme adjusted quantile; follow live repository rules and document numerical precision. No score, candidate or data changes in this review.
- The source leads in original cards are not verified implementations. No new literature retrieval or equation-level verification in this pass. Before execution, obtain primary source pages and independent reference cases; record unavailable inputs as blockers. No invented data, fitted constants or ad hoc switches.

### Revised ranking and release matrix

| Priority | ID | Disposition | Required evidence before next stage |
|---|---|---|---|
| 1 | X01 | Revise and advance | Period/terminal/calibration audit; shared registry |
| 2 | X06 | Merge with X01 | Confirm percentile convention; descriptive widths only |
| 3 | X03 | Advance bounded diagnostic | B32 parity, supported-domain sensitivity |
| 4 | X02 | Conditional advance | Defensible joint map uncertainty scenarios |
| 5 | X07 | Advance metadata audit | Documented datum/reference mismatch |
| 6 | X09 | Source ceiling only | P.676 domain and exact-support leverage |
| 7 | X04 | Hold | Historical reference and compatible population statistics |
| 8 | X05 | Conditional research | Contemporary surveyed DTM and independent measurements |
| 9 | X08 | Park | Installation normalization and solver benchmark |
| 10 | X10 | Park | Representative atmospheric profiles and independent path measurements |

**Recommended next batch:** one metadata-first seasonal diagnostic combining X01 and X06, with explicit T7/R5 exclusions, period-specific estimands, percentile convention and censoring rules. X03 follows as a separate model-only sensitivity. X02 and X07 metadata can be prepared without a model run. Do not register all ten as scored experiments. If seasonal metadata is insufficient, close as not identifiable rather than relax eligibility. If the supported-domain clamp and geometry sensitivity are small, stop repeated historical low-height mining and prioritize a prospective measurement design.

### Review verification and limitations

Reviewed original ten cards, B31 and B32 source/geometry/results, B14 mechanism and FRAMEWORK governance, and phase plan context. Arithmetic desk check: the B32 hi stratum counts sum to 325, not independent paths; nominal 120 non-R5 physical paths and 130 including R5 before eligibility, with T7 assignments and shared terminals requiring key-level verification. No raw CSV recomputation, MATLAB execution, independent reviewer agents, external source verification or lockbox access. Rankings and release recommendations are reviewer judgments, not experimental results. Original proposal preserved verbatim; this appendix is the review record. Human review before scientific claims leave the repository.
