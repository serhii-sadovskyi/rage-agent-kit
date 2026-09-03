---
name: templates
description: Generated app templates in the Rage framework — for rage-rb/rage core work only, not Rage apps. Use when changing lib/rage/templates/**. These are user-facing starter files copied into apps, not framework internals, and RuboCop excludes them.
---

# App templates

Files under `lib/rage/templates/` are copied into apps by `rage new` and the
generators. They are listed in `.rubocop.yml` `AllCops: Exclude` — do not restyle
them to match `lib/rage` internals.

Keep them as the public default app: idiomatic Rails-like structure, stable paths
and filenames, and comments that teach the user rather than framework internals
(`@private`, `@__` ivars, codegen). Changing a template is a user-visible change;
include a changelog entry when behavior or the generated layout changes.
