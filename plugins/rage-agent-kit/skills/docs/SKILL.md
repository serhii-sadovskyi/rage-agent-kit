---
name: docs
description: How to edit Rage framework design docs without rewriting them — for rage-rb/rage core work only, not Rage apps. Use when editing files under docs/**/*.md.
---

# Design docs

`docs/` means the checkout root's `docs/` — the directory containing `rage.gemspec` — not
necessarily the session's working directory. The generated `CLAUDE.md` opens by naming the
checkout root; see `rage-framework-core` if that note is absent. Do not target a `docs/`
sitting outside the git checkout.

Read the target file once, then edit in place. Do not regenerate sections that did not
change, and do not re-read slices of a file already read.

Do not number headings; link by heading id. Do not renumber existing sections.

Put cross-cutting decisions in one Decisions table; other sections point at it
instead of restating.

When adding points, patch in place. Do not regenerate unchanged FAQ, concerns,
or report text. Do not redraw mermaid unless actors or control flow change.
