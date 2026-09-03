---
name: deadlocks
description: Fiber deadlock prevention in the Rage framework — for rage-rb/rage core work only, not Rage apps. Read before writing any new wait, park, resource pool, or pub/sub wake-up, or when diagnosing a hung request or leaked fiber. Applies to lib/rage/fiber.rb, lib/rage/fiber_scheduler.rb, lib/rage/ext/active_record/**, and lib/rage/deferred/**.
---

# Fiber deadlocks

A fiber waiting on a wake-up that never arrives parks forever, holding its Active Record
connection and never answering the request. No exception, no log line, no backtrace. Ruby's
deadlock detector covers threads, not fibers under a scheduler.

## Every wait needs a bounded escape

The house pattern, in three subsystems:

- `Rage::FiberScheduler#block` arms `Iodine.run_after` only when given a timeout — omit the
  timeout and the wait is unbounded by construction.
- The Active Record pool's `#connection` parks on a bare `Fiber.yield`, backed by a reaper
  that raises `ActiveRecord::ConnectionTimeoutError` after `@__checkout_timeout`.
- `Rage::Deferred::Queue` raises `Rage::Deferred::PushTimeout` rather than waiting out
  backpressure.

A new wait primitive that can park indefinitely needs an explicit reason why it cannot.

## Guard the wake against stale messages

Both `Fiber.await` and `FiberScheduler#block` bump a generation counter, embed it in the
channel name, and resume only if it still matches:

```ruby
gen = (f.__wait_generation += 1)
channel = f.__await_channel = "await:#{f.object_id}:#{gen}"
# ...
f.resume if f.alive? && gen == f.__wait_generation
```

Without this, a late or duplicate message resumes a fiber that has already moved on to a
different wait — corrupting state rather than hanging, which is harder to diagnose.

## Two shapes to watch

- A `Mutex` held across a yield point. It is scheduler-aware, so it will not raise; it
  stalls silently.
- `Fiber.await` over more children than a fiber-keyed resource can supply. Active Record
  connections are keyed by `Fiber.current`, so the parent's own connection counts against
  the pool.

Read `lib/rage/fiber.rb`, `lib/rage/fiber_scheduler.rb`, and
`lib/rage/ext/active_record/connection_pool.rb` before adding to any of this.

`flock` is not fiber exclusion. The lock lives on the inode and the open file description,
not on the fiber, so a second fiber locking the same fd re-acquires the lock and both run
the critical section. Cross-process locking therefore needs a process-local flag on top of
`flock` — see `@locked` in `lib/rage/deferred/backends/disk.rb`. Since the lock is
tied to the inode, lock a dedicated file that is never renamed; locking a data file that
gets `rename`d leaves holders on the old, unlinked inode. Always take it with `LOCK_NB` and
retry with `sleep` — a blocking `flock` freezes the worker.
