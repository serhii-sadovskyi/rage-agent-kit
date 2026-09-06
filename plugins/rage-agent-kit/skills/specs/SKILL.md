---
name: specs
description: RSpec conventions for the Rage framework test suite — for rage-rb/rage core work only, not Rage apps. Use when writing or editing files under spec/**/*.rb or gemfiles/**, including the appraisal-only spec/ext tree.
---

# Rage specs

These are the conventions to follow when spec work has been asked for. Deciding *what* to
cover and writing it is this plugin's `write-specs` skill, a deliberately invoked step; when
specs may be run at all is stated once, in `CLAUDE.md`'s Commands section.

Specs mirror `lib/`. `spec/spec_helper.rb` calls `disable_monkey_patching!`, so always use
`RSpec.describe`, never bare `describe`, and only `expect` syntax.

## Fiber and scheduler specs

Use `within_reactor` from `spec/support/reactor_helper.rb`. `Iodine.start` blocks the
thread, so the block must **return a lambda** carrying the expectation — the helper calls
it after the reactor stops. A bare `expect` inside the block will not be evaluated.

```ruby
it "performs a long HTTP GET" do
  within_reactor do
    result = Net::HTTP.get(URI("#{TEST_HTTP_URL}/long-http-get"))
    -> { expect(result).to eq("...") }
  end
end
```

There is a 10-second timeout; a spec that hangs will surface as `execution expired`.

## What actually runs

- `.rspec` excludes `spec/ext/**` from the default run. Reach that tree with
  `bundle exec rake appraise`, which runs it against the Active Record 7.1–8.1 gemfiles under
  `gemfiles/`. A green `bundle exec rake` proves nothing about it.
- Integration, Fiber, and adapter specs skip unless `ENABLE_EXTERNAL_TESTS=true` with
  `TEST_HTTP_URL`, `TEST_PG_URL`, `TEST_MYSQL_URL`, `TEST_REDIS_URL`.
- `spec/spec_helper.rb` auto-includes `IntegrationHelper`, `RequestHelper`,
  `ControllerHelper`, `ReactorHelper`, and `WebSocketHelper`; do not re-require them.
- `launch_server` builds and installs the gem, so integration specs are slow.
- Clean up `storage/deferred-*` artifacts; never commit them.
