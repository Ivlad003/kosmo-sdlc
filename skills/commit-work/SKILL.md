---
name: commit-work
description: "Create high-quality git commits: review/stage intended changes, split into logical commits, write clear Conventional Commits messages, and run the project's pipeline gate before each commit. Use when committing within an agentic-sdlc cycle or whenever staging changes."
---

# Commit work

## Goal

Make commits that are easy to review and safe to ship:

- Only intended changes are included.
- Commits are logically scoped (split when needed).
- Commit messages describe **what changed** and **why**.
- The project's pipeline (lint, typecheck, test, build) is green before each commit.

## Inputs

- Single commit or multiple commits? Default to multiple small commits when changes are unrelated.
- Commit style: **Conventional Commits** required.
- Project profile: read `_/sdlc-config.md` if present. Use `overrides.pipeline_command` from its frontmatter if set; otherwise resolve the pipeline command at use site from `package.json:scripts.pipeline|ci|check` (first match), falling back to a chained `lint && typecheck && test && build`.

## Workflow

1. **Inspect the working tree**
   - `git status`
   - `git diff` (unstaged)
   - `git diff --stat` if many changes

2. **Decide commit boundaries**
   - Split by: feature vs refactor · backend vs frontend · formatting vs logic · tests vs production code · dependency bumps vs behavior changes.
   - If changes are mixed within one file, plan to use patch staging.

3. **Stage only what belongs in the next commit**
   - Prefer `git add -p` for mixed changes.
   - Unstage with `git restore --staged -p` or `git restore --staged <path>`.

4. **Review staged changes**
   - `git diff --cached`
   - Sanity checks:
     - No secrets or tokens (run `git diff --cached | grep -i -E 'password|secret|token|api[_-]?key'` and inspect).
     - No accidental debug logging (`console.log`, `dbg!`, `print(` in non-debug paths).
     - No unrelated formatting churn.
     - No commits of files under `_/` (the agentic-sdlc working dir is gitignored, but double-check).
     - No references to `_/` paths inside *staged files* (e.g. a source file mentioning `_/tracks/...` in a comment). The working directory is local-only — code shipped to git must not point at it.

5. **Describe the staged change in 1–2 sentences** before writing the message.
   - "What changed?" + "Why?"
   - If you can't describe it cleanly, the commit is too big or mixed. Go back to step 2.

6. **Run the pipeline gate**
   - If `_/sdlc-config.md` exists and frontmatter has `overrides.pipeline_command` set → run it.
   - Else read `package.json:scripts` and run the first of `pipeline`, `ci`, `check`.
   - Else chain `lint && typecheck && test && build` (each from `package.json:scripts.*`; `typecheck` falls back to `tsc --noEmit` when `tsconfig.json` exists). Prefix every invocation with the detected package manager (npm/pnpm/yarn/bun).
   - Else (no clues at all) → ask the user for the known-good check command.
   - **Don't commit on a red pipeline.** Fix and re-stage.

7. **Write the commit message**
   - Conventional Commits format:
     ```
     <type>(<scope>): <short summary>

     <body — what/why, not implementation diary>

     <footer if needed — BREAKING CHANGE, Refs, Co-authored-by>
     ```
   - Use an editor for multi-line: `git commit -v`.
   - Pass via HEREDOC to preserve formatting.
   - Never use `--no-verify` / `--no-gpg-sign` unless the user explicitly asks. If a hook fails → investigate.
   - Don't amend already-pushed commits. Create a new commit.

8. **Repeat** until the working tree is clean.

## Hard rules

- No `git add -A` / `git add .` blindly.
- No commits of `.env`, lockfiles you didn't intend to bump, large binaries, or build artifacts.
- No "Fix tests" / "Small edits" / "WIP" messages.
- Always run the pipeline gate before each commit (the original `commit-work` skill suggested it; this version enforces it).
- Conventional Commits subject ≤ 72 characters. Body wraps at 100.
- Co-authored-by lines only when explicitly requested. Attribution defaults are user-configured.
- **Never reference `_/` paths in commit messages** — no "see `_/tracks/TICKET-1.md`", no "per `_/recordings/...`", no mention of the track, scenario, or recordings. The agentic-sdlc working directory is local and gitignored; commit messages get pushed to GitHub and must not leak it. Cite code paths, ticket ids, and behavior — not the working dir.

## Deliverable

- Final commit message(s).
- Short summary per commit (what / why).
- Commands used to stage and verify (`git diff --cached`, pipeline output).
