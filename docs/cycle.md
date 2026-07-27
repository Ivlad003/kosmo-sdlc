# The cycle

`kosmo-sdlc` is a seven-phase loop that turns a ticket into a merged PR. Each phase has a gate; the cycle refuses to advance past a failing gate. The track file at `_/tracks/<TICKET>.md` is the single source of truth — every command reads its YAML frontmatter and writes a delta back.

```
*  /grill-me                    DEFAULT planning — grill before intake (not brainstorming)
*  /kosmo-sdlc:judge          optional multi-CLI AI judge (plan and/or code)
0  /kosmo-sdlc:init           one-time per project — detect + wizard, write _/sdlc-config.md
1  /kosmo-sdlc:intake         ticket + spec → _/tracks/<TICKET>.md with decomposed requirements
2  /kosmo-sdlc:implement      code + tests + mocks per requirement; pipeline gate per requirement
3  /kosmo-sdlc:validate       Playwright: assertions report + stakeholder demo (only if green)
4  /kosmo-sdlc:review         parallel code + security + standards review; CRITICAL = blocker
5  /kosmo-sdlc:pr             create PR with body built from track; pipeline gate again
5b /kosmo-sdlc:pr-comments    walk reviewer threads, verdict-prefix replies; log to track
6  /kosmo-sdlc:revalidate     re-validate; detect spec drift; mark ready_to_merge
*  /kosmo-sdlc:cycle          orchestrator — runs 1→6 in dedicated sub-agents
```

**Planning:** **`grill-me` is the default** for design/plan work (not brainstorming). Optional **`/kosmo-sdlc:judge`** asks peer CLIs (claude / codex / grok / …) to rank alternatives or critique a diff — advisory; does not replace the review gate. See [mattpocock-skills.md](mattpocock-skills.md).

## Phase gates

A phase only "passes" when its gate is satisfied. `/kosmo-sdlc:cycle` enforces gates between sub-agent dispatches; individual commands enforce their own gates when invoked manually.

| Phase | Gate |
| ----- | ---- |
| intake | Track validates against `schemas/track.schema.json`; every AC has ≥1 requirement. |
| implement | All in-scope requirements `status: done`; pipeline (lint + typecheck + test + build) green. |
| validate | Assertions report has 0 failures; no new console errors / network 4xx-5xx. |
| review | No CRITICAL findings unaddressed. HIGH allowed with explicit user ack. |
| pr | Pipeline green (lint included) and its exit-0 result recorded in the journal; branch pushed, PR opened, body populated. |
| revalidate | Requirements still pass; spec hash unchanged or user ack'd drift. |

## Why gates?

A common failure mode for agentic dev tools is "produces code, claims success, reviewer finds the gap". Gates flip this: every transition has a verifiable condition, and the cycle stops at the first unmet one. The track file remembers exactly where it stopped, so resuming a day later doesn't lose context.

## When to skip a phase

- **Backend-only changes**: `/kosmo-sdlc:validate` writes a `na` report and skips Playwright. Unit/E2E tests from `/kosmo-sdlc:implement` are the only gate.
- **No spec**: `/kosmo-sdlc:intake` runs in `freeform` mode (per `_/sdlc-config.md`); the user provides a description in their own words.
- **No Jira/Linear/GitHub**: `ticketing.system: "none"`; tracks are slug-named.
- **Hot fixes** (skip intake): not officially supported in v0.1. The recommended path is still `/kosmo-sdlc:intake` with a one-line description, then through the cycle. Time-pressure shortcuts hide the trail you'll wish you had two days later.

## Where artifacts live

```
_/
├── sdlc-config.md
├── tracks/
│   └── TICKET-1.md
├── demo/
│   ├── credentials.json              # never commit
│   ├── scenarios/TICKET-1.md
│   └── TICKET-1.spec.mjs            # generated Playwright script
└── recordings/
    ├── TICKET-1.20260513-211900.webm
    ├── TICKET-1.20260513-211900.log
    ├── TICKET-1.20260513-211900.zip   # Playwright trace
    ├── TICKET-1.validation.md
    ├── TICKET-1.revalidation.md
    ├── TICKET-1.review.md
    └── TICKET-1.latest.webm           # symlink to most recent passing demo
```

The whole `_/` directory is gitignored. Nothing the cycle produces lands in git history. The exception is the PR body, which is reproducible from the track at any time.

## Manual vs orchestrated

Two ways to run the cycle:

- **Manual**: invoke each phase yourself. Best when you want to read each phase's output before advancing, or when the project has unusual requirements that need on-the-fly judgement.
- **Orchestrated**: `/kosmo-sdlc:cycle <TICKET>`. Dispatches each phase to a sub-agent (preferably in a worktree for isolation — **optional fallback: in-process**), validates the frontmatter delta, persists, and advances. Pauses between phases (unless `--auto`). Stops on gate failures. Manual phase commands never require a worktree.

Pick orchestrated for the happy path. Pick manual when you're learning the cycle, debugging, or working on something the orchestrator's defaults don't fit.

## Resuming

A cycle can be interrupted at any point — closing the terminal, switching branches, days of dormancy. Resuming:

- `/kosmo-sdlc:cycle <TICKET> --resume` picks up at the last phase whose `phase_log` entry is missing or has `outcome != pass`.
- Individual commands are idempotent: running `/kosmo-sdlc:implement` twice on the same track skips already-done requirements.

The journal (§7 of the track) is the audit trail. Append-only.
