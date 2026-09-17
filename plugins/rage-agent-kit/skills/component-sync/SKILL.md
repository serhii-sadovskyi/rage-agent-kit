---
name: component:sync
description: Write or update a component document from the code on the default branch.
argument-hint: <component-name>
disable-model-invocation: true
---

# Sync a component document

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this command by stopping** —
artifact, line-level diff, then stop. Never start another phase yourself.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes. The list to offer
is the frontmatter of `rage-feature-specs/components/*.md`: the ones that are new (no `synced`
value) or out of date (the freshness check in the conventions lists commits).

This command finds what changed since the document was last checked, and patches the document
to match the code.

## Read scope

The component document; the commits and diffs in the Rage checkout that touch its `code`
paths since its `synced` commit — or, for a new document, the code under those paths; and the
knowledge skills that cover that code (see the conventions). Read the code as it is on
the default branch (`git -C <checkout> show <default branch>:<path>`), not the working tree,
which may hold work that is not merged. Not features, tasks, or ADRs.

## Steps

1. **Find the default branch** as the conventions describe (The Rage checkout). Do not fetch.
   Note its commit and date for the gate.

2. **List what changed** with the freshness check (see the conventions). Nothing listed — say
   the document is up to date and stop. Also check whether the `code` paths still match the
   component: a new file or directory that belongs to it is a change to `code`.

   No `synced` value — the document is new. Describe the component from the code instead
   (step 4), and say so.

3. **Read the changes, diff first.** `git -C <checkout> show <commit>`, or one
   `git -C <checkout> diff <synced>..<default branch> -- <code paths>`; read a whole file only
   when the hunk does not show enough. Describe everything the default branch holds, including
   tasks of features still in progress that are already merged — their `feature:close` later
   patches only what still does not match.

4. **Patch the sections that no longer match the code** — or, for a new document, write each
   one:
   - **Purpose** — for a new document, or when the component's job changed.
   - **How it works** and **Public surface** — what the code does now, with pointers into it.
   - **Invariants** — in the form the conventions give (`git -C <checkout> grep` finds a
     guarding example); check that each guarding example already named still exists. For a new
     document, write only the rules the code clearly keeps; where the reason is not clear from
     the code, its comments, or a knowledge skill, say so instead of inventing one. If a change
     broke an invariant, do not quietly remove it. Name it at the gate: the engineer decides
     whether the rule changed — then update it, and write the reason and the commit that
     changed it on its line — or the code is wrong, which is a new `bug`.
   - **Features** and **Decisions** — this command does not add lines; they come from
     `feature:close`.
   - **Known gaps** — add what the changes left missing or wrong.

   Describe the code, not the commits: the document is about the component, not its history.

5. **Set `synced`** to the default-branch commit you checked against. If the component was
   removed from the code, set `status: retired` and say so.

6. **Gate.** Show the commits you reviewed (for a new document, the paths you read), the
   default-branch commit and its date, a line-level diff of the component document, and
   anything left for the engineer: a broken invariant, a change that looks like a decision
   nobody recorded, a change to `code`. If a feature is waiting for this document, name its
   next command, as `/rage-agent-kit:feature:status` would. Then stop.

## Do not

- Do not edit anything except the component document: not code, not features, not tasks, not
  ADRs.
- Do not write an ADR for a decision made outside the flow. Name it at the gate.
