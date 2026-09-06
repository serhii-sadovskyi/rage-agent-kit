# rage-agent-kit — maintainer notes

This repo is a Claude Code plugin marketplace, not a Rage app or the Rage framework itself.
It ships one plugin, `rage-agent-kit` (`plugins/rage-agent-kit/`), whose skills teach
Claude Code the house rules for contributing to `rage-rb/rage`. See [README.md](README.md)
for the audience and install instructions.

## Editing skills

- Each skill is a single `SKILL.md` under `plugins/rage-agent-kit/skills/<name>/`.
- Frontmatter is just `name` and `description`. The description is what Claude matches
  against to decide whether to load the skill — front-load the trigger conditions (which
  files, which situations) before the summary of what it covers, the way the existing skills
  do.
- The `description` loads into every session's context whether or not the skill ends up
  firing — it is the one part of a skill that is never free. Keep it as short as the trigger
  conditions allow, and don't restate the same disambiguation clause verbatim across skills;
  reuse a short, consistent phrasing instead (e.g. "for rage-rb/rage core work only, not Rage
  apps"). Skill *bodies* only load once triggered, so they can be as detailed as the topic
  needs — the economy pressure applies to the description, not the content.
- Most skills load automatically off their description. `review-framework`, `apply-review`,
  and `write-specs` are the exception: they are deliberately invoked steps, their
  descriptions say so, and the passive skills point at them rather than folding their work
  in ("Spec work is this plugin's `write-specs` skill, invoked separately"). When adding a
  skill, decide which of the two it is and write the description to match.
- New skills need an entry in the `README.md` "What's included" list.

## The session hook and its template

The plugin also ships a `SessionStart` hook under `plugins/rage-agent-kit/hooks/`:
`hooks.json` wires up `scripts/sync-claude-md.sh`, which renders
`scripts/CLAUDE.md.template` into a `CLAUDE.md` in the consumer's Rage checkout at every
session start. Three constraints come with it:

- The template is the single source of truth for the rules every framework session needs —
  the canonical worker-freezing list, when `yardoc` and RSpec may be run, agent process
  rules, the closing report. Skills reference it ("the canonical list is in `CLAUDE.md`")
  instead of restating it, and `rage-framework-core` deliberately keeps only the
  non-negotiables that must still hold when the hook does not run (ambiguous layout, or
  outside a checkout). Change a shared rule in the template, then check that no skill has
  drifted into repeating it.
- `sync-claude-md.sh` is POSIX `sh` and POSIX `sed` only — it runs against whatever `sed`
  the consumer has, and the BSD one on macOS rejects GNU-only constructs such as the
  `addr,+N` address form. Anything interpolated into a `sed` replacement goes through
  `escape_replacement`.
- What the hook writes, backs up (`CLAUDE.md.bak`), and leaves alone (`AGENTS.md`) is
  documented for consumers in the `README.md` "Session start hook" section. Changing that
  behavior means updating the section in the same commit.

## Versioning

`plugins/rage-agent-kit/.claude-plugin/plugin.json` and the matching plugin entry in
`.claude-plugin/marketplace.json` both carry a `version` field. These must always match —
bumping one without the other is a broken release, since the version is the only update
signal consumers get. Bump on any change to `plugins/rage-agent-kit/**`.

## Validating changes

Run before every commit that touches `plugins/` or `.claude-plugin/`:

```bash
claude plugin validate .
```

## Session efficiency

When Claude Code is proposing or reviewing changes in this repo:

- Batch edits to the same file rather than alternating read → edit → read → edit across
  separate turns; read a file once, plan the full set of changes, then apply them.
- When showing a change for review before applying it, show a line-level diff (a ```diff
  block or the specific before/after lines) instead of pasting the whole file. Full-file
  reads are still fine for understanding a file — this is about what gets *shown back*.

## Committing changes

**Always ask before committing.** Do not commit silently. Show the diff first and wait
for explicit approval before running `git commit`. The only exception is when the user
has already given explicit commit instructions in this session.

## Scope

This marketplace is for people changing `rage-rb/rage` source. Do not add skills, docs, or
conventions aimed at people building applications on top of Rage — that's the separate
`rage-rb/skills` marketplace.
