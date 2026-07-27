---
name: kosmo-sdlc
description: "Run the kosmo-sdlc ticket-to-PR cycle on any coding agent (Codex, Grok, Cursor, Amp, …). Use when the user asks to init, intake, implement, validate, review, PR, cycle, judge, kosmo-ralph, or session-close."
---

# Kosmo SDLC (multi-harness adapter)

## Purpose

Harness-neutral entry point. **Canonical workflows** live in `commands/*.md` and `agents/*.md` — do not duplicate them here.

Works on **Claude Code** (slash commands), **Codex**, **Grok**, **Cursor**, **Amp**, and any agent that can read markdown and run tools. Install: [docs/install.md](../../docs/install.md).

## Source files

From this skill directory:

| Task | Source |
| --- | --- |
| Router | `../ask-kosmo-sdlc/SKILL.md` |
| Discover peer CLIs | `../discover-agents/SKILL.md` · `../../commands/discover-agents.md` |
| Planning (default) | `../grill-me/SKILL.md` · `../grilling/SKILL.md` |
| AI judge | `../ai-judge/SKILL.md` · `../../commands/judge.md` |
| kosmo-ralph | `../kosmo-ralph/SKILL.md` · `../../commands/kosmo-ralph.md` |
| Session close | `../session-close/SKILL.md` · `../../commands/session-close.md` |
| Init … cycle | `../../commands/{init,intake,implement,validate,review,pr,pr-comments,revalidate,cycle}.md` |
| Commits | `../commit-work/SKILL.md` |
| Phase agents | `../../agents/*.md` |
| Schemas | `../../schemas/*.json` |
| Matt map | `../../docs/mattpocock-skills.md` |
| Install | `../../docs/install.md` |

## Adaptation rules (all non-Claude harnesses)

- Treat `/kosmo-sdlc:…` names as **workflow labels**, not only slash commands.
- Ignore Claude-only frontmatter (`allowed-tools`, `AskUserQuestion`, …); use equivalent tools.
- Preserve `_/sdlc-config.md`, `_/tracks/`, `_/demo/`, `_/recordings/`, `_/kosmo-ralph/`, `_/judge/`.
- Validate frontmatter with the JSON schemas when writing.
- Sub-agents: use harness sub-agents if available; else run the phase in-process per `agents/*.md`.
- Worktrees: optional, **cycle only** — never required for every task.
- Never commit `_/`, credentials, `.env`, or recordings.

## Workflow

1. Map user intent → phase/skill (table below).
2. Planning / brainstorm → **grill-me** (not freeform brainstorm); optional **ai-judge**.
3. Open only the needed command/skill files.
4. Execute with this harness’s tools.
5. Update track + journal; enforce the phase gate.
6. Report the next concrete step.

## Command mapping

| User says | Action |
| --- | --- |
| which skill / what next | `ask-kosmo-sdlc` |
| plan / design / brainstorm / grill me | `grill-me` + `grilling` |
| discover agents | `discover-agents` |
| judge / multi-model review | `ai-judge` + `commands/judge.md` |
| kosmo-ralph / ralf loop | `kosmo-ralph` (not upstream `ralph`) |
| session-close / vault handoff | `session-close` |
| init, intake, implement, validate, review, pr, pr-comments, revalidate, cycle | matching `commands/*.md` |

## Completion

A phase is done only when its command doc’s **gate** passes. On failure: stop, name the gate, give the next exact action.
