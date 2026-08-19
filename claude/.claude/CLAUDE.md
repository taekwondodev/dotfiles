# CLAUDE.md

## Interaction Protocol

Applies to ad-hoc work outside the dev-cycle skills (`/grilling`, `/to-spec`, `/to-tickets`, `/implement`, `/wayfinder`): those own their own approval gates and this protocol never overrides them.

- 80% rule: confidence < 80% → ask first. No code until clear.
- Implementation: explain + snippet → confirm → implement.
- Spot optimization → propose.

## Dev-cycle approval model

Human checkpoint sits at design time: `/grilling`/`/to-spec`/`/to-tickets` settle architecture, seams, and tradeoffs with you before any code exists. Once a ticket is approved, `/implement` runs to commit without stopping per file; `/code-review` is the safety net before the commit, and the diff is yours to read after.

## Prose style

Plain English prose only. Never use em-dashes (—); prefer commas, colons, periods, or parentheses.
