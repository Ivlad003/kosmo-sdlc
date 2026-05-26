---
name: agentic-sdlc
description: Use when the user asks Codex to run, continue, initialize, validate, review, or create a PR through the agentic-sdlc ticket-to-PR cycle.
---

# Agentic SDLC

## Purpose

This is the Codex adapter for the existing agentic-sdlc plugin. Keep the Claude Code command and agent documents as the source of truth; do not duplicate their workflows into this skill.

## Source Files

From this skill directory, resolve the canonical workflow files at:

| Task | Source |
| --- | --- |
| Initialize project config | `../../commands/init.md` |
| Build a ticket track | `../../commands/intake.md` |
| Implement requirements | `../../commands/implement.md` |
| Validate with Playwright/demo artifacts | `../../commands/validate.md` |
| Run code/security/standards review | `../../commands/review.md` |
| Create PR | `../../commands/pr.md` |
| Address PR comments | `../../commands/pr-comments.md` |
| Revalidate | `../../commands/revalidate.md` |
| Run the whole loop | `../../commands/cycle.md` |
| Phase agent guidance | `../../agents/*.md` |
| Data contracts | `../../schemas/*.json` |
| Artifact templates | `../../templates/*.template.*` |

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
2. Open only the matching source file(s) from the table above, plus any linked schema/template needed for that phase.
3. Follow the source workflow with Codex-native tools.
4. Update the track and journal as specified by the source workflow.
5. Run the phase gate before claiming success.
6. Report the next concrete agentic-sdlc command or phase.

## Command Mapping

Users may still say the Claude-style names. Interpret them as:

| User says | Codex action |
| --- | --- |
| `/agentic-sdlc:init` | Follow `../../commands/init.md` |
| `/agentic-sdlc:intake` | Follow `../../commands/intake.md` |
| `/agentic-sdlc:implement` | Follow `../../commands/implement.md` |
| `/agentic-sdlc:validate` | Follow `../../commands/validate.md` |
| `/agentic-sdlc:review` | Follow `../../commands/review.md` |
| `/agentic-sdlc:pr` | Follow `../../commands/pr.md` |
| `/agentic-sdlc:pr-comments` | Follow `../../commands/pr-comments.md` |
| `/agentic-sdlc:revalidate` | Follow `../../commands/revalidate.md` |
| `/agentic-sdlc:cycle` | Follow `../../commands/cycle.md` |

## Completion Standard

A phase is complete only when its source document's gate passes. If the gate fails, stop, summarize the failing condition, and give the next exact phase/action to run.
