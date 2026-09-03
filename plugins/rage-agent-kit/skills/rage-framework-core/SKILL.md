---
name: rage-framework-core
description: Standing contract for working inside a Rage framework checkout (rage-rb/rage) — rage.gemspec, lib/rage/, spec/ — not a Rage or Rails application. Use whenever changing framework source, deciding whether a change is additive or breaking, adding a dependency, auditing for blocking I/O, or before any non-trivial change to the framework itself. Covers the Ruby version floor, blocking-I/O rules, performance and boot-time conventions, code style, and commands to run.
---

# Rage framework — core contract

Rage is a single-threaded, Fiber-based Ruby web framework running on Iodine. This is
framework code: it runs on every request of every app built on Rage.

Rationale for the rules below lives in CONTRIBUTING.md and ARCHITECTURE.md in the Rage
repository the user has open. Read them before your first non-trivial change. Other skills in
this plugin cover file-specific conventions (public API, deadlocks, request path, codegen,
specs, Active Record, docs, templates) — use the one matching the files you're touching.

## Stop and ask before

- Breaking any public API, method signature, config key, or wire format. Additive by
  default: new keyword arguments must be optional and default to current behavior. If the
  task cannot be solved additively, or additive would leave a worse API, say so and propose
  the break — what breaks, who is affected, the deprecation shim, and which release it
  targets. `Rage.load_middlewares` in `lib/rage-rb.rb` is the house pattern. Proposing a
  break is a valid outcome; shipping one silently is not.
- Adding a gem to `Gemfile` or `rage.gemspec`. Rage's central promise is one process with no
  Redis and no separate workers, so a feature that needs an external service to function by
  default breaks the product, not just the dependency list. Iodine (`rage-iodine`) is already
  a dependency and part of the runtime; use its API freely.
- Introducing an abstraction, adapter, registry, or config knob the task does not require.
  Duplication beats the wrong abstraction — justify it or skip it.
- Using anything newer than Ruby 3.3.0.

## Ruby 3.3.0 is the floor

Set by `required_ruby_version` in `rage.gemspec` and `TargetRubyVersion` in `.rubocop.yml`;
CI runs 3.3.0, 3.3, 3.4, and 4.0. `.ruby-version` (3.4.3) is the local interpreter, not a
target. Verify recent features exist in 3.3.0 — for example `it` as an implicit block
parameter is 3.4+.

## Blocking I/O

One blocking call freezes the worker and every request in it. Audit every new call site and
report the result; "none" is a valid result, silence is not. This applies everywhere on the
reactor, not just to files under `lib/rage/middleware`.

Flag as worker-freezing: native extension calls (DB drivers, crypto, compression, FFI);
`Thread.new`; `system`, backticks, `Process.spawn`/`wait`, `IO.popen`; `flock`, `fsync`,
large file reads and writes; long CPU-bound loops; client libraries with their own thread
pool or `IO.select`.

Escape hatches, in order of preference: scheduler-aware I/O, then `Iodine::WorkerPool` via
`blocking_operation_wait` (`lib/rage/fiber_scheduler.rb`), then `Rage::Deferred`, then
`Fiber.new(blocking: true)` — never in the request path.

`Fiber.pause` yields a tick, `Fiber.await` runs work concurrently, `Fiber.schedule` spawns.
`Fiber.defer` is redefined by the Active Record integration; it is not plain `Fiber.yield`.

Fiber waits deadlock silently — Ruby's deadlock detector does not cover fibers under a
scheduler. Before adding any wait, park, resource pool, or pub/sub wake-up, use this
plugin's `deadlocks` skill.

## Performance

- Do work at boot, not per request. See `RageController::API.__register_action`.
- A feature must cost nothing to users who do not enable it. Generate a method with or
  without the feature rather than branching on every request — see `Rage::Logger#rebuild!`
  and `Rage::Telemetry::Tracer#setup`.
- No avoidable allocations on the happy path.
- Boot time is a feature too. Moving work to boot makes requests cheaper and startup slower;
  when the two conflict, say which you chose and why.

## Conventions

- `# frozen_string_literal: true` in every new file. Nothing enforces this — the cop is off,
  so a green `rubocop` run proves nothing here. Check it by hand.
- Formatting is whatever `bundle exec rubocop` accepts (`DisabledByDefault`, explicit
  allowlist).
- Internal API is `__`-prefixed and tagged `# @private`; internal ivars are `@__`;
  Fiber-locals are namespaced `:__rage_*`.
- User-facing methods need YARD `@param`/`@return`/`@example`. CI runs
  `yardoc --fail-on-warning`, so a malformed tag fails the build.
- Active Record is not the only ORM. Sequel is a supported path via
  `Sequel.extension :fiber_concurrency`; do not assume Active Record is loaded.
- Design docs under `docs/` follow this plugin's `docs` skill.

## Commands

```bash
bundle exec rake                      # default task; what CI runs
bundle exec rubocop
bundle exec yardoc --fail-on-warning
bundle exec rake appraise             # spec/ext against Active Record 7.1-8.1
```

`.rspec` excludes `spec/ext/**` from the default run. Most integration, Fiber, and adapter
specs skip unless `ENABLE_EXTERNAL_TESTS=true` is set along with `TEST_HTTP_URL`,
`TEST_PG_URL`, `TEST_MYSQL_URL`, and `TEST_REDIS_URL`. A green local run is not full
coverage — say which specs did not actually run rather than claiming they passed.

Never commit spec artifacts such as `storage/deferred-*`.

## Report

Close every change with the blocking-I/O audit, a public-API compatibility statement, and
which specs you did not actually run.
