---
description: Bootstrap kosmo-sdlc for a project. Detects what it can (package manager, scripts, ticketing prefix), then walks the user through a short questionnaire for the decisions that can't be detected (validation strategy, spec convention, ticketing system). Writes _/sdlc-config.md.
argument-hint: "[--force] [--non-interactive]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "AskUserQuestion"]
---

# /kosmo-sdlc:init

One-time per-project bootstrap. Produces `_/sdlc-config.md` — a markdown file with YAML frontmatter (the structured contract every `/kosmo-sdlc:*` command queries) and a free-form **Notes for agents** body (read verbatim by every command, inlined into sub-agent prompts). Also appends `_/` to `.gitignore` and seeds `_/demo/credentials.template.json`.

Idempotent. Re-running diffs detected values against the on-disk file and asks before overwriting.

## Arguments

- `--force` (optional): overwrite an existing `_/sdlc-config.md` without prompting. Without it, init does a diff and asks per-field.
- `--non-interactive` (optional): skip the wizard. Use detected values + safe defaults for everything. Intended for scripted runs; the user should re-run interactively the first time on a new project.

## Why markdown and not JSON

Agents read this file every time. JSON can't carry comments, can't hold the project-specific guidance an agent picking up cold actually needs ("use `pnpm api:dev` not `pnpm dev` when working in apps/api"). Markdown with YAML frontmatter is the same pattern the track files use, so the surface is uniform. The frontmatter is still schema-validated.

## Workflow

### 1. Pre-flight

- `git rev-parse --is-inside-work-tree` to confirm we're in a git repo. If not, ask whether to `git init` first.
- Check whether `_/sdlc-config.md` already exists.
  - Exists and no `--force` → read it, parse frontmatter, treat detected values as proposed updates the user can accept/reject per-field.
  - Doesn't exist → fresh detection + full wizard.
- **MCP and skills availability check.** Probe which optional integrations are reachable and report them in the detection summary (§3). Do not fail init if something is missing — just flag it so the user knows what won't work:
  - **Playwright MCP** (`mcp__plugin_playwright_playwright__browser_navigate`) — required for live selector discovery during `/kosmo-sdlc:validate`. If absent, validate will fall back to static selector generation (lower quality; warn).
  - **Atlassian MCP** — required for Jira ticket fetch in `/kosmo-sdlc:intake`. If the user picked `jira` as the ticketing system but this MCP is absent, flag it: "intake will need the ticket pasted manually."
  - **Linear MCP** — same for Linear.
  - **`kosmo-sdlc:commit-work` skill** — used by `/kosmo-sdlc:implement`, `/kosmo-sdlc:review`, and `/kosmo-sdlc:pr` as the default commit command. If the skill registry doesn't list it, warn: "the default commit command (`commit-work`) is unavailable — you may want to pick a custom commit command during setup."

### 2. Detect what we can (silent pass)

Quick read-only scan. Nothing is written yet; values feed wizard defaults.

| Source                                                                   | Used to suggest                                                |
| ------------------------------------------------------------------------ | -------------------------------------------------------------- |
| `package.json` (root)                                                    | `scripts.*` map, `packageManager` field                        |
| `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` / `bun.lock(b)`     | Package manager fallback                                       |
| `turbo.json` / `nx.json` / `pnpm-workspace.yaml` / `lerna.json`          | Monorepo flag, workspace globs                                 |
| `apps/*/package.json`, `packages/*/package.json`                         | Per-workspace scripts (for the Notes body)                     |
| `playwright.config.{ts,js,mjs,cjs}` (depth ≤ 4)                          | `validation.mode` default + `validation.base_url`              |
| `.github/workflows/*.yml`                                                | List of workflows + jobs (printed for the user, not persisted) |
| `.github/pull_request_template.md`                                       | Existence flag (printed)                                       |
| `tsconfig.json`, `biome.json`, `.eslintrc*`, `.prettierrc*`              | Lint/typecheck capability (printed)                            |
| recent commit prefixes (`git log --oneline -50`)                         | `ticketing.prefix` guess (`^[A-Z]+-\d+`)                       |
| recent branch names                                                      | `conventions.branch_pattern` guess                             |
| `CLAUDE.md` / `AGENTS.md` / `.claude/rules/*.md` / `docs/conventions.md` | Standards-review eligibility (printed)                         |

Detection rules:

