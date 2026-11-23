# Headroom map and mechanism catalog (rev 1)

> **Planner note added on push (2026-11-22, Claude Code session).** This
> analysis ran in Claude Science against the Mac's working copy, whose git
> checkout was behind `origin/main`. Read these points with that in mind:
>
> - Open items 1, 2 and 4 are artifacts of the stale checkout. `B12.md`
>   (commit 5d77508), `experiments/proposals/` (including the research
>   package with H01–H21) and the merged `eval/` and `data/` changes are all on
>   `main`.
> - Runs 1301 and 1302 duplicate B12's 1201 and 1202. The history-matching
>   screen (`experiments/proposals/history_matching_rev1.md`) shows neither can
>   pass: largest possible gain 0.128 and 0.008 dB against the 0.3 dB gate.
>   This document's smoke tests agree. Don't register them again as B13.
> - Open item 5 (noise floor): `results/model_floor_rev1.csv` now gives the
>   Bayes floor from identical-input groups. It's weak (floor composite
>   0.33 dB), so the 3, 5 and 8 dB working floors here are assumptions, not
>   measurements.
> - Items 3 (707's stale screened figure), 6 (switches the core never reads)
>   and 7 (R3 saturated) stand.


Planner: Claude Opus 5, 2026-11-23. Parent: `best` = `707-cascaded-isolated-clutter-at-r`.
Analysis only: no change to `itm_variant/`, no scored run, no lockbox data.
Training folds only; every number comes from stored predictions, the frozen
link tables, the frozen profiles and the frozen long-term screen.

Reproduce with:

```bash
python3 experiments/proposals/headroom_map_rev1.py 707-cascaded-isolated-clutter-at-r
python3 experiments/proposals/headroom_smoke_rev1.py
```

## Summary

1. **The composite is two-thirds long-term.** Of 707's 12.51 dB composite, the
   Phase 2 cell part is 13.25 dB, the long-term level part 19.09 dB and the
   long-term shape part 5.17 dB. Setting every long-term error to zero drops
   the composite by 8.09 dB (95 % 6.21 to 8.92); setting every Phase 2 error to
   zero drops it by 4.42 dB.
2. **Nothing is left in bias.** Removing a class's weighted mean error, keeping
   its spread, is worth less than 0.3 dB for every class but two: rows with
   four or more terrain obstacles (0.34 dB) and 6-10 GHz rows (0.45 dB), and
   both intervals nearly touch zero. The error is spread, not level, in every
   class. This confirms FRAMEWORK.md's baseline reading at class resolution and
   rules out any further level-offset or recalibration work.
3. **Ten classes cannot reach the 0.3 dB keep threshold even when perfect**, so
   no mechanism that acts only on them can ever be kept (table below).
4. **ITM's line-of-sight term has almost no leverage above 3 GHz.** On Phase 2
   line-of-sight rows above 3 GHz the two-ray weight `w = 1/(1 + f·Δh/d_sML)`
   has median 0.062, and 96 % of those rows are below 0.2: at least 94 % of the
   predicted loss is the extrapolated diffraction line. Two model-only smoke
   tests confirm it (`headroom_smoke_rev1.py`): a rough-surface reflection
   coefficient (Ament 1953) changes the mean Phase 2 loss by +0.00 dB, and the
   curved-Earth specular phase (research package H02, already coded as
   `cfg.los_phase = "curved_specular"`) by +0.05 dB. Both have band means of
   −0.00 dB in the 3-6 and 6-10 GHz bands.
5. **The research package's H03 two-leg time variability fires on 8 of 548
   long-term links**, median blend weight 0.01. Over the links that fire, the
   predicted spread `L_p − L_50` moves by +0.34 dB at 1 % and −0.29 dB at 99 %
   on average, at most +1.43 dB. Eight links spread over 325 long-term paths
   cannot move the cell-balanced shape score by 0.3 dB.
6. **The screened composite recorded with the keep is stale.** 707's
   `results.tsv` row says screened 11.2 dB, which this analysis reproduces
   (11.15 dB) against the 14-link screen in force at B08. The frozen screen now
   holds 36 links (PR #5), under which 707's screened composite is **9.91 dB**.
7. **PR #5 also overturns D05's reading of the long-term set.** Before it, three
   paths carried 42 % of the troposcatter class's squared error; after it, the
   top three of 228 paths carry 13 %, and the long-term level score falls from
   19.09 to 11.22 dB with the worst cell (3-10 GHz, under 100 km) resting on
   seven paths. The remaining long-term error is broad, not a handful of links.
8. **Ranked by possible gain times plausibility**, the live mechanisms are
   troposcatter and the diffraction-to-scatter crossover on transhorizon paths
   (up to 3.2 dB at a 5 dB floor, source text needed), path vegetation on
   terrain-clear Phase 2 rows (up to 0.9 dB, land-cover input needed), and
   nothing else above 0.3 dB that the frozen inputs can drive.

## Method

### Row classification

`experiments/proposals/itm_stock_py_rev1.py` transcribes
`itm_variant/itm_p2p_core_exp.m` at `params_exp` defaults into Python, so the
quantities the MATLAB core computes internally and does not store can be read
out per row: propagation mode, the ITM 1.2.2 mode code (from which the horizon
count follows), horizon distances, effective heights and `delta_h`.

Validation: the transcription reproduces the stored baseline columns
`itm_lb_50` on all 16,805 Phase 2 rows to **6.8e-13 dB** and `itm_lb_<p>` on all
548 long-term rows at nine time percentages to **5.4e-13 dB**, the same order as
the harness's own parity figure (7e-13 dB). Mode counts: Phase 2 14,146 line of
sight, 2,079 diffraction, 580 troposcatter; long-term 94, 78 and 376.

Obstacle counts use the D04 rule (terrain plus 4/3-Earth bulge above the
straight ray, `experiments/D04-open-clear-paths/fresnel_clearance_rev1.py`),
counted as separate runs of profile samples above the ray. They are a property
of the profile, not of any multi-edge construction, so they do not match the
"by edge count" tables in LOG.md, which count the edges a given method selects.

Siting (open `O`, concealed `C`, undocumented `A`) comes from
`data/links/phase2_links_rev1.csv`; long-term rows have no siting.

### Score replication

`headroom_map_rev1.py` replicates `eval/score_rev1.m` in numpy: path weights
1/rows, cells site x band (Phase 2) and band x distance class (long-term),
composite = mean of the three cell-balanced RMS values. It reproduces 707 at
composite 12.505 (summary 12.51), Phase 2 cell 13.247 (metrics.json 13.2470),
long-term level 19.095 and shape 5.174, and stock ITM at 16.025 (16.02).

### Counterfactuals (step 2)

For each class, three modified error vectors are scored:

| Counterfactual | Definition |
| --- | --- |
| perfect | the class's errors set to zero; the class's whole contribution |
| bias | the class's weighted mean error removed, spread unchanged |
| floor | the class's errors scaled so its weighted RMS equals the floor, where its RMS is above the floor |

The reported headroom is the drop in the composite. Each is wrapped in the
paired bootstrap of `eval/paired_gain_rev1.m`: 500 draws, paths resampled with
replacement within each Phase 2 site and each long-term fold, both composites
scored on the same draw, class statistics recomputed inside the draw. The
scheme is the evaluator's; the draws are numpy's, so intervals are not
bit-identical to a MATLAB run.

### Noise floor

FRAMEWORK.md puts the measurement and location-variability floor in roadmap
Phase 1 and it is still **TODO**: `experiments/D02-noise-floor/` measures the
score's path-sampling spread, not the measurement floor, and the Phase 2 link
table stores only the median over runs, so no replicate spread is recoverable.
Two data-derived upper bounds are used instead: the best cell under 707
(R3, 0.3-1 GHz) is 6.08 dB, and the best open, terrain-clear classes at R1 and
R3 in D04 are 4.2 to 5.8 dB. Headroom is therefore reported at floors of 3, 5
and 8 dB, with 5 dB as the working value. No floor constant is introduced.

## 1. Error attribution

Weight share is the class's share of total path weight within its dataset.
Mean and RMS are path-weighted, in dB, error = predicted minus measured.
Censored violations are the share of that class's censored rows where 707
predicts less loss than the measured lower bound. "Contribution" is the perfect
counterfactual: how far the composite falls if the class's error goes to zero.

### By site and by dataset

| Class | Rows | Weight share | Mean | RMS | Censored rows | Violated | Contribution (dB) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R1 | 4,489 | 0.12 | +4.11 | 10.48 | 280 | 5.7 % | 0.83 |
| R2 | 2,560 | 0.08 | −0.20 | 18.16 | 1,184 | 14.7 % | 1.75 |
| R3 | 5,149 | 0.11 | +0.38 | 6.78 | 0 | — | 0.58 |
| VA | 2,562 | 0.69 | −2.87 | 12.89 | 581 | 47.5 % | 1.25 |
| long-term (all) | 548 | 1.00 | +0.39 | 13.83 | 0 | — | 8.09 |

VA holds 69 % of Phase 2 path weight (354 of 513 paths, most of them short),
but the cell-balanced score equalises the four sites, so its contribution is
1.25 dB.

### By ITM mode

| Mode | Phase 2 rows | LT rows | P2 mean | P2 RMS | LT mean | LT RMS | Violated | Contribution | of which P2 part / level / shape |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| line of sight | 13,096 | 94 | −2.90 | 13.29 | −0.33 | 12.88 | 30.7 % | 3.65 | 8.63 / 1.63 / 0.70 |
| diffraction | 1,580 | 78 | +2.30 | 10.65 | +7.14 | 15.90 | 20.6 % | 1.34 | 1.02 / 2.58 / 0.42 |
| troposcatter | 84 | 376 | +4.81 | 12.47 | −0.81 | 13.55 | 8.3 % | 4.61 | 0.11 / 10.77 / 2.94 |

Troposcatter is 1 % of Phase 2 path weight and 69 % of the long-term rows. It
carries 10.77 dB of the 19.09 dB level part and 2.94 dB of the 5.17 dB shape
part: the largest single mechanism class in the score.

### By profile horizons and obstacles

| Class | P2 rows | LT rows | P2 mean | P2 RMS | Violated | Contribution | P2 part / level / shape |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 horizons | 7,164 | 64 | −6.37 | 13.61 | 100 % of 39 | 1.37 | 3.12 / 0.67 / 0.32 |
| 1 horizon | 3,090 | 27 | −0.01 | 13.02 | 93.6 % of 110 | 0.58 | 1.58 / 0.10 / 0.06 |
| 2 horizons | 4,506 | 457 | +2.60 | 11.47 | 17.1 % of 1,896 | 7.51 | 3.11 / 15.57 / 3.86 |
| 0 obstacles | 7,170 | 63 | −6.39 | 13.63 | 100 % of 37 | 1.37 | 3.12 / 0.67 / 0.31 |
| 1 obstacle | 2,332 | 163 | +0.34 | 13.01 | 41.3 % of 150 | 1.24 | 1.29 / 1.29 / 1.12 |
| 2 obstacles | 1,665 | 86 | +0.92 | 14.56 | 25.8 % of 248 | 0.88 | 0.95 / 1.29 / 0.38 |
| 3 obstacles | 882 | 48 | +1.98 | 12.13 | 22.4 % of 304 | 0.64 | 0.44 / 1.24 / 0.23 |
| 4+ obstacles | 2,711 | 188 | +2.46 | 10.75 | 18.0 % of 1,306 | 3.66 | 1.71 / 8.16 / 1.10 |

The sign flips with obstruction: paths the 30 m profile leaves clear are
6.4 dB optimistic and violate every censored bound in the class, paths with
four or more obstacles are 2.5 dB pessimistic.

### By distance and frequency

| Class | P2 rows | LT rows | P2 mean | P2 RMS | LT mean | LT RMS | Contribution | P2 / level / shape |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| < 2 km | 475 | 0 | −3.42 | 14.02 | — | — | 0.05 | 0.14 / 0 / 0 |
| 2-5 km | 2,343 | 0 | −8.01 | 16.26 | — | — | 0.68 | 2.03 / 0 / 0 |
| 5-10 km | 2,302 | 0 | −4.61 | 12.44 | — | — | 0.26 | 0.79 / 0 / 0 |
| 10-30 km | 4,720 | 17 | −2.55 | 12.85 | +9.91 | 23.07 | 0.93 | 1.75 / 0.86 / 0.19 |
| 30-100 km | 4,443 | 55 | +1.74 | 11.93 | +2.94 | 16.49 | 2.22 | 2.36 / 3.51 / 0.78 |
| 100-300 km | 477 | 335 | +1.27 | 8.96 | +0.41 | 13.47 | 3.11 | 0.31 / 6.98 / 2.03 |
| >= 300 km | 0 | 141 | — | — | −1.50 | 12.41 | 2.71 | 0 / 6.26 / 1.87 |
| < 0.3 GHz | 2,830 | 313 | +4.21 | 8.99 | −1.44 | 8.49 | 1.92 | 1.91 / 2.45 / 1.42 |
| 0.3-1 GHz | 6,153 | 129 | −1.84 | 11.16 | −2.77 | 11.83 | 2.15 | 2.19 / 2.92 / 1.34 |
| 1-3 GHz | 1,990 | 67 | −5.03 | 14.24 | +7.26 | 19.77 | 2.85 | 2.65 / 4.68 / 1.22 |
| 3-6 GHz | 2,091 | 15 | −7.19 | 17.66 | +6.88 | 18.63 | 2.24 | 3.11 / 3.20 / 0.41 |
| 6-10 GHz | 1,696 | 24 | −8.02 | 18.52 | +28.88 | 45.29 | 2.89 | 3.40 / 4.74 / 0.55 |

Phase 2 error grows monotonically with frequency in both mean and RMS, from
+4.2 dB and 9.0 dB below 0.3 GHz to −8.0 dB and 18.5 dB at 6-10 GHz. The sign is
optimistic above 1 GHz on every band.

### Site by mode (Phase 2 only)

| Class | Rows | Weight share | Mean | RMS | Contribution |
| --- | --- | --- | --- | --- | --- |
| R1 / line of sight | 3,903 | 0.10 | +2.58 | 9.47 | 0.46 |
| R1 / diffraction | 544 | 0.02 | +11.72 | 14.70 | 0.09 |
| R1 / troposcatter | 42 | 0.00 | +10.40 | 11.24 | 0.01 |
| R2 / line of sight | 2,284 | 0.07 | −4.29 | 17.42 | 1.07 |
| R2 / diffraction | 251 | 0.01 | +20.64 | 21.40 | 0.16 |
| R2 / troposcatter | 25 | 0.00 | +23.43 | 23.77 | 0.02 |
| R3 / line of sight | 5,082 | 0.11 | +0.32 | 6.80 | 0.52 |
| R3 / diffraction | 67 | 0.00 | +3.57 | 5.83 | 0.00 |
| VA / line of sight | 1,827 | 0.46 | −4.59 | 14.36 | 0.82 |
| VA / diffraction | 718 | 0.23 | +0.52 | 9.31 | 0.09 |
| VA / troposcatter | 17 | 0.01 | +0.49 | 10.00 | 0.00 |

707 is still 10 to 23 dB pessimistic on every Phase 2 transhorizon class, but
those classes hold 4 % of the path weight between them, so no diffraction or
troposcatter change confined to Phase 2 can be kept.

### Phase 2 residual structure (707)

| Site | Siting | Terrain | Rows | Weight share | Mean | RMS |
| --- | --- | --- | --- | --- | --- | --- |
| R1 | concealed | clear | 156 | 0.00 | −0.47 | 12.68 |
| R1 | open | clear | 1,445 | 0.03 | −0.58 | 5.84 |
| R1 | open | obstructed | 2,036 | 0.06 | +7.46 | 12.49 |
| R1 | concealed | obstructed | 436 | 0.01 | +7.96 | 12.08 |
| R1 | undocumented | clear | 112 | 0.00 | +0.08 | 4.99 |
| R1 | undocumented | obstructed | 304 | 0.01 | −2.59 | 6.41 |
| R2 | concealed | clear | 46 | 0.00 | −26.78 | 33.41 |
| R2 | open | clear | 355 | 0.01 | −14.40 | 24.11 |
| R2 | concealed | obstructed | 186 | 0.01 | −9.11 | 22.50 |
| R2 | open | obstructed | 1,973 | 0.07 | +3.02 | 16.31 |
| R3 | open | clear | 4,005 | 0.08 | −1.57 | 5.85 |
| R3 | open | obstructed | 1,144 | 0.03 | +6.40 | 9.08 |
| VA | open | clear | 810 | 0.23 | −9.01 | 15.81 |
| VA | open | obstructed | 802 | 0.27 | −0.64 | 10.33 |
| VA | concealed | clear | 241 | 0.04 | −4.94 | 12.67 |
| VA | concealed | obstructed | 709 | 0.15 | +2.90 | 12.14 |

## 2. Headroom

Composite drops, in dB, with 95 % paired-bootstrap intervals. "Screened" is the
same drop on the screened composite under the current 36-link screen.

| Class | Perfect | 95 % interval | Screened | Bias only | Floor 3 dB | Floor 5 dB | Floor 8 dB |
| --- | --- | --- | --- | --- | --- | --- | --- |
| long-term, all rows | 8.09 | 6.21 to 8.92 | 5.50 | −0.03 | 5.95 | 4.67 | 3.02 |
| 2 horizons | 7.51 | 5.55 to 8.64 | 4.65 | 0.20 | 6.17 | 5.02 | 3.32 |
| long-term beyond 100 km | 5.71 | 3.97 to 6.56 | 3.63 | 0.10 | 4.17 | 3.23 | 2.03 |
| troposcatter mode | 4.61 | 2.80 to 5.57 | 2.41 | 0.13 | 3.67 | 2.96 | 1.94 |
| 4+ obstacles | 3.66 | 1.99 to 4.91 | 1.49 | 0.34 | 3.25 | 2.82 | 2.07 |
| line-of-sight mode | 3.65 | 3.18 to 4.64 | 4.18 | 0.11 | 3.17 | 2.63 | 1.76 |
| 100-300 km | 3.11 | 2.13 to 4.02 | 2.05 | 0.08 | 2.29 | 1.79 | 1.11 |
| 6-10 GHz | 2.89 | 1.92 to 3.80 | 1.91 | 0.45 | 2.61 | 2.39 | 2.09 |
| 1-3 GHz | 2.85 | 2.24 to 3.31 | 2.17 | 0.06 | 2.22 | 1.83 | 1.35 |
| open siting | 2.71 | 2.27 to 3.40 | 2.71 | −0.04 | 2.37 | 1.98 | 1.27 |
| >= 300 km | 2.71 | 1.56 to 3.10 | 1.68 | 0.04 | 1.95 | 1.50 | 0.91 |
| 3-6 GHz | 2.24 | 1.09 to 2.62 | 1.49 | 0.13 | 1.84 | 1.60 | 1.27 |
| 30-100 km | 2.22 | 1.41 to 2.92 | 1.75 | 0.14 | 1.87 | 1.57 | 1.12 |
| above 3 GHz (Phase 2) | 2.17 | 1.88 to 2.40 | 2.17 | −0.02 | 1.81 | 1.57 | 1.21 |
| all terrain-obstructed (Phase 2) | 1.78 | 1.46 to 2.22 | 1.78 | 0.07 | 1.60 | 1.35 | 0.83 |
| R2 | 1.75 | 1.42 to 2.23 | 1.75 | 0.00 | 1.55 | 1.27 | 0.82 |
| VA | 1.25 | 1.16 to 1.56 | 1.25 | 0.05 | 0.98 | 0.77 | 0.44 |
| all terrain-clear (Phase 2) | 1.04 | 0.75 to 1.35 | 1.04 | 0.09 | 1.03 | 0.87 | 0.58 |
| R1 | 0.83 | 0.70 to 1.04 | 0.83 | 0.02 | 0.57 | 0.43 | 0.22 |
| R1+R3 terrain-obstructed | 0.62 | 0.46 to 0.84 | 0.62 | 0.14 | 0.53 | 0.45 | 0.29 |
| R3 | 0.58 | 0.46 to 0.74 | 0.58 | 0.00 | 0.23 | 0.15 | 0.05 |
| concealed siting | 0.42 | 0.22 to 0.68 | 0.42 | −0.00 | 0.39 | 0.35 | 0.26 |
| VA open, terrain-clear | 0.42 | 0.34 to 0.57 | 0.42 | 0.15 | 0.40 | 0.37 | 0.31 |

### Classes that cannot reach 0.3 dB even when perfect

Upper end of the 95 % interval below 0.3 dB, so no change confined to these
rows can pass the acceptance rule, whatever its physics:

| Class | Rows | Perfect | Upper 95 % |
| --- | --- | --- | --- |
| undocumented siting (`A`) | 416 | 0.02 | 0.04 |
| under 2 km | 475 | 0.05 | 0.09 |
| R1 / diffraction | 544 | 0.09 | 0.16 |
| R1 / troposcatter | 42 | 0.01 | 0.03 |
| R2 / diffraction | 251 | 0.16 | 0.28 |
| R2 / troposcatter | 25 | 0.02 | 0.08 |
| R3 / diffraction | 67 | 0.00 | 0.01 |
| R3 / troposcatter | 0 | 0.00 | 0.00 |
| VA / diffraction | 718 | 0.09 | 0.12 |
| VA / troposcatter | 17 | 0.00 | 0.01 |

Phase 2 diffraction and troposcatter rows are jointly worth 1.08 dB at most and
no single site-by-mode cell clears 0.3 dB. The remaining 5-10 km class (0.26 dB)
is marginal. R3 is within 0.6 dB of perfect overall and within 0.15 dB at a 5 dB floor; its
five cells run 6.08 to 7.87 dB RMS, one to three dB above the empirical floor
bound, so it is at or near saturation on FRAMEWORK.md's test.

## 3. Mechanism catalog

Public sources only. Equation numbers marked "verified" were read from the
primary PDF; the rest are the section-level citations already used in the
repository, with equation numbers left **TODO** until a primary PDF is read.
"Max gain" is the perfect counterfactual for the row classes the mechanism acts
on, from the table above; it is a ceiling, not an expectation.

| # | Mechanism | Public source | Acts on | Effect size and sign | Frozen inputs sufficient? | Max gain (dB) | Repo status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M1 | Troposcatter attenuation (scattering-angle law and the frequency-gain function) | ITM as built: the ITM algorithm document (Hufford, Longley and Kissick, NTIA Report 82-100) and NBS Technical Note 101 (**TODO**: section and equation numbers); published alternatives ITU-R P.617-5 and ITU-R P.452-18 §4.3 (section from the repository's literature review; equations **TODO**) | troposcatter mode: 376 long-term rows, 84 Phase 2 rows; all rows beyond 100 km | Phase 2 +10 to +23 dB too lossy by site; long-term −0.8 dB mean with 13.6 dB spread | Yes: θ, h_e, N_s, climate and distance are all frozen inputs | 4.61 (screened 2.41); beyond 100 km 5.71 (3.63) | `cfg.troposcatter` exists in `params_exp.m` but the core never reads it: **placeholder, no code**. H12 found no transition bias (D05, B10) |
| M2 | Diffraction-to-scatter crossover (ITM switches at d_x where the scatter line undercuts the diffraction line) | ITM: the ITM algorithm document (NTIA Report 82-100), the diffraction and scatter line construction in `longley_rice`; P.452-18 and P.2001-6 combine sub-models instead of switching (**TODO**: sections and equations) | the 2-horizon class: 4,506 Phase 2 and 457 long-term rows | A hard switch leaves steps; the class is +2.6 dB on Phase 2, +0.9 dB long-term | Yes | 7.51 (screened 4.65) | Bounded form kept in 707 (`diffraction_bound = "itm_troposcatter_line"`, B06). H12 queued, no transition bias found |
| M3 | Multiple knife edges, cascaded with an isolation criterion | ITU-R P.526-11 §4.4.2; isolation ITU-R P.526-16 §2.5 (verified, §2.5 present); Bullington P.526-16 §4.5.1 eq. (49)-(55), (57) (verified); complete method §4.5.2 eq. (58)-(66) (verified) | transhorizon and obstructed rows | In 707 it over-predicts +6 to +8 dB on obstructed open rows at R1 and R3 | Yes | terrain-obstructed Phase 2 1.78; R1+R3 obstructed 0.62 | **Kept** in 707. Known defect: principal-edge switch, 51.7 dB jump for a 2.5 m height change (LOG 2026-11-22); the real-path height-gain check is report-only until a method without the jump exists (package H01) |
| M4 | Rounded obstacles: extra loss T(m,n) for an edge of finite radius | ITU-R P.526-16 §4.2 eq. (32), T(m,n) eq. (34a)-(34b), m eq. (35), n eq. (36), J(ν) eq. (31) (verified) | obstructed rows, mostly R1, R2, R3 | Adds loss, 0 to 10 dB with radius; wrong sign where 707 is already +6 to +8 dB pessimistic | Terrain yes; the radius estimate is the problem | <= 1.78, in practice negative | H06 **blocked**: the printed radius formula gives a negative radius on a smooth Earth (LOG, B09); needs an independent reference check |
| M5 | Multiple isolated cylinders | ITU-R P.526-16 §4.4 (verified heading), eq. (44)-(48) and Attachments 1-2 | transhorizon rows | Each joining ridge adds at least J(0) = 6 dB; loss reached 284 dB at 42 km | Yes | <= 1.78 | **Rejected** at the battery (H05, B09): rough-terrain distance step 64.9 dB against stock 33.0 |
| M6 | Ground-reflection coefficient of a rough surface | ITM uses exp(−min(10, 2πσ_h sinψ/λ)); Ament (1953) Proc. IRE 41(1) gives exp(−2(2πσ sinψ/λ)²); repository literature review rank 10 | line-of-sight rows | **Measured here, model only: mean +0.00 dB on Phase 2 and −0.00 dB in every band; 1,159 of 16,805 rows move more than 0.1 dB; above 3 GHz the largest single change is 0.29 dB** | Yes | effectively 0 | **New, and ruled out by this analysis.** The two-ray term carries a median weight of 0.062 above 3 GHz |
| M7 | Reflected-ray phase and divergence over a curved Earth | ITU-R P.530-19 §6.1.2.3: specular point eq. (121)-(125), path difference eq. (126), reflection coefficient eq. (129)-(131), divergence factor D eq. (132) (verified) | line-of-sight rows | **Measured here, model only: Phase 2 mean +0.05 dB, band means +0.19 (< 0.3 GHz) falling to −0.00 dB above 3 GHz; 1,644 rows move more than 0.1 dB; long-term 21 of 548 links move more than 0.1 dB, mean +0.03 dB** | Yes | effectively 0 | Package **H02**, coded as `cfg.los_phase = "curved_specular"`, never run and never registered (no B12.md) |
| M8 | Fresnel-zone intrusion on paths the profile leaves clear | ITU-R P.526-16 §2.1 "Fresnel ellipsoids and Fresnel zones" eq. (1), with the knife-edge loss J(ν) eq. (31) (both verified against the primary PDF; eq. (31) is printed in §4.1, not §2.1); repository literature review rank 9 | terrain-clear rows (7,170 Phase 2) | J(ν_max) is 2-3 dB where the errors are 10-28 dB, and the sign is reversed at VA | Yes | <= 1.04, in practice far less | **Rejected** (H04, D04/B09) |
| M9 | Terminal clutter height gain | ITU-R P.2108-1 §3.1 eq. (2a)-(2g) and Table 1 (checked against the PDF at B07/B08) | concealed Phase 2 terminals | +9 to +18 dB at the mobile end; frequency shape supported, height shape not | Yes, plus the siting flag | concealed siting 0.42 | **Kept** in 707 |
| M10 | Terminal clutter from land-cover class at open terminals | ITU-R P.2108-1 §3.1 with NLCD 2001 (USGS/MRLC) | open Phase 2 terminals | +14 to +18 dB where flagged forest; hurts R1 and R3, leaves VA unmoved | Yes, NLCD merged as PR #6 | 2.71 for open siting | **Rejected** both ways (H20/H21, runs 711 and 712, B11) |
| M11 | Vegetation along the path, not at the terminal | ITU-R P.833-10 (section and equations **TODO**: no primary PDF in the repo) | terrain-clear rows, above all VA open clear (−9.0 dB, rising with frequency) | Adds loss on clear paths, the right sign; D04 sizes the VA deficit at 17 to 25 dB over free space | **No**: needs land cover sampled along each profile, an extension of the existing NLCD builder; a data/ decision for Nick | terrain-clear 1.04 (floor 5 dB: 0.87); VA open clear 0.42 | **Queued, blocked on an input** (H21; B11 worker summary names it as what remains) |
| M12 | Terrain roughness Δh and the roughness factor 1 − 0.8·exp(−d/50 km) | the ITM algorithm document (NTIA Report 82-100), transcribed in `compute_delta_h`, `terrain_roughness` and `sigma_h_function` (**TODO**: equation numbers) | every row, through the diffraction weight and the line-of-sight blend | Constrained recalibration moved only the time-spread constant; every structural constant stayed at ITM's value | Yes | bias-only headroom < 0.3 dB everywhere | **Rejected** as a lever (R01, R02): retuning under the censored and continuity gates buys 0.1 dB |
| M13 | Effective antenna height | Paul (2003) ISART SP-03-401; Montgomery (1969) ERL TM 158 | all line-of-sight rows | Paul: error largest when h_e far exceeds h_s, best value often between | Yes | line of sight 3.65 (screened 4.18), but it costs a fitted parameter, so it must buy 0.5 dB | `cfg.effective_height`, `cfg.effective_height_alpha` exist but the core never reads them: **placeholder, no code**. Literature review rank 2, never tried |
| M14 | Smooth-surface fit that depends on the antenna heights | ITU-R P.526-16 §4.5.2 eq. (58)-(62d), with the horizon angles of eq. (61b)-(61d) formed from h_ts and h_rs (verified); the same construction as P.452-18 eq. (161)-(167) | obstructed rows where raising an antenna raises the loss (26 rows, 6 paths) | Up to 4.5 dB of inverted height gain | Yes | within the 0.62 dB of R1+R3 obstructed | **Diagnosed, not fixable from a public source**: the antenna dependence is in P.526-16 §4.5.2 as written, so removing it would depart from the Recommendation (LOG 2026-11-21 left this open as a TODO; this check closes it) |
| M15 | Ducting and super-refraction on the enhancement side | ITU-R P.452-18 ducting and layer reflection (section and equations **TODO**); ITU-R P.2001-6 anomalous-propagation sub-model | long-term rows at 1 % of time, above all beyond 100 km | D05: ITM's spread is 5.8 to 6.4 dB too wide at 1 % beyond 300 km and 2 to 7 dB too narrow below 100 km | **No**: P.452's duct incidence β0 needs the ΔN map and path-centre latitude; latitude is in the profile index, ΔN is not a repo input | shape part: beyond 100 km 3.89 of 5.17 | **New**; D05/H19 found no public model that scores better on shape (P.452 9.9, P.2001 6.6, ITM 5.2) |
| M16 | Time variability as two independent legs over a common crest | NBS Technical Note 101 §10.8 (independent legs) | long-term rows at non-median percentages | **Measured here, model only: fires on 8 of 548 links, median blend weight 0.01; spread change +0.34 dB at 1 % and −0.29 dB at 99 % on average over those links** | Yes | effectively 0 on the scored cells | Package **H03**, coded as `cfg.time_variability = "two_leg"`, never run and never registered (no B12.md) |

## Ranking by possible gain times plausibility

Plausibility is the planner's judgement of whether the mechanism can realise its
ceiling on these rows with the frozen inputs, given what the repo has already
measured. Gain is the floor-5 dB counterfactual, the realistic target.

| Rank | Mechanism | Gain at a 5 dB floor | Plausibility | Score | Blocking item |
| --- | --- | --- | --- | --- | --- |
| 1 | M1 troposcatter attenuation | 2.96 | medium (published alternatives exist; the class is spread, not bias) | high | primary PDF of P.617-5 or P.452-18 §4.3 |
| 2 | M2 diffraction-to-scatter combination instead of a switch | 5.02 on the 2-horizon class, overlapping M1 | low to medium (H12 found no transition bias) | medium | source text; overlaps M1 |
| 3 | M11 path vegetation | 0.87 | medium to high (right sign, right rows, D04 sizes it) | medium | land cover along the profile: data/ PR |
| 4 | M13 effective-height blend | up to 2.63, costs a fitted parameter | medium (Paul 2003 evidence is on other datasets) | medium | new code; must buy 0.5 dB |
| 5 | M15 ducting on the enhancement side | up to 3.89 on the shape part | low (no public model scores better on shape here) | low | ΔN input |
| 6 | M3 multi-edge without the principal-edge jump (H01) | 0.62 on R1+R3 obstructed | medium | low | every published alternative tried fails the censored gate |
| 7 | M6, M7, M16 line-of-sight and two-leg refinements | ~0 | ruled out by the smoke tests in this document | none | — |

## 4. Proposed next batch (B13)

Three experiments. Two can run today against `best` and close two
research-package items with registered null predictions; the third carries the
batch's gain and names its prerequisite. Predictions are registered here, before
any scored run, as program.md requires.

Score every run with `Best="707-cascaded-isolated-clutter-at-r"`. Launch through
`experiments/batches/launch_runs_rev1.m` with `ITMEXP_OVERRIDES`; 707's five
settings are
`{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}`.

Before the batch: rescore `000-baseline` and `707-cascaded-isolated-clutter-at-r`
against the current 36-link screen, so the screened column in `results.tsv` is
comparable (see Open items).

### 1301-two-leg-time-variability

- **Change** (launcher overrides): 707's five settings plus
  `"time_variability":"two_leg"`.
- **Source**: NBS Technical Note 101 §10.8, two independent legs; code already in
  `itm_variant/two_leg_quantiles_rev1.m` and `two_leg_geometry`
  (research package H03). No free parameters.
- **Function touched**: `variability`, through `cfg.leg`.
- **Rationale**: a path over one crest has two quasi-independent fading legs, so
  the time distribution is the convolution of two ITM time curves rather than
  one.
- **Planner smoke test** (model only, no measured loss read;
  `experiments/proposals/headroom_smoke_rev1.py`, a transcription of the same
  MATLAB): the common-crest gate fires on **8 of 548** long-term links, median
  blend weight **0.01**. Over those links the predicted spread `L_p − L_50`
  changes by **+0.34 dB at 1 %** (largest +1.43) and **−0.29 dB at 99 %**
  (largest −1.21), and by zero on the other 540 links. Phase 2 is unchanged by
  construction: `Y_T(0) = 0`.
- **Predictions** (confidence high unless stated):
  - Phase 2 cell score 13.2, identical to 707 to within 0.01 dB.
  - Long-term level 19.1, unchanged to within 0.05 dB.
  - Long-term shape 5.2, within 0.1 dB of 5.17 (medium confidence: the smoke
    test covers the predicted spread, not the scored shape).
  - Composite 12.5, |Δ| < 0.05 dB; paired 95 % interval includes zero.
  - Censored violations 22.8 %, unchanged (50 % values do not move).
  - Physics battery passes; `b12_battery_rev1.m` already reports it.
  - **Most likely: rejected, as a registered null.** That closes H03 on this data.
- **Falsified if**: more than 20 long-term links change by more than 0.1 dB at
  any percentage, or the shape score moves by more than 0.3 dB. Either means the
  MATLAB geometry gate fires more often than the transcription, and the worker
  should stop and hand back.

### 1302-curved-specular-phase

- **Change**: 707's five settings plus `"los_phase":"curved_specular"`.
- **Source**: ITU-R P.530-19 (09/2025) §6.1.2.3, specular point eq. (121)-(125)
  and path difference eq. (126); code in `itm_variant/los_phase_curved_rev1.m`
  (research package H02). No free parameters.
- **Function touched**: `line_of_sight_loss`.
- **Rationale**: ITM's two-ray phase uses the flat-Earth product `2 h1 h2 / d`;
  over a curved Earth the specular point moves and the heights above the tangent
  plane are smaller.
- **Planner smoke test** (model only, stock base,
  `experiments/proposals/headroom_smoke_rev1.py`): Phase 2 mean change
  **+0.05 dB**; **1,644 of 16,805** rows move more than 0.1 dB, with band means
  +0.19 dB below 0.3 GHz, +0.04 dB at 0.3-1 GHz, +0.02 dB at 1-3 GHz and
  −0.00 dB in both bands above 3 GHz; long-term **21 of 548** links move more
  than 0.1 dB, mean +0.03 dB. Reason: the two-ray term carries a median weight
  of 0.062 above 3 GHz.
- **Predictions**:
  - Composite within 0.1 dB of 12.5; paired 95 % interval includes zero.
  - Site RMS within 0.2 dB at every site; R3 within 0.1 dB.
  - Long-term level and shape within 0.1 dB.
  - Censored violations within 1 point of 22.8 %.
  - Physics battery passes.
  - **Most likely: rejected, as a registered null.** That closes H02 on this data.
- **Falsified if**: any site RMS moves by more than 0.5 dB, which would mean the
  707 base routes the change through the smooth-path reference `A_s` far more
  strongly than the stock base does; the worker should hand back with the
  per-band table.

### 1303-p833-path-vegetation

- **Status: blocked on an input.** Do not run until the prerequisite is merged.
- **Prerequisite** (data/ PR for Nick, extends the approved NLCD input): sample
  the NLCD 2001 class at every profile point of every Phase 2 path with the
  existing builder `data/build_landcover_rev1.m` and the MRLC WCS, and store the
  wooded fraction and the longest wooded run per path in
  `data/landcover/phase2_path_nlcd_rev1.csv`. Record the edition, the build
  script and the hash, as PR #6 did. Caveats to record before any score: NLCD
  2001 postdates the measurements by about 40 years, and 143 of 515 mobile
  terminal pixels have changed class since 1985.
- **Change**: 707's five settings plus a new switch
  `cfg.path_vegetation = "p833"`, adding excess vegetation loss over the wooded
  length of the path to the reference attenuation, after any diffraction bound
  and before the terminal clutter term.
- **Source**: ITU-R P.833-10, terrestrial path with vegetation
  (**TODO**: section and equation numbers to be read from the primary PDF before
  the code is written; the repository has no P.833 PDF).
- **Function touched**: `itm_p2p_core_exp` reference-attenuation assembly, a new
  `path_vegetation_rev1.m`.
- **Rationale**: the 30 m terrain of record is a bare-earth model, so trees
  along the path are invisible to every terrain-only method; the 7,170 Phase 2
  rows the profile leaves clear are 6.4 dB optimistic and violate 100 % of their
  censored bounds, and the deficit rises with frequency, which is the vegetation
  signature.
- **Predictions** (medium confidence; to be re-registered with a smoke test once
  the input exists):
  - Terrain-clear Phase 2 rows: mean error rises from −6.4 dB towards 0; VA open
    clear rises from −9.0 dB by 4 to 9 dB.
  - R3 open clear (mean −1.6 dB, RMS 5.85) is the risk: if the mapping adds more
    than about 2 dB there, R3 RMS fails the 0.5 dB site gate, as it did in 711.
  - Censored violations fall from 22.8 %, because every change adds loss.
  - Composite gain 0.3 to 0.9 dB if R3 holds, negative if it does not.
  - Physics battery passes; the term is monotonic in the wooded length.
- **Falsified if**: R3 RMS rises by more than 0.5 dB, which would repeat the 711
  and 712 result and close vegetation as a mechanism on this data.

### Queued for B14

1. **M1 troposcatter** (`cfg.troposcatter`), the largest remaining headroom:
   2.96 dB at a 5 dB floor on the troposcatter class, 3.23 dB on all rows beyond
   100 km. Prerequisite: a primary PDF of ITU-R P.617-5 or ITU-R P.452-18 §4.3,
   as Nick supplied for P.526-16 and P.530-19, so the planner can transcribe it
   with section and equation numbers.
2. **M13 effective-height blend** (`cfg.effective_height_alpha`), one fitted
   parameter, which the complexity rule requires to buy 0.5 dB.

## Open items for Nick

1. **`experiments/batches/B12.md` does not exist.** `b12_smoke_rev1.m`,
   `b12_battery_rev1.m`, `cfg.los_phase` and `cfg.time_variability` are all in
   the working tree, so the B12 code landed without a registered plan. This
   proposal registers predictions for both runs as 1301 and 1302.
2. **`experiments/proposals/` and `docs/research/FUTURE_RESEARCH_PLAN_rev1.md`
   are not in this clone**, and neither is in git on any branch. The H-codes used
   above (H01-H06, H12, H16, H19, H20, H21) are reconstructed from LOG.md and
   B11.md only; H07-H11, H13-H15, H17 and H18 could not be resolved and are not
   cited.
3. **707's screened figure is stale.** `results.tsv` records screened 11.2 dB,
   which was correct against the 14-link screen; under the current 36-link screen
   it is 9.91 dB. 711 and 712 were scored against the 36-link screen, so the
   screened column is not comparable across rows. Rescoring `000-baseline` and
   707 would fix it.
4. **The working tree carries uncommitted changes to `eval/` and `data/`**
   (including `longterm_screen_rev1.csv`, `score_rev1.m`, `run_eval_rev1.m`), and
   the B07 to B12 work is not committed on `main`. All numbers here are from the
   working tree as of 2026-11-23.
5. **The noise floor is still TODO** (FRAMEWORK.md, roadmap Phase 1). Headroom at
   the floor is reported at 3, 5 and 8 dB because no measured floor exists. A
   floor estimate from the Phase 2 runs, if per-run values can be recovered from
   `data/raw/its_phase2.zip`, would sharpen every number in section 2.
6. **Three `params_exp.m` switches are placeholders** the core never reads:
   `cfg.effective_height`, `cfg.effective_height_alpha`, `cfg.troposcatter`,
   `cfg.variability`. A worker setting one through `ITMEXP_OVERRIDES` would get a
   silent no-op rather than a loud failure.
7. **R3 is saturated** by FRAMEWORK.md's own rule: 0.58 dB from perfect, 0.15 dB
   at a 5 dB floor, no censored rows. It should stop being a target and stay a
   guard.

## Files

- `experiments/proposals/headroom_map_rev1.md` — this document.
- `experiments/proposals/headroom_map_rev1.py` — classification, score replication, counterfactuals and the paired bootstrap; writes `headroom_classes_rev1.csv`.
- `experiments/proposals/headroom_smoke_rev1.py` — the three model-only smoke tests (M6, M7, M16).
- `experiments/proposals/itm_stock_py_rev1.py` — the validated Python transcription of the stock core, used only to read out mode and geometry.
- `experiments/proposals/headroom_classes_rev1.csv` — one row per class: counts, weight shares, mean and RMS error, censored violations, and every counterfactual with its 95 % interval.
