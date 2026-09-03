---
name: specs
description: RSpec conventions for the Rage framework test suite — for rage-rb/rage core work only, not Rage apps. Use when writing or editing files under spec/**/*.rb.
---

# Rage specs

Write or run RSpec tests only when the user explicitly asks for tests in this session.
Implementing a feature or fix is not by itself a request to add or run test coverage.
Tests, when written, come only after the implementation's interface has been confirmed.

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

- `.rspec` excludes `spec/ext/**` from the default run; reach it via `bundle exec rake appraise`.
- Integration, Fiber, and adapter specs skip unless `ENABLE_EXTERNAL_TESTS=true` with
  `TEST_HTTP_URL`, `TEST_PG_URL`, `TEST_MYSQL_URL`, `TEST_REDIS_URL`.
- `spec/spec_helper.rb` auto-includes `IntegrationHelper`, `RequestHelper`,
  `ControllerHelper`, `ReactorHelper`, and `WebSocketHelper`; do not re-require them.
- `launch_server` builds and installs the gem, so integration specs are slow.
- Clean up `storage/deferred-*` artifacts; never commit them.
