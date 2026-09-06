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
# a place for manual edits; project-specific rules belong elsewhere. A
# pre-existing CLAUDE.md that this plugin did not write is copied to
# CLAUDE.md.bak once, before the first overwrite.
#
# An AGENTS.md, if present, is left completely alone — this hook only ever
# touches CLAUDE.md.
#
# Portability: POSIX sh and POSIX sed only. GNU-only sed constructs (such as
# the `addr,+N` address form) break on the BSD sed shipped with macOS.
#
# Runs with `set -e` inside main() so any unexpected failure is caught and
# reported to stderr without ever failing session startup (always exit 0).

MARKER='Managed by the rage-agent-kit Claude Code plugin'

# Escape a value for use as the replacement text of a sed `s#...#...#`
# expression: backslash, ampersand, and the `#` delimiter are all special
# there and would otherwise corrupt the output.
escape_replacement() {
  printf '%s' "$1" | sed -e 's/[\\&#]/\\&/g'
}

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
    # Both layouts substitute a real sentence, so there is one code path and
    # the generated file always states where the checkout root is.
    note="The Rage framework checkout is this directory; paths below are relative to it."
  else
    prefix="$checkout/"
    note="The Rage framework checkout is \`./$checkout\`, not this directory; paths below are relative to it."
  fi

  # Preserve a hand-written CLAUDE.md the first time this plugin overwrites
  # one. The marker is only present in files this hook generated.
  if [ -f "CLAUDE.md" ] && [ ! -f "CLAUDE.md.bak" ] &&
     ! grep -qF "$MARKER" "CLAUDE.md"; then
    cp "CLAUDE.md" "CLAUDE.md.bak"
    echo "sync-claude-md.sh: existing CLAUDE.md was not plugin-managed; saved a copy to CLAUDE.md.bak" >&2
  fi

  # Render to a temp file in the same directory and rename only on success, so
  # a sed failure can never leave a truncated or half-written CLAUDE.md.
  tmp="./CLAUDE.md.$$.tmp"
  if sed \
    -e "s#{{RAGE_ROOT_NOTE}}#$(escape_replacement "$note")#" \
    -e "s#{{RAGE_ROOT}}#$(escape_replacement "$prefix")#g" \
    "$template" > "$tmp"; then
    mv "$tmp" "CLAUDE.md"
  else
    rm -f "$tmp"
    return 1
  fi
}

if ! main; then
  echo "sync-claude-md.sh: unexpected error, skipping" >&2
fi

exit 0
