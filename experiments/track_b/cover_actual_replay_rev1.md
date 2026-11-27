# Actual environmental replay rev1
Snapshot 4cdbfd7244295a290064cd0ed02f304005976f94. Exploratory JS replay, not registered scored candidate. Git blob fetch retrieved NLCD and EVH full text. Selected first three lexicographically sorted eligible path IDs per site, open siting O, censored=0, nonempty finite measurement and archived ITM, finite antenna heights. All eligible rows on selected paths. 828 rows, 12 paths. No fit, no lockbox, no evaluator change.
Inputs data/links/phase2_links_rev1.csv, data/profiles/profiles_index_rev1.csv, data/profiles/phase2/<id>.csv, data/landcover/phase2_profiles_nlcd_rev1.csv, experiments/D30-landfire-evh/phase2_profiles_evh_rev1.csv. Verified run tiling and profile length, not SHA256 or orientation independently. JS equivalent dominant edge formula, not execution of Python adapter. D=spacing*(n-1), effective radius 4/3*6371000 m, FSPL uses D, v=sqrt(2)*clearance obstruction/r1, J=0 for v<=-.78 else max(0,6.9+20log10(hypot(v-.1,1)+v-.1)). Known tree heights only NLCD 41/42/43/90 and EVH 101..199 -> code-100 m. Unknown height omitted from partial sensitivity, not asserted clear. Direct ray overlap mean over interior samples. Errors prediction minus measured. Archived stock not fresh execution.
|path|n|terrain RMSE|opaque RMSE|stock RMSE|mean overlap|tree fraction|dominant tree fraction across rows|unknown tree fraction|
|---|---:|---:|---:|---:|---:|---:|---:|---:|
|P2_R1_R1-003-T2_O|91|4.7301|8.0437|5.2860|.004624|.0100|0|0|
|P2_R1_R1-003-T3_O|91|5.1802|5.1802|5.2766|0|0|0|0|
|P2_R1_R1-003-T4_O|91|8.5441|8.5441|7.5951|0|0|0|0|
|P2_R2_R2-003-T3_O|52|18.1135|16.1536|27.4041|.073013|.887755|1|.051020|
|P2_R2_R2-003-T4_O|91|7.7772|19.4758|7.7760|.070965|.848485|1|.020202|
|P2_R2_R2-003-T5_O|91|31.9236|14.3529|19.3394|.255768|.752577|1|.092784|
|P2_R3_R3-003-T1_O|105|6.4983|6.4983|6.4976|0|0|0|0|
|P2_R3_R3-003-T2_O|105|4.1755|4.1755|4.1809|0|0|0|0|
|P2_R3_R3-003-T3_O|90|8.4331|8.4331|8.4320|0|0|0|0|
|P2_VA_T1-003-R1_O|7|30.5175|20.3389|30.5537|.129338|.533898|0|.008475|
|P2_VA_T1-003-R2_O|7|7.8801|11.5636|5.0864|.200625|.438776|0|.112245|
|P2_VA_T1-005-R1_O|7|20.7561|14.4387|9.2344|.150591|.532544|.428571|.023669|
## Review
Small deterministic convenience sample, clustered endpoints, no uncertainty, historical cover mismatch, no urban heights, no target GHz validation, no runtime comparison. Similar overlap R2 T3/T4 opposite outcome; no monotone correction justified. This does not establish superiority of Fresnel features over whole-path fractions. Next reproduce with hash-checked executable driver, compare geometry-only, whole-path, edge-local and overlap features with shifted-cover controls and site holdout, then derive partial transmission/edge grouping. No independent reviewer.
