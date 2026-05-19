---
description: Code + security review of the current branch's diff. Three parallel reviewer sub-agents (code, security, standards) produce a consolidated CRITICAL/HIGH/MEDIUM/LOW report; a separate fix sub-agent then applies the approved findings in its own context. Auto-invokes the security reviewer when the diff touches auth/guard/controller/schema/env paths.
argument-hint: "<ticket-id> [--strict]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Agent"]
---

# /agentic-sdlc:review

Phase 4 of the cycle. Pre-emptive review — fixes issues before reviewers see them, not after. Produces `_/recordings/<TICKET>.review.md`.

## Arguments

- `$1` (required): ticket ID.
- `--strict` (optional): refuse to advance the track unless the report has zero HIGH findings. Default refuses only on CRITICAL.

## Preconditions

1. `_/sdlc-config.md` exists. Read both frontmatter and Notes body — the Notes body may carry team-specific review conventions (severity thresholds, "we always allow X", etc.) that the consolidated report should honour.
2. `_/tracks/<TICKET>.md` exists, status is `in_progress` or `in_review`.
3. Validation phase has run (frontmatter has at least one `phase_log` entry with `phase: validate, outcome: pass` OR all requirements are non-frontend).

## Workflow

### 1. Compute the diff

- Resolve the default branch: `overrides.default_branch` from `_/sdlc-config.md` if set, else `git symbolic-ref refs/remotes/origin/HEAD` and parse the trailing branch name.
- `git fetch origin <default_branch>`.
- `BASE=$(git merge-base HEAD origin/<default_branch>)`.
- `git diff $BASE...HEAD --stat` and `git diff $BASE...HEAD --name-only`.
- Build a file list (the "impact set"). If the diff is huge (>50 files), warn and ask whether to scope to a subset.

### 2. Decide which reviewers fire

Three review roles, each backed by an installed Claude Code sub-agent:

- **code-reviewer** — always fires.
- **security-reviewer** — fires when impact set matches `auth|guard|controller|service|schema|env|middleware|cors|csrf|jwt|password|secret|crypto|token` (case-insensitive path or content match). Always fires under `--strict`.
- **standards-reviewer** — fires when the project has a `CLAUDE.md`, `AGENTS.md`, `.claude/rules/*.md`, or `docs/conventions.md`. Reviews against those conventions.

**Dispatch all firing roles in parallel** — one batched message with one `Agent` call per reviewer. Each sub-agent runs in its own context window so analyses don't bleed across roles, and is scoped to **review only, no fixes** (fixes happen in §5 via a dedicated sub-agent).

### 3. Sub-agent contracts

Each sub-agent receives:

```yaml
ticket: TICKET-1
track_path: _/tracks/TICKET-1.md
base_sha: <BASE>
head_sha: HEAD
impact_files: [...]
project_profile: <_/sdlc-config.md snapshot — frontmatter + Notes body>
```

Each sub-agent returns a Markdown section with:

```markdown
## <agent-name>

### Findings

| Severity | Finding | File:Line | Recommendation |
| -------- | ------- | --------- | -------------- |
| CRITICAL | ...     | ...       | ...            |
| HIGH     | ...     | ...       | ...            |
| MEDIUM   | ...     | ...       | ...            |
| LOW      | ...     | ...       | ...            |

### Notes

<freeform observations the table can't capture>
```

The orchestrator never edits the sub-agents' findings — only consolidates.

### 4. Consolidate

Write `_/recordings/<TICKET>.review.md`:

```markdown
# Review report — TICKET-1

Base: <sha> (origin/trunk)
Head: <sha> (feat/TICKET-1)
Files reviewed: 12
Sub-agents dispatched: code, security, standards

## Summary

| Severity | code | security | standards | total |
| -------- | ---: | -------: | --------: | ----: |
| CRITICAL |    0 |        1 |         0 |     1 |
| HIGH     |    2 |        0 |         1 |     3 |
| MEDIUM   |    5 |        2 |         2 |     9 |
| LOW      |    3 |        1 |         4 |     8 |

> 1 CRITICAL finding must be addressed before advancing to /agentic-sdlc:pr.

## Findings — code-review-agent
...

## Findings — security-review-agent
...

## Findings — standards-review-agent
...
```

### 5. Dispatch the fix sub-agent

Reviewer fan-out is parallel; **fix application is sequential** (it consumes findings) but runs in its own context window so reviewer analysis doesn't pollute the fix work.

First, group findings by severity and ask the user which to apply now vs defer:

- CRITICAL → always apply (the gate).
- HIGH → recommend applying; user can defer with explicit acknowledgement.
- MEDIUM/LOW → user's call.

Then dispatch **one** `Agent` call with `subagent_type: agentic-sdlc:sdlc-impl-agent`, scoped to the approved findings only. The prompt must include:

- The consolidated report path (`_/recordings/<TICKET>.review.md`).
- The exact list of finding ids to apply (e.g. `CRITICAL-1, HIGH-1, HIGH-2`).
- Flags `--review-fix --no-frontmatter --no-pipeline` — the fix agent only edits code; the coordinator handles writes and the pipeline gate.

The fix sub-agent:
- Makes minimal, focused edits per finding; re-reads each touched file to confirm.
- Returns: files touched, per-finding note, and any findings it couldn't apply (with reason).
- Never commits — the user batches commits via the `commit-work` skill, or `/agentic-sdlc:pr` runs `commit-work` itself.

On return, the coordinator (this command):
- Re-runs the pipeline gate **once** for the whole fix batch.
- Persists frontmatter updates (status / journal) — single writer.
- Surfaces any unapplied findings to the user.

### 6. Update the track

- Append journal row: `Review pass — 1 CRITICAL applied, 2 HIGH applied, 1 HIGH deferred (logged in <followup>); 9 MEDIUM, 8 LOW.`
- Update "Where we at": next step is `/agentic-sdlc:pr <TICKET>`.
- If CRITICAL findings remain unaddressed → set `status` back to `in_progress` and **refuse** to advance the cycle.

### 7. Report

```
Review complete — _/recordings/TICKET-1.review.md
1 CRITICAL applied · 2 HIGH applied · 1 HIGH deferred · 11 MEDIUM/LOW remaining
Next: /agentic-sdlc:pr TICKET-1
```

## Hard rules

- Never declare the review "pass" with unaddressed CRITICAL findings.
- Reviewer sub-agents fan out **in parallel** and are scoped to review only — they never apply fixes.
- The fix sub-agent runs **sequentially after** review, in its own context, and **never writes frontmatter** — the coordinator is the single writer.
- The security reviewer is mandatory under `--strict` and when the file-path heuristic matches.
- Don't fabricate findings to "look thorough". If a sub-agent has nothing in a severity bucket, write `0` and move on.
- Never auto-commit fixes. The user commits when ready.
- Pre-existing issues outside the diff are **out of scope** unless the user explicitly asks to expand the review. Report them as informational notes, never as blocking findings.
