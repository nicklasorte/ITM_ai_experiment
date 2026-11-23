# History-matching screen and model floor

Planner: Claude Opus 5.5, 2026-11-22. Requested by Nick after the Claude
Science ideas note (idea 7). Tools: `experiments/batches/hm_screen_rev1.py`
and `experiments/batches/model_floor_rev1.py`. Outputs:
`results/hm_screen_retro_rev1.tsv` and `results/model_floor_rev1.csv`.

## Results

- **B12 can't pass.** From model-only smoke-test deltas, the largest
  possible composite gain over 707 is 0.128 dB for 1201 (curved-Earth
  phase) and 0.008 dB for 1202 (two-leg variability). The gate is 0.3 dB.
  This is a bound, not an estimate: no outcome of the runs can pass.
  Proposed: record both as screened out and don't spend the batch queue on
  them. That's Nick's call, because B12.md registered them as runs.
- **The screen never rejects a run that passed.** Across 36 past runs it
  ruled out 4: 501, 503, 602 (against stock) and 709 (against 707). All four
  were real rejections. Every actual gain lies inside its interval.
- **The screen doesn't catch harm from big changes.** B11 (711, 712)
  changed losses by several dB on many rows, so its interval was wide and it
  wasn't ruled out. My earlier note that B11 "touched too few rows" was
  wrong: B11 failed by doing harm. The emulator's central estimate did
  predict it: −0.84 dB for 711 (actual −0.77) and −0.33 dB for 712 (actual
  −0.38).
- **The model floor is weak.** The only identical-input repeats in the data
  are 21 long-term groups. They allow a composite as low as 0.33 dB against
  707's 12.5 dB. Phase 2 has no repeats, so its floor can't be identified.
  Measurement repeatability isn't what limits progress.

## Method

### Where it comes from

History matching is used to tune climate models, petroleum reservoir models
and galaxy-formation models against observations. Instead of searching for
one best input, it uses a cheap emulator with stated uncertainty and an
implausibility measure to rule out regions of input space before spending
expensive runs. It treats structural model error as a separate term, model
discrepancy. Williamson and colleagues used it to find structural biases in
the HadCM3 climate model.

### The emulator

For one score cell with path weights w (sum W), let e be the parent's error
(prediction minus measurement) and d the candidate's change (candidate
prediction minus parent prediction). Then the candidate's weighted mean-square
error is exactly:

    MSE' = MSE + 2 (m * dbar + c) + q

- m: the parent's weighted mean error in the cell.
- dbar and q: the weighted mean and mean square of d.
- c: the weighted covariance of e and d.

A model-only smoke test gives d without reading any measurement, and the
parent's run gives m and MSE. Only c is unknown, and Cauchy-Schwarz bounds
it: |c| <= s_e * s_d. So each cell's RMS lies in a known interval. The
composite, the screened composite and each site RMS are means or weighted
RMS values of cells and rows (`eval/score_rev1.m`), so they lie in known
intervals too.

### Two outputs

- **The bound** (c at its limits) gives the verdict:
  - CANNOT_PASS: the largest possible composite or screened gain is under
    0.3 dB.
  - CERTAIN_HARM: some site rises by more than 0.5 dB even in the best case.
  - NOT_RULED_OUT: anything else.
- **The required correlation** is the uniform correlation ρ between a
  change and the parent's existing error that would give a 0.3 dB gain:
  - ρ = 0 is the emulator's central estimate, a change unrelated to the
    current error.
  - ρ = 1 is the bound.
  - A change only helps if it lines up with the error that's already there.
    The required ρ says how strongly it must.

### Calibration of ρ from past runs

| Comparison | Effective ρ achieved |
| --- | --- |
| Delta-form and blocked-path diffraction changes against stock (201, 202, 401, 402, 5xx, 6xx, 7xx) | 0.5 to 0.8 |
| First-generation changes against stock (101–105, 301) | −0.2 to 0.5 |
| Incremental changes on 707 (709, 711, 712) | −0.04 to 0.05 |
| 708 (Deygout instead of the cascade) on 707 | 0.46 |

