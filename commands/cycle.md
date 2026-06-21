---
description: Run the full cycle for one ticket — intake → implement → validate → review → pr → revalidate — dispatching each phase to a dedicated sub-agent. Gated; refuses to advance past a failing phase.
argument-hint: "<ticket-id-or-description> [spec-path-or-url] [--resume] [--auto]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Agent"]
---

# /agentic-sdlc:cycle

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
| validate | Assertions report has 0 failures; no new console errors / network 4xx-5xx. (For `size: s`: pipeline green — no assertions/demo.) |
| review | No CRITICAL findings unaddressed. (HIGH allowed with explicit user ack under `--auto`.) |
| pr | Branch pushed, PR opened, body populated, pipeline green. |
| revalidate | All requirements still `done` against post-review code; spec hash unchanged or user ack'd drift. |

## Size-adaptive flow

`frontmatter.size` (set at intake, confirmed by the user — see [intake §4b](intake.md)) tunes which phases run:

| Size | Phase sequence | Notes |
| ---- | -------------- | ----- |
| `s` | intake → implement → validate → pr | **Review is skipped.** `validate` runs pipeline-only (`na` demo). The project's quality-gate rerun is the sole verification — no e2e authored, no `.webm`, no 3-agent review. |
| `m` | intake → implement → validate → review → pr → revalidate | The default. Full flow, unchanged. |
| `l` | fan out over sub-tracks, then aggregate | The mother track carries `children: [...]`. Run the size-appropriate sequence for **each** sub-track, then a single aggregate `pr`. See §"L fan-out". |

Rules:

- **Confirm before reducing rigor.** If the track resolves to `s`, the orchestrator surfaces "running the light flow (no e2e/demo, no review) — confirm?" and requires an explicit ack **even under `--auto`.** Reducing rigor is never silent. `m`/`l` need no extra friction.
- A missing `size` field ⇒ treat as `m` (backward compatible with pre-existing tracks).
- Never use size to bypass a gate that *does* run — `s` still demands a green pipeline at implement, validate, and pr.
- `sizing.small_skips_review` in `_/sdlc-config.md` controls whether `s` drops the review phase. Default `true` (drop it). If a project sets it `false`, the `s` sequence becomes intake → implement → validate → review → pr.

## Workflow

### 1. Bootstrap

- Read `_/sdlc-config.md` (frontmatter + Notes body). If missing → run `/agentic-sdlc:init` first; abort the cycle if user declines.
- Resolve the track filename from `$1`. If a track already exists and `--resume` not set → ask whether to update or start fresh.
- After intake (or when resuming on an existing track), read `frontmatter.size` (absent ⇒ `m`):
  - `l` and `children` is non-empty → hand off to §"L fan-out" instead of the linear loop below.
  - `s` → confirm the light flow with the user (required even under `--auto`); set the phase sequence to intake → implement → validate → pr (no review, no revalidate).
  - `m` → the full sequence below.

### 2. Dispatch loop

For each phase in the **size-resolved** sequence (see §"Size-adaptive flow"):

1. Skip the phase if `phase_log` already shows `{ phase: <name>, outcome: pass }` for the current branch HEAD.
2. Construct the agent prompt:
   ```
   You are <agent-name>. Read _/tracks/<TICKET>.md and _/sdlc-config.md.
   The Notes body of _/sdlc-config.md is project-specific guidance — treat it as
   binding instructions, not flavour. Do your phase per agents/<agent>.md. Return
   ONLY the updated track frontmatter (YAML) and a one-paragraph summary. Do not
   commit. Do not push (except /agentic-sdlc:pr-agent).
   ```
   After constructing the base prompt, read `phase_prompts.<phase>` from `_/sdlc-config.md` frontmatter. If it is non-null and non-empty, append the following block to the prompt:
   ```
   Additional project instructions for this phase:
   <phase_prompts.<phase> value>
   ```
   This lets teams inject house conventions (review checklists, deploy gates, Playwright helpers) without editing agent definitions. Phases without an overlay receive the base prompt unchanged.
3. Dispatch via the `Agent` tool with the appropriate sub-agent definition.
4. Receive the frontmatter delta. Validate against `schemas/track.schema.json`.
5. Merge into the track file. Append the agent's summary to §7 Journal.
6. Check the gate.
   - Pass → continue to the next phase.
   - Fail → stop the cycle. Surface the report. Tell the user the concrete next action (run `/agentic-sdlc:implement` again, address CRITICAL findings, etc.).
7. If not `--auto`, ask "advance to <next-phase>?" before dispatching the next sub-agent.

### 3. Final report

```
TICKET-1 — cycle complete
intake     ✅ (4 ACs → 7 requirements)
implement  ✅ (7 requirements done · 12 commits · pipeline green)
validate   ✅ (7/7 pass · 1 console warning surfaced)
review     ✅ (1 CRITICAL applied · 2 HIGH applied · 1 HIGH deferred)
pr         ✅ https://github.com/<org>/<repo>/pull/123
revalidate ✅ (CI green · PR approved · spec unchanged)

Status: ready_to_merge
Track:  _/tracks/TICKET-1.md
```

If a gate failed:

```
TICKET-1 — cycle stopped at validate
Reason: 1 requirement failed (R1.4 — drawer remained open on submit; toast 'Erreur réseau')
Next:   /agentic-sdlc:implement TICKET-1 --requirement R1.4
```

### L fan-out

When the resolved track is an `l` mother (`children` non-empty):

1. Read each sub-track in `children`. Each has its own `size` (`s` or `m`) and its own AC group.
2. Run the size-resolved sequence for **each** sub-track in order, up to but **not including** its `pr` phase — sub-tracks share the mother's feature branch in v1, so there's one PR, not one per sub-track. Each sub-track's gates must pass before the next starts (stop at the first failed gate, name the sub-track + phase).
3. After every sub-track has cleared implement + validate (+ review for `m` sub-tracks), update the mother's §0 Sub-tracks table and `phase_log` with each child's outcome.
4. Run a **single aggregate `pr` phase** on the mother track: the PR body lists every AC group and its sub-track outcome. Mark the mother `ready_to_merge` only when all sub-tracks are green.

> v1 keeps sub-tracks on one branch + one PR for reviewability of the whole feature. Per-sub-track branches/PRs are a documented future option, not the default.

## Hard rules

- Never skip a gate, even under `--auto`.
- `size: s` skips the **review** phase but never the pipeline gate (implement, validate, pr all still demand green). Reducing rigor to `s` requires explicit user confirmation, even under `--auto`.
- For `l`, the orchestrator is still the single writer of every track file (mother and children); sub-track sub-agents return deltas only.
- Each sub-agent runs in isolation (worktree). The orchestrator is the only writer of the track file.
- Frontmatter delta must validate against the schema before being merged.
- On failure, surface the **specific** next action. No "consider re-running" generalities.
- If a sub-agent returns malformed YAML or out-of-schema fields, retry once with a corrective prompt. On second failure → abort and surface the raw output.
- `/agentic-sdlc:pr-comments` is **not** part of the initial cycle — reviewers haven't commented yet. The user invokes it later, reactively.
