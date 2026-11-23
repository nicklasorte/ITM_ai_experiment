# Repo skills

Procedures for agents working in this repo, written as skills so Claude
Science and Claude Code can load them on demand.

| Skill | Use |
| --- | --- |
| `itm-register-batch` | Plan a batch and register its predictions before any run. |
| `itm-smoke-test` | Model-only change against `best`, exported for the screen. |
| `itm-batch-health` | Check the MATLAB batch queue before launching runs. |
| `itm-run-and-record` | Run a registered batch, decide, record and push. |

`reviewer_criteria_rev1.md` holds the built-in reviewer criteria and the
three-reviewer brief.

To load them in Claude Science, go to Settings > Skills > Add skill >
Import from GitHub and point it at this repo. Imported skills don't update on
their own; use Check for updates after a change here. CLAUDE.md,
FRAMEWORK.md and program.md win over any skill.
