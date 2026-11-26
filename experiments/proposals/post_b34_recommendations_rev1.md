# Post-B34 partial replay: research decisions and next actions

2026-11-26. Planner. Snapshot 3f39f60a2b878e048118f9a68fef1476e497b25f. Individual-path propagation only. This is a recommendation, not a batch registration or authorization to change model code.

## Decisions

1. Deprioritize seasonal correction (X01/X06). The partial replay has four J intervals spanning zero (Graham VHF −1.269 to 6.027 dB, UHF −6.775 to 0.078; Hunter VHF −2.296 to 1.894, UHF −1.931 to 1.300). These are descriptive crossed-terminal sensitivity intervals, not population inference. Calibration, source percentile convention and censor bounds remain unresolved. Finish the metadata audit and registered replay before closing the diagnostic; do not fit a seasonal coefficient.
2. Deprioritize transmitter-height correction (X03). On 325 eligible table-band observations, 92.923% (707) and 92.308% (stock) have contrast changes below 1 dB at both tested TX perturbations. Maximum changes 5.364 and 7.249 dB respectively. Mean paired absolute contrast-error difference at TX 1 m is +0.006 dB (707 minus stock). This is not equivalence; Eglin and Hunter exceptions remain. Complete existing-output terminal maxima, sign reversals and T7 sensitivity, then remaining nine factorial cells only after D34c parity. No inference below 0.5 m.
3. Prioritize D34c. B33 reports up to 0.197 dB loss discrepancy after profile CSV roundtrip despite elevation changes around 5e-13 m. This is a reported symptom, not a proven defect or independently reproduced result. Investigate representation sensitivity before new empirical model adjustments. Preserve original B33 decision.
4. Hold Package G model runs pending D34c. X02 map constraints and X07 metadata can be prepared without model runs. X09 source-grounded attenuation ceiling is a cheap parallel screen, subject to exact support and accounting checks. No new scored candidate.

## Work available without MATLAB

| Priority | Task | Deliverable | Release gate |
|---|---|---|---|
| 1 | Static code audit of experimental and pinned stock horizon/branch comparisons | Candidate divergence map with file/line references and minimal synthetic profiles | Stock source/version available; hypotheses only |
| 2 | Implement reproducible D34a/b replay script | Versioned script, synthetic tests, eligibility ledger, shared crossed draws, censor intervals, terminal extrema | Source convention/calibration unknown explicitly blocks stronger claims |
| 3 | Audit original OT 75-74 tables and Appendix A | Page-specific metadata and normalization ledger | PDF accessible and exact pages verified |
| 4 | Prepare D34c MATLAB diagnostic harness | Read-only profile replay, lossless MAT/17-digit serialization, trace schema, smoke instructions | Actual MATLAB execution on Mac required |
| 5 | X02/X07 metadata and X09 physical ceiling | Source-grounded uncertainty constraints and leverage screen | No frozen input changes; missing provenance stops |

## D34c decision tree

Reproduce fresh baseline within registered 1e-6 dB tolerance. If not, stop for source/runtime drift. Compare exact profile vectors including spacing and count, then lossless serialization and original CSV. Isolate spacing versus elevations; identify first divergent intermediate in each model. Examine branch margins, horizon tie handling, effective heights, roughness and mode transitions; do not assume a shared cause. Use single-element ULP perturbations, matched stable controls and synthetic ties. A physically legitimate near-boundary response is not automatically a bug. If reproducible representation-dependent discontinuity is localized, propose a separate repair with independent reference, continuity and frozen acceptance tests. Never add arbitrary epsilon or change input precision to improve score. If not localized, report unresolved and move to metadata work.

## Completion criteria and limits

Partial replay is exploratory: independent endpoint bootstrap draws rather than registered shared draws; source audit, censor bounds, standalone script, synthetic tests, full factorial and independent review outstanding. See [partial replay](../D34a-season-closure/partial_replay_rev1.md), [B34](../batches/B34.md), [B33](../batches/B33.md). No new calculations or MATLAB runs in this recommendation. Priorities are planner judgments. No changes to frozen data, evaluator, model, scores or lockbox. Human review before external scientific claims.
