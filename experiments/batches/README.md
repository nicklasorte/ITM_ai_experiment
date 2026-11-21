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
predictions failed, and what that implies for the next batch.
