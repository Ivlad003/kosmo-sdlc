# Skills shipped with kosmo-sdlc

**Canonical:** `skills/` (this directory)  
**Do not commit:** harness mirrors such as `.agents/skills` (see `.gitignore`)

Install paths for each coding agent: [docs/install.md](../docs/install.md)

## Product path

```text
discover-agents → grill-me → [ai-judge plan] → intake → implement | kosmo-ralph
       → validate → review → pr → session-close
```

| Skill | Invoke | Role |
| --- | --- | --- |
| `discover-agents` | user | Dynamic CLI inventory → `_/coding-agents.md` |
| **`grill-me`** | user | **Default planning** (not brainstorm) |
| `grilling` | model | Interview primitive |
| `ai-judge` | user | Multi-CLI plan/code court |
| `kosmo-ralph` / `kosmo-ralf` | user | snarktank-compatible PRD loop; non-conflicting id |
| `session-close` | user | handoff / session / memory / teach → Obsidian |
| `kosmo-sdlc` | model | Multi-harness adapter over `commands/*` |
| `commit-work` | model | Conventional Commits + pipeline gate |
| `ask-kosmo-sdlc` | user | Router |
| `handoff` | user | Thin handoff; prefers session-close when vault set |
| `grill-with-docs` | user | Grill + CONTEXT.md / ADRs |
| `domain-modeling` | model | Glossary + ADRs |
| `tdd` | user | Red→green at seams |
| `diagnosing-bugs` | user | Hard bugs / flakes |
| `codebase-design` | user | Deep-module vocabulary |
| `writing-great-skills` | user | Meta for skill authors |

Host-only companions: [docs/mattpocock-skills.md](../docs/mattpocock-skills.md)

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/discover-coding-agents.ps1` | Windows CLI inventory |
| `scripts/discover-coding-agents.sh` | Unix CLI inventory |
| `scripts/kosmo-ralph.sh` | Autonomous story loop (`--tool claude\|codex\|grok\|amp`) |

## Contributor notes

- Edit `skills/` only; re-copy to a local harness dir if you test multi-agent installs.
- Do not run `skills add --agent '*'` inside this repo (pollutes tree).
- `grilling` stays close to upstream mattpocock; `grill-me` / `kosmo-ralph` are product-adapted.
