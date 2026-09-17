---
name: request-path
description: Request-path Fiber/Iodine rules for the Rage framework — for core work only, not Rage apps. Use when editing the scheduler, FiberWrapper, or middleware that sits on every request — lib/rage/middleware/**, lib/rage/application.rb, lib/rage/fiber_scheduler.rb.
---

# Request path

`Rage::FiberWrapper` must stay at the top of the stack. It wraps each request in a
Fiber and implements Iodine's defer protocol: if the fiber is still `alive?` after
`@app.call`, return `[:__http_defer__, fiber]`; otherwise return `fiber.__get_result`.
When it finishes, it `Iodine.publish`es the fiber id so the connection can resume.

Nothing on the canonical worker-freezing list in `CLAUDE.md` belongs on this path unless it
goes through one of the ways listed there to move it off the reactor.

`Mutex`, `Queue`, and `ConditionVariable` are scheduler-aware — Ruby routes them
through `FiberScheduler#block`/`#unblock`, which yields the fiber, not the worker.
They are not a blocking-I/O problem, but they are a sign of bad design, since a
single-threaded runtime has nothing to synchronize — and a `Mutex` can still hang a fiber
silently (see `deadlocks`). Adding one here needs a good reason; `Thread.new` never belongs
here at all. The few legitimate uses in `lib/` change over time, so find them with
`git grep -n -e 'Mutex.new' -e 'Thread.new' -- lib/` from the checkout root instead of
assuming a list is complete.

Read `lib/rage/fiber.rb`, `lib/rage/fiber_scheduler.rb`, and
`lib/rage/middleware/fiber_wrapper.rb` before changing this path. For waits, parks, pub/sub
wake-ups, and file locks, also use this plugin's `deadlocks` skill.
