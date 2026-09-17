---
name: task:design
description: Phase 2 — design one task and write its acceptance criteria.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Design a task

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, next command named, then stop. Never start the next phase yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

**One task only.** Designing tasks ahead of the one about to be built is the failure this
phase exists to avoid: the design of task 2 depends on what task 1 taught you. A design
written early is either rewritten, or worse, followed after it is no longer true. If asked to
design several, design the first and say why the others wait.

## Read scope

The feature's `spec.md` (its Proposed behavior, Non-goals, Acceptance criteria, and this
task's entry in Tasks), the ADRs it links, the feature's component document, and the code the
task touches. For a `multi` feature, also the Design and Implementation constraints of its
earlier tasks that are `done` — what they built and decided is what this design builds on.
From other tasks, read only the boundary that the feature spec names.

The design keeps the component's **Invariants**. If it has to change one, say which one at the
gate and record the change as a `proposed` ADR.

## Steps

1. **Load the domain skills** matching the areas this task touches (see the conventions), and
   read the code it changes.

2. **Write `tasks/NN-<name>.md`** from `rage-feature-specs/templates/task.md`, and make sure
   the feature spec's Tasks list links it:

   - **Goal**, **Context** — short.
   - **Requirements** — the behavior it must deliver: interfaces, examples, data formats, and
     what happens when it fails — the part most often left too thin. Be specific about the
     failure, not the category: "the write is interrupted between the rename and the fsync,
     leaving a Deferred task in the log that already ran" is better than "handle I/O errors."
     Cover at least what happens if it runs twice, if it is interrupted halfway, and what the
     caller sees when it raises. End with what this task deliberately does not do, so review
     does not raise it as a gap.
   - **Design** — the technical shape: what gets added, what changes, where it lives, the
     interfaces involved, and the happy path step by step. Detailed enough that
     implementation only means writing it down, not inventing anything. Name every interface
     the tests will call, with its signature — `task:test-core` writes tests against them
     before they exist.
   - **Implementation constraints** — the compatibility requirements and invariants that the
     domain skills and the component document require, and rejected alternatives that must not
     quietly come back in.
   - **Acceptance criteria** — see below. This section is the contract.
   - **Verification** — the tests to add or update and the commands to run. If the change
     breaks behavior that existing examples check, name those examples.

3. **Write acceptance criteria as behaviors, not implementation.** `task:test-core` and
   `task:test-edge` write tests straight from them, so write each one as something that can be
   seen from outside.

   Not: "the `@__seen` hash is checked before write." A criterion that names a private
   variable locks the current implementation in place and produces a test that breaks on every
   refactor.

   Cover the failure behavior, not just the happy path. A criteria list that reads as a
   feature description has not done its job.

   **Tag each criterion** `core` or `edge`, as the conventions define them. Every interface a
   `core` criterion needs must be in the Design — `task:test-core` calls it before the code
   exists. A `core` criterion that can only be tested once the code exists (crash ordering,
   fiber interleaving) stays `core`; `task:test-core` leaves it for `task:test-edge`.

4. **Record design decisions** as the conventions describe, at the moment you make them. Most
   of a feature's real decisions happen in this phase.

5. **Gate.** Show a line-level diff of the task file and, separately, the acceptance criteria
   as a plain list grouped into `core` and `edge` — the criteria and that split are what the
   engineer is really approving. In a `multi` feature, name the feature-level criteria this
   task covers. If `task:test-core` already ran (a `bug` that moved up to `single`), name every
   core test this Design no longer matches. The next command is
   `/rage-agent-kit:task:test-core`. Then stop.

## Do not

- Do not write code, and do not change any file in the Rage checkout.
- Do not write tests. That is `/rage-agent-kit:task:test-core`, the next phase.
- Do not design around a constraint by quietly dropping it. If a constraint makes the task
  impossible with its current scope, say so at the gate and propose the change — that is a
  valid outcome of this phase.
