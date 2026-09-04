# rage-agent-kit

[![Validate](https://github.com/serhii-sadovskyi/rage-agent-kit/actions/workflows/validate.yml/badge.svg)](https://github.com/serhii-sadovskyi/rage-agent-kit/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) for
people developing the **[Rage framework](https://github.com/rage-rb/rage) itself** — i.e.
contributors changing `rage-rb/rage` source (`lib/rage/`, `rage.gemspec`, `spec/`).

This is **not** for people building applications on top of Rage, and it is independent of
`rage-rb/skills` (which targets Rage app authors). Installing this marketplace has no effect
on any Rage app or the Rage CLI — it only adds skills to your Claude Code session.

## Why

Framework code fails differently than app code — a wait with no timeout doesn't raise, it
parks a fiber forever with no exception and no log line. That kind of bug is easy to write
and easy to miss in review. With this plugin installed, asking Claude Code to add a new wait
primitive in `lib/rage/fiber_scheduler.rb` gets you a fiber-deadlock-aware answer by default:
Claude checks the change against the `deadlocks` skill's "every wait needs a bounded escape"
rule before proposing it, instead of writing a plausible-looking wait that hangs under load.
The same applies across the other skills — an "additive API" nudge before a public method
signature changes, a blocking-I/O flag before a gem gets added to `rage.gemspec`, and so on.

## Audience

Rage core contributors: anyone opening PRs against `rage-rb/rage` who wants Claude Code to
follow the framework's house rules — blocking-I/O and fiber-deadlock discipline, public API
and changelog conventions, boot-time codegen patterns, spec conventions, and an adversarial
framework-code review workflow — while working in that checkout.

## What's included

The `rage-agent-kit` plugin ships these skills:

- **rage-framework-core** — standing contract for the framework checkout: Ruby version
  floor, blocking I/O, performance, boot-time conventions, commands.
- **review-framework** — two-reviewer adversarial review of local framework changes.
- **public-api** — additive-API discipline, YARD, and CHANGELOG conventions.
- **deadlocks** — fiber deadlock prevention for waits, parks, and pub/sub wake-ups.
- **request-path** — rules for the scheduler, `FiberWrapper`, and per-request middleware.
- **codegen** — boot-time code generation conventions.
- **specs** — RSpec conventions for the framework's own test suite.
- **active-record** — Active Record integration and appraisal conventions.
- **docs** — how to edit Rage design docs under `docs/` without rewriting them.
- **templates** — conventions for the generated app templates under `lib/rage/templates/`.

Skills load automatically based on their descriptions and the files you're touching — there's
nothing to invoke manually.

## Install

Nothing is copied into your Rage checkout at install time — everything lives in Claude
Code's plugin cache. The one exception is `CLAUDE.md`, which the plugin's `SessionStart`
hook writes into your checkout on every session; see
[Session start hook](#session-start-hook) below, including the note on it being
overwritten each time.

```
/plugin marketplace add serhii-sadovskyi/rage-agent-kit
/plugin install rage-agent-kit@rage-agent-kit
```

To pick up updates later:

```
/plugin marketplace update rage-agent-kit
```

## Local development / testing

From this repo's root:

```bash
claude plugin validate .
```

To try it locally before publishing changes:

```
/plugin marketplace add ./path/to/this-repo
/plugin install rage-agent-kit@rage-agent-kit
```

Or, from a Rage checkout, point Claude Code directly at the plugin directory without
installing it:

```bash
claude --plugin-dir ./path/to/this-repo/plugins/rage-agent-kit
```

## Uninstall / deactivate

To remove the plugin entirely:

```
/plugin uninstall rage-agent-kit@rage-agent-kit
/plugin marketplace remove serhii-sadovskyi/rage-agent-kit
```

To keep it installed but turn it off temporarily (e.g. for a single session), disable it
instead of uninstalling:

```
/plugin disable rage-agent-kit@rage-agent-kit
```

Re-enable later with `/plugin enable rage-agent-kit@rage-agent-kit`. Note that `CLAUDE.md`
written by the [session start hook](#session-start-hook) is not removed by uninstalling or
disabling the plugin — it's a plain file in your checkout by that point, so delete or revert
it manually if you no longer want it there.

## Session start hook

Every Claude Code session, the plugin's `SessionStart` hook looks for a Rage framework
checkout from the working directory: either `rage.gemspec` right there, or exactly one
immediate subdirectory containing it — the layout some setups use to keep AI-tool files
(`AGENTS.md`, `CLAUDE.md`, `.cursor/`) in a parent directory so the checkout itself stays
clean. Zero or more than one match (ambiguous) is a no-op.

When a checkout is found, the hook **always overwrites `CLAUDE.md`** in the working
directory with this plugin's
[template](plugins/rage-agent-kit/hooks/scripts/CLAUDE.md.template), with paths rewritten
for the detected checkout location. `CLAUDE.md` is plugin-managed — **any manual edits to
it are silently discarded on the next session start.** Put project-specific rules
somewhere else, such as an `AGENTS.md`: the hook never reads or touches `AGENTS.md`, so
one there is safe from it.

The hook only writes a file; it never runs `git add` or touches git state, and it's a
no-op outside a Rage framework checkout. See
[`plugins/rage-agent-kit/hooks/`](plugins/rage-agent-kit/hooks/).

## Versioning

`plugins/rage-agent-kit/.claude-plugin/plugin.json` and the matching entry in
`.claude-plugin/marketplace.json` both carry a `version`. Bumping that version is the
update signal — keep the two in sync.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add or edit a skill.
