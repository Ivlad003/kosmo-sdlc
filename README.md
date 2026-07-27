# kosmo-sdlc

> **Ticket → merged PR — with a narrated demo video stakeholders can actually watch.**

A Claude Code / Codex plugin that runs a **gated** development loop: plan → intake → implement → validate → review → PR → revalidate. Every phase has a verifiable gate. The cycle refuses to advance past a broken state.

**Repo:** [github.com/Ivlad003/kosmo-sdlc](https://github.com/Ivlad003/kosmo-sdlc)

```
plan (grill-me) ──► intake ──► implement ──► validate ──► review ──► pr ──► revalidate ──► merge
       │               ▲           ▲              │           ▲        ▲          ▲
       │               └───────────┴── gate ──────┤           └── gate ┴── gate ──┘
       │                                          └─► 🎬 narrated demo.webm
       └─ optional: ai-judge · kosmo-ralph · session-close
```

## Why kosmo-sdlc

| Pillar | What you get |
| --- | --- |
| **Gates, not vibes** | Lint/typecheck/test/build, Playwright assertions, CRITICAL review findings — each transition is checkable |
| **Stakeholder demo** | Passing validate records a narrated `.webm` (only when assertions are green) |
| **Single track file** | `_/tracks/<TICKET>.md` is the contract for every phase |
| **Default planning** | **`grill-me`** before intake — not open-ended brainstorming |
| **Multi-CLI court** | **`ai-judge`** ranks plans/code with peer agents (Claude, Codex, Grok, …) |
| **Autonomous stretches** | **`kosmo-ralph`** — snarktank-style `prd.json` loop without clashing skill id `ralph` |
| **Session memory** | **`session-close`** writes handoff/session/memory/teach into your Obsidian vault |

## The cycle

| # | Command | What it does | Gate |
| --- | --- | --- | --- |
| 0 | `/kosmo-sdlc:init` | One-time setup: detect package manager, scripts, ticketing; optional token budget + vault path | Writes `_/sdlc-config.md` |
| ∗ | `/kosmo-sdlc:discover-agents` | Probe PATH for coding CLIs → `_/coding-agents.md` for judge | Inventory written |
| ∗ | `/grill-me` | **Default planning** — one decision at a time until shared understanding | Human confirms alignment |
| ∗ | `/kosmo-sdlc:judge` | Multi-CLI review of plan and/or code (`plan` \| `code` \| `both`) | Advisory verdict file |
| 1 | `/kosmo-sdlc:intake` | Ticket + spec → track with decomposed requirements + size (S/M/L) | Schema-valid track; ≥1 requirement per AC |
| 2 | `/kosmo-sdlc:implement` | Code + tests per requirement; pipeline per requirement | All requirements `done`; pipeline green |
| ∗ | `/kosmo-sdlc:kosmo-ralph` | Optional autonomous story loop (`convert` / `run`) under `_/kosmo-ralph/` | Stories `passes: true` or budget hit |
| 3 | `/kosmo-sdlc:validate` | Playwright two-pass: assertions → **demo `.webm` only on green** | 0 assertion failures; no new console/4xx–5xx |
| 4 | `/kosmo-sdlc:review` | Parallel code + security + standards → CRITICAL/HIGH/MEDIUM/LOW | No unaddressed CRITICAL |
| 5 | `/kosmo-sdlc:pr` | Push branch, open PR from track frontmatter | Pipeline green; PR URL recorded |
| 5b | `/kosmo-sdlc:pr-comments` | Reply to review threads with verdict prefixes | Threads logged to journal |
| 6 | `/kosmo-sdlc:revalidate` | Re-check post-review; detect spec drift | Still green; hash match or drift ack’d |
| ∗ | `/kosmo-sdlc:cycle` | Orchestrator 1→6 (worktrees **optional**, cycle-only) | Stops at first failed gate |
| ∗ | `/kosmo-sdlc:session-close` | End session → Obsidian `Work/{project}/…` markdown | Files written (no secrets) |

### Size-adaptive rigor

Intake proposes a **size**; you confirm it before the cycle scales down:

| Size | Flow | Verification |
| --- | --- | --- |
| **S** | implement → quality-gate rerun → pr | Project pipeline only (no new e2e / demo / 3-agent review) |
| **M** (default) | full loop | Playwright two-pass + demo + parallel review |
| **L** | mother track + one sub-track **per AC group** | Each sub-track runs its own size-appropriate cycle |

Choosing **S** always needs **explicit** confirmation (even under `--auto`). Missing `size` ⇒ treat as **M**.

### Git worktrees

Worktrees are **not** required for every task. Only `/kosmo-sdlc:cycle` may isolate phases in worktrees. Manual commands and skills (grill-me, judge, kosmo-ralph, …) run in the current workspace. If worktrees are unavailable, the cycle falls back to in-process phases.

## Single source of truth

```text
_/
├── sdlc-config.md              project profile + agent notes
├── coding-agents.md            discovered CLIs (for ai-judge)
├── coding-agents.json
├── tracks/PROJ-123.md          requirements, status, journal
├── kosmo-ralph/                prd.json, progress.txt, prompt.md
├── judge/<run-id>/             case + peer verdicts
├── demo/PROJ-123.spec.mjs
└── recordings/
    ├── PROJ-123.validation.md
    ├── PROJ-123.review.md
    ├── PROJ-123.judge.md
    └── PROJ-123.latest.webm
```

The whole `_/` tree is **gitignored**. Durable output is the PR body (and optional Obsidian vault notes).

## Recommended flow

```bash
# 1. Bootstrap
/kosmo-sdlc:init
/kosmo-sdlc:discover-agents

# 2. Plan (default — not brainstorm)
/grill-me
# optional high-stakes ranking:
/kosmo-sdlc:judge plan

# 3. Ship
/kosmo-sdlc:cycle PROJ-123
# or step-by-step:
/kosmo-sdlc:intake     PROJ-123 path/to/spec.md
/kosmo-sdlc:implement  PROJ-123
/kosmo-sdlc:validate   PROJ-123
/kosmo-sdlc:review     PROJ-123
/kosmo-sdlc:pr         PROJ-123

# 4. Optional autonomous stretch (after convert)
/kosmo-sdlc:kosmo-ralph convert PROJ-123
/kosmo-sdlc:kosmo-ralph run --tool claude --max 15

# 5. Close session → Obsidian (if vault configured)
/kosmo-sdlc:session-close
```

Unsure which skill? **`ask-kosmo-sdlc`**.

## Install

Full multi-agent guide: **[docs/install.md](docs/install.md)**  
(Claude Code · Codex · Grok · Cursor · Windsurf · Amp · OpenCode · Aider · Copilot · skills.sh)

### Claude Code (quick)

```
/plugin marketplace add Ivlad003/kosmo-sdlc
/plugin install kosmo-sdlc
```

```
/plugin update kosmo-sdlc
```

### Codex (quick)

```bash
mkdir -p ~/plugins ~/.agents/plugins
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
```

Register in `~/.agents/plugins/marketplace.json` (see [docs/install.md](docs/install.md#2-openai-codex)), then install via Codex UI.

### Other agents (quick)

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
# Copy or symlink skills/ into your harness skills root, e.g.:
#   .agents/skills  ·  .cursor/skills  ·  ~/.config/amp/skills
# Follow commands/*.md as playbooks when slash commands are unavailable.
```

## Bundled skills (high level)

| Skill | Role |
| --- | --- |
| **grill-me** / grilling | Default planning interview |
| grill-with-docs | Grill + `CONTEXT.md` / ADRs |
| ai-judge | Multi-CLI plan/code court |
| discover-agents | Dynamic peer CLI inventory |
| kosmo-ralph / kosmo-ralf | PRD → `prd.json` + autonomous loop ([snarktank/ralph](https://github.com/snarktank/ralph)-compatible; non-conflicting id) |
| session-close | Vault handoff / session / memory / teach |
| commit-work | Safe Conventional Commits + pipeline gate |
| kosmo-sdlc | Codex adapter over command docs |
| ask-kosmo-sdlc | Router |
| tdd, diagnosing-bugs, codebase-design, … | Optional companions |

Full inventory: [skills/README.md](skills/README.md) · Matt map: [docs/mattpocock-skills.md](docs/mattpocock-skills.md)

### Session budget & Obsidian

In `_/sdlc-config.md` (optional):

```yaml
session:
  max_tokens: 200000
  max_iterations: 20
  on_limit: handoff
  vault:
    path: null   # local clone of your vault
    remote: https://github.com/Ivlad003/obsidian-personal
    work_root: Work
    project_name: null
```

Writes:

```text
Work/{project}/handoff/{timestamp}.md
Work/{project}/session/{timestamp}.md
Work/{project}/memory/{timestamp}.md
Work/{project}/teach/{timestamp}.md
```

## Documentation

| Doc | Topic |
| --- | --- |
| **[docs/install.md](docs/install.md)** | **Install on Claude, Codex, Grok, Cursor, Amp, …** |
| [docs/cycle.md](docs/cycle.md) | Cycle phases and gates |
| [docs/track-format.md](docs/track-format.md) | Track file contract |
| [docs/init-detection.md](docs/init-detection.md) | What init detects |
| [docs/adapting.md](docs/adapting.md) | No Jira / no Playwright / monorepo variants |
| [docs/design-rationale.md](docs/design-rationale.md) | What’s in / out of scope |
| [docs/mattpocock-skills.md](docs/mattpocock-skills.md) | Companion skills to install on the host |
| [skills/README.md](skills/README.md) | Bundled skills |

## Requirements

- Claude Code **v2.1+** (plugin manifest) and/or Codex with local plugin install
- Node 18+ (Playwright may be standalone via `validation.mode: standalone-playwright`)
- `gh` CLI authenticated (PR phase)
- Optional: Atlassian / Linear MCP (better intake)
- Optional peer CLIs for judge: `claude`, `codex`, `grok`, …

## License

MIT — see [LICENSE](LICENSE).