Incremental changes on top of 707 have so far had no correlation with
707's remaining error. For those changes the central estimate has been
accurate to within 0.06 dB (709, 711, 712). A proposal that needs ρ above
about 0.5 against 707 should explain why its change would line up with the
current error that strongly. This threshold is advisory and based on few
points; it isn't a gate.

## The model floor

Any model whose output depends only on its inputs (terrain profile,
frequency, antenna heights, polarization, climate, N_0, siting) must give
rows with identical inputs one prediction. The spread of their measurements
around the group's weighted mean is error no such model can remove: the
Bayes error of the fixed inputs. For a cell, the floor is the square root of
the within-group weighted sum of squares over the cell's total weight. It's
a strict lower bound on the cell RMS, and it reads only measurements.

- **Long-term.** 21 groups measure the same path, frequency and heights in
  different years or for different record lengths. Floors range from 0 to
  4.3 dB per cell (largest: level at 1 %, 0.3–1 GHz, 300 km and beyond).
  The largest share of a 707 cell's mean-square error the floor explains is
  27 % (shape at 10 %, 0.3–1 GHz, 300 km and beyond). In most cells it's
  under 5 %.
- **Phase 2.** No two rows share all inputs, so the floor is set to 0 (no
  constraint). The tool checks this and stops if repeats ever appear.
- **What the floor doesn't include:** measurement calibration uncertainty
  and location uncertainty of 1960s sites. These would raise the floor, but
  the repo has no cited figures for them. TODO: find published measurement
  accuracy in the ITS reports for Phase 2 and the long-term records before
  using either.

`hm_screen_rev1.py --floor results/model_floor_rev1.csv` clamps each cell's
best case at its floor. Because the floor is weak, it changes no verdict
today.

## How to use the screen in the loop

1. Write the batch plan and run the model-only smoke test, as now. Export
   the per-row change against `best` as a CSV with `link_id`, `d_50` and
   `d_<p>` for the long-term percentiles (see
   `experiments/batches/b12_deltas_1201_rev1.csv`).
2. Run:

   ```bash
   python3 experiments/batches/hm_screen_rev1.py \
     --parent experiments/<best-run> --delta <deltas.csv> \
     --floor results/model_floor_rev1.csv
   ```

3. If the verdict is CANNOT_PASS or CERTAIN_HARM, don't run the experiment.
   Record it in the plan as screened out, with the bound.
4. If it's NOT_RULED_OUT, register the central estimate and the required ρ
   with the predictions, then run as usual.

The skill `experiments/skills/itm-register-batch` includes this step.

## Limits

- **Composite and site gates only.** The screen doesn't bound the censored
  gate (censored rows are excluded from the error score) or the physics
  battery. Both still need the run.
- **Wide intervals for big changes.** The bound is tight only when the
  change is small. That's where it saves the most runs: the small,
  physically clean changes that keep falling short.
- **The uniform ρ is a summary.** Real correlation differs by cell. The
  per-cell intervals are exact; ρ is for interpretation.
- **Reads the parent's residuals.** The parent's per-cell mean and spread
  come from development data, the same class of evidence the plans already
  cite (site means and RMS). It never reads lockbox data or the
  candidate's error.
- **Stored screened scores predate the 36-link screen.** Runs before PR #5
  stored screened scores with the 14-link list. The screen always uses the
  current list, so its screened figures for old runs differ from their
  stored ones. The composite parts reproduce `metrics.json` exactly (707:
  12.505 dB).

## Sources

- Craig, Goldstein, Seheult and Smith (1997), history matching in reservoir
  modelling; summarized in [Using history matching for prior choice](https://arxiv.org/pdf/1605.08860).
- Williamson et al., [Identifying and removing structural biases in climate models with history matching](https://nora.nerc.ac.uk/id/eprint/509284/1/Williamson_et_al_StructErrorPaper.pdf).
- Williamson et al., [History matching for exploring and reducing climate model parameter space](https://eprints.soton.ac.uk/359716).
- [Emulator diagnostics and premature convergence in multi-wave history matching](https://pmc.ncbi.nlm.nih.gov/articles/PMC5157755).
