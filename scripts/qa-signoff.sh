#!/usr/bin/env bash
# usage: qa-signoff.sh <pr> <sha7> "<audit comment>" <owner/repo>  -- final act of a passing round.
#        qa-signoff.sh --test                                -- send one test notification only.
# Checks the live head, labels and CI, posts the audit comment, moves QA Active to
# Ready for QA Signoff, then notifies through ntfy. Exit 0 = done, 1 = refused, nothing changed
# on the label, 3 = labeled, but the notification failed: tell the maintainer.
# Message text is the repo name, PR number and label only: never a PR title, which is untrusted text.
set -euo pipefail
topic_file="$HOME/.config/claude-qa/ntfy-topic"

notify() { # message, click URL
  local topic
  topic=$(cat "$topic_file") || return 1
  curl -fsS --max-time 15 -o /dev/null \
    -H "Title: QA signoff" -H "Priority: high" -H "Tags: white_check_mark" -H "Click: $2" \
    -d "$1" "https://ntfy.sh/$topic"
}

if [ "${1:-}" = "--test" ]; then
  notify "Test from QA: signoff notifications work" "https://github.com/pulls" \
    && echo "test sent" || { echo "NOTIFY FAILED"; exit 3; }
  exit 0
fi

[ $# -eq 4 ] || { echo "usage: qa-signoff.sh <pr> <sha7> \"<audit comment>\" <owner/repo>"; exit 1; }
pr=$1; sha=$2; comment=$3; repo=$4
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "REFUSED: repo must be owner/name, got '$repo'"; exit 1; }
[ "$(gh api user --jq .login)" = "cmeans" ] || { echo "REFUSED: not the cmeans account"; exit 1; }

state=$(gh pr view "$pr" --repo "$repo" --json state,headRefOid,mergeable,labels \
  --jq '"\(.state)|\(.mergeable)|\(.headRefOid[0:7])|" + ([.labels[].name] | join(","))')
IFS='|' read -r st mergeable head labels <<<"$state"
has() { case ",$labels," in *",$1,"*) return 0;; *) return 1;; esac; }
why=""
[ "$st" = OPEN ] || why="state is $st"
[ "$head" = "$sha" ] || why="${why:+$why; }head is $head, not $sha"
has "QA Active" || why="${why:+$why; }no QA Active"
for l in "Dev Active" "QA Invalidated" "CI Failed" "Merge conflict"; do
  if has "$l"; then why="${why:+$why; }$l is on"; fi
done
[ "$mergeable" != CONFLICTING ] || why="${why:+$why; }merge conflict"
bad=$(gh pr checks "$pr" --repo "$repo" | cut -f1,2 | grep -vE '\b(pass|skipping)$' | grep -vE '^(QA Gate|on-label|qa-approved)\s' || true)
[ -z "$bad" ] || why="${why:+$why; }CI not green: $(echo "$bad" | tr '\n' ';')"
[ -z "$why" ] || { echo "REFUSED #$pr at $head: $why [labels: $labels]"; exit 1; }

gh pr comment "$pr" --repo "$repo" --body "$comment" >/dev/null

# The comment took a moment: last look at the head and QA Active, then the label.
[ "$(gh api user --jq .login)" = "cmeans" ] || { echo "REFUSED: not the cmeans account"; exit 1; }
again=$(gh pr view "$pr" --repo "$repo" --json headRefOid,labels \
  --jq '.headRefOid[0:7] + "|" + ([.labels[].name] | join(","))')
case "$again" in
  "$sha|"*QA\ Active*) ;;
  *) echo "REFUSED before the label: $again (the audit comment is already posted)"; exit 1;;
esac
gh pr edit "$pr" --repo "$repo" --remove-label "QA Active" --add-label "Ready for QA Signoff" >/dev/null
echo "LABELED #$pr at $sha"

if notify "${repo##*/} #$pr Ready for QA Signoff" "https://github.com/$repo/pull/$pr"; then
  echo "notified"
else
  echo "NOTIFY FAILED for #$pr: tell the maintainer directly"; exit 3
fi
