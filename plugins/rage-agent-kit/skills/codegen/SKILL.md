---
name: codegen
description: Boot-time code generation conventions for the Rage framework — for core work only, not Rage apps. Use when changing controller actions, logger, telemetry, or Rage::Internal helpers — lib/rage/controller/**, lib/rage/logger/**, lib/rage/telemetry/**, lib/rage/internal.rb.
---

# Boot-time codegen

Generated methods are built with `class_eval` and a heredoc:

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

Pass `__FILE__, __LINE__ + 1` so backtraces point at the generating file and line instead of
`(eval)`. Use `Rage::Internal.build_arguments` when generating calls to user-supplied
methods, so optional kwargs are only passed when the method actually declares them.

Anything interpolated into the heredoc becomes source: a name that contains a quote, a newline, or
a non-identifier character generates broken or unexpected code. Interpolate values you
control, not values that come from a user exactly as given.
