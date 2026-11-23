# Data sources

All data in `data/raw/` are public NTIA/ITS downloads, unmodified.

| File | Source | SHA-256 |
| --- | --- | --- |
| `its_phase2.zip` | ITS legacy radio propagation data, Phase 2 UHF spot measurements (`phase_2.zip`), https://its.ntia.gov/data/legacy-radio-propagation-data/ ; same file as `nicklasorte/matlab_itm` `docs/model_comparison/data/its/its_phase2.zip` | `30e611b88b2188aedbe408c04b05e90dd52e35f2512c3bcf6d120142458ac668` |
| `longterm.zip` | ITS legacy radio propagation data, long-term distributions, https://its.ntia.gov/media/66292/longterm.zip (Longley, Reasoner, and Fuller, OT/TRER 16, 1971) | `c04d65be42cac0b64275d7c647d732712e6d68e041c8239fb38ecbcb3314f3c6` |

Phase 2 references: McQuate et al., ESSA Tech. Rep. ERL 65-ITS 58, parts 1–3
(1968–1970); Hufford and Steele, NTIA Report 91-282 (1991) for the Virginia
set. See `nicklasorte/matlab_itm` `docs/model_comparison/data/its/README.md`.

Long-term notes: quantiles are hourly-median attenuation relative to free
space (base FS) at 0.01, 0.1, 1, 10, 50, 90, 99, 99.9, and 99.99 % of time.
The archive has no terrain profiles. `export_profiles_rev1(Extract=true)`
samples each one with `itm_terrain_profile_rev1` at 30 m (USGS 3DEP in the
US, Copernicus 30 m elsewhere), one path at a time, and deletes the tiles
after writing the profile.

## Terrain profiles

`profiles/<dataset>/<path_id>.csv` holds one profile per file: header `h_m`,
then one elevation in metres per line (4 decimals), transmitter first, at
the spacing given in `profiles/profiles_index_rev1.csv`. Phase 2 profiles
are the surveyed profiles from the data set, resampled linearly to 30 m.
Copernicus DEM: © DLR e.V. 2010–2014 and © Airbus Defence and Space GmbH
2014–2018, provided under COPERNICUS by the European Union and ESA; USGS
3DEP is public domain.

## Long-term screen list (D01, 2026-11-21)

`data/links/longterm_screen_rev1.csv` lists 14 long-term rows on 10 paths
whose path type in the 1971 record (Longley, Reasoner, and Fuller, OT/TRER 16)
is LOS but whose 30 m terrain profile blocks the 4/3-earth ray between the
antennas. The rule was fixed before any experiment. The rows stay in the
frozen set; `score_rev1` reports scores with and without them, and a kept
change must improve both. Generated from
`experiments/D01-longterm-level/rows_rev1.csv`; hash in
`longterm_screen_rev1.sha256`.

## Refractivity at path midpoints (B14, proposed 2026-11-23)

`data/links/path_refractivity_rev1.csv` gives, for each of the 840 paths in
`profiles/profiles_index_rev1.csv`, the average annual radio-refractivity
lapse rate through the lowest 1 km of the atmosphere, `dN` (N-units/km), and
the sea-level surface refractivity `N0_map`, at the path midpoint. Source:
the ITU-R digital maps DN50.txt and N050.txt named in ITU-R P.617-6 Table 1
(1.5° grid, originating from ITU-R P.452), read by bilinear interpolation
with the edge handling of the ITU-R P.452 reference implementation. Built by
`data/build_refractivity_rev1.m`. The maps themselves aren't in this repo,
because the ITU doesn't allow redistributing its digital products; only the
derived per-path values are. `N0_map` equals the existing `N_0` column at
every path (largest difference 0.00), which confirms the same map and
midpoint. Hash in `path_refractivity_rev1.csv.sha256`.

## Land cover along Phase 2 profiles (B17, proposed 2026-11-23)

`data/landcover/phase2_profiles_nlcd_rev1.csv` gives the USGS NLCD 2001 land
cover class (30 m, CONUS, MRLC coverage `mrlc_download__NLCD_2001_Land_Cover_L48`,
the edition approved for the terminal file in PR #6) at every sample of every
Phase 2 profile: 688,564 samples on 515 paths, run-length encoded (columns
`path_id`, `i_first`, `i_last`, `nlcd2001`; transmitter = sample 1). Samples
are placed on the great circle from transmitter to receiver at the profile's
own spacing. Built by `data/build_landcover_profiles_rev1.m` from the MRLC
GeoServer WCS, one window per path. Every sample has a class; the runs tile
each profile exactly (checked by the builder). Forest classes (41, 42, 43, 90)
cover 60 % of VA samples, 53 % of R2, 18 % of R1 and 1.5 % of R3. Land cover
can have changed since the 1960s measurements. Hash in
`phase2_profiles_nlcd_rev1.sha256`.
