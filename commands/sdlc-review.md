---
description: Code + security review of the current branch's diff. Three parallel sub-agents (code, security, standards) produce a consolidated CRITICAL/HIGH/MEDIUM/LOW report. Auto-invokes the security sub-agent when the diff touches auth/guard/controller/schema/env paths.
argument-hint: "<ticket-id> [--strict]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Agent"]
---

# /sdlc-review

Phase 4 of the cycle. Pre-emptive review — fixes issues before reviewers see them, not after. Produces `_/recordings/<TICKET>.review.md`.

## Arguments

- `$1` (required): ticket ID.
- `--strict` (optional): refuse to advance the track unless the report has zero HIGH findings. Default refuses only on CRITICAL.

## Preconditions

1. `_/sdlc.config.json` exists.
2. `_/tracks/<TICKET>.md` exists, status is `in_progress` or `in_review`.
3. Validation phase has run (frontmatter has at least one `phase_log` entry with `phase: validate, outcome: pass` OR all requirements are non-frontend).

## Workflow

### 1. Compute the diff

- `git fetch origin <default_branch>` from config.
- `BASE=$(git merge-base HEAD origin/<default_branch>)`.
- `git diff $BASE...HEAD --stat` and `git diff $BASE...HEAD --name-only`.
- Build a file list (the "impact set"). If the diff is huge (>50 files), warn and ask whether to scope to a subset.

### 2. Decide which sub-agents fire

Three sub-agents (definitions in `agents/`):

- **code-review-agent** — always fires.
- **security-review-agent** — fires when impact set matches `auth|guard|controller|service|schema|env|middleware|cors|csrf|jwt|password|secret|crypto|token` (case-insensitive path or content match). Always fires under `--strict`.
- **standards-review-agent** — fires when the project has a `CLAUDE.md`, `AGENTS.md`, `.claude/rules/*.md`, or `docs/conventions.md`. Reviews against those conventions.

Dispatch all firing agents **in parallel**.

### 3. Sub-agent contracts

Each sub-agent receives:

```yaml
ticket: TICKET-1
track_path: _/tracks/TICKET-1.md
base_sha: <BASE>
head_sha: HEAD
impact_files: [...]
project_profile: <_/sdlc.config.json snapshot>
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

> 1 CRITICAL finding must be addressed before advancing to /sdlc-pr.

## Findings — code-review-agent
...

## Findings — security-review-agent
...

## Findings — standards-review-agent
...
```

### 5. Apply fixes (interactive)

Group findings by severity and ask the user which to address now vs defer:

- CRITICAL → always apply now (the gate).
- HIGH → recommend applying; user can defer with explicit acknowledgement.
- MEDIUM/LOW → user's call.

When applying:
- Make minimal, focused edits.
- After each fix, re-read the relevant file to confirm.
- Don't auto-commit. The user batches commits via the `commit-work` skill or `/sdlc-pr` runs `commit-work` itself.

### 6. Update the track

- Append journal row: `Review pass — 1 CRITICAL applied, 2 HIGH applied, 1 HIGH deferred (logged in <followup>); 9 MEDIUM, 8 LOW.`
- Update "Where we at": next step is `/sdlc-pr <TICKET>`.
- If CRITICAL findings remain unaddressed → set `status` back to `in_progress` and **refuse** to advance the cycle.

### 7. Report

```
Review complete — _/recordings/TICKET-1.review.md
1 CRITICAL applied · 2 HIGH applied · 1 HIGH deferred · 11 MEDIUM/LOW remaining
Next: /sdlc-pr TICKET-1
```

## Hard rules

- Never declare the review "pass" with unaddressed CRITICAL findings.
- Sub-agents run in parallel, never sequentially.
- The security sub-agent is mandatory under `--strict` and when the file-path heuristic matches.
- Don't fabricate findings to "look thorough". If a sub-agent has nothing in a severity bucket, write `0` and move on.
- Never auto-commit fixes. The user commits when ready.
- Pre-existing issues outside the diff are **out of scope** unless the user explicitly asks to expand the review. Report them as informational notes, never as blocking findings.
