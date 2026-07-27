---
name: ai-judge
description: "Multi-agent AI judge: cross-review plans and code with peer CLIs (claude, codex, grok, copilot). Use when the user wants a second opinion, multi-model review, alternative designs ranked, or cross-CLI judging."
disable-model-invocation: true
---

# AI Judge — multi-model / multi-CLI court

Cross-check **plans** and **implementation** with agents that are *not* the one currently driving the session. Goal: surface dissent, rank alternatives, pick a better path — not rubber-stamp the host model.

## When

- After `grill-me` / a written plan, before intake or implement.
- After implement (or on a PR/diff), as a second review layer beside `/kosmo-sdlc:review`.
- User asks for AI judge, multi-model review, "what would Claude/Codex say", alternatives ranked.

## Modes

| Mode | Subject | Typical peers |
| --- | --- | --- |
| `plan` | design / AC / architecture options | 2–3 other CLIs |
| `code` | git diff / PR / files changed | 2–3 other CLIs |
| `both` | plan package + current diff | peers for each, then joint synthesis |

## Peer CLIs (dynamic inventory — do not hard-code)

**Always load machine inventory first:**

1. If `_/coding-agents.json` missing or `discovered_at` older than 24h → run **`discover-agents`** (`/kosmo-sdlc:discover-agents` or `scripts/discover-coding-agents.*`).
2. Read `_/coding-agents.md` + `.json` (project memory for judge).
3. Peers = `judge_peers` from JSON, or `judge.peers` override in `_/sdlc-config.md` when non-null.
4. Headless recipes come from each agent's `headless` / `code_review` fields — not from a static table in this skill.

**Host exclusion rule:** use `host_family` from the inventory (or config `judge.host`). **Never send the subject only to the same product family as the host** if other peers exist — e.g. Grok host → prefer `claude` + `codex`.

If fewer than **2** peer CLIs are available, say so and either:

1. Run single-peer + local sub-agent with a *different* model if the host supports multi-model, or  
2. Abort judge with "install another coding CLI, then re-run discover-agents".

Do **not** invent peer verdicts. No network scrapes pretending to be another model.

## Workflow

### 1. Scope

Collect from user or args:

- `mode`: `plan` | `code` | `both`
- `subject`: free text path, ticket id (`_/tracks/<T>.md`), plan markdown, or `git` range (default `origin/<default>..HEAD`)
- Optional: `variants` count (default **3** for plan mode) — generate alternatives only if user has not already fixed one design

### 2. Build the case file

Write a temporary case under `_/judge/<run-id>/case.md` (gitignored via `_/`):

```markdown
# Case
- host: <detected>
- mode: plan|code|both
- ticket: <id or null>
- generated_at: <ISO>

## Context
<summary of product goal, constraints, non-goals>

## Subject — plan
<plan or grilled decisions>

## Subject — code
`git diff` / PR summary / file list (truncated if huge; keep high-signal hunks)

## Alternatives (plan mode)
### A — <name>
### B — <name>
### C — <name>
```

For **plan mode**, if alternatives are missing: as the **host** agent, draft 2–3 *radically different* approaches (not wording tweaks) with trade-offs — then judges rank them. Do not implement code while drafting alternatives.

### 3. Judge prompt (same text to every peer)

Use a fixed template so answers are comparable:

```text
You are an independent reviewer. Do NOT implement. Do NOT edit files.
Read the case below and answer ONLY with this structure:

## Verdict
- recommendation: <A|B|C|hybrid|reject-all>   # plan mode
- ship_risk: <low|medium|high>                 # code mode
- overall: <approve|approve-with-changes|block>

## Scores (1-5)
- correctness:
- simplicity:
- testability:
- operability:
- fit_to_constraints:

## Dissent
- what the author likely missed
- best counter-argument to the leading option

## Must-fix (≤5 bullets)
## Nice-to-have (≤5 bullets)
## One-paragraph rationale

CASE:
<<<paste case.md>>>
```

Prefer **read-only** / no-write invocations. Cap wall-clock per peer (e.g. 3–8 minutes); on timeout, record `timeout` and continue.

### 4. Dispatch peers in parallel

Run available peers concurrently (background shells). Capture stdout/stderr to:

```text
_/judge/<run-id>/peer-<name>.md
```

Never pass secrets, `.env`, or `_/demo/credentials.json` into the case.

### 5. Synthesize (host agent = clerk of the court)

Produce `_/judge/<run-id>/verdict.md` and optionally copy to `_/recordings/<TICKET>.judge.md` when a ticket is known:

```markdown
# AI Judge verdict
- host: …
- peers: claude, codex, …
- mode: …

## Consensus
## Dissent (peer vs peer)
## Ranked options (plan) / Risk (code)
## Recommended decision
## Conditions to accept recommendation
## Open questions for the human
```

Rules for synthesis:

- Majority is a signal, **not** automatic truth — note when a minority has a stronger falsifiable argument.
- Prefer **simpler** option when scores tie.
- If peers **block** and host wanted ship → surface as gate-style warning; do not auto-merge or auto-implement.
- Human confirms final call (judge is advisory unless user said `--binding` and explicitly accepts).

### 6. Hand off

| After mode | Next |
| --- | --- |
| `plan` approved | `/kosmo-sdlc:intake` or continue cycle |
| `plan` blocked / hybrid | back to `grill-me` on the contested branch |
| `code` approve-with-changes | fix via `/kosmo-sdlc:implement` / review fixes |
| `code` block | stop PR; address must-fix first |

Append a journal line on the track when a ticket exists: `AI judge <run-id> — <overall> (peers: …)`.

## Config (optional, `_/sdlc-config.md`)

```yaml
judge:
  peers: null              # null = use _/coding-agents.json judge_peers
  # peers: [claude, codex]
  exclude_host: true       # default true
  timeout_seconds: 300
  default_mode: plan       # plan | code | both
  inventory_max_age_hours: 24
```

## Hard rules

- Advisory by default; never force-merge or force-implement.
- No fabricated peer output.
- No secrets in case files.
- Exclude host family when other peers exist.
- Judge ≠ `/kosmo-sdlc:review` — review is the in-cycle code/security/standards gate; judge is **cross-model** second court (can run before or after).
