---
name: session-close
description: "End a session under token/iteration limits: write handoff, session log, memory, and teach notes as markdown into the Obsidian personal vault Work/{project}/. Use when session ends, budget hit, user says handoff/close session, or kosmo-ralph finishes."
disable-model-invocation: true
---

# Session close → Obsidian vault

When a session ends (user asks, Ralph budget hit, or soft token limit), persist four markdown artifacts into the user's **personal Obsidian repo** so the next agent/human can continue.

## Vault layout

Configured root (clone of https://github.com/Ivlad003/obsidian-personal or local path):

```text
{vault}/Work/{project-name}/
  handoff/{timestamp}.md
  session/{timestamp}.md
  memory/{timestamp}.md
  teach/{timestamp}.md
```

- **timestamp:** `yyyy-MM-dd-HHmmss` (local) or ISO compact.
- **project-name:** `session.vault.project_name` or git remote name or workspace folder name (slug: lowercase, `-`).

## Config (`_/sdlc-config.md`)

```yaml
session:
  max_tokens: 200000          # soft budget; null = unlimited
  max_iterations: 20          # kosmo-ralph default
  warn_tokens_ratio: 0.8
  on_limit: handoff           # handoff | stop | ask
  vault:
    path: null                # e.g. C:/Users/you/obsidian-personal
    # path may also be a git URL; clone to session.vault.clone_dir if missing
    clone_dir: null           # default: ~/vaults/obsidian-personal
    remote: https://github.com/Ivlad003/obsidian-personal
    work_root: Work
    project_name: null
    git_commit: false         # true → commit after write
    git_push: false           # true → push (requires explicit user trust)
```

Resolve vault path order:

1. `session.vault.path` if set and exists  
2. `session.vault.clone_dir` if repo present  
3. Clone `session.vault.remote` into `clone_dir` **only with user confirmation**  
4. Else ask user for local vault path

## Artifacts

### 1. `handoff/{ts}.md`

For the **next agent** (fresh context):

- Goal / ticket / branch
- Shared understanding (from grill)
- Done / in progress / blocked
- Exact next commands (`/kosmo-sdlc:…`, skills)
- Pointers to tracks, plans, PRs (no secrets)
- Suggested skills

### 2. `session/{ts}.md`

**Session log** (audit):

- host agent family + model if known  
- started/ended, iteration count, token estimate vs `max_tokens`  
- peers used (judge/kosmo-ralph)  
- files/commits touched (paths only)  
- limits hit?

### 3. `memory/{ts}.md`

**Durable project memory** (for future sessions):

- Decisions & rationale  
- Domain terms  
- Operational gotchas (build commands, flakes)  
- Open questions  

Prefer merging new bullets; don't dump raw chat.

### 4. `teach/{ts}.md`

**Teach notes** — what the human/agent learned this session:

- Patterns that worked / failed  
- Prompt or process tweaks  
- Links to skills to practice  

If the **`teach`** skill from mattpocock is installed, align structure with it; otherwise use the sections above.

## Redaction

Never write: API keys, tokens, passwords, `.env`, credentials.json, private URLs with secrets, personal data.

## Process

1. Read config + resolve vault + project-name.  
2. Create directories under `Work/{project}/…`.  
3. Write the four files (same timestamp).  
4. Optionally update a thin index `Work/{project}/README.md` with latest links.  
5. If `git_commit: true`: commit only those paths with message `memory({project}): session {ts}`.  
6. Push only if `git_push: true` **and** user confirmed this session.  
7. Also keep a local copy under `_/session-close/{ts}/` for the project.  
8. Report absolute vault paths to the user.

## When to auto-invoke

- `session.on_limit: handoff` and token/iteration budget reached (Ralph or long cycle)  
- User: "close session", "handoff", "save to obsidian"  
- End of successful `/kosmo-sdlc:cycle` if `session.close_on_cycle_end: true`

## Completion criterion

- [ ] Four markdown files exist under the vault paths (or user declined vault → only `_/session-close/`)  
- [ ] No secrets in content  
- [ ] User told next exact step for the following session  
