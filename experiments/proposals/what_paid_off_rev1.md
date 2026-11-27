# What has paid off in improving ITM against the measurements (through B38)

Planner: Claude Opus 5.5, 2026-11-27, for Nick. This is a synthesis of
`results/results.tsv`, `results/batch_stability.tsv`, `experiments/LOG.md`
and the batch files. It adds no new result. All numbers are on the
development data (Phase 2 at 50 %, and the long-term rows).

## The scoreboard

- 38 scored candidates (results.tsv, not counting references). One keep:
  **707**. Composite 12.51 dB against stock's 16.02 (−3.51; paired 95 %
  +2.30 to +4.41). Censored violations 22.8 % against 28.0 %.
- 707 by site, RMS at 50 % (stock in brackets): R1 10.5 (13.3), R2 18.2
  (28.6), R3 6.8 (9.0), VA 12.9 (15.4).
- No candidate after 707 has beaten it (711, 712, 1301, 1804, 1901,
  2901–2903). B30–B38 were diagnostics.

## What paid off, in order of size

1. **Profile-based diffraction in the delta construction** (ITU-R
   P.452-18 eq. (38)–(40) form, with ITM's own smooth-earth reference).
   This is where most of the gain is. 401 and 402 (Bullington) reached
   composite 11.5, but censored violations went to 68 %. The cascade
   (ITU-R P.526-11 section 4.4.2, isolation-weighted secondaries) with
   the troposcatter-line bound (604) kept most of the gain at 12.8, and
   censored fell to 31.5 %, just over the 29 % gate.
2. **ITU-R P.2108-1 section 3.1 terminal clutter at concealed sites, with
   the path computed at the clutter height** (707, after 701's double
   count was found). It added the loss that 604 was missing where a
   terminal sits behind trees or buildings, and it brought censored
   violations under the gate. That made 604's diffraction gain keepable.
3. **The process.** Independent reviewers caught 701's double count, B36's
   one-point PE average and B37's wrong switch assumption. Registering
   first, the censored gate and parity checks kept out changes that only
   looked better. That's why the keep count is one.

## What hasn't paid off

- **Land cover near or at the terminals, from class data:** 711 and 712
  (NLCD at open terminals, rejected), B17 (P.833 along the terminal rays,
  certain harm), 1806 (15 m canopy on every woodland sample, certain
  harm), B30 (LANDFIRE canopy height near terminals, RMS gain 0.26 dB at
  one site).
- **Repairs to the delta construction's heights and edges:** B18 (1801 to
  1807, one kept open, 1804 rejected when scored).
- **Calibration and time variability:** B28 and B29 (2901–2903, gains
  under 0.3 dB). **Troposcatter swaps:** 1301 and 1901.
- **A physics reference (PE):** B36 and B37. It's valid only on gentle
  paths, it couldn't be made wide-angle, and it can't reach R2, where
  707's error is largest, or R3.

## Where the remaining error is, and the two live leads (B36–B38)

- **R1 (too much loss).** 707's cascade adds about 2.2 dB over Bullington
  on R1's gentle open rows (B37), and about 9.5 dB on its diffraction-mode
  rows. Almost all of it comes from the secondary edges (B38 D38a,
  descriptive regrouping). Lead: limit the secondary edges where they
  over-count, without losing what they do at VA. It's model-only.
- **R2 and R3 (missing loss).** Within site, frequency and obstruction,
  rows whose first Fresnel zone holds more forest have more loss than 707
  predicts (B38 D38b, outcome F−). The outcome needs R3, whose slope is an
  extrapolation from small forest shares; R2 only just meets the rule. Lead: a vegetation term along the path, weighted
  by the Fresnel zone. That form hasn't been tried. It needs canopy height
  (the held data PR D2) and its own registration.

## Caveat

This is all on development data that many batches have read. This note
uses no lockbox result, and nothing here says how 707 or a new lead would
do on data the loop hasn't seen.
