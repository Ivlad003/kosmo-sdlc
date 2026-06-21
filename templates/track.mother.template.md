---
ticket: {{TICKET}}
title: {{TITLE}}
status: planned
size: l
parent: null
children:
{{CHILDREN_YAML_LIST}}
created: {{TODAY}}
updated: {{TODAY}}
branch: null
spec:
  path: {{SPEC_PATH_OR_NULL}}
  url: {{SPEC_URL_OR_NULL}}
  hash: {{SPEC_HASH_OR_NULL}}
  rows: {{SPEC_ROWS_OR_NULL}}
figma: {{FIGMA_OR_NULL}}
pr: null
demo:
  scenario: null
  recording: null
  report: null
  applicable: true
acs:
  - id: AC1
    text: "{{AC1_TEXT}}"
    requirements:
      - id: R1.1
        text: "{{R1_1_TEXT}}"
        owner: frontend
        status: not_started
        evidence: null
phase_log:
  - phase: intake
    at: {{NOW_ISO}}
    note: "Mother track created from {{SOURCE}}; split into {{N_CHILDREN}} sub-tracks (one per AC group)."
    outcome: pass
---

# Where we at on this track

Intake just completed. This is an **L (large)** mother track — the work is split into {{N_CHILDREN}} sub-tracks, one per AC group. Each sub-track runs its own cycle; this track aggregates their gate outcomes. Next step: run `/agentic-sdlc:cycle {{TICKET}}` to fan out over the sub-tracks (or run each sub-track individually).

## §0 Sub-tracks

Each row is an independent unit of work with its own track file. The mother track is `ready_to_merge` only when **every** sub-track has cleared its gates.

| Sub-track | AC group | Owner mix | Status | Track file |
| --------- | -------- | --------- | ------ | ---------- |
{{SUBTRACK_TABLE_ROWS}}

> Status mirrors each sub-track's frontmatter `status`. The cycle orchestrator updates this table as sub-tracks advance.

## §1 Scope

**In:**
- {{AC_BULLETS}}

**Out:**
- {{OUT_OF_SCOPE_BULLETS_OR_TBD}}

## §2 Ticket (verbatim)

```
{{TICKET_BODY_VERBATIM}}
```

> Verbatim from the ticketing system. Typos and dangling phrases preserved on purpose; never edited.

## §3 Spec slice (verbatim)

```
{{SPEC_SLICE_VERBATIM_OR_TBD}}
```

### What this means in plain language

{{SPEC_PLAIN_LANGUAGE_OR_TBD}}

## §5 Open questions

| # | Status | Owner | Question | Decision |
| - | ------ | ----- | -------- | -------- |
| 1 | DECIDE | TBD   | {{Q_OR_TBD}} | — |

Statuses: `DECIDE` · `✅ RESOLVED` · `DEFERRED`

## §7 Journal (append-only)

| Date | Phase | Author | Note |
| ---- | ----- | ------ | ---- |
| {{TODAY}} | intake | {{AUTHOR}} | Mother track created; split into {{N_CHILDREN}} sub-tracks. |
