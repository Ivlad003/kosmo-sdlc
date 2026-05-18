---
description: Re-run validation against the post-review state. Detects spec drift, confirms every requirement still passes, refreshes the demo .webm, and marks the track ready_to_merge when all gates clear.
argument-hint: "<ticket-id>"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /sdlc-revalidate

Phase 6 of the cycle. The "final check before merge". Same engine as `/sdlc-validate`, plus drift detection.

## Arguments

- `$1` (required): ticket ID.

## Preconditions

1. `_/sdlc.config.json` exists.
2. `_/tracks/<TICKET>.md` exists, status is `in_review`.
3. A PR exists (`frontmatter.pr` set), or the user is preparing to merge a branch directly.

## Workflow

### 1. Detect spec drift

If `frontmatter.spec.hash` is set:

- Re-read the spec slice from `frontmatter.spec.path` (or URL).
- Compute its current sha256.
- If different from `frontmatter.spec.hash`:
  - Surface the drift. Show a diff if the spec is local.
  - Ask the user: re-intake the ticket (`/sdlc-intake <TICKET> --refresh`), proceed despite drift, or abort.
  - Append journal row: `Spec drift detected: <old-hash> → <new-hash>. User chose <action>.`

### 2. Re-run validation

Delegate to `/sdlc-validate <TICKET>`:

- Same two-pass execution (assertions then demo).
- Re-uses the existing `_/demo/<TICKET>.spec.mjs` if present; regenerates only if requirements changed since the last validate run.
- Outputs:
  - `_/recordings/<TICKET>.revalidation.md` (assertions report)
  - `_/recordings/<TICKET>.<run-id>.final.webm` (demo, if assertions pass)
  - Updates `_/recordings/<TICKET>.latest.webm` symlink.

### 3. Check PR state (when `frontmatter.pr` is set)

```bash
gh pr view "$PR" --json reviewDecision,mergeable,statusCheckRollup
```

- `reviewDecision`: must be `APPROVED` (or unblocked).
- `mergeable`: must be `MERGEABLE`.
- `statusCheckRollup`: all required checks must be `SUCCESS`.

If any of those fail → don't mark ready_to_merge. Surface the blockers.

### 4. Update the track

If everything passes:

- `frontmatter.status` → `ready_to_merge`.
- Append journal row: `Revalidation pass — N/N requirements green; PR approved; CI green; spec unchanged.`
- Update "Where we at": "Ready to merge. Merge the PR via `gh pr merge <pr>` or the GitHub UI."

If something fails:

- Status stays `in_review`.
- Append journal row with the specific blocker.
- Update "Where we at" to describe the next concrete step (re-implement R1.4, ask reviewer for re-review, wait for CI re-run, etc.).

### 5. Report

On pass:

```
Revalidation complete — _/recordings/TICKET-1.revalidation.md
✅ All 7 requirements pass · ✅ Spec unchanged · ✅ PR approved · ✅ CI green
Status: ready_to_merge
Demo: _/recordings/TICKET-1.20260513-220500.final.webm
Next: gh pr merge <PR> (or merge via the GitHub UI)
```

On blocked — surface the specific blocker and point at its fix command:

```
Revalidation blocked — _/recordings/TICKET-1.revalidation.md
❌ R1.4 regressed after review fixes
Next: /sdlc-implement TICKET-1 --requirement R1.4
```

Other common blockers and their next steps:

- spec drift detected → `/sdlc-intake TICKET-1 --refresh`
- new reviewer comments → `/sdlc-pr-comments <PR>`
- CI still running → wait, then re-run `/sdlc-revalidate TICKET-1`
- review not yet approved → ping reviewers; re-run `/sdlc-revalidate` once approved

## Hard rules

- Never auto-merge the PR. `ready_to_merge` is a state, not an action.
- Never skip drift detection when `frontmatter.spec.hash` is set.
- Never report green when console errors or network 4xx/5xx surfaced during validation.
- If `demo.applicable: false`, the assertions report is the only gate; no demo refresh.
- If the project's CI is still running when revalidate is invoked, wait up to 5 minutes (polling `gh pr checks --watch`) before declaring blocked.
