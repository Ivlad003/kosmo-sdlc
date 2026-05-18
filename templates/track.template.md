---
ticket: {{TICKET}}
title: {{TITLE}}
status: planned
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
    note: "Track created from {{SOURCE}}."
    outcome: pass
---

# Where we at on this track

Intake just completed. 0 of N requirements started. Next step: run `/agentic-sdlc:implement {{TICKET}}`.

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

## §4 UI layout reference

```
{{ASCII_SKETCH_OR_TBD}}
```

Open visual questions:
- {{VISUAL_QUESTIONS_OR_TBD}}

## §5 Open questions

| # | Status | Owner | Question | Decision |
| - | ------ | ----- | -------- | -------- |
| 1 | DECIDE | TBD   | {{Q_OR_TBD}} | — |

Statuses: `DECIDE` · `✅ RESOLVED` · `DEFERRED`

## §6 Implementation plan

### Backend
- [ ] {{BACKEND_TASKS_OR_TBD}}

### Shared contracts
- [ ] {{SHARED_TASKS_OR_TBD}}

### Frontend
- [ ] {{FRONTEND_TASKS_OR_TBD}}

### Tests
- [ ] Unit tests for each requirement
- [ ] Playwright assertions report for UI requirements
- [ ] Stakeholder demo recording

## §7 Journal (append-only)

| Date | Phase | Author | Note |
| ---- | ----- | ------ | ---- |
| {{TODAY}} | intake | {{AUTHOR}} | Track created. |
