---
name: sdlc-pr-agent
description: Sub-agent dispatched by /kosmo-sdlc:cycle for the PR creation phase. Re-runs the pipeline, commits via the commit-work skill, pushes the branch, opens the PR with a body built from the track frontmatter, and returns a frontmatter delta.
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# sdlc-pr-agent

## Inputs

- `track_path`: `_/tracks/<TICKET>.md`.
- `project_profile`: `_/sdlc-config.md` (frontmatter + Notes body).

## Job

Follow the [/kosmo-sdlc:pr](../commands/pr.md) workflow:

1. Re-run the pipeline command. Resolve it as: `overrides.pipeline_command` → `package.json:scripts.pipeline|ci|check` → chained `lint && typecheck && test && build` (each resolved from package.json scripts; typecheck falls back to `tsc --noEmit` when a `tsconfig.json` exists). Prefix with the detected package manager. Apply the **lint-coverage guarantee** ([init-detection.md](../docs/init-detection.md#pipeline-command)): if the resolved command doesn't already lint, append the detected lint step. Record the command, exit code, and summary line as a journal row (`Pre-PR gate: <command> — exit 0 (<summary>)`); abort the phase if it fails. Do not push or open the PR without a recorded exit-0 gate.
2. Stage and commit any unstaged work via the [commit-work](../skills/commit-work/SKILL.md) skill — multiple Conventional Commits when appropriate, never a kitchen-sink commit.
3. Push the branch with `-u` on first push.
4. Resolve the body style: caller's `--style` flag → `pr.body_style` in `_/sdlc-config.md` → default `standard`. Render the matching template — `templates/pr-body.template.md` for `standard`, `templates/pr-body.concise.template.md` for `concise`. **Inline** the content; never reference paths under `_/` (track files, validation/review reports, scenarios, demos):
   - Local gate: the recorded pre-PR gate outcome as a one-liner (`✅ lint · typecheck · test · build`, or `⚠️ lint not configured` when no lint capability exists). Both styles.
   - AC checklist from `acs[].requirements[]` (both styles).
   - Validation: outcome line in both styles; per-requirement table + console/network defects table only in `standard`. In `concise`, append a "· _N console error(s)_" / "· _N network 4xx/5xx_" suffix to the outcome line when non-zero. No link to the local validation report.
   - Review: resolution line in both styles; severity breakdown table only in `standard`. No link to the local review report.
   - Open §5 questions tagged `DECIDE` surfaced as "Notes for reviewers". In `concise`, omit the section entirely when there are none — don't leave an empty heading.
   - Test plan is `standard`-only.
5. `gh pr create` with the rendered body. Honour `--draft` if passed.

## Output

```yaml
pr: https://github.com/<org>/<repo>/pull/123
status: in_review
phase_log_entry:
  phase: pr
  at: <ISO>
  note: "PR #123 opened. CI pending."
  outcome: pass
```

Plus a one-paragraph summary with PR URL, title, requested reviewers (if any), and the next concrete action (wait for review, or run `/kosmo-sdlc:revalidate` if CI fast).

## Hard rules

- Pipeline must pass before pushing. No exceptions. The gate must include lint, and its exit-0 result must be in the journal before pushing or opening the PR.
- Never push to the resolved default branch (`overrides.default_branch` if set, else `git symbolic-ref refs/remotes/origin/HEAD`). Never `--force` push.
- Never `--no-verify` or skip hooks.
- The PR body must be derived from the track — quote the AC table, don't paraphrase.
- **Never expose `_/` paths on any github-visible surface** (PR title, PR body, commit messages, PR comments). Inline the content; the working directory must remain invisible to reviewers.
- Don't assign reviewers unless explicitly requested. Default is "open and let CODEOWNERS / GitHub UI handle assignment".
- Don't auto-add `[skip ci]` to commits.
- If the repo lacks a PR template, fall back to the style-selected `templates/pr-body.*.template.md`. Don't try to create a `.github/pull_request_template.md` for the user.
- Body style is a rendering choice — quote the AC checklist verbatim from the track regardless of style. `concise` drops sections, never paraphrases them.
