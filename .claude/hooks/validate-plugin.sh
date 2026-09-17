#!/bin/sh
# PreToolUse hook: stop Claude from running `git commit` while the plugin
# manifest does not validate. Wired up in .claude/settings.json.
#
# The real gate for every commit is .githooks/pre-commit. This hook exists so
# that Claude gets the failure as readable feedback instead of a raw git error.
#
# Exit 0 lets the command run. Exit 2 blocks it and sends stderr back to Claude.
#
# The tool call arrives as JSON on stdin. `jq` is not assumed to be installed,
# so the payload is searched as plain text: a false match only means the
# validation runs when it did not have to, which is harmless.

payload=$(cat)

case "$payload" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

command -v claude >/dev/null 2>&1 || exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Nothing to validate in a checkout without a marketplace manifest.
[ -f .claude-plugin/marketplace.json ] || exit 0

if output=$(claude plugin validate . 2>&1); then
  exit 0
fi

printf '%s\n' "$output" >&2
printf '`claude plugin validate .` failed. Fix the manifest before committing.\n' >&2
exit 2
