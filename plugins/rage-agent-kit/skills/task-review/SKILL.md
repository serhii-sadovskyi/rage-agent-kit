---
name: task:review
description: Phase 6 — adversarial review of an implemented, tested task.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Review a task

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
report, then stop. Never start applying findings yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

Review adversarially. Assume the change is wrong and look for the input or the interleaving
that proves it — the author already went through the happy path, so going through it again
finds nothing.

## Read scope

The task's diff, the task's **Acceptance criteria** (a criterion the code does not actually
meet is a finding), **Implementation constraints** (a constraint the code breaks is a finding
too), and **Verification** records, the feature's ADRs — only to see which breaks were
agreed — the **Invariants** section of the feature's component document (an invariant the code
breaks is a finding, unless an ADR of this feature changes it), and the files the diff touches.
Not the feature spec.

## Do not report these as defects on their own

Duplication, long methods, string `class_eval`, missing abstraction, and untestable private
methods are deliberate trade-offs in this project — see its `CONTRIBUTING.md` design
principles. Raise one only with a concrete runtime or maintenance cost attached. A style
objection with no cost attached is noise. Noise hides the findings that matter.

Boot-time work and boot speed work against each other. Name the trade-off; do not mention
only the side that happens to support the objection.

Limit edge cases to the boundary: user-supplied values, classes, methods, and blocks; config;
wire formats; anything crossing a fiber or a process. Skip them on `__`-prefixed internals
where the framework is the only caller. Asking for a nil check on an internal method is noise.

## Steps

1. **Collect the diff for this task** in the Rage checkout — edits under
   `rage-feature-specs` are not under review. Empty diff — stop and say so.

2. **Save it to one file and share it.** Write it once and pass the path to both
   reviewers, instead of having each one generate it again. Use the session scratchpad or
   `mktemp`, never a fixed path in shared `/tmp`. The range and `<default branch>` are as the
   conventions define them (see The Rage checkout). Run this from the root of the Rage
   checkout, which may be a subdirectory of the working directory:

   ```bash
   base="$(git merge-base HEAD <default branch>)"
   patch="$(mktemp -t review.XXXXXX)"
   git diff "$base" > "$patch"
   git ls-files --others --exclude-standard | while IFS= read -r f; do
     git diff --no-index -- /dev/null "$f" >> "$patch" || true
   done
   ```

   New files have no diff, so the loop adds each one as a whole-file patch — they are often
   the core of the change and must not reach reviewers as bare paths. `git diff --no-index`
   exits with 1 when it finds a difference, which is why the loop ends in `|| true`.

   Tell reviewers to read the diff hunks with context first, and to read a whole file only
   when the surrounding logic is not visible in the hunk.

3. **Assess the diff before launching anything.** Read the patch once and write down what the
   change actually touches — reactor or fiber state, durability and crash recovery, locking,
   extension points taking user code, codegen, config and wire formats, public surface,
   per-request work. That assessment decides the tier, which reviewers run, what they focus
   on, and which knowledge skills each one loads — the ones whose descriptions match the paths
   in its part of the diff.

   - **Reviewer A** always runs: on `opus` when the diff touches durability, locking, crash
     recovery, the reactor or fiber scheduler, or re-entrant state; `sonnet` otherwise.
   - **Reviewer B** runs by default on `sonnet`. Skip it only when the diff touches none of
     the items in its list. "It looks like internals" is not that reason — a private method
     reachable from an extension point is still user-facing.

   Skipping is a deliberate decision with a stated reason. The costs are not equal: a skipped reviewer that was needed ships a defect to every user, while an
   unnecessary one costs one small subagent on a diff already saved to a file.

4. **Find out what has actually been released.** Do not use `CHANGELOG.md` — entries get out
   of date, go missing, or are put in the wrong place. Check the latest release, once, for
   each class or method the diff changes. Ask rubygems for its version, then search the
   matching tag in the checkout:

   ```bash
   gem search --remote --exact rage-rb                # latest release, e.g. "rage-rb (1.28.0)"
   git rev-parse -q --verify "refs/tags/v<version>"   # is that release tagged in this checkout?
   git grep -n '<class or method>' "v<version>" -- lib/
   ```

   If the checkout has no tag for that version — an old copy or a fork often does not — check
   the published gem instead, in a temporary directory, because `gem fetch` and `gem unpack`
   write into the current one:

   ```bash
   dir="$(mktemp -d -t rage-release.XXXXXX)"
   (cd "$dir" && gem fetch rage-rb --version <version> && gem unpack rage-rb-<version>.gem)
   grep -rn '<class or method>' "$dir"/rage-rb-<version>/lib/
   ```

   Search for the class or method, not only its folder: a folder that exists says nothing
   about a method added since. If the changed class or method is not in the released source,
   no user can depend on it yet. Name the version you checked, and state the result as a fact
   in every reviewer prompt. This check runs **once**, here, and is passed down — reviewers
   must never work it out again.

