---
name: feature:new
description: Phase 1 — classify a new piece of work (feature or bug) and write its feature spec.
argument-hint: [the idea, in a sentence or two]
disable-model-invocation: true
---

# New feature

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, next command named, then stop. Never start the next phase yourself.

The idea is `$ARGUMENTS`. If that is empty, ask for it and stop; do not invent one.

This phase decides **what limits the solution**, not what the solution is. Every sentence you
write in the feature spec should either rule something out or set an order of work. If a
sentence only describes the current system, it belongs in the component document, not the
feature spec.

## Steps

1. **Base the idea on the code.** Read enough of the codebase to know where the change
   goes and what it conflicts with. Invoke the domain skills that match those areas (see the
   conventions). The constraints they name are the raw material of this phase.

   If a component document covers this part of the framework, read it first: it says how the
   component works now and which invariants it keeps. Run the freshness check on it (see the
   conventions); if it lists anything, say so at the gate and name
   `/rage-agent-kit:component:sync`. Do not update the document in this phase.

   Do not propose an approach before this. A feature spec written from the request alone will
   build again something that already exists.

2. **Classify the tier** (`bug`, `single`, `multi` — defined in the conventions). State the
   tier and the reason in one line, first at the gate.

3. **Choose the component** — the lasting part of the framework this work belongs to. Read the
   frontmatter of `rage-feature-specs/components/*.md` and pick one. If none fits, propose a
   new one and name it at the gate: create `components/<component-name>.md` from
   `templates/component.md` with only its frontmatter filled in — `title`, `status: active`,
   and the `code` paths — and leave `synced` empty and the body as the template has it.
   `/rage-agent-kit:component:sync` writes the body from the code. If the work also touches
   other components, name them in the feature spec's References.

4. **Create the feature.** `rage-feature-specs/features/<feature-name>/`, kebab-case and
   descriptive. Write `spec.md` from `rage-feature-specs/templates/feature.md` with status
   `draft`, and `tier:` and `component:` added to the frontmatter. Remove the Decisions section
   only if nothing ends up with an ADR, as the template says.

5. **Fill it in according to the tier.**

   - **`bug`** — Motivation (the bug and how it shows up), References (the issue, if there is
     one), and a Tasks list with one entry, `01-fix`. Write `tasks/01-fix.md` from
     `templates/task.md`: Goal, Context, Requirements, and Acceptance criteria as behaviors
     that can be seen from outside, each tagged `core` or `edge` as the conventions describe —
     the behavior the defect breaks is always `core`. Leave Design empty — a bug has no design
     phase.
   - **`single`** — Motivation, Proposed behavior, Non-goals, and a Tasks list with one entry.
     `task:design` writes the task file.
   - **`multi`** — the full feature spec:
     - **Motivation** — one paragraph: what is true after this ships that is not true now.
     - **Proposed behavior** — the behavior that can be seen from outside and the public API,
       and the constraints this work has to stay within, each with the consequence of breaking
       it. "No new dependencies" is a constraint; "the code uses fibers" is not.
     - **Non-goals**
     - **Acceptance criteria** — feature-level only. `task:design` writes the task-level ones
       and names the `AC-NN` each helps prove.
     - **Tasks** — what ships independently, in order, one linked entry per task. Under each,
       one line on what it leaves the system able to do and where the boundary with the next
       one is. Do **not** design them or create their files; that is `task:design`, and
       designing task 2 before task 1 is built guarantees a rewrite.

6. **Record decisions** as the conventions describe. The approaches you rejected are the most
   valuable record this phase produces, and the easiest to leave without enough detail.

7. **Gate.** Show the tier, the component (and whether it is new or out of date), the task
   list, and a line-level diff of the files created. For a `bug`, also list its acceptance
   criteria grouped into `core` and `edge`. List any open questions — what you could not
   resolve and who resolves it — and say that the next command promotes the feature spec to
   `implementation`, so they should be resolved first. The next command is
   `/rage-agent-kit:component:sync` if this phase created a component document; otherwise
   `/rage-agent-kit:task:design`, or `/rage-agent-kit:task:test-core` for a `bug`. Then stop.

## Do not

- Do not write any code, not even a sketch, and do not change any file in the Rage checkout.
- If you are between two tiers, say which two and why you chose the one you did.
