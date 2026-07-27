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

## Sub-agents in worktrees (cycle only)

`/kosmo-sdlc:cycle` *may* dispatch each phase to a dedicated sub-agent in a git worktree. This is **orchestrator isolation**, not a global rule for all skills.

Benefits when worktrees are used:

1. **Context isolation.** Intake's verbose ticket body doesn't pollute the implementer's window.
2. **Phase independence.** Phases can be retried or swapped without coordination overhead.

**Not required** for manual phase commands (`intake`, `implement`, `validate`, …), grill-me, kosmo-ralph, ai-judge, or session-close. If worktrees are unavailable, run phases in-process.

Cost when used: each sub-agent re-reads `_/tracks/<TICKET>.md` and `_/sdlc-config.md` (cheap).

## `_/` is gitignored

Tracks, demos, recordings, scenarios, and the project config all live under `_/`. None of it is committed. Three reasons:

1. **Process artifacts shouldn't pollute history.** Five years from now, no one cares which `<run-id>.webm` was the final one.
2. **Secrets stay local.** `_/demo/credentials.json` holds test accounts. Gitignore is the simplest sandbox.
3. **The PR body is the durable artifact.** Anything the cycle wants to preserve for posterity — the AC checklist, the validation outcome, the review summary — lives in the PR body, which is reproducible from the track at any time.

## What's deliberately not in scope

**No bundled MCP servers.** The plugin documents which user MCPs improve which phase (Atlassian for intake, Playwright for validate) but doesn't ship them. Different teams use different ticketing systems; bundling locks users into one.

**No knowledge-graph indexing.** `code-review-graph` is a great companion for `/kosmo-sdlc:review` on large diffs, but it's a separate plugin with its own setup. Bundling would double the install surface.

**No hooks.** Everything is on-demand. Hooks (pre-commit, post-edit) are tempting but increase the failure surface and slow developer feedback. The cycle's gates are explicit invocations, not background processes. Open door for v1.x.

**No CLI binary.** In-session only. The plugin is for users who already live inside Claude Code; building a separate `omc`-style CLI doubles the maintenance.

**No multi-harness manifests.** Claude Code first. Codex / Cursor / Gemini ports happen if there's demand and a contributor; they're not v0 priorities. The track format and `_/sdlc-config.md` schema are harness-neutral, so porting is mostly command-prompt translation.

**No mandatory pre-intake gate.** Alignment before coding uses **`grill-me` / `grilling`** (from [mattpocock/skills](https://github.com/mattpocock/skills), bundled under `skills/`) instead of brainstorming. Grilling is advisory and user-invoked — one decision at a time until shared understanding — then hand off to `/kosmo-sdlc:intake`. It is not a cycle gate; skipping it is fine when the ticket already has clear ACs.

**No second SDLC in the plugin.** We deliberately **do not ship** mattpocock's parallel main flow (`to-spec` → `to-tickets` → `implement` → `code-review`) or its router/`setup` skills. Those conflict with track gates, size tiers, and `/kosmo-sdlc:implement` / `:review`. Hosts can still install them via skills.sh for non-cycle work.

**Multi-CLI AI judge is advisory.** `/kosmo-sdlc:judge` fans a plan or diff out to peer agent CLIs (excluding the host family when possible) and synthesizes ranked verdicts. It does **not** replace `/kosmo-sdlc:review` gates or pipeline/Playwright — it is a second court for high-stakes decisions and alternative ranking.

## Size adaptivity — proportional rigor, never silent

A one-line copy fix and a multi-AC feature don't deserve the same ceremony. `frontmatter.size` (`s`/`m`/`l`, proposed at intake, confirmed by the user) scales the cycle:

- **`s`** reuses machinery that already existed: `/kosmo-sdlc:validate` already drops Playwright/demo and runs only the automated-checks pipeline track for backend-only / `manual` changes. `s` is just one more trigger into that path, plus skipping the 3-agent review. The verification a small ticket gets is the project's **own quality gates re-run** — the same lint/typecheck/test/build the team already trusts — confirming nothing broke. No new e2e is authored for a change that doesn't warrant it.
- **`m`** is the default and is untouched. A track with no `size` field is treated as `m`, so this feature is fully backward compatible.
- **`l`** splits one mother track into a sub-track **per AC group**, each run as its own (smaller) cycle. The split is by AC because that's the unit the spec already defines and the unit a reviewer reasons about; splitting by owner tends to produce sub-tracks that can't be validated independently.

Two principles kept this from becoming a "skip the gates" knob:

1. **Reducing rigor is never silent.** Resolving to `s` requires explicit user confirmation, even under `--auto`. Intake *proposes*; the human *decides*. This is the one place the cycle asks before doing less.
2. **`s` drops phases, not gates.** The pipeline gate still runs at implement, validate, and pr. `s` removes the demo and the review — the parts that are overkill for a trivial change — but never the green-pipeline requirement. Consistent with "Gates over hopes": a lighter gate is still a gate.

Tuning lives in the optional `sizing` block of `_/sdlc-config.md` (thresholds, and a `small_skips_review` toggle for teams that want review even on small tickets).

## What we'd add in v1.x

- Optional orchestrated "grill then intake" prompt in `/kosmo-sdlc:cycle` when freeform input has no ACs (still zero gate — user can skip).
- Hooks: pre-commit pipeline gate, post-merge revalidation trigger.
- Multi-track view: a `/kosmo-sdlc:status` command that summarizes all tracks across `_/tracks/`.
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
- **`/qa-test-backend`** — parallel sub-agent phases with consolidated reporting. Adopted for `/kosmo-sdlc:review`.
- **`/visual-qa`** — console + network log scanning. Adopted for `/kosmo-sdlc:validate`.
- **`commit-work` skill** — staging discipline, Conventional Commits, sanity checks. Kept and added the pipeline gate the original lacked.
- **`superpowers`** (obra) — skill-as-curriculum philosophy. Took the modularity; **replaced brainstorm-before-build with mattpocock-style grilling**.
- **`mattpocock/skills`** — pruned bundle: `/grill-me` + `/grilling` as design alignment; optional `tdd`, `diagnosing-bugs`, `domain-modeling`, `grill-with-docs`, `codebase-design`, `handoff`. **Not** the full matt main flow (that collides with the cycle).
- **`everything-claude-code`** (affaan-m) — marketplace.json schema, command frontmatter conventions. Direct borrowings.
- **`oh-my-claudecode`** — `/team` and `/autopilot` orchestrator patterns. Inspired `/kosmo-sdlc:cycle` but with explicit gates rather than autonomous best-effort.
- **`code-review-graph`** — blast-radius queries. Documented as an optional pairing; not bundled to keep the install surface small.
