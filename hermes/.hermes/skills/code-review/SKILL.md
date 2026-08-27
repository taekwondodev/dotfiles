---
name: code-review
description: Review a diff on Standards, Spec, and Adversarial axes.
---

Three-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards**: does the code conform to `/coding-standards` and `/architect`?
- **Spec**: does the code faithfully implement the originating issue / spec?
- **Adversarial**: what unsafe assumption, hidden impact, or unproven claim survives the first two axes?

The Standards axis also checks the applicable principles through their canonical skills. The no-comments rule comes only from `/coding-standards`; do not create a second comments policy here.

The Adversarial axis loads `interrogate` and uses `blast-radius` evidence to challenge callers, contracts, migrations, runtime effects, and verification without merging its findings into Standards or Spec.

All available axes run as **parallel sub-agents** so they do not pollute each other's context, then this skill reports them side by side.

`/implement` invokes this automatically as its close-out step, before committing. Reach for it directly whenever you want to review a branch or PR against a fixed point.

The issue tracker should have been provided to you. Tell the user to run `/dev-cycle-setup` if `docs/agents/issue-tracker.md` is missing; it's user-invoked, so you can't call it yourself.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point: a commit SHA, branch name, tag, `main`, `HEAD~5`, etc. If they didn't specify one, ask for it. Inside `/implement`, the fixed point is always the ticket's starting commit.

Resolve the comparison base once with `git merge-base <fixed-point> HEAD`, then capture the review command as `git diff <merge-base>`. Comparing the working tree to the merge-base includes committed, staged, and unstaged changes; `git diff <fixed-point>...HEAD` would silently omit uncommitted implementation work. Also record `git status --short` and the commit list via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`), the merge-base resolves, and the working-tree diff is non-empty. A bad ref or empty diff should fail here, not inside the parallel sub-agents. Treat untracked paths in `git status --short` as review inputs and pass their paths to every reviewer because Git does not include their contents in a diff until they are staged.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, etc.). Fetch via the workflow in `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. A `/to-spec`-published issue or `/to-tickets` ticket matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. The standards source

The Standards axis is anchored on this repo's own rules, never a generic baseline:

- **`/coding-standards`**: TyDD, dependency management, secure defaults, visibility, secrets hygiene, version/API lookup discipline.
- **`/architect`**: layering (Handler/Service/Repository/Middleware), bounded contexts, shared kernel, cross-boundary error handling, observability, threat modeling.
- **`/testing`**: scope rule and the Test quality anti-patterns (implementation-coupled, tautological, self-graded). `/implement` writes tests itself, so this axis is their only independent judge.

Read all three skills' full bodies before spawning the sub-agent. The sub-agent gets them pasted in, not a pointer, since it has no other access.

Select every canonical principle skill whose trigger fires in the spec or diff and paste its full body into the Standards context. A principle is reviewable only through the concrete type, boundary, ownership, migration, or verification choice it should have changed.

Load `blast-radius` before dispatch when the diff changes a shared symbol, contract, data shape, migration, or persisted behavior. Pass confirmed consumers, checks, and unproven risks to all applicable reviewers.

Underneath those, the axis also carries the **smell baseline** below: a fixed set of Fowler code smells (_Refactoring_, ch.3) for anything `/coding-standards`/`/architect` don't already cover. Two rules bind it:

- **`/coding-standards` and `/architect` override.** Where either endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Like any standard here, skip anything tooling already enforces (linters, type checker).

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. This signals it's living in the wrong `/architect` layer. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together. This suggests a type wanting to be born: a Domain Type per `/coding-standards`' TyDD rule. → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type; make the invalid state unrepresentable.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module, respecting `/architect`'s layer boundaries.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn independent reviewers in parallel

Dispatch the three axes as parallel sub-agents (one per axis), each with the corresponding prompt below. Each runs in its own isolated context. The review prompts carry their source material explicitly, since each sub-agent has no other access.

**Standards sub-agent prompt**: include:

- The full diff command and commit list.
- The full bodies of `/coding-standards`, `/architect`, `/testing`'s Test quality section, and every applicable principle, **plus the smell baseline from step 3** pasted in full. The sub-agent has no other access to any of it.
- The brief: "Report, per file/hunk where relevant: (a) every place the diff violates `/coding-standards`, `/architect`, or an applicable principle: cite the rule and the concrete decision it should have changed; (b) any baseline smell you spot: name it and quote the hunk; (c) any test that's implementation-coupled, tautological, or self-graded per `/testing`'s Test quality section; quote the assertion and name which one. Distinguish hard violations from judgement calls. Standards and Test quality violations can be hard, but baseline smells are always judgement calls, and canonical skills override the baseline where they conflict. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt**: include:

- The diff command and commit list.
- The path or fetched contents of the spec/ticket.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. For a refactoring, also verify the pinned behavior and target-shape contract. Quote the spec line for each finding. Under 400 words."

**Adversarial sub-agent prompt**: include:

- The diff command, commit list, full `interrogate` body, relevant `blast-radius` findings, and spec when available.
- The brief: "Challenge the diff independently. Look for unsafe assumptions, affected consumers missed by the visible diff, migration or rollback gaps, security and runtime failure modes, and tests or checks that do not prove the claim. Do not propose scope expansion by default. Cite a file, hunk, requirement, consumer, or observable behavior for every finding. Categorize each as act on, consider, noted, or dismissed. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report. Standards and Adversarial still run.

### 5. Aggregate

Present the reports under `## Standards`, `## Spec`, and `## Adversarial` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings. The axes are deliberately separate (see _Why separate axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Do not pick a single winner across axes.

Inside `/implement`: a hard Standards violation, a missing Spec requirement, or an evidenced Adversarial finding categorized `act on` blocks the commit. Fix it and rerun every affected axis rather than committing around it. Judgement-call smells, scope-creep notes, and `consider` findings do not block; surface them and let the user decide.

## Why separate axes

A change can pass one axis and fail another:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**
- Code that satisfies both but relies on an unsafe assumption or misses a distant consumer → **Standards and Spec pass, Adversarial fail.**

Reporting them separately stops one axis from masking another.
