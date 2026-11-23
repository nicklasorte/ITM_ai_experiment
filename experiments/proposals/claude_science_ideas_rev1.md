# Claude Science ideas for ITM_ai_experiment

Planner: Claude Opus 5.5, 2026-11-22. Requested by Nick. Sources are public
Anthropic documentation, Anthropic announcements, press coverage, and
journal or preprint papers; links are at the end of each section.

This note answers three questions:

1. What do Claude Science's features do, and how have others used them?
2. Which of those uses carry over to this repo's ratchet loop?
3. What adjacent fields do something close to this repo, and what can we
   borrow from them?

It ends with a ranked list of ideas, each tied to an acceptance gate in
FRAMEWORK.md, and the limits to plan around.

## Constraint to plan around first: MATLAB

Claude Science runs Python, R and shell code in a sandbox on the Mac. It has
no MATLAB kernel. Its starter environments are Python (numpy, pandas, scipy,
matplotlib) and R (tidyverse). The sandbox reads and writes only the
workspace and granted folders, and its network is deny-by-default.

Three ways to reach MATLAB, to test in this order:

1. **Add the MATLAB MCP server as a custom connector.** Claude Science
   accepts connectors by remote URL or by local command (Settings >
   Connectors > Add connector > Local command). This is the same server the
   Claude Code sessions use. Test with a call that runs
   `itm_exp_paths_rev1` and one batch job.
2. **Call `matlab -batch` from the shell.** It may be blocked by the sandbox,
   because MATLAB is outside the granted folders. Test once; don't work
   around a refusal.
3. **Work only from CSV outputs.** Much of the analysis needs no MATLAB at
   all: `experiments/<tag>/predictions_*.csv`, `cells_phase2.csv`,
   `metrics.json` and `results/results.tsv` are plain files. The headroom
   map (running now) works this way.

Run the evaluator and physics battery only through MATLAB. Do analysis,
diagnostics, literature work and writing in Python inside Claude Science.

