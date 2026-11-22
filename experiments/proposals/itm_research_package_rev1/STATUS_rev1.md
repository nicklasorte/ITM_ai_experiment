# Research package status (planner note)

Added 2026-11-22 at Nick's request. The package files in this folder are kept
as received. The package README asks for its research documents to go in
`docs/research/`; agents can't write there (CLAUDE.md), so the whole package
lives here with its own folder structure. Nick can move the documents to
`docs/research/` if he wants them there.

## What's out of date

The package was written against `main` at commit 5d39122, with experiments
through B05 and diagnostics D01–D03. Since then:

- **Parent model.** 707 is kept and is `best` (composite 12.51 dB, censored
  22.8 %; LOG "KEEP 707"). The package's statements that stock ITM is the
  eligible parent, and its 373-repair arithmetic from 502, no longer apply.
  New experiments branch from `best` and score with
  `Best="707-cascaded-isolated-clutter-at-r"`.
- **Censored ceiling.** The package reads the gate as at most one percentage
  point over the current best. FRAMEWORK.md fixes it at 29.0 % (stock 28.0 %
  + 1). Nick decided on 2026-11-22 to keep the overall gate and report
  censored violations by site in every run.
- **A_fo.** Removed from the delta forms after the B06 reviewer pass;
  proposals that keep 502's A_fo need a new parent.
- **Terminal clutter.** P.2108-1 section 3.1 at concealed sites is in 707.
  The package's H20 (VA clutter) is now approved to proceed with a NLCD
  land-cover input (data/ PR pending).
- **Tooling.** Experiments run in parallel through
  `experiments/batches/launch_runs_rev1.m` with per-run overrides; see the LOG
  entry "Tooling: parallel runs and run records".

## Mapping to work already done

| Package item | Status in this repository |
| --- | --- |
| H01 Vogler coupled two-screen field | Not run. Highest relevance after B08–B09: 707's P.526-11 three-edge cascade jumps about 30 dB when the principal edge switches (LOG, 2026-11-22), and P.526-16 section 4.4 failed continuity (B09). A coupled-field oracle is the principled test. |
| H02 Curved-Earth reflection phase | Not run. Clean zero-parameter candidate on line-of-sight rows. |
| H03 Two-leg time variability | Not run. Targets the long-term shape error D05 measured (spread too narrow below 100 km, too wide beyond 300 km), which no run has moved. Median-neutral by design, so it can't hurt the censored gate. |
| H04 Multi-scale roughness | Not run. |
| H05 Rounded isolated ridge | Not run. Its radius from P.526-16 section 4.2 eq. (37)–(38) sidesteps the eq. (122) sign question that stopped the rounded form of section 4.4 in B09. |
| H06 continuous Fresnel clearance | Partly covered by D04 (Fresnel intrusion doesn't explain open clear paths). |
| H08 EP coherent coupling | B09 is relevant: section 4.4's sum of knife edges plus sub-path terms isn't continuous on multi-ridge terrain. |
| H09 profile-consistent smooth reference | 707 uses the delta construction; the antenna-height inversion traced to P.452-18 eq. (166) (LOG, 2026-11-21) is a known side effect. |
| H11 profile horizons for region selection | Tested as 105 (rejected). |
| H20 VA terminal clutter | Approved with NLCD input (pending). |
| H21 profile aliasing | D05 found the long-term level outliers are terminal-geometry artifacts at mountaintop sites; screen-rule data/ PR pending. |

## Planner's next-batch order

1. H02 (phase) and H03 (two-leg variability) as B11, in parallel: both have
   zero fitted parameters, exact formulations in the package, and source
   checks that run before any score.
2. H01 as a diagnostic oracle against 707's cascade on the R2 multi-ridge
   paths, before any model change.
3. H05 as the matched-path curvature diagnostic.

Each still needs its equations rechecked against the cited edition, as the
package itself says.
