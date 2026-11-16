#!/usr/bin/env bash
# usage: tick.sh <pr> <owner/repo> <step numbers...>  -- ticks the PR body's QA checkboxes.
# Step N is the box written "N. - [ ]" or "- [ ] N." (any indentation). A body with no numbered
# boxes counts its "- [ ]" / "- [x]" lines from 1 instead. A step that matches no box, or more
# than one, refuses the whole edit (exit 2), so a format this doesn't know can't pass silently.
set -euo pipefail
[ $# -ge 3 ] || { echo "usage: tick.sh <pr> <owner/repo> <step numbers...>"; exit 1; }
pr=$1; repo=$2; shift 2
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "REFUSED: repo must be owner/name, got '$repo'"; exit 1; }
for n in "$@"; do [[ "$n" =~ ^[0-9]+$ ]] || { echo "REFUSED: step must be a number, got '$n'"; exit 1; }; done
[ "$(gh api user --jq .login)" = "cmeans" ] || { echo WRONG IDENTITY; exit 1; }
here=$(dirname "$0")
out=~/.cache/claude-qa/pr-${repo##*/}-$pr-body.md
# pipefail: a refusal from tick_body.py stops the script here, before the edit.
gh pr view "$pr" --repo "$repo" --json body --jq .body | python3 -I "$here/tick_body.py" "$@" > "$out"
gh pr edit "$pr" --repo "$repo" --body-file "$out" >/dev/null
gh pr view "$pr" --repo "$repo" --json body --jq .body | python3 -I "$here/tick_body.py" --list
