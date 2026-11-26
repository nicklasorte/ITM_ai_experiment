# Prompt for a Fable planner session: phase plan rev 6 (research-heavy)

Written 2026-11-26 by Claude Opus 5.5 after B33; revised the same day to make the
session research-led. Paste the block below into a Fable session with the repo checked out
at `main`.

```text
You are the planner (Agent-Role: planner) for nicklasorte/ITM_ai_experiment. Write phase plan
rev 6. This session is research-led: most of your effort goes into reading primary public
sources, and the plan rests only on what you verified in them.

READ THE REPO FIRST, in order: CLAUDE.md, FRAMEWORK.md, program.md,
experiments/proposals/phase_plan_rev5.md, experiments/proposals/data_proposal_rev1.md,
experiments/proposals/post_b32_ten_experiments_rev1.md (Nick's ten proposals X01 to X10, the
red-team appendix and revision 2; revision 2 governs), results/results.tsv,
results/batch_stability.tsv, results/archive_rev1.txt, the last 12 entries of
experiments/LOG.md, experiments/batches/B27.md to B33.md, and
experiments/writeup/writeup_draft_rev1.md.

WHERE THINGS STAND
- Best is 707: composite 12.51 dB, screened 9.91, censored 22.8 % (707r-rescore-screen36). It's
  ITM with the delta construction L_ba + max(A_s - L_bs, 0) (P.452-18 eq. 38 to 40, P.526
  cascade) and P.2108 terminal clutter at siting C. k = 9; read program.md for what the tenth
  scored candidate needs.
- Every registered batch is closed (B01 to B33). Nothing is queued.
- B28 and B29: calibrating 707's constants gives no held-out gain (best 2903, screened
  +0.11 dB, lo995 -0.06).
- B30: LANDFIRE vegetation height shows a resolved slope only at R2 (-1.11 dB per m), post hoc.
- B31 to B33 use OT Report 75-74 (Longley and Hufford 1975; 172.5 and 410.5 MHz; transmitters
  0.35 m; receivers 10, 3 and 0.35 m; Eglin, Graham Mountain, Hunter Liggett), now inspected
  development evidence, not a holdout.
  - B32: ITM rejects heights below 0.5 m, so 0.35 m was modeled at 0.5 m. On the 3 m to 10 m
    contrast, no stratum favors 707 and one favors stock (outcome C, not equivalence). Both
    models predict far less loss than measured at Eglin (about 14 to 30 dB).
  - B33: measured loss shifts between seasons on unchanged paths (4 of 8 strata resolved,
    1.4 to 2.2 dB); models predict zero by construction. Graham's 3 m minus 10 m response
    changes with season, with opposite signs by band. Season shifts are 0.3 to 1.05 times the
    10 to 90 % width. Moving the transmitter from 0.5 to 1.0 m changes C_hi by under 1 dB on
    about 92 % of paths, but not at Eglin. On 12 of 840 rows, ITM's loss jumps up to 0.2 dB
    under 1e-13 m profile rounding. Equipment and calibration per season weren't audited.
  - D2 (Ofcom) is parked behind a human check only Nick can clear.
- The lockbox isn't a gate, but never read lockbox data or plan around a lockbox score.

RESEARCH PHASE (do this before planning; budget most of the session here)
Search for and read primary public sources: ITU-R Recommendations and Reports, NTIA/ITS
(and OT, NBS) reports, ESSA and NBS technical notes, IEEE and Radio Science papers, and
government measurement reports. Prefer the original document over summaries. For each source,
record in a source register: full citation, URL, edition or version, the sections and
equations you actually read, and one line on what it supports. Mark anything you only saw
in a search snippet as "unverified" and don't rely on it.

Answer these questions, each with the sources that settle it:
Q1. Low antennas and near-ground propagation at VHF and UHF: what do published measurements
    and theory (Norton surface wave, minimum effective antenna height, Bullington, the ITS
    sensor-path reports and their sequels) say about loss and height gain for antennas below
    1 m? Is there a published model, valid below 0.5 m, that could serve as a reference?
Q2. Forest and vegetation with a terminal in or under the canopy: what do ITU-R P.833 (the
    current edition), Tamir's lateral-wave work, the US Army and ITS foliage measurements and
    later papers give for excess loss versus frequency, depth and antenna height? Which
    formulation uses only published constants and fits the Eglin geometry?
Q3. Seasonal change on fixed paths: what does the literature report for leaf-on against
    leaf-off, soil moisture and ground constants, at these frequencies, and what sizes and
    signs? Does any source explain opposite-sign height responses by band?
Q4. OT 75-74 itself and its companion reports: what did the authors conclude, what equipment,
    calibration and season dates do they document, and do later ITS reports reuse or correct
    this data? This is the metadata audit Nick's revision 2 asks for before any season work.
Q5. ITM's internal discontinuities: what does the ITM documentation (NTIA ITM code and
    TN 101, TR 82-100, Hufford's notes) say about horizon and effective-height determination
    that could explain 0.2 dB jumps under tiny profile changes?
Q6. Independent data: which public, non-lockbox measurement sets (ITS, NTIA, ITU-R
    Study Group 3 databanks, national regulators, journal supplements) have low-antenna,
    forested or multi-season path loss with terminal coordinates? Give access status and size.
Q7. Anything else you find that names a physical mechanism ITM omits, with a public source,
    and that differs from every closed attempt in results.tsv, the archive and B18 to B33.

PLANNING TASK (after the research)
1. Decide whether the phase should stop under program.md's stopping rule. Give the reason in
   three sentences or fewer, naming the population each claim rests on.
2. If it continues, rank at most three items, drawn from X01 to X10 (revision 2) or from your
   research. Each must name its physics and public source with section and equation numbers;
   say which closed attempt is nearest and how it differs; add no fitted or unsourced
   constant; and give a falsifier, a model-only headroom estimate (hm_screen_rev1.py) where
   it's a model change, and a population. A diagnostic must say what decision it would change.
   Say plainly if nothing meets these bars.
3. If the phase stops, write the close-out plan instead: what the final write-up says, what
   the reviewers check, and what new public data would justify reopening.
4. For the top item (or the close-out), write the next free batch file (B34) so a Haiku worker
   can run it exactly: checks written before code, including a smoke trial of the exact
   configuration before any job longer than a few minutes; file list; commands; stop
   conditions; registered predictions; and a "Not done" section.

OUTPUTS
- experiments/proposals/phase6_research_rev1.md: the answers to Q1 to Q7 and the source
  register (verified and unverified sources listed separately).
- experiments/proposals/phase_plan_rev6.md: the decision and ranking.
- experiments/batches/B34.md.

RULES
Edit only experiments/. Don't edit eval/, data/, FRAMEWORK.md, program.md or CLAUDE.md. Never
read lockbox data. Public and cleared sources only; paraphrase, and quote at most a short
phrase from any source. No invented constants: cite a source or mark it TODO. Plain technical
English, Google developer documentation style. Before committing, have one fresh reviewer check
each claim sentence against its data and each citation against its source, and apply the
findings. Commit with an Agent-Role: planner trailer, run
python3 .github/scripts/guard_rev1.py --range origin/main..HEAD, and push. Results that leave
the repo need Nick's read first.
```