- **Package manager** → `package.json:packageManager` first; lockfile fallback (`bun.lock(b)` → bun, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm); default npm.
- **Validation mode** → `project-playwright` if a `playwright.config.*` is found; else default to `standalone-playwright` (sdlc can drive Playwright on its own — the project doesn't need any setup to get demos).
- **`base_url`** → parsed from the host `playwright.config.*` `use.baseURL` when present; else null (the wizard asks).
- **Ticketing prefix** → most-common `^[A-Z]+-\d+` prefix across the last 50 commits, if ≥ 5 hits.
- **Branch pattern** → if recent branches match `feat/<TICKET>` / `fix/<TICKET>` consistently → `<type>/<TICKET>`; else null.
- **Lint capability** → a `lint`/`format` script, or `biome.json` / `.eslintrc*` / `.prettierrc*`. The pre-PR gate appends lint when the resolved pipeline doesn't already run it (lint-coverage guarantee, see [init-detection.md](../docs/init-detection.md#pipeline-command)); if none of these exist, the gate can't catch style/format failures CI may enforce — warn in Missing signals.

Missing signals stay null. Detection never invents values.

### 3. Print the detection summary

Before the wizard, show the user what was found so they can answer the questions in context:

```
Detected
--------
Repo:         monorepo (turborepo) · npm · root scripts: dev, build, lint, typecheck, test, pipeline
Workspaces:   apps/*, packages/*
Playwright:   apps/frontend/playwright.config.ts · baseURL http://localhost:3000
CI:           .github/workflows/test.yml (build, lint, test, knip)
PR template:  .github/pull_request_template.md
Standards:    CLAUDE.md present (standards-review will fire on review)
Ticketing:    recent commits show TICKET-### prefix (12 of last 50)
Branch:       recent branches use <type>/<TICKET> pattern
```

If something key is missing, call it out:

```
Missing signals
---------------
- no playwright.config.* found — validation will default to standalone-playwright
  (sdlc installs and drives its own Playwright; project needs only a base_url)
- no commit prefix detected — ticketing will default to "none" unless you set it
- no lint capability found (no lint/format script, no eslint/biome/prettier config) —
  the pre-PR gate can't catch style/format failures; CI may still reject the PR on them

MCP / skills
------------
✅ Playwright MCP        — live selector discovery in validate
✅ kosmo-sdlc:commit-work skill
⚠️  Atlassian MCP absent  — intake will need ticket body pasted manually (if using Jira)
⚠️  Linear MCP absent     — intake will need ticket body pasted manually (if using Linear)
```

### 4. Walk the wizard

Use `AskUserQuestion` for each decision. Pre-fill each question's first option with the detected default and tag it `(Recommended)`. Skip a question only when detection produced a high-confidence value AND `--non-interactive` is set.

Questions, in order:

0. **Track file visibility.** Ask whether to add `_/` to `.gitignore`.
   - `gitignore _/` *(Recommended)* — track files, recordings, and credentials stay local. Teammates run their own `/kosmo-sdlc:intake` per branch. Best for teams where tickets are per-developer.
   - `commit _/tracks/ only` — track files are committed (useful for async review or shared branches); recordings and `_/demo/credentials.json` are still gitignored.
   - `commit everything in _/` — full transparency; credentials must be managed externally (warn the user that `_/demo/credentials.json` will be committed).

   Store the answer as `tracks.gitignore: true|partial|false` in the config frontmatter. The write-artifacts step (§5) acts on this value.

1. **Ticketing system.** Options: `jira`, `linear`, `github`, `none`. If the user picks jira/linear, follow up for the prefix (free text, default = detected) and MCP server name (free text, default = `atlassian` for jira, `linear` for linear, null otherwise).

2. **Spec convention.** Options:
   - `ticket-references-path` — specs live in arbitrary paths; tickets carry the path. *(Recommended for teams with a docs/specs hierarchy.)*
   - `fixed-dir` — specs live in one directory; follow-up asks for the path.
   - `freeform` — no formal specs; intake will pull scope from the ticket / description alone.

3. **Validation strategy.** Options:
   - `project-playwright` — reuse host project's `playwright.config.*`. *(Recommended when a config is detected.)*
   - `standalone-playwright` — sdlc installs and drives its own Playwright against `base_url`. The project doesn't need any Playwright setup. *(Recommended when no config is detected but the project has a browsable UI.)*
   - `manual` — skip the validation phase. *(For backend-only projects, CLIs, libraries.)*

   Follow-up for the first two: `base_url` (free text, default = detected or `http://localhost:3000`).

4. **Branch pattern.** Free text. Default = detected pattern or `<type>/<TICKET>`. Empty = null (the user lives without it).

5. **Commit style.** Options: `conventional` (default — implies `feat/fix/refactor/...` prefixes), `freeform`.

6. **Commit strategy.** How should the implement and review phases commit code changes? Three strategies:

   - **`skill`** *(Recommended)* — invoke a named Claude Code skill. Follow-up: skill name (default `commit-work`). The skill handles staging, message drafting, and safety checks. Works out of the box when `commit-work` is installed; any other installed commit-style skill is equally valid.
   - **`command`** — run a shell command. Follow-up: the command string (e.g. `git commit -S`, `cz commit`, `git-crypt-commit`). Use `{{MESSAGE}}` in the command as a placeholder for the agent-drafted message. The agent stages only the files for that unit of work before running it.
   - **`prompt`** — give the agent natural-language commit instructions and let it decide how to stage and message. Follow-up: free-text (multi-line). Examples: "group frontend and backend changes into separate commits", "always sign off with `Signed-off-by:`", "write messages in Ukrainian", "never mix test files with source files in the same commit". The agent reads these instructions verbatim before every commit and applies them.

   Store as `conventions.commit` in the config frontmatter (`via`, plus `skill` / `command` / `prompt` — null the unused two). If `commit-work` is unavailable (flagged in the MCP/skills check above), pre-select `command` with `git commit` as the recommended fallback and note that the skill can be enabled later.

7. **PR body style.** Options:
   - `standard` *(Recommended)* — full body with the AC checklist, per-requirement validation table, console/network defects, review severity breakdown, test plan, and reviewer notes. Best when reviewers want to verify everything inline.
   - `concise` — one-line summary, ticket link, validation + review outcome lines, AC checklist only. Best when ACs are long and the per-requirement tables would dominate the PR.

   Per-PR override is always available via `/kosmo-sdlc:pr <TICKET> --style <name>`.

8. **Session token budget (optional).** Soft max tokens for a session / Ralph run. Options: skip (null), `100000`, `200000`, `400000`, or free number. Store as `session.max_tokens`. Default `on_limit: handoff`.

9. **Obsidian vault for handoff/memory (optional).** Path to local clone of personal vault (default remote `https://github.com/Ivlad003/obsidian-personal`). Empty = skip. Store under `session.vault.path`; `work_root: Work`; project name defaults to workspace folder.

10. **Anything else the agents should know?** Free text (multi-line). Whatever the user writes lands in the `# Notes for agents` body verbatim. Examples to suggest if they hesitate:
   - per-workspace dev commands
   - env vars the agents shouldn't read but should know exist
   - flaky tests + acceptable retry counts
   - ticketing conventions ("WIP: prefix = draft", etc.)

If the user skips a free-text question, the body stays as the template's placeholder (`_No project-specific notes yet…_`).

9. **Per-phase prompt overlays** (optional). Do any phases need team-specific instructions appended to the generic phase prompt?

   Ask first: "Do any phases need custom instructions beyond the Notes body above? (y/n — press Enter to skip)"

   If the user answers yes (or types anything non-empty), ask one free-text question per phase, each skippable by pressing Enter:
   - "Custom instructions for the **intake** phase? (Enter to skip)"
   - "Custom instructions for the **implement** phase? (Enter to skip)"
   - "Custom instructions for the **review** phase? (Enter to skip)"
   - "Custom instructions for the **validate** phase? (Enter to skip)"

   Suggest examples inline to help the user answer:
   - intake: "Always extract a non-functional performance AC if none is stated."
   - implement: "Every requirement must ship with a unit test."
   - review: "Flag raw SQL as CRITICAL. All migrations must be reversible."
   - validate: "Use /en/ locale prefix. Demo account: demo@example.com."

   Store each non-empty answer as `phase_prompts.<phase>` in the config frontmatter. Leave phases with no input as `null`. The overlays are appended at cycle dispatch time — the agent treats them as binding instructions alongside the base prompt.

### 5. Write artifacts

- `_/sdlc-config.md` — render `templates/sdlc-config.template.md` with wizard answers; substitute `{{TODAY}}` etc.; phase_prompts from the overlay questions; `session.max_tokens` / `session.vault` from Q8–Q9; place free-text notes (Q10) under `# Notes for agents`.
- `_/demo/credentials.template.json` — copy from `templates/demo-credentials.template.json` (skip if `_/demo/credentials.json` already exists).
- `.gitignore` — update based on `tracks.gitignore`:
  - `true` → append `_/` (ignore everything).
  - `partial` → append `_/recordings/`, `_/demo/credentials.json`, `_/demo/scenarios/` but not `_/tracks/`.
  - `false` → append only `_/demo/credentials.json` and `_/recordings/` (recordings are large binary artifacts; credentials must never be committed regardless of the choice above).
  Never remove existing gitignore lines — only add what's missing.
- `_/tracks/` and `_/recordings/` — create with `.gitkeep`.
- **Coding agents inventory** — run `/kosmo-sdlc:discover-agents` (or `scripts/discover-coding-agents.ps1|.sh`) so `_/coding-agents.md` + `.json` exist for **ai-judge**.

Validate the parsed frontmatter against `schemas/sdlc-config.schema.json` before writing. Fail loudly on schema violation.

### 6. Report

Print a structured summary:

```
kosmo-sdlc initialized at /path/to/project

Ticketing:      jira (prefix TICKET) via Atlassian MCP
Spec:           ticket-references-path (no default dir)
Validation:     project-playwright @ http://localhost:3000
Conventions:    <type>/<TICKET> branches · conventional commits · commit via <strategy> (<skill|command|prompt value>)
PR body:        standard (per-PR override: /kosmo-sdlc:pr <TICKET> --style concise)
Notes:          8 lines captured (see _/sdlc-config.md)
Phase prompts:  implement ✅ · review ✅ · intake — · validate —

Next:
  /kosmo-sdlc:intake <TICKET-ID> [spec-path]
```

(The `Phase prompts:` line is omitted when all four overlays are null.)

Then the usage primer (same as before — kept verbatim except for the artifact name change):

```
How to use kosmo-sdlc
-----------------------

One ticket = one track file at _/tracks/<TICKET>.md. Every /kosmo-sdlc:* command
reads and writes that file. Run the phases in order, or run the whole cycle
with /kosmo-sdlc:cycle.

Phases (each suggests the next when it finishes):

  1. /kosmo-sdlc:intake     <TICKET> [spec]   build the track from the ticket + spec
  2. /kosmo-sdlc:implement  <TICKET>          code the requirements; pipeline-gated
  3. /kosmo-sdlc:validate   <TICKET>          Playwright assertions + stakeholder demo
  4. /kosmo-sdlc:review     <TICKET>          parallel code/security/standards review
  5. /kosmo-sdlc:pr         <TICKET>          push branch + open PR with inlined report
  5b. /kosmo-sdlc:pr-comments [PR]            walk reviewer threads; verdict-prefixed replies
  6. /kosmo-sdlc:revalidate <TICKET>          drift check + final green-light before merge

Shortcuts:

  /kosmo-sdlc:cycle <TICKET> [spec]           run all phases end-to-end, gated
  /kosmo-sdlc:cycle <TICKET> --resume         pick up at the last incomplete phase
  /kosmo-sdlc:cycle <TICKET> --auto           don't pause between phases (still stops on gate fails)

Where things live:

  _/sdlc-config.md          this file — project profile + freeform notes,
                            regenerate with /kosmo-sdlc:init --force
  _/tracks/<TICKET>.md      per-ticket source of truth (gitignored)
  _/recordings/             validation reports, review reports, demo .webm
  _/demo/credentials.json   fill this in before /kosmo-sdlc:validate (template seeded for you)

First run from here:

  1. Open _/demo/credentials.template.json, save it as _/demo/credentials.json,
     fill in a non-production test account.
  2. /kosmo-sdlc:discover-agents           # inventory CLIs → _/coding-agents.md (for judge)
  3. /grill-me                               # DEFAULT planning
  4. /kosmo-sdlc:intake <TICKET-ID>
  5. Follow the "Next:" line each command prints.
  Optional: set session.vault.path to your obsidian-personal clone for handoff/memory.
```

## Re-running on an existing project

When `_/sdlc-config.md` already exists:

1. Parse current frontmatter + capture the Notes body.
2. Run detection.
3. For each field where detection disagrees with on-disk value, ask:
   - "Field `validation.mode`: on disk = `manual`, detected = `project-playwright`. Update?"
4. Never overwrite the Notes body without explicit confirmation. If the user adds new notes mid-wizard, append rather than replace.
5. Append-only update of `detected_at`.

Under `--force`, skip all per-field prompts and overwrite with detected values — but **never** clobber the Notes body. The body is the user's hand-curated context; preserve it across re-runs.

## Hard rules

- Never write outside `_/` and (if needed) the project's root `.gitignore`.
- Never invent values to fill null fields. Downstream commands handle nulls by re-detecting or asking at use site.
- Validate frontmatter against `schemas/sdlc-config.schema.json` before writing. Fail loudly on schema violation.
- Never read `.env` files for values — only note that they exist.
- The Notes body is sacred user content. Don't paraphrase it, reformat it, or trim it. Pass it through verbatim. Re-runs preserve it unless the user explicitly replaces it.
- `--non-interactive` doesn't auto-accept ambiguous answers: if detection produced null for a required field (ticketing system, spec convention, validation mode), abort with a friendly "this project needs the interactive wizard at least once".
