---
name: task:test-edge
description: Phase 5 — cover an implemented task's edge cases and remaining acceptance criteria.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Cover the edge cases

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, next command named, then stop. Never start the next phase yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

## Before starting

Stop if the Verification section has no core-test record — name
`/rage-agent-kit:task:test-core` — or if nothing outside the tests changed since the merge base
(see The Rage checkout in the conventions) — name `/rage-agent-kit:task:implement`.

For a `bug`, this phase is optional (see Tiers in the conventions). If it runs anyway, look
only for edge cases worth a test, and record `none` if there are none.

## Read scope

The task's **Acceptance criteria** — the contract this phase exists to prove — and its
**Verification** section, including the core-test record from `/rage-agent-kit:task:test-core`,
plus the implemented code, the existing tests around it, and the existing examples
`task:implement` named as changed on purpose. Not the feature spec, not the task's Design
beyond what the criteria need.

This phase covers the `edge` criteria, the `core` criteria that `task:test-core` left for after
the code, and the edge cases around them. The core tests already exist: list them by name, do
not rewrite them, and do not write a second example for what they already prove.

Load the `specs` skill for how tests are written here, and the domain skills for the areas
under test (see the conventions).

## Steps

1. **List what already exists before proposing anything.** Find the tests that already test
   this code, and list the example names as the `specs` skill shows ("Finding what a file
   already covers"); read an example's body only when its name is close enough to a candidate
   that the assertion decides it. Never write an example that repeats an existing one in
   different words.

2. **Map criteria to coverage.** For each `edge` criterion, and each `core` criterion the
   core-test record left for this phase, say whether it is already covered, needs a new
   example, or cannot be tested at this level. List the `core` criteria the record already
   covers as covered, with their example. A criterion that cannot be proven is a finding —
   say so instead of writing something close to it that passes, and record why no test can
   prove it: `task:close` then asks the engineer how they checked it.

   Add each existing example that checks behavior the task changed on purpose — the ones
   `task:implement` named, and any you find — as a change to the new behavior. Only the
   behavior a criterion or the Design states counts; an example that fails for any other
   reason is a finding.

3. **Propose before writing.** Present the candidate examples grouped by file, one line each,
   stating the behavior each one checks:

   ```
   spec/rage/deferred/backends/disk_spec.rb
   - restores a Deferred task written by a pre-migration schema version
   - skips and logs a Deferred task whose class no longer exists
   - change "retries forever" → gives up after the retry limit
   ```

   **Wait for explicit confirmation before writing anything.** Tests are a contract the
   engineer approves. If they want changes to the list, update it and confirm again, instead of
   writing more examples than they asked for just to be safe.

4. **Write against the contract, not the implementation.** Assert documented behavior that can
   be seen from outside — signatures, config semantics, the acceptance criteria — not details
   of how the code happens to work today. Prefer the cases an implementation is likely to get
   wrong:

   - legacy or pre-migration stored records, and schema drift
   - shutdown and teardown paths
   - concurrent or re-entrant access — two fibers, two processes, a resumed fiber racing a
     new request

5. **Never change the implementation to make a test pass.** A failing new test is a finding,
   not a bug in the test by default. Stop, show the failure output, and ask whether the
   expectation or the implementation is wrong. In the same way, never loosen, widen, or restub
   an existing helper to make new coverage fit without saying so and getting confirmation, and
   never edit a core test — one that looks wrong now is a finding for the gate. The one
   exception: a core test written before its class existed names the class as a string; now
   that the class exists, replace the string with the class, as the `specs` skill describes,
   and name the change at the gate.

6. **Report what did not actually run.** Running tests is allowed in this phase. Run only the
   test files you wrote or changed — not the full suite, not linters, and not the core tests
   again: the final run in `/rage-agent-kit:task:apply-findings` runs all of the task's tests
   together. Then state clearly which examples executed and which were skipped, instead of
   reporting green as if it were full coverage. Before trusting a run, read "What actually
   runs" in the `specs` skill.

   A test that only ran in skipped or stubbed form has not proven what it claims. Record every
   example of this phase that was skipped or excluded as not run — its evidence can only be a
   CI run, which `task:close` asks the engineer for.

7. **Flag what the test setup cannot prove.** Where the test doubles stub out the exact thing
   under test — reactor timing, cross-process interleaving — say what the test can and cannot
   show, instead of writing one that only tests the stub.

8. **Gate.** Add the edge-test record to the task's Verification section, as the conventions
   describe (Records in Verification). `task:close` reads it in a later session, so it has to
   stand on its own. If the tests you wrote differ from the tests Verification planned, patch
   the plan to match. Show the full map (core and
   edge), a line-level diff of the tests and of the Verification change, and the run report
   including what was skipped. The next command is `/rage-agent-kit:task:review`. Then stop.
