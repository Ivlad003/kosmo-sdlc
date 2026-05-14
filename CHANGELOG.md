# Changelog

All notable changes to `agentic-sdlc` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Initial scaffold: cycle commands `/sdlc-init`, `/sdlc-intake`, `/sdlc-implement`, `/sdlc-validate`, `/sdlc-review`, `/sdlc-pr`, `/sdlc-pr-comments`, `/sdlc-revalidate`, `/sdlc-cycle`.
- Track file format with YAML frontmatter (`schemas/track.schema.json`).
- Project profile auto-detection (`schemas/sdlc-config.schema.json`).
- `commit-work` skill ported.
- Sub-agent definitions for the orchestrator.
- Documentation: cycle walkthrough, track format, init detection, project adaptation, design rationale.
- Reference example for a Turborepo/NestJS/Next.js project (`examples/picto/`).
