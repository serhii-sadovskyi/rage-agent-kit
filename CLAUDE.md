# rage-agent-kit — maintainer notes

This repo is a Claude Code plugin marketplace, not a Rage app or the Rage framework itself.
It ships one plugin, `rage-agent-kit` (`plugins/rage-agent-kit/`), whose skills teach
Claude Code the house rules for contributing to `rage-rb/rage`. See [README.md](README.md)
for the audience and install instructions.

## Editing skills

- Each skill is a single `SKILL.md` under `plugins/rage-agent-kit/skills/<name>/`.
- Frontmatter is `name` and `description`; flow skills also set `argument-hint` and
  `disable-model-invocation`. The description is what Claude matches
  against to decide whether to load the skill, so it must name the trigger conditions —
  which files, which situations — and not only the topic. The knowledge skills all use the
  same shape: topic, the disambiguation clause, then `Use when …` with the triggers. Follow
  it. Matching runs over the whole description, so the order of those parts changes nothing;
  what matters is that the triggers are there and are specific.
- The `description` loads into every session's context whether or not the skill ends up
  firing — it is the one part of a skill that is never free. Keep it as short as the trigger
  conditions allow, and don't restate the same disambiguation clause verbatim across skills;
  reuse a short, consistent phrasing instead — every knowledge skill uses exactly "for core
  work only, not Rage apps". Skill *bodies* only load once triggered, so they can be as detailed as the topic
  needs — the economy pressure applies to the description, not the content.
- Skills come in two kinds, and a new one is always one or the other:
  - **Knowledge** — Rage domain conventions, loaded automatically off the description when
    the files match. `rage-framework-core`, `public-api`, `deadlocks`, `deferred`,
    `request-path`, `specs`.
  - **Flow** — the phases the engineer invokes. Marked `disable-model-invocation: true`, so
    the model never fires one on its own. Their descriptions are short: nothing matches
    against them, so they only need to read well in the invocable list.
