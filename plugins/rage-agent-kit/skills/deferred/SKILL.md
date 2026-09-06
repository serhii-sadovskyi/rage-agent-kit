---
name: deferred
description: How Rage::Deferred is put together — the boundary between the agnostic queue layer and the storage backend, and the task lifecycle from enqueue through retry to dead-lettering — for rage-rb/rage core work only, not Rage apps. Use when changing anything under lib/rage/deferred/**, adding to or writing a backend, or deciding which layer a new piece of behavior belongs in.
---

# Rage::Deferred

An in-process, at-least-once background queue. No Redis, no separate worker process: tasks are
written to a local write-ahead log and executed by fibers on the same reactor that serves requests.
That constraint is the product, so a change here that needs an external service to function is a
design problem, not a dependency question.

## The layers, and the boundary that matters

```
Task / Proxy    user surface — `.enqueue`, retry policy, middleware, telemetry
      ↓ Context (a plain Array; the unit that gets serialized)
Queue           agnostic layer — scheduling, retries, backpressure, dead-lettering
      ↓ backend contract
Backends::Disk  storage — files, locks, fsync
Backends::Nil
```

`Context` is an Array rather than an object because it is what gets `Marshal`'d on every enqueue and
every retry; `Rage::Deferred::Context` is the only thing that should know its layout.

**The backend is a data access layer and nothing more.** It answers *store this*, *give me that*,
*how many are there*. It never decides when work runs, how much of it to batch, or how a caller
should pace itself — that is the agnostic layer's job, and it has to stay identical whether the store
is a file, Redis, or Postgres.

## Stop and ask before changing the backend contract

Disk is today's only real implementation, but it is a *strategy*, not the design. Redis, SQL, or
something else is expected to sit behind the same contract later, and every method on that contract
is a tax each of them pays forever. So the contract does not grow just because the disk
implementation happened to have a value handy, or because passing something through was the shortest
path to making a feature work. Extending it is a design decision on the same footing as adding a
dependency or a config knob: propose it, justify it, and expect to be told no.

**The default is to solve the problem in the agnostic layer instead.** A number that comes out the
same for every backend is a constant in `Queue` and its neighbours, not a method on the contract. If
the only reason a method exists is that the file implementation needed it, it is in the wrong place.

The test for a method that genuinely belongs: *can any implementation answer it from facts about
itself?* A backend may describe what it holds, and how its own writes behave. It may not tell a
caller what batch size to use, or how long to hold something back before acting — that is queue
policy tuned against one store, and a Redis or SQL backend would have to invent an answer or copy a
number that only ever meant something for files. Watch especially for a method whose name mentions
one store's mechanics (fsync windows, file rewrites, lock retries): the concept it is really
reaching for usually belongs to the layer above.

Changing an existing method is the same decision in reverse. A signature or semantics change lands on
every backend at once, `Backends::Nil` included, and `Nil` must keep satisfying the contract in full
rather than being patched up afterwards.

The contract is listed in the header comment of `lib/rage/deferred/backends/disk.rb`. Read it before
touching either backend, and keep it in step with the code — it is the only place the contract is
written down. It is internal in the sense that `config.deferred.backend=` accepts only `:disk` and
`nil`, so there are no third-party implementations to break today; that makes it cheap to get right
now and expensive to fix once alternatives exist.

## Lifecycle

`Task.enqueue` builds a `Context`; `Queue#enqueue` writes it to the write-ahead log and arms an
`Iodine.run_after`. When the timer fires, `Fiber.schedule` runs `__perform`: a truthy result removes
the task from the log, a falsy one increments attempts and either re-enqueues with backoff
(`__next_retry_in`) or gives up and dead-letters it through `abandon_task`.
`Iodine.task_inc!`/`task_dec!` around the perform keep a graceful shutdown from cutting a task off
mid-flight. `Queue#apply_backpressure` is the only thing standing between an enqueue loop and an
unbounded backlog; it raises `PushTimeout` rather than waiting forever.

Recovery is why the log exists. Each worker owns one storage file held under an exclusive `flock`;
on boot a worker adopts the files left behind by workers that died and replays their pending tasks
(`pending_tasks`). A storage file rotates once it passes a size limit and all immediate tasks have
drained, with the limit raised dynamically so that copying delayed tasks forward cannot spin into an
endless rotation loop.

Tasks that exhaust their retries are written to a separate dead-tasks store: one append-only file
shared by all workers and processes, serialized by a non-blocking file lock, with deletions applied
by atomically replacing the file so a crash cannot leave it half-rewritten.

## Things that bite

- Everything here runs on the reactor. `sleep` in the dead-tasks store's `with_lock` retry loop is
  safe only because the fiber scheduler handles it — the same call anywhere the scheduler is not
  active blocks the whole worker.
- `flock` is not fiber exclusion, which is why the lock is paired with a process-local flag. See the
  `deadlocks` skill before touching any of it.
- Nothing handles an exception raised inside an `Iodine.run_after` block, so anything scheduled that
  way must rescue on its own.
- Deserializing a stored task can fail for reasons that are not the framework's fault — a class that
  no longer exists, a signature that changed. Those paths skip and log rather than abort a batch.
- Spec artifacts land in `storage/deferred-*`. Never commit them.
