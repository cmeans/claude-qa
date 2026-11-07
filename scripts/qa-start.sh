#!/usr/bin/env bash
# usage: qa-start.sh <pr> <owner/repo>  -- adds QA Active only if the PR's live labels allow a round.
# QA_START_DRY=1 checks without writing. Exit 0 = started, 1 = refused.
set -euo pipefail
[ $# -eq 2 ] || { echo "usage: qa-start.sh <pr> <owner/repo>"; exit 1; }
pr=$1; repo=$2
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "REFUSED: repo must be owner/name, got '$repo'"; exit 1; }
[ "$(gh api user --jq .login)" = "cmeans" ] || { echo "REFUSED: not the cmeans account"; exit 1; }
state=$(gh pr view "$pr" --repo "$repo" --json state,labels,headRefOid,mergeable \
  --jq '"\(.state)|\(.mergeable)|\(.headRefOid[0:7])|" + ([.labels[].name] | join(","))')
IFS='|' read -r st mergeable head labels <<<"$state"
why=""
has() { case ",$labels," in *",$1,"*) return 0;; *) return 1;; esac; }
[ "$st" = OPEN ] || why="state is $st"
has "Ready for QA" || why="${why:+$why; }no Ready for QA"
for l in "Dev Active" "QA Invalidated" "CI Failed" "Merge conflict"; do has "$l" && why="${why:+$why; }$l is on"; done
[ "$mergeable" != CONFLICTING ] || why="${why:+$why; }merge conflict"
[ -z "$why" ] || { echo "REFUSED #$pr at $head: $why [labels: $labels]"; exit 1; }
if [ "${QA_START_DRY:-}" = 1 ]; then echo "WOULD START #$pr at $head [labels: $labels]"; exit 0; fi
gh pr edit "$pr" --repo "$repo" --add-label "QA Active" >/dev/null
echo "STARTED #$pr at $head [was: $labels]"
