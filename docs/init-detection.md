# Detection rules

`/kosmo-sdlc:init` writes `_/sdlc-config.md` once. The frontmatter captures **user decisions** (ticketing system, spec convention, validation strategy, branch pattern, commit style); the Notes body captures **project-specific guidance** the user wants every agent to read.

Project state that's cheap to re-read — package manager, Node version, default branch, root scripts, CI workflows — is **not** persisted. Each `/kosmo-sdlc:*` command re-detects it at use site. This way the config never goes stale, and `/kosmo-sdlc:init` doesn't have to be re-run after a `package.json` change.

This document describes both halves: what init asks (for the persisted decisions), and what each command re-detects (for the ephemeral state).

## What init asks the user

The wizard pre-fills every option with a detected default and asks the user to confirm. Questions, in order:

| Field | Detected from | Options |
| --- | --- | --- |
| `ticketing.system` | recent commit prefixes (`^[A-Z]+-\d+`), `.github/ISSUE_TEMPLATE/`, `.linearignore` | jira / linear / github / none |
| `ticketing.prefix` | most common commit prefix in last 50 commits (≥ 5 hits) | free text |
| `ticketing.mcp` | derived from system (jira → atlassian, linear → linear) | free text or null |
| `spec.convention` | not detected — always asked | ticket-references-path / fixed-dir / freeform |
| `spec.default_dir` | only for `fixed-dir` | free text |
| `validation.mode` | `playwright.config.*` exists → `project-playwright`; else → `standalone-playwright` (recommended) | project-playwright / standalone-playwright / manual |
| `validation.base_url` | parsed from `playwright.config.*:use.baseURL` | free text, default `http://localhost:3000` |
| `conventions.branch_pattern` | recent branch names matching `<word>/<TICKET>` | free text, default `<type>/<TICKET>` |
| `conventions.commit_style` | last 50 commits' Conventional Commits compliance ratio | conventional / freeform |
| **Notes body** | not detected | freeform multi-line text |

The "Notes for agents" body is the killer feature: anything the user types lands verbatim under the heading and is read by every command going forward. Use it for "use `pnpm api:dev` in apps/api", "PR template's AC section is rendered, don't hand-edit", etc.

## Validation modes

| Mode | What it means | Host project needs |
| --- | --- | --- |
| `project-playwright` | sdlc reuses the host project's `playwright.config.*` and its installed `playwright`/`@playwright/test` dep. | `playwright.config.*`, installed Playwright dep, dev server at `base_url`. |
| `standalone-playwright` | sdlc installs Playwright on its own (one-off `npx --yes playwright@latest install --with-deps chromium`) and runs the generated `_/demo/<TICKET>.spec.mjs` via plain `node`. | A reachable `base_url`. **Nothing else.** |
| `manual` | Validation phase is skipped (`na` report). | — |

`standalone-playwright` is the mode that lets sdlc produce Playwright video demos for projects that never adopted Playwright themselves. It was the missing piece in earlier versions — fixed by decoupling "can we drive a browser" from "does the project have a playwright config".

## What each command re-detects at use site

These values are NOT in `_/sdlc-config.md`. Every command runs the same resolution at the start of its workflow, so the answers stay fresh.

### Default branch

1. `overrides.default_branch` in `_/sdlc-config.md` if set.
2. `git symbolic-ref refs/remotes/origin/HEAD` → parse trailing branch name.
3. `git config --get init.defaultBranch`.
4. Ask the user.

Used by `/kosmo-sdlc:review`, `/kosmo-sdlc:pr`, the impl/pr agents.

### Package manager

1. `package.json:packageManager` field (canonical when present).
2. Lockfile presence:
   - `bun.lockb` / `bun.lock` → bun
   - `pnpm-lock.yaml` → pnpm
   - `yarn.lock` → yarn
   - `package-lock.json` → npm
3. Default: npm.

Used to prefix all `scripts.*` invocations.

### Pipeline command

