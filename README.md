# agentic-sdlc

A Claude Code plugin that turns a Jira ticket (or a one-line feature description) into a merged PR through a deterministic, gated loop. Built for full-stack JavaScript projects. Portable across stacks, host-project-aware, opinionated about gates.

```
0  /sdlc-init           detect project, write _/sdlc.config.json
1  /sdlc-intake         build _/tracks/<TICKET>.md from ticket + spec
2  /sdlc-implement      code + tests + mocks, journal as you go
3  /sdlc-validate       Playwright: assertions report + stakeholder .webm
4  /sdlc-review         code review + security review on impacted files
5  /sdlc-pr             create PR, body from track frontmatter
5b /sdlc-pr-comments    walk reviewer threads, verdict-prefix replies
6  /sdlc-revalidate     re-run /sdlc-validate against final state
*  /sdlc-cycle          orchestrator, dispatches each phase as a sub-agent
```

## Why

Slash commands that "just produce code" are easy to write and hard to trust. They miss tests, skip security review, recycle stale specs, and leave the user reading diffs to figure out what shipped. `agentic-sdlc` enforces a small number of gates between phases so the agent can't advance past a broken state — and it persists every decision in a single, machine-readable track file.

The track file is the source of truth. Sections are for humans; YAML frontmatter is the contract every later command queries. Every artifact lives under a gitignored `_/` directory, so nothing leaks into your project's history.

## Install

Until a public marketplace URL is published, install from a local clone of this repo:

```
/plugin marketplace add /path/to/sdlc
/plugin install agentic-sdlc@agentic-sdlc
```

Manual install (clone + symlink) is documented in [docs/adapting.md](docs/adapting.md).

## First run

In any full-stack JS project:

```
/sdlc-init                          # detects scripts, Playwright, CI, ticketing
/sdlc-cycle PROJ-123                # runs the full loop, gated, end-to-end
```

Or step through manually:

```
/sdlc-intake PROJ-123 path/to/spec.md
/sdlc-implement PROJ-123
/sdlc-validate PROJ-123
/sdlc-review PROJ-123
/sdlc-pr PROJ-123
```

## What's in the box

| Folder | Contents |
|---|---|
| `commands/` | The nine slash commands |
| `agents/` | Sub-agent definitions dispatched by `/sdlc-cycle` |
| `skills/commit-work/` | Reusable commit-craft skill |
| `schemas/` | JSON Schemas for the track file and project config |
| `templates/` | Scaffolds rendered by `/sdlc-init` and `/sdlc-intake` |
| `docs/` | The cycle, the track format, init detection rules, how to adapt |
| `examples/sample/` | A reference track + config from a real Turborepo project |

## Documentation

- [The cycle, step by step](docs/cycle.md)
- [Track file format](docs/track-format.md)
- [What `/sdlc-init` detects](docs/init-detection.md)
- [Adapting to your project (no Jira / no spec / non-monorepo)](docs/adapting.md)
- [Design rationale — what's deliberately not in scope](docs/design-rationale.md)

## Requirements

- Claude Code v2.1 or later (plugin manifest format).
- Node 18+ on the host project for Playwright validation.
- `gh` CLI authenticated for the PR phase.
- Atlassian or Linear MCP (optional, improves intake quality when configured).

## Status

Alpha. Schema and command surface may change between 0.x releases. See [CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE).
