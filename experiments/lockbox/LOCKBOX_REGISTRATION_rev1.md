# Lockbox registration, rev 1

Written by Claude Opus 5.5 on 2026-11-24, before any lockbox number exists.
The agent has not read, and doesn't read, lockbox data or metrics.
Nick scores the lockbox once (FRAMEWORK.md, Tier B, and roadmap phase 4).
Decisions behind this file: phase plan rev 3, section 5, approved by Nick
on 2026-11-24 ("All approved").

The trigger was met when B18 closed without a keep, so this file is the
registration that has to be fixed first.

## 1. Frozen model

| Item | Value |
| --- | --- |
| Best run | `707-cascaded-isolated-clutter-at-r` (the only keep) |
| `best` branch commit | `2baa02b26bc3288269d45d3f69934ac864b5325a` (main `e76ca9d` plus 707's five switch lines) |
| `itm_variant/params_exp.m` MD5 on `best` | `1a122bfbe9796e9ae9dee920c8962dff` |
| `itm_variant/itm_p2p_core_exp.m` MD5 | `45aefdb9a6e58cda7e43532961f305fd` |
| `itm_variant/multi_edge_diffraction_rev1.m` MD5 | `bc09b4a28a3fcb32f3f1e474efb2a8bf` |
| Check that the code reproduces 707 | Every B18 smoke test recomputed 707's 16,805 Phase 2 and 548 long-term predictions on this code and matched the stored run to 1e-9 dB; parity at stock defaults 6.8e-13 dB |
| matlab_itm | `9bd6a4e` (pinned in `eval/itm_exp_paths_rev1.m`) |

No model edit after this file is committed. If the frozen files' MD5s
change before the lockbox is scored, this registration is void and is
redone.

## 2. Panel

Each model runs with the overrides below (the launcher's JSON;
`params_exp.m` defaults otherwise). R02 uses its fitted constants
(`experiments/R02-constrained-recalibration/params_by_fold.csv`: one moved,
`time_minus_scale` 0.8, the same on all five folds).

| Model | Role | Overrides |
| --- | --- | --- |
| 707 (`best`) | The result | `{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}` |
| Stock ITM | Baseline | none (public `itm_p2p_rev1`) |
| R02 | Recalibration baseline (FRAMEWORK.md) | none, with `time_minus_scale` = 0.8 |
| R03 | Continuous comparator (added by decision 4) | `{"diffraction":"delta_bullington","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}` |

R03 on the development set (run 2026-11-24, reference, not a keep
candidate): composite 11.0, screened 9.6 (707: 12.5, 9.9), censored
violations 58.0 % (707: 22.8 %), sites R1 8.8, R2 17.9, R3 6.4, VA 13.5,
battery pass; real-path height excess 4.2 dB (707: 27.0); paired screened
gain over 707 +0.27 dB (95 % −0.14 to +0.73).

## 3. Row inputs

- Profiles: 30 m, from the same builder as the development set
  (`data/export_profiles_rev1`), transmitter first.
- Lockbox rows carry no siting flag, so `cfg.row.set` is empty: the
  terminal clutter term is zero, as on long-term rows. The same holds for
  the land-cover switches, which are off in the whole panel.
- Fixed inputs as `eval/settings_rev1.m` (ε 25, σ 0.02 S/m, mdvar 13, 50 %
  confidence); climate and N_0 from each set's own records.

## 4. Metrics, per set

1. RMS and mean error (predicted minus measured), path-weighted, overall and
   by frequency band and by set-specific stratum (for the low-antenna set:
   site; for Phase 1: terrain region).
2. The composite parts that apply: cell-balanced RMS at 50 % by band.
3. If a set has censored results: share of censored bounds violated, and the
   cell RMS with censored rows scored as bounds (the E2 definition, PR #11).
4. Each model against stock ITM and against 707, with a paired bootstrap by
   path (95 %).

## 5. Predictions (planner, from development data only)

| Set | Prediction | Evidence |
| --- | --- | --- |
| ITS low antenna height (230 and 416 MHz, antennas under 3 m) | 707's RMS is at least 4 dB lower than stock ITM's | Development rows with the lower antenna at 3 m or under, 150 MHz to 1 GHz: 707 RMS 8.3 to 12.3 dB, stock 14.9 to 21.2 |
| ITS Phase 1 VHF (20 to 100 MHz) | 707 doesn't beat stock ITM on RMS, and 707's mean error is positive (too much loss) by 3 dB or more | 76 MHz development rows (VA, 452): 707 +6.7 / 9.6 dB, stock −1.2 / 9.3 |
| ITS Phase 1 VHF | R03 is closer to stock than 707 is | 76 MHz: R03's ancestor 703 +2.3 / 7.9 |
| DBSG3 Table VI-2 | No prediction (location medians, a different quantity) | — |
| All sets | R02 within 0.5 dB of stock ITM | R02 moved one time-spread constant; at 50 % it equals stock |

## 6. Known defects, stated before the result

1. **Principal-edge jump** (P.526-11 three-edge cascade): up to 30.6 dB for a
   0.05 m change in antenna height on R2-020 T1 and T2; real-path height
   check 119 row-ends over the 1 dB limit on 10 paths; pointwise continuity
   263 steps over the limit, worst 23.2 dB. Candidate 1801 removes it but
   adds 1.08 points of censored violations (the repair rule allows 1.0), so
   it isn't in the frozen model (B18).
2. **Height inversion** from the smooth-surface construction (P.452-18
   section 5.1.6.3): up to 4.5 dB of extra loss when an antenna rises, on a
   few R1 paths. No public fix found (B18: 1803 makes it worse).
3. **VHF pessimism**: section 5's second prediction.
4. **Clear terrain above 3 GHz** is about 13.6 dB optimistic in development
   data for every model in the archive: clutter the 30 m terrain can't show.

## 7. Before Nick scores

1. Three independent reviewer sessions on the frozen model (FRAMEWORK.md,
   Agent roles), and one Fable read of the kept chain. Each tries to break
   707; findings that two of three report are fixed or recorded before the
   lockbox.
2. PR #11 (E2) merged or not: either way, this file's metrics section is
   what's reported.
3. Nick confirms this file, then scores the panel once and records the
   result in the LOG, whatever it shows.

After the lockbox, the phase ends (phase plan rev 3, section 5). The
write-up reports the lockbox figures as the result and the development
figures as the search record.
