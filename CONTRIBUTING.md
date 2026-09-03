# Contributing

This repo ships a single Claude Code plugin, `rage-agent-kit`
(`plugins/rage-agent-kit/`), made up of skills that teach Claude Code the house rules for
contributing to [`rage-rb/rage`](https://github.com/rage-rb/rage). See
[CLAUDE.md](CLAUDE.md) for the full maintainer notes this file summarizes.

## Adding or editing a skill

1. Each skill is a single `SKILL.md` under `plugins/rage-agent-kit/skills/<name>/`.
2. Frontmatter is just `name` and `description`. Claude matches the description against the
   task at hand to decide whether to load the skill, so front-load the trigger conditions
   (which files, which situations) before summarizing what the skill covers — follow the
   pattern in the existing skills.
3. Skills load automatically; there is no manual invocation step to wire up.
4. If you add a new skill, add an entry for it to the "What's included" list in
   [README.md](README.md).
5. Scope check: this marketplace is for people changing `rage-rb/rage` source. Skills aimed
   at people building applications on top of Rage belong in the separate `rage-rb/skills`
   marketplace, not here.

## Bumping the version

`plugins/rage-agent-kit/.claude-plugin/plugin.json` and the matching plugin entry in
`.claude-plugin/marketplace.json` both carry a `version` field, and they must always match —
CI fails the build otherwise. Bump both on any change to `plugins/rage-agent-kit/**`.

## Before opening a PR

Run this from the repo root and make sure it passes:

```bash
claude plugin validate .
```

Try the plugin locally against a real `rage-rb/rage` checkout before submitting, either by
installing it from your local clone:

```
/plugin marketplace add ./path/to/this-repo
/plugin install rage-agent-kit@rage-agent-kit
```

or by pointing Claude Code at the plugin directory directly, without installing it:

```bash
claude --plugin-dir ./path/to/this-repo/plugins/rage-agent-kit
```
