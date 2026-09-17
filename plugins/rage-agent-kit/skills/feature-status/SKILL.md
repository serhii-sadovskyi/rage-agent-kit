---
name: feature:status
description: Report what work is in progress and which command comes next. Writes nothing.
argument-hint: [feature-name]
disable-model-invocation: true
---

# Flow status

Read `${CLAUDE_PLUGIN_ROOT}/flow/CONVENTIONS.md` first. If it cannot be read, say so in the
report.

**This command writes nothing.** It does not create, fix, or clean up documents, it does not
move a status forward, and it does not commit. If it finds the documents inconsistent it
reports that; fixing them is the engineer's decision.

## Steps

1. **Find the features.** If there is no `rage-feature-specs/` in the working directory, say
   so and stop. Otherwise read the frontmatter of every `rage-feature-specs/features/*/spec.md`
   and ignore the `done` ones completely. If none remain, say nothing is in progress and name
   `/rage-agent-kit:feature:new` as the way to start something. Read the frontmatter of the
   component documents the remaining features name.

2. **Read the minimum per feature.** For each feature in progress: the feature spec's Tasks
   list, the frontmatter of its task files and ADRs, and — for the current task only, the
   first whose file is missing or `todo` — which of its sections are filled in beyond the
   template placeholders, which Verification records it holds
   (`rg -n '^\*\*(Core tests|Edge tests|Review outcome|Closing evidence)\*\*' <task>`),
   whether any acceptance criterion is tagged `edge` (`rg -n '^- \[.\] \(edge' <task>`), and
   whether its review report (see Review reports in the conventions) exists and has an
   `## Outcome` heading (`rg -n '^## Outcome' <report>`). **Do not read document bodies
   otherwise** — the report needs state, not content, and reading bodies would make the command
   slow.

3. **Check git in both repositories.** `git -C rage-feature-specs status --short` and
   `git -C rage-feature-specs log --oneline -5 -- features/<feature>` show uncommitted
   document edits and when the feature last changed. In the Rage checkout,
   `git -C <checkout> diff --stat "$(git -C <checkout> merge-base HEAD <default branch>)"` and
   `git -C <checkout> ls-files --others --exclude-standard` show whether code or tests changed,
   committed or not (see The Rage checkout in the conventions). Every feature shares that
   checkout: when more than one feature is in progress, say that the changes cannot be tied to
   one of them. For each component those features name, run the freshness check (see the
   conventions).

4. **Work out the next command for each** from the tier, the statuses, and the above:

   | State | Next |
   | --- | --- |
   | The feature's component document has no `synced` value | `/rage-agent-kit:component:sync` |
   | Task file missing, or its Design empty (`single`/`multi`) | `/rage-agent-kit:task:design` |
   | Design written (or `bug` tier), no core-test record | `/rage-agent-kit:task:test-core` |
   | Core-test record, no code changed outside the tests | `/rage-agent-kit:task:implement` |
   | Code changed, no edge-test record | `/rage-agent-kit:task:test-edge`; for a `bug` with no `edge` criterion, `/rage-agent-kit:task:review` may come first — Tiers in the conventions lists the conditions |
   | Edge-test record (or none needed), no review-outcome record, no review report here | `/rage-agent-kit:task:review` |
   | Review report here without an Outcome, no review-outcome record | `/rage-agent-kit:task:apply-findings` |
   | Review-outcome record, task still `todo` | `/rage-agent-kit:task:close` |
   | Every task `done`, feature spec `implementation` | Merge, then `/rage-agent-kit:feature:close` |

   Decide the test rows from the records, not from git: git shows that test files changed, but
   not whether they hold core or edge tests. A task with no record but with code already
   changed was probably started before the flow had these records — say so instead of sending
   it back to `task:test-core`. Where the state does not decide the answer — a review that ran
   on another machine and was never applied leaves no trace here, for example — say what you
   can tell and what you cannot, instead of guessing.

5. **Report.** One block per feature: name, tier, component, status, current task, and the
   next command. Flag anything inconsistent — a task `done` but unticked in the feature spec's
   Tasks list, a task file the feature spec does not link, a `todo` task under a `done` feature
   spec, a feature spec with no `tier`, a `proposed` ADR on a feature whose tasks are all
   `done`, a task with an edge-test record but no core-test record, a feature spec with no
   `component:` or with a component document that does not exist, and a component document
   that is behind the code (name `/rage-agent-kit:component:sync`).

   If a feature was asked for by name in `$ARGUMENTS`, report only that one, and include its
   task list with per-task status.

End with the single most likely next command. Then stop.
