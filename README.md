# agentic-sdlc

> **Ticket → merged PR — with a narrated demo video the stakeholders can actually watch.**

A Claude Code plugin that runs a deterministic seven-phase loop: intake the ticket, implement against decomposed requirements, **validate with Playwright and record a stakeholder `.webm`**, run parallel code+security review, open the PR, address review comments, revalidate. Each phase has a verifiable gate — the cycle refuses to advance past a broken state.

```
ticket ──► intake ──► implement ──► validate ──► review ──► pr ──► revalidate ──► merge
            ▲           ▲              │           ▲          ▲          ▲
            └───────────┴── gate ──────┤           └── gate ──┴── gate ──┘
                                       └─► 🎬 narrated demo.webm
```

## 🎬 The demo video — our strongest feature

Every passing validate phase produces a `.webm` you can drop into a Slack thread, a Linear comment, or a stakeholder email. It's not a screenshot. It's not a test report. It's a narrated, slow-motion walkthrough of the feature behaving correctly:

- **Overlays + fake cursor + section badges** — the viewer sees what's happening *and why*
- **Two-pass execution** — assertions run first (headless, strict). The demo only records when **every** assertion passes. A demo of a broken state is worse than no demo.
- **Console + network capture** — any error or 4xx/5xx during the run fails the report. The demo never papers over bugs.
- **No project setup required** — `validation.mode: standalone-playwright` lets sdlc install and drive its own Playwright. Projects that never adopted E2E testing still get demos.
- **Real waits, no `force: true`** — if the UI is wrong, the run fails. The video is honest.

> "I shipped a feature. Here's the 40-second video of it working." — what every PR description should be.

## The cycle

| #   | Command                     | What it does                                                                                                           | Gate                                                           |
| --- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| 0   | `/agentic-sdlc:init`        | One-time setup. Detects package manager, scripts, ticketing prefix; wizard fills the rest.                             | Writes `_/sdlc-config.md`                                      |
| 1   | `/agentic-sdlc:intake`      | Pulls the ticket + spec, decomposes ACs into testable requirements.                                                    | Schema-valid track; every AC has ≥1 requirement                |
| 2   | `/agentic-sdlc:implement`   | Codes each requirement with tests + mocks, journals as it goes.                                                        | All requirements `done`; lint + typecheck + test + build green |
| 3   | `/agentic-sdlc:validate`    | 🎬 Playwright two-pass: strict assertions report → **narrated stakeholder demo `.webm`** with overlays (only on green). | 0 assertion failures; no new console / 4xx-5xx errors          |
| 4   | `/agentic-sdlc:review`      | Three parallel sub-agents (code, security, standards) → CRITICAL/HIGH/MEDIUM/LOW report.                               | No unaddressed CRITICAL findings                               |
| 5   | `/agentic-sdlc:pr`          | Pushes branch, opens PR with body built from the track frontmatter.                                                    | Pipeline green; PR URL written back                            |
| 5b  | `/agentic-sdlc:pr-comments` | Walks every unresolved review thread, verdict-prefixes each reply (Applied / Rejected / Deferred / …).                 | Each thread logged to journal                                  |
| 6   | `/agentic-sdlc:revalidate`  | Re-runs validation against the post-review state; detects spec drift.                                                  | All requirements still pass; spec hash matches or drift ack'd  |
| ∗   | `/agentic-sdlc:cycle`       | Orchestrator — runs 1→6 in dedicated sub-agents, pausing between phases.                                               | Stops at the first failed gate                                 |

## Single source of truth

Every command reads and writes one file per ticket — `_/tracks/<TICKET>.md` — with YAML frontmatter as the contract and a freeform body for humans.

```
_/
├── sdlc-config.md                project profile (frontmatter + agent notes)
├── tracks/PROJ-123.md            track: requirements, status, journal
├── demo/PROJ-123.spec.mjs        generated Playwright script
└── recordings/
    ├── PROJ-123.validation.md    assertions report
    ├── PROJ-123.review.md        consolidated review findings
    ├── PROJ-123.latest.webm      stakeholder demo
    └── …
```

The whole `_/` directory is gitignored. Nothing the cycle produces lands in git — the PR body is reproduced from the track on demand.

## Install

### Claude Code

```
/plugin marketplace add inperegelion/agentic-sdlc
/plugin install agentic-sdlc
```

### Codex

Codex support is local-clone based for now:

```bash
mkdir -p ~/plugins ~/.agents/plugins
git clone https://github.com/inperegelion/agentic-sdlc.git ~/plugins/agentic-sdlc
```

Add the plugin to your personal Codex marketplace at `~/.agents/plugins/marketplace.json`:

```json
{
  "name": "personal",
  "interface": {
    "displayName": "Personal"
  },
  "plugins": [
    {
      "name": "agentic-sdlc",
      "source": {
        "source": "local",
        "path": "./plugins/agentic-sdlc"
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

If you already have a personal marketplace file, add only the `agentic-sdlc` object to its `plugins` array. Then open this URL, replacing `<you>` with your macOS username, and click **Install**:

```
codex://plugins/agentic-sdlc?marketplacePath=/Users/<you>/.agents/plugins/marketplace.json
```

## Update

### Claude Code

```
/plugin update agentic-sdlc
```

## First run

```bash
/agentic-sdlc:init                          # detect + short wizard → _/sdlc-config.md
/agentic-sdlc:cycle PROJ-123                # full loop, gated, end-to-end
```

Or step through manually:

```bash
/agentic-sdlc:intake     PROJ-123 path/to/spec.md
/agentic-sdlc:implement  PROJ-123
/agentic-sdlc:validate   PROJ-123
/agentic-sdlc:review     PROJ-123
/agentic-sdlc:pr         PROJ-123
```

## Documentation

- [The cycle, step by step](docs/cycle.md)
- [Track file format](docs/track-format.md)
- [What `/agentic-sdlc:init` detects](docs/init-detection.md)
- [Adapting to your project (no Jira / no spec / non-monorepo)](docs/adapting.md)
- [Design rationale — what's deliberately not in scope](docs/design-rationale.md)

## Requirements

- Claude Code **v2.1+** (plugin manifest format)
- Node 18+ (for Playwright — sdlc can run Playwright standalone if the host project has none)
- `gh` CLI authenticated (for the PR phase)
- Atlassian or Linear MCP — optional, improves intake quality
