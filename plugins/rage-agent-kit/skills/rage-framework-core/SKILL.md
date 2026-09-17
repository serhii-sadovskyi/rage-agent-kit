---
name: rage-framework-core
description: Core contract for rage-rb/rage framework source (rage.gemspec, lib/rage/, spec/) — for core work only, not Rage apps. Use before a larger framework change, or to find the checkout root.
---

# Rage framework — core contract

The full contract is in the plugin-managed `CLAUDE.md` at the working directory, written again
at the start of each session by this plugin's `SessionStart` hook. Read it instead of repeating
it. This skill contains only the hard rules, so they still apply if that hook did not run (it
does nothing when the layout is unclear, and when it runs outside a checkout).

## The four hard rules

1. **Ruby 3.3.0 is the minimum version.** Set by `required_ruby_version` in `rage.gemspec` and
   `TargetRubyVersion` in `.rubocop.yml`. Check that recent features exist in 3.3.0 — `it` as an
   implicit block parameter, for example, is 3.4+.
2. **Nothing blocking on the reactor.** One blocking call freezes the worker and every
   request in it. Check every new call site and report the result; "none" is a valid result,
   silence is not. Fiber waits deadlock silently — Ruby's deadlock detector does not cover
   fibers under a scheduler — so use this plugin's `deadlocks` skill before adding any wait,
   park, resource pool, pub/sub wake-up, or file lock.
3. **Additive by default.** New keyword arguments must be optional and default to current
   behavior. If the task cannot be solved additively, or additive would leave a worse API,
   stop and propose the break — what breaks, who is affected, the deprecation shim, and which
   release it targets. Proposing a break is a valid outcome; shipping one silently is not.
   This applies to surfaces in a released gem: one added since the latest release is not
   public yet and can still change without a shim — say so. When you cannot tell, treat it as
   released.
4. **No new gems without asking, and no new required services.** Rage's central promise is one
   process with no Redis and no separate workers, so a feature that needs an external service
   to work by default breaks the product. Stop and ask before adding a gem to `Gemfile` or
   `rage.gemspec`. Iodine (`rage-iodine`) is already a dependency and part of the runtime; use
   its API freely.

The reasons for all of it are in `CONTRIBUTING.md` and `ARCHITECTURE.md` in the Rage
checkout. Read them before your first larger change.

When you plan or review without editing, invoke the matching knowledge skill from this plugin
with the Skill tool — they load on their own only when a file they cover is edited. Do not
write or change tests as a side effect of a change: `/rage-agent-kit:task:test-core` and
`/rage-agent-kit:task:test-edge` do that.

## Finding the checkout root

Paths in the other skills (`lib/`, `spec/`, `docs/`, `rage.gemspec`) are relative to the
checkout root — the directory containing `rage.gemspec` — which is not always the session's
working directory. Some setups keep AI-tool files (`AGENTS.md`, `CLAUDE.md`, `.cursor/`) in a
parent directory so the checkout itself stays clean.

The generated `CLAUDE.md` names the checkout root in its first line. If that line is missing,
find `rage.gemspec` instead of assuming.
