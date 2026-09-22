---
name: task:apply-findings
description: Phase 7 — apply the findings from a task review.
argument-hint: <feature-name> [task]
disable-model-invocation: true
---

# Apply review findings

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, next command named, then stop. Never start the next phase yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

Takes the report `/rage-agent-kit:task:review` saved (see Review reports in the conventions)
and applies it. If there is no report file, stop and say so; do not work from a summary or
from memory. If the engineer gives you a review report in the conversation instead, save it to
that path first. If handed something that is not a review report, ask for one instead of
guessing its structure.

A report with no findings still comes through this phase: the lint and doc checks, the final
run, and the records below happen here.

**Apply the findings yourself. Do not delegate them to agents.**

## Read scope

The review report, the task's Design, Implementation constraints, Acceptance criteria, and
Verification records, the ADRs the task links, and the files the findings name.

## Order of work

Start with findings that touch a public contract, a wait/wake or pooling protocol, or more
than one file. Decide the shape of those first, so smaller edits are made on top of the final
structure instead of being done again.

## Do not write tests

Applying findings is implementation. Coverage is `/rage-agent-kit:task:test-edge`. Do not add
an example to prove a fix works, and do not adjust an existing stub or one of the task's tests
so new code passes. While you work, running the tests that cover the files you touched is
allowed, and encouraged.

## Disagreeing with a finding is allowed

A finding you believe is wrong is not applied silently and not ignored silently. Say which
one, why you think it is not correct, and leave it for the engineer at the gate. Reviewers
work from a diff and can miss context that makes a finding no longer relevant.

## Lint and doc checks

Once every finding is handled, run the project's linter and doc validation once
(`bundle exec rubocop` and `bundle exec yardoc --fail-on-warning` here). Show the output and
**ask** whether to fix what they report — do not start fixing, not even offenses that are easy
to auto-correct. An offense may have existed before this change, or be out of scope for this
review.

## Final run

Run this last — after the lint and doc checks, and after any fixes the engineer asked for
there. Run the task's tests once: the test files the core-test and edge-test records name, and
the tests covering the files this phase touched. Not the full suite. Before trusting the
result, read "What actually runs" in the `specs` skill; then state which of the task's examples
ran and which did not. A task test that fails is a finding for the gate; do not change it.

This run is the evidence `task:close` ticks criteria from (see Evidence for a criterion in the
conventions).

## Gate

Report which findings were applied and which were deliberately skipped, with a reason for
each, plus the blocking-I/O audit the project's `CLAUDE.md` requires — "none" is a valid
result, silence is not. State the compatibility effect of what you applied.

Name any "coverage" items from the review as skipped instead of silently leaving them out, and
point to `/rage-agent-kit:task:test-edge` as where they get handled.

If a finding changed the design, patch the task's Design to match and record a significant
change as a `proposed` ADR, as the conventions describe.

Write two records:

- An `## Outcome` section at the end of the review report: for each finding, applied, skipped
  with the reason, or left for the engineer.
- The `**Review outcome**` record in the task's Verification section, with the final run, as
  the conventions describe (Records in Verification).

Then stop. The task closes with `/rage-agent-kit:task:close`.
