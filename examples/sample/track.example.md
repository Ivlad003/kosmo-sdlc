---
ticket: TICKET-1
title: Add prices grid to customer page
status: planned
created: 2026-05-13
updated: 2026-05-13
branch: null
spec:
  path: /Users/professional/Projects/any2md/Client - Grille tariffaires .md
  url: null
  hash: sha256-a7f3c41b0d8e92f5c6a18e3d7b4920cc6e1a2b8d9f0e1c4d5b6a7e8f9c0d1e2f
  rows: "1-21"
figma: null
pr: null
demo:
  scenario: null
  recording: null
  report: null
  applicable: true
acs:
  - id: AC1
    text: "On a client page, I see a new table 'price grid'."
    requirements:
      - id: R1.1
        text: "Render 'Grilles tarifaires client' section on client detail page below existing tables"
        owner: frontend
        status: not_started
        evidence: null
      - id: R1.2
        text: "Columns: Nom de la grille, Date de début, Date de fin, Auteur, Date d'ajout, Fichier, Actions"
        owner: frontend
        status: not_started
        evidence: null
      - id: R1.3
        text: "GET /clients/:id/price-grids returns paginated list with required columns"
        owner: backend
        status: not_started
        evidence: null
  - id: AC2
    text: "I can download the Excel template of the price grid."
    requirements:
      - id: R2.1
        text: "Render 'Importer une nouvelle grille tarifaire client' button above the table"
        owner: frontend
        status: not_started
        evidence: null
      - id: R2.2
        text: "Static Excel template served from /assets/price-grid-template.xlsx"
        owner: backend
        status: not_started
        evidence: null
  - id: AC3
    text: "I can open the drawer to create a new price grid."
    requirements:
      - id: R3.1
        text: "Right-side drawer opens on button click"
        owner: frontend
        status: not_started
        evidence: null
      - id: R3.2
        text: "Drawer renders fields: name (required), start date, end date, file upload (required)"
        owner: frontend
        status: not_started
        evidence: null
      - id: R3.3
        text: "Validation surfaces field-level errors for missing required fields"
        owner: frontend
        status: not_started
        evidence: null
      - id: R3.4
        text: "POST /clients/:id/price-grids accepts multipart/form-data, returns 201 with created entity"
        owner: backend
        status: not_started
        evidence: null
      - id: R3.5
        text: "On successful submit, drawer closes and the table refreshes via TanStack Query invalidation"
        owner: frontend
        status: not_started
        evidence: null
      - id: R3.6
        text: "Backend rejects invalid file payloads with a localized error message"
        owner: backend
        status: not_started
        evidence: null
  - id: AC4
    text: "On any existing price grid, I can edit, delete, download."
    requirements:
      - id: R4.1
        text: "Edit icon opens the same drawer pre-filled with the row's values"
        owner: frontend
        status: not_started
        evidence: null
      - id: R4.2
        text: "PUT /clients/:id/price-grids/:gridId accepts the same payload as POST"
        owner: backend
        status: not_started
        evidence: null
      - id: R4.3
        text: "Delete icon prompts for confirmation; deactivates (soft-delete) the row"
        owner: frontend
        status: not_started
        evidence: null
      - id: R4.4
        text: "DELETE /clients/:id/price-grids/:gridId soft-deletes via isActive flag"
        owner: backend
        status: not_started
        evidence: null
      - id: R4.5
        text: "Download icon fetches the stored file via GET /clients/:id/price-grids/:gridId/file"
        owner: frontend
        status: not_started
        evidence: null
      - id: R4.6
        text: "GET /clients/:id/price-grids/:gridId/file streams the stored file with content-disposition header"
        owner: backend
        status: not_started
        evidence: null
phase_log:
  - phase: intake
    at: 2026-05-13T15:40:00Z
    note: "Track created from TICKET-1 + spec rows 1-21 of Client - Grille tariffaires.md."
    outcome: pass
---

# Where we at on this track

Intake just completed. 18 requirements identified across 4 acceptance criteria (10 frontend, 8 backend). Spec hash captured for drift detection. Next: run `/agentic-sdlc:implement TICKET-1` to begin shipping the requirements, starting with the backend table + endpoints.

## §1 Scope

**In (TICKET-1):**
- Render a price-grid table on the client detail page (AC1).
- Excel template download (AC2).
- Drawer for creating a new price grid with name, dates, file (AC3).
- Row-level edit / delete / download actions (AC4).

**Out:**
- Bulk import or multi-file upload (not in spec).
- Notifications when a grid expires (separate ticket).
- Sharing a grid across multiple clients (out of spec; spec is per-client).

## §2 Ticket (verbatim)

