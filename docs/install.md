# Installing kosmo-sdlc on coding agents

**Repo:** [https://github.com/Ivlad003/kosmo-sdlc](https://github.com/Ivlad003/kosmo-sdlc)

kosmo-sdlc is a **skill + command pack**: gated SDLC workflows under `commands/`, agent prompts under `agents/`, and Agent Skills under `skills/`. Different coding agents load these paths in different ways. This guide covers the main harnesses.

After install, run once per **host project**:

```text
/kosmo-sdlc:init
/kosmo-sdlc:discover-agents
```

---

## Support matrix

| Agent | Install style | Commands (`/kosmo-sdlc:*`) | Skills | Notes |
| --- | --- | --- | --- | --- |
| **Claude Code** | Plugin marketplace | Native slash | Native skills | First-class |
| **Codex** | Local plugin + marketplace.json | Via `kosmo-sdlc` skill adapter | `skills/` | First-class |
| **Grok CLI** | Clone + skills / project skills | Via skill adapter / docs | `skills/` or `.agents/skills` | Use invent + commands as source of truth |
| **Cursor** | Clone + Project Rules / skills | Manual / rules point at docs | `.cursor/skills` or Agent Skills | Commands as markdown playbooks |
| **Windsurf** | Clone + Cascade rules / skills | Playbooks | project skills dir | Same pattern as Cursor |
| **Amp** | skills.sh or copy `skills/` | Optional | Amp skills dir | Pair with `commands/` as runbooks |
| **OpenCode** | Clone + skills path | Playbooks | agent skills | |
| **Aider** | Clone; point CONVENTIONS / readme | N/A (chat) | Optional | Agent reads `docs/cycle.md` + track files |
| **GitHub Copilot Chat / CLI** | Clone; repo instructions | N/A | Optional | Use `AGENTS.md` / `.github/copilot-instructions.md` |
| **Generic Agent Skills** | `npx skills` or symlink `skills/` | Via harness | Standard | [skills.sh](https://skills.sh) compatible layout |

**Harness-neutral core:** `_/sdlc-config.md`, `_/tracks/*.md`, `schemas/*`, `docs/*`. Any agent that can read markdown and run shell can follow the cycle even without slash commands.

---

## 1. Claude Code (recommended)

```text
/plugin marketplace add Ivlad003/kosmo-sdlc
/plugin install kosmo-sdlc
```

Update:

```text
/plugin update kosmo-sdlc
```

### Manual Claude Code (no marketplace)

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc

# Option A — local marketplace entry (Claude Code plugins)
# Point marketplace at the clone, then /plugin install kosmo-sdlc

# Option B — symlink commands + skills + agents
SDLC_HOME=~/plugins/kosmo-sdlc
mkdir -p ~/.claude/commands ~/.claude/skills ~/.claude/agents
for f in "$SDLC_HOME"/commands/*.md; do
  ln -sf "$f" ~/.claude/commands/"$(basename "$f")"
done
for d in "$SDLC_HOME"/skills/*/; do
  name=$(basename "$d")
  ln -sfn "$d" ~/.claude/skills/"$name"
done
for f in "$SDLC_HOME"/agents/*.md; do
  ln -sf "$f" ~/.claude/agents/"$(basename "$f")"
done
```

On Windows (PowerShell, developer mode or admin for symlinks):

```powershell
$home = $env:USERPROFILE
$src = "$home\plugins\kosmo-sdlc"
git clone https://github.com/Ivlad003/kosmo-sdlc.git $src
New-Item -ItemType Directory -Force ~/.claude/commands, ~/.claude/skills, ~/.claude/agents | Out-Null
Get-ChildItem "$src\commands\*.md" | ForEach-Object {
  New-Item -ItemType SymbolicLink -Force -Path "$home\.claude\commands\$($_.Name)" -Target $_.FullName
}
Get-ChildItem "$src\skills" -Directory | ForEach-Object {
  New-Item -ItemType SymbolicLink -Force -Path "$home\.claude\skills\$($_.Name)" -Target $_.FullName
}
Get-ChildItem "$src\agents\*.md" | ForEach-Object {
  New-Item -ItemType SymbolicLink -Force -Path "$home\.claude\agents\$($_.Name)" -Target $_.FullName
}
```

---

## 2. OpenAI Codex

```bash
mkdir -p ~/plugins ~/.agents/plugins
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
```

Create or merge `~/.agents/plugins/marketplace.json`:

```json
{
  "name": "personal",
  "interface": {
    "displayName": "Personal"
  },
  "plugins": [
    {
      "name": "kosmo-sdlc",
      "source": {
        "source": "local",
        "path": "./plugins/kosmo-sdlc"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Engineering"
    }
  ]
}
```

Install via Codex plugin UI, or open (macOS path example):

```
codex://plugins/kosmo-sdlc?marketplacePath=/Users/<you>/.agents/plugins/marketplace.json
```

On Windows, use your user profile path for `marketplacePath`.

**Usage:** ask Codex to “run kosmo-sdlc intake for PROJ-123” — the `skills/kosmo-sdlc` adapter maps wording to `commands/*.md`.

---

## 3. Grok CLI

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
```

**Project-level (recommended for one app):**

```bash
# from your application repo
mkdir -p .agents/skills .grok/skills
# symlink or copy skills
cp -R ~/plugins/kosmo-sdlc/skills/* .agents/skills/
# optional: also expose under .grok/skills if your Grok build reads that path
cp -R ~/plugins/kosmo-sdlc/skills/* .grok/skills/ 2>/dev/null || true
```

**Or skills.sh:**

```bash
# From app repo — install individual skills from a path if supported,
# or copy the skills tree as above.
npx skills@latest add ./path-to-kosmo-sdlc   # if/when skills.sh supports local path
```

**How to run the cycle in Grok:**

1. Open the host project in Grok.
2. Say: “Follow `~/plugins/kosmo-sdlc/commands/init.md`” or “Use the kosmo-sdlc skill and run init”.
3. Prefer: “Run `/kosmo-sdlc:cycle PROJ-123` using the kosmo-sdlc command docs”.

Slash commands may not register unless your Grok build maps plugin commands; **command markdown files are always the source of truth**.

---

## 4. Cursor

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
cd your-app
```

**Skills (Cursor Agent Skills / project skills):**

```bash
mkdir -p .cursor/skills
cp -R ~/plugins/kosmo-sdlc/skills/* .cursor/skills/
# or symlink
```

**Project rule (optional)** — `.cursor/rules/kosmo-sdlc.mdc` or Project Rules:

```markdown
# kosmo-sdlc
When the user asks for ticket/PR workflow, follow:
- ~/plugins/kosmo-sdlc/docs/cycle.md
- Commands under ~/plugins/kosmo-sdlc/commands/
- Track contract: _/tracks/<TICKET>.md
Default planning: grill-me skill (not brainstorm).
```

**Usage:** “Run kosmo-sdlc intake for PROJ-123 per the command file”.

---

## 5. Windsurf / Cascade

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
```

- Copy `skills/*` into the project skills directory Windsurf uses (often `.windsurf/skills` or workspace skills — check current Windsurf docs).
- Add a Cascade rule pointing at `docs/cycle.md` and `commands/`.
- Same track/config contract as other agents (`_/sdlc-config.md`, `_/tracks/`).

---

## 6. Amp

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
cp -R ~/plugins/kosmo-sdlc/skills/* ~/.config/amp/skills/
# or project-local skills path per Amp docs
```

Pair with reading `commands/*.md` for phase workflows. For autonomous PRD loops, prefer **`kosmo-ralph`** (skill id does not clash with snarktank `ralph`).

---

## 7. OpenCode / other Agent-Skills harnesses

Any harness that implements the [Agent Skills](https://skills.sh) layout:

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
# Point the harness skills root at:
#   ~/plugins/kosmo-sdlc/skills
# or copy into the project's skills directory
```

Then invoke by skill name: `kosmo-sdlc`, `grill-me`, `kosmo-ralph`, `session-close`, `ai-judge`, …

---

## 8. Aider

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
cd your-app
```

Add to `CONVENTIONS.md` or `.aider.conf.yml` read list:

```text
Read and follow ~/plugins/kosmo-sdlc/docs/cycle.md when implementing tickets.
Persist state in _/tracks/<TICKET>.md and _/sdlc-config.md per docs/track-format.md.
```

Aider does not run Claude-style sub-agents; run **one phase per chat**, validate gates yourself (`npm test`, Playwright, etc.).

---

## 9. GitHub Copilot (Chat / CLI / coding agent)

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
```

In the **host application** repo, add `.github/copilot-instructions.md` (or `AGENTS.md`):

```markdown
## kosmo-sdlc
Ticket-to-PR workflow lives at https://github.com/Ivlad003/kosmo-sdlc.
- Init: follow commands/init.md → _/sdlc-config.md
- Per ticket: _/tracks/<TICKET>.md (see docs/track-format.md)
- Phases: intake → implement → validate → review → pr → revalidate
- Planning: use grill-me style (one question at a time), not freeform brainstorm
```

For **Copilot CLI**, open the app repo and attach or `@` the kosmo-sdlc docs paths.

---

## 10. skills.sh bulk helpers

From a host project (when you want skills without full plugin commands):

```bash
# Clone once
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc

# Copy skills into the project (Agent Skills convention)
mkdir -p .agents/skills
cp -R ~/plugins/kosmo-sdlc/skills/* .agents/skills/
```

Or use `npx skills@latest` if/when publishing this package to skills.sh; until then, clone + copy is the portable path.

**Discover peer CLIs for ai-judge** (any OS with bash/PowerShell):

```bash
# Unix
bash ~/plugins/kosmo-sdlc/scripts/discover-coding-agents.sh _ .

# Windows
powershell -File ~/plugins/kosmo-sdlc/scripts/discover-coding-agents.ps1 -ProjectRoot .
```

---

## After install — first project

```text
1. Open the application repository (not only the plugin clone)
2. /kosmo-sdlc:init                 # or: follow commands/init.md
3. /kosmo-sdlc:discover-agents      # or: run scripts/discover-coding-agents.*
4. /grill-me                        # default planning
5. /kosmo-sdlc:cycle PROJ-123       # or step through commands/*
6. /kosmo-sdlc:session-close        # optional Obsidian vault write
```

### Config snippets worth setting

```yaml
# _/sdlc-config.md (excerpt)
session:
  max_tokens: 200000
  vault:
    path: null  # path to clone of https://github.com/Ivlad003/obsidian-personal
    work_root: Work
judge:
  peers: null   # null = use _/coding-agents.json
  exclude_host: true
```

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Slash commands not found | Plugin not installed, or harness has no slash support — open `commands/<phase>.md` and follow manually |
| Skills not listed | Skills path wrong; copy/symlink into the harness’s skills root |
| Judge finds 0 peers | Install another CLI (`claude`, `codex`, `grok`, …) and re-run discover-agents |
| Codex can’t find plugin | Check `marketplace.json` path and `source.path` relative to `~/.agents/plugins` |
| Windows symlink fails | Run PowerShell as admin, enable Developer Mode, or **copy** instead of symlink |

---

## Updating

```bash
cd ~/plugins/kosmo-sdlc   # or your clone path
git pull
# Claude marketplace:
#   /plugin update kosmo-sdlc
# Symlink installs update automatically; copy installs need re-copy of skills/
```

## See also

- [README.md](../README.md) — product overview  
- [docs/cycle.md](cycle.md) — phases and gates  
- [docs/adapting.md](adapting.md) — project shape variations  
- [skills/README.md](../skills/README.md) — skill inventory  
