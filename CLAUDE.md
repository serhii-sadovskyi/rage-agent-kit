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
- Skills load automatically; there is no manual invocation step to wire up.
- New skills need an entry in the `README.md` "What's included" list.

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

## Scope

This marketplace is for people changing `rage-rb/rage` source. Do not add skills, docs, or
conventions aimed at people building applications on top of Rage — that's the separate
`rage-rb/skills` marketplace.
