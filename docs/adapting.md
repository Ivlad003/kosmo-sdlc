# Adapting kosmo-sdlc to your project

The plugin defaults assume a "modern full-stack JS monorepo with a Jira ticket and a written spec". Many projects don't fit that profile. This document covers the common variations.

## No Jira / Linear / GitHub Issues

Set `ticketing.system: "none"` in `_/sdlc-config.md` (init's wizard asks; pick "none" when prompted).

- `/kosmo-sdlc:intake` will prompt for a freeform feature description.
- Track filenames become `feat-<slug>.md` instead of `<TICKET>.md`.
- PR titles drop the `(TICKET)` scope.
- The journal still anchors decisions; there's just no upstream tracker to sync with.

## No spec file

Set `spec.convention: "freeform"`.

- `/kosmo-sdlc:intake` skips §3 "Spec slice" (writes `TBD`) and pulls scope entirely from the ticket / description.
- `frontmatter.spec` is `null`; `/kosmo-sdlc:revalidate` skips drift detection.

## Non-monorepo (single-app)

Detected on the fly when there's no workspaces config — nothing to set in `_/sdlc-config.md`. Commands read root `package.json:scripts` directly.

## No Playwright in the project

Set `validation.mode: standalone-playwright` (init's wizard picks this by default when it can't find a `playwright.config.*`). sdlc installs and drives its own Playwright; the host project needs only a reachable `validation.base_url`.

- `/kosmo-sdlc:validate` still runs assertions + records the stakeholder .webm.
- The first invocation runs `npx --yes playwright@latest install --with-deps chromium` if no Playwright binary is on the PATH.
- No `playwright.config.ts` needed in the project.

If the feature is genuinely non-UI (CLI, library, pure backend), pick `validation.mode: manual` instead — the validation phase is skipped and unit/E2E tests from `/kosmo-sdlc:implement` become the only gate.

To switch later: re-run `/kosmo-sdlc:init` and pick a different mode in the wizard, or edit `validation.mode` directly in `_/sdlc-config.md`.

## No CI workflows

Without `.github/workflows/`:

- `/kosmo-sdlc:revalidate` skips the CI check.
- The local pipeline (re-detected from `package.json:scripts.pipeline|ci|check` or pinned via `overrides.pipeline_command`) becomes the only build gate. Make sure it's comprehensive.

## Different default branch name

`/kosmo-sdlc:review` and `/kosmo-sdlc:pr` resolve the default branch via `git symbolic-ref refs/remotes/origin/HEAD` on each run. If that returns the wrong thing (shallow clone, mirrored repo), pin it: set `overrides.default_branch: trunk` (or whatever) in `_/sdlc-config.md`.

## Different branch pattern

If your team uses `release/v1.2.x/PROJ-123` or `firstname/PROJ-123`:

- Set `conventions.branch_pattern` to a template, e.g. `"release/v1.2.x/<TICKET>"` or `"<author>/<TICKET>"`.
- `/kosmo-sdlc:implement` substitutes `<TICKET>`, `<type>`, and `<author>` (from `git config user.name`).

## Different package manager

Bun, pnpm, and Yarn are supported out of the box. Each command re-detects the manager from `package.json:packageManager` or the lockfile and prefixes script invocations correctly.

## TypeScript-only / JavaScript-only / mixed

- TS detected on the fly by presence of `tsconfig.json`.
- Typecheck falls back to `tsc --noEmit` when no `package.json:scripts.typecheck` is defined.
- Pure JS: the typecheck step is skipped silently in the pipeline chain.

## Ticket size: overriding the estimate and tuning the policy

Intake proposes a size (`s`/`m`/`l`) and asks you to confirm it. To override, just pick a different tier at the prompt — your choice wins. Notes:

- **`s`** drops the e2e/demo and (by default) the 3-agent review; the project's quality-gate pipeline rerun is the verification. Choosing `s` always needs explicit confirmation, so it's never applied behind your back.
- **`l`** splits the ticket into one sub-track per AC group. If the auto-grouping isn't right, adjust the groups at the intake prompt before the tracks are written.
- A pre-existing track with no `size` field runs as `m`.

To change the defaults project-wide, add a `sizing` block to `_/sdlc-config.md`:

```yaml
sizing:
  small_max_requirements: 3   # propose 's' only at/below this requirement count
  small_max_acs: 2            # propose 's' only at/below this AC count
  large_min_acs: 5           # propose 'l' at/above this AC count
  small_skips_review: true   # set false to keep the review phase even for small tickets
```

Omit the block entirely to use the built-in defaults shown above.

## Languages other than JS/TS

Out of scope for v0.x. The detection logic, Playwright assumptions, and the `commit-work` skill are JS-flavored. A polyglot adaptation is possible but not bundled.

## Pairing with other plugins

`kosmo-sdlc` is deliberately minimal. Useful companions:

- **Bundled skills** (see [`skills/README.md`](../skills/README.md), [mattpocock-skills.md](mattpocock-skills.md)):
  - **`grill-me`** — **default planning** (brainstorm/design/plan → grill). **`grill-with-docs`** when you want `CONTEXT.md` / ADRs.
  - **`ai-judge` / `/kosmo-sdlc:judge`** — multi-CLI second opinions (e.g. Grok session judged by Claude + Codex).
  - **`tdd`**, **`diagnosing-bugs`**, **`codebase-design`**, **`handoff`** — optional discipline layers.
  - **`ask-kosmo-sdlc`** — router.
  - **Host installs:** `prototype`, `research`, `wayfinder` recommended; full matt `to-spec`→`implement` pipeline only if you are *not* using the cycle for that work.
- **`code-review-graph`** — build a Tree-sitter knowledge graph for token-efficient impact analysis. `/kosmo-sdlc:review`'s impact-set computation works without it but benefits substantially when it's installed. Pair when reviewing diffs > 30 files.
- **`everything-claude-code`** — bundles `code-reviewer`, `security-reviewer`, and `e2e-runner` sub-agents that `/kosmo-sdlc:review` and `/kosmo-sdlc:validate` reference by name. If you don't have them installed, the sub-agents fall back to ad-hoc Agent calls without the specialised prompts.
- **Atlassian / Linear MCP** — improves intake quality dramatically. Without an MCP, intake falls back to user-pasted ticket bodies.

## Manual install (without the plugin marketplace)

If you can't use `/plugin install` (older Claude Code, locked harness):

```bash
# Clone this repo somewhere
SDLC_HOME=~/.claude/kosmo-sdlc
# e.g. git clone https://github.com/Ivlad003/kosmo-sdlc.git "$SDLC_HOME"

# Symlink the commands
for cmd in "$SDLC_HOME"/commands/*.md; do
  ln -sf "$cmd" ~/.claude/commands/"$(basename "$cmd")"
done

# Symlink the skill
ln -sf "$SDLC_HOME"/skills/commit-work ~/.claude/skills/commit-work

# Symlink agents (optional — only needed for /kosmo-sdlc:cycle)
for agent in "$SDLC_HOME"/agents/*.md; do
  ln -sf "$agent" ~/.claude/agents/"$(basename "$agent")"
done
```

Re-run after `git pull` to pick up updates.

## Reporting issues

- Open an issue at https://github.com/Ivlad003/kosmo-sdlc/issues.
- Include: project type (monorepo/single), package manager, Node version, the command that failed, and `_/sdlc-config.md` (redact paths/secrets — the Notes body is fine to share once scrubbed).
- For schema validation failures, include the failing frontmatter (redact ticket bodies if confidential).
