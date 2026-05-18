---
# Frontmatter validates against ../schemas/sdlc-config.schema.json
# Captures user decisions only. Project state (package manager, Node version,
# default branch, CI workflows, root scripts) is re-detected at use site by
# each /sdlc-* command, so this file stays small and doesn't go stale.
detected_at: {{TODAY}}

ticketing:
  system: {{TICKETING_SYSTEM}}            # jira | linear | github | none
  prefix: {{TICKETING_PREFIX_OR_NULL}}    # e.g. PROJ (null if no fixed prefix)
  mcp: {{TICKETING_MCP_OR_NULL}}          # e.g. atlassian | linear (null if not configured)

spec:
  convention: {{SPEC_CONVENTION}}         # ticket-references-path | fixed-dir | freeform
  default_dir: {{SPEC_DEFAULT_DIR_OR_NULL}}

validation:
  mode: {{VALIDATION_MODE}}               # project-playwright | standalone-playwright | manual
  base_url: {{VALIDATION_BASE_URL_OR_NULL}}
  credentials: _/demo/credentials.json

conventions:
  commit_style: {{COMMIT_STYLE}}          # conventional | freeform
  branch_pattern: {{BRANCH_PATTERN_OR_NULL}}  # e.g. "<type>/<TICKET>"
  track_dir: _/tracks
  demo_dir: _/demo
  recordings_dir: _/recordings

# Pinned overrides — leave null to re-detect on every run. Fill in only when
# detection picks the wrong value (e.g. several plausible "pipeline" scripts).
overrides:
  default_branch: null                    # e.g. "trunk"
  pipeline_command: null                  # e.g. "pnpm pipeline"
  dev_command: null                       # e.g. "pnpm dev"
---

# Notes for agents

<!--
  Every /sdlc-* command reads this section verbatim and inlines it into
  sub-agent prompts. Capture anything the agents should know that doesn't fit
  the frontmatter above. Free-form markdown — no required structure.

  Examples of what belongs here:
  - monorepo-specific commands ("use `pnpm api:dev` when working in apps/api;
    root `pnpm dev` boots everything")
  - environment quirks ("requires VAULT_TOKEN; copy from 1Password 'Dev Vault'")
  - ticketing nuances ("WIP: prefix in titles means draft; don't open a PR")
  - known-flaky tests ("e2e/checkout.spec.ts retries up to 3x; one failure is fine")
  - Playwright nuances ("use /en/ locale prefix for routes; site is localised")
  - "what counts as done" rules the team enforces beyond green tests

  Keep this section short — agents read it every time. Trim stale entries.
-->

_No project-specific notes yet. Replace this paragraph with anything the agents should know that the frontmatter above doesn't capture._
