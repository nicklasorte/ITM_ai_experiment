# How to score the lockbox (for Nick)

This runs the panel in [registration rev 2](LOCKBOX_REGISTRATION_rev2.md),
sections 2 and 3, and applies section 4's rule (as amended on 2026-11-24).
Only Nick runs it: the agent never sees lockbox data or results until Nick
records them.

The scorer was checked on 400 development rows with no clutter
(`TestOnly=true`): 707 matched the stored predictions to 0.0 dB, and R02
matched stock ITM to 1e-12 dB.

## What you need

- For each lockbox set, the converted link table, with the same columns as
  `data/links/phase2_links_rev1.csv`. Required: `link_id`, `path_id`,
  `f_mhz`, `htx_m`, `hrx_m`, `pol`, `climate`, `N_0`, `meas_lb_db`, and
  `itm_lb_50` (stock ITM). Optional: `censored`, `site` (for the
  site-cluster bootstrap), `itm_error`, `p452_lb_50`, `p2001_lb_50`.
- Its 30 m profiles: an index CSV (`path_id`, `n_points`, `spacing_m`,
  optionally `sha256`) and a folder of `<path_id>.csv` files with one
  column, `h_m`.
- MATLAB on the Mac, with `matlab_itm` at 9bd6a4e in `~/github/matlab_itm`.

Your everyday `~/github/ITM_ai_experiment` isn't a clean checkout, so the
scorer would refuse to run there. The agent made two clean clones on the Mac
on 2026-11-24 and checked them:

- `~/github/ITM_lockbox_best`, branch `best-lockbox`, at 2baa02b (707, R03)
- `~/github/ITM_lockbox_r02`, branch `r02-lockbox`, at e76ca9d (R02)

## Steps (MATLAB only, no shell)

```matlab
gh = fullfile(getenv('HOME'), 'github');
main_dir = fullfile(gh, 'ITM_ai_experiment');            % holds the scorer
best_dir = fullfile(gh, 'ITM_lockbox_best');             % 707 and R03
r02_dir  = fullfile(gh, 'ITM_lockbox_r02');              % R02

% Per set: fill in these three paths and a short name
links = "<lockbox link table .csv>";
pidx  = "<profile index .csv>";
pdir  = "<profile folder>";
name  = "low_antenna";                                   % or "phase1_vhf", "dbsg3"
out   = fullfile(gh, 'ITM_lockbox_out');

% 707 (best, no overrides)
restoredefaultpath; addpath(fullfile(best_dir,'eval'), fullfile(best_dir,'itm_variant'), fullfile(main_dir,'experiments','lockbox'));
setenv('ITMEXP_OVERRIDES', '');
score_lockbox_rev1(links, pidx, pdir, out, Model="707", SetName=name);

% R03 (best, Bullington)
setenv('ITMEXP_OVERRIDES', '{"diffraction":"delta_bullington"}');
score_lockbox_rev1(links, pidx, pdir, out, Model="R03", SetName=name);
setenv('ITMEXP_OVERRIDES', '');

% R02 (e76ca9d; the scorer sets time_minus_scale = 0.8)
restoredefaultpath; addpath(fullfile(r02_dir,'eval'), fullfile(r02_dir,'itm_variant'), fullfile(main_dir,'experiments','lockbox'));
score_lockbox_rev1(links, pidx, pdir, out, Model="R02", SetName=name);
```

Each call checks the commit and the overrides and stops with an error if
either is wrong. Long sets can run as `batch` jobs with the same arguments.

## Summarize and record

In a terminal (not from the MATLAB MCP session):

```text
python3 -I ~/github/ITM_ai_experiment/experiments/lockbox/summarize_lockbox_rev1.py ~/github/ITM_lockbox_out low_antenna low_antenna
python3 -I ~/github/ITM_ai_experiment/experiments/lockbox/summarize_lockbox_rev1.py ~/github/ITM_lockbox_out phase1_vhf vhf
python3 -I ~/github/ITM_ai_experiment/experiments/lockbox/summarize_lockbox_rev1.py ~/github/ITM_lockbox_out dbsg3 report_only
```

Each writes `<name>_summary_rev1.md` with the verdict (CONFIRMS, FAILS or
INCONCLUSIVE), the calibration check, and the secondary tables. Then add one
LOG entry with the three verdicts, the summaries, and the `scorer_md5` from
any `_meta.json`, whatever they show. That closes the phase.
