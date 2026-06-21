---
# Frontmatter validates against ../schemas/sdlc-config.schema.json
# Captures user decisions only. Project state (package manager, Node version,
# default branch, CI workflows, root scripts) is re-detected at use site by
# each /agentic-sdlc:* command, so this file stays small and doesn't go stale.
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
  commit:
    via: {{COMMIT_VIA}}                   # skill | command | prompt
    skill: {{COMMIT_SKILL_OR_NULL}}       # skill name when via: skill (default: commit-work)
    command: {{COMMIT_COMMAND_OR_NULL}}   # shell command when via: command (use {{MESSAGE}} for the message)
    prompt: {{COMMIT_PROMPT_OR_NULL}}     # free-text instructions when via: prompt
  branch_pattern: {{BRANCH_PATTERN_OR_NULL}}  # e.g. "<type>/<TICKET>"
  track_dir: _/tracks
  demo_dir: _/demo
  recordings_dir: _/recordings

pr:
  body_style: {{PR_BODY_STYLE}}           # standard (full tables) | concise (one-liners + AC checklist only)

# Pinned overrides — leave null to re-detect on every run. Fill in only when
# detection picks the wrong value (e.g. several plausible "pipeline" scripts).
overrides:
  default_branch: null                    # e.g. "trunk"
  pipeline_command: null                  # e.g. "pnpm pipeline"
  dev_command: null                       # e.g. "pnpm dev"

# Optional ticket-size policy. intake proposes a size (s/m/l) and the user confirms;
# 's' skips e2e/demo and (by default) the 3-agent review, relying on the quality-gate
# pipeline rerun. Omit this block to use built-in defaults. Uncomment to tune.
# sizing:
#   small_max_requirements: 3   # propose 's' only at/below this requirement count
#   small_max_acs: 2            # propose 's' only at/below this AC count
#   large_min_acs: 5           # propose 'l' (mother + per-AC sub-tracks) at/above this
#   small_skips_review: true   # false ⇒ keep the review phase even for small tickets

# Per-phase prompt overlays — each non-null string is appended to that phase's
# base dispatch prompt at cycle time. Use for team conventions the generic prompts
# can't know: a house review checklist, a required deploy gate, stack-specific
# Playwright helpers, etc. null means no overlay for that phase.
phase_prompts:
  intake: {{PHASE_PROMPTS_INTAKE}}        # e.g. "Always extract a non-functional performance AC if none is stated."
  implement: {{PHASE_PROMPTS_IMPLEMENT}}  # e.g. "Every requirement must include a unit test. Never skip test files."
  review: {{PHASE_PROMPTS_REVIEW}}        # e.g. "Flag any use of raw SQL as CRITICAL regardless of parameterisation."
  validate: {{PHASE_PROMPTS_VALIDATE}}    # e.g. "Use /en/ locale prefix for all routes. Site is localised."
---

# Notes for agents

<!--
  Every /agentic-sdlc:* command reads this section verbatim and inlines it into
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
