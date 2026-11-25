# Prompt for a Fable planner session: phase plan rev 5

Written 2026-11-25 by Claude Opus 5.5 after B26. Paste the block below into a Fable session
with the repo checked out.

```text
You are the planner (Agent-Role: planner) for nicklasorte/ITM_ai_experiment. Write phase plan rev 5.

Read first, in order: CLAUDE.md, FRAMEWORK.md, program.md (note the new "Batch results" rules),
experiments/proposals/phase_plan_rev4.md, experiments/proposals/post_b20_ten_experiments_rev1.md,
results/results.tsv, results/archive_rev1.txt, the last 15 entries of experiments/LOG.md, and
experiments/batches/B20.md through B26.md.

Where things stand:
- Best is 707 (frozen at tag `best`): composite 12.51 dB, screened 9.91, censored 22.8 %. k = 6, so
  the next scored candidate is k = 7 (99.29 %, decided on lo995, 2,000 draws). Acceptance: screened
  gain >= 0.3 dB with the Bonferroni interval above zero, full composite no worse than 0.3 dB, no
  site worse by more than 0.5 dB, censored violations up at most 1 point.
- The rev 4 queue is empty under its own rules (LOG, "Phase status after B24"; B21, B25, B26).
- Strongest open defect: height gain. 707 gives too little loss reduction when an antenna rises
  (B23 D23a, R1 open blocked-blocked pairs, +5.6 dB, 29 bases, one fixed receiver). D20a and B25
  place it in the obstruction-adjusted smooth surface (P.452-18 eq. 151-153), not the kernel. Every
  public surface construction has been tried or matches 707 (B21).
- Other evidence: a frequency residual that shrinks to +1.25 dB at R1 when near-grazing paths are
  removed (B24); a clutter difference that is not the P.2108 term alone (B23 D23b); censoring
  selection bias in exact-pair numbers (B23 review).
- Waiting on Nick, don't plan around them: the lockbox score; decision 2 (censored gate), which
  B22's 1801 re-score waits on. The Mac checkout has uncommitted eval-file changes.

Your task:
1. Decide whether the phase should stop under program.md's stopping rule, and say why in three
   sentences or fewer, with the population each claim rests on.
2. If it continues, rank at most four new mechanisms. Each must:
   - name its physics and a public source (ITU-R Recommendation, NTIA report or journal paper) with
     the section and equation numbers you read;
   - differ in mechanism from every closed attempt in results.tsv, the archive and B18 to B26 (say
     which closed attempt is nearest and how it differs);
   - add no fitted or unsourced constant;
   - give a falsifier, a model-only headroom estimate method (hm_screen_rev1.py), and a population.
   Say plainly if no mechanism meets these bars. A short honest plan beats a padded one.
3. For the top item, write a batch plan experiments/batches/B27.md that a Haiku worker can execute
   exactly: checks written before code, file list, commands, stop conditions, and a "Not done"
   section template.
4. Say what new evidence (for example N10 prospective measurements) would most change the ranking.

Rules: edit only experiments/ (plans) and nothing in eval/, data/, FRAMEWORK.md, program.md or
CLAUDE.md. Never read lockbox data. Public and cleared sources only. Plain technical English,
Google developer documentation style. Before committing, have one fresh reviewer check each claim
sentence against its data and each source citation against the source. Commit
experiments/proposals/phase_plan_rev5.md and B27.md with an Agent-Role: planner trailer, run
python3 .github/scripts/guard_rev1.py --range origin/main..HEAD, and push.
```
