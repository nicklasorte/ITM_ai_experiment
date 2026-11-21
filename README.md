# ITM_ai_experiment

A sandbox for testing changes to the Irregular Terrain Model (ITM,
Longley-Rice) against measured propagation loss. An AI agent proposes
physically justified changes to a copy of the MATLAB ITM and keeps only the
ones that reduce error on held-out measurement sites.

- [FRAMEWORK.md](FRAMEWORK.md): prior work, data, evaluation protocol,
  change catalog, experiment loop, guardrails, and roadmap.
- [program.md](program.md): the agent's standing instructions.
- [experiments/LOG.md](experiments/LOG.md): one entry per experiment.
- [results/results.tsv](results/results.tsv): one row per experiment.

Baseline: [nicklasorte/matlab_itm](https://github.com/nicklasorte/matlab_itm),
a port of [NTIA/itm](https://github.com/NTIA/itm) that matches the C++
reference to within 4 × 10⁻¹³ dB.

Starting point on the ITS Phase 2 measurements (76–9190 MHz, 426 paths): ITM
has 16.7 dB RMS error, versus 12.7 dB for P.452 and 12.6 dB for P.2001.
