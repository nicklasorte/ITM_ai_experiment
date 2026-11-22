# ITM research package — proposed, review-only

This package proposes scientifically testable changes to the repository's copy of the Irregular Terrain Model. It contains no MATLAB implementation, evaluator, dataset, experiment record, branch, commit, or result. No experiment was executed.

- `docs/research/research_basis_rev1.md` — repository state, evidence, source map, and scope limits.
- `docs/research/hypothesis_rankings_rev1.md` — 24 ranked hypotheses with mechanism, source, novelty, target stratum, and falsifier.
- `docs/research/validation_protocol_rev1.md` — fixed-input implementation contract, evaluation gates, censoring treatment, and external-validation plan.
- `docs/research/adversarial_review_rev1.md` — independent challenges, reachability bounds, and stop conditions.
- `docs/research/implementation_roadmap_rev1.md` — order of work and decision points.
- `experiments/proposals/H01_proposal_rev1.md` through `H05_proposal_rev1.md` — detailed specifications for the five strongest experiments.

The repository was read at `main`, commit `5d39122275ef2b1b9c93be1e72007e61a90b53cc`, with baseline ITM pinned to `matlab_itm@9bd6a4e`. The package reflects experiment history through B05 and diagnostics D01–D03 recorded on 2026-11-21.

All citations point to primary NTIA, NBS, or ITU sources. Equations marked as candidate formulations must be rechecked against the cited edition before implementation.

## Review decision requested

Review the ranking, source applicability, eligibility definitions, and acceptance controls before any file is copied into the repository. If approved, copy only the Markdown files into `docs/research/` and `experiments/proposals/`. The existing MATLAB implementation, evaluator, datasets, and experimental records remain unchanged.