1. `overrides.pipeline_command` in `_/sdlc-config.md` if set.
2. `package.json:scripts.pipeline`.
3. `package.json:scripts.ci`.
4. `package.json:scripts.check`.
5. Chain `lint && typecheck && test && build`, each resolved from `package.json:scripts.*`. `typecheck` falls back to `tsc --noEmit` when `tsconfig.json` exists and no script is defined. Skip steps whose script doesn't exist.

**Lint-coverage guarantee.** Whichever form is chosen, the gate must run lint — otherwise CI fails on style/format issues that the local gate silently skipped. After resolving forms 1–4, inspect the chosen command for a lint/format step (a `lint`/`format` script, or `eslint` / `biome` / `prettier` in the script body). If it's absent, append the detected lint step so the gate always lints:

- `<pm> run lint` if a `lint` script exists, else
- `biome check .` (when `biome.json` present) / `eslint .` (when `.eslintrc*` present) / `prettier --check .` (when `.prettierrc*` present).

The chained fallback (form 5) already includes lint, so the guarantee only matters when a `pipeline`/`ci`/`check` script or a pinned `pipeline_command` was selected. If **no** lint capability exists at all (no `lint` script and no eslint/biome/prettier config), the gate can't catch style failures — surface this once at `init` (see [init](../commands/init.md) Missing signals) rather than silently shipping a gate that lints nothing.

Used by `/kosmo-sdlc:implement` per-requirement gate and by `/kosmo-sdlc:pr` re-gate.

### Dev command

1. `overrides.dev_command` in `_/sdlc-config.md` if set.
2. `package.json:scripts.dev`.
3. `package.json:scripts.start`.

Used by `/kosmo-sdlc:validate` when it needs to launch the dev server before running Playwright.

### Project type / workspaces

Cheap to re-read on the rare command that needs it (intake's "where's the closest precedent" survey, implement's plan-against-§6):

- `monorepo` if any of `turbo.json`, `nx.json`, `pnpm-workspace.yaml`, `lerna.json`, or `package.json:workspaces` is present. Workspaces array comes from the matching source.
- `single-app` otherwise.

### CI workflows / required checks

Read `.github/workflows/*.yml` on demand (in `/kosmo-sdlc:revalidate` and when the impact set heuristic in `/kosmo-sdlc:review` wants to compare). Parse `jobs.*.name` for required check names. Best-effort — some matrices have dynamic names.

### Standards-review eligibility

`standards-review-agent` fires in `/kosmo-sdlc:review` when any of these exist: `CLAUDE.md`, `AGENTS.md`, `.claude/rules/*.md`, `docs/conventions.md`. Re-checked each run.

### PR template

Existence of `.github/pull_request_template.md` is checked at PR time. If absent, `/kosmo-sdlc:pr` falls back to `templates/pr-body.template.md`.

## Pinned overrides

`overrides.{default_branch,pipeline_command,dev_command}` are escape hatches for cases where detection picks the wrong value:

- Mirrored or shallow clone where `origin/HEAD` doesn't resolve.
- A monorepo where the root `scripts.dev` boots the wrong thing (e.g. a docs site instead of the app).
- Several plausible "pipeline" scripts and the user wants to lock one in.

Leave them null otherwise. Re-detection is the simpler, less-stale answer.

## Re-running `/kosmo-sdlc:init`

Re-running diffs:

- **Frontmatter conflict** (on-disk value differs from detected) → ask whether to update.
- **New high-confidence detection** (e.g. a ticketing prefix that wasn't there before) → ask whether to apply.
- **Notes body** → never touched without explicit confirmation. Append-only mid-wizard if the user adds more.

User-edited fields are respected by default. `--force` overwrites frontmatter without prompting — but still preserves the Notes body.

## Handling missing signals

A missing detection signal stays null. The wizard surfaces what's missing so the user can decide whether to fill it in by hand or leave it for runtime resolution.

Examples:

- No `playwright.config.*` → validation mode defaults to `standalone-playwright` (sdlc handles its own Playwright). The user can still pick `manual` if the project is non-UI.
- No commit prefix → `ticketing.system: "none"`, intake runs in freeform mode.
- No PR template → PR body uses the built-in template; nothing to persist.
- No `.nvmrc` and no `engines.node` → Node version isn't recorded anywhere. Commands trust whatever Node is on the PATH.
