---
description: Playwright-driven validation — generates an assertions report (one expect() per requirement) and, only if assertions pass, a stakeholder demo .webm with overlays. Captures console + network defects.
argument-hint: "<ticket-id> [--no-demo] [--update-baseline]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /sdlc-validate

Phase 3 of the cycle. Two outputs in one command:

1. **Assertions report** (`_/recordings/<TICKET>.validation.md`) — real `expect()` calls per UI requirement; console + network log scan; pass/fail table.
2. **Stakeholder demo** (`_/recordings/<TICKET>.<run-id>.webm`) — narrated overlays, fake cursor, highlights. Recorded **only if assertions pass**.

If `frontmatter.demo.applicable: false` or all requirements have `owner: backend|shared|infra|docs`, the command writes a `na` report and exits. Backend-only changes are validated by `/sdlc-implement`'s test runs, not Playwright.

## Arguments

- `$1` (required): ticket ID.
- `--no-demo` (optional): produce the assertions report but skip the .webm recording.
- `--update-baseline` (optional): refresh saved screenshots used for visual snapshots.

## Preconditions

1. `_/sdlc.config.json` exists, `playwright.present: true`, `playwright.base_url` set.
2. `_/demo/credentials.json` exists (not the template; the real one). If only the template exists → fail with "fill in _/demo/credentials.json first".
3. `_/tracks/<TICKET>.md` exists; at least one requirement has `owner: frontend | mixed`.
4. The dev server is running at `playwright.base_url`. Check via HTTP HEAD; if down, ask before launching.

## Workflow

### 1. Generate the scenario

Build a scenario file at `_/demo/scenarios/<TICKET>.md`:

- One section per AC.
- Each section has: page route, click targets, fields to fill, expected UI elements, and a one-line "Say" narration for the overlay.
- Map every `requirement.id` to an explicit `expect()` step in the scenario.
- Discover selectors live: navigate via Playwright MCP (`browser_navigate`, `browser_snapshot`), prefer accessibility-tree references over text matches, prefer `getByRole`/`getByLabel` over CSS selectors.

Never guess selectors. If a selector can't be verified live, mark the requirement `blocked` in the report and ask the user.

### 2. Render the Playwright script

Write to `_/demo/<TICKET>.spec.mjs` (a node-runnable Playwright script — not a project test, to avoid coupling):

```js
import { chromium, expect } from 'playwright';
// Standard demo helpers (define inline or import from a shared module):
//   ensureStyles, showSection, hideSection, showOverlay, pointAt, demoClick,
//   demoGoto, hideNextjsOverlay, attachConsoleLogger, log
```

Hard requirements for the generated script:

- Read credentials from `_/demo/credentials.json` — never hardcode.
- English locale for navigation; project may be localized but the demo uses `/en/` or equivalent.
- `attachConsoleLogger(page)` immediately after page creation. Capture console errors/warnings, page errors, network 4xx/5xx into the log file.
- Use real waits (`waitFor({ state: 'visible' })`) — **no `force: true` on clicks**. Hidden/disabled elements should fail the report, not be force-clicked through.
- Per-requirement assertions: one `await expect(locator).toBeVisible()` (or appropriate matcher) per `requirement.id`. Wrap in `test.step('<R-id>: <text>', async () => { ... })` for clean report mapping.
- Video recording: `recordVideo` configured on the browser context, but writing only the run that **passes assertions** to `<TICKET>.<run-id>.webm`. Failed runs save to `<TICKET>.<run-id>.failed.webm` for debugging.
- Demo overlays only fire on the second pass (after assertions pass) so the recording shows a clean run.

### 3. Run the script

```
node _/demo/<TICKET>.spec.mjs
```

Two-pass execution:

1. **Pass 1 — assertions** (headless, no overlays, no slow-mo). Drives the report.
2. **Pass 2 — demo recording** (headed or recorded headless, slow-mo on, overlays on). Only runs if Pass 1 was 100% green.

### 4. Produce the assertions report

Write `_/recordings/<TICKET>.validation.md`:

```markdown
# Validation report — TICKET-1

Run id: 20260513-211900
Base URL: http://localhost:3000
Outcome: 7 passed, 0 failed, 0 skipped

## Per-requirement results

| Requirement | Status | Note |
| ----------- | ------ | ---- |
| R1.1 — Open drawer from button       | ✅ pass | `page.getByRole('button', { name: 'Importer une nouvelle grille' })` |
| R1.2 — Drawer renders form fields    | ✅ pass | |
| R1.3 — POST endpoint accepts file    | ✅ pass | covered by unit test in apps/backend/.../price-grids.spec.ts |
| R1.4 — Drawer closes on submit       | ❌ fail | drawer remained open; toast 'Erreur réseau' surfaced |
| R2.1 — Action column renders icons   | ✅ pass | |

## Console / network defects detected

| Severity | Message | Source |
| -------- | ------- | ------ |
| WARN | React Hook useEffect has missing dependency 'priceGrids' | apps/frontend/.../client-prices-grid.tsx:42 |

## Artifacts

- Playwright log: `_/recordings/TICKET-1.20260513-211900.log`
- Trace: `_/recordings/TICKET-1.20260513-211900.zip`
- Failed-run video: `_/recordings/TICKET-1.20260513-211900.failed.webm`
```

### 5. Produce the stakeholder demo

Only if Pass 1 is 100% green:

- Pass 2 runs with overlays, fake cursor, section badges, slow-mo.
- Output: `_/recordings/<TICKET>.<run-id>.webm`.
- Also update a symlink `_/recordings/<TICKET>.latest.webm → <TICKET>.<run-id>.webm`.

### 6. Update the track

- Per requirement: set `evidence` to "validated by `R1.1` in _/recordings/<TICKET>.validation.md" when `evidence` was previously null.
- Append journal row: `Validation pass — 7/7 requirements green; 1 console warning; demo recorded.`
- Update "Where we at": next step is `/sdlc-review <TICKET>`.

If Pass 1 fails:
- Append journal row with the failing requirement ids and the new console/network defects.
- Set the relevant requirements back to `in_progress`. The user re-runs `/sdlc-implement` to fix.

## Hard rules

- No `force: true` on clicks. The demo is not the place to hide UI bugs.
- Credentials only from `_/demo/credentials.json`. Never from inline strings, never from `.env`.
- Console errors and network 4xx/5xx fail the report (warnings are surfaced but don't fail by default; the user can promote them via config).
- The .webm is regenerated only when assertions pass. A demo of a broken state is worse than no demo.
- The Playwright script is generated under `_/`, never under `apps/*/playwright/` or any other project-test directory. The script is throw-away; the report is the artifact.
- When `playwright.present: false` in the config → fail with a friendly "this project has no Playwright setup; the validation phase can be skipped via `--no-demo` and `--no-assertions`, or you can set up Playwright first."
