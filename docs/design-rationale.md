# Design rationale

Why the cycle is shaped the way it is, and what's deliberately not in it.

## The track file is the contract

Every command reads `_/tracks/<TICKET>.md` first and writes a frontmatter delta last. The frontmatter is YAML and is validated against `schemas/track.schema.json` on every write.

**Why YAML frontmatter instead of prose?** Earlier iterations (the `/feature-track` command this plugin is descended from) used pure-markdown sections. Downstream commands had to grep the prose for AC status, which broke when the user edited the markdown by hand. Frontmatter is queryable, parseable, and schema-checkable. Sections are still there for human readers — but no command depends on them.

**Why the body sections still matter.** Three reasons: (1) the verbatim ticket / spec quotes preserve the original source of truth, immune to paraphrase drift; (2) §0 "Where we at" is the one paragraph every agent reads first to ground itself; (3) §7 Journal is the human-readable audit trail. The frontmatter is for machines; the sections are for context-restoring humans (and agents reading the document cold).

## One source of truth per ticket

Tracks are one-per-ticket, not one-per-branch or one-per-release. A branch may live and die; the track persists across rebases, force-pushes, and abandoned attempts. When a feature gets re-scoped, the old track stays — its journal records the abandonment — and a new track gets created.

## Gates over hopes

Every transition between phases has a verifiable condition. The cycle won't advance past a failing gate, even with `--auto`. This is the single biggest difference from "one-shot agentic dev" tools that produce code and trust the developer to verify.

Concrete gates:

- intake → must validate against schema; must have ≥1 requirement per AC.
- implement → all requirements `done` with `evidence`; pipeline green.
- validate → 0 failing assertions; no new console errors / network 4xx-5xx.
- review → no CRITICAL findings unaddressed.
- pr → pipeline green again; PR opened, body populated.
- revalidate → still green; spec unchanged or drift ack'd.

The bar for each gate is intentionally raised slightly above "the agent thinks it's done". Real verification beats agent self-assessment.

## Two outputs from validation

Validation produces an assertions report (the *gate*) and a stakeholder demo .webm (the *artifact*). The original `/demo-video` command conflated them: a script that "completed" was assumed to validate the feature, but it used `force: true` on every click and had no `expect()` calls. A demo that succeeds while the feature is broken is worse than no demo.

Splitting them:

- Assertions are the truth source. They use real visibility checks, no `force`, and console/network logs are mined for new defects.
- The demo is regenerated **only when assertions pass**. A failed run still produces a "failed.webm" for debugging, but it's not the artifact reviewers see.

## Sub-agents in worktrees

`/sdlc-cycle` dispatches each phase to a dedicated sub-agent running in a git worktree. Two benefits:

1. **Context isolation.** Each phase has its own context window. Intake's verbose ticket body doesn't pollute the implementer's window; the implementer's edit log doesn't push the reviewer out of context.
2. **Phase independence.** Phases can be retried, swapped (e.g. a different review agent), or run by different models without coordination overhead.

Cost: each sub-agent reads `_/tracks/<TICKET>.md` and `_/sdlc.config.json` afresh. The track is small (< 50KB typically); this is cheap.

## `_/` is gitignored

Tracks, demos, recordings, scenarios, and the project config all live under `_/`. None of it is committed. Three reasons:

1. **Process artifacts shouldn't pollute history.** Five years from now, no one cares which `<run-id>.webm` was the final one.
2. **Secrets stay local.** `_/demo/credentials.json` holds test accounts. Gitignore is the simplest sandbox.
3. **The PR body is the durable artifact.** Anything the cycle wants to preserve for posterity — the AC checklist, the validation outcome, the review summary — lives in the PR body, which is reproducible from the track at any time.

## What's deliberately not in scope

**No bundled MCP servers.** The plugin documents which user MCPs improve which phase (Atlassian for intake, Playwright for validate) but doesn't ship them. Different teams use different ticketing systems; bundling locks users into one.

**No knowledge-graph indexing.** `code-review-graph` is a great companion for `/sdlc-review` on large diffs, but it's a separate plugin with its own setup. Bundling would double the install surface.

**No hooks.** Everything is on-demand. Hooks (pre-commit, post-edit) are tempting but increase the failure surface and slow developer feedback. The cycle's gates are explicit invocations, not background processes. Open door for v1.x.

**No CLI binary.** In-session only. The plugin is for users who already live inside Claude Code; building a separate `omc`-style CLI doubles the maintenance.

**No multi-harness manifests.** Claude Code first. Codex / Cursor / Gemini ports happen if there's demand and a contributor; they're not v0 priorities. The track format and `_/sdlc.config.json` schema are harness-neutral, so porting is mostly command-prompt translation.

**No spec-pressure-testing skill baked in.** `vibe-testing` is a recommended companion (see [adapting.md](adapting.md)), not a bundled feature. Pressure-testing a spec before intake is good practice but adds another command and another gate; it's optional.

## What we'd add in v1.x

- Spec-pressure-testing as an opt-in `/sdlc-prespec` phase (zero gate, advisory only).
- Hooks: pre-commit pipeline gate, post-merge revalidation trigger.
- Multi-track view: a `/sdlc-status` command that summarizes all tracks across `_/tracks/`.
- Release notes generator from the journal entries since the last release tag.
- Multi-harness manifests for Codex / Cursor / Gemini.

## What we'd never add

- Auto-merge on `ready_to_merge`. The cycle marks state; a human (or a CI workflow controlled by a human) merges.
- Silent failure modes. Every gate failure produces a specific next-action message. No "consider re-running" generalities.
- "Skip this gate" flags. `--auto` skips user prompts; it doesn't skip gates.

## Inspirations and what we learned from them

- **`/feature-track`** (the predecessor) — verbatim-everything discipline, append-only journal, TBD-not-omitted. Kept all of it.
- **`/pr-comments`** — verdict-first replies, read-before-decide, no auto-resolve on `Applied`. Kept verbatim.
- **`/demo-video`** — Playwright helpers, log capture, fake-cursor overlays. Kept the helpers; split the demo from the assertions.
- **`/qa-test-backend`** — parallel sub-agent phases with consolidated reporting. Adopted for `/sdlc-review`.
- **`/visual-qa`** — console + network log scanning. Adopted for `/sdlc-validate`.
- **`commit-work` skill** — staging discipline, Conventional Commits, sanity checks. Kept and added the pipeline gate the original lacked.
- **`superpowers`** (obra) — skill-as-curriculum philosophy. Took the modularity, skipped the multi-harness fragmentation.
- **`everything-claude-code`** (affaan-m) — marketplace.json schema, command frontmatter conventions. Direct borrowings.
- **`oh-my-claudecode`** — `/team` and `/autopilot` orchestrator patterns. Inspired `/sdlc-cycle` but with explicit gates rather than autonomous best-effort.
- **`vibe-testing`** — scenario-driven validation. Adapted into the assertions half of `/sdlc-validate`; the full pressure-testing pattern is recommended as a separate companion.
- **`code-review-graph`** — blast-radius queries. Documented as an optional pairing; not bundled to keep the install surface small.
