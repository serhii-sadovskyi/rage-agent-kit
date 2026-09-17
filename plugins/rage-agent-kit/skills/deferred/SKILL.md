---
name: deferred
description: Rage::Deferred internals for the Rage framework — for core work only, not Rage apps. Use when changing lib/rage/deferred/**, adding or changing a storage backend, or deciding whether behavior belongs in the queue layer or the backend.
---

# Rage::Deferred

An in-process, at-least-once background queue. No Redis, no separate worker process: tasks are
written to a local write-ahead log and executed by fibers on the same reactor that serves requests.
That constraint is what the product is, so a change here that needs an external service to work is a
design problem, not a dependency question.

## The layers, and the boundary that matters

```
Task / Proxy    user surface — `.enqueue`, retry policy, middleware, telemetry
      ↓ Context (a plain Array; the unit that gets serialized)
Queue           backend-independent layer — scheduling, retries, backpressure, dead-lettering
      ↓ backend contract
Backends::Disk  storage — files, locks, fsync
Backends::Nil
```

`Context` is an Array instead of an object because it is what gets `Marshal`'d on every enqueue and
every retry; `Rage::Deferred::Context` is the only thing that should know its layout.

**The backend is a data access layer and nothing more.** It answers *store this*, *give me that*,
*how many are there*. It never decides when work runs, how much of it to batch, or how fast a caller
should go — that is the backend-independent layer's job, and it has to stay identical whether the store
is a file, Redis, or Postgres.

## Stop and ask before changing the backend contract

Disk is today's only real implementation, but it is a *strategy*, not the design. Redis, SQL, or
something else is expected to sit behind the same contract later, and every method on that contract
is a cost each of them pays forever. So the contract does not grow just because the disk
implementation already had a value available, or because passing something through was the shortest
path to making a feature work. Extending it is a design decision, just like adding a
dependency or a config option: propose it, explain why it is needed, and expect to be told no.

**The default is to solve the problem in the backend-independent layer instead.** A number that comes
out the same for every backend is a constant in `Queue` and the code around it, not a method on the
contract. If the only reason a method exists is that the file implementation needed it, it is in the
wrong place.

The test for a method that really belongs: *can any implementation answer it from facts about
itself?* A backend may describe what it holds, and how its own writes behave. It may not tell a
caller what batch size to use, or how long to hold something back before acting — that is queue
policy tuned for one store, and a Redis or SQL backend would have to invent an answer or copy a
number that only ever meant something for files. Watch especially for a method whose name mentions
one store's mechanics (fsync windows, file rewrites, lock retries): the idea it is really
trying to express usually belongs to the layer above.

Changing an existing method is the same decision in reverse. A change to a signature or its meaning
affects every backend at once, `Backends::Nil` included, and `Nil` must keep fully meeting the
contract instead of being fixed afterwards.

The contract is listed in the header comment of `lib/rage/deferred/backends/disk.rb`. Read it before
touching either backend, and keep it matching the code — it is the only place the contract is
written down. It is internal in the sense that `config.deferred.backend=` accepts only `:disk` and
`nil`, so there are no third-party implementations to break today; that makes it cheap to get right
now and expensive to fix once alternatives exist.

## Lifecycle

`Iodine.task_inc!`/`task_dec!` around a task's perform stop a graceful shutdown from stopping a
task while it is still running. `Queue#apply_backpressure` is the only thing that stops an
enqueue loop from building a backlog with no limit; it raises `PushTimeout` instead of waiting
forever.

Recovery is why the write-ahead log exists. Each worker owns one storage file held under an
exclusive `flock`; on boot a worker takes over the files left behind by workers that died and
replays their pending tasks (`pending_tasks`). A storage file rotates once it passes a size
limit and no immediate tasks are left in it, with the limit raised dynamically so that copying
delayed tasks forward cannot turn into an endless rotation loop.

Tasks that use up all their retries are written to a separate dead-tasks store: one append-only file
shared by all workers and processes, serialized by a non-blocking file lock, with deletions applied
by atomically replacing the file so a crash cannot leave it half-rewritten.

## Common traps

- Everything here runs on the reactor. `sleep` in the dead-tasks store's `with_lock` retry loop is
  safe only because the fiber scheduler handles it — the same call anywhere the scheduler is not
  active blocks the whole worker.
- `flock` does not give exclusion between fibers, which is why the lock is paired with a process-local
  flag. See the `deadlocks` skill before touching any of it.
- Nothing handles an exception raised inside an `Iodine.run_after` block, so anything scheduled that
  way must rescue on its own.
- Deserializing a stored task can fail for reasons that are not the framework's fault — a class that
  no longer exists, a signature that changed. Those paths skip and log instead of stopping a whole batch.
