# What `/sdlc-init` detects

The init command profiles a host JS/TS project once and writes `_/sdlc.config.json`. Every subsequent `/sdlc-*` command reads that file instead of re-scanning. This document is the source of truth for what the init command looks at and how it resolves each field.

## Files scanned (read-only)

| Source | Used to populate |
| ------ | ---------------- |
| `package.json` (root) | `scripts.*`, `project.package_manager`, `project.node_version`, `project.workspaces` |
| `.nvmrc` | `project.node_version` (preferred over `package.json:engines.node`) |
| `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` / `bun.lockb` / `bun.lock` | `project.package_manager` fallback |
| `turbo.json` | monorepo detection, task list |
| `nx.json` | Nx monorepo detection |
| `pnpm-workspace.yaml` | pnpm workspaces |
| `lerna.json` | Lerna monorepo detection |
| `apps/*/package.json` and `packages/*/package.json` | Workspace overrides for scripts |
| `playwright.config.{ts,js,mjs,cjs}` (anywhere) | `playwright.present`, `playwright.config`, `playwright.base_url` |
| `.github/workflows/*.yml` | `ci.workflows`, `ci.required_checks` |
| `.github/pull_request_template.md` | `git.pr_template` |
| `tsconfig.json` | typecheck fallback |
| `biome.json` / `.eslintrc*` / `.prettierrc*` | lint fallback |
| `.env.example`, `.env.dist`, `.env.test` (existence only) | flagged in summary |
| `CLAUDE.md` / `AGENTS.md` / `.claude/rules/*.md` / `docs/conventions.md` | enables `standards-review-agent` later |

## Field resolution

### `project.package_manager`

Priority:

1. `package.json:packageManager` (canonical when present).
2. Lockfile presence:
   - `bun.lockb` or `bun.lock` → `bun`
   - `pnpm-lock.yaml` → `pnpm`
   - `yarn.lock` → `yarn`
   - `package-lock.json` → `npm`
3. Default: `npm`.

### `project.node_version`

Priority:

1. `.nvmrc` contents.
2. `package.json:engines.node` (parse range, take the floor).
3. `null` if neither.

### `project.type`

- `monorepo` if any of `turbo.json`, `nx.json`, `pnpm-workspace.yaml`, `lerna.json`, or `package.json:workspaces` is present.
- `single-app` otherwise.

### `project.workspaces`

- From `package.json:workspaces` (array form).
- From `pnpm-workspace.yaml:packages`.
- From `turbo.json` patterns when explicit.

### `scripts.*`

Map common script aliases to canonical phases.

| Phase | Source order |
| ----- | ------------ |
| `dev` | `scripts.dev` → `scripts.start` |
| `build` | `scripts.build` |
| `lint` | `scripts.lint` → `scripts["lint:fix"]` (read-only invocation: just `lint`) |
| `typecheck` | `scripts.typecheck` → `scripts["check-types"]` → `scripts.tsc` → `tsc --noEmit` if `tsconfig.json` exists |
| `test` | `scripts.test` |
| `pipeline` | `scripts.pipeline` → `scripts.ci` → `scripts.check` → `null` (commands chain individually when absent) |

Resolved values are always full command strings ("`npm run lint`"), not just the script name. They are package-manager-aware.

### `playwright.*`

- Search for `playwright.config.{ts,js,mjs,cjs}` from repo root downward (depth ≤ 4).
- If found:
  - `present: true`
  - `config: <path>`
  - `base_url`: parse the config file, look for `baseURL` in `use:` block.
- If not found: `present: false`, others `null`.
- `credentials` always defaults to `_/demo/credentials.json` (the user fills in the actual file).

### `git.default_branch`

Priority:

1. `git symbolic-ref refs/remotes/origin/HEAD` (parse the trailing branch name).
2. `git config --get init.defaultBranch`.
3. Current branch (if it's `main` / `master` / `trunk` / `develop`).
4. Ask the user.

### `git.branch_pattern`

- If recent commits match `feat/PROJ-123` / `fix/PROJ-123` pattern → `<type>/<TICKET-ID>`.
- If `feature/PROJ-123` → `feature/<TICKET-ID>`.
- Else → `null` (the user can fill it in by hand).

### `git.pr_template`

- Path to `.github/pull_request_template.md` if it exists; else `null`.

### `ci.workflows` / `ci.required_checks`

- All `.github/workflows/*.yml` files → `ci.workflows`.
- Parse each `jobs.*.name` → `ci.required_checks` (best-effort; some jobs are matrix-named).

### `ticketing.*`

Detection:

1. If commit messages on the current branch match `^[A-Z]+-\d+` consistently → `prefix` = the captured prefix, `system: "jira"` by default.
2. If `.github/ISSUE_TEMPLATE/` exists with GitHub-style templates → `system: "github"`.
3. If `.linearignore` or commits reference `LINEAR-` prefixes → `system: "linear"`.
4. Otherwise → ask the user to pick or set `none`.

`mcp` is populated when the user confirms (defaults: `atlassian` for jira, `linear` for linear, none for github/none).

### `spec.*`

Always ask the user:

- "Where do feature specs live?"
  - `ticket-references-path` — specs live in arbitrary paths, tickets carry the path reference.
  - `fixed-dir` — specs live in a known directory; the user provides the path.
  - `freeform` — no formal specs; `/sdlc-intake` falls back to user descriptions.

### `conventions.*`

- `commit_style`: scan recent commits for Conventional Commits compliance (`<type>(<scope>): <summary>` ratio > 50%) → `conventional`. Else `freeform`. Always offered; user can override.
- `track_dir`, `demo_dir`, `recordings_dir`: defaults to `_/tracks`, `_/demo`, `_/recordings`. User can change.

## Handling missing signals

A missing signal becomes `null` or `"none"` — never an invented value. The init summary surfaces "Missing signals" so the user knows what `_/sdlc.config.json` lacks. Examples:

- No `.nvmrc` → `project.node_version: null`, surfaced as "consider adding .nvmrc to pin Node version".
- No Playwright config → `playwright.present: false`, surfaced as "validation phase will be skipped unless Playwright is added".
- No PR template → `git.pr_template: null`, surfaced as "PR body will use the built-in template".
- No ticketing system → `ticketing.system: "none"`, surfaced as "intake will run in freeform mode".

## Re-running `/sdlc-init`

Re-running diffs detected vs on-disk values:

- **Conflict** (value changed) → ask whether to update.
- **Added** (new signal found) → ask whether to apply.
- **Removed** (signal disappeared) → ask whether to null the field.

User-edited fields are respected by default; the user only sees prompts when init has higher-confidence info to offer. `--force` overwrites without prompting.
