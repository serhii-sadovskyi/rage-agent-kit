---
name: request-path
description: Request-path Fiber/Iodine rules for the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when editing the scheduler, FiberWrapper, or middleware that sits on every request — lib/rage/middleware/**, lib/rage/application.rb, lib/rage/fiber.rb, lib/rage/fiber_scheduler.rb.
---

# Request path

`Rage::FiberWrapper` must stay at the top of the stack. It wraps each request in a
Fiber and implements Iodine's defer protocol: if the fiber is still `alive?` after
`@app.call`, return `[:__http_defer__, fiber]`; otherwise return `fiber.__get_result`.
On completion it `Iodine.publish`es the fiber id so the connection can resume.

One blocking call freezes the worker and every request in it. Nothing on the canonical
worker-freezing list in `CLAUDE.md` belongs on this path, and neither does any of the escape
hatches it names — `Iodine::WorkerPool`, `Rage::Deferred`, and
`Fiber.new(blocking: true)` are for work moved *off* the request path, not for use on it.

`Mutex`, `Queue`, and `ConditionVariable` are scheduler-aware — Ruby routes them
through `FiberScheduler#block`/`#unblock`, which yields the fiber, not the worker.
They are not a blocking-I/O problem; they are a design smell, since a
single-threaded runtime has nothing to synchronize. The only `Mutex` in `lib/` is
`Rage::Reloader`'s, held around the development reloader check on each request
(`lib/rage/middleware/reloader.rb`); a second one anywhere needs justification.
`Thread.new` appears only in `FiberScheduler#process_wait` and the skills CLI — never
on the request path.

`Fiber.pause` yields a tick, `Fiber.await` runs work concurrently, `Fiber.schedule`
spawns. `Fiber.defer` is redefined in `lib/rage/ext/setup.rb` when the Active Record
integration loads; it is not plain `Fiber.yield`.

Read `lib/rage/fiber.rb`, `lib/rage/fiber_scheduler.rb`, and
`lib/rage/middleware/fiber_wrapper.rb` before changing this path. For waits, parks,
or pub/sub wake-ups, also use this plugin's `deadlocks` skill.

Changing the scheduler or middleware does not by itself call for specs. Spec work is this
plugin's `write-specs` skill, invoked separately once the interface is settled.
