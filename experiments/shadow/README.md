# Shadow comparisons

Before a kept variant informs any study, briefing, or filing, run it in
shadow beside stock ITM (`matlab_itm` at the pinned commit) on one real
study. Use one folder per study, `experiments/shadow/<study>/`, with:

- `inputs.md`: the study, its public inputs, and the variant commit
- `paired_predictions.csv`: one row per link, stock and variant loss in dB
- `summary.txt`: median and 95th-percentile difference, and every case
  where the difference changes a protection, coordination, or exclusion
  decision

Nick reads the summary before the variant is used outside this repository.
Studies that rely on controlled or non-public inputs don't go here; run
them privately and record only that the shadow check passed.
