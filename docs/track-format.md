# Track file format

`_/tracks/<TICKET>.md` is the single source of truth for one feature. Every `/agentic-sdlc:*` command queries the YAML frontmatter; the body of the file is for human readers. The frontmatter contract is enforced by `schemas/track.schema.json` — commands validate before writing.

## Frontmatter — the contract

```yaml
---
ticket: TICKET-1                    # ticket id or freeform slug
title: Add prices grid to customer page
status: planned                      # planned | in_progress | in_review | ready_to_merge | merged | abandoned
size: m                              # s | m | l — proposed at intake, confirmed by user; absent ⇒ m
parent: null                         # 'l' sub-track: mother ticket id; else null
children: null                       # 'l' mother: [sub-track ids]; else null
created: 2026-05-13
updated: 2026-05-13
branch: null                         # set by /agentic-sdlc:implement
spec:
  path: /abs/path/to/spec.md         # or null
  url: null                          # or null
  hash: sha256-…                     # set at intake; drift detector
  rows: "131-132"                    # row range when ticket points at a sub-section
figma: null
pr: null                             # set by /agentic-sdlc:pr
demo:
  scenario: null                     # set by /agentic-sdlc:validate
  recording: null
  report: null
  applicable: true                   # false → /agentic-sdlc:validate skips, writes 'na' report
acs:
  - id: AC1
    text: "I can see a new price grid table on the client page"
    requirements:
      - id: R1.1
        text: "Render table with columns: Nom, Date début, Date fin, Auteur, Date d'ajout, Fichier"
        owner: frontend               # backend | frontend | shared | infra | docs | mixed
        status: not_started           # not_started | in_progress | done | blocked | na
        evidence: null                # file:line or short commit SHA when done
phase_log:                            # append-only
  - phase: intake                     # intake | implement | validate | review | pr | pr-comments | revalidate
    at: 2026-05-13T15:40:00Z
    note: "Track created from TICKET-1 + spec slice 1-21."
    outcome: pass                     # pass | fail | partial | skipped
---
```

### Field semantics

- **`ticket`** — opaque identifier. Doesn't have to match a known ticketing system if `ticketing.system: "none"`.
- **`status`** — coarse state. Each phase transitions it deterministically: intake → `planned` → implement → `in_progress` → review → `in_review` → revalidate → `ready_to_merge` → user merges → `merged`.
- **`size`** — rigor tier proposed at intake and confirmed by the user. `s` skips e2e/demo and the 3-agent review (the quality-gate pipeline rerun is the verification); `m` is the full cycle; `l` is a mother track that splits into one sub-track per AC group via `parent`/`children`. Absent ⇒ `m`. Downgrading to `s` always needs explicit confirmation. See [design-rationale.md](design-rationale.md#size-adaptivity--proportional-rigor-never-silent).
- **`spec.hash`** — sha256 of the captured slice at intake. `/agentic-sdlc:revalidate` recomputes and compares; mismatch = drift.
- **`acs[].requirements[]`** — the decomposition you do at intake. One AC may produce N requirements. Each is the smallest verifiable behavior. `evidence` is a `file:line` reference or short SHA recording where the requirement landed.
- **`demo.applicable`** — set to `false` when the feature has no UI surface. `/agentic-sdlc:validate` writes a `na` report instead of running Playwright.
- **`phase_log`** — every phase that runs appends an entry. The orchestrator uses this for `--resume`. The journal in §7 of the body is the human-readable mirror.

## AC decomposition

Acceptance criteria capture user-visible behavior. Requirements capture testable units. The decomposition is the most important step in intake.

A weak decomposition:

```yaml
acs:
  - id: AC1
    text: "I can manage price grids"
    requirements:
      - id: R1.1
        text: "Implement price grid feature"
        owner: mixed
        status: not_started
```

A strong decomposition:

```yaml
acs:
  - id: AC1
    text: "I can open a drawer to create a new price grid"
    requirements:
      - id: R1.1
        text: "Show 'Importer une nouvelle grille' button on client detail page"
        owner: frontend
        status: not_started
      - id: R1.2
        text: "Clicking the button opens a right-side drawer"
        owner: frontend
        status: not_started
      - id: R1.3
        text: "Drawer renders fields: name (required), start date, end date, file upload (required)"
        owner: frontend
        status: not_started
      - id: R1.4
        text: "POST /clients/:id/price-grids accepts multipart/form-data, returns 201 with the created entity"
        owner: backend
        status: not_started
      - id: R1.5
        text: "On successful submit, drawer closes and the price-grid table refreshes"
        owner: frontend
        status: not_started
```

The second version gives the implementer concrete units to ship and the validator concrete `expect()` calls to write.

## Body sections

Every section must be present, even when its content is `TBD`. A missing section is a silent lie about state.

| § | Purpose |
| - | ------- |
| §0 "Where we at on this track" | One paragraph status. **First thing every agent reads.** Rewritten by every command. |
| §1 Scope | In/out bullets derived from frontmatter + ticket exclusions. |
| §2 Ticket (verbatim) | The original ticket body, typos preserved. |
| §3 Spec slice (verbatim) | The relevant rows of the spec, plus a "what this means in plain language" gloss. |
| §4 UI layout reference | ASCII sketch or screenshot reference + open visual questions. |
| §5 Open questions | Numbered list with `DECIDE` / `✅ RESOLVED` / `DEFERRED` tags. |
| §6 Implementation plan | Backend / Shared / Frontend / Tests checkboxes with file paths. |
| §7 Journal | Append-only audit trail. One row per phase that materially changed state. |

## Verbatim rules

- **Ticket bodies**: copy exactly. Don't fix typos. Don't reformat the AC list. Don't expand abbreviations. If the ticket has a dangling phrase, keep it dangling. You may add a `> Note:` gloss below the fenced block, never inside.
- **Spec slices**: same rules. Preserve markdown table structure exactly. If the ticket points at row 131-132, capture those rows in full — not paraphrased, not "summarised".
- **Decisions**: when §5 questions resolve, record the decision verbatim from the conversation (or a one-line summary plus a link to the conversation thread). Don't reword in agent-friendly prose.

## Schema validation

Before writing the track, every command:

1. Renders the frontmatter as YAML.
2. Parses it back as an object.
3. Validates against `schemas/track.schema.json`.
4. Fails loudly on violation, with the path of the offending field.

This is what makes the track a contract instead of a vibe.
