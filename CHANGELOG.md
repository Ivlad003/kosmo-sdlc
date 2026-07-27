# Changelog

All notable changes to `kosmo-sdlc` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## Release checklist
- [ ] Bump `version` in `.claude-plugin/marketplace.json`
- [ ] Update `## [Unreleased]` → `## [x.y.z] - YYYY-MM-DD`
- [ ] Tag the commit (`git tag vx.y.z && git push --tags`)

## [Unreleased]

### Added
- Pruned [mattpocock/skills](https://github.com/mattpocock/skills) companions under `skills/` (see `skills-lock.json` + `skills/README.md`): **`grill-me`** / **`grilling`**, `grill-with-docs`, `domain-modeling`, `tdd`, `diagnosing-bugs`, `codebase-design`, `handoff`, `writing-great-skills`
- **`ask-kosmo-sdlc`** router — product cycle only; no second idea→ship pipeline
- **`ai-judge`** + **`/kosmo-sdlc:judge`** — multi-CLI court; peers from **dynamic inventory**
- **`discover-agents`** + scripts — probe PATH, write `_/coding-agents.md` + `.json` for judge memory
- **`kosmo-ralph` / `kosmo-ralf`** + **`/kosmo-sdlc:kosmo-ralph`** — fork of [snarktank/ralph](https://github.com/snarktank/ralph) renamed to avoid skill-id conflict with upstream `ralph` (`_/kosmo-ralph/`, `scripts/kosmo-ralph.sh`)
- **`session-close`** + **`/kosmo-sdlc:session-close`** — handoff/session/memory/teach → Obsidian `Work/{project}/…` ([Ivlad003/obsidian-personal](https://github.com/Ivlad003/obsidian-personal))
- Vault note templates under `templates/vault-*.template.md`
- [docs/mattpocock-skills.md](docs/mattpocock-skills.md)

### Changed
- **`grill-me` is the default planning skill**
- **ai-judge** loads `_/coding-agents.json` (re-discovers if stale) instead of hard-coded peers
- Init wizard: optional `session.max_tokens` + vault path; post-init discover-agents
- `handoff` prefers session-close when vault configured
- `tdd` / `codebase-design` / `diagnosing-bugs` are **user-invoked**
- Full docs pass: **[docs/install.md](docs/install.md)** multi-agent install (Claude, Codex, Grok, Cursor, Windsurf, Amp, OpenCode, Aider, Copilot); cycle / adapting / design-rationale / presentations / README updated for **kosmo-sdlc**

### Removed (from plugin surface — install on host if needed)
- Conflicting matt skills: `implement`, `code-review`, `to-spec`, `to-tickets`, `ask-matt`, `setup-matt-pocock-skills` (name/process collisions with the gated cycle)

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
