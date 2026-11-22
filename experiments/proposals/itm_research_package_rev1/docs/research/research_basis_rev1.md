# Research basis and repository review

## Scope and snapshot

The repository was read at `main` commit `5d39122275ef2b1b9c93be1e72007e61a90b53cc`. The implementation under test is a MATLAB copy of ITM v1.4 pinned to `nicklasorte/matlab_itm@9bd6a4e`. The harness uses ITS Phase 2 spot measurements at 50% time and ITS long-term distributions. Terrain profiles are frozen CSV profiles sampled at 30 m. The requested work is planning only.

The controlling files are `README.md`, `FRAMEWORK.md`, `program.md`, `CLAUDE.md`, `docs/PLAN_rev1.md`, `docs/WORKING_PAPER_FINDINGS.md`, `eval/score_rev1.m`, `eval/physics_battery_rev1.m`, and `experiments/LOG.md`.

## What the current evidence says

Stock ITM has composite 16.0249 dB, Phase 2 cell-balanced RMS 18.3155 dB, long-term level RMS 24.6042 dB, long-term shape RMS 5.1550 dB, and 573 violations among 2,045 censored Phase 2 bounds, or 28.0196%. It has 14,760 uncensored Phase 2 rows represented by 513 site/siting path IDs. The README's 426-path description is a different nominal-path grouping. Preserve both counts and state the unit used.

The current history contains 16 structural evaluations through B05. B01–B03 tested profile diffraction, region selection, and phasing. B04–B05 tested delta-Bullington and multi-edge forms. The best composite diagnostic is 502 (`delta_bullington_afo`) at 11.13 dB, but it has 966 lower-bound violations, or 47.2%, and is therefore rejected. Stock ITM remains the eligible parent. This matters because a lower RMS is not evidence of a better propagation model when it predicts signal below a measured no-signal bound.

D01 found 14 long-term rows whose 1971 record says line of sight while the 30 m profile blocks the 4/3-Earth ray. D03 found that R2 no-signal rows have more separated Deygout edges, greater obstruction, longer paths, and higher frequency than measured rows even when delta-Bullington loss is held in bins. These are diagnoses, not proof of causality.

## Physical opportunity map

The original working-paper diagnosis identifies five separable gaps. ITM extrapolates a diffraction line from synthetic distances `d_3` and `d_4`. It combines terrain knife-edge, smooth-earth, and `A_fo` terms in a way that can overpredict loss on rough 15–150 km paths. It uses effective-height horizons and can classify a profile-obstructed path as line of sight. Its two-ray reflection phase uses a flat-Earth phase expression while the surrounding geometry uses an effective Earth. Its terrain roughness is a single interdecile statistic, and its time-variability model does not represent a stable diffracted link as a two-leg distribution.

Each proposed experiment isolates one of these mechanisms. H01 tests coupled wave diffraction by multiple screens. H02 tests the reflection phase geometry. H03 tests a documented two-leg distribution for a common ridge. H04 tests the terrain-statistic representation. H05 tests rounded-obstacle curvature. None imports a site offset or an unobservable loss constant.

## Primary source map

- NTIA, *The ITS Irregular Terrain Model, version 1.2.2 Algorithm*, official algorithm and source index: https://its.ntia.gov/software/itm/
- Hufford, Longley, and Kissick, NTIA TR-82-100, definition of `Δh` as the 90th minus 10th percentile about a fitted line: https://its.ntia.gov/publications/download/82-100_ocr.pdf
- ITU-R P.526-16 (11/2025), §§2.4–2.5, §4.2, §4.3, and §4.5: https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.526-16-202511-I!!PDF-E.pdf
- Vogler, NTIA Report 83-124, §§2–3: https://its.ntia.gov/publications/download/83-124_ocr.pdf
- Rice, Longley, Norton, and Barsis, NBS Technical Note 101, §§7.5, 9.5, and 10.8: https://its.ntia.gov/publications/download/TN101v1.pdf
- ITU-R P.530-19 (09/2025), Annex 1 §§6.1.2.3–6.1.2.4.1: https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.530-19-202509-I!!PDF-E.pdf
- ITU-R P.2001-6 (09/2025), Attachment E: https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I!!PDF-E.pdf
- Barsis and Kirby, J. Res. NBS 65D (1961): https://nvlpubs.nist.gov/nistpubs/jres/65D/jresv65Dn5p437_A1b.pdf
- Hufford and Steele, NTIA TR-91-282: https://its.ntia.gov/umbraco/surface/download/publication?reportNumber=91-282.pdf
- Ofcom, UK data below 6 GHz: https://www.ofcom.org.uk/siteassets/resources/documents/spectrum/radiowave-propagation-measurement/sub-6ghz-propagation-measurement-data.pdf

## Source and implementation limits

The frozen profiles are one-dimensional and linearly interpolated. They cannot establish transverse terrain curvature, a reflecting patch, vegetation, or a complete sub-sample crest shape. A source formula may therefore be scientifically valid while a proposed test remains unidentifiable on this dataset. Each proposal states when it must stop as a mechanism diagnostic rather than become a global model change.
