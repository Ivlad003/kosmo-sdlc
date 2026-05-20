---
marp: true
theme: default
paginate: true
header: 'agentic-sdlc'
---

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700&family=Fira+Code:wght@400;500;700&display=swap');

:root {
  --color-background: #0d1117;
  --color-foreground: #c9d1d9;
  --color-heading: #58a6ff;
  --color-accent: #7ee787;
  --color-muted: #8b949e;
  --color-code-bg: #161b22;
  --color-border: #30363d;
  --color-warn: #f0883e;
  --font-default: 'Inter', system-ui, sans-serif;
  --font-code: 'Fira Code', 'Consolas', 'Monaco', monospace;
}

section {
  background-color: var(--color-background);
  color: var(--color-foreground);
  font-family: var(--font-default);
  font-weight: 400;
  box-sizing: border-box;
  border-left: 4px solid var(--color-accent);
  position: relative;
  line-height: 1.6;
  font-size: 22px;
  padding: 56px 64px;
}

h1, h2, h3, h4, h5, h6 {
  font-weight: 700;
  color: var(--color-heading);
  margin: 0;
  padding: 0;
  font-family: var(--font-code);
}

h1 { font-size: 52px; line-height: 1.25; text-align: left; }
h1::before { content: '# '; color: var(--color-accent); }

h2 {
  font-size: 36px;
  margin-bottom: 28px;
  padding-bottom: 10px;
  border-bottom: 2px solid var(--color-border);
}
h2::before { content: '## '; color: var(--color-accent); }

h3 {
  color: var(--color-foreground);
  font-size: 24px;
  margin-top: 24px;
  margin-bottom: 8px;
}
h3::before { content: '### '; color: var(--color-accent); }

ul, ol { padding-left: 28px; }
li { margin-bottom: 8px; }
li::marker { color: var(--color-accent); }

pre {
  background-color: var(--color-code-bg);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 16px 20px;
  overflow-x: auto;
  font-family: var(--font-code);
  font-size: 16px;
  line-height: 1.5;
}

code {
  background-color: var(--color-code-bg);
  color: var(--color-accent);
  padding: 2px 6px;
  border-radius: 3px;
  font-family: var(--font-code);
  font-size: 0.88em;
}
pre code { background-color: transparent; padding: 0; color: var(--color-foreground); }

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 18px;
  margin-top: 12px;
}
th, td {
  border: 1px solid var(--color-border);
  padding: 8px 12px;
  text-align: left;
  color: var(--color-foreground);
  background-color: var(--color-background);
}
th {
  background-color: var(--color-code-bg);
  color: var(--color-heading);
  font-family: var(--font-code);
}
tr:nth-child(even) td { background-color: rgba(21, 29, 24, 0.9); }

blockquote {
  border-left: 3px solid var(--color-accent);
  padding-left: 16px;
  color: var(--color-muted);
  font-style: italic;
  margin: 16px 0;
}

strong { color: var(--color-accent); font-weight: 700; }
em { color: var(--color-warn); font-style: normal; }

header {
  position: absolute;
  top: 20px;
  left: 64px;
  font-size: 14px;
  color: var(--color-muted);
  font-family: var(--font-code);
}
header::before { content: '// '; color: var(--color-accent); }

footer {
  font-size: 14px;
  color: var(--color-muted);
  font-family: var(--font-code);
  position: absolute;
  left: 64px;
  right: 64px;
  bottom: 28px;
  text-align: left;
}
footer::before { content: '// '; color: var(--color-accent); }

section::after {
  font-family: var(--font-code);
  color: var(--color-muted);
  font-size: 14px;
}

section.lead {
  display: flex;
  flex-direction: column;
  justify-content: center;
}
section.lead h1 { margin-bottom: 24px; font-size: 60px; }
section.lead p {
  font-size: 24px;
  color: var(--color-foreground);
  font-family: var(--font-code);
}
section.lead p strong { color: var(--color-accent); }
</style>

<!-- _class: lead -->
<!-- _paginate: false -->

# /agentic-sdlc

A Claude Code plugin. Seven phases, every transition gated.

**Spec & Ticket** → *ready PR with a narrated demo video.*

---

## The problem

> "we trust Claude but it does weird trash. then we forget to retest and end up with 13 items from QA."

- Claude does wrong presumptions and we miss the colleagues questions.
- We do same prompts over and over.
- Claude has destructive intentions and tries to delete a lot of staff just because.
- We want to be sure that application actually works with Claude's changes.

**We need gates the cycle itself refuses to cross.**

---

## The cycle

