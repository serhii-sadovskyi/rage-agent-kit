---
name: codegen
description: Boot-time code generation conventions for the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when changing controller actions, logger, telemetry, or Rage::Internal helpers — lib/rage/controller/**, lib/rage/logger/**, lib/rage/telemetry/**, lib/rage/internal.rb.
---

# Boot-time codegen

A feature must cost nothing for users who do not enable it. Generate a method with
or without the feature at boot rather than branching on every request. See
`RageController::API.__register_action`, `Rage::Logger#rebuild!`, and
`Rage::Telemetry::Tracer#setup`.

```ruby
class_eval <<~RUBY, __FILE__, __LINE__ + 1
  def __run_#{action}
    #{before_actions_chunk}
    #{action} unless @__before_callback_rendered
    #{after_actions_chunk}
    [@__status, @__headers, @__body]
  end
RUBY
```

Pass `__FILE__, __LINE__ + 1` so backtraces stay useful. Use
`Rage::Internal.build_arguments` when generating calls to user-supplied methods so
optional kwargs are only forwarded when the method declares them.

Do work at boot, not per request. No avoidable allocations on the happy path.
