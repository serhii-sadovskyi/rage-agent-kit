#!/bin/sh
# SessionStart hook: bridge CLAUDE.md and AGENTS.md in a Rage framework checkout.
#
# Only acts when the session's working directory is the root of a Rage
# framework checkout (rage.gemspec present). Never overwrites an existing
# CLAUDE.md (file, directory, or symlink — including a broken one).
#
# Runs with `set -e` inside main() so any unexpected failure is caught and
# reported to stderr without ever failing session startup (always exit 0).

main() {
  set -e

  [ -f "rage.gemspec" ] || return 0

  # -e is false for a dangling symlink, so also check -L to catch one.
  if [ -e "CLAUDE.md" ] || [ -L "CLAUDE.md" ]; then
    return 0
  fi

  if [ -e "AGENTS.md" ] || [ -L "AGENTS.md" ]; then
    ln -s "AGENTS.md" "CLAUDE.md"
    return 0
  fi

  cat > "CLAUDE.md" <<'EOF'
This repo has the rage-agent-kit Claude Code plugin enabled. See its skills
(rage-framework-core, deadlocks, public-api, specs, docs, and others) for
Rage framework conventions.

Consider adding project-specific rules to this file (or an AGENTS.md).
EOF
}

if ! main; then
  echo "bridge-agents-md.sh: unexpected error, skipping" >&2
fi

exit 0
