# kosmo-sdlc

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
| 0   | `/kosmo-sdlc:init`        | One-time setup. Detects package manager, scripts, ticketing prefix; wizard fills the rest.                             | Writes `_/sdlc-config.md`                                      |
| 1   | `/kosmo-sdlc:intake`      | Pulls the ticket + spec, decomposes ACs into testable requirements.                                                    | Schema-valid track; every AC has ≥1 requirement                |
| 2   | `/kosmo-sdlc:implement`   | Codes each requirement with tests + mocks, journals as it goes.                                                        | All requirements `done`; lint + typecheck + test + build green |
| 3   | `/kosmo-sdlc:validate`    | 🎬 Playwright two-pass: strict assertions report → **narrated stakeholder demo `.webm`** with overlays (only on green). | 0 assertion failures; no new console / 4xx-5xx errors          |
| 4   | `/kosmo-sdlc:review`      | Three parallel sub-agents (code, security, standards) → CRITICAL/HIGH/MEDIUM/LOW report.                               | No unaddressed CRITICAL findings                               |
| 5   | `/kosmo-sdlc:pr`          | Pushes branch, opens PR with body built from the track frontmatter.                                                    | Pipeline green; PR URL written back                            |
| 5b  | `/kosmo-sdlc:pr-comments` | Walks every unresolved review thread, verdict-prefixes each reply (Applied / Rejected / Deferred / …).                 | Each thread logged to journal                                  |
| 6   | `/kosmo-sdlc:revalidate`  | Re-runs validation against the post-review state; detects spec drift.                                                  | All requirements still pass; spec hash matches or drift ack'd  |
| ∗   | `/kosmo-sdlc:cycle`       | Orchestrator — runs 1→6 in dedicated sub-agents, pausing between phases.                                               | Stops at the first failed gate                                 |

## Size-adaptive rigor

Not every ticket needs the full loop. Intake proposes a **size** and you confirm it — the cycle then scales its rigor to the change:

| Size | Flow | Verification |
| ---- | ---- | ------------ |
| **S** (small / XS) | implement → quality-gate rerun → pr | The project's existing pipeline (lint/prettier/typecheck/test/build) reruns to confirm nothing broke. No new e2e, no demo `.webm`, no 3-agent review. |
| **M** (default) | the full loop above | Playwright two-pass + demo + parallel review. |
| **L** (large) | mother track → one sub-track **per AC group** → aggregate | Each sub-track runs its own size-appropriate cycle; the mother aggregates into one PR. |

Rigor is never reduced silently: choosing **S** always needs explicit confirmation, even under `--auto`. A track with no size behaves as **M**, so existing tracks are unaffected. Tune the thresholds (or keep review on for S) via the optional `sizing` block in `_/sdlc-config.md`.

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
/plugin marketplace add Ivlad003/kosmo-sdlc
/plugin install kosmo-sdlc
```

### Codex

Codex support is local-clone based for now:

```bash
mkdir -p ~/plugins ~/.agents/plugins
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
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

If you already have a personal marketplace file, add only the `kosmo-sdlc` object to its `plugins` array. Then open this URL, replacing `<you>` with your macOS username, and click **Install**:

```
codex://plugins/kosmo-sdlc?marketplacePath=/Users/<you>/.agents/plugins/marketplace.json
```

## Update

### Claude Code

```
/plugin update kosmo-sdlc
```

## First run

```bash
/kosmo-sdlc:init                          # wizard → _/sdlc-config.md (+ token budget, vault path)
/kosmo-sdlc:discover-agents               # dynamic CLI inventory → _/coding-agents.md
/grill-me                                   # DEFAULT planning
/kosmo-sdlc:judge plan                    # multi-CLI ranking (peers from inventory)
/kosmo-sdlc:cycle PROJ-123
# … or autonomous stretches (our fork of snarktank/ralph — no skill-id clash):
/kosmo-sdlc:kosmo-ralph convert PROJ-123   # → _/kosmo-ralph/prd.json
/kosmo-sdlc:kosmo-ralph run --tool claude --max 15
/kosmo-sdlc:session-close
```

**`/grill-me`** — default planning. **`/kosmo-sdlc:discover-agents`** for judge peers. **`/kosmo-sdlc:kosmo-ralph`** — kosmo-sdlc fork of [snarktank/ralph](https://github.com/snarktank/ralph) (skill id **`kosmo-ralph`**, not `ralph`). **`/kosmo-sdlc:session-close`** → Obsidian. Unsure? **`ask-kosmo-sdlc`**.

## Documentation

- [The cycle, step by step](docs/cycle.md)
- [Track file format](docs/track-format.md)
- [What `/kosmo-sdlc:init` detects](docs/init-detection.md)
- [Adapting to your project (no Jira / no spec / non-monorepo)](docs/adapting.md)
- [Design rationale — what's deliberately not in scope](docs/design-rationale.md)
- [Bundled skills inventory](skills/README.md)
- [Matt Pocock skills map](docs/mattpocock-skills.md) — what to install on the host

## Requirements

- Claude Code **v2.1+** (plugin manifest format)
- Node 18+ (for Playwright — sdlc can run Playwright standalone if the host project has none)
- `gh` CLI authenticated (for the PR phase)
- Atlassian or Linear MCP — optional, improves intake quality
