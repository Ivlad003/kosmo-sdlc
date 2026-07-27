---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up. Prefer session-close when Obsidian vault is configured.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

## Where to save

1. If `_/sdlc-config.md` has `session.vault` configured (or user wants Obsidian) → run **`session-close`** so handoff lands at:

   `Work/{project}/handoff/{timestamp}.md`

   (plus session / memory / teach siblings).

2. Else save under `_/session-close/{timestamp}/handoff.md` in the project (gitignored).

3. OS temp dir only as last resort.

Include a "suggested skills" section (grill-me, ai-judge, kosmo-ralph, kosmo-sdlc phases, …).

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

When **session token/iteration limits** are hit (`session.max_tokens` / kosmo-ralph max_iterations), always prefer full **`session-close`** over a lone handoff.
