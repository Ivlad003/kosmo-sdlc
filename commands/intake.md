---
description: Build _/tracks/<TICKET>.md — the single source of truth for one ticket. Verbatim ticket body, verbatim spec slice, acceptance criteria decomposed into testable requirements, YAML frontmatter that every later /kosmo-sdlc:* command queries.
argument-hint: "<ticket-id-or-description> [spec-path-or-url]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch"]
---

# /kosmo-sdlc:intake

Phase 1 of the cycle. Produces a track file an agent can drop into cold and act on without re-fetching the ticket or the spec.

## Arguments

- `$1` (required): ticket ID (`TICKET-1`), ticket URL, or a freeform feature description when `ticketing.system: "none"`.
- `$2` (optional): spec path or URL. If the ticket body references one and `$2` is missing, the user gets prompted.

## Preconditions

1. `_/sdlc-config.md` exists. Run `/kosmo-sdlc:init` if not — fail loudly with that instruction; don't auto-init. Read both the frontmatter and the Notes body; the Notes body shapes how you handle ticket / spec quirks.
2. The directory `_/tracks/` exists. If not, create it.

## Before intake — grill-me is default planning

**`grill-me` is the primary planning skill** (not brainstorming, not open design dumps).

1. If the work is freeform, ACs are thin, trade-offs are open, or the user is still shaping the idea → **run `grill-me` first** (backed by `grilling`). For glossary/ADR capture use `grill-with-docs`.
2. Reach **shared understanding** (one question at a time; recommend an answer each time).
3. Optional: high-stakes or contested design → `/kosmo-sdlc:judge plan` (`ai-judge`) before writing the track.
4. Only then continue this intake workflow so the track captures the resolved decisions as ACs/requirements.

Skip the grill only when the ticket + spec already define testable acceptance criteria clearly enough to decompose (user may still request grill).

## Workflow

### 1. Parse arguments

- If `$1` matches `<PREFIX>-<NUMBER>` and `ticketing.system != "none"` → treat as a ticket ID.
- If `$1` is a URL → derive ticket ID from the URL.
- Otherwise → treat `$1` as a freeform description; generate a slug for the track filename (`feat-<slug>.md`).

### 2. Resolve ticket body (verbatim)

In priority order:

1. **Pasted inline** — if the invocation already contains the AC (any "Acceptance Criteria" heading, `Given/When/Then`, or numbered AC list), use it verbatim. Skip all fetching.
2. **`ticketing.mcp`** set in config — call that MCP server to fetch the ticket. For `github`, fall back to `gh issue view <id> --json title,body,state`.
3. **Otherwise** — ask the user to paste the body.

Never paraphrase from training data even if you "remember" the ticket. Preserve typos and original formatting.

### 3. Resolve spec slice (verbatim)

If the ticket body references a spec path or URL, and `$2` was not given, use the referenced one. Else use `$2`.

- Read the whole file when small.
- For large specs, grep for the section name from the ticket's "Sources" line, then read with offset/limit.
- If the ticket points at specific rows ("see last rows 131-132"), capture **those rows in full** — preserve the markdown table structure exactly.
- Compute `sha256` of the captured slice → `frontmatter.spec.hash`. `/kosmo-sdlc:revalidate` uses this to detect drift.

If `spec.convention: "freeform"` or no spec → write `frontmatter.spec: null`, leave §3 as `TBD`.

### 4. Decompose acceptance criteria

For each acceptance criterion, ask: "what testable behaviors does this imply?"

- One AC may produce 1..N `requirements[]`. Aim for the smallest verifiable unit.
- Assign `owner: backend | frontend | shared | infra | docs | mixed` per requirement.
- All `status: not_started` at intake.
- `evidence: null` at intake.
- Use sequential ids: `R1.1`, `R1.2`, `R2.1`, …

Example decomposition for AC: *"I can open a drawer to create a new price grid"*
- `R1.1` (frontend): "Open price-grid drawer from the client page's 'Importer une nouvelle grille' button"
- `R1.2` (frontend): "Drawer renders form fields: name, start date, end date, file upload"
- `R1.3` (backend): "POST /clients/:id/price-grids accepts multipart form-data"
- `R1.4` (frontend): "Drawer closes and table refreshes on successful submit"

If the user can't yet decide on a requirement's owner, mark it `mixed` and surface it in §5 Open questions.

### 4b. Estimate the ticket size — then confirm with the user

Size tiers tune how much rigor the cycle applies. Propose one from the signals you already have, then **confirm with the user** before writing the track:

| Size | Heuristic (typical) | What the cycle does |
| ---- | ------------------- | ------------------- |
| `s` | 1–2 ACs, ≤ ~3 requirements, single owner, no meaningful UI surface (no `frontend`/`mixed` requirement) or a trivial UI tweak, small spec slice. | No new e2e design, no demo `.webm`, no 3-agent review. The project's quality-gate pipeline rerun (lint/prettier/typecheck/test/build) is the sole verification. |
| `m` | The default. Anything that isn't clearly small or clearly large. | Full cycle: implement → Playwright two-pass + demo → 3-agent review → pr. |
| `l` | Many ACs spanning distinct concerns, or work that naturally splits into independent units. | Mother track + one sub-track **per AC group**; each sub-track runs its own cycle. |

