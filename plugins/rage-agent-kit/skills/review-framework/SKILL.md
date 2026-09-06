---
name: review-framework
description: Review local Rage framework changes as framework code rather than application code — for rage-rb/rage core work only, not Rage apps. Use when the user asks to review their changes, look for bugs or edge cases, before opening a PR, or after finishing work in lib/.
---

# Framework code review

Rage runs on every request of every app built on it. Review for runtime cost and blast
radius, not for tidiness.

Two reviewers split the axes — runtime correctness, and contract, cost and surface — hunting
edge cases and failure modes rather than checking the happy path. A triage pass over the diff
decides which of them run and at what model tier; when both run they run in parallel, and
their findings are merged into one report.

Review adversarially. Assume the change is wrong and look for the input or the interleaving
that proves it — the author already walked the happy path. Reviewer A hunts the ways the
runtime breaks the code; Reviewer B hunts the ways a user breaks it.

Scope edge cases to the boundary: user-supplied values, classes, methods, and blocks; config;
wire formats; anything crossing a fiber or a process. Skip them on `__`-prefixed internals,
where the framework is the only caller and the contract is already fixed. Demanding a nil
check on an internal method is noise.

## Do not report these as defects on their own

Duplication, long methods, string `class_eval`, missing abstraction, and untestable private
methods are deliberate trade-offs in this repo — read CONTRIBUTING.md's Design Principles
in the Rage repository the user has open. Raise one only with a concrete runtime or
maintenance cost attached. A style objection without a cost is noise, and noise buries the
findings that matter.

Boot-time work and boot speed pull against each other. Name the trade-off; do not cite
whichever side happens to support the objection.

## Steps

1. Collect the diff. Default to **uncommitted work**: `git diff`, `git diff --staged`, and
   `git ls-files --others --exclude-standard`. Use `git diff main...HEAD` only when the user
   asks for branch or PR review. If the diff is empty, stop and say so.
2. Write that diff to a single file once and pass its path to both reviewers, rather than
   having each reviewer regenerate it. Use the session scratchpad directory, or `mktemp` —
   not a fixed path in shared `/tmp`. The capture must match the default target from step 1,
   which is the working tree *and* the index:

   ```bash
   patch="$(mktemp -t review.XXXXXX)"
   { git diff; git diff --staged; } > "$patch"
   git ls-files --others --exclude-standard   # untracked files, listed separately: no diff to capture
   ```

   `git diff --staged` alone reviews a strict subset, and reports nothing at all on the
   common case of an unstaged working tree.

   For each touched file, tell reviewers to read the diff hunks with context first, and only read the *entire* file when the surrounding logic isn't visible in
   the hunk context — large pre-existing files (storage backends, the fiber scheduler) should
   be read in full only when the change touches state or control flow that spans beyond what
   the hunk shows. When the change references a design doc under docs/, point reviewers at the
   specific sections relevant to the diff (e.g. "read §4 and §7, not the whole file") rather
   than instructing a full-file read by default. Duplicated full-file reads across the two
   reviewers, not model tier, are the actual driver of review cost.
3. Triage the diff before launching anything. Read the captured patch once and name what the
   change actually touches — reactor or fiber state, durability and crash recovery, locking,
   extension points that take user code, `class_eval` codegen, config and wire formats, public
   surface, per-request work. Write that assessment down rather than carrying it in your head:
   it drives the model tier, the reviewer selection, and what each reviewer is told to focus
   on.

   Route from it:

   - **Reviewer A** runs on `opus` whenever the diff touches durability, locking,
     crash-recovery, the reactor or fiber scheduler, or re-entrant state, and on `sonnet`
     otherwise.
   - **Reviewer B** runs by default, on `sonnet`. Skip it only when the diff reaches none of
     its bullets — no user-reachable input, no codegen, no config or wire format, no public
     surface, no per-request work. "It looks like internals" is not that reason: a private
     method reachable from an extension point is still user-facing. When B does run, tell it
     which of its bullets are live for this diff.

   Skipping is a deliberate call with a stated reason, and the report says which reviewer was
   skipped and why. The costs are not symmetric — a skipped reviewer that was needed ships a
   defect to every app running Rage, while an unnecessary one costs a single sonnet subagent
   on a diff already captured to a file.
4. Before launching reviewers, determine whether the surface the diff changes has ever been
   published. Do not use `CHANGELOG.md` for this — entries can be stale, missing, or
   mis-filed under `[Unreleased]`. Check the published gem instead:

   ```bash
   gem fetch rage-rb --version <latest published>
   gem unpack rage-rb-<version>.gem
   ls rage-rb-<version>/lib/rage/<area touched by the diff>/
   ```

   If the changed file, class, or method is absent from the published source, no user can
   depend on it yet. State that as a fact in every reviewer prompt — e.g. "`Rage::Deferred::DeadTasks`
   has never been published; changes to it are design decisions, not compatibility breaks."
   This check runs once, in the orchestrating session, and its result is passed down to the
   reviewers; they must never re-derive it themselves — duplicating a network fetch and gem
   inspection across parallel subagents costs real tokens for an identical answer.
