---
name: public-api
description: Public API, YARD, changelog, and generated app templates for the Rage framework — for core work only, not Rage apps. Use when changing user-facing Rage classes, config keys, CHANGELOG.md, lib/rage-rb.rb, controllers, Cable, events, Deferred's public files, or lib/rage/templates/**.
---

# Public API

Controller and Cable should stay familiar to Rails developers; Rage is not a Rails
reimplementation.

When a break cannot be avoided, `Rage.load_middlewares` in `lib/rage-rb.rb` is the pattern
this project uses: keep the method, print a warning, tag it `@deprecated`.

Adding a telemetry span is almost a breaking change. Users match with wildcards
(`handle "cable.*"`), so a new span starts firing their existing handlers.

New always-loaded files go in `lib/rage/all.rb` in dependency order; the framework
does not use Zeitwerk on itself. Prefer `autoload` in `lib/rage-rb.rb` for optional
subsystems, so they cost nothing at boot for apps that never touch them.

User-facing methods need YARD `@param` / `@return` / `@example` tags — write them as part
of the change.

User-visible behavior needs an entry under `## [Unreleased]` in `CHANGELOG.md`
(`Added` / `Fixed` / `Changed`), prefixed with the component in brackets — `[Deferred]
Add ...`, `[OpenAPI]`, `[Logger]` — and with the PR number added at the end when it is known,
matching the entries already there. If the change is internal-only, say so in the PR
description and let a maintainer apply the `skip-changelog` label; according to
`CONTRIBUTING.md`, adding that label is their decision, so do not skip the entry on your own.
A change to a surface that has not been released yet is covered by that surface's existing
`[Unreleased]` entry — update that entry instead of adding a second one.

## Generated app templates

Files under `lib/rage/templates/` are copied into apps by `rage new` and the generators. They
are listed in `.rubocop.yml` `AllCops: Exclude` — do not change their style to match
`lib/rage` internals.

Keep them as the public default app: idiomatic Rails-like structure, stable paths and
filenames, and comments that teach the user instead of explaining framework internals
(`@private`, `@__` ivars, codegen).
