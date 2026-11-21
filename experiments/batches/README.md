# Batch plans

The planner (Opus or Fable) writes one file per batch, `BNN.md`, before the
worker (Haiku) starts. Each experiment in a batch has:

- ID and short name (`NNN-short-name`)
- Tier and the `itm_p2p_core_exp.m` function it touches
- The exact change: the `params_exp.m` values, or the code to switch on
- Public source, with section and equation numbers
- Physical rationale, one sentence
- Predicted effect per site and band, and on the long-term shape score
- What would make the worker stop and hand back

After the batch, the planner appends a short analysis: what was kept, which
predictions failed, how the best compares with the recalibrated baseline
R01, and what that implies for the next batch. The planner also appends one
row to `results/batch_stability.tsv`. If the share of kept changes later
reverted, or of physics or censored-gate failures, rises from the previous
batch, run the three-reviewer pass before the next batch.
