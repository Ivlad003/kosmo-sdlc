# Adapting agentic-sdlc to your project

The plugin defaults assume a "modern full-stack JS monorepo with a Jira ticket and a written spec". Many projects don't fit that profile. This document covers the common variations.

## No Jira / Linear / GitHub Issues

Set `ticketing.system: "none"` in `_/sdlc.config.json` (init asks if it can't detect a system).

- `/sdlc-intake` will prompt for a freeform feature description.
- Track filenames become `feat-<slug>.md` instead of `<TICKET>.md`.
- PR titles drop the `(TICKET)` scope.
- The journal still anchors decisions; there's just no upstream tracker to sync with.

## No spec file

Set `spec.convention: "freeform"`.

- `/sdlc-intake` skips §3 "Spec slice" (writes `TBD`) and pulls scope entirely from the ticket / description.
- `frontmatter.spec` is `null`; `/sdlc-revalidate` skips drift detection.

## Non-monorepo (single-app)

Init detects this when there's no workspaces config:

- `project.type: "single-app"`.
- Scripts come straight from root `package.json`.
- Workspaces array is empty.
- All `/sdlc-*` commands run unchanged.

## No Playwright

Set `playwright.present: false`.

- `/sdlc-validate` and `/sdlc-revalidate` write a `na` report and exit.
- The implementation phase's unit/E2E tests become the only validation gate.
- The stakeholder demo (.webm) is unavailable until Playwright is added; PRs include a "no demo — feature is non-UI / no Playwright setup" note.

To add Playwright later: install it with `npm i -D @playwright/test`, create `playwright.config.ts` with at least `baseURL`, and re-run `/sdlc-init`.

## No CI workflows

Without `.github/workflows/`:

- `ci.workflows: []`, `ci.required_checks: []`.
- `/sdlc-revalidate` skips the CI check.
- The local pipeline (`scripts.pipeline`) becomes the only build gate. Make sure it's comprehensive.

## Different default branch name

Init detects `main` / `master` / `trunk` / `develop` automatically. For non-standard names, set `git.default_branch` manually in `_/sdlc.config.json`.

## Different branch pattern

If your team uses `release/v1.2.x/PROJ-123` or `firstname/PROJ-123`:

- Set `git.branch_pattern` to a template, e.g. `"release/v1.2.x/<TICKET>"` or `"<author>/<TICKET>"`.
- `/sdlc-implement` substitutes `<TICKET>` and `<type>` (and `<author>`, derived from `git config user.name`).

## Different package manager

Bun, pnpm, and Yarn are supported out of the box. The resolved `scripts.*` commands automatically use the right runner.

## TypeScript-only / JavaScript-only / mixed

- TS detected by presence of `tsconfig.json`.
- Typecheck falls back to `tsc --noEmit` when no script is defined.
- Pure JS: `scripts.typecheck` stays `null`; the typecheck step is skipped.

## Languages other than JS/TS

Out of scope for v0.x. The detection logic, Playwright assumptions, and the `commit-work` skill are JS-flavored. A polyglot adaptation is possible but not bundled.

## Pairing with other plugins

`agentic-sdlc` is deliberately minimal. Useful companions:

- **`code-review-graph`** — build a Tree-sitter knowledge graph for token-efficient impact analysis. `/sdlc-review`'s impact-set computation works without it but benefits substantially when it's installed. Pair when reviewing diffs > 30 files.
- **`everything-claude-code`** — bundles `code-reviewer`, `security-reviewer`, and `e2e-runner` sub-agents that `/sdlc-review` and `/sdlc-validate` reference by name. If you don't have them installed, the sub-agents fall back to ad-hoc Agent calls without the specialised prompts.
- **`vibe-testing`** — pressure-test specs before intake. Run it on the spec document before `/sdlc-intake` to catch architectural gaps early.
- **Atlassian / Linear MCP** — improves intake quality dramatically. Without an MCP, intake falls back to user-pasted ticket bodies.

## Manual install (without the plugin marketplace)

If you can't use `/plugin install` (older Claude Code, locked harness):

```bash
git clone https://github.com/code-store-platform/agentic-sdlc ~/.claude/agentic-sdlc

# Symlink the commands
for cmd in ~/.claude/agentic-sdlc/commands/*.md; do
  ln -sf "$cmd" ~/.claude/commands/"$(basename "$cmd")"
done

# Symlink the skill
ln -sf ~/.claude/agentic-sdlc/skills/commit-work ~/.claude/skills/commit-work

# Symlink agents (optional — only needed for /sdlc-cycle)
for agent in ~/.claude/agentic-sdlc/agents/*.md; do
  ln -sf "$agent" ~/.claude/agents/"$(basename "$agent")"
done
```

Re-run after `git pull` to pick up updates.

## Reporting issues

- Open an issue at <https://github.com/code-store-platform/agentic-sdlc/issues>.
- Include: project type (monorepo/single), package manager, Node version, the command that failed, and the `_/sdlc.config.json` (redact paths/secrets).
- For schema validation failures, include the failing frontmatter (redact ticket bodies if confidential).
