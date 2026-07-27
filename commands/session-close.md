---
description: Close the agent session — write handoff, session, memory, and teach markdown into Obsidian vault Work/{project}/… and local _/session-close/.
argument-hint: "[--push] [--project name] [focus notes]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /kosmo-sdlc:session-close

Persist session knowledge to the personal Obsidian vault.

Full discipline: [`skills/session-close/SKILL.md`](../skills/session-close/SKILL.md).

## Arguments

- Optional free text: focus for the next session (goes into handoff).
- `--project <name>`: override project folder under `Work/`.
- `--push`: allow git push if config permits (still confirm if first time).

## Workflow

1. Follow `session-close` skill end-to-end.
2. Default remote if unset: `https://github.com/Ivlad003/obsidian-personal`.
3. Layout:

```text
Work/{project}/handoff/{timestamp}.md
Work/{project}/session/{timestamp}.md
Work/{project}/memory/{timestamp}.md
Work/{project}/teach/{timestamp}.md
```

4. Print paths + whether commit/push happened.

## Gate

Files written; redaction check done. Missing vault path → write only to `_/session-close/` and ask for `session.vault.path`.
