# Experiment log

Write each entry before the run, then complete it after. Newest at the
bottom.

## Template

```text
### NNN-short-name
- Date:
- Tier: 0 | 1 | 2 | 3 | 4
- Function(s) touched:
- Rationale (one sentence, physical):
- Predicted effect: which sites/bands improve, which don't change
- New free parameters: N (names, bounds, source)
- Result: score_cv X dB (Δ vs best), worst cell, per-site RMS, censored violations
- Physics battery: pass | fail (which check)
- Decision: keep | reject
- Prediction came true? yes | partly | no, and what that tells us
```

## Entries

### 000-baseline
- Date: 2026-11-21
- Tier: none
- Function(s) touched: none (unmodified `itm_p2p_core.m`, `nicklasorte/matlab_itm` at `9bd6a4e`)
- Rationale: reference point
- Result (ITS Phase 2, uncensored, from the existing `its_phase2_results.csv`):
  row RMS 16.74 dB; cell-balanced path-weighted RMS 18.3 dB; worst cell
  38.2 dB; site RMS R1 13.2, R2 29.9, R3 8.7, VA 16.3 dB
- Note: a leave-one-site-out constant offset doesn't help (VA gets worse,
  16.3 → 17.7 dB), so the error is path-specific, not a bias
- Decision: baseline; must be reproduced exactly by `eval/` in Phase 0
