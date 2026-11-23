---
name: itm-batch-health
description: Check that the Mac's MATLAB batch queue starts jobs before an ITM_ai_experiment run, and stop with a clear report if it doesn't. Use at the start of any session that will launch evaluator runs, the physics battery, or long smoke tests.
---

# MATLAB batch-queue health check

On 2026-11-22 batch jobs stayed queued for hours after a MATLAB MCP session
hung, and a whole batch waited. Check the queue before planning around it.

## Steps

1. **Session responds.** Run `disp(version)` through the MATLAB MCP. If the
   call times out, try the other MATLAB server if one is listed, and record
   which one answered.
2. **Queue starts a trivial job.**

   ```matlab
   c = parcluster;
   j = batch(c, @() 1 + 1, 1, {}, 'AutoAddClientPath', false, 'AutoAttachFiles', false);
   pause(45); disp(j.State)
   ```

   `finished` within 60 s means healthy. Delete the test job afterwards.
3. **If it stays `queued`:**
   - List `c.Jobs` with IDs, states and creation times, and report them.
   - Don't quit or restart MATLAB, and don't delete other jobs, without
     Nick's yes.
   - A fresh `JobStorageLocation` didn't help last time; don't count on it.
   - Log the failure as `infra` in the LOG and the batch plan. It isn't an
     experiment result. Retry once after Nick restarts MATLAB.
4. **Work that doesn't need the queue** can go on: interactive chunked
   smoke tests, parity checks on short row sets, the history-matching
   screen and any analysis on stored CSV files.

## Rules that still apply

- Don't use `system()` or `!` from the MCP session.
- Each MCP call is capped at about 80 s. Anything longer is a batch job.
- Add the script's folder to the client path before `batch`, and pass
  `eval/` and that folder in `AdditionalPaths`, with `AutoAddClientPath`
  and `AutoAttachFiles` set to false.
