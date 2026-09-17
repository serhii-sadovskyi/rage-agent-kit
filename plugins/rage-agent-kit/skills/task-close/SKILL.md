---
name: task:close
description: Phase 8 — accept a finished task's ADRs and close the task.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Close a task

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, status changes listed, then stop.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

## The ADRs are what remain after the feature is done

After the feature is `done` the ADR is the only place a decision survives (see The goal in the
conventions), and the component document links to it without repeating it. So:

- **Point into the code.** Name the classes, methods, and files the decision produced, in the
  Decision or Consequences section. Code stays current; a task's Design describes what was
  intended.

Complete does not mean long. The decision, the constraint that forced it, the rejected options,
the consequences, and pointers into the code — for anything beyond that, it is better to work it
out again from the code, which is actually current.

## Read scope

The task file — its Verification records (see Records in Verification in the conventions),
including any closing evidence from an earlier run of this phase. Also the feature spec's
Tasks and Decisions sections, the feature's `proposed` ADRs,
and — where an ADR has to be checked against the code — the task's diff in the Rage checkout
(see The Rage checkout in the conventions). The review report (see Review reports in the
conventions) adds detail when it is on this machine; it is not required.

## Steps

1. **Check each `proposed` ADR from this task against the code.** If what was built
   matches, add the code pointers and set it `accepted`. If implementation or review changed
   the decision, patch Decision and Consequences to what was built and say so at the gate. If
   the decision was replaced completely, set the old ADR `superseded`, naming its replacement.

   Where "Options considered" has little detail, say so in the ADR instead of filling the gap
   with a reason that sounds right — a gap you record honestly still tells the reader
   something. A reason you invented misleads them.

2. **Look for a significant decision with no ADR** — in the task's Implementation constraints
   and in any deviation from the Design. Name it at the gate and ask; do not write one from
   memory.

3. **Close the task.** If the core-test record or the review-outcome record is missing — or
   the edge-test record, unless the task is a `bug` that skipped `task:test-edge` (see Tiers in
   the conventions) — tick nothing and say which is missing. Otherwise, tick an acceptance
   criterion only when both are true:

   - **It is proven**, by one of the kinds of evidence the conventions list (Evidence for a
     criterion).
   - **The review does not contradict it:** the review-outcome record does not list the
     criterion as unmet, or lists its fix as applied. An applied fix is not evidence on its
     own — the criterion still needs the first condition.

   For a criterion whose example did not run in the final run, or that no test can prove, ask
   the engineer for a CI run or their own check, and record the answer under
   `**Closing evidence**`. If they cannot give it yet, leave the criterion unticked.

   Name every criterion left unticked, and why. Set the task `done` only when every criterion
   is ticked. Fill Result with the implementation PR if one exists; if not, leave the
   placeholder and name it at the gate.

4. **Update the feature spec.** Tick the task in its Tasks list, and make sure every ADR is
   linked from its Decisions section — restore the section from the template if `feature:new`
   removed it (see Recording decisions in the conventions).

5. **If this was the last task**, leave the feature spec `implementation` and name
   `/rage-agent-kit:feature:close` as the next command, to run once the work is merged. Do not
   close the feature spec here.

6. **Gate.** Show the ADR and task changes as a line-level diff, list the status changes
   made, and name anything left for the engineer — a PR link, a merge, a CI run or a check
   that an unticked criterion still needs. If the task is still `todo`, the next command is
   this one again, once that evidence exists. Otherwise the next command is
   `/rage-agent-kit:task:design` for the next task, or `/rage-agent-kit:feature:close` after
   the last one. Then stop.

## Do not

- Do not write an ADR for a decision that was never made. A task with only one approach
  that works and no rejected alternatives needs no ADR, and should not get one that looks
  important and says nothing.
- Do not change code in this phase.
