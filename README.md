# claude-qa

QA agent role configuration for [Claude Code](https://claude.ai/code).

## What this is

A `CLAUDE.md` that configures Claude Code as an **independent QA agent** — scoped to code review, manual testing via MCP tools, and filing findings. Boundaries are explicit: no code changes, no PRs, and no commits outside this config repo.

## Usage

```bash
claude --add-dir ~/github.com/cmeans/Claude-QA
```

This loads the QA role alongside your project's own `CLAUDE.md`. Use the alias `claude-qa` if configured.

## Companion

The Developer counterpart is [claude-dev](https://github.com/cmeans/claude-dev) — a separate role for writing code and managing PRs.

---

*Part of the [Awareness](https://github.com/cmeans/mcp-awareness) ecosystem. Copyright (c) 2026 Chris Means.*

## Scripts

`scripts/` holds the helpers `CLAUDE.md` names. Each needs the PR's `owner/repo`, so none assumes a project, and each refuses unless the active `gh` account is the maintainer's.

- `qa-start.sh <pr> <owner/repo>` adds **QA Active** if the PR's live labels allow a round.
- `tick.sh <pr> <owner/repo> <step numbers...>` ticks QA steps in a PR's body.
- `qa-signoff.sh <pr> <sha7> "<audit comment>" <owner/repo>` applies **Ready for QA Signoff** and notifies the maintainer through ntfy. `--test` sends one test message.

The ntfy topic is read from `~/.config/claude-qa/ntfy-topic`, mode 600. It stays out of this repo: anyone with the topic can read the messages, so they hold only the repo name, a PR number and a fixed label.
