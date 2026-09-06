---
name: apply-review
description: Apply the findings from a review-framework report to the Rage framework checkout — for rage-rb/rage core work only, not Rage apps. Use when the user asks to apply, fix, or address a review's findings, or hands back the merged report review-framework produced.
---

# Applying a framework review

Takes the merged report `review-framework` produces — per-finding severity, file and line,
what breaks, a suggested fix, plus its closing "which specs would exercise this" note — and
applies it. Expects that format; if handed something else, ask for the review-framework
report instead of guessing at its structure.

Apply the findings yourself, one at a time. Do not delegate them to agents.

## Order of work

Start with the findings that touch a public contract, a wait/wake or pooling protocol, or more
than one file. Settle the shape of those fixes first, so the smaller edits land on top of the
final structure instead of being redone.

Then work the remaining findings file by file, so each file is opened and edited once rather
than revisited per finding.

## House rules to apply

- Follow the plugin-managed `CLAUDE.md` at the working directory, and this plugin's
  `rage-framework-core` skill for the non-negotiables and for locating the checkout root when
  it is not the working directory.
- Consult the kit skill matching each file being edited: `deadlocks` (which also covers
  `lib/rage/ext/**`), `public-api`, `request-path`, `specs`, `codegen`, `docs`, or `templates`.

## Do not write specs

Applying findings is an implementation step; spec writing is a separate, deliberately invoked
step (this plugin's `write-specs` skill). Do not add examples to prove a change works, and do
not adjust existing stubs so new code passes. Running the specs that cover the files you touch
is fine and encouraged.

## Verification

After every finding is applied, run `bundle exec rubocop` and
`bundle exec yardoc --fail-on-warning` once. Show the output to the user and ask whether to fix
what they report — do not start fixing, not even trivially auto-correctable offenses, since an
offense may be pre-existing or out of scope for this review.

## Reporting

Report which findings were applied and which were deliberately skipped, with the reason for
each, plus the three items `CLAUDE.md`'s "Report" section requires: the blocking-I/O audit
("none" is a valid result, silence is not), a public-API compatibility statement, and which
specs did not actually run.

Skipped items explicitly include any "Spec coverage" or "Ruled out" material in the review that
was out of scope — name those as skipped rather than dropping them silently. Point the user at
this plugin's `write-specs` skill for the "Spec coverage" items; that is where they get
addressed, not here.
