# ITM_ai_experiment

A sandbox for testing changes to the Irregular Terrain Model (ITM,
Longley-Rice) against measured propagation loss. An AI agent proposes
physically justified changes to a copy of the MATLAB ITM and keeps only the
ones that reduce error on held-out measurement sites.

- [docs/FLOW.md](docs/FLOW.md): flow diagrams of the system and of one
  experiment.
- [FRAMEWORK.md](FRAMEWORK.md): prior work, data, evaluation protocol,
  change catalog, experiment loop, guardrails, and roadmap.
- [program.md](program.md): the agent's standing instructions.
- [CLAUDE.md](CLAUDE.md): rules and commands for agents working here.
- [docs/LITERATURE_REVIEW.md](docs/LITERATURE_REVIEW.md): harness design,
  and replacement parts for ITM from P.452, P.2001, P.526, and the literature.
- [docs/AGENT_OPTIMIZATION_LITERATURE.md](docs/AGENT_OPTIMIZATION_LITERATURE.md):
  how agents are set up to optimize against a score, and how those loops fail.
- [docs/PUBLICATION_LITERATURE.md](docs/PUBLICATION_LITERATURE.md): could
  this be published; related work outside propagation and on AI with
  propagation models; venues and reporting rules.
- [experiments/LOG.md](experiments/LOG.md): one entry per experiment.
- [results/results.tsv](results/results.tsv): one row per experiment.

Baseline: [nicklasorte/matlab_itm](https://github.com/nicklasorte/matlab_itm),
a port of [NTIA/itm](https://github.com/NTIA/itm) that matches the C++
reference to within 4 × 10⁻¹³ dB.

Scored on ITS Phase 2 spot measurements (50 % time) and ITS long-term time
distributions (1 % to 99 % of time). Runs in MATLAB R2025b.

Starting point on the ITS Phase 2 measurements (76–9190 MHz, 426 paths): ITM
has 16.7 dB RMS error, versus 12.7 dB for P.452 and 12.6 dB for P.2001.
