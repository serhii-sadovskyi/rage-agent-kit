# Flow conventions

Shared rules for every `/rage-agent-kit:` flow command. Read this first: the command says what
to produce, this file says how every phase behaves.

## The goal: the documents lead

Documents lead the work; the code is the final source of truth.

- **In progress:** the feature spec and task files lead — code is written from them, tests from
  their acceptance criteria. A phase that makes the code differ patches the document in the
  same phase, or stops and asks if the difference is bigger than it may decide. No phase ends
  with a document that disagrees with its code.
- **After `done`:** the feature spec and tasks are history — never updated, and not read again
  unless the engineer asks. The component document, the ADRs, and the code stay current.
- **Later changes to finished work** are a new feature (often a `bug`) that links the old one
  under References. Never edit the old feature's files.
- **Maintainers and most contributors never see the specs repo.** Anything they need —
  behavior, why a public API looks as it does, a deprecation — also goes into the code, YARD,
  the changelog, or the PR description.

## The gate

**Every phase ends by stopping for the engineer.** A phase that starts the next one has
failed, even if its output is correct. End with, in order:

1. The artifact, written to disk.
2. A **line-level diff** (a ```diff block or before/after lines). Reading a whole file is fine;
   pasting one back is not.
3. One line: what the next phase does, and the exact command.
4. Stop.

Exceptions: `feature:status` writes nothing — its report is the output. `task:review` shows
its new report instead of a diff.

Approval covers that phase only, never the next one. Approval with changes means revise and
present again — not do more "to be safe". Never spawn agents to run other phases; subagents
inside a phase only where its instructions say so.

## Where the documents live

`rage-feature-specs/` is a git checkout of `rage-rb-fans/rage-feature-specs` in the
**session's working directory**, beside the Rage checkout, never inside it. The flow never
creates or clones it. If the working directory is itself the Rage checkout, the flow cannot
run: say so and stop.

```
rage-feature-specs/
  AGENTS.md                  the repo's rules for agents
  templates/                 feature.md, task.md, adr.md, component.md — every new document starts from one
  components/<name>.md       one per lasting part of the framework: how it works now
  features/<feature-name>/   kebab-case
    spec.md                  the feature spec; frontmatter holds status, tier, component
    tasks/NN-<name>.md       one per task: design, acceptance criteria, verification, result
    adr/NNN-<name>.md        one per significant decision, numbered within the feature
```

A **task** is one task file and one thing that ships.

Words:
- **Feature spec** = `spec.md`. Never write a bare "spec": in Rage, specs are RSpec files, which
  the flow calls **tests**.
- **Task** = a task file. `Rage::Deferred` jobs are always **Deferred tasks**.

`AGENTS.md` and `templates/` define the documents; this file only says how phases use them.
Start every document from its template, keep its sections, and invent none. If `AGENTS.md`
disagrees with this file, `AGENTS.md` wins — say so at the gate.

The repo is shared:
- **Edit files; never commit, push, or branch.** The gate's diff is
  `git -C rage-feature-specs diff` plus new untracked files.
- Patch the section that changed; never regenerate a document.
- Nothing is archived or moved; a finished feature stays in place, marked `done`.

### Review reports

`task:review` saves its report to `.rage-agent-kit/reviews/<feature-name>/NN-<task-name>.md` in
the session's working directory — in neither repo, and never committed. It exists only on that
machine, so what other phases need from it goes into the task's `**Review outcome**` record;
`task:close` and `feature:status` work from that record, and use the report only for detail.

## The Rage checkout

- **`<checkout>`** — the directory with `rage.gemspec`, beside `rage-feature-specs/` (the
  generated `CLAUDE.md` names it). Use `git -C <checkout>`.
- **`<default branch>`** — `main` of the remote that points to `rage-rb/rage`
  (`git -C <checkout> remote -v`; in a fork usually `upstream`, not `origin`). If none does,
  use `origin/main` and say so at the gate.
- **Never fetch.** A phase that uses the default branch names its commit and date at the gate.
- **What a task changed** — everything since the merge base, committed or not, plus new files:

  ```bash
  base="$(git -C <checkout> merge-base HEAD <default branch>)"
  git -C <checkout> diff "$base"
  git -C <checkout> ls-files --others --exclude-standard
  ```

  If the range also holds other work (an earlier, unmerged task), ask where this task starts.

## Target

`task:` commands take `<feature-name> [task]`:

- **No feature** — list the features whose `spec.md` is not `done` (from frontmatter) and ask.
  Never guess.
- **No task** — the first entry in the Tasks list whose file is missing or `todo`.

`feature:new` takes the idea itself; `feature:close` takes `<feature-name>`; `component:sync`
takes `<component-name>`; `feature:status` takes an optional `<feature-name>` and reports every
feature in progress when it is left out. Where a target is needed and missing, list what the
command could act on and ask — never guess.

## Frontmatter and status

Use only these values:

| Document | Frontmatter | Status |
| --- | --- | --- |
| `spec.md` | `title`, `status`, `tier`, `component` | `draft` (under discussion) · `implementation` (agreed) · `done` (merged, criteria verified) |
| task | `status` | `todo` · `done` |
| ADR | `status` | `proposed` · `accepted` · `superseded` |
| component | `title`, `status`, `code`, `synced` | `active` · `retired` (removed from the code) |

`tier` and `component` are the flow's own keys; add no others. Finer state ("designed",
"reviewed") comes from which task sections are filled, the Verification records, and git. Only
`task:close` sets a task `done`; only `feature:close` sets a feature spec `done`.

Never promote a document in the turn that produced it. **Running the next phase is the
approval:** `task:design`, `task:test-core`, and `task:implement` promote a `draft` feature
spec to `implementation` when they start, and say so. Where there is no status to promote,
running the command is the approval. That is why a phase never starts the next one: it would
be approving its own output.

## Read scope

Read only what the phase names — later phases need the context space. Never read a `done`
feature unless asked, another feature's directory, or another task of this feature unless the
phase's read scope names it.

Always in scope: the frontmatter of any `spec.md` or component document, `AGENTS.md`, the
template of a document being written, and the whole component document of the feature in play.

## Domain skills

The knowledge skills hold the project rules, but load on their own only when a file they cover
is edited. A phase that edits no code, or only tests, invokes the ones matching the areas it
works on with the Skill tool.

## Component documents

A **component** is a lasting part of the framework (Deferred, telemetry, Cable — the changelog's
bracket names). Its document, `components/<name>.md` from `templates/component.md`, describes
how it works **now** on the default branch — no plans, no history, no unmerged work.

- Each feature names exactly one component in `component:`; others it touches go in
  References.
- Only three commands write component documents: `feature:new` (creates a new one with
  frontmatter only), `component:sync` (writes the body, and updates it after changes made
  outside the flow), and `feature:close` (updates it after the merge).
- Each invariant gives its reason, and the ADR that set it and the example that guards it,
  where they exist.
- `code` lists the component's paths; `synced` is the Rage commit last checked — no value means
  the body was never written. **The freshness check** — any output means the document may be
  out of date:

  ```bash
  git -C <checkout> log --oneline <synced>..<default branch> -- <code paths>
  ```

Skills hold the rules for changing code; component documents hold what the code does now. If
they disagree on a fact, follow the code and say at the gate which is wrong (a wrong skill is a
plugin bug). If `templates/component.md` is missing, a phase that must write a component
document stops.

## Recording decisions

Record decisions **when they are made**, in that phase — later, the reasoning is gone and an
invented one is worse than none.

- **Significant choice** (one a later reader would reopen: an interface, a storage format, a
  concurrency strategy, a rejected dependency) → an ADR at
  `features/<feature>/adr/NNN-<name>.md` from `templates/adr.md`, status `proposed`, numbered one
  past the highest (three digits, never reused). "Options considered" lists the real options
  and why each lost. Link it from the feature spec's Decisions section; if that section was
  removed, restore it from `templates/feature.md`.
- **Smaller decision** (a rejected alternative, an invariant to respect) → the task's
  Implementation constraints.

`task:close` later checks `proposed` ADRs against what was built and accepts them; no phase
writes an ADR from memory.

## Refuse on inconsistent state

Stop and say so — never improvise missing input — when:

- `rage-feature-specs/` is not in the working directory;
- the feature directory, its `spec.md`, or a document the phase depends on is missing;
- the component document it reads has no `synced` value (name `component:sync`);
- the named task is not in the Tasks list;
- the feature spec is `done` (new work is a new feature; a `draft` spec is promoted, not
  refused);
- the phase's own output already exists (a written Design, a record, a report, a `done` task)
  — ask whether to revise or move on.

Say which document is in which state and what would unblock it.

## Tiers

`feature:new` decides the tier once and records it as `tier:`.

| Tier | When | Commands |
| --- | --- | --- |
| `bug` | One plausible fix, no interface choice | feature:new → task:test-core → task:implement → task:test-edge (may be skipped) → task:review → task:apply-findings → task:close → feature:close |
| `single` | One change that ships in one go | feature:new → task:design → task:test-core → task:implement → task:test-edge → task:review → task:apply-findings → task:close → feature:close |
| `multi` | Several things that ship independently | feature:new → for each task: task:design → … → task:close → after the last merge, feature:close |

When `feature:new` creates a component document, `/rage-agent-kit:component:sync` runs before
the next phase, in every tier.

Every tier has a feature directory and a `spec.md`. A `bug` has one task, `01-fix`, which
`feature:new` writes with an empty Design; later phases work from its Requirements and
criteria.

**A `bug` may skip `task:test-edge`** when every criterion is `core`, the core-test record left
nothing for it, and `task:implement` named no existing example to update. `task:implement` then
names `task:review` next and `task:test-edge` as optional; the engineer chooses. The missing
edge-test record is then not a gap.

Moving up a tier is normal: a `bug` that needs an interface decision becomes `single` — update
`tier`, run `task:design`, and say so at the next gate.

## Core and edge criteria

Every task-level criterion starts with one tag:

- `(core)` — the happy path and the failures that matter most: lost data, a broken public
  contract, a wrong state. For a `bug`, the broken behavior is always `core`.
- `(edge)` — everything else: unusual inputs, rare failures, cleanup.

```
- [ ] (core) Two enqueues with the same idempotency key produce one stored record.
- [ ] (edge, AC-02) A Deferred task whose class no longer exists is skipped and logged.
```

The tag is plain text in the list and stays when the box is ticked. Keep `core` small; if every
criterion is `core`, no choice was made. In a `multi` feature, a task criterion that helps prove
a feature-level criterion (`AC-NN`, itself untagged) names it after its tag.

No phase rewrites another phase's tests, apart from the one mechanical change `task:test-edge`
describes — a test that looks wrong is a finding. Existing examples that check behavior the task
changes on purpose are updated only by `task:test-core` and `task:test-edge`, and only with the
engineer's confirmation.

## Records in Verification

Bold labels at the start of a line inside the task's Verification section (not new sections):

- `**Core tests**` (`task:test-core`) — per `core` criterion: the example and its failure before
  the code; or written but not run here, and why; or left for `task:test-edge`; or not provable
  by a test, and why. Plus the existing examples it changed.
- `**Edge tests**` (`task:test-edge`) — per criterion handled: the example; criteria no test can
  prove, and why; existing examples changed; which examples ran and which did not.
- `**Review outcome**` (`task:apply-findings`) — when the review ran, which reviewers ran (why
  one was skipped), the report path; findings applied / skipped / left for the engineer;
  criteria found unmet and whether each fix was applied; **the final run** — command, result,
  and which task examples did not run.
- `**Closing evidence**` (`task:close`, only when needed) — per criterion ticked on outside
  evidence, what the engineer gave.

Each phase writes only its own record. "none" or "skipped" with a reason is valid; a missing
record means the phase has not run (except a `bug` that skipped `task:test-edge`).
`feature:status` reads the labels to pick the next command; `task:close` ticks criteria from
all records together.

## Evidence for a criterion

A criterion is proven only by:

- **The final run** — a covering example passed in the run the `**Review outcome**` record
  describes. Earlier phase runs do not count (code may have changed since); skipped or pending
  examples did not run.
- **A CI run** — a covering example that could not run in the session (excluded by default, or
  skipped without services) passed in a CI run the engineer names.
- **The engineer's check** — no test can prove it at this level (crash ordering, timing between
  processes), and the engineer says how they checked.

Only the engineer can give the last two, in conversation, and no phase writes them on its own.