```
TICKET-1

# Services - Add prices grid to the customer page

## Objective
Allow the user to see and add price tables on the client page

## Sources
Specs: `/Users/professional/Projects/any2md/Client - Grille tariffaires .md`
Figma: (screenshot attached)

## Acceptance criteria
As a user
- On a client page, I see a new table, "price grid."
  - I can download the Excel template of the price grid
  - I can open the drawer to create a new price grid
    - On the drawer, I can put the required information (name, date, file…)
    - I see an error message if I didn't put the correct information, or if the price grid doesn't have the correct info
  - On any price grid existing, i can do the following action
    - Edit, Delete, Download
```

> Verbatim from Jira. Original typos and dangling phrases preserved on purpose; never edited.

## §3 Spec slice (verbatim, rows 1-21)

```
TBD — paste rows 1-21 of /Users/professional/Projects/any2md/Client - Grille tariffaires .md here at intake time.
```

### What this means in plain language

The screenshot in the ticket shows a "Grilles tarifaires client" section appearing in the bottom half of the client detail page. The header has the section title (1) and an "Importer une nouvelle grille tarifaire client" button (2). Below that, a table with columns "Nom de la grille | Date de début | Date de fin | Auteur | Date d'ajout | Fichier" (3) and rows like "Grille n°1 | 00/00/0000 | 00/00/0000 | PR Pascal Renoir | 00/00/0000 | fichier.xlsx" (4). Each row ends with two icon buttons (5), interpreted as edit and download. The delete action is implied by AC4 even though not visible in the screenshot.

## §4 UI layout reference

```
┌─ Client: <name> ──────────────────────────────────────────────────────────┐
│  ... existing client sections (contacts, etc.) ...                        │
│                                                                            │
│  Grilles tarifaires client  (1)         [↓ Importer une nouvelle...] (2)  │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │ Nom         Date début   Date fin    Auteur          Date d'ajout  │ (3)│
│  ├────────────────────────────────────────────────────────────────────┤   │
│  │ Grille n°1  00/00/0000   00/00/0000  PR Pascal R.   00/00/0000  ↓✎│ (4,5)│
│  │ Grille n°2  00/00/0000   00/00/0000  PR Pascal R.   00/00/0000  ↓✎│   │
│  └────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```

Open visual questions:
1. Edit vs delete icon — is the leftmost icon a download arrow and the rightmost an edit pencil? Spec text says edit/delete/download → three actions, but the screenshot shows only two icons.
2. Empty state copy when the client has no grids yet.
3. Author display — initials avatar + name vs name only?

## §5 Open questions

| # | Status | Owner | Question | Decision |
| - | ------ | ----- | -------- | -------- |
| 1 | DECIDE | frontend | Two-icon row vs three-icon row (edit + delete + download)? Screenshot ambiguous. | — |
| 2 | DECIDE | frontend | Empty-state copy: "No price grids yet. Import one to get started." or per spec? | — |
| 3 | DECIDE | backend | Where do uploaded files live? Local storage adapter (matches existing pattern) or new bucket? | — |
| 4 | DECIDE | backend | Soft-delete column name — `isActive` (project convention) confirmed for this table? | — |
| 5 | DEFERRED | frontend | Author avatar UX — current pattern uses initials chip; confirm reuse. | — |

## §6 Implementation plan

### Backend (`apps/backend/`)
- [ ] Schema: `client_price_grids` table (`src/db/schema/client-price-grids.ts`)
- [ ] Drizzle migration
- [ ] Module: `src/modules/clients/_child-modules/client-price-grids/` (controller, service, DTOs, types)
- [ ] Permission entries in `packages/contracts/src/consts/permissions.ts`
- [ ] Error keys in `packages/contracts/src/consts/errors.ts`
- [ ] Endpoints: GET list, POST create, PUT update, DELETE soft-delete, GET file
- [ ] Unit tests (Jest) for service + controller
- [ ] E2E test using Testcontainers

### Shared contracts (`packages/contracts/`)
- [ ] `PriceGridDto`, `CreatePriceGridDto`, `UpdatePriceGridDto`
- [ ] Zod schemas mirroring the DTOs
- [ ] `Permission.PRICE_GRID_*` enum entries

### Frontend (`apps/frontend/`)
- [ ] Component: `src/components/clients/single-client/client-prices-grid.tsx`
- [ ] Drawer: `src/components/clients/single-client/client-prices-grid-drawer.tsx`
- [ ] API queries: `src/lib/api-queries/clients/client-price-grids.ts` (list, mutations)
- [ ] Mount on `src/app/[locale]/(site)/admin/clients/[id]/page.tsx`
- [ ] Translations: `src/i18n/messages/fr.json` + `en.json` ("Clients.PriceGrid.*")
- [ ] Vitest unit tests for the form schema + the drawer component

### Tests
- [ ] Unit: schema validation, service business rules
- [ ] Playwright assertions report for AC1–AC4
- [ ] Stakeholder demo recording

## §7 Journal (append-only)

| Date | Phase | Author | Note |
| ---- | ----- | ------ | ---- |
| 2026-05-13 | intake | Vlad Kosmach | Track created. 18 requirements across 4 ACs. Spec rows 1-21 hashed (a7f3…). |
