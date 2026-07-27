# Adapting kosmo-sdlc to your project

Defaults assume a modern full-stack JS project with tickets and a written spec. This page covers common variations.

## No Jira / Linear / GitHub Issues

Set `ticketing.system: "none"` in `_/sdlc-config.md` (init wizard).

- Intake uses a freeform description.
- Tracks are named `feat-<slug>.md`.
- PR titles drop `(TICKET)` scope.
- Journal still records decisions.

## No spec file

Set `spec.convention: "freeform"`.

- Intake skips verbatim spec slice (`TBD`); scope comes from the ticket/description.
- `frontmatter.spec` is `null`; revalidate skips drift detection.

## Non-monorepo

No workspaces config required. Commands read root `package.json:scripts` directly.

## No Playwright in the project

Set `validation.mode: standalone-playwright` (init default when no `playwright.config.*`).

- Validate still asserts + records stakeholder `.webm`.
- First run may `npx playwright@latest install --with-deps chromium`.
- Non-UI work: `validation.mode: manual` (skip Playwright; implement tests are the gate).

## No CI workflows

Revalidate skips remote CI checks; local pipeline is the build gate. Pin with `overrides.pipeline_command` if needed.

## Different default branch / branch pattern

- Pin `overrides.default_branch` if `origin/HEAD` is wrong.
- Set `conventions.branch_pattern` e.g. `"<author>/<TICKET>"`.

## Package managers

npm, pnpm, yarn, bun — re-detected from lockfile / `packageManager`.

## TypeScript vs JavaScript

- TS: typecheck from scripts or `tsc --noEmit`.
- Pure JS: typecheck step skipped when no tsconfig.

## Ticket size policy

Intake proposes `s` / `m` / `l`; you confirm. Optional `_/sdlc-config.md`:

```yaml
sizing:
  small_max_requirements: 3
  small_max_acs: 2
  large_min_acs: 5
  small_skips_review: true
```

## Languages other than JS/TS

Out of scope for v0.x (Playwright + commit-work are JS-flavored). Polyglot use is possible with manual pipeline commands.

## Multi-agent / multi-harness

The track format and `_/sdlc-config.md` are harness-neutral. Install paths differ:

→ **[install.md](install.md)** — Claude Code, Codex, Grok, Cursor, Windsurf, Amp, OpenCode, Aider, Copilot, skills.sh.

## Pairing with other tools

- **Bundled skills** — [skills/README.md](../skills/README.md), [mattpocock-skills.md](mattpocock-skills.md)
  - `grill-me` default planning; `grill-with-docs` for CONTEXT/ADRs
  - `ai-judge` multi-CLI second opinions
  - `kosmo-ralph` autonomous PRD loop (not snarktank skill id `ralph`)
  - `session-close` → Obsidian vault
  - `tdd`, `diagnosing-bugs`, `codebase-design`
- **Host-only matt skills** — `prototype`, `research`, `wayfinder` (do not mix matt `implement` with `/kosmo-sdlc:implement` on the same ticket)
- **code-review-graph** — large-diff review support
- **everything-claude-code** — specialized sub-agents for review/validate names
- **Atlassian / Linear MCP** — richer intake

## Manual install (any agent)

See [install.md](install.md). Short form:

```bash
git clone https://github.com/Ivlad003/kosmo-sdlc.git ~/plugins/kosmo-sdlc
# Then symlink or copy skills/ + follow commands/*.md for your harness
```

## Reporting issues

- https://github.com/Ivlad003/kosmo-sdlc/issues  
- Include: monorepo/single, package manager, Node version, failing command, scrubbed `_/sdlc-config.md`  
