---
name: task:test-core
description: Phase 3 — write failing tests for a task's core acceptance criteria.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Write the core tests first

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, next command named, then stop. Never start the next phase yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

This phase writes tests for the task's `core` acceptance criteria **before the code exists**,
and shows that each one fails. If the list is long, you are writing the whole test pass too
early — the `edge` criteria and the other edge cases wait for
`/rage-agent-kit:task:test-edge`, after implementation.

## Before starting

Stop if the task's Design is empty on a `single` or `multi` tier — for a `bug` it is empty on
purpose. Stop too if any acceptance criterion has no `core` or `edge` tag, and name those
criteria: choosing the split is `task:design`'s decision (`feature:new`'s, for a `bug`), not
this one's.

## Read scope

From the task file: the **Acceptance criteria** tagged `core` (the `edge` ones only to know
which they are), the **Requirements**, the **Design** — only the interfaces the tests will
call — and **Verification**. Plus the existing tests around the code the task changes, and the
public signatures of the existing code those tests will call; for a `bug`, also the code path
the defect runs through. Not the feature spec, not the rest of the Design, and not private
internals.

Load the `specs` skill for how tests are written here, and the domain skills for the areas
under test (see the conventions).

## Steps

1. **List what already exists before proposing anything.** Find the tests that already test
   this code, and list the example names as the `specs` skill shows ("Finding what a file
   already covers"); read an example's body only when its name is close enough to a candidate
   that the assertion decides it. Never write an example that repeats an existing one in
   different words.

2. **Map the core criteria to tests.** For each `core` criterion, say which of these it is:

   - **already covered** by an existing example — name it;
   - **covered by an existing example that checks the old behavior**, which the task changes
     on purpose — propose changing that example to the new behavior; after the change it must
     fail like a new example (see the conventions);
   - **needs a new example**;
   - **cannot be tested before the code exists** — its failure depends on the implementation
     being there: crash ordering, fiber interleaving, timing between two processes. Name it
     and the reason, and leave it for `/rage-agent-kit:task:test-edge`. Do not fake it with a
     test that fails for some other reason;
   - **cannot be tested at this level** — a finding for the gate. Do not write something
     close to it instead.

   For a `bug`, the first new or changed example **reproduces the defect** as the task's
   Context describes it: the same input, and the same wrong result or error the bug shows
   today.

3. **Propose before writing.** Present the candidate examples grouped by file, one line each,
   with the criterion each one proves:

   ```
   spec/rage/deferred/queue_spec.rb
   - stores one record for two enqueues with the same key            (core 1)
   - change "waits when the backlog is full" → raises instead         (core 3)
   left for task:test-edge: core 2 — needs a crash between write and rename
   ```

   **Wait for explicit confirmation before writing anything.** These tests are the contract
   the implementation will be held to. If the engineer wants changes to the list, update it
   and confirm again.

4. **Write against the Design's interfaces, not an implementation.** A test calls only the
   interfaces the Design names, and the existing public ones they build on. Never call
   `__`-prefixed internals, read private state, or stub a method the Design does not name —
   there is no implementation yet, and a test that guesses its insides locks in a shape
   nobody approved. A test that needs an interface the Design does not name is a finding;
   do not invent the interface.

   Do not loosen, widen, or restub an existing helper to make a new test fit without saying so
   and getting confirmation.

5. **Show that each test fails for the right reason.** Running tests is allowed in this phase:
   run **only the test files you wrote or changed** — not the full suite, not linters. Every
   new or changed example must fail, and the failure must be the behavior it checks:

   - **Right reason:** an assertion failure — expected one thing, got another. For an
     interface the Design adds and that does not exist yet, a `NameError` or `NoMethodError`
     that names exactly that interface, raised inside the example, also counts; list those
     separately — `task:implement` checks each of them against empty interfaces before it
     writes the code.
   - **Wrong reason:** a `LoadError`, a file that fails to load, a `NameError` for anything
     else (a typo, a missing `require`, a helper), a timeout, a skipped or pending example, or
     an example the default run does not include. Fix the test and run it again.
   - **Passes already:** either the behavior already exists — say so, since the criterion may
     not describe a change — or the test does not check what it claims. Either way it is a
     finding.

   A test can look red or green without having run. Before trusting a run, read "What actually
   runs" and "Fiber and scheduler specs" in the `specs` skill.

   A core test that cannot be made to run red here — it only skips, or it needs services
   this session does not have — is a finding for the gate. Do not weaken it until it runs,
   and do not drop it without saying so. Record it as not run, with the reason (see Evidence
   for a criterion in the conventions).

6. **Record the core map.** Write the core-test record into the task's Verification section,
   as the conventions describe (Records in Verification) — also when no core test could be
   written first. Do not touch the rest of Verification, except to make its planned tests match
   what you wrote.

7. **Gate.** Show the criteria-to-test map, a line-level diff of the tests and of the
   Verification change, and the red-run report: the command, and for each example its failure
   line and whether that is an assertion failure or a missing interface. Name what did not run
   and what was left for `task:test-edge`. The next command is
   `/rage-agent-kit:task:implement`. Then stop.

## Do not

- **Do not write implementation code** — not even an empty class or method to make a test
  load. Making the tests pass is `/rage-agent-kit:task:implement`.
- Do not write tests for `edge` criteria or other edge cases. That is
  `/rage-agent-kit:task:test-edge`, after implementation.
- Do not change an existing example except to the new behavior a `core` criterion states, as
  proposed and confirmed in step 3.
- Do not edit the task's Acceptance criteria or their tags. A criterion that looks wrongly
  tagged or cannot be tested is a finding for the gate.
