---
name: specs
description: RSpec conventions for the Rage framework test suite — for core work only, not Rage apps. Use when writing or editing files under spec/**/*.rb or gemfiles/**, including the appraisal-only spec/ext tree.
---

# Rage specs

These are the conventions to follow when spec work has been asked for. When specs may be run
at all is stated once, in `CLAUDE.md`'s Commands section.

Specs follow the same structure as `lib/`. `spec/spec_helper.rb` calls
`disable_monkey_patching!`, so always use `RSpec.describe`, never plain `describe`, and only
`expect` syntax.

Tests written before the code (`task:test-core`) can refer to a class or method that does not
exist yet. Keep every reference to it inside an example, or inside a `let`, `subject`, or
`before` block, which run per example. Describe a new class by its name as a string —
`RSpec.describe "Rage::NewThing"` — so the file still loads and the missing constant fails
only the examples that use it. `described_class` is `nil` in that case, so name the constant
in the example. Once the class exists, `task:test-edge` replaces the string with the class
itself; that is the only change a later phase makes to such a test.

## Fiber and scheduler specs

Use `within_reactor` from `spec/support/reactor_helper.rb`. `Iodine.start` blocks the
thread, so the block must **return a lambda** that contains the expectation — the helper calls
it after the reactor stops. A plain `expect` inside the block will not be evaluated.

```ruby
it "performs a long HTTP GET" do
  within_reactor do
    result = Net::HTTP.get(URI("#{TEST_HTTP_URL}/long-http-get"))
    -> { expect(result).to eq("...") }
  end
end
```

There is a 10-second timeout; a spec that hangs will show up as `execution expired`.

An error raised inside the block does not reach RSpec: Iodine only logs it, and the example
fails with ``undefined method `__get_result' for nil``. To see the real error — for example the
`NameError` of a class that does not exist yet — rescue inside the block and return a lambda
that raises it again:

```ruby
within_reactor do
  result = Rage::NewThing.new.call
  -> { expect(result).to eq(:ok) }
rescue => e
  -> { raise e }
end
```

## What actually runs

- `.rspec` excludes `spec/ext/**` from the default run. Run that tree with
  `bundle exec rake appraise`, which runs it against the Active Record 7.1–8.1 gemfiles under
  `gemfiles/`. A green `bundle exec rake` proves nothing about it.
- Integration, Fiber, and adapter specs skip unless `ENABLE_EXTERNAL_TESTS=true` with
  `TEST_HTTP_URL`, `TEST_PG_URL`, `TEST_MYSQL_URL`, `TEST_REDIS_URL`.
- `spec/spec_helper.rb` auto-includes the helpers under `spec/support`; do not require them
  again.
- `launch_server` builds and installs the gem, so integration specs are slow.

## Finding what a file already covers

To see which behaviors a spec file already covers, list its example names instead of reading
the file from start to end:

```bash
rg -n '^\s*(RSpec\.)?(describe|context|it|specify)\b' spec/path/to/thing_spec.rb
```

Read an example's body only when its name is not enough to tell what it checks.
