---
name: kosmo-sdlc
description: Use when the user asks Codex to run, continue, initialize, validate, review, or create a PR through the kosmo-sdlc ticket-to-PR cycle.
---

# Kosmo SDLC

## Purpose

This is the Codex adapter for the existing kosmo-sdlc plugin. Keep the Claude Code command and agent documents as the source of truth; do not duplicate their workflows into this skill.

## Source Files

From this skill directory, resolve the canonical workflow files at:

| Task | Source |
| --- | --- |
| Which skill/phase? | `../ask-kosmo-sdlc/SKILL.md` |
| Discover peer CLIs | `../discover-agents/SKILL.md` + `../../commands/discover-agents.md` |
| **Planning (default)** | `../grill-me/SKILL.md` + `../grilling/SKILL.md` |
| Multi-CLI AI judge | `../ai-judge/SKILL.md` + `../../commands/judge.md` |
| kosmo-ralph loop (snarktank fork) | `../kosmo-ralph/SKILL.md` + `../../commands/kosmo-ralph.md` |
| Session close в†’ Obsidian | `../session-close/SKILL.md` + `../../commands/session-close.md` |
| Initialize project config | `../../commands/init.md` |
| Build a ticket track | `../../commands/intake.md` |
| Implement requirements | `../../commands/implement.md` |
| Validate with Playwright/demo artifacts | `../../commands/validate.md` |
| Run code/security/standards review | `../../commands/review.md` |
| Create PR | `../../commands/pr.md` |
| Address PR comments | `../../commands/pr-comments.md` |
| Revalidate | `../../commands/revalidate.md` |
| Run the whole loop | `../../commands/cycle.md` |
| Commits inside the cycle | `../commit-work/SKILL.md` |
| Phase agent guidance | `../../agents/*.md` |
| Data contracts | `../../schemas/*.json` |
| Artifact templates | `../../templates/*.template.*` |
| Matt skill map | `../../docs/mattpocock-skills.md` |

## Codex Adaptation Rules

- Treat Claude slash command names as user-facing workflow names, not as commands Codex can execute directly.
- Ignore Claude-only frontmatter such as `allowed-tools`, `argument-hint`, `Agent`, `AskUserQuestion`, `WebFetch`, `Read`, `Write`, `Edit`, `Glob`, and `Grep`; use the equivalent Codex tools and normal conversation instead.
- Preserve the track-file contract: read and write `_/sdlc-config.md`, `_/tracks/<TICKET>.md`, `_/recordings/`, and `_/demo/` exactly as the command docs specify.
- Use `schemas/track.schema.json` and `schemas/sdlc-config.schema.json` whenever writing or validating structured frontmatter.
- When a command doc dispatches Claude sub-agents, translate that to Codex execution: use available sub-agent tooling if present; otherwise perform the phase directly while following the corresponding `agents/*.md` instructions.
- Keep generated working artifacts under `_/` unless the source workflow explicitly says to edit project files.
- Never commit files under `_/`, real credentials, `.env` files, validation recordings, or other local-only artifacts.

## Workflow

1. Identify the requested phase from the user's wording.
2. If the user is planning, designing, brainstorming, or shaping a freeform idea вЂ” **`grill-me` is the default** (never open-ended brainstorm). Optional **`ai-judge`** after shared understanding for multi-CLI ranking. Then intake.
3. Open only the matching source file(s) from the table above, plus any linked schema/template needed for that phase.
4. Follow the source workflow with Codex-native tools.
5. Update the track and journal as specified by the source workflow.
6. Run the phase gate before claiming success.
7. Report the next concrete kosmo-sdlc command or phase.

## Command Mapping

Users may still say the Claude-style names. Interpret them as:

| User says | Codex action |
| --- | --- |
| "which skill", "what next", `/ask-kosmo-sdlc` | Follow `../ask-kosmo-sdlc/SKILL.md` |
| `/grill-me`, "plan", "design", "brainstorm", "grill me" | **Default planning:** `../grill-me/SKILL.md` + `../grilling/SKILL.md` |
| `/kosmo-sdlc:discover-agents` | `../discover-agents/SKILL.md` |
| `/kosmo-sdlc:judge`, "ai judge", multi-model review | `../ai-judge/SKILL.md` + `../../commands/judge.md` |
| `/kosmo-sdlc:kosmo-ralph`, kosmo-ralph, kosmo-ralf | `../kosmo-ralph/SKILL.md` + `../../commands/kosmo-ralph.md` (not upstream `/ralph`) |
| `/kosmo-sdlc:session-close`, handoff to vault | `../session-close/SKILL.md` + `../../commands/session-close.md` |
| `/kosmo-sdlc:init` | Follow `../../commands/init.md` |
| `/kosmo-sdlc:intake` | Follow `../../commands/intake.md` |
| `/kosmo-sdlc:implement` | Follow `../../commands/implement.md` only вЂ” never a generic implement skill |
| `/kosmo-sdlc:validate` | Follow `../../commands/validate.md` |
| `/kosmo-sdlc:review` | Follow `../../commands/review.md` only вЂ” never a generic code-review skill |
| `/kosmo-sdlc:pr` | Follow `../../commands/pr.md` |
| `/kosmo-sdlc:pr-comments` | Follow `../../commands/pr-comments.md` |
| `/kosmo-sdlc:revalidate` | Follow `../../commands/revalidate.md` |
| `/kosmo-sdlc:cycle` | Follow `../../commands/cycle.md` |

## Completion Standard

A phase is complete only when its source document's gate passes. If the gate fails, stop, summarize the failing condition, and give the next exact phase/action to run.
