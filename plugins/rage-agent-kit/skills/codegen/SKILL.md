---
name: codegen
description: Boot-time code generation conventions for the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when changing controller actions, logger, telemetry, or Rage::Internal helpers — lib/rage/controller/**, lib/rage/logger/**, lib/rage/telemetry/**, lib/rage/internal.rb.
---

# Boot-time codegen

`CLAUDE.md` says *why* work moves to boot. This skill covers *how* it is written here.
The house examples are `RageController::API.__register_action`, `Rage::Logger#rebuild!`, and
`Rage::Telemetry::Tracer#setup` — each generates a method with or without the feature instead
of branching per request.

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

Pass `__FILE__, __LINE__ + 1` so backtraces point at the generating file and line rather
than `(eval)`. Use `Rage::Internal.build_arguments` when generating calls to user-supplied
methods, so optional kwargs are only forwarded when the method actually declares them.

Anything interpolated into the heredoc becomes source: a name carrying a quote, a newline, or
a non-identifier character generates broken or surprising code. Interpolate values you
control, not values a user supplies verbatim.

Changing generated code does not by itself call for specs. Spec work is this plugin's
`write-specs` skill, invoked separately once the interface is settled.
