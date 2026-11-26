# Prompt for a Fable planner session: phase plan rev 6

Written 2026-11-26 by Claude Opus 5.5 after B32. Paste the block below into a Fable session
with the repo checked out at `main`.

```text
You are the planner (Agent-Role: planner) for nicklasorte/ITM_ai_experiment. Write phase plan rev 6.

Read first, in order: CLAUDE.md, FRAMEWORK.md, program.md, experiments/proposals/phase_plan_rev5.md,
experiments/proposals/data_proposal_rev1.md, results/results.tsv, results/batch_stability.tsv,
results/archive_rev1.txt, the last 12 entries of experiments/LOG.md, experiments/batches/B27.md
through B32.md, and experiments/writeup/writeup_draft_rev1.md.

Where things stand:
- Best is 707: composite 12.51 dB, screened 9.91, censored 22.8 % (scored as
  707r-rescore-screen36). It's the delta construction L_ba + max(A_s - L_bs, 0) with P.2108
  terminal clutter at siting C. k = 9 scored candidates; read program.md for the interval and
  acceptance rule the tenth needs.
- Phase plan rev 5's queue is empty, and the data proposal has one item left:
  - B27 (D27): R1 open blocked-blocked height pairs, 149 pairs on 29 bases. 707's height-gain
    error +5.64 dB against stock ITM's +10.43; bracket share 0.10; blend ceiling 0.00. Outcome C.
  - B28: constrained calibration of 707's constants can't run; fold 4 is infeasible under the
    stock-referenced censored rule (excess from R2).
  - B29: the same calibration with the censored rule referenced to 707 itself. Three scored
    (k = 7 to 9), none kept; the best was 2903 (time spread), screened +0.11 dB, lo995 -0.06.
    707's predictions barely depend on its diffraction and line-of-sight constants.
  - B30 (D30): LANDFIRE vegetation height along every Phase 2 profile. Only R2 shows a resolved
    slope of 707's error on vegetation above the antennas (-1.11 dB per m); outcome B; post hoc.
  - B31 and B32 (D31, D32): OT Report 75-74 (Longley and Hufford 1975; 172.5 and 410.5 MHz,
    transmitters 0.35 m, receivers 10, 3 and 0.35 m; Eglin, Graham Mountain, Hunter Liggett),
    data the search never used. ITM rejects heights below 0.5 m, so B32 modeled 0.35 m antennas
    at 0.5 m (amended before any output). On the 3 m to 10 m contrast, outcome C: no stratum
    favors 707, one favors stock. Both models predict far less loss than measured at Eglin
    (14 to 30 dB). At 172.5 MHz, 707's absolute error is 2.5 to 5.5 dB lower than stock's at
    every table and height, because it adds loss; at 410.5 MHz neither is consistently lower.
    These absolute errors weren't deciding and carry the 0.5 m height offsets.
  - D2 (Ofcom frequency contrasts) is parked: the Ofcom site shows a human check that only Nick
    can clear.
- Nick told the loop to ignore the lockbox as a gate. That doesn't lift the rule against reading
  lockbox data; don't read it or plan around a lockbox score.

Your task:
1. Decide whether the phase should stop under program.md's stopping rule. Say why in three
   sentences or fewer, naming the population each claim rests on. Weigh B28 and B29 (the
   constants carry no held-out gain) and B32 (no contrast advantage on outside data).
2. If it continues, rank at most three new mechanisms or data tests. Each must:
   - name its physics and a public source (ITU-R Recommendation, NTIA report or journal paper),
     with the section and equation numbers you read;
   - differ in mechanism from every closed attempt in results.tsv, the archive and B18 to B32,
     and say which closed attempt is nearest and how it differs;
   - add no fitted or unsourced constant;
   - give a falsifier, a model-only headroom estimate (hm_screen_rev1.py), and a population.
   One candidate area to assess, not a requirement: the absolute level on forested, very low
   antenna paths (Eglin in B32 and R2 in B30 point the same way), with a public vegetation source
   such as ITU-R P.833 that fits a terminal inside or under the canopy.
   Say plainly if nothing meets these bars. A short honest plan beats a padded one.
3. If the phase stops, write the close-out plan instead: what goes into the write-up's final
   version, what the reviewers check, and what new public data would justify reopening it.
4. For the top item (or the close-out), write experiments/batches/B33.md so a Haiku worker can
   run it exactly: checks written before code (including a smoke trial of the exact configuration
   before any job longer than a few minutes), file list, commands, stop conditions and a
   "Not done" section.

Rules: edit only experiments/ (plans); nothing in eval/, data/, FRAMEWORK.md, program.md or
CLAUDE.md. Never read lockbox data. Public and cleared sources only. Plain technical English,
Google developer documentation style. Before committing, have one fresh reviewer check each claim
sentence against its data and each citation against its source. Commit
experiments/proposals/phase_plan_rev6.md and experiments/batches/B33.md with an
Agent-Role: planner trailer, run python3 .github/scripts/guard_rev1.py --range origin/main..HEAD,
and push.
```
