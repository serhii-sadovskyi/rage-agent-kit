---
name: rage-framework-core
description: Standing contract for rage-rb/rage framework source (rage.gemspec, lib/rage/, spec/) — for core work only, not Rage apps. Use before any non-trivial framework change, and to locate the checkout root when it is not the working directory.
---

# Rage framework — core contract

Rage is a single-threaded, Fiber-based Ruby web framework running on Iodine. This is
framework code: it runs on every request of every app built on Rage.

The full contract — blocking-I/O rules and the canonical list of worker-freezing primitives,
performance and boot-time conventions, code style, commands and when they may be run, agent
process rules, and the closing report — lives in the plugin-managed `CLAUDE.md` at the
working directory, written fresh each session by this plugin's `SessionStart` hook. Read it
rather than restating it. This skill carries only the non-negotiables, so they still hold if
that hook did not run (it no-ops on an ambiguous layout, and outside a checkout entirely).

## The four non-negotiables

1. **Ruby 3.3.0 is the floor.** Set by `required_ruby_version` in `rage.gemspec` and
   `TargetRubyVersion` in `.rubocop.yml`. Verify recent features exist in 3.3.0 — `it` as an
   implicit block parameter, for example, is 3.4+.
2. **Nothing blocking on the reactor.** One blocking call freezes the worker and every
   request in it. Audit every new call site and report the result; "none" is a valid result,
   silence is not. Fiber waits deadlock silently — Ruby's deadlock detector does not cover
   fibers under a scheduler — so use this plugin's `deadlocks` skill before adding any wait,
   park, resource pool, or pub/sub wake-up.
3. **Additive by default.** New keyword arguments must be optional and default to current
   behavior. If the task cannot be solved additively, or additive would leave a worse API,
   stop and propose the break — what breaks, who is affected, the deprecation shim, and which
   release it targets. Proposing a break is a valid outcome; shipping one silently is not.
4. **No new gems, no new required services.** Rage's central promise is one process with no
   Redis and no separate workers. Iodine (`rage-iodine`) is already a dependency and part of
   the runtime; use its API freely.

Rationale for all of it lives in `CONTRIBUTING.md` and `ARCHITECTURE.md` in the Rage
checkout. Read them before your first non-trivial change.

## Finding the checkout root

Paths in the other skills (`lib/`, `spec/`, `docs/`, `rage.gemspec`) are relative to the
checkout root — the directory containing `rage.gemspec` — which is not always the session's
working directory. Some setups keep AI-tool files (`AGENTS.md`, `CLAUDE.md`, `.cursor/`) in a
parent directory so the checkout itself stays clean.

The generated `CLAUDE.md` opens by naming the root explicitly: either "The Rage framework
checkout is this directory" or "The Rage framework checkout is `./<dir>`, not this
directory." When that note is absent, locate `rage.gemspec` rather than assuming.

## File-specific skills

`public-api`, `deadlocks`, `request-path`, `codegen`, `specs`, `docs`, and `templates` cover
the conventions for particular trees — use the one matching the files you're touching.
`review-framework`, `apply-review`, and `write-specs` are deliberately invoked steps, not
things to fold into an implementation task.
