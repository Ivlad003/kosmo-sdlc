---
description: Implement the requirements in _/tracks/<TICKET>.md. Code, tests, mocks, seeds — and update the track's requirement statuses and journal as each lands.
argument-hint: "<ticket-id> [--requirement R1.1] [--no-pipeline]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /sdlc-implement

Phase 2 of the cycle. Reads the track, plans against §6, implements requirements one by one, runs the pipeline gate, and updates frontmatter as it goes. Refuses to mark a requirement `done` without test evidence when the project has a test script configured.

## Arguments

- `$1` (required): ticket ID matching an existing `_/tracks/<TICKET>.md`.
- `--requirement <id>` (optional): implement only this requirement (e.g. `R1.1`). Otherwise loops through all `not_started` / `in_progress`.
- `--no-pipeline` (optional): skip the per-requirement pipeline run. Use only when debugging the implement command itself.

## Preconditions

1. `_/sdlc.config.json` exists. If not → fail with "run /sdlc-init first".
2. `_/tracks/<TICKET>.md` exists and validates against `schemas/track.schema.json`. If not → fail with "run /sdlc-intake <TICKET> first".
3. Git working tree is clean. If not → ask whether to stash or proceed.

## Workflow

### 1. Read the track

- Parse frontmatter. Extract `acs[].requirements[]`.
- Filter to `status: not_started | in_progress`. Skip `done | blocked | na`.
- Read "Where we at on this track" and §6 Implementation plan to ground next steps.

### 2. Branch hygiene

- If `frontmatter.branch` is null: create one using `git.branch_pattern` from config (default `<type>/<TICKET>`), checkout, push `-u`. Write back to frontmatter.
- If `frontmatter.branch` is set: confirm we're on it. If not, ask user before switching.

### 3. Plan against §6

If §6 is empty or stale (no file paths, no checkbox items):

- Survey the codebase for the closest precedent (similar feature, similar mount point).
- Draft §6 as four sub-lists: Backend / Shared / Frontend / Tests, each with concrete file paths the change will touch.
- Ask the user to confirm the plan before any edits.

If §6 is populated: proceed.

### 4. Implement requirement by requirement

For each requirement in order:

1. Set `status: in_progress`, write track. Append journal row: `Started R1.1 — <text>`.
2. Make the code change. Prefer editing existing files. Add tests in the same commit-able unit.
3. Run targeted verification:
   - Backend requirement → service unit test, controller test if applicable.
   - Frontend requirement → component test (Vitest), and a Playwright assertion will land in `/sdlc-validate`.
   - Shared requirement → typecheck + unit test.
   - Infra/docs requirement → manual check + commit.
4. Run the pipeline gate (unless `--no-pipeline`):
   - If `scripts.pipeline` set → run it.
   - Else chain `scripts.lint && scripts.typecheck && scripts.test && scripts.build`.
   - On failure → keep requirement at `in_progress`, surface the failure, ask user how to proceed.
5. On pipeline pass:
   - Set `status: done`.
   - Set `evidence` to a `file:line` reference or short commit SHA.
   - Append journal row: `Done R1.1 — <evidence>`.

Don't mark `done` if:

- Tests are missing and `scripts.test` is configured.
- Pipeline failed and the user didn't explicitly override.
- The edit is partial (TODO comments, stubbed handlers).

### 5. Update "Where we at"

After each requirement transitions to `done`, rewrite the paragraph:

```
Implementation in progress. 3 of 7 requirements done (R1.1, R1.2, R2.1).
Next: R1.3 (backend) — POST /clients/:id/price-grids endpoint.
```

### 6. Mocks, seeds, fixtures

Per the project's conventions (detected at init):

- If the project has a seed script → ensure new entities have seed coverage before declaring a requirement done.
- If the project uses fixtures → place new ones beside their tests, not in a global directory unless that's the convention.
- Never commit credentials, real customer data, or production-shaped secrets. Use the `_/demo/credentials.json` accounts only.

### 7. Finalize

When all in-scope requirements are `done`:

- Set `frontmatter.status: in_review` (the act of finishing implementation moves us toward review).
- Append journal row: `Implementation complete. <N> requirements done. Next: /sdlc-validate <TICKET>.`
- Print:

```
PICTO-594 — implementation complete
Done: R1.1, R1.2, R1.3, R1.4, R2.1, R2.2, R3.1
Branch: feat/PICTO-594 (12 commits ahead of trunk)
Next: /sdlc-validate PICTO-594
```

## Hard rules

- Frontmatter must stay schema-valid after every write.
- Never mark a requirement `done` without `evidence` set.
- Never disable the pipeline silently. `--no-pipeline` requires the user to type it.
- Never commit `.env` files, real credentials, or files outside the project working tree.
- Always use existing patterns over new abstractions. Three similar lines are better than a premature abstraction.
- Don't auto-push every commit. Push the branch once at branch-creation time; subsequent pushes are the user's call.