```
ticket, requirements, specs, context
  │
  ▼
intake ──────── pick up work and resolve open questions
  │             every AC → testable requirements
  ▼
implement ───── write code
  │             run automated checks
  ▼
validate ────── Playwright video proof ──► 🎬 narrated .webm
  │
  ▼
review ──────── three reviewers: code · security · standards
  │             user chooses which proposed changes to apply
  ▼
pr ──────────── push branch · open PR
  │             handle comments · post replies
  ▼
revalidate ──── re-run checks after review
  │             updated video after everything
  ▼
merge
```

Seven phases. Each writes evidence to the track file. The cycle **stops at the first failed gate**.

---

## The commands

| #   | Command                     | Phase idea                                                   |
| --- | --------------------------- | ------------------------------------------------------------ |
| 0   | `/agentic-sdlc:init`        | Bootstrap project profile; choose whether `_/` is gitignored |
| 1   | `/agentic-sdlc:intake`      | Ask clarifying questions, turn ACs into requirements         |
| 2   | `/agentic-sdlc:implement`   | Code until lint + typecheck + tests + build go green         |
| 3   | `/agentic-sdlc:validate`    | Playwright assertions pass → record narrated demo            |
| 4   | `/agentic-sdlc:review`      | Three-reviewer fan-out: CRITICAL / HIGH / MEDIUM / LOW       |
| 5   | `/agentic-sdlc:pr`          | Push branch, open PR, record URL in track                    |
| 5b  | `/agentic-sdlc:pr-comments` | Address each PR thread with a verdict prefix                 |
| 6   | `/agentic-sdlc:revalidate`  | Re-assert after review; acknowledge spec drift               |
| ∗   | `/agentic-sdlc:cycle`       | Orchestrate phases 1→6, pause between each                   |

---

## INTAKE: Single source of track

- **Asks you clarifying questions first** — agent presumptions are surfaced and correctable before a single line of code is written.
- One track file per ticket — `_/tracks/<TICKET>.md`.
- YAML frontmatter is the contract, body is for agents and humans.
- Heavy emphasis on specs, requirements, and acceptance criteria

```
_/
├── sdlc-config.md                project profile
├── tracks/PROJ-123.md            requirements, status, journal
├── demo/PROJ-123.spec.mjs        generated Playwright script
└── recordings/
    ├── PROJ-123.validation.md    assertions report
    ├── PROJ-123.review.md        consolidated findings
    ├── PROJ-123.latest.webm      stakeholder demo
    └── …
```

---

## VALIDATE: Playwright script → passing assertions → 🎬 demo

**How the script is built:** Playwright MCP navigates the live app (`browser_navigate`, `browser_snapshot`) to discover real selectors from the accessibility tree — no guessing.

**Two-pass execution of the generated script:**

**Pass 1** — run and verify checks without a visible browser

**Pass 2** — record the demo video
- Overlays + fake cursor + section badges, slow-motion, recorded as `.webm`
- Drop straight into Slack, a Jira comment, or a stakeholder email

> "I shipped a feature. Here's the 40-second video of it working."

---

## REVIEW: three parallel sub-agents

```
            ┌──► code reviewer       ┐
intake ────►├──► security reviewer   ├──► consolidator ──► report
            └──► standards reviewer  ┘
```

Findings consolidated into *CRITICAL / HIGH / MEDIUM / LOW*
After this, a sub-agent will be proposed to apply the findings.

---

## /agentic-sdlc:cycle

```bash
/agentic-sdlc:cycle PROJ-123
```

- Runs phases 1 → 6 in **dedicated sub-agents** (clean context per phase)
- Pauses between phases for a human glance
- Stops at the **first failed gate**
- Resumable — the track file remembers where it stopped

You can step through manually if you'd rather:

```bash
/agentic-sdlc:intake     PROJ-123 path/to/spec.md
/agentic-sdlc:implement  PROJ-123
/agentic-sdlc:validate   PROJ-123
```

---

## Install + first run

```bash
# install
/plugin marketplace add /path/to/sdlc
/plugin install agentic-sdlc@agentic-sdlc

# one-time setup — detects pkg manager, scripts, ticketing prefix,
# checks available MCPs + skills, prompts about gitignore and other settings
/agentic-sdlc:init

# full loop, gated, end-to-end
/agentic-sdlc:cycle PROJ-123
```

**Requirements:** Claude Code v2.1+, Node 18+, `gh` CLI authenticated. Atlassian / Linear MCP optional.

---

## Why this beats vibe-coding


- Resuming a day later doesn't lose context — the track file is the contract
- Narrated `.webm` makes it something you can *watch*
- Original specs and requirements always in the agent's context

> Make the cycle refuse to lie. Then trust it.

---

<!-- _class: lead -->
<!-- _paginate: false -->

# Try it

**`/agentic-sdlc:cycle PROJ-123`**

