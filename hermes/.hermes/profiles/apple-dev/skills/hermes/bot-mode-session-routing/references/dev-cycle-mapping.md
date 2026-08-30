# Mapping the dev-cycle pipeline onto session tiers

The dev-cycle is deliberately *session-agnostic*: its durable state lives in GitHub
Issues, not in conversations. `capture-issue → grilling → to-spec` resumes from an issue
URL/number (`/grilling <issue>`). So any phase CAN run in a fresh session — choose the
tier by *what you want to preserve*, not by what the tools force.

## The rule that generates the table

> What is the capital of this work?
> - *Shared understanding under construction* → **bot's forever-chat**
> - *Artifact already defined on the tracker, to execute or record* → **fresh session**

Everything before the dev-cycle STOP is volatile in-head understanding (needs the
forever-chat's continuity). Everything after STOP is a durable tracker artifact (can run
in disposable sessions).

## Per-feature loop

| Phase | Where | Why |
|---|---|---|
| capture-issue | fresh session | one-shot record+park; issue URL is the handoff |
| grilling | **bot chat** | shared understanding under construction; needs continuity |
| STOP → to-spec | **bot chat** (right after grilling) | context is live; produces the durable artifact |
| to-tickets | fresh session | mechanical; reads the spec from the tracker |
| implement (one ticket) | fresh session | self-contained slice: code+test+review+commit+close |
| code-review | fresh (or tail of implement) | gate on the commit |
| reflection / retrospective | **bot chat** | turn the lesson into memory/skill/ADR/CONTEXT.md/AGENTS.md |

1. capture → issue #N (labelled `needs-grilling`).
2. grilling in the bot chat — **critical:** transcribe decisions into the issue comments
   as you go, so you can move elsewhere afterward.
3. STOP → run `to-spec` in the same bot chat while the context is alive.
4. `to-tickets` in a fresh session.
5. `implement` per ticket in fresh sessions.
6. `code-review`.
7. return to the bot chat for the retrospective and persist the durable lesson.

## Switching physically

- Bot chat → fresh session: New Chat, or `hermes -p <bot> chat`.
- Fresh session → bot chat: click the bot in the roster (always lands in its forever-chat).

## The one error that costs

Grilling in a throwaway session without transcribing decisions to the issue loses the
shared understanding. That is the only mistake that is hard to recover from; everything
else the tracker makes resumable.