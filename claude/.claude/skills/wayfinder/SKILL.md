---
name: wayfinder
description: Plan a huge chunk of work — more than one agent session can hold — as a shared map of decision tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear.
disable-model-invocation: true
---

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **shared map** on the repo's issue tracker, then works its **decision tickets** — questions whose resolution is a decision, not slices of a build to execute — one at a time until the route is clear.

**Only invoke this for work that is genuinely too big for one session.** If the task fits in one session, don't chart a map — just do it.

The destination varies per effort, and naming it is the first act of charting — it shapes every ticket. It might be a spec to hand off, a decision to lock before work starts, or a change made in place. The map is domain-agnostic across coding projects, app projects, exams, cloud-security work — whatever fits the shape.

## Plan, don't do

Wayfinder is **planning** by default: each ticket resolves a decision, and the map is done when the way is clear — nothing left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. The one exception is the Task ticket type (below), which does rather than decides.

## Refer by name

Every map and ticket is an issue, so it has a **name** — its title. In everything the human reads — narration, the map's Decisions-so-far — refer to it by that name, never by a bare id, number, or slug. A wall of `#42, #43, #44` is illegible; names read at a glance. The id and URL don't vanish — a name wraps its link — but they ride *inside* the name, never stand in for it.

## The Map

The map is a single issue on the tracker, labelled `wayfinder:map`. Its tickets are child issues of the map.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place — its ticket — so the map never restates it, only gists it and links.

### Tracker choice

Where the map, its child tickets, blocking, and frontier queries physically live is tracker-specific. Consult `docs/agents/issue-tracker.md`'s "Wayfinding operations" section for how *this* repo expresses them — GitHub Issues if the repo has a GitHub remote, personal Linear otherwise, never a local-markdown tracker (a map needs a real tracker to show blocking edges visually). If that file doesn't exist yet, tell the user to run `/dev-cycle-setup` ad hoc in the moment — it's user-invoked, so you can't call it yourself; not a reason to write tracker state to local files.

### The map body

Loaded once per session. Open tickets are **not** listed — they are open child issues, found by query.

```markdown
## Destination

<what reaching the end of this map looks like. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult (e.g. /grilling, /domain-modeling, /design, /coding-standards, /testing); standing preferences for this effort>

## Decisions so far

- [<closed ticket title>](link) — <one-line gist of the answer>

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

Each ticket carries a `wayfinder:<type>` label — `research`, `grilling`, or `task`.

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work. An open, unassigned ticket is unclaimed.

Blocking uses the tracker's native dependency relationship, so the frontier renders visually in the tracker's own UI. A ticket is **unblocked** when everything blocking it is closed; the **frontier** is the open, unblocked, unclaimed children.

The answer isn't part of the body — it's recorded on resolution. Assets created while resolving a ticket are linked from the issue, not pasted in.

## Ticket Types

Every ticket is either **HITL** — human in the loop, worked *with* a human who speaks for themselves — or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange.

- **Research** (AFK): Reading documentation, third-party APIs, or local resources to surface a fact a decision waits on. Resolved by a subagent following the research flow from `/coding-standards` — verify against current sources (`web_search` → `web_extract`, browser if needed), never from memory, returning *verified, context-lean* findings (excerpts/URLs, not page dumps). Fire these in parallel at charting time, capturing findings on a throwaway `research/<name>` branch with a context pointer from the ticket.
- **Grilling** (HITL, default case): Conversation, one question at a time. Read the `grilling` and `domain-modeling` skills to sharpen the terms the question turns on, and additionally consult `design` (architecture, bounded contexts) and `coding-standards` (types, dependencies) whenever the decision is code-shaped.
- **Task** (HITL or AFK): Manual work that must happen before a decision can be made — nothing to decide or research, but the discussion is blocked until it's done. Signing up for a service, provisioning access, moving data. This is the one type that *does* rather than decides — it earns its place by unblocking a decision, not by delivering the destination.
  - **AFK Task tickets are restricted to non-code chores.** Anything that touches code is HITL, and follows the interaction protocol (confirm before code) before anything gets written — no exception for wayfinder.
  - Resolved when the work is done; the answer records what was done and any resulting facts later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete. Beyond the live tickets lies the **fog of war** — decisions and investigations you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets — one at a time.

The map's **Not yet specified** section holds that dim view: the suspected question, the area to revisit later.

**Fog or ticket?** The test is whether you can state the question precisely now — not whether you can answer it now.

- **Ticket when** the question is already sharp — even if blocked.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog into ticket-sized pieces; one patch may graduate into several tickets, or none.

## Out of scope

The destination fixes the scope; work beyond it is **out of scope**, not fog. It gets its own **Out of scope** section: work consciously ruled out of this effort.

When a ticket turns out to sit past the destination, **close it** and leave one line in **Out of scope**: the gist plus why, linking the closed ticket. It stays out of **Decisions so far** — a scope boundary isn't a step on the route.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session** — except research tickets, which can run in parallel.

### Chart the map

User invokes with a loose idea.

1. **Name the destination.** Read the `grilling` and `domain-modeling` skills to pin down the language the destination is stated in, informed by `design` and `coding-standards` when the destination is code-shaped, to pin down what this map is finding its way to.
2. **Map the frontier.** Grill again, breadth-first: fan out across the whole space rather than deep on any one thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog** — the whole journey fits in one session — stop, you don't need a map. Ask how to proceed instead.
3. **Create the map** (label `wayfinder:map`) on the right tracker — GitHub Issues if in a repo, personal Linear otherwise. Destination and Notes filled in, Decisions-so-far empty, the fog sketched into Not yet specified.
4. **Create the tickets you can specify now** as child issues, then wire blocking edges in a second pass. Everything you can't yet specify stays in the fog.
5. **Fire the research subagents** in parallel — one `delegate_task` per research ticket just created, following the coding-standards research flow, capturing findings on a throwaway `research/<name>` branch with a context pointer from the ticket. Each runs isolated and visible in the session, never stealing focus.
6. Stop — charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a map (URL or number). A ticket is optional — without one, pick the next decision, not the user.

1. Load the map — the low-res view, not every ticket body.
2. Choose the ticket. If named, use it. Otherwise take the first frontier ticket in order. **Claim it** — assign it to yourself before any work.
3. Resolve it — zoom as needed: fetch the full body of any related or closed ticket on demand; read whichever skills the Notes block names. If in doubt, read the `grilling` and `domain-modeling` skills.
4. Record the resolution: post the answer as a resolution comment, close the issue, append a context pointer to the map's Decisions-so-far.
5. Add newly-surfaced tickets (create-then-wire); graduate any fog the answer made specifiable, clearing it from Not yet specified. If the answer reveals a ticket sits beyond the destination, rule it out of scope rather than resolving it. If the decision invalidates other parts of the map, update or delete those tickets.
6. **When the frontier empties and Not yet specified holds nothing further, the map is done — hand off, don't build.** Tell the user to run `/to-spec`, pointing it at this map — it's user-invoked, so you can't call it yourself: it reads every closed ticket's full body and the map's Decisions-so-far, and collapses them into one buildable spec. The pipeline after hand-off (to-spec → to-tickets → implement → code-review, checkpoints and invocation rules) lives in the `dev-cycle` skill — read it before proceeding. Looping straight into `/implement` from the map skips that collapse and throws the linked detail away — only skip the handoff when the resolved map turned out small enough that a spec would just restate one ticket.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker concurrently.
