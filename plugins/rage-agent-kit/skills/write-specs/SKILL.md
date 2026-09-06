---
name: write-specs
description: Decide what spec coverage a Rage framework change needs and write it — for rage-rb/rage core work only, not Rage apps. Invoke deliberately as its own step (the user asks to write specs, add coverage, or address a review's "Spec coverage" section) — never as a side effect of an implementation or review task. Complements the passive `specs` conventions skill.
---

# Writing specs

This skill is the active counterpart to this plugin's `specs` skill. `specs` documents *how*
this repo writes RSpec; this skill decides *what* is uncovered and writes it. It runs as its
own deliberate step, the same way `review-framework` does — not folded into an implementation
task or triggered automatically by editing `lib/`.

Load this plugin's `specs` skill now for style conventions. Load the file-specific kit skills
(`deadlocks`, `public-api`, `request-path`, `codegen`) that match the areas
the target touches — they name the edge cases each area gets wrong.

## Target

Resolve what to cover from the user's request, defaulting to the uncommitted diff:

- **Uncommitted diff (default)**: `git diff`, `git diff --staged`, and
  `git ls-files --others --exclude-standard`.
- **A named file or directory**: the code at that path, not just its recent diff.
- **A feature**: the files implementing it, found by reading the code, not by guessing paths.
- **A `review-framework` review's "Spec coverage" section**: read the findings there as the
  list of gaps to close, not as a starting point to re-derive from scratch.

If the resolved target has no code (empty diff, path doesn't exist), stop and say so.

## Steps

1. **Find what's actually uncovered.** Read the target's changed or relevant code, then take
   inventory of the RSpec files that already exercise it — files under `spec/`, mirroring
   `lib/` → `spec/` paths (`lib/rage/deferred/queue.rb` → `spec/rage/deferred/queue_spec.rb`).
   Design docs under `docs/` are not specs in this sense; they are the `docs` skill's
   territory, and they describe intent rather than coverage.

   Do not read those files end to end. A framework spec file runs to hundreds of lines, and
   all this step needs is the list of behaviors already pinned down. Pull the example names
   first:

   ```bash
   rg -n '^\s*(describe|context|it|specify)\b' spec/rage/deferred/queue_spec.rb
   ```

   Read an example's body only when its name is close enough to a candidate that you need the
   assertion to tell whether it is a duplicate. Build the list from those names before
   proposing anything new — do not write an example that duplicates an existing one, even in
   different words.

2. **Propose before writing.** Present the candidate examples to the user grouped by spec
   file, one line each, stating the behavior each pins down — not the implementation detail
   it happens to touch. For example:

   ```
   spec/rage/deferred/backends/disk_spec.rb
   - restores a task written by a pre-migration schema version
   - two `defer` calls with the same idempotency key produce one on-disk record

   spec/rage/fiber_scheduler_spec.rb
   - a wait past its timeout raises instead of parking forever
   ```

   Wait for explicit confirmation before writing anything. Specs are a contract the user is
   signing off on, not an artifact to hand over as a fait accompli. If the user wants changes
   to the list, revise and re-confirm rather than writing a superset "to be safe."

3. **Write against the contract, not the implementation.** Specs assert documented and public
   behavior — method signatures, YARD docs, config semantics, CHANGELOG entries — not
   incidental details of how the current code happens to work. Favor the cases an
   implementation plausibly gets wrong over the ones it obviously gets right:
   - legacy or pre-migration on-disk records, and schema/version drift
   - duplicate, empty, `nil`, or malformed inputs
   - error and exception paths, not just the success path
   - shutdown and reactor-callback paths (`Iodine.on_state`, `at_exit`, signal handlers)
   - concurrent or re-entrant access — two fibers, two processes, or a resumed fiber racing a
     new request

4. **Never make implementation changes to pass a new spec.** If a spec you just wrote fails,
   that is a finding, not a bug in the spec by default — stop, show the failure output, and
   ask the user whether the spec's expectation or the implementation is wrong. Do not silently
   adjust either one. Likewise, never loosen, widen, or restub an existing test helper or stub
   to make new coverage fit without calling it out explicitly and getting confirmation first.

5. **Report what did not actually run.** After running the specs you wrote (see Steps below),
   state plainly which ones executed and which were skipped, rather than reporting a green run
   as if it means full coverage:
   - `.rspec` excludes `spec/ext/**` from the default run.
   - Integration, Fiber, and adapter specs skip unless `ENABLE_EXTERNAL_TESTS=true` is set with
     `TEST_HTTP_URL`, `TEST_PG_URL`, `TEST_MYSQL_URL`, and `TEST_REDIS_URL`.
   - Active Record coverage (`spec/ext/**`) needs `bundle exec rake appraise`.
   A spec that only ran in skipped/stub form has not demonstrated the behavior it claims to.

6. **Flag what can't be specced at the requested level.** Some behavior is invisible to this
   repo's test doubles — e.g. the dead-tasks suite stubs `Iodine.on_state`/`run_after` and
   `Fiber.pause`, so reactor-timing and cross-process interleaving never actually execute
   there. When the requested coverage falls in a stubbed-out area, say so and describe what the
   spec can and can't prove, instead of writing a spec that exercises the stub rather than the
   real path.

7. **Run only the files you touched.** Do not run rubocop or `yardoc`; those are separate,
   explicit-request-only end-of-session checks (see the `public-api` skill).
