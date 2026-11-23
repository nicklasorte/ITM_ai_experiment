---
name: itm-smoke-test
description: Model-only change of an ITM_ai_experiment candidate against best on every row, exported as a deltas CSV for the history-matching screen. Use before registering any batch; never reads measured loss.
---

# Model-only smoke test

The smoke test shows what a change does to predictions, before any score
exists. It reads geometry, frequency and climate columns only. Reading a
`meas_*` column here would contaminate the registered predictions.

## Steps

1. **Settings.** Build the parent's cfg from its launcher overrides (707's
   five: `diffraction=delta_cascaded_isolated`,
   `diffraction_bound=itm_troposcatter_line`,
   `terminal_clutter=p2108_height_gain`,
   `terminal_clutter_base=clutter_height`,
   `terminal_clutter_frange=hold3`), and the candidate's cfg as the parent
   plus its new switches.
2. **Rows.** Every in-scope row, using the same rule as `baseline_ok` in
   `eval/run_eval_rev1.m`: Phase 2 at 50 % time, long-term at all nine
   percentages in `settings_rev1().p_all`. Pass `cfg.row` with `set`,
   `siting`, `reversed=false` and `path_id`, as `run_rows` does.
3. **Run.** Call `itm_p2p_core_exp` for parent and candidate on each row.
   Phase 2 is about 6 ms a row per setting, so one setting over all 16,805
   rows takes about 100 s. Run it as a batch job, or interactively in chunks
   under 70 s that stop on a timer and resume. Fail with `error()` on any
   non-finite value.
4. **Check the parent.** The parent's smoke predictions must match its
   stored `predictions_*.csv` (`var_lb_*`) to 1e-9 dB. If they don't, the
   settings are wrong; stop.
5. **Export.** Write `experiments/batches/<batch>_deltas_<id>_rev1.csv` with
   columns `link_id`, `d_50`, and `d_0_01` … `d_99_99` (NaN for Phase 2
   rows). `d` is candidate minus parent prediction. See
   `b12_deltas_1201_rev1.csv`.
6. **Summarize for the plan.** By site and ITM mode for Phase 2, and by
   time percentage for long-term: rows changed (|d| > 0.01 dB), mean
   change, and range. Report no error against measurements.

Then run the history-matching screen (`itm-register-batch`, step 7).
