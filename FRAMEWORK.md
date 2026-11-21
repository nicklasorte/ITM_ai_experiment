# ITM measurement-tuning framework

This document defines how this repository tests changes to the Irregular
Terrain Model (ITM, Longley-Rice) against measured propagation loss, and how an
AI agent proposes and keeps changes by hill climbing. It covers prior work,
the data, the evaluation protocol, the catalog of changes, the experiment
loop, and the guardrails that keep the loop from overfitting.

Status: Rev 2, 2026-11-21. Scaffolding is in `data/`, `eval/`, and
`itm_variant/`; see [Roadmap](#roadmap).

Decisions (Nick, 2026-11-21):

- **Terrain source is fixed.** Every model sees the same profile; terrain
  source and profile spacing are never experiment variables.
- **Replacement parts come from P.452, P.2001, P.526, or the literature**, or
  are written here from the literature. See
  [docs/LITERATURE_REVIEW.md](docs/LITERATURE_REVIEW.md) for the ranked list.
- **Time variability is scored**, using the ITS long-term measurements.
- **Runs use MATLAB R2025b on Nick's Mac.**

Background reading: [docs/AGENT_OPTIMIZATION_LITERATURE.md](docs/AGENT_OPTIMIZATION_LITERATURE.md)
(how agent optimization loops are built and how they fail).

## Goal

Find changes to ITM point-to-point mode that reduce prediction error against
measured basic transmission loss **on measurements the change was not tuned
on**, where each change has a physical explanation that a propagation engineer
would accept.

Success has three tiers:

1. **Minimum:** a reproducible harness, a frozen baseline, and a ranked
   diagnosis of where ITM error comes from.
1. **Target:** a variant that beats baseline ITM on every held-out site and
   matches or beats P.452 and P.2001 on path-weighted RMS error.
1. **Stretch:** a short list of physically motivated ITM changes, each with
   held-out evidence, written up in a form that could support an ITU-R or
   NTIA/ITS contribution.

## What the baseline looks like

These numbers come from the existing comparison in
`nicklasorte/matlab_itm` (commit `9bd6a4e`,
`docs/model_comparison/chart_data/its_phase2_results.csv`), which runs ITM,
P.452, and P.2001 at 50 % of time on the ITS Phase 2 measurements. Error is
predicted minus measured basic transmission loss, so positive means the model
predicts too much loss. Censored results (signal below sensitivity) are
excluded.

| Model | Rows | Mean (dB) | Std (dB) | RMS (dB) | Path-weighted RMS (dB) | Worst set × band cell RMS (dB) |
| --- | --- | --- | --- | --- | --- | --- |
| ITM | 14,760 | +0.8 | 16.7 | 16.7 | 16.4 | 38.2 |
| P.452 | 14,308 | −4.6 | 11.8 | 12.7 | 14.6 | 26.1 |
| P.2001 | 14,760 | −4.5 | 11.8 | 12.6 | 13.8 | 26.1 |

ITM error by subset:

| Subset | Rows | Mean (dB) | RMS (dB) |
| --- | --- | --- | --- |
| R1, Colorado plains | 4,489 | +1.8 | 13.2 |
| R2, Colorado mountains | 2,560 | +9.2 | 29.9 |
| R3, North Table Mountain | 5,149 | +0.1 | 8.7 |
| VA, Virginia piedmont | 2,562 | −8.2 | 16.3 |
| 1–3 GHz | 1,990 | −0.5 | 18.1 |
| 3–6 GHz | 2,091 | +3.3 | 22.1 |
| 6–10 GHz | 1,696 | +2.8 | 21.4 |
| ITM mode near 3 GHz: line of sight | 13,124 | +0.2 | 15.7 |
| ITM mode near 3 GHz: diffraction | 1,402 | +3.1 | 21.3 |
| ITM mode near 3 GHz: troposcatter | 234 | +19.1 | 33.7 |

What this tells us:

- **ITM has little overall bias but a large spread.** A constant offset fitted
  on three sites and applied to the fourth does not help (R1 13.2 → 13.1 dB,
  R2 29.9 → 30.3 dB, VA 16.3 → 17.7 dB). The error depends on the path, so
  gains must come from changing how ITM treats geometry, not from shifting it.
- **The error is concentrated.** Mountains (R2), frequencies above 3 GHz, and
  paths ITM classifies as troposcatter (75–120 km here) carry most of
  the squared error. These are the first targets.
- **P.452 and P.2001 set the bar.** Both use multi-edge diffraction
  (Bullington-type) on the actual profile. Their roughly 4 dB lower spread is
  a rough measure of what better diffraction alone may be worth.

## How others approach this problem

### NTIA/ITS model-versus-measurement comparisons

- ITM itself was checked against measurements from the start.
  [Longley and Reasoner (1970), ERL 148-ITS 97](https://www.its.ntia.gov/publications/details?pub=2772)
  compared the 1968 method with measurements from 20 to 10,000 MHz to set
  its limits of applicability.
- [Paul (2003), ISART SP-03-401](https://its.ntia.gov/publications/download/2003%20ISART%2003-401%20Paul.pdf)
  compared ITM and TIREM on 13 datasets with more than 41,000 measurements.
  Overall statistics were similar, but single-path errors differed by 20 dB
  or more. The paper names two concrete ITM levers:
  - The **effective antenna height** drives ITM error. Errors are largest
    when effective heights far exceed structural heights, and the best value
    often lies between the two.
  - Neither model accounts for **land use, vegetation, or buildings**.
  It also warns that many measurements share paths and are correlated.
- [Hammerschmidt and Johnk (2017)](https://www.its.ntia.gov/publications/details?pub=3185)
  showed that the choice of terrain database changes ITM predictions and
  therefore the clutter loss you infer from measurements. Terrain input is a
  variable to control, not a constant.
- Broadcast work by Kasampalis et al.
  ([2015, BMSB](https://bura.brunel.ac.uk/handle/2438/34053?mode=full))
  found ITM accurate in most mountainous cases but underestimating field
  strength in some long fringe paths, where multiple knife-edge methods did
  better.

### ITU-R Study Group 3

- SG3 tests P-series methods against the
  [DBSG3 databanks](https://www.itu.int/en/ITU-R/study-groups/rsg3/Pages/dtbank-dbsg3.aspx),
  which hold measurements accepted under
  [Rec. ITU-R P.311](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.311-14-201309-S!!MSW-E.docx),
  whose Annex 1 gives the testing criteria for comparing methods. SG3 also
  publishes
  [guidelines for testing terrestrial prediction methods](https://www.itu.int/oth/R0A04000008/en)
  (Doc. 3M/FAS/2).
- [Willis, Craig, and Thomas (RAL)](https://its.ntia.gov/media/33514/wil_m-08.pdf)
  on improving P.1812: differences between models were hidden by measurement
  error, data are not all of equal weight, and a model risks being tuned to
  the most numerous measurement set. This framework adopts both lessons:
  filter the data, and weight by path and site rather than by row.

### Correction factors and machine learning

- [Varner et al.](https://par.nsf.gov/servlets/purl/10409412) applied
  minimum mean-squared-error correction factors to TIREM, which is based on
  ITM, and cut the error standard deviation by as much as 6.9 dB on some
  Utah campus datasets. This is the simplest data-driven fix and the right
  baseline to beat with a physics change.
- Canada's CRC (Ethier, Dempsey, and others) trains path-loss models on
  Ofcom's UK drive-test data: 8.2 million measurements at six bands from 449
  to 5850 MHz
  ([arXiv 2405.10006](https://arxiv.org/html/2405.10006v1)). Two practices
  matter here:
  - They rejected random splits within a city because too much of each
    drive test leaks into training, and used **leave-one-city-out**
    holdouts.
  - P.1812 scored 11.85 dB median RMS, but the authors note it was developed
    on the same Ofcom data. **A model tuned on a dataset can't be validated
    on it.**
- "Delta learning" trains a regressor on the residual of a fast baseline
  model (free space, P.1546, P.1812, P.452) instead of replacing it
  ([Technologies 14, 363](https://maxwell.sze.hu/~ungert/technologies-14-00363-v2.pdf)).
  Here a residual model is a diagnostic. If it finds structure in the
  residuals, that structure tells the agent which physics to change.

### AI agents that improve code against an evaluator

- [FunSearch](https://pmc.ncbi.nlm.nih.gov/articles/PMC10794145) pairs an LLM
  with a systematic evaluator that guards against confabulated or incorrect
  ideas, and searches for programs rather than answers.
- [AlphaEvolve](https://arxiv.org/abs/2506.13131) has LLMs make direct
  changes to an algorithm's code and keeps improving it on feedback from one
  or more evaluators. Open versions include OpenEvolve and ShinkaEvolve.
- Karpathy's **autoresearch** (March 2026) is the closest template: an agent
  edits one file, runs a fixed-budget experiment, reads a validation metric,
  and keeps or reverts the commit (a "ratchet"). Its three-file contract
  separates an immutable evaluator, the one file the agent edits, and a
  `program.md` that only the human edits. A stated rule is that a small gain
  that adds ugly complexity is not worth it
  ([DataCamp guide](https://www.datacamp.com/tutorial/guide-to-autoresearch)).

### What this framework takes from each

| Practice | Source | How it shows up here |
| --- | --- | --- |
| Error = predicted − measured; report mean, std, RMS | ITS, ITU-R SG3 | `eval/` reports all three by set, band, and ITM mode |
| Weight by path, not by row | Paul 2003; Willis | Path-weighted RMS; each set × band cell counts equally |
| Hold out whole sites | CRC city holdouts | Leave-one-site-out cross-validation |
| Don't validate on tuning data | CRC on P.1812 | Sealed lockbox datasets, evaluated once |
| Effective height and multi-edge diffraction are known levers | Paul 2003; Kasampalis | First tiers of the change catalog |
| Immutable evaluator, single mutable file, human-owned instructions | autoresearch, FunSearch | `eval/` read-only, `itm_variant/` editable, `program.md` human-owned |
| Simpler wins ties | autoresearch | Complexity cost in the acceptance rule |

## Repository layout

```text
ITM_ai_experiment/
├── FRAMEWORK.md          This plan (human-owned)
├── program.md            Instructions for the agent (human-owned)
├── CLAUDE.md             Rules and commands for any agent working here
├── docs/
│   ├── FLOW.md                         Flow diagrams (Mermaid)
│   ├── LITERATURE_REVIEW.md            Harness design and ITM replacement parts
│   └── AGENT_OPTIMIZATION_LITERATURE.md How agent optimization loops are built and fail
├── data/                 Human-owned; read-only to the agent
│   ├── raw/              Unmodified public downloads (ITS Phase 2, ITS long-term)
│   ├── build_links_rev1.m  Builds links, profiles, splits, baseline and reference predictions
│   ├── links/            Link tables (CSV) and manifest with hashes
│   ├── splits/           Frozen fold assignments and their SHA-256
│   └── cache/            Profiles (not committed; rebuilt by build_links_rev1)
├── eval/                 Read-only to the agent
│   ├── run_eval_rev1.m          Runs the variant, checks parity, scores, writes experiments/<tag>/
│   ├── score_rev1.m             Composite, Phase 2, long-term level and shape scores
│   ├── physics_battery_rev1.m   Checks every variant must pass
│   ├── settings_rev1.m          Fixed inputs (ground constants, mdvar, time percentages, cells)
│   └── itm_exp_paths_rev1.m     Paths, and the pinned matlab_itm commit check
├── itm_variant/          The only code the agent edits
│   ├── itm_p2p_core_exp.m       Copy of the ITM v1.4 core with a cfg argument
│   ├── params_exp.m             Submodel switches and constants
│   └── private/                 Unchanged helpers from matlab_itm
├── experiments/
│   ├── LOG.md            Hypothesis ledger, one entry per experiment
│   └── NNN-short-name/   summary.txt, metrics.json, predictions for each experiment
└── results/
    └── results.tsv       One row per experiment (the ratchet record)
```

The baseline is the unmodified `itm_p2p_core.m` from `nicklasorte/matlab_itm`,
pinned by commit. That port matches the NTIA C++ to within 4 × 10⁻¹³ dB, so
the experimental copy starts bit-identical to the reference, and
`run_eval_rev1` confirms this before every run (baseline score must
reproduce exactly).

## Data

### Tier A: development set (in hand)

**ITS Phase 2 UHF spot measurements** (1965–1967), already parsed by
`compare_its_phase2_rev1.m` in `matlab_itm`. It has 426 usable paths, 14,760
uncensored results, four sites (R1, R2, R3, VA), 76–9190 MHz with six
frequencies from 1846 to 9190 MHz, receiver heights from 1 to 15 m, and
surveyed terrain profiles. It covers the 1–10 GHz range this work cares
about. Source:
[ITS legacy radio propagation data](https://its.ntia.gov/data/legacy-radio-propagation-data/).

Known limits: profiles were digitized from 1:24,000 and 1:62,500 maps;
horizontal polarization only; spot measurements, so the 50 % time value is
approximate; 2,045 censored results must be handled as lower bounds, not
dropped silently.

### Tier A2: ITS long-term time distributions (development set)

**ITS long-term data** (measured 1944–1969; Longley, Reasoner, and Fuller,
OT/TRER 16, 1971): 1,131 measured time distributions of hourly-median
attenuation at 0.01 % to 99.99 % of time, 40 MHz to 10 GHz, 10 to 1000 km.
296 rows are at 1–10 GHz. After filtering (free-space reference only, both
antenna heights known, H or V polarization, coordinates for both ends, not
over sea, distance consistent with coordinates), about 548 rows on 325
paths remain, 106 of them at 1–10 GHz (count from a Python check of the
filter rules; `data/build_links_rev1` writes the exact list to
`data/links/longterm_links_rev1.csv` and the dropped rows, with reasons, to
`longterm_dropped_rev1.csv`). The largest loss is 376 rows with no antenna
heights in the archive; OT/TRER 16 may list them, which would recover
data (TODO).

The public archive has no profiles, so profiles come from matlab_itm's
`itm_terrain_profile_rev1` at 30 m with its default source. That is the same
terrain source matlab_itm uses for every path; it is fixed, not a variable.

Known bias: ITM's time-variability curves were drawn from long-term data of
the same era, so the baseline's time score here is likely optimistic (see
[docs/LITERATURE_REVIEW.md §1.2](docs/LITERATURE_REVIEW.md)).

Folds: paths grouped by receiver site (0.1°), groups assigned to five folds.

### Tier B: lockbox sets (sealed until the end)

These are converted to the same link table but **not scored** until the
final evaluation:

| Dataset | Coverage | Why it is a good test |
| --- | --- | --- |
| ITS Phase 1 VHF spot | 20–100 MHz; Colorado plains, Colorado mountains, Ohio hills | Different band, same methods; tests whether a fix is frequency-general |
| ITS low antenna height | 230 and 416 MHz; Wyoming, Idaho, Washington; antennas under 3 m; more than 145 paths of 2–45 km | Paul (2003) found ITM's largest bias in Idaho; tests effective-height fixes |
| DBSG3 Table VI-2 | 30 MHz–3 GHz broadcast location medians; parsed by `compare_dbsg3_area_rev1.m` | Independent international data, different measurement method |

Lockbox rule: the agent never reads lockbox metrics. A human runs the lockbox
once per candidate that survives the development loop, and the result is
recorded whatever it shows.

### Tier C: later, needs clutter

These need a clutter term, which ITM doesn't have, so they belong to a
separate track (ITM plus P.2108 or a learned clutter term) after the
terrain-only work:

- **Ofcom UK sub-6 GHz propagation measurements** (2015–2018; 449–5850 MHz;
  [data description](https://www-bau.drcf.org.uk/siteassets/resources/documents/spectrum/uk-radiowave-propagation-measurement/sub-6ghz-propagation-measurement-data.pdf)).
  P.1812 was tuned on these, so they are a fair test of ITM but not of P.1812.
- **ITS 1.7 GHz Salt Lake City clutter measurements**
  ([Kozma 2022](https://its.ntia.gov/publications/download/Kozma_IEEE_2022.pdf)).
  TODO: confirm public data access.
- **ITS 3.5 GHz Denver and San Diego measurements**
  ([workshop series](https://its.ntia.gov/research/workshops/propagation-measurement-workshops-webinars)).
  TODO: confirm public data access.
- **ITS Green Bank signal-of-opportunity measurements**
  ([TM-26-583, August 2026](https://its.ntia.gov/publications/download/NTIA%20Technical%20Memorandum%20TM-26-583.pdf)).
  TODO: confirm public data access.

Only public, cleared data goes in this repository.

## Evaluation protocol

### Measured and predicted quantities

- Measured value: basic transmission loss `Lb` in dB, as built by the
  existing comparison scripts. For Phase 2,
  `Lb = 32.45 + 20 log10(f_MHz) + 20 log10(d_km) + A_measured`, median over
  runs.
- Long-term: `Lb_p = 32.45 + 20 log10(f_MHz) + 20 log10(d_km) + A_p` for
  each measured time percentage p.
- Predicted value: ITM basic transmission loss at reliability p (50 % for
  Phase 2; 0.01 % to 99.99 % for the long-term set), 50 % confidence, with
  the same profile, heights, polarization, climate, and refractivity for
  baseline and variant. Fixed inputs are in `eval/settings_rev1.m`
  (ε 25, σ 0.02 S/m, mdvar 13, as in `itm_pathloss_rev1`).
- Error `e = predicted − measured`.

### Splits

1. **Group by path.** A path is a transmitter site, receiver site, and
   profile. All frequencies and heights on a path stay in the same fold, so
   the evaluator never scores a path that a change was tuned on.
1. **Leave one site out.** The four folds are R1, R2, R3, and VA. For a
   change with fitted parameters, fit on three sites and score on the
   fourth. For a change with no fitted parameters, the fold score is the
   per-site score.
1. **Lockbox.** Tier B sets, scored only by a human, as described in
   [Tier B](#tier-b-lockbox-sets-sealed-until-the-end).

Fold assignments live in `data/splits/` and are frozen with a hash. The
evaluator refuses to run if the hash changes.

### Score

The number the agent climbs is the **composite score**, the mean of three
parts, each a cell-balanced, path-weighted RMS error in dB:

| Part | Data | Cells |
| --- | --- | --- |
| Phase 2 level at 50 % | ITS Phase 2 | site × frequency band |
| Long-term level | ITS long-term, at 1, 10, 50, 90, 99 % | band × distance class (< 100, 100–300, ≥ 300 km) |
| Long-term shape | ITS long-term, `(L_p − L_50)` at 1, 10, 90, 99 % | band × distance class |

The shape part removes the median error and tests only the time spread, so
a change can't win on time variability by fixing the median, or the reverse.
The 0.01 %, 0.1 %, 99.9 %, and 99.99 % quantiles rest on few hours and are
reported, not scored. `eval/score_rev1.m` implements this; the agent sees
scores rounded to 0.1 dB.

The Phase 2 part is computed as follows:

1. Within each held-out site, give each path a total weight of 1, split
   evenly across its rows (frequencies and heights).
1. Group rows into cells of site × frequency band (< 0.3, 0.3–1, 1–3, 3–6,
   and 6–10 GHz).
1. Compute the weighted RMS error in each cell.
1. Average the cell RMS values. Baseline ITM: **18.3 dB**. P.452: 13.3 dB.
   P.2001: 13.3 dB (from the existing matlab_itm comparison; reproduced by
   `eval/` in Phase 0).

The evaluator also reports the following, which gate acceptance but aren't
climbed directly:

- Worst cell RMS (baseline 38.2 dB).
- Mean error per site (bias).
- Error by ITM propagation mode, Δh bin, distance bin, and the ratio of
  effective to structural antenna height.
- **Censored-bound violations.** The share of censored results where the
  variant predicts less loss than the measured lower bound. A change that
  "fixes" RMS by predicting low loss on paths where no signal was measured
  is caught here.
- Runtime per 1,000 links, so a variant stays usable in large Monte Carlo
  runs.

### Physics battery

Every variant must pass all of these before it is scored. They come from
checks already in `matlab_itm` (`check_reciprocity`, `check_continuity`,
`check_height_swap`):

- **Reciprocity:** swapping transmitter and receiver (and reversing the
  profile) changes loss by less than 0.1 dB.
- **Continuity:** no jumps over 1 dB at line-of-sight/diffraction or
  diffraction/troposcatter boundaries when distance, height, or frequency
  changes by a small step.
- **Bounds:** line-of-sight loss stays within a set margin of free-space
  loss (exact margin to be set from the baseline distribution); loss is
  finite and real for all valid inputs.
- **Monotonic trends on canonical profiles:** on smooth-earth and single
  knife-edge test profiles, loss rises with distance and frequency where
  physics says it must.
- **Reference parity of unchanged parts:** if a change touches only
  diffraction, line-of-sight-only reference cases are bit-identical to the
  baseline.

### Acceptance rule (the ratchet)

The agent keeps a change only if all of these hold:

1. The physics battery passes.
1. The primary score improves by at least **0.3 dB** over the current best.
   This is above the run-to-run noise of a deterministic model and the
   variation from profile resampling. TODO: confirm by measuring the score
   change from resampling profiles at 25 m versus 30 m.
1. **No held-out site gets worse** by more than 0.5 dB RMS.
1. Censored-bound violations don't increase by more than 1 percentage point.
1. **Complexity cost:** each new free parameter must buy at least 0.5 dB on
   the primary score. A change that adds a fitted parameter and gains 0.4 dB
   is rejected.
1. The change has a one-sentence physical rationale recorded in
   `experiments/LOG.md` before the run.

If a change fails, the agent reverts it and logs it. Failed experiments are
data too; the log stops the agent from retrying the same idea.

### Noise floor

Measurement error and location variability set a floor no model can beat.
Phase 1 of the roadmap estimates it from paths measured in more than one run
and from the spread among nearby receiver heights. The agent stops pushing a
cell once its RMS is within 1 dB of that floor and reports the cell as
saturated.

## Change catalog

Inputs are fixed (terrain source, profile spacing, ground constants,
climate, refractivity); only the model changes. The ranked candidate list,
with sources, is in
[docs/LITERATURE_REVIEW.md Part 3](docs/LITERATURE_REVIEW.md#part-3-ranked-candidates).
Submodel swaps (Tier 2) come first, because the baseline diagnosis shows
path-specific structural error that recalibration can't remove. Each entry
names the `itm_p2p_core_exp.m` function it touches. Name every part by its
physics and its public source.

### Tier 1: calibrate existing constants

ITM has many hard-coded constants that came from fits to 1960s data. Move
each one in turn into `params_exp.m`, then fit it with leave-one-site-out
cross-validation using MATLAB `bayesopt` or `surrogateopt` within physically
plausible bounds:

- Diffraction weighting between knife-edge and smooth-earth loss, and the
  terrain clutter term `A_fo` (`diffraction_loss`).
- The terrain roughness factor `1 − 0.8·exp(−d/50 km)` and the `sigma_h`
  relation (`terrain_roughness`, `sigma_h_function`).
- The interdecile window in `compute_delta_h`.
- Line-of-sight weighting between two-ray and extrapolated diffraction loss
  (`line_of_sight_loss`).
- Troposcatter `H0` curve constants (`h0_curve`, `f_function`).

Rule: one constant group per experiment, so each accepted change has a clear
cause.

### Tier 2: swap submodels (first)

Each swap is written in `itm_variant/` from the ITU-R text or the cited
paper and switched by a field in `params_exp.m`. Nick's ports of P.452
(`matlab_itu_p452`) and P.2001 (`itu_p2001`) serve as numerical checks of
the new code, not as code to copy.

- **Effective antenna height.** Paul (2003) found ITM error largest when
  effective height far exceeds structural height. Try a blend
  `h_e = h_s + α(h_e,ITM − h_s)` with α fitted, or a cap based on the
  terrain under each antenna (`quick_pfl`, `initialize_point_to_point`).
- **Multi-edge diffraction.** Replace ITM's double knife-edge with the
  Bullington or Delta-Bullington method of ITU-R P.526 (as P.452 and P.2001
  use), Deygout, or Epstein-Peterson, keeping ITM's smooth-earth blend
  (`knife_edge_diffraction`). This is the most likely fix for R2's 29.9 dB
  RMS.
- **Troposcatter and the mode switch.** ITM picks troposcatter on 234 Phase 2
  rows (paths of 75–120 km) with +19.1 dB mean error. Test the P.452 or
  P.2001 troposcatter formula, and test whether the mode switch fires too
  early on obstructed paths of this length (`longley_rice`,
  `troposcatter_loss`).
- **Time variability.** Replace ITM's time deviate with P.2001's clear-air
  fading and enhancement (Attachment B) on the ITM median, or replace only
  the enhancement side with P.452's ducting and layer-reflection model
  (P.452 covers 0.001–50 % of time only) (`variability`).
- **Line-of-sight ground reflection.** Use the actual reflection point and
  terrain slope from the profile instead of the smoothed effective-height
  geometry (`line_of_sight_loss`).
- **Frequency scaling above 3 GHz.** Errors grow from 18.1 dB (1–3 GHz) to
  22.1 dB (3–6 GHz). Test whether roughness and diffraction terms scale with
  frequency as the physics predicts, for example through Fresnel-zone
  clearance.

### Tier 3: add terms ITM lacks

- Vegetation along the path (P.833) where land cover is known.
- Clutter at the terminals (P.2108) for Tier C data only.

### Tier 4: residual model (diagnostic, not a deliverable)

Fit a small gradient-boosted model to the baseline residuals using path
features: Δh, distance, frequency, heights, horizon angles, number of
obstructions, and the effective-to-structural height ratio. Use its feature
importance and partial-dependence plots to point Tiers 1 and 2 at the right
mechanism. Its held-out score is the **ceiling** the physics changes are
trying to approach. Report it, but don't ship it as an ITM change.

## Experiment loop

Diagrams: [docs/FLOW.md](docs/FLOW.md).

Each experiment follows these steps. `program.md` restates them as
instructions to the agent.

1. **Read the state.** Read `results/results.tsv`, the last 20 entries in
   `experiments/LOG.md`, and the current error breakdown.
1. **Pick a hypothesis** from the catalog, targeting the cell with the most
   remaining squared error. Write the log entry first: ID, tier, function
   touched, physical rationale, and the predicted effect (which cells should
   improve and which should not change).
1. **Branch:** `git switch -c exp/NNN-short-name` from the current best, or
   from one of the top three kept variants (tree-style branching, see
   [docs/AGENT_OPTIMIZATION_LITERATURE.md](docs/AGENT_OPTIMIZATION_LITERATURE.md)).
1. **Edit** only `itm_variant/itm_p2p_core_exp.m` and `params_exp.m`.
1. **Run** `run_eval_rev1(Tag="NNN-short-name")` in MATLAB R2025b on Nick's
   Mac (physics battery, then scoring). A full pass takes minutes.
1. **Decide** with the acceptance rule. Keep: merge to the `best` branch.
   Reject: discard the branch. Either way, append the result row and
   complete the log entry, including whether the predicted effect happened.
1. **Every 10 accepted changes,** a separate reviewer agent, which hasn't
   seen the reasoning behind them, tries to break the current best: it looks
   for parameter values that sit at their bounds, gains that come from one
   site, and physics battery gaps. A human reviews its findings before the
   loop continues.

`results/results.tsv` columns:

```text
id  date  branch  tier  function  n_new_params  composite  delta_vs_best  p2_cell  lt_level  lt_shape  worst_cell  site_R1  site_R2  site_R3  site_VA  censor_viol_pct  physics_pass  decision  commit
```

## Guardrails

- **The evaluator is read-only.** The agent can't edit `eval/`,
  `data/splits/`, or `data/links/`. A hook or CI check rejects commits that
  touch them.
- **The agent never sees the lockbox.** Lockbox data is outside the agent's
  working tree until a human runs the final check.
- **Every gain must be explainable.** If the agent can't state the physical
  mechanism, the change isn't kept, even if it scores.
- **No silent failures.** NaN loss, complex loss, or an ITM error code on a
  valid input fails the run (`error()`, not a skipped row).
- **Baseline parity is checked every run.** If the unmodified core doesn't
  reproduce the baseline score exactly, the run stops.
- **Reproducibility.** Every result row records the commit, data hashes,
  and MATLAB release. Any fitted parameter uses `opts.seed`.
- **Human gate.** No result leaves the repository, and nothing merges to
  `main`, without Nick's review.

## Roadmap

| Phase | Work | Exit check |
| --- | --- | --- |
| 0. Scaffold | `data/build_links_rev1` builds Phase 2 and long-term link tables, profiles, splits, baseline and reference predictions; `itm_variant/` copy; `eval/` and the physics battery | Baseline reproduces 16.74 dB row RMS and 18.3 dB cell-balanced score on Phase 2; variant parity to 1e-9 dB |
| 1. Diagnose | Error breakdown by mechanism, Δh, effective height ratio, frequency, and time percentage; noise floor estimate; Tier 4 residual ceiling | A ranked list of where squared error lives, with the ceiling and floor |
| 2. Restructure | Tier 2 submodel swaps from P.452, P.2001, P.526, and the literature, in the ranked order | Target: Phase 2 cell score at or below 13.3 dB, no site worse than baseline, long-term scores no worse |
| 3. Calibrate | Tier 1 constants of the kept structure, fitted in cross-validation | Accepted changes logged; held-out score trend |
| 4. Lockbox | Human runs Tier B sets on the best variant and on baseline | Lockbox result recorded, whatever it is |
| 5. Write-up | Working paper: which changes, why, held-out evidence, limits | Human review |

## Open questions for Nick

1. Is the 0.3 dB acceptance threshold and the 0.5 dB per-parameter cost the
   right bar, or should the bar be higher for a policy-facing result?
1. Should the composite weight the three parts equally, or weight the 1–10
   GHz cells more, since that is the band this work is for?