5. **Launch the selected reviewers** with `subagent_type: "general-purpose"`, at the tiers
   the assessment set, in the background. When both run, launch them **in parallel in a single
   message** — that is what makes them actually run in parallel. Give each: the diff path, the
   paths touched, the acceptance criteria, implementation constraints, Verification records,
   and component invariants, the agreed breaks from the ADRs, the fact about what has been
   released, the risk areas and knowledge skills the assessment named, the "Both reviewers"
   section below, and both the adversarial framing and the "do not report" section above. Run
   the selected reviewers whatever the diff size — a one-line change that removes a timeout or
   moves a yield point is the highest-risk kind, not the lowest.

6. **Merge into one report and save it.** Remove duplicates, order by severity, mark anything
   both reviewers raised independently. Save it where the conventions say (Review reports). If
   `.rage-agent-kit/.gitignore` does not exist, create it with the single line `*`, so the
   reports never show up in git.

## Both reviewers — do the tests prove the criteria?

The task's Verification records map each acceptance criterion to the example that proves it.
For each criterion in the reviewer's area, check that the example really proves it. Look for
an example that checks only a stub, one whose only recorded failure was a missing class or
method, one that did not run, and one that tests something close to the criterion but not the
criterion itself. A criterion the code meets but no example proves is a finding too.

## Reviewer A — runtime correctness

The kind of bug that is hardest to see: crash ordering, fsync timing, lock re-entry, blocking
I/O on the reactor, fiber leaks and re-entrancy.

- Blocking I/O anywhere on the reactor. Copy the canonical list from the project's `CLAUDE.md`
  into the reviewer's prompt word for word, instead of making a subagent search for it. Only if
  `CLAUDE.md` is not in context, use this copy, which CI keeps equal to the canonical one:
  native extension calls (DB drivers, crypto, compression, FFI); `Thread.new`; `system`,
  backticks, `Process.spawn`/`wait`, `IO.popen`; blocking `flock` (without `LOCK_NB`),
  `fsync`, large file reads and writes; long CPU-bound loops; client libraries with their own
  thread pool or `IO.select`.
- Waits with no limit. Every park needs a timeout or an explicit reason it cannot hang.
- Outdated wake-ups: does the resume check a generation counter first?
- Fiber leaks, and fibers that never resume while holding a connection.
- `Fiber.await` over more children than a fiber-keyed resource can provide.
- Durability: atomic rename, `flock` inode semantics, crash recovery, partial writes.
- Cleanup: tmp files, lock files, subscriptions, and any hash keyed by fiber, connection, or
  `object_id` that nothing deletes from.
- Failure paths: if this raises halfway, what is left behind?
- Re-entrancy and ordering: what if it runs twice for the same request, fiber, or connection,
  or the two halves interleave with another fiber between them?

Tell this reviewer to use the `deadlocks` skill before reviewing any wait.

## Reviewer B — contract, cost, and surface

Everything here is user-facing: ask what a user can pass in that the author did not imagine.
Users do not attack the code on purpose — they just do not know the contract.

- User-supplied input at extension points: unexpected signature or arity, a block that raises
  or returns early, a class that does not respond to what the code assumes, `nil` or an empty
  collection, a duplicate registration.
- Codegen interpolation: anything interpolated into a `class_eval` heredoc becomes source.
  What does a name containing a quote, a newline, or a non-identifier character generate?
- Config and wire formats: unset, wrong type, out of range, mutated after boot. What happens
  on the second call, or on a value that differs between workers?
- Allocations on the happy path; per-request work that could happen at boot.
- Does the feature cost anything to users who do not enable it?
- Boot time: a new `require` versus `autoload`.
- Extensibility: can users hook in without monkeypatching?
- Scope: code the task does not need. A parameter nothing passes, a branch no criterion
  requires, an abstraction, adapter, registry, or config knob added for a caller that does not
  exist yet. The project's `CLAUDE.md` makes this a stop-and-ask at design time; at review time
  it is a finding. Name the acceptance criterion that does not ask for it. This is scope, not
  style — the objections ruled out above stay out.
- Public API: additive unless a break was agreed in an ADR — but only for surfaces that
  exist in the latest release, according to the fact passed down in step 4. If the surface
  never shipped, present it as a design decision still in progress, worth changing now while
  changing it costs nothing, not as a compatibility break.
- Doc tags, internal naming, `# frozen_string_literal: true` on new files, and the changelog
  entry — check each against the `public-api` skill, which this reviewer loads.

## Report and gate

Per finding: severity, file and line, what breaks and under what load, and a suggested fix.
Start by naming which reviewers ran and, if one was skipped, the reason from the assessment —
the reader needs to know which area was not reviewed.

State whether the diff is additive, and for surfaces the step-4 check found released, what
breaks and who is affected.

Say which acceptance criteria the code does not actually meet, and which criteria the
Verification records map to an example that does not prove them, noting what does not run by
default.

Show the report and give its path — it is a new file, so it is shown, not diffed (see the gate
in the conventions). Then stop. Applying findings is `/rage-agent-kit:task:apply-findings` —
also when the report has no findings.
