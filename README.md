# claude-qa

QA agent role configuration for [Claude Code](https://claude.ai/code).

## What this is

A `CLAUDE.md` that configures Claude Code as an **independent QA agent** — scoped to code review, manual testing via MCP tools, and filing findings. Boundaries are explicit: no code changes, no commits, no PRs.

## Usage

```bash
claude --add-dir ~/github.com/cmeans/Claude-QA
```

This loads the QA role alongside your project's own `CLAUDE.md`. Use the alias `claude-qa` if configured.

## Companion

The Developer counterpart is [claude-dev](https://github.com/cmeans/claude-dev) — a separate role for writing code and managing PRs.

---

*Part of the [Awareness](https://github.com/cmeans/mcp-awareness) ecosystem. Copyright (c) 2026 Chris Means.*
