# Changelog

All notable changes to `agentic-sdlc` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Initial scaffold: cycle commands `/agentic-sdlc:init`, `/agentic-sdlc:intake`, `/agentic-sdlc:implement`, `/agentic-sdlc:validate`, `/agentic-sdlc:review`, `/agentic-sdlc:pr`, `/agentic-sdlc:pr-comments`, `/agentic-sdlc:revalidate`, `/agentic-sdlc:cycle`.
- Track file format with YAML frontmatter (`schemas/track.schema.json`).
- Project profile (`schemas/sdlc-config.schema.json`) as markdown-with-frontmatter (`_/sdlc-config.md`), with a freeform Notes body every command reads verbatim and inlines into sub-agent prompts.
- Interactive wizard in `/agentic-sdlc:init` for first-run setup (ticketing, spec convention, validation mode, branch pattern, free-text agent notes). Detection feeds defaults; the user confirms or overrides per question.
- `validation.mode: standalone-playwright` — sdlc installs and drives its own Playwright when the host project has none, so projects without a `playwright.config.*` still get assertion reports and stakeholder demos.
- `overrides` block (`default_branch`, `pipeline_command`, `dev_command`) as escape hatches when auto-detection picks the wrong value.
- `commit-work` skill ported.
- Sub-agent definitions for the orchestrator.
- Documentation: cycle walkthrough, track format, init detection, project adaptation, design rationale.
- Reference example for a Turborepo/NestJS/Next.js project (`examples/sample/`).

### Changed
- Project profile format: `_/sdlc.config.json` (strict JSON, detection-as-persistence) → `_/sdlc-config.md` (markdown + YAML frontmatter, user-decisions-as-persistence, project state re-detected at use site by each command).
- Validation gate: `playwright.present` boolean → `validation.mode` enum (`project-playwright` / `standalone-playwright` / `manual`). Decouples "can sdlc drive a browser" from "does the project have a playwright config".
- Detection-only fields removed from the persisted profile: `project.*`, `scripts.*`, `git.default_branch`, `git.pr_template`, `ci.workflows`, `ci.required_checks`. Each command re-resolves these from `package.json` / git / `.github/workflows` on demand — the config no longer goes stale when the project changes.
