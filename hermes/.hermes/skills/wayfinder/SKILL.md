---
name: wayfinder
description: Plan a huge chunk of work that exceeds one agent session's capacity as a shared map of decision tickets on your issue tracker, then resolve them one at a time until the way to the destination is clear.
disable-model-invocation: true
---

A loose idea has arrived, too big for one agent session and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **shared map** on the repo's issue tracker, then works its **decision tickets**, which are questions whose resolution is a decision rather than slices of a build to execute, one at a time until the route is clear.

Read `writing-for-agents` before drafting map bodies, ticket bodies, resolution comments, or Decisions-so-far entries. Its general writing rules govern those artifacts; wayfinding adds only map-specific structure.

**Only invoke this for work that is genuinely too big for one session.** If the task fits in one session, don't chart a map; just do it.

The destination varies per effort, and naming it is the first act of charting because it shapes every ticket. It might be a spec to hand off, a decision to lock before work starts, or a change made in place. The map is domain-agnostic across coding projects, app projects, exams, cloud-security work, or whatever else fits the shape.

## Plan, don't do

Wayfinder is **planning** by default: each ticket resolves a decision, and the map is done when the way is clear, with nothing left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. The one exception is the Task ticket type (below), which does rather than decides.

## Continuity, capabilities, and principles

Load the canonical owner when its trigger fires:

- `principle-guard-the-context-window` keeps the map as a low-resolution index and loads ticket detail only for the active decision.
- `principle-sequence-verifiable-units` makes one ticket the normal session unit, with a checkable resolution before the frontier advances.
- `principle-never-block-on-the-human` sends observable facts and independent research to AFK work while preserving HITL ownership of product, scope, architecture, contract, and security decisions.
- `show-me-your-work` records an auditable decision trail for long, unattended, or measurement-heavy tickets.
- Parallel `delegate_task` workers handle independent research only; the map owner verifies artifacts and synthesizes the result.
- `hillclimb` governs multi-session measurement work with a frozen harness and one keep-or-revert iteration per work unit.
- `session-pickup` reconciles a resumed map with live tracker and repository state. `pause-safely` records evidence and the next completion criterion before a session boundary.

Record which ticket shape, ownership mode, or continuation step each principle changed. Do not copy the specialist procedure into the map.

## Refer by name

Every map and ticket is an issue, so it has a **name**, namely its title. In everything the human reads, including narration and the map's Decisions-so-far, refer to it by that name, never by a bare id, number, or slug. A wall of `#42, #43, #44` is illegible; names read at a glance. The id and URL don't vanish: a name wraps its link, but they ride *inside* the name, never stand in for it.

## The Map

The map is a single issue on the tracker, labelled `wayfinder:map`. Its tickets are child issues of the map.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place, its ticket, so the map never restates it, only gists it and links.

### Tracker choice

Where the map, its child tickets, blocking, and frontier queries physically live is tracker-specific. Consult `docs/agents/issue-tracker.md`'s "Wayfinding operations" section for how *this* repo expresses them. Use GitHub Issues if the repo has a GitHub remote, personal Linear otherwise, and never a local-markdown tracker (a map needs a real tracker to show blocking edges visually). If that file doesn't exist yet, tell the user to run `/dev-cycle-setup` ad hoc in the moment because it is user-invoked and you can't call it yourself. That is not a reason to write tracker state to local files.

### The map body

Loaded once per session. Open tickets are **not** listed; they are open child issues, found by query.

