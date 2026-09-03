---
name: docs
description: How to edit Rage framework design docs without rewriting them — for rage-rb/rage core work only, not Rage apps. Use when editing files under docs/**/*.md.
---

# Design docs

Read the target file once; do not re-read slices. For a cross-cutting change,
rewrite the whole file in one Write if more than ~4 sections move; otherwise
StrReplace only the changed blocks.

Do not number headings; link by heading id. Do not renumber existing sections.

Put cross-cutting decisions in one Decisions table; other sections point at it
instead of restating.

When adding points, patch in place. Do not regenerate unchanged FAQ, concerns,
or report text. Do not redraw mermaid unless actors or control flow change.
