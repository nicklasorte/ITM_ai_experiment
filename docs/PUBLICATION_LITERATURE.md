# Could this work be published? A literature review

Rev 1, 2026-11-21. Scope: what others have done (1) with AI agents that
improve scientific models outside spectrum and propagation, and (2) with
propagation models and AI, and where this project would fit. It ends with a
novelty assessment, target venues, the reporting rules that apply, and the
experiments a paper would need. The search was broad but not systematic:
treat "we found no prior work on X" as "a reviewer may know one we missed."

## Bottom line

Yes, probably, as a methods-and-results paper, if three things are true when
it is written:

1. **The contribution is physics, not a black box.** Each kept change to ITM
   is a named submodel from a public source, with held-out evidence and a
   physical explanation.
1. **The comparison is honest.** The paper compares the agent's best variant
   with stock ITM, with P.452 and P.2001, and with **ITM recalibrated by a
   conventional optimizer**. The closest prior study outside propagation
   found that no agent-generated parameterization beat a retuned physical
   scheme (see [Outside spectrum](#2-outside-spectrum-and-propagation)).
1. **The validation survives a leakage review.** Group-wise held-out sites,
   a lockbox scored once, and an explicit note that ITM's time-variability
   curves come from data of the same era.

**The gap.** We found ML corrections layered on top of ITM, ML path-loss
models that replace it, symbolic regression that discovers new path-loss
formulas, and LLM agents that operate propagation simulators. We did not find
work in which an AI agent edits the internals of an established, standardized
propagation model under a measurement-based, held-out acceptance protocol,
and reports which physical submodel changes survive. That combination is
the publishable claim.

## 1. The pattern this project uses

An LLM proposes code changes, an automatic evaluator scores them, and only
improvements are kept. The general literature is in
[AGENT_OPTIMIZATION_LITERATURE.md](AGENT_OPTIMIZATION_LITERATURE.md)
(FunSearch, AlphaEvolve, AIDE, OPRO, Reflexion, autoresearch). This review
looks only at work that applies the pattern to physical science and
engineering models.

## 2. Outside spectrum and propagation

### Closest analog: agents improving Earth system model parameterizations

[Lamb et al., "Can LLM agents improve imperfect parameterizations in Earth
system models?" (NeurIPS 2026)](https://neurips.cc/virtual/2026/166426)
([arXiv 2611.03543](https://arxiv.org/pdf/2611.03543)) is the nearest
published study. Its setup:

- The test case is warm-rain collision-coalescence.
- Agents synthesized the literature, reimplemented published bulk
  parameterizations, and proposed new functional forms as differentiable
  JAX code.
- Their parameterizations were compared with conventional schemes and
  data-driven emulators, against high-fidelity superdroplet simulations.

Results:

- The agents wrote executable, differentiable, mass-conserving code.
- Unattended performance depended strongly on the scheme.
- Evaluation feedback reduced rollout errors.
- **No agent-generated closure beat the retuned physical schemes**, and the
  retuned schemes often matched learned closures at much lower compute cost.

The same paper argues that physically grounded parameterizations remain
essential for interpretability and out-of-distribution robustness, and notes
related work on agentic translation of legacy Fortran components into JAX.

**What it means for us.** It is the right template: a legacy physical model,
agents proposing submodel changes, a reference dataset, and a retuned
baseline. It also sets the bar: a paper must show the agent beats
recalibration, or report honestly that it doesn't.

### LLM-guided evolution of physics and engineering code

- **MadEvolve** (cosmology) integrates LLM-driven evolution with physical
  fitness metrics and HPC-compatible evaluation; the LLMs act as mutation
  operators that understand code semantics, while physics-based evaluators
  steer the search
  ([Li, Zang, Münchmeyer 2026](https://arxiv.org/html/2602.15951v1)).
- **Self-evolving fluid-control agent:** instead of adjusting weights, the
  agent runs candidate controllers in simulation, diagnoses failures from
  multimodal evidence, and refines the source code
  ([Sun et al. 2026](https://arxiv.org/html/2606.08405)).
- **PhyNex** couples LLM-guided search with domain tools that enforce
  physical consistency. It points out that evolutionary program search,
  which applies several mutations at once, obscures the causal contribution
  of each change
  ([Lin et al. 2026](https://arxiv.org/html/2606.14266v1)). This project's
  one-change-per-experiment rule addresses exactly that.
- **Surveys** of LLM scientific agents cover CFD workflow automation such as
  OpenFOAMGPT ([survey, arXiv 2503.24047](https://arxiv.org/pdf/2503.24047)).

### LLM-guided equation discovery

- **LLM-SR** (ICLR 2025 oral) treats equations as programs and combines LLM
  scientific priors with evolutionary search over equation programs
  ([Shojaee et al.](https://arxiv.org/html/2404.18400v1)). It reports
  physically accurate equations that beat symbolic-regression baselines,
  especially out of domain
  ([ICLR paper](https://par.nsf.gov//servlets/purl/10621221)).
- Follow-ups add reflection on data (DrSR,
  [arXiv 2506.04282](https://arxiv.org/pdf/2506.04282)), residual-informed
  search (RISR, [arXiv 2610.11387](https://arxiv.org/pdf/2610.11387)), and
  influence-guided term selection (IGSR,
  [arXiv 2605.29184](https://arxiv.org/pdf/2605.29184)).

The difference: equation discovery writes a new formula from scratch; this
project edits a 60-year-old model whose structure regulators already rely
on.

### Hybrid physics–ML models (hydrology)

Hydrology is the field with the most experience embedding ML inside
process-based models:

- A distributed hybrid framework uses a neural network to refine internal
  water fluxes inside a conceptual model
  ([HESS 2025](https://hess.copernicus.org/articles/29/3589/2025/hess-29-3589-2025.html)).
- Differentiable, physics-informed ("δ") models with learned
  parameterizations approach deep-learning accuracy and extrapolate
  plausibly ([Feng et al. 2023](https://par.nsf.gov/servlets/purl/10437869)).
- A 2026 opinion piece names the tension: ML predicts well but often gives
  little mechanistic insight, breaks physical constraints, and struggles
  beyond its training data
  ([Samadi et al.](https://egusphere.copernicus.org/preprints/2026/egusphere-2026-6531/egusphere-2026-6531.pdf)).

**What it means for us.** Reviewers from these fields will ask the same
question: is the result more accurate *and* more physical? Keeping changes
as named submodels, not learned corrections, is the answer.

## 3. Propagation models and AI

### Surveys and venues that already carry this topic

- IEEE Transactions on Antennas and Propagation ran a 2022 special section,
  "Artificial Intelligence in Radio Propagation for Communications"
  ([guest editorial](https://research.dial.uclouvain.be/entities/publication/6d4819b7-f0b2-473a-b696-e31e1260bc11)),
  with a two-part survey; Part II covers ML for scenario identification and
  channel modeling
  ([Huang et al., TAP 70(6)](https://lup.lub.lu.se/record/73f63ccd-39df-4868-907a-6a0bfb60b13c)).
- Seretis and Sarris survey ML for radiowave propagation modeling and name
  the input/output specification and model architecture as the main
  challenges ([arXiv 2101.11760](https://arxiv.org/pdf/2101.11760.pdf)).

### ML corrections on top of ITM or its relatives

- NIST used model-aided deep learning with satellite images to improve
  path-loss prediction in the 3.5 GHz CBRS band, where WInnForum standards
  use ITM, which has no clutter and underestimates loss
  ([Nguyen, Caromi, Kallas, WCNC 2022](https://www.nist.gov/node/1715181)).
- Minimum mean-squared-error correction factors reduced the error standard
  deviation of an ITM-derived model by as much as 6.9 dB on a Utah campus
  campaign ([Varner et al.](https://par.nsf.gov/servlets/purl/10409412)).
- TV white space work augmented ITM and ITWOM with field measurements and
  land cover, cutting RMSE by more than 7 dB
  ([NWU repository](https://repository.nwu.ac.za/items/d8efe837-639a-48d3-9c00-1dffb4c2df25)).
- A suburban sub-6 GHz study reports Longley-Rice RMSE of 16.12 dB against
  far lower ML errors
  ([arXiv 2510.00696](https://arxiv.org/pdf/2510.00696)).

These add corrections around ITM, or replace it. None changes ITM's own
submodels.

### ML that replaces the propagation model

Canada's CRC trains ML path-loss models on Ofcom drive tests with
city-holdout validation; P.1812 scores 11.85 dB median RMS, and is noted to
have been developed on the same data
([Ethier and Châteauvert](https://arxiv.org/html/2405.10006v1)). See also
[LITERATURE_REVIEW.md](LITERATURE_REVIEW.md).

### Discovering path-loss formulas

- An automated method compares deep symbolic regression and
  Kolmogorov-Arnold networks for path-loss model discovery and reports up to
  75 % lower prediction error than traditional methods on its examples
  ([Anaqreh et al., arXiv 2505.23383](https://arxiv.org/html/2505.23383v4)).
- Symbolic regression has been applied to ITU-R P.1546 curves to produce
  explicit expressions instead of tables
  ([Springer, Telecommunication Systems 2025](https://link.springer.com/article/10.1007/s11235-025-01297-9)).
- A physics-inspired KAN for air-to-ground channels builds free-space and
  two-ray physics into the learner and returns symbolic expressions
  ([arXiv 2510.06355](https://arxiv.org/pdf/2510.06355v2)).

These are the nearest propagation cousins of this project: interpretable,
data-driven model discovery. They start from data and a function library;
this project starts from a standardized model and a list of published
submodels.

### LLM agents in propagation and wireless

- **RadioSim Agent** couples LLMs with deterministic EM solvers; the agent
  chooses propagation mechanisms, runs simulations, and summarizes path loss
  ([Hussain and Brennan, arXiv 2511.05912](https://arxiv.org/abs/2511.05912v1)).
- **LLM agents for radio map generation and network planning** drive
  commercial tools and save manual work
  ([Quan et al., arXiv 2501.11283](https://www.arxiv.org/abs/2501.11283)).
- A 2025 survey traces LLMs in wireless from task adaptation to autonomous
  agents ([arXiv 2507.21524](https://arxiv.org/pdf/2507.21524)).

These agents *operate* propagation tools. None *modifies* the model and
validates the change against measurements.

## 4. Novelty assessment

| Claim a paper could make | Prior work that comes close | Holds? |
| --- | --- | --- |
| An LLM agent proposes, implements, and tests submodel changes inside ITM | ESM parameterization agents (other field); RadioSim and radio-map agents (operate tools, don't edit models) | Yes, for propagation |
| Changes are validated on held-out measurement sites and a lockbox, with censored data handled | CRC city holdouts (ML models, not ITM edits) | Yes, as a protocol for model-editing agents |
| Time variability is scored as level and shape separately | OT/TRER 16 compared ITM with long-term data (no agent, no shape score) | Partly; the shape metric is a modest addition |
| The surviving changes identify which ITM mechanisms limit accuracy (diffraction, effective height, mode switch) | Paul 2003 named effective height and land cover qualitatively | Yes, if results show it |
| A cheap-worker, strong-planner agent split works for model editing | AlphaEvolve's Flash and Pro ensemble (math and code) | Secondary contribution |

**Threats a reviewer will raise:**

1. *"Recalibration would do as well."* Run Tier 1 recalibration with a
   standard optimizer as its own baseline. The ESM study's result makes
   this mandatory.
1. *"The data are old and small."* Phase 2 is 1965–1967 and 426 paths.
   Answer with the lockbox sets and, ideally, one modern public dataset.
1. *"The baseline time curves were fit on similar data."* State it, and
   rely on the shape metric and the lockbox.
1. *"The agent just found what P.452 already does."* That is a finding if
   stated plainly: show which P.452 or P.2001 parts transfer into ITM and
   which don't.
1. *"Who did the science?"* Log every hypothesis, who proposed it (planner,
   worker, human), and what happened. The experiment log is the audit
   trail.

## 5. Where to publish

| Venue | Fit | Notes |
| --- | --- | --- |
| IEEE Transactions on Antennas and Propagation | Full paper on method and physics findings | Already published a special section on AI in radio propagation (2022) |
| IEEE Antennas and Wireless Propagation Letters | Short letter on one strong result, for example a diffraction swap | Fast; a narrow claim |
| Radio Science (AGU / URSI) | Propagation physics and measurement comparison | Natural home for long-term time-variability results |
| IEEE Open Journal of Antennas and Propagation | Open access full paper | Code and data can be public alongside |
| ISART (NTIA/ITS) | Spectrum-policy audience; ITM's home institution | Good first venue; Paul 2003 was an ISART paper |
| ITU-R Study Group 3 contribution (via the US administration) | If a change improves a P-series method | Requires DBSG3-based testing |
| NTIA Technical Memorandum or Report | Full record with all data | Agency publication review applies |
| ML-for-science workshops at major ML conferences | Agent method and the honest-baseline protocol | The ESM study appeared at NeurIPS 2026 |

## 6. Reporting rules that apply

- **AI disclosure (IEEE).** IEEE allows AI-generated content if it is
  disclosed in the acknowledgments: name the AI system, the sections where it
  was used, and the level of use
  ([IEEE CAS](https://ieee-cas.org/publications/using-ai-generated-content-ieee-article)).
  The rule covers text, figures, images, and code
  ([IEEE guideline as quoted by SANER 2026](https://conf.researchr.org/attending/saner-2026/Guidelines+for+Artificial+Intelligence+%28AI%29-Generated+Text)).
  Authors remain responsible for all content
  ([Enago summary](https://www.enago.com/responsible-ai-movement/publisher-ai-guidelines/ieee-ai-guidelines/)).
  Because the agent writes code that produces the results, the disclosure
  must describe that role, not just editing help.
- **REFORMS checklist.** A 32-item checklist for ML-based science, built by
  consensus of 19 researchers across fields
  ([Kapoor et al., Science Advances 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11092361);
  [site](https://reforms.cs.princeton.edu/)). It is written for ML models,
  but most items (data, splits, leakage, metrics, reproducibility) map
  directly onto this harness. Include the filled checklist as a supplement.
- **Leakage.** The eight leakage types in
  [Kapoor and Narayanan (2023)](https://pmc.ncbi.nlm.nih.gov/articles/PMC10499856)
  should be addressed one by one in the methods section.
- **Prior publication.** IEEE requires authors to disclose earlier
  conference versions and state how a new submission differs
  ([IEEE Author Center](https://journals.ieeeauthorcenter.ieee.org/become-an-ieee-journal-author/publishing-ethics/guidelines-and-policies/submission-and-peer-review-policies/)),
  so an ISART paper followed by a journal paper is fine if both say so.
- **Clearance.** As NTIA work, any external paper goes through agency
  publication review, and only public data and public sources are used,
  which this repo already enforces.

## 7. What a paper needs that the repo doesn't have yet

1. **Recalibrated-ITM baseline:** fit Tier 1 constants with `bayesopt` in
   the same cross-validation, with no agent involved.
1. **Results from at least one full batch of submodel swaps** with the
   per-change log.
1. **Lockbox results** on ITS Phase 1, low antenna, and DBSG3 VI-2, run once.
1. **An ablation of the agent:** the same batch run by the Haiku worker
   alone versus the planner-worker split, and versus a human doing the same
   swaps, to show what the agent contributed.
1. **A reproducibility package:** this repository at a tagged commit, with
   profile CSVs, link tables, and a one-command rerun.

A possible title: *"Agent-guided submodel replacement in the Irregular
Terrain Model, validated on held-out ITS measurements."*
