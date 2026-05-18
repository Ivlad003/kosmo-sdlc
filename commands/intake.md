---
description: Build _/tracks/<TICKET>.md — the single source of truth for one ticket. Verbatim ticket body, verbatim spec slice, acceptance criteria decomposed into testable requirements, YAML frontmatter that every later /agentic-sdlc:* command queries.
argument-hint: "<ticket-id-or-description> [spec-path-or-url]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch"]
---

# /agentic-sdlc:intake

Phase 1 of the cycle. Produces a track file an agent can drop into cold and act on without re-fetching the ticket or the spec.

## Arguments

- `$1` (required): ticket ID (`TICKET-1`), ticket URL, or a freeform feature description when `ticketing.system: "none"`.
- `$2` (optional): spec path or URL. If the ticket body references one and `$2` is missing, the user gets prompted.

## Preconditions

1. `_/sdlc-config.md` exists. Run `/agentic-sdlc:init` if not — fail loudly with that instruction; don't auto-init. Read both the frontmatter and the Notes body; the Notes body shapes how you handle ticket / spec quirks.
2. The directory `_/tracks/` exists. If not, create it.

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
- Compute `sha256` of the captured slice → `frontmatter.spec.hash`. `/agentic-sdlc:revalidate` uses this to detect drift.

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

### 5. Render the track file

- Filename: `_/tracks/<TICKET>.md` (or `_/tracks/feat-<slug>.md` for freeform).
- Build frontmatter against `schemas/track.schema.json`. Validate before writing.
- Use `templates/track.template.md` as the body scaffold.
- "Where we at on this track": one short paragraph — `Intake done. <N> requirements identified. Next: /agentic-sdlc:implement <TICKET>.`
- §2 contains the ticket body **verbatim** in a fenced block. Add a one-line `> Note:` gloss below only if needed; never edit the original.
- §3 contains the spec slice **verbatim**, plus a "What this means in plain language" subsection.
- §6 Implementation plan starts empty — `/agentic-sdlc:implement` fills it.
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
Status: planned · 4 requirements (3 frontend, 1 backend)
Spec: /Users/.../Client - Grille tariffaires.md (rows 1-21) · sha256 a7f3…
Next: /agentic-sdlc:implement TICKET-1
```

## Hard rules

- Ticket body and spec slice are **verbatim**. Typos preserved.
- Never invent ticket IDs, spec paths, Figma URLs, or commit hashes.
- Every required section exists in the output — even if its body is `TBD`. A missing section is a silent lie about state.
- Frontmatter must validate against `schemas/track.schema.json` before write.
- Never auto-stage or commit the track (it lives under gitignored `_/`).
- File paths inside the body must be repo-relative markdown links so VSCode renders them clickable.
