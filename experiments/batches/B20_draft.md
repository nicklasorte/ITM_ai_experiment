# Batch B20 (draft): three diagnostics before the next candidates

Planner: Claude Opus 5.5, 2026-11-24, from
[phase plan rev 4](../proposals/phase_plan_rev4.md). Status: **draft**,
waiting for Nick's approval (plan decision 5). Parent: `best` (707).

No scored runs. Diagnostics don't count toward the Bonferroni k. They read
development data only, never lockbox data. Each one has a decision rule,
fixed here before it runs, that picks what goes into B21.

707's settings, as the launcher takes them (used by every script below):

```text
{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}
```

## Worker rules

- Put each script in `experiments/batches/` and its output in
  `experiments/<id>/summary.txt` plus CSVs. Name files with `_rev1`.
- Run MATLAB parts as `batch` jobs (CLAUDE.md). Fail with `error()` on any
  non-finite value.
- First, every script reproduces a stored 707 value to 1e-9 dB, or stops.
- Hand back to the planner on any error, or on a result that the decision
  rule doesn't cover.

## D20a: which term flattens height gain

**Question:** on the battery's ridge sweep and on the worst real paths, which
term of 707's delta cancels the height gain: L_ba, L_bs, A_s, the bound, or
the clutter term?

**Geometry:**
- The battery's `rx_height_ridge40` sweep (`eval/physics_battery_rev1.m`):
  40 km, 30 m spacing, triangular ridge `150 * max(0, 1 - abs(x - 0.5) / 0.05)`
  with x from 0 to 1, transmitter 10 m, receiver 1 to 30 m in 0.25 m steps,
  3000 MHz, climate 5, N_0 301, horizontal polarization.
- The two worst real paths from B18: P2_R2_R2-020-T2_O (9,190 MHz, antenna 2)
  and P2_R1_R1-005-T5, the height inversion (both its `_O` and `_A` rows,
  at the frequency B18 reports for the 4.5 dB case). Sweep the named antenna from 1 to 30 m in 0.25 m steps.

**Settings to run on each sweep:**
1. 707.
2. 707 with `diffraction_bound` = "none".
3. 707 with `smooth_heights` = "p452_ducting" (no obstruction adjustment).
4. 707 with `smooth_heights` = "itm_effective".
5. 707 with `smooth_heights` = "structural".
6. Stock ITM (`itm_p2p_rev1`).

**Outputs per setting and height:** A_ref, and the delta's parts: L_ba,
L_bs, A_s, the bound value and whether it binds, the smooth-surface
heights hst and hsr, and the heights above it hp. Add the parts to the
`info` output behind `want_info` (report-only fields, no change to A_ref;
the B18 `edge_switch` pattern). Check by test that A_ref is unchanged to
1e-12 dB with `want_info` on and off.

**Report:** net change from 1 to 30 m for each setting and each part, and a
plot of the parts against height for 707.

**Decision rule:**
- If setting 2 stays flat (within 1 dB of 707) and any of settings 3 to 5
  restores at least half of stock's net change, the smooth surface carries
  the flattening. B21 runs a smooth-surface candidate (phase plan R1) that
  differs from 1803 and 1804 in mechanism, after the planner checks P.1812-8
  §5.6 against the PDF.
- If setting 2 restores it, the bound carries it after all. Record that the
  rev-4 correction was wrong, and B21 takes the bound question instead.
- If no setting restores it, the flattening is in L_ba itself, and the hand
  back says so.

## D20b: what drives the overshoot on obstructed rows

**Question:** is 707's pessimism on obstructed rows at VHF and low UHF
carried by the cascade correction C, by the edge losses, or by A_s?

**Rows:** every in-scope Phase 2 row at 50 %, and long-term rows at 50 %.
Use 707's stored predictions and the measured loss (development data) for
the residual. Uncensored rows for error; censored rows reported apart.

**Per row, recompute 707's diffraction parts** with
`multi_edge_diffraction_rev1("p526_cascaded_isolated", ...)` and its `D`
output (edges, ν, weights), then:
- J(ν) for each edge, by ITU-R P.526-16 eq. (31)
  (J = 6.9 + 20 log10(sqrt((ν − 0.1)² + 1) + ν − 0.1) for ν > −0.78, else 0);
- C by P.526-11 §4.4.2 eq. (51) (C = 10 + 0.04 D, D in km) and T by
  eq. (52), as `multi_edge_diffraction_rev1.m` uses them;
- L_ba, L_bs and A_s from D20a's `info` fields.

Check that the recomputed parts add up to the stored 707 A_ref to 1e-6 dB on
every row, or stop.

**Report:** by set, band (<100, 100–300, 300 MHz–1 GHz, 1–3 GHz, >3 GHz),
and clear or obstructed (L_ba = 0 or not):
- rows, mean and RMS error;
- mean C·T, mean of the edge terms, mean A_s − L_bs;
- the regression of error on C·T within obstructed rows, by band, with a
  path bootstrap 95 % interval on the slope.

**Decision rule:**
- If the slope on C·T is positive with the interval above zero in at least
  two of the three bands below 1 GHz, and C·T is at least a third of the
  predicted diffraction loss there, C carries the overshoot. B21 runs one
  correction alternative (phase plan R2) whose keep path depends on plan
  decision 2.
- If clear rows show |A_s − L_bs| of 1 dB or more on average in any band,
  phase plan R4 (line-of-sight A_s) goes into B21 too.
- Otherwise neither runs; record what carries the overshoot.

## D20c: is the terminal clutter term physics or an offset

**Question:** does P.2108-1 explain concealed-minus-open loss better than a
constant?

**Pairs:** the 1,400 matched C/O pairs: same base path (path_id without its
`_C` or `_O` suffix), same frequency and antenna heights. Use pairs where
both rows are uncensored; report censored pairs apart.

**For each pair:**
- measured difference Δm = meas(C) − meas(O);
- 707's predicted difference Δ707 (the clutter term: terrain, bound and
  diffraction are the same for both rows);
- the constant control Δc: 704's constant (`terminal_clutter_db` from 704's
  `metrics.json` cfg);
- zero (no clutter term).

**Report:** by set, band and mobile antenna height:
- n, mean and RMS of Δm − Δ707, Δm − Δc and Δm;
- the slope of Δm against log10(f), and of Δ707 against log10(f);
- a leave-one-site-out comparison: RMS of Δm − Δ707 against Δm − Δc on the
  held-out site, for each of R1, R2 and VA.

**Decision rule:**
- P.2108-1 is supported if its leave-one-site-out RMS beats the constant on
  at least two of the three sites, and the measured frequency slope has the
  sign P.2108-1 predicts.
- Otherwise the term is recorded as an empirical offset: the write-up says
  so, and the next reviewer pass treats it as fitted.

## Outputs and records

- `experiments/D20a-smooth-surface-terms/`, `experiments/D20b-cascade-terms/`,
  `experiments/D20c-paired-clutter/`, each with `summary.txt` and CSVs.
- The `info` fields from D20a are the only change to `itm_variant/`
  (report-only; tests must show A_ref unchanged).
- One LOG entry for the batch, with each decision rule's outcome.
- A `results/batch_stability.tsv` row: 0 experiments, 0 kept.
- Commit with the `Agent-Role: worker` trailer, guard, push.
