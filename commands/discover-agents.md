---
description: Probe PATH for coding-agent CLIs (claude, codex, grok, …) and write _/coding-agents.md + .json for AI judge peer selection.
argument-hint: "[--commit-docs]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob"]
---

# /kosmo-sdlc:discover-agents

Refresh the machine-local coding-agent inventory used by **ai-judge** and **kosmo-ralph**.

## Workflow

1. Resolve plugin `scripts/discover-coding-agents.ps1` (Windows) or `.sh` (Unix) relative to this command file (`../scripts/…`). If missing, follow the manual probe in `skills/discover-agents/SKILL.md`.
2. Run the script with project root = current workspace. Output → `_/coding-agents.md` + `_/coding-agents.json`.
3. Print summary: host_family, available agents, judge_peers.
4. If `--commit-docs`: also write `docs/agents/coding-agents.md` (create dir) — still redact absolute home paths if user prefers privacy (keep versions + ids).
5. If `_/sdlc-config.md` has `judge.peers: null` or missing peers, note that judge will auto-load from the inventory.

## Gate

Inventory files written; at least the probe completed without crash. Zero agents found → warn with install hints, do not fail hard.
