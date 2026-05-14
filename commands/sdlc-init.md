---
description: Detect the host project's commands, Playwright setup, CI, and ticketing system; write _/sdlc.config.json so the other /sdlc-* commands stop hardcoding paths.
argument-hint: "[--force]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# /sdlc-init

One-time per-project bootstrap. Produces `_/sdlc.config.json` (a machine-readable project profile), appends `_/` to `.gitignore`, and seeds `_/demo/credentials.template.json` for the user to fill in. Idempotent — re-running diffs detected values against the on-disk file and asks before overwriting.

## Arguments

- `--force` (optional): overwrite an existing `_/sdlc.config.json` without prompting. Without it, init does a diff and asks for confirmation per-field.

## Workflow

### 1. Pre-flight

- `git rev-parse --is-inside-work-tree` to confirm we're in a git repo. If not, ask whether to `git init` first.
- Check if `_/sdlc.config.json` already exists.
  - If yes and `--force` is not set → read it, then diff detected values against existing fields; prompt only on conflicts.
  - If no → fresh detection.

### 2. Detect project profile

Read these files (read-only, never modify):

| Source | Fields extracted |
| --- | --- |
| `package.json` (root) | `scripts.*`, `packageManager`, `engines.node`, `workspaces` |
| `.nvmrc` | Node version |
| `turbo.json` / `nx.json` / `pnpm-workspace.yaml` / `lerna.json` | Monorepo type, workspace globs |
| `apps/*/package.json`, `packages/*/package.json` | Workspace scripts (override root if app-specific) |
| `playwright.config.{ts,js,mjs,cjs}` anywhere | `playwright.present`, `playwright.config` path, `baseURL` |
| `.github/workflows/*.yml` | `ci.workflows`, `ci.required_checks` (parse `jobs.*.name`) |
| `.github/pull_request_template.md` | `git.pr_template` |
| `tsconfig.json` | typecheck script defaults |
| `biome.json` / `.eslintrc*` / `.prettierrc*` | lint script defaults |
| `.env.example`, `.env.dist`, `.env.test` | Note required env vars exist (don't read values) |

Detection rules:

- **Package manager**: prefer `packageManager` field; else infer from lockfile (`package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb`/`bun.lock` → bun).
- **Scripts**: map common aliases.
  - `dev` → `scripts.dev`, else `start`.
  - `build` → `scripts.build`.
  - `lint` → `scripts.lint`.
  - `typecheck` → `scripts.typecheck`, else `check-types`, else `tsc --noEmit` if `tsconfig.json` exists.
  - `test` → `scripts.test`.
  - `pipeline` → `scripts.pipeline` or `scripts.ci` or `scripts.check`; else `null` (commands chain individually).
- **Default branch**: `git symbolic-ref refs/remotes/origin/HEAD` first; fall back to `git config --get init.defaultBranch`; fall back to current branch if neither resolves.
- **Ticketing**: detect from PR template or recent commit prefix. If commit messages match `^[A-Z]+-\d+`, ticketing.prefix = first match.
  - If no signal → `ticketing.system: "none"`. Ask user if they want to set Jira/Linear/GitHub manually.
- **Spec convention**: ask the user — `ticket-references-path` (specs in arbitrary paths referenced by tickets), `fixed-dir` (e.g. `docs/specs/`), or `freeform` (no specs).

Missing signals must become `null` or empty arrays in the output — never invented.

### 3. Write artifacts

- `_/sdlc.config.json` — populate `templates/sdlc.config.template.json` with detected values.
- `_/demo/credentials.template.json` — copy from `templates/demo-credentials.template.json`. Do not copy if `_/demo/credentials.json` already exists.
- Append the snippet in `templates/gitignore.snippet` to the project's root `.gitignore` if `_/` is not already ignored.
- Create empty `_/tracks/` and `_/recordings/` directories with `.gitkeep` so the layout is visible.

### 4. Report

Print a structured summary the user can scan:

```
agentic-sdlc initialized at /path/to/project

Project:      monorepo (turborepo) · npm · Node 22
Workspaces:   apps/*, packages/*
Scripts:      dev=npm run dev · build=npm run build · pipeline=npm run pipeline
Playwright:   detected at apps/frontend/playwright.config.ts (base_url http://localhost:3000)
Git:          default branch 'trunk' · PR template ✓
CI:           .github/workflows/test.yml (build, lint, test, knip)
Ticketing:    jira (prefix TICKET) via Atlassian MCP
Spec:         ticket-references-path (no default dir)

Missing signals:
  - .nvmrc not found — using engines.node from package.json
  - PR template lacks AC section — /sdlc-pr will append one

Next:
  /sdlc-intake <TICKET-ID> [spec-path]
```

## Hard rules

- Never write outside `_/` and (if needed) the project's root `.gitignore`.
- Never invent values to fill `null` / empty arrays. The schema allows nulls; downstream commands handle them.
- If `_/sdlc.config.json` exists and `--force` not set, do a per-field diff and ask before overwriting any non-null value.
- Validate the final JSON against `schemas/sdlc-config.schema.json` before writing. Fail loudly on schema violation.
- Never read `.env` files for values — only enumerate which env vars exist.
