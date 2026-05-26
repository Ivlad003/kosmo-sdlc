# Changelog

All notable changes to `agentic-sdlc` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## Release checklist
- [ ] Bump `version` in `.claude-plugin/marketplace.json`
- [ ] Update `## [Unreleased]` → `## [x.y.z] - YYYY-MM-DD`
- [ ] Tag the commit (`git tag vx.y.z && git push --tags`)

## [0.2.1] - 2026-05-26

### Fixed
- Plugin manifest version was out of sync with the changelog, causing installation failures

## [0.2.0] - 2026-05-26

### Added
- Per-phase prompt overlays (`phase_prompts`) configurable via init wizard and appended by cycle dispatch
- Configurable commit strategy (`skill` / `command` / `prompt`) set at init time, used by implement, review, and PR phases
- Codex plugin manifest and skill adapter for Claude Codex integration
- Codex install instructions in README

## [0.1.0] - 2026-05-26
