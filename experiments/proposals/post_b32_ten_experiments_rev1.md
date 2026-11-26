# Ten new ITM research experiments after B32

Planner proposal, revision 2, 2026-11-26 (red-team disposition and source update). Snapshot [f233546](https://github.com/nicklasorte/ITM_ai_experiment/tree/f2335462dd678b90757e30c4f448ed045db1c40c). Not a batch registration or authorization to run. Parent 707, evaluated as 707r-rescore-screen36. Follow CLAUDE.md, FRAMEWORK.md and program.md; no lockbox examination, no changes to frozen data/evaluator, no production code or scored runs in this delivery.

## Evidence and strategy

Read B21, B23–B32, phase plan rev 5, LOG, archive, headroom map, data proposal and previous N01–N10 headings; earlier experiment history remains binding. B23/B24 contrasts are inconclusive; B25 spherical reference fails headroom and does not remove the R1 inversion; B26 closes reflection for that target; B27 M1 bracket fails (707 +5.64 dB and stock +10.43 dB on R1 blocked height pairs, bracket share 0.10). B29 scores three candidates, zero keeps, k=9: two groups effectively inactive; time scales screened gain 0.11 dB, lo995 -0.06 dB. B30 vegetation proxy fails registered cross-site rule; only R2 has resolved negative slope, pooled slope-only improvement 0.26 dB in sample; modern canopy is not historical canopy. B31 digitized 210 paths; B32 C_hi 3–10 m contrasts on 325 eligible table-band observations across ten strata (not independent paths; distinct eligible physical IDs not yet recomputed), no stratum favors 707, one favors stock, outcome C. 0.35 m TX is outside official ITM domain; both models used 0.5 m and low-height contrast is descriptive. B32 follow-up varied receiver height only; transmitter-offset sensitivity and season-paired analysis remain undone. No claim that B32 disproves 707's overall value.

The next portfolio attacks input uncertainty, physical identifiability and independent measurements instead of searching more constants. Headroom on existing inputs is limited; rev 5's perfect cell-mean fix is only 1.13 dB screened (9.91 to 8.78); this is not a universal irreducible-error bound. Do not reopen B21, B25, M1, B29 or B30 merely because another formulation sounds plausible. No proposed item duplicates N01–N10: new cards are narrower interventions or new estimands, not another grid-phase, height/frequency contrast, ground impedance, transverse bypass or generic field campaign. Some extend earlier work; explicitly labeled.

## Ranked portfolio and release status

| Priority | ID | Study | Release |
|---|---|---|---|
| 1 | X01 | Period-paired loss and height interaction | metadata first |
| 2 | X06 | Period-paired quantile widths | same registration as X01 |
| 3 | X03 | Supported TX height sensitivity | model-only after parity |
| 4 | X02 | Joint geolocation uncertainty | conditional on defensible map constraints |
| 5 | X07 | Vertical reference audit | metadata only initially |
| 6 | X09 | Gas attenuation physical ceiling | source and leverage only |
| 7 | X04 | Area-mode reference | hold pending comparable statistic |
| 8 | X05 | Foreground DTM resolution | conditional contemporary survey |
| 9 | X08 | Installation electromagnetics | parked |
| 10 | X10 | Vertical refractivity profile | parked |

## Shared protocol

No lockbox access, scored runs, fitted parameters, frozen input/evaluator edits or production changes. D31/D32 are inspected development evidence. Pin live parent, versions, hashes, approved data, settings, and actual k before registration; do not assume historical k. Reproduce stored 707 to 1e-9 dB for identical full precision inputs; if only serialized output is available, register a precision-derived tolerance before response analysis. Fixed support for paired comparisons; stable keys and explicit exclusion ledger, no response-based selection. Report coverage by physical path, TX, RX, site, period and band; preserve repeated measurements within path and terminal resampling. Use Owen's crossed row/column resampling as sensitivity, with weights equal to TX multiplicity times RX multiplicity, plus leave-one-TX and leave-one-RX checks. With few receivers, report descriptive envelopes, not population confidence claims. Prespecify primary endpoints and familywise inference before outcomes; 2,000 draws for descriptive sensitivity only, not extreme score quantiles. Follow live FRAMEWORK for any later candidate.

Use ±1 dB as a proposed practical diagnostic margin (not score gate); directional support requires uncertainty interval entirely beyond the margin, equivalence requires entire interval inside it, otherwise inconclusive. Include calibration and geometry uncertainty; missing provenance means not identifiable. For a lower-censored loss use [bound,+infinity), detected value [x,x]; subtract intervals [a,b]-[c,d]=[a-d,b-c], propagate linear contrasts termwise, and report unbounded cases without point imputation. No hypothesis is falsified merely because a confidence interval crosses zero. New candidate requires physical mechanism, independent reference, approved held-out measurements where feasible, exact-support headroom and live acceptance gates. No aggregate analysis.

## X01 — Period-paired loss and height interaction

Use OT 75-74 Tables 8/9 (Graham Sep/Oct 1973 vs Apr 1974) and 10/11 (Hunter Liggett Jan/Feb vs May/Jun 1974). Test period differences, not causal vegetation effects. B31 reports equal printed distances but that does not prove identical placements. Exclude R5 (no second period) and T7 both locations in primary Hunter analysis until independently verified; sensitivity includes both plausible assignments. Audit hardware, calibration, antenna configuration, measurement windows and table flags before accessing responses for new contrasts. Freeze path-band-height keys and eligible counts. For each band and site S(h)=q50(period2,h)-q50(period1,h), J=S(3)-S(10), four valid cells required; measured 0.35 m descriptive only. Shared additive period offset cancels in J only if common across heights. Report S and J with uncertainty and interval censor bounds; exclude questionable/uncertain cells primary. Static model zero contrast applies only to identical inputs. Crossed terminal sensitivity per shared protocol, no pooled season estimate or independent replication claim with two sites. Directional support, equivalence, inconclusive and not identifiable as above. No vegetation correction. Outputs eligibility_rev1.csv, period_pairs_rev1.csv, calibration_ledger_rev1.md, contrasts_rev1.csv. Release: joint metadata registration with X06; unknown calibration limits inference, do not relax eligibility. Sources S1,S6.


## X02 — Joint geolocation uncertainty propagation

Test whether B32 model ranking is robust to map-derived geometry. B31's 100 m prior is a planning assumption, not a measured standard deviation. Reconstruct pixel/graticule constraints, scale and map registration (translation/rotation/scale shared within map), per-terminal digitization bounds and geodesic distance rounding intervals; do not fit loss. Enumerate both T7 assignments; keep R5 descriptive (underdetermined). Joint feasible scenarios shared across bands, periods and models. Use deterministic boundary cases and reproducible space-filling interior samples (128 then 256, report stability, not proof of extrema). No probability statements without justified distribution; no universal robustness claim without certified bounds. Recompute PFL at same epoch/source, endpoint distance, clearance, horizon and model mode; preserve B32 settings and fixed support, report invalid runs not selectively drop. Compare absolute loss, C_hi and paired error difference by stratum, report sampled extrema and any decision reversals. If sampled changes below margin, scope to tested scenarios; sign reversal qualifies interpretation not registered B32 outcome. Outputs map_constraints_rev1, terminal_scenarios_rev1, profile_diagnostics_rev1, contrast_envelopes_rev1. Release requires documented map error and profile access; otherwise unknown. Sources S1,S2.


## X03 — Supported-domain transmitter height sensitivity

At B32 geometry, fixed frequencies and settings, run each model on complete TX {0.5,0.7,1.0} m × RX {0.5,0.7,1.0,3,10} m grid (15 cells/path/model/band). Keep original measured TX 0.35 m separately. Reproduce B32 0.5 m TX baseline and receiver-only follow-up; compute C_hi(t)=L(t,3)-L(t,10), mixed difference C_hi(t)-C_hi(0.5), paired absolute contrast error difference vs measured and stock. Report all strata and terminal worst cases, sign reversals and mode changes, not only fraction within 1 dB. Reciprocity check only symmetric metadata/config; no imposed monotonicity for coherent fields. Never run ITM below 0.5 m or extrapolate to 0.35 m. Small differences indicate local supported-domain robustness only; large differences motivate independent supported-height data or X08, not clamp removal. Outputs factorial_height_rev1.csv, parity_rev1, stratum_sensitivity_rev1. Release: model-only on approved MATLAB after parity. S2.


## X04 — Area-mode reference and population statistic

Hold observational stage. NTIA TR-82-100 includes sample problems; first reproduce one historical example with documented source version, then official area.csv cases with pinned implementation and precision-based tolerance. Use independent terrain sampling for delta-h and source-defined siting classes (not loss fit). Register comparable distance/terrain/siting populations, sampling weights and time/location/situation settings; area location distribution differs from P2P per-path time quantiles. Compare marginal distributions at each supported height only when compatible sampling/statistic exists. Difference of marginal medians is not median paired height contrast; do not claim C_hi superiority, or use per-path RMSE as deciding area-mode metric. Record historical/current differences, reference checks and exclusions. If no compatible population, close as not identifiable. Outputs area_reference_rev1, statistic_mapping_rev1, population_summary_rev1. No 707 replacement. S1,S2,S3.


## X05 — Contemporary foreground terrain resolution

Conditional on approved independent contemporary survey and path-loss measurements with surveyed terminal position/electrical center and source DTM accuracy. Modern terrain cannot establish historic geometry. Compare native bare-earth DTM to same-source/epoch coarsened representation with preregistered area-weighted low-pass operator, grid origin/interpolation, and uniform endpoint-preserving PFL at supported spacing; verify actual sampling distance. Compare independent surveyed profile checkpoints first; report vertical and horizontal errors, not assume finer is better. Separate fixed absolute antenna elevation (recompute structural height; reject out-of-domain) and fixed AGL arms. Whole profile and foreground-only diagnostic with geometry-defined window and fixed smooth transition, report delta-h/horizons/clearance and mode. Flat and surveyed obstacle controls plus spacing convergence; separate numerical error from geometry. Compare paired loss error only after geometry improves, independent terminal/site replication and uncertainty; artificial 30 m resample is not actual historical product. No frozen data change or model improvement credit. Outputs DTM provenance, grid spec, survey error, paired_loss_rev1. S2,S4,S5.


## X06 — Period-paired quantile widths and asymmetry

Same eligibility registration as X01, distinct estimand. Verify source convention against OT 75-74 Tables 8–11 and distribution plots before use: if exceedance, q_p=L_(100-p); if nonexceedance q_p=L_p. Confirm q10≤q50≤q90 without sorting invalid rows. Six valid cells per height/band/path across two periods; report censor bounds and exclusions. W=q90-q10, K=q90+q10-2q50 (quantile asymmetry, not moment skewness), compare period differences and |S| relative to W descriptively. Three quantiles do not identify variance or pooled CDF. No annual distribution inference or B29 reopening. For future approved raw individual-path time series only, define target duration weights and autocorrelation blocks in advance; F(x)=sum w_s F_s(x) is descriptive identity, prediction needs independent periods and known weights. Shared terminal dependence and not independent confirmation of X01. Outputs quantile_manifest_rev1, widths_rev1, asymmetry_rev1. Release contingent on explicit convention and comparable windows. S1,S6.


## X07 — Vertical reference and antenna datum audit

Inventory product edition, CRS, units, datum/geoid, bare-earth versus surface semantics, survey center-of-radiation reference and uncertainty. USGS notes product-dependent projection and vertical reference; read actual tile headers, not generic default. Orthometric H=h-N_geoid where convention verified; geoid undulation is spatially varying, not a canopy correction. Documented mismatch versus unknown separately. At fixed curvature common constant offset preserves relative geometry; test independently of full ITM. Source-check pinned initialization and calculate expected change in surface refractivity/effective curvature for offset before comparing full core; do not assume final loss invariant. Verify any transformation sign/units against known control points and independent surveyed endpoints, propagate uncertainty; no guessed canopy subtraction. Output datum_manifest_rev1, discrepancy ledger, geometry and full-core checks. Metadata first; numerical test only on documented mismatch, separate owner-approved correction/rebaseline if warranted. S2,S4.


## X08 — Installation electromagnetics and normalization

Park solver stage. B32 records vertical quarter-wave monopoles; audit OT 75-74 Appendix A for actual feed, screen, soil, electrical length, mounting, cable and calibration equations. Establish whether reported basic loss already removes gain/mismatch; no historic correction without documentation. Future independent benchmark: source-supported lossy-ground MoM solver, specify boundary/feed/polarization/accepted power, distinguish gain referenced to accepted power from realized gain (includes mismatch). Verify free-space dipole, ideal conducting-plane monopole and independent lossy-ground case, convergence and energy balance. 0.35 m allowed in Maxwell solver only. Far-field gain product valid only with appropriate separation and reference; near-field coupling needs full two-antenna treatment. Validate measured installation patterns before predicting path loss, no double counting propagation ground interaction. Output normalization ledger, benchmark and pattern uncertainty. No solver selected or validated in this revision; Appendix A normalization unresolved. S1,S2.


## X09 — Gaseous attenuation physical ceiling

ITU-R P.676-13 (2022) listed in force; verify Annex 1 specific attenuation equation and independent numerical example before computation. For clear terrestrial paths use A_gas=integral gamma(f,p,T,rho) ds with gamma in dB/km and ds in km; homogeneous case gamma*d. Nonnegative correction only after checking existing model/reference and measurement loss accounting. Document pressure, temperature and water-vapour ranges and frequency/distance support before outcomes. No surface gamma applied blindly to scatter, no weather fit, no claim VHF sensor measurements justify GHz correction. Compute conservative envelope per eligible path and optimistic exact-support error reduction: for e=prediction-measurement, best delta in [0,Amax] is clamp(-e,0,Amax); use frozen score weighting and compare headroom, censor/site constraints separately. This is optimistic, not realizable candidate performance. If ceiling cannot pass, close; if unknown, source-only. No numeric attenuation result yet. Outputs source_checks_rev1, envelope_rev1, headroom_rev1. S7.


## X10 — Vertical refractivity-profile sensitivity

Park observational stage. B14 actually tested P.617 scatter time distributions using PR7 maps; this is a distinct clear/forward-path deterministic atmospheric profile test. P.453-14 Annex 1 eq (1): n=1+N*1e-6; P.834-9 covers refraction. For conventional flattened-earth formulation M=N+1e6*z/a (z,a same units; about 157 N-units/km for a=6371 km); verify solver convention and avoid applying curvature twice. Require published homogeneous, constant-gradient and stratified reference cases, fixed launch field, polarization, ground impedance, terrain, range/height step, absorbing boundary and convergence. Compare full profile to fixed source-defined scalar-gradient approximation within same validated PE solver; compare paired absolute errors first, stock/707 secondary. No tuning scalar to measured losses. Independent calibrated time-matched individual paths and representative along-path soundings or justified horizontal homogeneity, uncertainty ensembles, independent terminal groups. Snapshot is not annual percentile. No candidate if profile uncertainty dominates, effect unresolved, or benchmark/data unavailable. Output atmosphere provenance, reference checks, paired_path_loss_rev1 and uncertainty. Solver-specific equations and reference case remain unverified; synthetic study only with separate registration. S8,S9.


## Execution sequence and decision gates

F: X01/X06 one metadata-first registered period diagnostic, then X03 separately. G: X02 map constraints and X07 datum metadata in parallel; numerical work conditional. X09 source ceiling before any candidate; X04 benchmark only pending statistic audit. H: X05 contemporary survey conditional; X08/X10 parked. No batch ID assigned or execution authorized. If metadata insufficient stop; if clamp and sampled geometry sensitivity small, stop repeated historical mining. Independent prospective measurement design is next if no transferable mechanism emerges.

## Source register (revision 2)

- S1 Longley & Hufford, OT 75-74 (1975), https://doi.org/10.70220/hx4hbkz5 ; https://www.its.ntia.gov/publications/download/OT-75-74.pdf . Official abstract and extracted distribution-plot captions inspected; tables/Appendix A calibration and percentile orientation still require page-level verification. B31 supplies period and geometry details.
- S2 NTIA ITM official README https://github.com/NTIA/itm : verified height limits, uniform PFL encoding, area inputs, variability modes and official examples. Pinned implementation parity not run.
- S3 Hufford, Longley & Kissick, NTIA TR-82-100 https://doi.org/10.70220/zjkb4hxb : official abstract confirms area-mode sample problems and scope; sample numeric reproduction pending.
- S4 USGS DEM datum FAQ https://www.usgs.gov/faqs/what-projection-horizontal-datum-vertical-datum-and-resolution-a-usgs-digital-elevation-model : product-specific resolution and datum verified; per-tile metadata mandatory.
- S5 USGS 3DEP FAQ https://www.usgs.gov/3d-elevation-program/science/faqs : national 1/3 arc-second seamless DEM accuracy approximately 0.82 m RMSE as of 2022; not a local error bound or fine-resolution product accuracy.
- S6 Owen (2007), The pigeonhole bootstrap https://arxiv.org/abs/0712.1111 : separate row/column resampling in crossed unbalanced setting; not a guarantee with four receivers.
- S7 ITU-R P.676-13 https://www.itu.int/rec/R-REC-P.676-13-202208-I : edition/status verified, numerical formula validation pending.
- S8 ITU-R P.453-14 https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.453-14-201908-I%21%21PDF-E.pdf : Annex 1 eq (1) verified from extracted text.
- S9 ITU-R P.834-9 https://www.itu.int/rec/R-REC-P.834/en : edition/scope verified, solver-specific benchmark pending.

## Red-team disposition register

| Finding | Resolution in revised card | Remaining release gate |
|---|---|---|
| X01 causal/identity confounding | named periods, R5/T7 primary exclusions, calibration and four-cell contrast | original metadata |
| X02 arbitrary prior and extrema | joint map constraints, both assignments, sampled envelope | map bounds |
| X03 invalid extrapolation | full supported grid, no extrapolation, stratum checks | MATLAB parity |
| X04 marginal vs paired statistics | marginal endpoint only, official reference cases | comparable population |
| X05 resolution vs accuracy | same-source coarsening, surveyed geometry, two height arms | surveyed cohort |
| X06 unidentified mixture | verified convention, six cells, no annual inference | original convention/windows |
| X07 datum vs refractivity | separate fixed-curvature and full-core tests | documented mismatch |
| X08 gain double count | normalization first, accepted vs realized gain | installation/solver benchmark |
| X09 low leverage | physical envelope and optimistic headroom | source numeric check |
| X10 confounded PE comparison | within-solver reference, matched atmospheric observations | solver and independent data |
| Shared statistics | crossed terminal sensitivity, equivalence vs inconclusive, fixed support | registration and small-cluster limits |
| B32 count and B14 description | 325 stratum observations, corrected B14 mechanism | distinct eligible IDs recomputation |

Design responses incorporated, not empirical closure. The historical review below is retained verbatim. No new numerical runs, primary table-page audit, independent reviewer agent or lockbox access. Source coverage is partial; source-specific equations and benchmarks remain fail-closed prerequisites. Ranking, margins and grid are planner choices. Human review before external scientific claims.

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
