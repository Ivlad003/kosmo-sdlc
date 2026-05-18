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

| # | Command | What it does | Gate |
|---|---|---|---|
| 0 | `/sdlc-init` | One-time setup. Detects package manager, scripts, ticketing prefix; wizard fills the rest. | Writes `_/sdlc-config.md` |
| 1 | `/sdlc-intake` | Pulls the ticket + spec, decomposes ACs into testable requirements. | Schema-valid track; every AC has ≥1 requirement |
| 2 | `/sdlc-implement` | Codes each requirement with tests + mocks, journals as it goes. | All requirements `done`; lint + typecheck + test + build green |
| 3 | `/sdlc-validate` | 🎬 Playwright two-pass: strict assertions report → **narrated stakeholder demo `.webm`** with overlays (only on green). | 0 assertion failures; no new console / 4xx-5xx errors |
| 4 | `/sdlc-review` | Three parallel sub-agents (code, security, standards) → CRITICAL/HIGH/MEDIUM/LOW report. | No unaddressed CRITICAL findings |
| 5 | `/sdlc-pr` | Pushes branch, opens PR with body built from the track frontmatter. | Pipeline green; PR URL written back |
| 5b | `/sdlc-pr-comments` | Walks every unresolved review thread, verdict-prefixes each reply (Applied / Rejected / Deferred / …). | Each thread logged to journal |
| 6 | `/sdlc-revalidate` | Re-runs validation against the post-review state; detects spec drift. | All requirements still pass; spec hash matches or drift ack'd |
| ∗ | `/sdlc-cycle` | Orchestrator — runs 1→6 in dedicated sub-agents, pausing between phases. | Stops at the first failed gate |

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

```bash
/plugin marketplace add /path/to/sdlc
/plugin install agentic-sdlc@agentic-sdlc
```

Manual install (clone + symlink) is documented in [docs/adapting.md](docs/adapting.md).

## First run

```bash
/sdlc-init                          # detect + short wizard → _/sdlc-config.md
/sdlc-cycle PROJ-123                # full loop, gated, end-to-end
```

Or step through manually:

```bash
/sdlc-intake     PROJ-123 path/to/spec.md
/sdlc-implement  PROJ-123
/sdlc-validate   PROJ-123
/sdlc-review     PROJ-123
/sdlc-pr         PROJ-123
```

## Why gates

The common failure mode for agentic dev tools is *"produces code, claims success, reviewer finds the gap."* Gates flip this: every transition has a verifiable condition, and the cycle stops at the first unmet one. The track file remembers exactly where it stopped, so resuming a day later doesn't lose context.

## What's in the box

| Folder | Contents |
|---|---|
| `commands/` | The nine slash commands |
| `agents/` | Sub-agent definitions dispatched by `/sdlc-cycle` |
| `skills/commit-work/` | Reusable commit-craft skill |
| `schemas/` | JSON Schemas for the track file and project config |
| `templates/` | Scaffolds rendered by `/sdlc-init` and `/sdlc-intake` |
| `docs/` | Cycle walkthrough, track format, init detection, adapting |
| `examples/sample/` | Reference track + config from a real Turborepo project |

## Documentation

- [The cycle, step by step](docs/cycle.md)
- [Track file format](docs/track-format.md)
- [What `/sdlc-init` detects](docs/init-detection.md)
- [Adapting to your project (no Jira / no spec / non-monorepo)](docs/adapting.md)
- [Design rationale — what's deliberately not in scope](docs/design-rationale.md)

## Requirements

- Claude Code **v2.1+** (plugin manifest format)
- Node 18+ (for Playwright — sdlc can run Playwright standalone if the host project has none)
- `gh` CLI authenticated (for the PR phase)
- Atlassian or Linear MCP — optional, improves intake quality

## Status

Alpha. Schema and command surface may change between 0.x releases. See [CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE).
