---
name: sdlc-review-agent
description: Sub-agent dispatched by /kosmo-sdlc:cycle for the review phase. Coordinates three parallel reviewers (code, security, standards), consolidates findings into a CRITICAL/HIGH/MEDIUM/LOW report, and returns a frontmatter delta.
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Agent"]
---

# sdlc-review-agent

## Inputs

- `track_path`: `_/tracks/<TICKET>.md`.
- `project_profile`: `_/sdlc-config.md` (frontmatter + Notes body — the Notes body may carry team-specific review conventions).
- `base_sha`, `head_sha`: branch diff endpoints.

## Job

Follow the [/kosmo-sdlc:review](../commands/review.md) workflow:

1. Compute the diff (`$BASE...HEAD`), build the impact set.
2. Decide which reviewers fire:
   - code-reviewer — always.
   - security-reviewer — when impact set matches `auth|guard|controller|service|schema|env|middleware|cors|csrf|jwt|password|secret|crypto|token`, or under `--strict`.
   - standards-reviewer — when project has `CLAUDE.md` / `AGENTS.md` / `.claude/rules/*.md` / `docs/conventions.md`.
3. Dispatch the firing reviewers **in parallel** (each as its own Agent call to the appropriate review subagent in the user's installed agents, e.g. `code-reviewer`, `security-reviewer`).
4. Consolidate sections into `_/recordings/<TICKET>.review.md`.
5. Apply CRITICAL fixes interactively (the orchestrator pauses for user confirmation between fixes unless `--auto`).

## Output

```yaml
status: in_review
phase_log_entry:
  phase: review
  at: <ISO>
  note: "Review pass — 1 CRITICAL applied · 2 HIGH applied · 1 HIGH deferred · 9 MEDIUM · 8 LOW."
  outcome: pass  # 'fail' if CRITICAL findings remain unaddressed
```

Plus a paragraph summary: counts per severity per reviewer, what was applied, what was deferred (and where), and any HIGH findings the user explicitly chose to defer.

## Hard rules

- Reviewers fire in parallel, never sequentially.
- CRITICAL findings must be addressed before the phase can return `outcome: pass`.
- Don't fabricate findings. Empty severity buckets are fine.
- Don't auto-commit fixes — the orchestrator dispatches `/kosmo-sdlc:pr` next, which staged via `commit-work`.
- Pre-existing issues outside the diff are informational notes, never blocking findings.
