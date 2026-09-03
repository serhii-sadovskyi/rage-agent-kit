---
name: active-record
description: Active Record integration and appraisals for the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when changing lib/rage/ext/**, spec/ext/**, or gemfiles/**. Default rspec excludes spec/ext, so a green local run does not cover this tree.
---

# Active Record integration

`.rspec` excludes `spec/ext/**` from the default run. Reach those specs with
`bundle exec rake appraise` (Active Record 7.1–8.1 gemfiles). A green
`bundle exec rake` does not cover this tree.

Active Record is not the only ORM. `rage new -d` supports mysql, trilogy,
postgresql, and sqlite3, and Sequel is a supported path via
`Sequel.extension :fiber_concurrency`. Do not assume Active Record is loaded.

`Fiber.defer` is redefined here; it is not plain `Fiber.yield`. Connection pool
waits, checkout timeouts, and fiber-keyed connections are covered by this
plugin's `deadlocks` skill — use it before changing any of them.
