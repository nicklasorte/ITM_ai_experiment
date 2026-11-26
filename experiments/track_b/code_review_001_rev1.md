# Track B review gate and review 001
2026-11-26. Reviewed tournament_rev1.py at a1f2ff361512aeed20a39dcfdff7aeebf5d36eb7. Self-review, not independent approval.

## Mandatory sequence
For each new implementation: freeze specification and acceptance criteria; implement isolated versioned code; run unit, analytic, convergence and adversarial tests as applicable; record results and coverage; review exact commit for mathematical correctness, physical domain, numerical stability, software, reproducibility and performance; fix blocking findings and rerun; record disposition before next implementation. Independent reviewer required before architecture selection or external claims. Do not weaken gates after seeing results. No legacy score or lockbox changes.

## Review 001
Verdict: exploratory smoke reproduced; BLOCK progression until blocking findings addressed.
- High: assertions disappear under python -O; replace with explicit tests and nonzero failure exit. Asymptotic metrics printed but no acceptance criteria.
- High: no finite scalar input validation or declared finite supported interval; quadrature cancellation and phase accuracy outside sweep untested. Explicit domain and status; reject invalid input; test boundary and nonfinite cases.
- High: three kernels share scalar Fresnel approximation, not independent architectures. Label as canonical kernel test only; independent EM reference and source equation verification before broader claims.
- Medium: no pinned dependency manifest, machine-readable per-case results or environment provenance; add versions, coverage and per-case errors.
- Medium: quadrature error estimates discarded; check convergence and warnings; use explicit relative/absolute tolerances.
- Medium: report signed loss error, common-support comparisons and worst-case v; no timing claims without benchmark.
- Low: document complex convention, normalization and asymptotic derivation; separate test runner from implementation.

Recomputed in local Python using equivalent formulas on 65 v values [-8,8], step 0.25. Max field / max absolute loss error: wave 2.2342807379e-15 / 4.1755379302e-13 dB (65/65); leading asymptotic 0.008502663215 / 0.11706505486 dB (50/65); two-term 0.001930263735 / 0.14448036081 dB (50/65). Results reproduce previous report. Integration by parts yields the stated leading and next terms under the declared convention. This is not independent full-wave validation. No timing, source-level literature verification, independent reviewer or CI run. No fixes made in this review commit. Next action: repair review findings in rev2 and review again before new solver.
