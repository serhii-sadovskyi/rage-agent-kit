---
name: task:implement
description: Phase 4 — write the code for one approved task.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Implement a task

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, next command named, then stop. Never start the next phase yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

## Before starting

Stop if the task's Design is empty on a `single` or `multi` tier — for a `bug` it is empty on
purpose; work from the Requirements and Acceptance criteria. Stop too if the Verification
section has no core-test record, or names core tests that are not in the checkout — name
`/rage-agent-kit:task:test-core`.

## Read scope

**The task file, its parent `spec.md`, the ADRs either one links, the core tests its
Verification section names, and the code the task touches. Nothing else** — not other tasks,
not unlinked ADRs. These documents should hold everything you need; if they turn out not to,
that is a finding to raise at the gate, not a reason to read more.

Load the domain skills matching the files you edit (see the conventions).

## Steps

1. **Start with the interfaces.** If the core-test record lists examples that failed only
   because an interface did not exist yet, add those interfaces first as empty shells — the
   classes and methods the Design names, with the signatures it gives and no behavior — and
   run those examples once. Each must now fail on its assertion. One that passes against an
   empty shell does not check its criterion, and one that fails for another reason does not
   check what it claims: stop, show the output, and name `/rage-agent-kit:task:test-core` as
   the command that revises it.

2. **Implement the task's Design, within its Implementation constraints.**

3. **When the design turns out to be wrong, stop instead of improvising.** Say what does not
   work and what you propose instead, and let the engineer decide whether to update the design
   or change the approach. Quietly implementing something different leaves a design document
   that no longer matches the code, which is worse than no design at all.

   Small differences from the design that do not change the interface or the acceptance
   criteria you may make yourself — patch the task's Design to match, so it does not lie, and
   name them at the gate.

4. **Running tests is allowed in this phase.** Run the core tests and the existing tests
   covering the files you touched. Do not run the full suite, linters, or doc validation —
   linters and doc validation run once in `/rage-agent-kit:task:apply-findings`, and no phase
   runs the full suite.

   **Do not edit the core tests.** They are the contract the engineer approved before the code
   existed. A core test that looks wrong — it checks something the Design does not say, or it
   cannot pass without breaking an Implementation constraint — is a finding: stop, show the
   failure, and let the engineer decide; if they agree the test is wrong,
   `/rage-agent-kit:task:test-core` revises it. Do not change the test to make it pass, and do
   not bend the code away from the Design to satisfy it.

   An existing example that fails because the Design changed the behavior it checks, on
   purpose, is not a problem in the code: name it at the gate — `task:test-edge` updates it.
   One that fails for any other reason is a finding.

5. **Record any significant decision** as a `proposed` ADR, as the conventions describe, at
   the moment you make it.

6. **Gate.** Show a line-level diff of the code, name any difference from the design and why,
   report the empty-interface run from step 1, each core test as red → green (and any still
   red, with the reason), the other tests you ran and their result, and the existing examples
   left for `task:test-edge`. Give the blocking-I/O or equivalent audit the project's
   `CLAUDE.md` requires — "none" is a valid result, silence is not. The next command is
   `/rage-agent-kit:task:test-edge` — or, for a `bug` that may skip it (see Tiers in the
   conventions), `/rage-agent-kit:task:review`, with `task:test-edge` as the optional step.
   Then stop.

## Do not

- **Do not write or edit tests.** The core tests come from `/rage-agent-kit:task:test-core`;
  the rest of the coverage, and the updates to existing examples the task changed on purpose,
  are `/rage-agent-kit:task:test-edge`, the next phase. Do not add an example to prove a change
  works, and do not adjust an existing stub, helper, or fixture so new code passes — a test
  that still fails when the code is done is a finding for the gate.
- Do not implement more than this task, even when the next one looks like two more lines. The
  boundary between tasks is what makes each one possible to review.
- Do not fix unrelated problems you notice. Note them at the gate; let the engineer decide
  their scope.