5. Launch the reviewers step 3 selected, with `subagent_type: "general-purpose"`, at the model
   tiers step 3 set, in the background — only the merge in step 6 needs their results, and
   backgrounding leaves the user able to interject. When both run, launch them **in parallel,
   in a single message** — that is what buys the parallelism. Give each the diff path from
   step 2, the paths it touches, the released-surface fact from step 4, the risk areas the
   triage named, and both the adversarial framing and the "do not report" section above — the
   scoping rule is what keeps edge-case hunting from turning into noise. Run whichever
   reviewers were selected regardless of diff size — a one-line change that removes a timeout
   or moves a yield point is the highest-risk kind, not the lowest.
6. Merge into one report. Drop duplicates, order by severity, and mark anything both
   reviewers raised independently.

## Reviewer A — runtime correctness

Run this reviewer on opus when the triage in step 3 puts it there: it hunts the subtlest class of bug — crash ordering, fsync timing, lock
re-entry, blocking I/O on the reactor, fiber leaks and re-entrancy — and opus has caught real
high-severity issues here before. "Re-entrant state" means anything a request can leave
half-finished for the next one to see.

- Blocking I/O anywhere on the reactor. The canonical list is in `CLAUDE.md`; paste it into
  the reviewer's prompt along with the rest of the shared framing, since a subagent should
  not have to go looking for it: native extensions, `Thread.new`, `system`, backticks,
  `Process.spawn`, `IO.popen`, blocking `flock`, `fsync`, large file I/O, long CPU loops,
  clients with their own thread pool or `IO.select`.
- Unbounded waits. Every park needs a timeout or an explicit reason it cannot hang.
- Stale wake-ups: does the resume check a generation counter before resuming the fiber?
- Fiber leaks, and fibers that never resume while holding an Active Record connection.
- `Fiber.await` over more children than a fiber-keyed resource can supply.
- Durability: atomic rename, `flock` inode semantics, crash recovery, partial writes.
- Cleanup: tmp files, lock files, subscriptions, and any hash keyed by fiber, connection, or
  `object_id` that nothing ever deletes from.
- Failure paths: if this raises halfway, what is left behind — a half-written file, a
  checked-out connection, a live subscription, a fiber that never resumes, or `@__` state the
  next request on that object will see?
- Re-entrancy and ordering: what happens if this runs twice for the same request, fiber, or
  connection, or if the two halves interleave with another fiber between them?

Use this plugin's `deadlocks` skill before reviewing any wait.

## Reviewer B — contract, cost, and surface

Everything here is user-facing, so ask what a user can feed it that the author did not
picture. Framework extension points take arbitrary user code, and users are not adversarial
on purpose — they are just unaware of the contract.

- User-supplied input at extension points: a method with an unexpected signature or arity, a
  block that raises or returns early, a class that does not respond to what the code assumes,
  `nil` or an empty collection where one object was expected, a duplicate registration.
  `Rage::Internal.build_arguments` exists because user method signatures vary.
- Codegen interpolation: anything interpolated into a `class_eval` heredoc becomes source.
  What does a name containing a quote, a newline, or a non-identifier character generate?
- Config and wire formats: values unset, of the wrong type, out of range, or mutated after
  boot. What happens on the second call, or on a value that changes between workers?
- Allocations on the happy path; per-request work that could happen at boot.
- Does the feature cost anything to users who do not enable it? Prefer generating a method
  with or without the feature over a runtime branch.
- Boot time: a new `require` in `lib/rage/all.rb` versus `autoload` in `lib/rage-rb.rb`.
- Extensibility: can users hook into this without monkeypatching?
- Public API: additive unless the break is proposed explicitly — but only for surfaces that
  exist in the published gem, per the released-surface fact handed down in the prompt. If the
  surface has never shipped, there is nothing to break: frame the finding as a design decision
  still in flight — a suboptimal API worth changing now, while changing it is free — not as a
  compatibility break. New telemetry spans are quasi-breaking — user wildcard handlers like
  `handle "cable.*"` start matching them.
- New gems, or features that need an external service to work by default. Rage's promise is
  one process with no Redis and no separate workers.
- YARD `@param`/`@return`/`@example` on user-facing methods — the tags are required; whether
  `yardoc` may be run to check them is `CLAUDE.md`'s call, not this review's. `# @private`
  and `__` prefixes on internals, `# frozen_string_literal: true` on new files, and a
  `CHANGELOG.md` entry for user-visible behavior — but do not raise a missing entry for a
  surface that has never been published.

## Report

Per finding: severity, file and line, what breaks and under what load, and a suggested fix.
Open by naming which reviewers ran and, if one was skipped, the triage reason for skipping it
— the reader needs to know which axis went unexamined.

This review is where public-API compatibility gets stated, since `CLAUDE.md` no longer asks
for it on every change: say whether the diff is additive, and for surfaces the step-4 check
found in the published gem, what breaks and who is affected. For surfaces that have never
shipped, say so plainly instead — there is nothing to be compatible with yet.

Close with which specs would actually exercise the change, noting that the default run
excludes `spec/ext/**` and that integration and Fiber specs skip without
`ENABLE_EXTERNAL_TESTS=true`. Addressing a "Spec coverage" finding is a separate step: this
plugin's `write-specs` skill, invoked deliberately by the user, not this review.
