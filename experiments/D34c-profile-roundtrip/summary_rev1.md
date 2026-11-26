# D34c: profile round trip and ITM's integer truncation (B34, diagnostic, no score)

Run 2026-11-26 on the Mac (MATLAB R2025b, matlab_itm at 9bd6a4e). Worker
and planner: Claude Opus 5.5. Scripts: `experiments/batches/d34_roundtrip_rev1.m`,
`d34_trace_rev1.m`. Registered in [B34](../batches/B34.md) section 4.
Nothing in `eval/`, `data/` or `itm_variant/` was changed; the trace used a
renamed, instrumented copy of the core in a scratch folder.

## Result

**The 0.197 dB discrepancy B33 found comes from the profile spacing alone,
through an integer truncation in ITM's least-squares fit for the
effective antenna heights. It is a property of ITM's algorithm as
ported, and it isn't a physical sensitivity.** The same truncation lines
are in the pinned stock source (`matlab_itm/private/itm_p2p_core.m` lines
408 and 409 at 9bd6a4e; text match, rechecked by the reviewer).

| Check | Population | Result |
| --- | --- | --- |
| Fresh profiles reproduce B32's stored predictions | 840 rows (B32 rows with a 3 m or 10 m receiver, transmitter 0.5 m), 130 pairs | Largest difference 5.1e-13 dB (limit 1e-6) |
| `%.17g` text and MAT round trips are bit-identical | 130 profiles | Yes, all |
| CSV profile differs from fresh | 130 profiles | Spacing differs on 127 (median 7 ULP, largest 14); elevations differ on all 130 (largest 5.0e-12 m, 28 ULP) |
| Stock ITM, CSV profile against fresh | 840 rows | 12 rows over 1e-6 dB; largest 0.197 dB |
| Stock ITM, fresh elevations with CSV spacing | 840 rows | The same 12 rows; largest 0.197 dB |
| Stock ITM, CSV elevations with fresh spacing | 840 rows | 0 rows; largest 3.0e-11 dB |
| 707, CSV profile against fresh | 840 rows | 16 rows over 1e-6 dB; largest 5.5e-4 dB |
| 707, spacing only / elevations only | 840 rows | 12 rows (largest 5.5e-4 dB) / 0 rows (largest 6.4e-7 dB) |

The 12 stock rows are two pairs, each in two tables (seasons):

| Population: pair | Rows | First instrumented integer truncation that differs (traced core, which reproduces both stock losses within 1e-9 dB) |
| --- | --- | --- |
| Hunter Liggett T4–R4 | 10 m receiver, both bands, Tables 10 and 11 (4 rows); stock 104.64 → 104.44 dB (VHF), 123.52 → 123.39 dB (UHF) | `linear_least_squares_fit`, end of the fit window: d_end / spacing = 92.000000000000014 (fresh) against exactly 92 (CSV spacing), so `i_end = np − fix(fdim(np, ·))` is 93 against 92 |
| Graham T3–R3 | 3 m and 10 m receivers, both bands, Tables 8 and 9 (8 rows); differences 0.07 to 0.12 dB | `linear_least_squares_fit`, start of the fit window: d_start / spacing = 74.99999999999925 (fresh) against 75.0000000000007 (CSV), so `i_start = fix(fdim(·, 0))` is 74 against 75 |

The 3 m rows of Hunter Liggett T4–R4 didn't change under the CSV spacing,
so they act as a matched control for that pair.

**Sensitivity to the spacing alone** (`perturbations_rev1.csv`, written by
`d34_perturb_rev1.m` with the exact spacing in hex; stock ITM; spacing
moved by −20 to +20 ULP, about ±7e-14 m, elevations fixed; a level is a
distinct loss after rounding to 1e-6 dB):

| Population: pair, band, receiver | Levels | Range (dB) | Monotonic in the offset |
| --- | --- | --- | --- |
| Hunter Liggett T4–R4, VHF, 10 m | 4 | 0.36 | No |
| Hunter Liggett T4–R4, VHF, 3 m | 2 | 0.32 | No |
| Hunter Liggett T4–R4, UHF, 10 m | 4 | 0.25 | No |
| Hunter Liggett T4–R4, UHF, 3 m | 2 | 0.15 | No |
| Graham T3–R3, VHF, 3 m | 2 | 0.12 | Yes (one step) |
| Graham T3–R3, VHF, 10 m | 2 | 0.11 | Yes (one step) |
| Graham T3–R3, UHF, 3 m | 2 | 0.07 | Yes (one step) |
| Graham T3–R3, UHF, 10 m | 2 | 0.07 | Yes (one step) |

On Hunter Liggett T4–R4 the loss jumps back and forth between levels as
the offset changes; on Graham T3–R3 it takes one step. So the CSV round
trip's 0.197 dB is one sample of a spread that, on Hunter Liggett, also
reaches the 3 m rows the round trip happened not to flip.

## Reading

- **Mechanism:** the distances passed to the fit (for example
  d_m − 0.9 d_hzn, with d_hzn a whole number of spacings) divided by the
  spacing land on, or within a few ULP of, an integer, and are truncated.
  Which side they fall on depends on the last bits of the spacing. Moving
  one end of the fit window by one sample changes the effective heights
  and so the loss.
- **Not physical:** the inputs differ by about 4e-14 m in spacing; no
  terrain or geometry change is involved.
- **What the trace shows and doesn't:** it logs only the integer results
  of four truncations, so it finds the first of those that differs; the
  real-valued quotients differ earlier (for example 68.000000000000185
  against 68.000000000000014 at the start of the Hunter Liggett window,
  which truncates to 68 either way). The horizon-index log stores no
  integer, so a horizon change couldn't have been flagged; none is
  implied.
- **707 is barely affected** on these rows (at most 5.5e-4 dB). The
  trace followed stock ITM only. 707's 16 rows, 4 of which (Graham
  T10–R1) aren't among stock's 12, weren't traced, so whether 707 has a
  second representation-dependent step of its own is open.
- **Scoring is consistent:** the evaluator reads the same CSV profiles for
  every model, so scores are reproducible. But a stock ITM prediction on a
  path can carry a few tenths of a dB that depends on how the profile was
  stored.

## Consequences

1. Any comparison that rebuilds profiles from text with fewer than 17
   significant digits can differ by a few tenths of a dB per row from one
   that uses exact profiles. Keep profiles in memory, as MAT files, or as
   `%.17g` text (both shown bit-identical here).
2. A repair (for example, rounding the quotient to the nearest integer
   when it lies within a few ULP of one, before truncation) would change
   stock ITM's behavior and the baseline, so it would need its own
   registration with continuity tests and the frozen acceptance gates, as
   B34 section 4 says. No patch is proposed or made here.

## Not done

- Synthetic flat and tied-horizon controls, and single-element elevation
  ULP perturbations.
- Tracing 707's 16 rows, and horizon angles, branch margins and modes
  beyond the first divergent truncation.
- Comparison with the NTIA C++ source itself (only the matlab_itm port
  was checked).
- A survey of how many Phase 2 or long-term rows sit near such a tie (the
  evaluator's CSV profiles weren't swept).
- `divergence_rev1.csv` as a separate file: its content is in
  `trace_rev1.csv`.
- Repeated deterministic runs as a separate check (the smoke and full
  runs agree on the shared pair, which is the only repeat).
- Traces of matched stable controls; Hunter Liggett T4–R4 at 3 m is a
  control by loss only.
- Effective heights, Δh, reference attenuation and variability terms in
  the trace.
- The exact parity maximum is printed in the run log (5.1e-13 dB) but
  not stored in a file.
