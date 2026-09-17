# rage-agent-kit

[![Validate](https://github.com/serhii-sadovskyi/rage-agent-kit/actions/workflows/validate.yml/badge.svg)](https://github.com/serhii-sadovskyi/rage-agent-kit/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) for
contributors to the **[Rage framework](https://github.com/rage-rb/rage) itself**. Its one
plugin teaches Claude Code the project rules for changing `rage-rb/rage` source. It covers
blocking I/O and fiber deadlocks, public API changes that add without breaking anything, and
the rules for codegen and specs. It also adds a workflow split into phases, and you approve
each phase before the next one starts.

It is **not** for building apps on Rage. For that, use the separate `rage-rb/skills`
marketplace.

## What's included

### The flow

A workflow for larger pieces of work. You run each phase yourself, and **every phase stops for
your approval** before the next one starts. The number of phases depends on the size of the
work: a bug fix skips the design phase and often the edge-case test phase, and only features
with several tasks get a full spec with a task list. Tests are written in two steps: before
the code, failing tests for the main behavior and the most important errors; after the code,
tests for edge cases and the rest.

| Command | Phase |
| --- | --- |
| `/rage-agent-kit:feature:new` | Decide what kind of work it is, write the spec |
| `/rage-agent-kit:task:design` | Design one task, with acceptance criteria |
| `/rage-agent-kit:task:test-core` | Write failing tests for the most important acceptance criteria |
| `/rage-agent-kit:task:implement` | Write the code, so that those tests pass |
| `/rage-agent-kit:task:test-edge` | Add tests for edge cases and the other acceptance criteria |
| `/rage-agent-kit:task:review` | Critical review by one or two reviewers, depending on the change |
| `/rage-agent-kit:task:apply-findings` | Apply the review findings, then run the task's tests one last time |
| `/rage-agent-kit:task:close` | Accept the decisions, close the task |
| `/rage-agent-kit:feature:close` | Close the feature after its work is merged |
| `/rage-agent-kit:component:sync` | Write or update a component document from the code |
| `/rage-agent-kit:feature:status` | What is in progress, and what comes next |

`feature:` commands work on a whole feature, `task:` commands on one of its tasks, and
`component:` commands on a component document. See [FLOW.md](FLOW.md) for how to use them,
with a diagram for each kind of work.

The flow keeps its specs, task docs, and ADRs in a clone of
[`rage-feature-specs`](https://github.com/rage-rb-fans/rage-feature-specs). Put that clone in
your session's working directory, next to the Rage checkout rather than inside it. Phases edit
those files but never commit them.

Review reports are saved in `.rage-agent-kit/reviews/` in the same working directory. They are
not part of either repository: the folder tells git to ignore it, so nothing commits it. A
short summary of each review also goes into the task file, so someone on another computer can
continue the work.

The flow is *spec-anchored*. While a feature is in progress, its spec and task files are kept
in line with the code. When a feature is finished, its files are not updated any more.
Instead, each lasting part of the framework (a *component*, for example Deferred or telemetry)
has one document in `rage-feature-specs/components/` that describes how it works now.
`/rage-agent-kit:component:sync` writes that document from the code and updates it after
changes made outside the flow, and `/rage-agent-kit:feature:close` updates it when a feature
is finished. A later fix to finished work starts a new feature.

These documents are for you and the agents. Other contributors and the maintainers do not see
them, so anything they need still goes into the code, the YARD docs, the changelog, and the PR
description.

### Knowledge

These load automatically when you edit the files they cover, and the flow commands load the
ones they need:

- **rage-framework-core**: core rules that always apply, and how to find the checkout
- **public-api**: API changes that don't break existing code, YARD, CHANGELOG, app templates
- **deadlocks**: how to prevent fiber deadlocks
- **deferred**: how `Rage::Deferred` works inside
- **request-path**: scheduler, `FiberWrapper`, per-request middleware
- **codegen**: code generation at boot time
- **specs**: RSpec conventions for the framework's test suite

## Install

```
/plugin marketplace add serhii-sadovskyi/rage-agent-kit
/plugin install rage-agent-kit@rage-agent-kit
```

Update with `/plugin marketplace update rage-agent-kit`. You can turn it off with
`/plugin disable rage-agent-kit@rage-agent-kit`, or remove it with
`/plugin uninstall rage-agent-kit@rage-agent-kit`.

### Upgrading from 0.5

Version 0.6 renames the flow commands:

| 0.5 | 0.6 |
| --- | --- |
| `discovery:feature` | `feature:new` |
| `design:milestone` | `task:design` |
| `implement:milestone` | `task:implement` |
| `test:cover` | `task:test-edge` (tests before the code are the new `task:test-core`) |
| `review:milestone` | `task:review` |
| `review:apply` | `task:apply-findings` |
| `adr:write` | `task:close` (closing the whole feature is the new `feature:close`) |
| `status:feature` | `feature:status` |

Features that are already in progress have no `component:` and no test records yet.
`/rage-agent-kit:feature:status` shows them, and says which step to run next.

## Session start hook

When a session starts in a Rage checkout (or in a directory with exactly one checkout directly
inside it), the plugin **overwrites `CLAUDE.md`** in that directory using its
[template](plugins/rage-agent-kit/hooks/scripts/CLAUDE.md.template). Manual edits to that file
are lost, so put your own rules in `AGENTS.md`, which the hook never touches. If you already
had your own `CLAUDE.md`, it is backed up once to `CLAUDE.md.bak`. Uninstalling the plugin
does not delete the generated file.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
