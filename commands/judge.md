---
description: Multi-CLI AI judge — peer agents (claude/codex/grok/copilot) cross-review a plan and/or code diff, rank alternatives, write a verdict. Advisory; does not replace /kosmo-sdlc:review gates.
argument-hint: "[plan|code|both] [ticket-id|path|git-range] [--variants N]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Agent"]
---

# /kosmo-sdlc:judge

Cross-model court for plans and code. Uses **other** coding-agent CLIs than the host session so decisions get independent critique.

Full discipline: [`skills/ai-judge/SKILL.md`](../skills/ai-judge/SKILL.md).

## Arguments

- `$1` (optional): mode — `plan` | `code` | `both`. Default from `judge.default_mode` in `_/sdlc-config.md`, else `plan` if no diff / `code` if on a feature branch with changes.
- `$2` (optional): ticket id, path to a plan/spec, or git range (`main...HEAD`). Default: open track if unique, else `origin/<default>..HEAD` for code mode.
- `--variants N` (optional, plan mode): number of alternatives to generate before judging (default 3).

## Preconditions

1. At least **two** peer CLIs on PATH among `claude`, `codex`, `grok`, `copilot` / `gh` — **or** one peer + explicit user ack to run single-peer judge.
2. `_/` writable (case + verdicts live under `_/judge/`).
3. Prefer green or at least intentional WIP; judge does not require pipeline green.

## Workflow

1. Load `skills/ai-judge/SKILL.md` and follow it end-to-end.
2. Detect host + peers; apply `judge.*` from `_/sdlc-config.md` if present.
3. Build `_/judge/<run-id>/case.md`.
4. Dispatch peers in parallel; store `peer-*.md`.
5. Write `_/judge/<run-id>/verdict.md`; if ticket known, also `_/recordings/<TICKET>.judge.md` and a track journal line.
6. Report ranked recommendation + conditions; ask human to accept before acting.

## Gate

Judge is **advisory**. It does not block `/kosmo-sdlc:cycle` unless the user treats the verdict as binding.  
It does **not** replace:

- `/kosmo-sdlc:review` (in-cycle CRITICAL/HIGH gate)
- pipeline / Playwright validate gates

## Report

```
AI Judge: _/judge/20260727-1530/verdict.md
Mode: plan · host: grok · peers: claude, codex
Recommendation: B (event-sourced) — 2/2 peers preferred over A
Next: confirm with human → /kosmo-sdlc:intake PROJ-123
```
