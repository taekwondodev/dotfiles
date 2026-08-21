# Issue tracker: Linear

Issues, specs, and tickets for this repo (or non-repo effort) live in personal Linear.

Exact tool/API surface is not hardcoded here because Linear's MCP tools or CLI change independently of this file. Before the first operation in a session, check what Linear integration is actually connected (an `mcp__linear__*` tool, or a CLI) and use it; **never guess field names or endpoints from memory** (`/coding-standards`' version/API lookup rule applies here too). If nothing is connected, say so and ask the user to connect one rather than fabricating a call.

## Conventions

- **Create an issue**: via the connected tool, with a title and body.
- **Read an issue**: fetch by id/url, including comments and labels.
- **List issues**: filter by label/state as the connected tool allows.
- **Comment on an issue**: via the connected tool.
- **Update an issue body**: via the connected tool, preserving the existing issue id and comments.
- **Apply / remove labels**: via the connected tool.
- **Close**: mark done/cancelled via the connected tool.

## When a skill says "publish to the issue tracker"

Create a Linear issue.

## When a skill says "fetch the relevant ticket"

Fetch the issue by its id or URL.

## Quick issue capture

Used by `/capture-issue`. Create a new issue with exactly one fixed category label (`bug` or `enhancement`), the configured `needs-triage` state label, and the configured `needs-grilling` workflow marker. The issue is intentionally incomplete and must not receive `ready-for-agent` until a complete spec exists.

When `/to-spec` completes an existing issue, update its body in place through the connected tool, then apply and remove labels in the same transition. Do not create a replacement issue.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single Linear issue, titled with the destination, holding the Destination / Notes / Decisions-so-far / Not yet specified / Out of scope body. Tag it according to how this Linear workspace marks a parent/tracking issue (label or project).
- **Child ticket**: a Linear sub-issue of the map. Encode the ticket type (`research`/`grilling`/`task`) as a label. Once claimed, assign it to the driving dev.
- **Blocking**: Linear's native issue-relation "blocks/blocked by"; set it through the connected tool, never a body convention, so the frontier is visible in Linear's own UI.
- **Frontier query**: the map's open, unassigned sub-issues with no open blocker; first in map order wins.
- **Claim**: assign the issue to yourself. This is the session's first write.
- **Resolve**: comment the answer, close the issue, then append a context pointer (gist + link) to the map's Decisions-so-far.

## Tracer-bullet ticket operations

Used by `/to-tickets` and `/implement`.

- **Ticket**: a Linear issue, one per tracer-bullet slice. Body states the layer(s) touched (Handler/Service/Repository, per `/design`) and the behaviour to build.
- **Blocking**: same native blocks/blocked-by relation as wayfinding above.
- **Grabbing work**: any ticket whose blockers are all closed and which is unassigned is takeable. Claim it before `/implement` starts.
- **Closing out**: `/implement` closes the ticket only after `/code-review` passes and the commit lands.
