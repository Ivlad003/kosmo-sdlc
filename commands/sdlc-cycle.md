---
description: Run the full cycle for one ticket — intake → implement → validate → review → pr → revalidate — dispatching each phase to a dedicated sub-agent. Gated; refuses to advance past a failing phase.
argument-hint: "<ticket-id-or-description> [spec-path-or-url] [--resume] [--auto]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Agent"]
---

# /sdlc-cycle

The orchestrator. One invocation, end-to-end loop. Each phase runs as a sub-agent in its own context window, returns a track-frontmatter delta, and the orchestrator validates and persists the delta before dispatching the next phase.

## Arguments

- `$1` (required): ticket ID, ticket URL, or freeform feature description.
- `$2` (optional): spec path or URL (forwarded to intake).
- `--resume` (optional): pick up at the last incomplete phase per `frontmatter.phase_log`. Default starts at intake (or skips intake if the track already exists).
- `--auto` (optional): don't pause for user confirmation between phases. Even with `--auto`, the orchestrator still **stops** on gate failures.

## Sub-agents

Each phase has a dedicated sub-agent in `agents/`:

| Phase | Sub-agent | Definition |
| ----- | --------- | ---------- |
| intake | `sdlc-intake-agent` | [agents/sdlc-intake-agent.md](../agents/sdlc-intake-agent.md) |
| implement | `sdlc-impl-agent` | [agents/sdlc-impl-agent.md](../agents/sdlc-impl-agent.md) |
| validate | `sdlc-validate-agent` | [agents/sdlc-validate-agent.md](../agents/sdlc-validate-agent.md) |
| review | `sdlc-review-agent` | [agents/sdlc-review-agent.md](../agents/sdlc-review-agent.md) |
| pr | `sdlc-pr-agent` | [agents/sdlc-pr-agent.md](../agents/sdlc-pr-agent.md) |
| pr-comments | (skipped in initial cycle; runs reactively when reviewers comment) | — |
| revalidate | reuses `sdlc-validate-agent` with `--mode revalidate` | — |

Each sub-agent runs in a git worktree (see `~/.agents/skills/using-git-worktrees/SKILL.md`) so context windows don't bleed into each other.

## Phase gates

| Phase | Gate (must pass to advance) |
| ----- | --------------------------- |
| intake | Track validates against `schemas/track.schema.json`; every AC has ≥1 requirement. |
| implement | All non-`na` requirements `status: done`; pipeline green. |
| validate | Assertions report has 0 failures; no new console errors / network 4xx-5xx. |
| review | No CRITICAL findings unaddressed. (HIGH allowed with explicit user ack under `--auto`.) |
| pr | Branch pushed, PR opened, body populated, pipeline green. |
| revalidate | All requirements still `done` against post-review code; spec hash unchanged or user ack'd drift. |

## Workflow

### 1. Bootstrap

- Read `_/sdlc.config.json`. If missing → run `/sdlc-init` first; abort the cycle if user declines.
- Resolve the track filename from `$1`. If a track already exists and `--resume` not set → ask whether to update or start fresh.

### 2. Dispatch loop

For each phase in order: intake → implement → validate → review → pr → revalidate:

1. Skip the phase if `phase_log` already shows `{ phase: <name>, outcome: pass }` for the current branch HEAD.
2. Construct the agent prompt:
   ```
   You are <agent-name>. Read _/tracks/<TICKET>.md and _/sdlc.config.json.
   Do your phase per agents/<agent>.md. Return ONLY the updated track frontmatter (YAML)
   and a one-paragraph summary. Do not commit. Do not push (except /sdlc-pr-agent).
   ```
3. Dispatch via the `Agent` tool with the appropriate sub-agent definition.
4. Receive the frontmatter delta. Validate against `schemas/track.schema.json`.
5. Merge into the track file. Append the agent's summary to §7 Journal.
6. Check the gate.
   - Pass → continue to the next phase.
   - Fail → stop the cycle. Surface the report. Tell the user the concrete next action (run `/sdlc-implement` again, address CRITICAL findings, etc.).
7. If not `--auto`, ask "advance to <next-phase>?" before dispatching the next sub-agent.

### 3. Final report

```
PICTO-594 — cycle complete
intake     ✅ (4 ACs → 7 requirements)
implement  ✅ (7 requirements done · 12 commits · pipeline green)
validate   ✅ (7/7 pass · 1 console warning surfaced)
review     ✅ (1 CRITICAL applied · 2 HIGH applied · 1 HIGH deferred)
pr         ✅ https://github.com/<org>/<repo>/pull/123
revalidate ✅ (CI green · PR approved · spec unchanged)

Status: ready_to_merge
Track:  _/tracks/PICTO-594.md
```

If a gate failed:

```
PICTO-594 — cycle stopped at validate
Reason: 1 requirement failed (R1.4 — drawer remained open on submit; toast 'Erreur réseau')
Next:   /sdlc-implement PICTO-594 --requirement R1.4
```

## Hard rules

- Never skip a gate, even under `--auto`.
- Each sub-agent runs in isolation (worktree). The orchestrator is the only writer of the track file.
- Frontmatter delta must validate against the schema before being merged.
- On failure, surface the **specific** next action. No "consider re-running" generalities.
- If a sub-agent returns malformed YAML or out-of-schema fields, retry once with a corrective prompt. On second failure → abort and surface the raw output.
- `/sdlc-pr-comments` is **not** part of the initial cycle — reviewers haven't commented yet. The user invokes it later, reactively.
