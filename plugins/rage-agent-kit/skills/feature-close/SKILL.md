---
name: feature:close
description: Phase 9 — close a feature once all its tasks are done and merged.
argument-hint: <feature-name>
disable-model-invocation: true
---

# Close the feature

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so at the
gate and still follow the rule that matters most: **end this phase by stopping** —
artifact, line-level diff, status changes listed, then stop.

Target: `$ARGUMENTS`, resolved as the conventions' Target section describes.

## Read scope

The feature spec's frontmatter and its Tasks, Non-goals, Acceptance criteria, Decisions, and
References sections; the frontmatter of every task and ADR in the feature; the Acceptance
criteria section of every task — the one place a phase reads more than one task, because
feature-level criteria are proven through their tasks' criteria; the feature's accepted ADRs;
the component document named by `component:`; and the merged changes, diff first
(`git -C <checkout> show <merge commit>`), with the code as it is on the default branch
(`git -C <checkout> show <default branch>:<path>`), not the working tree.

## Steps

1. **Check the tasks.** Every task in the Tasks list must be `done` and ticked. If one is not,
   stop and name it, with `/rage-agent-kit:task:close` as the next command for it.

2. **Check the ADRs.** Every ADR must be `accepted` or `superseded`, and linked from the
   feature spec's Decisions section. A `proposed` ADR means a task was closed without checking
   it — stop and name it.

3. **Check the feature-level acceptance criteria**, if the feature spec has any. Tick a
   criterion only when at least one task criterion names it (`AC-NN` after its tag) and every
   task criterion that names it is ticked. A feature-level criterion that no task criterion
   names is not proven: leave it unticked. Name every criterion left unticked, and why.

4. **Check that the work is merged.** Nothing in these documents records it. Ask the engineer
   for the PR of each task — or find its merge commit with
   `gh pr view <number> --json mergeCommit` if `gh` is available — and check that each merge
   commit is on the default branch:

   ```bash
   git -C <checkout> merge-base --is-ancestor <merge commit> <default branch>
   ```

   If one is not — the work is not merged, or the local copy is behind — stop and say so. Add
   the PR links to the feature spec's References.

5. **Update the component document** named by `component:` — only when steps 1–4 pass. If the
   feature spec has no `component:`, or the document does not exist or has no `synced` value,
   stop and say so. Describe the code as it is on the default branch after the merge, not the
   plan:

   - **How it works** and **Public surface** — patch the parts this feature changed, with
     pointers into the code (classes, methods, files).
   - **Invariants** — add the rules this feature introduced, in the form the conventions give;
     update any rule an ADR of this feature changed.
   - **Features** — add this feature's line.
   - **Decisions** — one line per accepted ADR of this feature.
   - **Known gaps** — what the feature deliberately left out (its Non-goals), and any
     criterion left unticked.

   Then run the freshness check (see the conventions). If it lists only commits that came in
   with this feature's PRs, set `synced` to the default-branch commit you checked against. If
   it lists other commits too, leave `synced` as it is, say so, and name
   `/rage-agent-kit:component:sync` — do not describe other people's changes here.

6. **Close the feature spec.** Set it `done` only when the checks in steps 1–4 pass and the
   component document is updated. Otherwise leave it `implementation` and say exactly what is
   still missing.

7. **Gate.** Show the feature spec and component document changes as line-level diffs, list
   the status change, and name the default-branch commit you checked against, with its date.
   The `rage-feature-specs/` changes are still uncommitted — committing them is the engineer's
   step. Then stop.

## Do not

- Do not change code.
- Do not write or accept ADRs, and do not reopen or edit tasks — send those back to
  `/rage-agent-kit:task:close`.
