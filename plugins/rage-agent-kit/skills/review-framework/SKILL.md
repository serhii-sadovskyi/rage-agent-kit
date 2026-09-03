---
name: review-framework
description: Review local Rage framework changes as framework code rather than application code — for rage-rb/rage core work only, not Rage apps. Use when the user asks to review their changes, look for bugs or edge cases, before opening a PR, or after finishing work in lib/. Runs two reviewers in parallel on split axes — runtime correctness and contract/cost/surface — hunting edge cases and failure modes rather than checking the happy path, then merges the findings.
---

# Framework code review

Rage runs on every request of every app built on it. Review for runtime cost and blast
radius, not for tidiness.

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
2. Launch both reviewers below **in parallel, in a single message**, with
   `subagent_type: "general-purpose"` and `run_in_background: false`. Give each the full diff,
   the paths it touches, and both the adversarial framing and the "do not report" section
   above — the scoping rule is what keeps edge-case hunting from turning into noise. Run both
   regardless of diff size — a one-line change that removes a timeout or moves a yield point
   is the highest-risk kind, not the lowest.
3. Merge into one report. Drop duplicates, order by severity, and mark anything both
   reviewers raised independently.

## Reviewer A — runtime correctness

`model: opus`

- Blocking I/O anywhere on the reactor: native extensions, `Thread.new`, `system`, backticks,
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

`model: sonnet`

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
- Public API: additive unless the break is proposed explicitly. New telemetry spans are
  quasi-breaking — user wildcard handlers like `handle "cable.*"` start matching them.
- New gems, or features that need an external service to work by default. Rage's promise is
  one process with no Redis and no separate workers.
- YARD `@param`/`@return`/`@example` on user-facing methods (these tags are required;
  running `yardoc --fail-on-warning` is a final stage, explicit request only), `# @private`
  and `__` prefixes on internals, `# frozen_string_literal: true` on new files, and a
  `CHANGELOG.md` entry for user-visible behavior.

## Report

Per finding: severity, file and line, what breaks and under what load, and a suggested fix.

Close with which specs would actually exercise the change, noting that the default run
excludes `spec/ext/**` and that integration and Fiber specs skip without
`ENABLE_EXTERNAL_TESTS=true`.
