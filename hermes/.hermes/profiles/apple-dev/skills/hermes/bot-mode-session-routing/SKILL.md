---
name: bot-mode-session-routing
description: "Route Hermes work between bot chats and fresh sessions."
---

# Bot Mode session routing

Use inside Hermes desktop Bot Mode when deciding where a piece of work lives: a bot's
canonical "Bot Chat" (a persistent forever-chat) or a fresh/disposable session.

## Mental model

A Bot is a persistent profile, and its canonical Bot Chat is a pinned *forever-chat* —
the bot's "home base". Clicking a bot in the roster always lands there by design. Inside
that canonical chat, `/new` and `/reset` are rerouted to `/compact` (fresh working
context, same conversation) to protect the forever-chat contract. Regular sessions on
the same profile keep full `/new` freedom.

So there are two tiers:
- **Canonical Bot Chat** = long-lived working relationship / in-progress shared understanding.
- **Fresh session** (New Chat, or `hermes -p <bot> chat`) = disposable, artifact-driven work.

## Decision rule

> What is the capital of this work?
> - *Shared understanding under construction* → **forever-chat**
> - *Artifact already defined on an external tracker, to execute or record* → **fresh session**

The bridge that makes the two interchangeable is an **external durable artifact** — a
GitHub Issue, ticket, or spec. Pass around a token/pointer to it (e.g. an issue number)
when switching contexts; never rely on chat memory being carried from one to the other.

## Pitfalls

- **Building understanding in a disposable session without transcribing it to the tracker
  loses the work.** If the shared understanding stays only in chat, you are chained to that
  chat. Always write evolving decisions to the tracker so sessions stay interchangeable.
- **Don't try to get the Bots roster click to open a fresh chat** — it is hardwired to the
  canonical Bot Chat. (A profile whose chat pointer is not `Bot Chat` may not open at all,
  per the bot-mode-troubleshooting skill.) To start fresh, create a new session or run
  `hermes -p <bot> chat`.
- A productive pattern is to run **reflection/retrospective** back in the forever-chat at
  the end of a ticket: turn the durable lesson into memory, a skill patch, an ADR, or a
  CONTEXT.md/AGENTS.md update, instead of leaving it only in a session.

## Reference

- `references/dev-cycle-mapping.md` — concrete mapping of the dev-cycle pipeline
  (capture-issue → grilling → STOP → to-spec → to-tickets → implement → code-review)
  onto bot-chat vs fresh-session tiers, with the per-feature loop and switch mechanics.