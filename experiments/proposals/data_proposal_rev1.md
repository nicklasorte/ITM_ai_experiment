# Data proposal rev 1: new public inputs that could reopen the structural search

Planner: Claude Opus 5.5, 2026-11-25. Status: proposal only. Nothing here
changes `data/`, the terrain source or the profile spacing. Each item needs
Nick's approval and a separate data PR, as B14 (refractivity) and B17 (land
cover) did.

## 1. Why new data

Phase plan rev 5 recommends stopping the structural search on the frozen
inputs, and B28 found little room in 707's constants (folds 1 to 3, training
rows: no gain for two groups, 0.09 to 0.20 dB for the time spread). Two kinds of
evidence would change the ranking (rev 5, "Evidence that would change the
ranking"):

1. Vegetation height along the paths. Forest covers 60 % of VA and 53 % of
   R2 profile samples (NLCD 2001, `data/SOURCES.md`). 707 uses no
   vegetation data along the path: its terminal clutter rests on the Phase 2
   siting code and an assumed 15 m height (`itm_variant/params_exp.m`).
2. Height and frequency contrasts with documented calibration at more than
   one fixed terminal per site. B23 to B27's height contrasts rest on one
   fixed receiver at R1.

## 2. Excluded on purpose

FRAMEWORK.md Tier B names three lockbox sets: ITS Phase 1 VHF, the ITS
low-antenna-height set (230 and 416 MHz, antennas under 3 m), and DBSG3
Table VI-2. They may hold the height and frequency contrasts item 2 asks
for, but the agent can't check that, because it never reads lockbox data. Nick's "ignore the lockbox"
(2026-11-25) removed the lockbox as a gate, not the rule against reading it.
This proposal doesn't use them.

## 3. Candidates

### D1. Vegetation height along Phase 2 profiles (recommended first)

| Source | Resolution and coverage | Basis | Terms | Notes |
| --- | --- | --- | --- | --- |
| LANDFIRE Existing Vegetation Height (EVH), USFS, USGS and The Nature Conservancy | 30 m, CONUS (LF 2025 is the current CONUS edition per the product page; earlier editions back to 2001) | Height of the dominant vegetation per cell, from field plots, lidar and Landsat (tree height range not verified) | Public domain (USGS LANDFIRE metadata) | Same 30 m grid as NLCD, which B17 sampled along the profiles; US government source |
| ETH Global Canopy Height 2020 (Lang et al., *Nature Ecology & Evolution* 7, 2023) | 10 m, global, year 2020 | Deep learning on Sentinel-2, trained on GEDI lidar; gives an uncertainty per pixel | Free (check the license text before a data PR) | Global, so it could also cover long-term paths outside CONUS |
| Meta and WRI High Resolution Canopy Height Maps | 1 m, global, imagery mostly 2018 to 2020 | Model trained on aerial lidar, applied to Maxar imagery | CC BY 4.0 (AWS Open Data registry entry) | Finest grid; imagery dates not verified; the publisher warns of no field validation above 25 m and of slope effects |

Sources: LANDFIRE EVH product description and data.gov catalog; Lang et al.
(2023); WRI Land & Carbon Lab dataset page.

Recommendation: LANDFIRE EVH. It's public domain, on the same 30 m grid as
NLCD (sampled along the profiles in B17), and from a US government source, which suits results that may
leave NTIA. ETH is the fallback for paths outside CONUS.

Caveat: every candidate maps vegetation decades after the 1960s
measurements. B17 has the same caveat for NLCD 2001.

How it would enter, in order:

1. **Diagnostic (no score).** A D-series batch that samples EVH along each
   Phase 2 profile (the B17 builder pattern: great circle, profile spacing)
   and tests one registered question: do 707's residuals track vegetation
   height near the terminals or at the principal edge, by site? All four
   sites, reported separately: VA and R2 have the most forest, and R1 and
   R3 carry 707's largest pessimism on open obstructed rows (rev 5).
   Population and strata fixed before the run.
2. **Data PR.** Only if the diagnostic shows a by-site signal: add
   `data/canopy/phase2_profiles_evh_rev1.csv` with a builder and hash, like
   B17.
3. **Model candidate.** Only then a scored change, for example clutter
   height from EVH instead of the P.2108 class default. It would have to
   cite a public method for using canopy height in a path-loss model.

Cost: one builder run on the Mac (515 paths, one WCS or file window each,
as B17), then one diagnostic script.

### D2. Frequency contrasts at fixed terminals: Ofcom UK drive-test data

Ofcom measured basic transmission loss in seven UK areas from 2015 to 2018
at six frequencies (449, 915, 1802, 2695, 3602 and 5850 MHz), with
calibrated equipment. The data is in the ITU-R Study Group 3 databank and
on Ofcom's open data pages. Ofcom's data description gives transmitters at
17 m (25 m in London) and a receiver at 1.5 m above ground. That gives same-path frequency contrasts
at fixed terminals with documented calibration, which B23 to B27 lacked.

Limits:

- It's mobile drive-test data in urban, suburban and rural clutter, at
  shorter ranges than Phase 2. Mixing it into the composite would change
  what the score measures. Propose it as a separate diagnostic target only:
  does 707 track the frequency contrast better or worse than stock ITM, by
  area?
- It has no height contrasts (one receiver height).
- Terrain would come from UK sources, not the frozen 3DEP and Copernicus
  set, so it would need its own profile build, kept apart from `data/`.

Terms: Ofcom releases its open data under the Open Government Licence v3.0
(check the specific dataset page before a data PR).

FRAMEWORK.md already lists Ofcom as a Tier C set (needs clutter, separate
track). This proposal keeps it there.

### D3. Height contrasts: ITS Eglin AFB sensor measurements (lower priority)

Longley and Hufford, OT Report 75-74 (1975), report VHF and UHF path loss
at Eglin AFB at 172 and 410 MHz with receiving antennas at 10, 3 and
0.35 m. That's a height contrast at fixed paths, and it isn't a Tier B
lockbox set. Phase 2 has rows at the same frequencies (172.98, 409.25 and
410 MHz), which makes it more relevant than its age suggests. But it exists
as PDF tabulations only, so it would need digitizing, with a second-person
check of every value. Listed as the third option.

## 4. Decisions for Nick

1. Approve the D1 diagnostic with LANDFIRE EVH? Recommended: yes. It's the
   cheapest test of the most likely missing input.
2. Approve D2 as a separate diagnostic (not in the score)? Recommended:
   after D1.
3. D3: no action unless D1 and D2 point at height gain.

## 5. Not done

- No dataset was downloaded or opened.
- License texts for ETH and the specific Ofcom dataset weren't read in
  full; read them before any data PR.
- LANDFIRE's tree height range and the Meta imagery dates weren't verified.
- The fresh reviewer read Ofcom's data description for the antenna heights
  and frequencies; the planner didn't.
