---
name: discover-agents
description: "Dynamically discover coding-agent CLIs on this machine and write inventory for AI judge. Use when setting up judge, after installing a CLI, or user asks which agents are available."
disable-model-invocation: true
---

# Discover coding agents

Probe PATH for known coding-agent CLIs and persist an inventory the project (and **ai-judge**) can reuse.

## Output (project memory)

Always write under the host project's `_/` (gitignored):

| File | Purpose |
| --- | --- |
| `_/coding-agents.md` | Human + agent readable inventory (judge peers, versions, recipes) |
| `_/coding-agents.json` | Machine-readable list |

Also mirror a durable copy when the user wants docs in-repo:

- `docs/agents/coding-agents.md` — only if `docs/agents/` exists **or** user asks to commit inventory (usually keep local-only under `_/`).

## How to run

**Preferred — scripts shipped with the plugin:**

```powershell
# Windows
pwsh -File <plugin>/scripts/discover-coding-agents.ps1 -ProjectRoot .
```

```bash
# macOS / Linux
bash <plugin>/scripts/discover-coding-agents.sh _ .
```

From a plugin install path, resolve `scripts/` relative to this skill: `../../scripts/…`.

**Fallback — manual probe** if scripts missing: check `Get-Command` / `command -v` for  
`grok`, `claude`, `codex`, `copilot`, `gemini`, `aider`, `cursor-agent`, `opencode`, `amp`, `qwen`, `gh` (copilot extension).

## Host family

Detect who is driving the session (`grok` | `claude` | `codex` | `cursor` | …) from env / parent process.  
**Judge peers** = available agents whose `family` ≠ host family.

## After discovery

1. Confirm `_/coding-agents.md` lists expected tools.
2. **ai-judge** must **read this file first** (or the JSON) instead of hard-coded peer lists.
3. Optional: set in `_/sdlc-config.md`:

```yaml
judge:
  peers: null   # null = use _/coding-agents.json judge_peers
  exclude_host: true
```

4. Tell the user which peers will judge them on this machine.

## Completion criterion

- [ ] `_/coding-agents.md` and `.json` exist and `discovered_at` is fresh
- [ ] `judge_peers` non-empty when ≥2 families installed; else explicit warning
