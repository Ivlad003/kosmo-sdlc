---
# Frontmatter validates against ../../schemas/sdlc-config.schema.json
detected_at: 2026-05-14

ticketing:
  system: jira
  prefix: TICKET
  mcp: atlassian

spec:
  convention: ticket-references-path
  default_dir: null

validation:
  mode: project-playwright
  base_url: http://localhost:3000
  credentials: _/demo/credentials.json

conventions:
  commit_style: conventional
  commit:
    via: skill
    skill: commit-work
    command: null
    prompt: null
  branch_pattern: "<type>/<TICKET>"
  track_dir: _/tracks
  demo_dir: _/demo
  recordings_dir: _/recordings

overrides:
  default_branch: trunk        # detection returns "main"; this repo merges into trunk
  pipeline_command: null
  dev_command: null

phase_prompts:
  intake: null
  implement: "Each requirement must ship with a unit test in the same commit. Never skip
    test files. For NestJS changes, add an e2e spec under apps/backend/test/."
  review: "Apply the team review checklist: (1) no raw knex queries — use the QueryBuilder
    wrapper; (2) all new env vars documented in docs/env.md; (3) migrations must be
    reversible. Flag violations as HIGH."
  validate: "Use /en/ locale prefix for all routes. Credentials are in _/demo/credentials.json
    (email: demo@example.com). Run against apps/frontend dev server on port 3000."
---

# Notes for agents

Turborepo: `apps/frontend` (Next.js), `apps/backend` (NestJS), `packages/contracts`
(shared Zod schemas + DTOs). Root pipeline is `npm run pipeline` which fans out via
turbo.

## Running things
- `npm run dev` boots everything via turbo
- `npm run dev:frontend` / `npm run dev:backend` for single-app loops
- Frontend Playwright runs use the `/en/` locale prefix; the site is localised
- Backend tests need a clean DB — `npm run db:reset` first when state-sensitive

## Conventions
- Zod schemas live in `packages/contracts/src/schemas/<domain>/*.schema.ts`; never
  define DTOs inline in controllers
- Commit scopes use the ticket id, not the package name (`feat(TICKET-1): ...`)
- The PR template's "AC" section is rendered by `/kosmo-sdlc:pr` from track frontmatter;
  do not hand-edit it

## Gotchas
- `npm run pipeline` flakes ~5% on the e2e step due to a port race; re-run once before
  reporting failure
- Linting Tailwind class lists times out on cold cache; pre-warm with `npm run lint`
  before measuring CI duration
