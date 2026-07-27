# Skills shipped with kosmo-sdlc

**Canonical:** `skills/` · **Mirror:** `.agents/skills/`

## Product path

```text
discover-agents → grill-me → [ai-judge plan] → intake → implement|kosmo-ralph → validate → review → pr
                                    ↓ limit / end
                            session-close → Obsidian Work/{project}/…
```

| Skill | Invoke | Role |
| --- | --- | --- |
| `discover-agents` | user | Dynamic CLI inventory → `_/coding-agents.md` for judge |
| **`grill-me`** | user | **Default planning** |
| `grilling` | model | Interview primitive |
| `ai-judge` | user | Multi-CLI court (peers from inventory) |
| `kosmo-ralph` / `kosmo-ralf` | user | Fork of [snarktank/ralph](https://github.com/snarktank/ralph) — named to avoid skill-id clash with upstream `ralph` |
| `session-close` | user | handoff/session/memory/teach → Obsidian vault |
| `kosmo-sdlc` | model | Codex adapter |
| `commit-work` | model | Safe commits |
| `ask-kosmo-sdlc` | user | Router |
| `handoff` | user | Thin handoff; prefers session-close when vault set |

## Optional companions

`grill-with-docs`, `domain-modeling`, `tdd`, `diagnosing-bugs`, `codebase-design`, `writing-great-skills` — see [docs/mattpocock-skills.md](../docs/mattpocock-skills.md).

## Scripts

- `scripts/discover-coding-agents.ps1` (Windows)
- `scripts/discover-coding-agents.sh` (Unix)
- `scripts/kosmo-ralph.sh` — multi-tool loop (`--tool claude|codex|grok|amp`)