Sources: [Tools and environments](https://claude.com/docs/claude-science/tools-and-environments.md),
[Core concepts](https://claude.com/docs/claude-science/core-concepts.md),
[Connectors and skills](https://claude.com/docs/claude-science/connectors-and-skills.md).

## Features, how others used them, and the ITM version

| Feature | What it does | How others used it | ITM version |
| --- | --- | --- | --- |
| Reviewer and Specialists | Re-reads responses, plans, artifacts and the execution record, and checks that claims match what ran. It doesn't re-run analyses. Custom review criteria and new specialists go in Settings > Specialists. | Lecoq (Allen Institute) paired writing agents with reviewer agents. A customer quote credits agentic fact-checking for confidence in outputs. | Make the three reviewer agents (every 10 keeps) into Specialists. Add FRAMEWORK.md gates as reviewer criteria (see idea 2). |
| Skills | Written instructions loaded when relevant. Created by chat, by hand, by upload, imported from GitHub (private repos with a token), or distilled from a session. | Lecoq built about 20 custom skills for a multi-agent review template. | Distill the repo's repeated procedures into skills (see idea 3). |
| Delegation and forks | Splits a request into parallel tracks; a fork compares two approaches without losing the original. | Anthropic's protein-design study ran all targets in one session and also one target per session. | Fork to compare rival forms of one mechanism (H01 Vogler against 707's P.526-11 cascade). Delegate literature tracks by mechanism. |
| Provenance and artifacts | Each output keeps its code, environment, a plain-language description and message history. Figures can be annotated in place. | Francis (UCSF) had his group validate results independently; Lecoq valued how each fact's derivation is recorded. | Every figure in a LOG entry or briefing gets a provenance bundle that links it to the run tag and commit. |
| Literature access | Open-access full text through Unpaywall, Semantic Scholar and PubMed Central; OpenAlex and arXiv through the Literature Graph connector. Paywalled HTML isn't scraped. | Literature reviews in neuroscience and genomics; Lecoq notes paywalls limited coverage. | Pull NBS, NTIA and ITU-R sources for the mechanism catalog. ITS reports and ITU-R Recommendations are free, which suits this repo. |
| Remote compute | SSH to HPC, SLURM sweeps, or Modal GPUs. | Parameter sweeps and ML jobs. | Low priority: runs are MATLAB-bound and take minutes. Useful only for a Python reference ITM sweep (idea 6). |
| Memory and project instructions | Facts kept across sessions, and instructions read at the start of every session. | General. | Already set up with the project instructions. |

Sources: [The reviewer](https://claude.com/docs/claude-science/the-reviewer.md),
[Connectors and skills](https://claude.com/docs/claude-science/connectors-and-skills.md),
[Core concepts](https://claude.com/docs/claude-science/core-concepts.md),
[Literature access](https://claude.com/docs/claude-science/literature-access.md),
[Announcement](https://www.anthropic.com/news/claude-science-ai-workbench),
[Product page](https://claude.com/product/claude-science),
[Protein design study](https://anthropic.com/research/Claude-accelerates-protein-design),
[The Scientist, early verdicts](https://www.the-scientist.com/early-verdicts-on-claude-science-faster-workflows-but-gaps-remain-74745).

## Adjacent fields and what to borrow

### Automated ML research (Karpathy's autoresearch)

This repo's layout comes from autoresearch:

- a human-only `program.md`
- an agent-edited model file
- a frozen evaluator
- `results.tsv`
- a keep-or-revert ratchet

autoresearch runs without stopping, keeps a commit only if validation loss
improves, and prefers simplicity over small gains.

What this repo adds, and should keep: predictions registered before each
run, a physics battery, held-out folds, a censored gate, and reviewer passes.
autoresearch has none of these, because a language-model loss has no
physics to violate.

What to borrow: the overnight cadence. Claude Science's auto mode plus
delegation can run a planned batch end to end while Nick is away, stopping
only at permission cards and at keep decisions. Keep decisions stay gated by
the three reviewers.

Source: [DataCamp guide to autoresearch](https://www.datacamp.com/tutorial/guide-to-autoresearch).

### Climate model tuning (history matching)

Climate modellers tune expensive models against observations with history
matching. They don't hunt for one best setting. Instead, they use fast
emulators and an implausibility measure to rule out regions of parameter
space, and they treat structural model error as a separate term (model
discrepancy). Williamson and colleagues also used it to find and remove
structural biases in HadCM3.

What to borrow:

- **Model discrepancy as a floor.** For each row class, estimate the error a
  perfect version of a given mechanism still couldn't remove: measurement
  noise, terrain-data limits, and the 1960s siting uncertainty. That is the
  headroom map's noise floor; this literature gives the method.
- **Implausibility before runs.** Rule out mechanism and switch combinations
  whose best case can't pass the 0.3 dB gate, before spending runs on them.
  B11 and B12 would have been flagged this way: each touched too few rows.
- **Structural-bias framing.** A persistent site bias (R1 +4.1 dB, VA
  -2.9 dB in 707) is a structural error to explain with physics. It isn't
  a parameter to tune away; this matches the rule against site offsets.

Sources: [Williamson et al., structural biases with history matching](https://nora.nerc.ac.uk/id/eprint/509284/1/Williamson_et_al_StructErrorPaper.pdf),
[History matching with a 10,000-member ensemble](https://eprints.soton.ac.uk/359716),
[Emulator diagnostics and premature convergence](https://pmc.ncbi.nlm.nih.gov/articles/PMC5157755).

### Multi-agent literature review (Allen Institute)

Lecoq's template: sub-agents extract key claims from thousands of papers,
writing agents draft sections, and reviewer agents check them. He reports
about 10 long reviews done this way, and says human reviewers still connect
disparate ideas better and errors still need checking.

What to borrow: a claim-level evidence table for each mechanism in the
research package. Record the claim, the source section and equation, the
measurement campaign it rests on, the frequency and distance range, and
whether that campaign overlaps this repo's Phase 2 or long-term data.
Overlap matters: TN101-era measurements may share ancestry with the
evaluation data, which the H03 proposal already flags.

Source: [Announcement](https://www.anthropic.com/news/claude-science-ai-workbench).

### Target ranking (Manifold Bio)

Manifold ranked drug targets on several criteria with its own internal data.
The ITM version is hypothesis ranking: headroom times plausibility, minus
cost. The headroom task running now produces this ranking.

Source: [Announcement](https://www.anthropic.com/news/claude-science-ai-workbench).

## Ranked ideas

Each idea names the gate in FRAMEWORK.md it serves, what it needs, and the
outside check that shows it worked.

### 1. Headroom map before any new batch (running now)

- **What:** attribute 707's error by row class, compute each class's best
  possible gain, and rank mechanisms by possible gain times plausibility.
- **Serves:** the 0.3 dB gain gate. It stops runs that can't pass it.
- **Needs:** CSV outputs only.
- **Check:** recompute 707's composite from the class contributions to
  within 0.05 dB of `metrics.json`.

### 2. FRAMEWORK.md gates as reviewer criteria

- **What:** in Settings > Specialists > Reviewer, add these criteria:
  - every dB figure in a response matches `metrics.json` or the LOG
  - the commit that registers predictions comes before the run commit
  - no file under the lockbox path was opened
  - no change to `eval/` or `data/`
  - every new constant has a citation or a TODO
  - no unpublished or restricted model is named
- Also create three Specialists for the reviewer pass every 10 keeps:
  - **Physics:** limits, reciprocity and continuity.
  - **Statistics:** fold leakage, paired intervals and multiple testing
    across batches.
  - **Red team:** the strongest case that a keep is overfit.
- **Serves:** every gate. The reviewer checks claims against the record.
- **Needs:** settings only.
- **Check:** seed a deliberate mismatch (a wrong composite in a draft LOG
  entry) and confirm the reviewer flags it.

### 3. Repo procedures as skills

Distill from the Claude Code sessions, then import from GitHub:

- `itm-register-batch`: plan, smoke test, predictions, commit, push.
- `itm-run-and-record`: launch, collect, decide, record, branch, rebuild
  `best`.
- `itm-smoke-test`: model-only change against `best` on all rows, with no
  measured loss read.
- `itm-batch-health`: check that the MATLAB batch queue starts a trivial
  job, and stop with a clear message if it doesn't. Today's queue failure
  cost a batch.

- **Serves:** worker reliability and the Haiku worker role.
- **Needs:** the skills written and kept in this repo or in
  nicklasorte/skills.
- **Check:** a fresh session runs B12 from the skills alone, with no other
  guidance, and gets the same parity figure.

### 4. Forks for rival forms of one mechanism

- **What:** use a fork to compare two forms of one mechanism side by side,
  for example H01's coupled two-screen field against 707's P.526-11 cascade
  on the rows where the principal edge switches. Do the same for H02's phase
  against the P.530 eq. (132) divergence-amplitude rival (H18).
- **Serves:** physics battery continuity, and the record of rejected rivals.
- **Needs:** MATLAB access (constraint above).
- **Check:** both forks score the same `best` and the paired difference is
  reported.

### 5. Claim-level evidence table for the research package

- **What:** the Allen-style table above, for H01 to H21.
- **Serves:** the source rule (public, cited) and the risk of overlapping
  datasets.
- **Needs:** literature access; free ITS and ITU-R PDFs.
- **Check:** the reviewer confirms each cited section supports its claim.

### 6. Independent reference check of the MATLAB ITM

- **What:** before trusting new runs, reproduce published reference cases.
  Do these two:
  - the TN101 section 7.5 worked example (still a TODO in B12)
  - the test cases that ship with NTIA's reference ITM, run on the same
    inputs as the MATLAB port
- **Serves:** parity, and confidence in the stock baseline.
- **Needs:** check whether NTIA ITS publishes a Python-callable ITM build
  that installs in the sandbox. If it doesn't, compare against its
  published test-case outputs.
- **Check:** agreement within ITS's own stated tolerance.

### 7. Model-discrepancy floor from history matching

- **What:** estimate, for each row class, the error no ITM change could
  remove: repeat-measurement spread where runs exist, and terrain and siting
  uncertainty. Use it as the noise floor in the headroom map and as an
  implausibility cut before each batch.
- **Serves:** the gain gate, and planning effort.
- **Needs:** Phase 2 `runs` column and the long-term records; no new data.
- **Check:** the floor is below 707's RMS in every class. If a class sits at
  the floor already, stop working on it.

### 8. Overnight batches in auto mode

- **What:** once ideas 2 and 3 exist, run a registered batch overnight with
  delegation (one track per experiment), stopping at keep decisions for the
  reviewers and Nick.
- **Serves:** throughput, without loosening any gate.
- **Needs:** MATLAB access and a healthy batch queue.
- **Check:** the morning LOG matches the run records, and the reviewer has no
  open findings.

### 9. Briefing artifacts with provenance

- **What:** when results are ready to leave the repo, produce figures and a
  short technical note with provenance bundles: residual maps, CDFs against
  measurement, and the before-and-after composite.
- **Serves:** "results that leave the repo get Nick's read first."
- **Needs:** Nick's decision on audience and timing.
- **Check:** every number traces to a run tag and commit.

## Limits to plan around

- The reviewer checks claims against the record; it doesn't re-run analyses
  or judge whether a method fits the question. The physics battery and
  held-out folds stay the real tests.
- Early users report errors that still need careful checking, weaker
  judgment of paper quality, and slower local computation.
- Paywalled papers aren't reachable without your own credentials. ITS
  reports and ITU-R Recommendations are free, so this matters little here.
- Claude Science's files, artifacts and history stay on the Mac they were
  made on. Commit anything durable to the repo.
- A Claude Science session and a Claude Code session can both commit to the
  Mac's working copy. Pull before starting each, and push only after review.

Sources: [The reviewer](https://claude.com/docs/claude-science/the-reviewer.md),
[The Scientist, early verdicts](https://www.the-scientist.com/early-verdicts-on-claude-science-faster-workflows-but-gaps-remain-74745),
[Literature access](https://claude.com/docs/claude-science/literature-access.md),
[Core concepts](https://claude.com/docs/claude-science/core-concepts.md).
