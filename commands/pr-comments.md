---
description: Walk every unresolved review comment on the PR, decide a verdict (Applied / Rejected / Deferred / Acknowledged / Stale / Duplicate), apply code changes when needed, and post a verdict-prefixed reply. Logs each thread to the track's journal.
argument-hint: "[pr-number]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /kosmo-sdlc:pr-comments

Phase 5b of the cycle. Replies start with a single verdict word. Bot comments and human comments follow the same ceremony.

## Arguments

- `$1` (optional): PR number. If omitted, infer from the current branch via `gh pr view --json number`.

## Verdict vocabulary

| Verdict | When to use |
| --- | --- |
| **Applied** | Code change made that addresses the comment |
| **Rejected** | Disagreement; the current behavior is intentional |
| **Deferred** | Valid but out of scope for this PR; logged as follow-up |
| **Acknowledged** | Noted; no code change but no disagreement either |
| **Stale** | Comment is based on outdated state (rebased, refactored, scope changed) |
| **Duplicate** | Already addressed by another comment/thread |

The first word of every posted reply MUST be one of these (capitalized, followed by `.` or ` —`). No hedges before the verdict.

## Preconditions

1. `_/sdlc-config.md` exists (frontmatter + Notes body).
2. A track exists for the current branch (`_/tracks/<TICKET>.md`) — used to log threads back to the journal.
3. `gh auth status` is logged in.

## Workflow

### 1. Resolve PR and repo

```bash
PR=${1:-$(gh pr view --json number --jq .number)}
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
```

If neither produces a number → ask. Don't guess.

### 2. Pull metadata and comment streams in parallel

Single batch:

- `gh pr view "$PR" --repo "$REPO" --json title,body,state,headRefName,baseRefName,isDraft`
- `gh api "repos/$REPO/pulls/$PR/comments" --paginate` — inline review comments
- `gh api "repos/$REPO/pulls/$PR/reviews" --paginate` — review summaries
- `gh api "repos/$REPO/issues/$PR/comments" --paginate` — general PR conversation
- GraphQL `reviewThreads` query — authoritative `isResolved` / `isOutdated` state per thread

Use GraphQL `isResolved` as source of truth. Skip threads where `isResolved == true`.

### 3. Identify unanswered comments

A thread is "unanswered" when **either**:

- `isResolved == false` AND the latest comment is not from the PR author, OR
- `isResolved == false` AND the latest comment is from the PR author but doesn't start with one of the verdict words above.

Capture per thread: thread id, file path, line, comment author, body, root comment's `databaseId`.

### 4. Read the referenced code

For every unanswered comment with a `path`, read the file at the cited line (with offset/limit) **before** deciding. Don't decide from the comment body alone.

If the comment cites a function or symbol that may have moved, grep to find its current location — comments lag behind rebases.

### 5. Decide the verdict for each comment

Decision tree:

1. **Is the technical claim correct given the current code?**
   - No → likely `Stale` or `Rejected`. State your reading of the current code.
   - Yes → continue.
2. **Is the suggested change in scope for this PR?**
   - No (different feature / follow-up) → `Deferred`. Capture in a Linear / Jira / GitHub issue per `ticketing.system`. If `system: "none"`, note as a TODO in the project's tracker.
   - Yes → continue.
3. **Do you agree with the suggested fix?**
   - Yes → `Applied`. Make the code change first, then reply.
   - No, but the underlying concern is real → `Applied` with a different fix, or `Rejected` with a clear "we instead do X because Y".
   - No, and the concern is invalid → `Rejected` with reasoning grounded in the code.
4. **Is it just a description / metadata gripe?** → `Stale` or `Acknowledged`; fix the metadata via `gh pr edit "$PR" --title ... --body ...`. State explicitly whether you updated the metadata.

Group verdicts in a table before posting:

```
| # | File:Line | Author | Verdict | Action |
|---|-----------|--------|---------|--------|
| 1 | path:42   | Copilot| Applied | edit X |
```

Wait for user confirmation before posting unless the user said "auto" up front.

### 6. Apply code changes (only for "Applied")

For each `Applied` row:

- Make the minimal, focused edit.
- If a contracts/shared package is touched, rebuild it and verify no consumer regressed.
- Do not commit or push automatically — let the user batch.

### 7. Post replies

Reply to the **root comment id**. Body must:

- Start with a single verdict word, followed by `.` or ` —`.
- State concretely what changed (or why nothing changed). Reference file paths/lines.
- One short paragraph. No essays. No emojis.

```bash
gh api -X POST "repos/$REPO/pulls/$PR/comments/$ROOT_COMMENT_ID/replies" -f body='Applied. ...'
```

Top-level review summary (no path) → use the issue comments endpoint:

```bash
gh api -X POST "repos/$REPO/issues/$PR/comments" -f body='Applied. ...'
```

Mark `Stale` / `Acknowledged` threads resolved when appropriate (GraphQL `resolveReviewThread` mutation). **Never** auto-resolve `Applied` threads — the original reviewer confirms.

### 8. Log to the track's journal

For each processed thread, append one journal row:

| Date | Phase | Author | Note |
| ---- | ----- | ------ | ---- |
| 2026-05-13 | pr-comments | <reviewer-name> | Applied — fixed Zod schema trim on companyName (`packages/contracts/src/schemas/.../customer.schema.ts:42`) |

Append a phase_log entry: `{ phase: pr-comments, at: <iso>, note: "Processed N threads: X applied, Y rejected, Z deferred", outcome: pass }`.

### 9. Final summary

```
PR #295 — 3 of 5 comments addressed
- Applied: 2 (Zod trim, missing tooLong message)
- Rejected: 1 (controller is intentionally CRUD)
- Deferred: 1 (pricing fields out of scope, tracked in TICKET-XXX)
- Stale: 1 (PR description updated)

Code changes:
  M packages/contracts/src/schemas/.../upsert-customer-service-bundle.dto.schema.ts

Pending: commit + push
Next:
  - commit + push the applied changes (use the `commit-work` skill)
  - /kosmo-sdlc:pr-comments 295 — re-run when new comments arrive
  - /kosmo-sdlc:revalidate TICKET-1 — once the PR is approved and CI is green, before merge
```

## Hard rules

- Never post a reply that doesn't start with a verdict from the table above.
- Never apply a code change without first reading the cited file at the cited line.
- Never auto-commit or auto-push. User commits when ready.
- Never resolve a thread on the reviewer's behalf for `Applied` verdicts.
- Bot and human comments follow the same ceremony. No special-casing.
- If you can't tell whether a comment is resolved (no GraphQL access, ambiguous thread), surface it to the user instead of guessing.
- Don't paraphrase the reviewer's comment back at them. They wrote it. Lead with the verdict and what changed.
- **Never reference `_/` paths in posted replies** (no `_/tracks/...`, `_/recordings/...`, `_/demo/...`, `_/sdlc-config.md`). Those artifacts are local-only and reviewers cannot open them. Cite code files and lines in the actual repo. The track journal (step 8) is internal and stays in the gitignored track — never quote it in a github comment.
