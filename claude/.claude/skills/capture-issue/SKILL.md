---
name: capture-issue
description: Capture a new issue quickly when the idea should be recorded now and explored later.
disable-model-invocation: true
---

# Capture Issue

Create a new issue from the user's current request when they want to record an idea without grilling or repository exploration. This is a parked capture, not a specification or an implementation ticket.

Read `writing-for-agents` before writing the issue title or body. Keep the result minimal: synthesize a concise title and minimally clean the user's text without adding requirements, acceptance criteria, architecture, testing decisions, or scope claims.

The issue tracker and issue-label vocabulary must be configured before this skill runs. If `docs/agents/issue-tracker.md` or `docs/agents/triage-labels.md` is missing, tell the user to run `dev-cycle-setup` and stop without publishing. Read `docs/agents/issue-tracker.md` for the tracker's issue-creation operations and quick-capture rules, then read the right-hand mappings in `docs/agents/triage-labels.md`: `bug` and `enhancement` are fixed category labels, while the state and workflow-marker labels may be tracker-specific.

## Process

1. Read the user's request as the only source material. Do not explore the repository or ask design questions.
2. Classify the request as exactly one category: `bug` or `enhancement`.
3. If the category is ambiguous, ask one focused classification question before publishing. Do not ask any other question in this skill.
4. Create a new issue in the configured tracker with the concise title and minimally cleaned body.
5. Apply the category label and the configured labels for the `needs-triage` state and `needs-grilling` marker.
6. Report the created issue and stop. Do not apply `ready-for-agent` and do not start grilling, `to-spec`, `to-tickets`, or `implement`.

## Resuming from a fresh session

The created issue URL or number is the handoff between sessions. The issue body and labels must be enough to find and classify the parked idea without this conversation.

Later, from a fresh session with no capture context:

1. Invoke `/grilling <issue URL or number>`. `grilling` reads the issue's full body, comments, and labels through the configured tracker before asking questions.
2. After the grilling hand-off, invoke `/to-spec <same issue URL or number>`. `to-spec` rereads the issue and comments, writes the complete spec to that same issue, and replaces the configured `needs-triage` state and `needs-grilling` marker with `ready-for-agent`.
3. Invoke `/to-tickets <same issue URL or number>` only if the complete spec needs multiple implementation slices. Otherwise invoke `/implement <same issue URL or number>` directly.

The capture session itself stops after publishing. It does not try to grill, create a spec, or preserve hidden state in the original conversation.