Procedure:

1. Compute the proposal from: AC count, requirement count, distinct `owner`s, whether any requirement is `frontend`/`mixed`, spec-slice size. If `_/sdlc-config.md` has a `sizing` block, apply its thresholds/policy first.
2. **Ask the user to confirm or override** (AskUserQuestion). Show the proposal and the one-line rationale.
3. Safety rule — never silently reduce rigor:
   - Default to `m` when unconfirmed.
   - Resolving to `s` (less rigor) **requires explicit user confirmation**. Do not auto-select `s`.
   - `m` and `l` may be accepted without friction once proposed, but still surface the proposal.
4. Write the resolved value to `frontmatter.size`.

### 4c. Large tickets — split into sub-tracks (size `l` only)

When size resolves to `l`, intake produces a **mother track plus one sub-track per AC group**:

1. Group the ACs into cohesive units (one group per AC by default; cluster tightly-coupled ACs only when they can't be delivered independently).
2. Render the **mother track** from `templates/track.mother.template.md`: `size: l`, `parent: null`, `children: [<sub-track ids>]`, the full AC list, and the §0 Sub-tracks table.
3. For each AC group, render a **sub-track** from `templates/track.template.md`: a derived ticket id (`<TICKET>-a`, `<TICKET>-b`, … or `<slug>-<group>` for freeform), `parent: <mother ticket>`, `children: null`, that group's ACs + requirements, and its own proposed size (`s` or `m`, confirmed per §4b). Re-number requirement ids within each sub-track (`R1.1`, `R1.2`, …).
4. The verbatim ticket body (§2) lives on the mother; sub-tracks quote only their AC slice and link back to the mother for the full body.
5. Report the mother + every sub-track path.

### 5. Render the track file

- Filename: `_/tracks/<TICKET>.md` (or `_/tracks/feat-<slug>.md` for freeform).
- Build frontmatter against `schemas/track.schema.json`. Validate before writing. Set `size` to the value resolved in §4b; set `parent`/`children` only for `l` tracks (see §4c) — both stay `null` otherwise.
- Use `templates/track.template.md` as the body scaffold (`templates/track.mother.template.md` for an `l` mother track).
- For a `size: s` track, drop the "Playwright assertions report" and "Stakeholder demo recording" lines from §6 Tests — they don't apply; leave a one-line note that verification is the quality-gate pipeline rerun.
- "Where we at on this track": one short paragraph — `Intake done. <N> requirements identified. Next: /kosmo-sdlc:implement <TICKET>.`
- §2 contains the ticket body **verbatim** in a fenced block. Add a one-line `> Note:` gloss below only if needed; never edit the original.
- §3 contains the spec slice **verbatim**, plus a "What this means in plain language" subsection.
- §6 Implementation plan starts empty — `/kosmo-sdlc:implement` fills it.
- §7 Journal: append the intake row with today's date.

### 6. Update existing track (re-run)

If `_/tracks/<TICKET>.md` already exists:

1. Read it. Parse frontmatter.
2. Diff new inputs against current state:
   - **add**: new ACs, new spec rows.
   - **update**: spec hash changed (drift), title changed.
   - **leave**: requirements already started, journal entries.
3. Show the user the three buckets and ask for confirmation before writing.
4. Never delete journal rows. Append-only.
5. Append a new journal row recording the re-intake.

### 7. Report

```
Track created: _/tracks/TICKET-1.md
Status: planned · size m · 4 requirements (3 frontend, 1 backend)
Spec: /Users/.../Client - Grille tariffaires.md (rows 1-21) · sha256 a7f3…
Next: /kosmo-sdlc:implement TICKET-1
```

For a `size: s` ticket, name the lighter flow so the user knows what's skipped:

```
Track created: _/tracks/TICKET-7.md
Status: planned · size s · 2 requirements (1 backend, 1 shared)
Verification: quality-gate pipeline rerun (no e2e/demo, no 3-agent review) — confirmed with you
Next: /kosmo-sdlc:implement TICKET-7
```

For a `size: l` ticket, report the mother and every sub-track:

```
Mother track: _/tracks/TICKET-9.md (size l · 3 sub-tracks)
  └ _/tracks/TICKET-9-a.md  (size m · AC1)
  └ _/tracks/TICKET-9-b.md  (size m · AC2)
  └ _/tracks/TICKET-9-c.md  (size s · AC3)
Next: /kosmo-sdlc:cycle TICKET-9
```

## Hard rules

- Ticket body and spec slice are **verbatim**. Typos preserved.
- Never invent ticket IDs, spec paths, Figma URLs, or commit hashes.
- Every required section exists in the output — even if its body is `TBD`. A missing section is a silent lie about state.
- Frontmatter must validate against `schemas/track.schema.json` before write.
- Size is **proposed by you, confirmed by the user.** Never auto-resolve to `s` (the lighter flow) without explicit user confirmation — that's the issue-#11 safety rule. When unconfirmed, default to `m`.
- Never auto-stage or commit the track (it lives under gitignored `_/`).
- File paths inside the body must be repo-relative markdown links so VSCode renders them clickable.
