---
name: public-api
description: Public API, YARD, and changelog conventions for the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when changing user-facing Rage classes, config keys, CHANGELOG.md, lib/rage-rb.rb, controllers, Cable, events, or Deferred public files (lib/rage/deferred/deferred.rb, task.rb, queue.rb).
---

# Public API

Additive by default: new keyword arguments must be optional and default to current
behavior. Controller and Cable should stay familiar to Rails developers; Rage is not
a Rails reimplementation.

If the change cannot be made additively, or additive would leave a worse API, stop
and propose the break rather than shipping it silently. `Rage.load_middlewares` in
`lib/rage-rb.rb` is the house pattern: keep the method, print a warning, tag it
`@deprecated`.

Adding a telemetry span is quasi-breaking. Users match with wildcards
(`handle "cable.*"`), so a new span starts firing their existing handlers.

New always-loaded files go in `lib/rage/all.rb` in dependency order; the framework
does not use Zeitwerk on itself. Prefer `autoload` in `lib/rage-rb.rb` for optional
subsystems, so they cost nothing at boot for apps that never touch them.

User-facing methods need YARD `@param` / `@return` / `@example` tags — write them as part
of the change; when `yardoc` may be run to validate them is stated in `CLAUDE.md`'s Commands
section. Internal API is `__`-prefixed and tagged `# @private`; internal ivars are `@__`;
Fiber-locals are `:__rage_*`.

User-visible behavior needs an entry under `## [Unreleased]` in `CHANGELOG.md`
(`Added` / `Fixed` / `Changed`), prefixed with the component in brackets — `[Deferred]
Add ...`, `[OpenAPI]`, `[Logger]` — and appending the PR number where one is known, matching
the entries already there. If the change is internal-only, say so in the PR description and
let a maintainer apply the `skip-changelog` label; per `CONTRIBUTING.md` that label is theirs
to add, so do not skip the entry unilaterally.

Changing a public signature does not by itself call for specs. Spec work is this plugin's
`write-specs` skill, invoked separately once the interface is settled.
