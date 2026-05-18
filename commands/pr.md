---
description: Create the GitHub PR for the current ticket. Re-runs the pipeline gate, builds the PR body from the track frontmatter (AC checklist + links to validation + review reports), pushes the branch, and writes the PR URL back to the track.
argument-hint: "<ticket-id> [--draft] [--reviewers user1,user2]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /agentic-sdlc:pr

Phase 5 of the cycle. Turns the track + branch into a PR with a body the reviewer doesn't need to ask questions about.

## Arguments

- `$1` (required): ticket ID.
- `--draft` (optional): open as a draft PR. Default is ready-for-review.
- `--reviewers <list>` (optional): comma-separated GitHub usernames to request review from.

## Preconditions

1. `_/sdlc-config.md` exists (frontmatter + Notes body).
2. `_/tracks/<TICKET>.md` exists, status is `in_review`.
3. `_/recordings/<TICKET>.review.md` exists; has no unaddressed CRITICAL findings.
4. `_/recordings/<TICKET>.validation.md` exists OR the track has `demo.applicable: false`.
5. `gh auth status` is logged in.
6. The current branch matches `frontmatter.branch` (or no branch is set, in which case create from `conventions.branch_pattern` in `_/sdlc-config.md`).

## Workflow

### 1. Re-run the pipeline gate

Resolve the pipeline command (same order as `/agentic-sdlc:implement`: `overrides.pipeline_command` → `package.json:scripts.pipeline|ci|check` → chained `lint && typecheck && test && build`). Run it. On failure → abort with the output. The user fixes and re-runs.

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

Render `templates/pr-body.template.md` from the track. **Inline** all reviewer-facing content — never reference paths under `_/` (track files, recordings, scenarios, demos). Those artifacts are local-only by design; reviewers cannot open them and even mentioning the paths leaks the working directory layout.

- **Summary**: derived from track's "Where we at on this track" paragraph + a one-line "what this PR does" generated from the title + commits. Do not quote the file path of the track.
- **Ticket link**: built from `_/sdlc-config.md:ticketing` (Jira URL pattern, Linear URL, GitHub issue, or `None`).
- **AC checklist**: for each `requirement` in `acs[].requirements[]`:
  - `[x] <text>` if `status: done`
  - `[ ] <text>` (with `_(blocked)_` suffix) if `status: blocked`
  - `[~] <text> (n/a)` if `status: na`
- **Validation**: inline the outcome line ("✅ N passed · M failed · K skipped") and the per-requirement table from the local validation report. Inline the console/network defects table if non-empty, else write `_No console errors or network 4xx/5xx detected._`. **Never** link to `_/recordings/<TICKET>.validation.md`. The demo .webm is not referenced in the body; if the user wants to share it, attach via `gh pr comment` after the PR is open — and even then, upload the file as a GitHub attachment, don't quote the local path.
- **Review**: inline the consolidated severity table (CRITICAL/HIGH/MEDIUM/LOW counts per sub-agent) and one line stating resolution ("1 CRITICAL applied · 2 HIGH applied · 1 HIGH deferred to <follow-up>"). **Never** link to `_/recordings/<TICKET>.review.md`.
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

Title format derives from the track's commit type (feat / fix / refactor / chore / docs) and the ticket id. If `ticketing.system: "none"` in `_/sdlc-config.md` → omit the `(<TICKET>)` scope.

### 6. Update the track

- `frontmatter.pr` → the PR URL.
- `frontmatter.status` → `in_review`.
- Append journal row: `PR opened: <url>. Awaiting review.`
- Update "Where we at": "PR open; waiting for review. Run `/agentic-sdlc:pr-comments <PR>` to walk reviewer threads."

### 7. Report

```
PR opened: https://github.com/<org>/<repo>/pull/123
Title: feat(TICKET-1): Add prices grid to customer page
Status: ready for review · 7/7 requirements done · 0 CRITICAL findings
Next:
  - /agentic-sdlc:pr-comments 123 — when reviewers (human or bot) comment
  - /agentic-sdlc:revalidate TICKET-1 — once the PR is approved and CI is green, before merge
```

## Hard rules

- Pipeline must pass before opening the PR. No exceptions.
- Never open a PR with unaddressed CRITICAL review findings.
- Never `--force` push; never push to the resolved default branch.
- The PR body must be derived from the track — don't paraphrase the AC table; quote it. Reviewers need to see the same text the implementer worked from.
- **Never expose the existence of `_/` artifacts on any github-visible surface** — no `_/tracks/...`, `_/recordings/...`, `_/demo/...`, `_/sdlc-config.md`, or any other path under `_/` in the PR title, PR body, commit messages, or PR comments. Inline the content (tables, summaries) instead of linking to local files. The working directory is a private contract between the user and these commands; reviewers must never see it referenced.
- Don't auto-add `[skip ci]` to commits.
- Don't assign reviewers without explicit `--reviewers` flag — different teams have different ownership conventions.
- If the GitHub repo lacks a PR template at `.github/pull_request_template.md`, just use the `templates/pr-body.template.md` render. Don't try to create one for the user.
