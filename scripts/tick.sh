#!/usr/bin/env bash
# usage: tick.sh <pr> <owner/repo> <step numbers...>  -- ticks "N. - [ ]" checkboxes in the PR body
set -euo pipefail
[ $# -ge 3 ] || { echo "usage: tick.sh <pr> <owner/repo> <step numbers...>"; exit 1; }
pr=$1; repo=$2; shift 2
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "REFUSED: repo must be owner/name, got '$repo'"; exit 1; }
[ "$(gh api user --jq .login)" = "cmeans" ] || { echo WRONG IDENTITY; exit 1; }
body=$(gh pr view "$pr" --repo "$repo" --json body --jq .body)
for n in "$@"; do body=$(printf '%s' "$body" | sed -E "s/^${n}\. - \[ \]/${n}. - [x]/"); done
printf '%s' "$body" > ~/.cache/claude-qa/pr-${repo##*/}-$pr-body.md
gh pr edit "$pr" --repo "$repo" --body-file ~/.cache/claude-qa/pr-${repo##*/}-$pr-body.md >/dev/null
gh pr view "$pr" --repo "$repo" --json body --jq .body | grep -E '^[0-9]+\. - \[' | cut -c1-12
