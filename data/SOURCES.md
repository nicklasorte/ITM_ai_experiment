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
