# B34 partial existing-output replay — 2026-11-26

Diagnostic only; no score. Source blobs D31 ot7574_tables_rev1.csv 9436f2ae17bae4e486393eafa8a4179530bba448 (3780 rows), D32 tx_sensitivity_rev1.csv 12f6fe457f7c90d89bdfcc7a775785c2490ac74f (840 rows). Parsed CSV with quoted-field support; measurement key uniqueness checked. Detected unflagged finite values only; Graham R5 and Hunter T7 excluded for seasonal primary. Quantile orientation assumed from B33 ordering, not source verified. No calibration audit. This is partial exploratory replay, not registered D34 completion.

Crossed bootstrap: 2000 draws per endpoint, observed eligible TX and RX sampled separately with replacement, multiplicity product weights, empty draws omitted; LCG seed 20261126, update (1664525*s+1013904223) mod 2^32; sequential independent draws per endpoint (deviation from registered shared area draws), order Graham then Hunter, VHF then UHF, S10,S3,J,dW10,dW3,dK10,dK3. Quantile index floor(p*(n-1)). Leave-one-terminal range over both TX and RX deletions. Small receiver counts mean descriptive only. No independent inference.

| Population | Endpoint | n | TX | RX | Mean dB | Crossed interval dB | Leave-one range dB | Empty draws |
|---|---|---:|---:|---:|---:|---|---|---:|
| Graham VHF | S10 |30|9|4|0.803|-2.536 to 3.556|0.343 to 1.959|0|
| Graham VHF | S3 |34|10|4|2.097|-0.705 to 5.237|1.396 to 2.681|0|
| Graham VHF | J |29|9|4|2.152|-1.269 to 6.027|1.312 to 3.475|0|
| Graham VHF | dW10 |15|8|2|-1.287|-3.350 to 1.600|-2.208 to -0.243|0|
| Graham VHF | dW3 |16|8|3|0.006|-3.700 to 5.100|-2.111 to 1.925|23|
| Graham VHF | dK10 |15|8|2|-1.207|-3.937 to 2.375|-2.875 to 0.700|0|
| Graham VHF | dK3 |16|8|3|-0.719|-5.100 to 4.656|-2.222 to 0.425|28|
| Graham UHF | S10 |19|10|4|0.821|-2.485 to 3.700|0.127 to 1.300|13|
| Graham UHF | S3 |18|9|4|-1.550|-7.275 to 0.122|-2.422 to -1.153|16|
| Graham UHF | J |17|9|4|-2.747|-6.775 to 0.078|-4.056 to -2.143|12|
| Graham UHF | dW10 |12|9|2|-4.492|-7.275 to 1.100|-5.725 to -2.025|2|
| Graham UHF | dW3 |14|9|3|-2.507|-4.778 to 0.050|-3.123 to -1.580|33|
| Graham UHF | dK10 |12|9|2|-4.075|-5.900 to -1.700|-4.575 to -3.075|1|
| Graham UHF | dK3 |14|9|3|-1.750|-5.478 to 4.100|-2.690 to 1.300|31|
| Hunter VHF | S10 |32|9|4|1.934|0.220 to 4.085|1.333 to 2.438|0|
| Hunter VHF | S3 |28|9|4|1.457|-0.709 to 3.990|0.835 to 1.850|0|
| Hunter VHF | J |26|9|4|-0.504|-2.296 to 1.894|-1.164 to 0.028|0|
| Hunter VHF | dW10 |26|9|4|-0.035|-0.991 to 1.164|-0.205 to 0.189|0|
| Hunter VHF | dW3 |24|9|4|-0.383|-1.825 to 1.170|-0.755 to 0.076|0|
| Hunter VHF | dK10 |26|9|4|-0.142|-1.565 to 1.257|-0.555 to 0.281|0|
| Hunter VHF | dK3 |24|9|4|1.017|-0.150 to 2.371|0.789 to 1.400|0|
| Hunter UHF | S10 |30|9|4|1.200|-0.536 to 3.625|0.408 to 1.652|0|
| Hunter UHF | S3 |23|9|4|0.783|-1.086 to 2.510|0.395 to 1.230|0|
| Hunter UHF | J |20|9|4|-0.295|-1.931 to 1.300|-0.875 to 0.129|0|
| Hunter UHF | dW10 |21|9|4|-0.152|-1.721 to 1.900|-0.594 to 0.562|0|
| Hunter UHF | dW3 |20|8|4|-0.150|-1.382 to 1.345|-0.394 to 0.377|1|
| Hunter UHF | dK10 |21|9|4|1.457|-0.057 to 2.829|0.931 to 1.694|1|
| Hunter UHF | dK3 |20|8|4|0.040|-1.315 to 1.207|-0.344 to 0.493|2|

All four J intervals span zero; Graham signs survive single terminal deletion but not crossed resampling. No seasonal correction supported. Hunter VHF S10 interval excludes zero but not +1 dB, and calibration unknown.

## D34b partial replay

325 deciding table-band-path observations reproduced. T7 retained here to match B33. Percent below 1 dB at both TX perturbations; max is over BOTH 0.7 and 1.0 m (not B33's 1.0-only max). Last columns mean signed 707 minus stock delta-C at 0.7 m, and mean paired absolute contrast-error difference at 0.7 and 1.0 m (negative favors 707).

| Population table/band | n | 707 % | 707 max dB | stock % | stock max dB | delta diff dB | error diff 0.7 | error diff 1.0 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| All |325|92.923|5.364|92.308|7.249|0.249|-0.054|0.006|
|7 VHF|39|82.051|1.990|76.923|5.837|0.360|-0.367|-0.468|
|7 UHF|37|78.378|3.841|72.973|7.249|0.421|-0.449|-0.192|
|8 VHF|35|100|0.826|100|0.796|0.121|-0.193|-0.087|
|8 UHF|18|94.444|1.134|94.444|2.253|0.268|-0.110|0.073|
|9 VHF|33|100|0.826|100|0.796|0.137|1.230|1.238|
|9 UHF|39|97.436|1.134|97.436|2.253|0.186|-0.245|-0.151|
|10 VHF|31|93.548|4.836|93.548|1.675|0.195|-0.007|0.012|
|10 UHF|31|96.774|5.364|100|0.957|0.298|-0.173|-0.115|
|11 VHF|34|94.118|4.836|94.118|1.675|0.186|0.180|0.180|
|11 UHF|28|96.429|5.364|100|0.957|0.318|-0.342|-0.321|

Eglin stock maximum across both perturbations is 7.249 dB, not directly comparable to B33's 1 m-only 6.3 dB. Overall mean paired error differences near zero do not establish equivalence. No below-domain inference.

Not done: original source page audit, censor bounds, shared bootstrap draws, B33 original interval replay, 0.35 m descriptive endpoints, ratio, terminal maxima/sign reversals/T7 sensitivity for height, synthetic tests, standalone script, full factorial, D34c MATLAB trace, independent reviewer and CI. Results generated via connector-side JS calculation, not MATLAB. Do not mark B34 closed. No frozen input, code, score or lockbox changes. Human review before external use.
