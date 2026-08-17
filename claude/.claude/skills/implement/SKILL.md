---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, writing tests against the spec's Testing Decisions and closing out with /code-review before committing."
disable-model-invocation: true
---

Implement the work described by the user in the spec or ticket.

**This step is user-invoked**: do not start it on your own — the user triggers it explicitly (normally by approving a spec or tickets, after grilling/to-spec/to-tickets). The pipeline, its checkpoints, and the invocation rules live in the `dev-cycle` skill — read it before proceeding.

Read the ticket's **Layer(s)** line first (`/to-tickets`/`/triage` set it) — it tells you which of `/design`'s Handler/Service/Repository/Middleware layers this touches before you open a single file.

Build against `/design` and `/coding-standards` throughout, not just at review time: place new code in the layer the ticket names, wire it through the port the layer already exposes, and apply `/coding-standards`' TyDD/dependency/secure-defaults rules as you write each piece — don't defer them to `/code-review` to catch after the fact.

Write tests alongside the implementation, at the seams `/testing` allows. Take expected values from the spec/ticket's Testing Decisions or acceptance criteria, never invent them from the same reasoning that produced the implementation — that's the self-graded anti-pattern in `/testing`'s Test quality section. Layers outside `/testing`'s scope get integration coverage instead — never a unit test bent to reach them.

Run typechecking regularly, single test files regularly, and the full test suite once at the end. If `HERDR_ENV=1`, run the test suite in watch mode on a herdr sibling pane instead of re-invoking it inline each cycle — read its output rather than re-running it. Run `herdr --skill` for the mechanics; don't restate its CLI here.

When closing a ticket unblocks new frontier tickets (per `docs/agents/issue-tracker.md`), and `HERDR_ENV=1`, **ask** the user whether to open a herdr sibling pane running `/implement` on one of them — never spawn it without asking first.

Once done, call the Skill tool with "code-review" to review the work against this ticket, with `git rev-parse` of the ticket's starting commit as the fixed point — its Standards axis independently judges the tests you wrote, catching what a self-graded pass would miss. A hard `/coding-standards`/`/design` violation or a missing Spec requirement blocks the commit — fix it and re-review, don't commit around it.

Commit your work to the current branch, then close the ticket per `docs/agents/issue-tracker.md`'s tracer-bullet operations.
