---
name: deadlocks
description: Fiber deadlock prevention in the Rage framework — for core work only, not Rage apps. Read before writing any new wait, park, resource pool, pub/sub wake-up, or file lock, or when debugging a hung request or leaked fiber. Applies to lib/rage/fiber.rb, lib/rage/fiber_scheduler.rb, and lib/rage/ext/**.
---

# Fiber deadlocks

A fiber waiting on a wake-up that never arrives parks forever, holding its Active Record
connection and never answering the request. No exception, no log line, no backtrace. Ruby's
deadlock detector covers threads, not fibers under a scheduler.

## Every wait needs a limited way out

The pattern this project uses, in three subsystems:

- `Rage::FiberScheduler#block` sets up `Iodine.run_after` only when given a timeout — leave out the
  timeout and the wait has no limit by design.
- The Active Record pool's `#connection` parks on a plain `Fiber.yield`, supported by a reaper
  that raises `ActiveRecord::ConnectionTimeoutError` after `@__checkout_timeout`.
- `Rage::Deferred::Queue` raises `Rage::Deferred::PushTimeout` instead of waiting until the
  backpressure ends.

A new wait primitive that can park with no time limit needs an explicit reason why it cannot.

## Protect the wake-up from outdated messages

Both `Fiber.await` and `FiberScheduler#block` increase a generation counter, put it in the
channel name, and resume only if it still matches:

```ruby
gen = (f.__wait_generation += 1)
channel = f.__await_channel = "await:#{f.object_id}:#{gen}"
# ...
f.resume if f.alive? && gen == f.__wait_generation
```

Without this, a late or duplicate message resumes a fiber that has already moved on to a
different wait — corrupting state instead of hanging, which is harder to debug.

## Two patterns to watch for

- A `Mutex` held across a yield point. It is scheduler-aware, so it will not raise; it
  gets stuck without any error.
- `Fiber.await` over more children than a fiber-keyed resource can provide. Active Record
  connections are keyed by `Fiber.current`, so the parent's own connection counts toward
  the pool's limit.

The primitives: `Fiber.pause` yields a tick, `Fiber.await` runs work concurrently,
`Fiber.schedule` spawns a fiber. `Fiber.defer` is redefined in `lib/rage/ext/setup.rb` when
the Active Record integration loads; it is not plain `Fiber.yield`.

Read `lib/rage/fiber.rb`, `lib/rage/fiber_scheduler.rb`, and
`lib/rage/ext/active_record/connection_pool.rb` before adding to any of this.

## File locks between fibers

`flock` does not give exclusion between fibers. The lock belongs to the inode and the open
file description, not to the fiber, so a second fiber locking the same fd acquires the lock
again and both run the critical section.

- Cross-process locking therefore needs a process-local flag on top of `flock` — see
  `@locked` in `lib/rage/deferred/backends/disk.rb`.
- Lock a separate file that is used only for locking and is never renamed. The lock is tied
  to the inode, so locking a data file that gets `rename`d leaves lock holders on the old,
  unlinked inode.
- Take the lock with `LOCK_NB` and retry with `sleep` on any file another process can already
  hold. A blocking `flock` freezes the worker.
- A blocking `LOCK_EX` is only acceptable on a file this process just created under a name
  nothing else can guess (PID- and random-suffixed), where nothing else can compete for the
  lock.
