---
name: request-path
description: Request-path Fiber/Iodine rules for the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when editing the scheduler, FiberWrapper, or middleware that sits on every request — lib/rage/middleware/**, lib/rage/application.rb, lib/rage/fiber.rb, lib/rage/fiber_scheduler.rb.
---

# Request path

`Rage::FiberWrapper` must stay at the top of the stack. It wraps each request in a
Fiber and implements Iodine's defer protocol: if the fiber is still `alive?` after
`@app.call`, return `[:__http_defer__, fiber]`; otherwise return `fiber.__get_result`.
On completion it `Iodine.publish`es the fiber id so the connection can resume.

One blocking call freezes the worker and every request in it. Do not add
`Thread.new`, `system` / backticks / `Process.spawn`, blocking `flock`, `fsync`,
large file I/O, or native extensions on this path.

Escape hatches, in order: scheduler-aware I/O, then `Iodine::WorkerPool` via
`blocking_operation_wait`, then `Rage::Deferred`, then `Fiber.new(blocking: true)` —
never in the request path.

`Mutex`, `Queue`, and `ConditionVariable` are scheduler-aware — Ruby routes them
through `FiberScheduler#block`/`#unblock`, which yields the fiber, not the worker.
They are not a blocking-I/O problem; they are a design smell, since a
single-threaded runtime has nothing to synchronize. All of `lib/` contains one
`Mutex` and three `Thread.new` calls, every one outside request processing — a
fourth of either needs justification.

`Fiber.pause` yields a tick, `Fiber.await` runs work concurrently, `Fiber.schedule`
spawns. `Fiber.defer` is redefined by the Active Record integration; it is not
plain `Fiber.yield`.

Read `lib/rage/fiber.rb`, `lib/rage/fiber_scheduler.rb`, and
`lib/rage/middleware/fiber_wrapper.rb` before changing this path. For waits, parks,
or pub/sub wake-ups, also use this plugin's `deadlocks` skill.
