---
name: code-review
description: Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes — Standards (does the code follow /coding-standards and /design?) and Spec (does the code match what the originating issue/spec asked for?). Runs both reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X".
---

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to `/coding-standards` and `/design`?
- **Spec** — does the code faithfully implement the originating issue / spec?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

`/implement` invokes this automatically as its close-out step, before committing. Reach for it directly whenever you want to review a branch or PR against a fixed point.

The issue tracker should have been provided to you — tell the user to run `/dev-cycle-setup` if `docs/agents/issue-tracker.md` is missing; it's user-invoked, so you can't call it yourself.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, etc. If they didn't specify one, ask for it. Inside `/implement`, the fixed point is always the ticket's starting commit.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here — not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, etc.) — fetch via the workflow in `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. A `/to-spec`-published issue or `/to-tickets` ticket matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. The standards source

The Standards axis is anchored on this repo's own rules, never a generic baseline:

- **`/coding-standards`** — TyDD, dependency management, secure defaults, visibility, secrets hygiene, version/API lookup discipline.
- **`/design`** — layering (Handler/Service/Repository/Middleware), bounded contexts, shared kernel, cross-boundary error handling, observability, threat modeling.
- **`/testing`** — scope rule and the Test quality anti-patterns (implementation-coupled, tautological, self-graded). `/implement` writes tests itself, so this axis is their only independent judge.

Read all three skills' full bodies before spawning the sub-agent — the sub-agent gets them pasted in, not a pointer, since it has no other access.

Underneath those, the axis also carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) for anything `/coding-standards`/`/design` don't already cover. Two rules bind it:

- **`/coding-standards` and `/design` override.** Where either endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces (linters, type checker).

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own — a signal it's living in the wrong `/design` layer. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born — a Domain Type per `/coding-standards`' TyDD rule). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type; make the invalid state unrepresentable.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module, respecting `/design`'s layer boundaries.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both reviewers in parallel

If `HERDR_ENV=1`, run each axis as its own **herdr sibling pane** (named `review-standards` and `review-spec`) instead of a Task sub-agent — real process isolation, visible to the user, never stealing focus. Run `herdr --skill` for the mechanics; it is the sole authority on current CLI syntax, don't restate it here. If `HERDR_ENV` is not set, fall back to two parallel **Task sub-agents** with the same two prompts below.

Both axes run as the configured delegation model (Hermes routes subagents via `delegation.model`/`delegation.provider`). The review prompts carry their standards/spec context explicitly, since each sub-agent has no other access.

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The full bodies of `/coding-standards`, `/design`, and `/testing`'s Test quality section, **plus the smell baseline from step 3** pasted in full — the sub-agent has no other access to any of it.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates `/coding-standards` or `/design`: cite the rule; (b) any baseline smell you spot: name it and quote the hunk; (c) any test that's implementation-coupled, tautological, or self-graded per `/testing`'s Test quality section — quote the assertion and name which one. Distinguish hard violations from judgement calls — `/coding-standards`/`/design` breaches and Test quality violations can be hard, but baseline smells are always judgement calls, and either skill overrides the baseline where they conflict. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The path or fetched contents of the spec/ticket.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings — the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes — that's the reranking the separation exists to prevent.

Inside `/implement`: a hard `/coding-standards`/`/design`/Test-quality violation or a missing Spec requirement blocks the commit — fix it rather than committing around it. Judgement-call smells and scope-creep notes don't block; surface them and let the user decide.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