- Flow skills are written **generically** — they describe the phase, not Rage — and delegate
  to the knowledge skills for house rules ("load the domain skills matching the areas this
  task touches"). Rage specifics belong in a flow skill only where the *process* itself
  differs because of Rage, and even then the flow skill points to where the fact lives
  instead of copying it: `task:test-core`, `task:test-edge`, and `task:apply-findings` send the
  agent to the `specs` skill for what the default RSpec run leaves out, because otherwise a red
  or green run means something other than what it looks like. `task:review` is the one flow
  skill that carries Rage checklists itself, because its reviewers are subagents and the
  checklist has to be pasted into their prompt; CI keeps its copy of the blocking-I/O list
  equal to the template's. Resist
  anything beyond that — a rule about Rage belongs in a knowledge skill.
- New skills need an entry in the `README.md` "What's included" list; flow skills need a row
  in its command table, which CI enforces.

## Flow skill mechanics

- `plugins/rage-agent-kit/flow/CONVENTIONS.md` is the single source for everything shared
  across phases: the spec-anchored goal, the gate protocol, the `rage-feature-specs/` layout
  and the review report location, the words that mean two things ("feature spec", "task"),
  the Rage checkout and its default branch, how a command resolves its target, the status
  contract, read scope, how phases load domain skills, component documents and their freshness
  check, how decisions are recorded, the tier definitions, the `core`/`edge` split of
  acceptance criteria, the records in Verification, and what counts as evidence for a
  criterion. Every flow skill opens by reading
  it via `${CLAUDE_PLUGIN_ROOT}`, which resolves inside a skill body. Change a shared rule
  there, then check no phase has drifted into restating it.
- That read can be *denied* — it reaches outside the working directory, so a session may
  refuse it — and a denied read would otherwise strip a phase of every rule it has. Each flow
  skill therefore restates its own stop-at-the-gate rule inline as a fallback, and is told to
  report the failed read. That one duplication is deliberate: keep it when editing a phase.
- The document types come from the specs repo (`rage-rb-fans/rage-feature-specs`): its
  `AGENTS.md` and `templates/`, including `templates/component.md`. A change here to the
  sections of a document — for example what `feature:close` writes into a component
  document — needs the matching change to the template there.
- Invocation names come from the frontmatter `name`, not the directory: `name: task:design`
  in `skills/task-design/` produces `/rage-agent-kit:task:design`. **The colon form
  is undocumented.** It is verified working, and a colon-named skill registers *only* under
  the full namespaced name — no bare `/task:design` — which is why it's used: no
  collisions with other plugins. `claude plugin validate` never opens skill files, so CI
  checks the name shape statically. Names follow `<document>:<action>` — `feature:` for
  commands that act on the whole feature, `task:` for one task, `component:` for a component
  document — and the directory is the same name with a hyphen. After a Claude Code upgrade,
  re-check it live:

  ```bash
  claude --plugin-dir ./plugins/rage-agent-kit -p "/rage-agent-kit:feature:status"
  ```

  If it ever breaks, the fallback is a hyphen (`task-design`), which works both
  namespaced and bare — a frontmatter edit per skill plus a README pass, no structural change.
- **Every phase ends by stopping for the engineer.** This is the point of the flow, not a
  formality. A phase that chains into the next has failed even when its output is correct.
  Any edit that makes a phase "helpfully" continue is a bug.

## The session hook and its template

The plugin also ships a `SessionStart` hook under `plugins/rage-agent-kit/hooks/`:
`hooks.json` wires up `scripts/sync-claude-md.sh`, which renders
`scripts/CLAUDE.md.template` into a `CLAUDE.md` in the consumer's Rage checkout at every
session start. Three constraints come with it:

- The template is the single source of truth for the rules every framework session needs —
  the canonical worker-freezing list, when `yardoc` and RSpec may be run, agent process
  rules. Skills reference it ("the canonical list is in `CLAUDE.md`")
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

## Writing docs for people

This is an open source repo, and many readers do not know English at an advanced level.
In `README.md`, `CONTRIBUTING.md`, and any other docs written for people, keep the vocabulary
at about **B2 level**:

- Avoid C1+ words and idioms when a common word says the same thing: "larger", not
  "non-trivial"; "in progress", not "in flight"; "project rules", not "house rules".
- Avoid abstract or figurative framing when a direct statement says the same thing.
- Keep one idea per sentence or paragraph. Long sentences are acceptable; dense ones are not.
- Technical terms the reader needs — fiber, spec, ADR, checkout, backend contract — are fine
  and should not be replaced.
- Simpler wording must keep the exact meaning. Do not drop a detail to make a sentence easier
  to read.

## Versioning

`plugins/rage-agent-kit/.claude-plugin/plugin.json` and the matching plugin entry in
`.claude-plugin/marketplace.json` both carry a `version` field. These must always match —
bumping one without the other is a broken release, since the version is the only update
signal consumers get. Bump on any change to `plugins/rage-agent-kit/**`.

## Validating changes

`claude plugin validate .` runs from a pre-commit hook, not after every edit. Two hooks
cover it, and both only fire when the commit touches `plugins/` or `.claude-plugin/`:

- `.githooks/pre-commit` is the real gate for every commit, by a person or by Claude. It is
  enabled once per clone with `git config core.hooksPath .githooks`, which
  `CONTRIBUTING.md` tells contributors to run. It skips with a warning when `claude` is not
  on `PATH`.
- `.claude/hooks/validate-plugin.sh`, wired up as a `PreToolUse` hook in
  `.claude/settings.json`, stops Claude's own `git commit` and hands back the validator
  output as readable feedback. It searches the tool payload as plain text, because `jq` is
  not always installed.

CI runs the same command, so a bypass with `git commit --no-verify` is caught in the pull
request.

Because these two files must be committed, `.gitignore` ignores `.claude/*` with exceptions
for `settings.json` and `hooks/` instead of ignoring the whole directory.
`.claude/settings.local.json` stays ignored.

## Session efficiency

When Claude Code is proposing or reviewing changes in this repo:

- Batch edits to the same file rather than alternating read → edit → read → edit across
  separate turns; read a file once, plan the full set of changes, then apply them.
- When showing a change for review before applying it, show a line-level diff (a ```diff
  block or the specific before/after lines) instead of pasting the whole file. Full-file
  reads are still fine for understanding a file — this is about what gets *shown back*.

## Review passes

When the task is to review, clean up, consolidate, or optimize, the question for every line is
**"should this exist"**, not only "is this correct". Making a line correct is not an audit of
it. Report lines that should be deleted even when they are correct, and even when they are not
what you were asked to look at.

Three signals mean a line has to justify itself:

- You are editing it only because something else changed — a renamed skill, a deleted file, a
  new phase. That edit *is* its maintenance cost, and you are paying it.
- It repeats something the session already has: a skill description that always loads, another
  document, or the file it links to.
- It is a list that has to grow when the project grows.

Report deletions as proposals with a diff. Do not delete silently. When a passage earns its
length, say so and defend it instead of cutting to look thorough.

## Committing changes

**Always ask before committing.** Do not commit silently. Show the diff first and wait
for explicit approval before running `git commit`. The only exception is when the user
has already given explicit commit instructions in this session.

## Scope

This marketplace is for people changing `rage-rb/rage` source. Do not add skills, docs, or
conventions aimed at people building applications on top of Rage — that's the separate
`rage-rb/skills` marketplace.
