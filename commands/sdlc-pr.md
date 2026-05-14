---
description: Create the GitHub PR for the current ticket. Re-runs the pipeline gate, builds the PR body from the track frontmatter (AC checklist + links to validation + review reports), pushes the branch, and writes the PR URL back to the track.
argument-hint: "<ticket-id> [--draft] [--reviewers user1,user2]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /sdlc-pr

Phase 5 of the cycle. Turns the track + branch into a PR with a body the reviewer doesn't need to ask questions about.

## Arguments

- `$1` (required): ticket ID.
- `--draft` (optional): open as a draft PR. Default is ready-for-review.
- `--reviewers <list>` (optional): comma-separated GitHub usernames to request review from.

## Preconditions

1. `_/sdlc.config.json` exists.
2. `_/tracks/<TICKET>.md` exists, status is `in_review`.
3. `_/recordings/<TICKET>.review.md` exists; has no unaddressed CRITICAL findings.
4. `_/recordings/<TICKET>.validation.md` exists OR the track has `demo.applicable: false`.
5. `gh auth status` is logged in.
6. The current branch matches `frontmatter.branch` (or no branch is set, in which case create from `git.branch_pattern`).

## Workflow

### 1. Re-run the pipeline gate

Run `scripts.pipeline` (or chain lint + typecheck + test + build if `null`). On failure → abort with the output. The user fixes and re-runs.

### 2. Stage and commit if there are unstaged changes

- If `git status` shows changes → invoke the `commit-work` skill to craft Conventional Commits.
- Never `git add -A` blindly. Patch-stage when changes are mixed.
- Don't include the `_/` directory (it's gitignored, but double-check).

### 3. Push the branch

```bash
git push -u origin "$BRANCH"
```

If the branch already exists upstream, push without `-u`.

### 4. Build the PR body

Render `templates/pr-body.template.md` from the track:

- **Summary**: derived from track's "Where we at on this track" paragraph + a one-line "what this PR does" generated from the title + commits.
- **Ticket link**: built from `ticketing.system` config (Jira URL pattern, Linear URL, GitHub issue, or `None`).
- **AC checklist**: for each `requirement` in `acs[].requirements[]`:
  - `[x] <text>` if `status: done`
  - `[ ] <text>` (with `_(blocked)_` suffix) if `status: blocked`
  - `[~] <text> (n/a)` if `status: na`
- **Validation**: link to `_/recordings/<TICKET>.validation.md`. Note that the .webm is not committed; reviewers pull from local `_/`. Optionally upload the .webm as a PR comment attachment (ask the user).
- **Review artifacts**: link to `_/recordings/<TICKET>.review.md` and summary table (CRITICAL/HIGH/MEDIUM/LOW counts).
- **Test plan**: bulleted list reviewers can check. Derived from the requirements + any open §5 questions tagged `DEFERRED`.
- **Notes for reviewers**: §5 `DECIDE` items still open. Things the user wants the reviewer to weigh in on.

### 5. Create the PR

```bash
gh pr create \
  --title "<type>(<TICKET>): <title>" \
  --body "$(cat <pr-body>)" \
  ${DRAFT:+--draft} \
  ${REVIEWERS:+--reviewer "$REVIEWERS"}
```

Title format derives from the track's commit type (feat / fix / refactor / chore / docs) and the ticket id. If `ticketing.system: "none"` → omit the `(<TICKET>)` scope.

### 6. Update the track

- `frontmatter.pr` → the PR URL.
- `frontmatter.status` → `in_review`.
- Append journal row: `PR opened: <url>. Awaiting review.`
- Update "Where we at": "PR open; waiting for review. Run `/sdlc-pr-comments <PR>` to walk reviewer threads."

### 7. Report

```
PR opened: https://github.com/<org>/<repo>/pull/123
Title: feat(TICKET-1): Add prices grid to customer page
Status: ready for review · 7/7 requirements done · 0 CRITICAL findings
Next: /sdlc-pr-comments 123 (when reviewers comment)
```

## Hard rules

- Pipeline must pass before opening the PR. No exceptions.
- Never open a PR with unaddressed CRITICAL review findings.
- Never `--force` push; never push to `default_branch`.
- The PR body must be derived from the track — don't paraphrase the AC table; quote it. Reviewers need to see the same text the implementer worked from.
- Don't auto-add `[skip ci]` to commits.
- Don't assign reviewers without explicit `--reviewers` flag — different teams have different ownership conventions.
- If the GitHub repo lacks a PR template at `.github/pull_request_template.md`, just use the `templates/pr-body.template.md` render. Don't try to create one for the user.