```markdown
## Destination

<what reaching the end of this map looks like. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult (e.g. /grilling, /domain-modeling, /architect, /coding-standards, /testing); standing preferences for this effort>

## Decisions so far

- [<closed ticket title>](link): <one-line gist of the answer>

## Not yet specified

<!-- fog of war: in-scope, not yet sharp enough to ticket -->

## Out of scope

<!-- work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is a **child issue** of the map. Its body is the question, sized to one session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries a `wayfinder:<type>` label: `research`, `grilling`, or `task`.

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work. An open, unassigned ticket is unclaimed.

Blocking uses the tracker's native dependency relationship, so the frontier renders visually in the tracker's own UI. A ticket is **unblocked** when everything blocking it is closed; the **frontier** is the open, unblocked, unclaimed children.

The answer isn't part of the body. Record it when resolving the ticket. Assets created while resolving a ticket are linked from the issue, not pasted in.

## Ticket Types

Every ticket is either **HITL**, meaning human in the loop and worked *with* a human who speaks for themselves, or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange.

- **Research** (AFK): Reading documentation, third-party APIs, or local resources to surface a fact a decision waits on. Resolved by a subagent following the research flow from `/coding-standards`. Verify against current sources (search → extract, browser if needed), never from memory, returning *verified, context-lean* findings (excerpts/URLs, not page dumps). Fire these in parallel at charting time, capturing findings on a throwaway `research/<name>` branch with a context pointer from the ticket.
- **Grilling** (HITL, default case): Conversation, one question at a time. Read the `grilling` and `domain-modeling` skills to sharpen the terms the question turns on, and additionally consult `architect` (architecture, bounded contexts) and `coding-standards` (types, dependencies) whenever the decision is code-shaped.
- **Task** (HITL or AFK): Manual work that must happen before a decision can be made. There is nothing to decide or research, but the discussion is blocked until it's done. Signing up for a service, provisioning access, moving data. This is the one type that *does* rather than decides. It earns its place by unblocking a decision, not by delivering the destination.
  - **AFK Task tickets are restricted to non-code chores.** Anything that touches code is HITL, and follows the interaction protocol (confirm before code) before anything gets written; this rule has no exception for wayfinder.
  - Resolved when the work is done; the answer records what was done and any resulting facts later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete. Beyond the live tickets lies the **fog of war**, which contains decisions and investigations you can tell are coming but can't yet pin down because they hang on questions still open. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets, one at a time.

The map's **Not yet specified** section holds that dim view: the suspected question, the area to revisit later.

**Fog or ticket?** The test is whether you can state the question precisely now, not whether you can answer it now.

- **Ticket when** the question is already sharp, even if blocked.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog into ticket-sized pieces; one patch may graduate into several tickets, or none.

## Out of scope

The destination fixes the scope; work beyond it is **out of scope**, not fog. It gets its own **Out of scope** section: work consciously ruled out of this effort.

When a ticket turns out to sit past the destination, **close it** and leave one line in **Out of scope**: the gist plus why, linking the closed ticket. It stays out of **Decisions so far**; a scope boundary isn't a step on the route.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session**; research tickets are the exception and can run in parallel.

### Chart the map

User invokes with a loose idea.

1. **Name the destination.** Read the `grilling` and `domain-modeling` skills to pin down the language the destination is stated in, informed by `architect` and `coding-standards` when the destination is code-shaped, to pin down what this map is finding its way to.
2. **Map the frontier.** Grill again, breadth-first: fan out across the whole space rather than deep on any one thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog**, meaning the whole journey fits in one session, stop; you don't need a map. Ask how to proceed instead.
3. **Create the map** (label `wayfinder:map`) on the right tracker: use GitHub Issues if in a repo, personal Linear otherwise. Destination and Notes filled in, Decisions-so-far empty, the fog sketched into Not yet specified.
4. **Create the tickets you can specify now** as child issues, then wire blocking edges in a second pass. Everything you can't yet specify stays in the fog.
5. **Fire the research subagents** in parallel, one sub-agent per research ticket just created, following the coding-standards research flow, capturing findings on a throwaway `research/<name>` branch with a context pointer from the ticket. Each runs isolated.
6. Stop. Charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a map (URL or number). A ticket is optional. Without one, pick the next decision, not the user.

1. Load the map, using the low-res view rather than every ticket body.
2. Choose the ticket. If named, use it. Otherwise take the first frontier ticket in order. **Claim it** by assigning it to yourself before any work.
3. Resolve it, zooming as needed: fetch the full body of any related or closed ticket on demand; read whichever skills the Notes block names. If in doubt, read the `grilling` and `domain-modeling` skills.
4. Record the resolution: post the answer as a resolution comment, close the issue, append a context pointer to the map's Decisions-so-far.
5. Add newly-surfaced tickets (create-then-wire); graduate any fog the answer made specifiable, clearing it from Not yet specified. If the answer reveals a ticket sits beyond the destination, rule it out of scope rather than resolving it. If the decision invalidates other parts of the map, update or delete those tickets.
6. **When the frontier empties and Not yet specified holds nothing further, the map is done. Hand off instead of building.** Tell the user to run `/to-spec` against this map. It is user-invoked, so you can't call it yourself; the command reads every closed ticket's full body and the map's Decisions-so-far, then collapses them into one buildable spec. The pipeline after hand-off (to-spec → to-tickets → implement → code-review, checkpoints and invocation rules) lives in the `dev-cycle` skill; read it before proceeding. Looping straight into `/implement` from the map skips that collapse and throws the linked detail away. Skip the handoff only when the resolved map turned out small enough that a spec would just restate one ticket.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker concurrently.
