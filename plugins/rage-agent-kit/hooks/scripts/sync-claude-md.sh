#!/bin/sh
# SessionStart hook: keep CLAUDE.md in sync with this plugin's template in a
# Rage framework checkout.
#
# Acts when the session's working directory either is the root of a Rage
# framework checkout (rage.gemspec present) or contains exactly one immediate
# subdirectory that is one — the common layout where AI-tool files are kept in
# a parent directory so the checkout itself stays clean. The search does not
# recurse deeper than one level, and more than one match is treated as
# ambiguous and left alone.
#
# CLAUDE.md at the working directory is always (re)written from the plugin's
# template — with paths substituted for the detected checkout root — so it
# stays consistent with the plugin version. It is a plugin-managed file, not
# a place for manual edits; project-specific rules belong elsewhere.
#
# An AGENTS.md, if present, is left completely alone — this hook only ever
# touches CLAUDE.md.
#
# Runs with `set -e` inside main() so any unexpected failure is caught and
# reported to stderr without ever failing session startup (always exit 0).

main() {
  set -e

  template="${CLAUDE_PLUGIN_ROOT}/hooks/scripts/CLAUDE.md.template"
  [ -f "$template" ] || return 0

  checkout=""

  if [ -f "rage.gemspec" ]; then
    checkout="."
  else
    # Immediate subdirectories only. An unmatched glob leaves the literal
    # pattern, which fails the -f test like any other non-match.
    for dir in */; do
      [ -f "${dir}rage.gemspec" ] || continue
      if [ -n "$checkout" ]; then
        # More than one candidate: can't tell which is meant, so do nothing.
        return 0
      fi
      checkout="${dir%/}"
    done
  fi

  [ -n "$checkout" ] || return 0

  if [ "$checkout" = "." ]; then
    prefix=""
    note_script="/{{RAGE_ROOT_NOTE}}/,+1d"
  else
    prefix="$checkout/"
    note="The Rage framework checkout is \`./$checkout\`, not this directory; paths below are relative to it."
    note_script="s#{{RAGE_ROOT_NOTE}}#$note#"
  fi

  sed -e "$note_script" -e "s#{{RAGE_ROOT}}#$prefix#g" "$template" > "CLAUDE.md"
}

if ! main; then
  echo "sync-claude-md.sh: unexpected error, skipping" >&2
fi

exit 0
