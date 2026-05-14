---
name: sdlc-validate-agent
description: Sub-agent dispatched by /sdlc-cycle for the validate (and revalidate) phases. Drives a two-pass Playwright run — assertions first, demo only on green — and returns a frontmatter delta + a written report.
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# sdlc-validate-agent

## Inputs

- `track_path`: `_/tracks/<TICKET>.md`.
- `project_profile`: `_/sdlc.config.json`.
- `mode`: `validate` (default) or `revalidate` (adds spec-drift detection).

## Job

Follow the [/sdlc-validate](../commands/sdlc-validate.md) workflow:

1. (revalidate only) Compute spec hash, compare against `frontmatter.spec.hash`, surface drift.
2. Generate scenario + Playwright script. No `force: true` clicks.
3. Pass 1 — assertions, headless, no overlays.
4. Pass 2 — demo recording, only if Pass 1 is 100% green.
5. Write `_/recordings/<TICKET>.validation.md` (or `<TICKET>.revalidation.md` in revalidate mode).

## Output

```yaml
demo:
  scenario: _/demo/scenarios/<TICKET>.md
  recording: _/recordings/<TICKET>.<run-id>.webm  # null if assertions failed or --no-demo
  report: _/recordings/<TICKET>.validation.md
acs:
  # requirements may transition done → done (idempotent) or done → in_progress (if a regression surfaced)
phase_log_entry:
  phase: validate
  at: <ISO>
  note: "7/7 pass · 1 console warning · demo recorded."
  outcome: pass
```

Plus a paragraph summary: pass/fail count, console + network defects, demo path, and any requirements that regressed.

## Hard rules

- Two-pass execution. Never record a demo of a broken state.
- No `force: true` on clicks. Real visibility/enabled checks only.
- Credentials only from `_/demo/credentials.json`. Never hardcoded.
- Console errors and network 4xx/5xx fail the report. Warnings surface but don't fail by default.
- If `playwright.present: false`, return `outcome: skipped` and explain in the summary.
- If `demo.applicable: false`, return `outcome: pass` for the assertion phase (delegated to unit tests) with no demo artifact.
