---
name: grill-me
description: "Default planning skill. Relentless design interview before any plan, design, freeform ticket, or ambiguous scope. Prefer over brainstorming — especially before /kosmo-sdlc:intake or writing implementation plans."
disable-model-invocation: true
---

# Grill me — default planning

**This is the primary planning skill for kosmo-sdlc.** Prefer it over brainstorming, open design dumps, or jumping straight to intake/implement.

Run a `grilling` session (see the `grilling` skill).

## When (always start here for planning)

- Any new feature, behaviour change, or freeform idea.
- Before `/kosmo-sdlc:intake` or `/kosmo-sdlc:cycle` when ACs/trade-offs are not fully resolved.
- Before writing an implementation plan or choosing architecture.
- User says "plan", "design", "grill me", "stress-test", or "brainstorm" (map brainstorm → grill).
- With a codebase that should keep glossary/ADRs → use **`grill-with-docs`** instead (same interview + `domain-modeling`).

## Process

1. Run `grilling` until **shared understanding** (one question at a time; recommend an answer each time).
2. Recap decisions in ≤ 10 bullets.
3. **Optional multi-model check:** if the plan is high-stakes or the user wants second opinions, run **`ai-judge`** with `mode: plan` (peer CLIs critique alternatives).
4. Hand off — do **not** implement yet:
   - `/kosmo-sdlc:intake <ticket-or-description> [spec]` or `/kosmo-sdlc:cycle …`
   - Remaining opens → track §5 Open questions

## Hard rules

- One question at a time; recommend an answer each time.
- Look up facts; only put *decisions* to the user.
- Stop until shared understanding is confirmed — then intake (or judge → intake), never `/kosmo-sdlc:implement` first.
