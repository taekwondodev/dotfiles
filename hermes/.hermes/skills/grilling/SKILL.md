---
name: grilling
description: Resolve decisions through evidence, investigation, and a structured design tree.
---

# Grilling

Interview the user until the decision tree is complete and shared understanding is reached. Before asking a question, determine whether it is a fact, a hypothesis, or a decision. Facts belong to tools and investigation. Decisions belong to the user.

This skill is the understanding phase of `dev-cycle`. It does not publish a spec or implement code. It may investigate, prototype, profile, or run read-only forensics before asking questions.

## Pre-flight

Read the repository context before the first decision round:

- `AGENTS.md`;
- `CONTEXT.md` or `CONTEXT-MAP.md`;
- relevant ADRs;
- relevant README or design documents;
- the issue body, comments, and labels when the user provides an issue reference;
- the current conversation.

Treat an explicit, unambiguous decision in these sources as settled. Do not ask it again. If sources conflict, ask about the conflict after presenting the evidence.

## Design tree

Keep a ledger of:

- settled decisions and their source;
- facts verified by tools;
- hypotheses still being tested;
- questions already asked;
- decisions still at the frontier;
- capabilities activated and their completion status.

The frontier contains only decisions whose prerequisites are settled. Recompute it after every user answer or investigation result.

## Classify before asking

For every apparent question, classify it first.

### Fact

A fact can be observed from the repository, runtime, tool output, documentation, issue tracker, or another accessible source. Investigate it. Do not ask the user.

### Hypothesis

A hypothesis can be tested with a probe, prototype, benchmark, or forensic artifact. Test it when the result is cheaper and safer than asking.

### Decision

A decision changes product behavior, scope, architecture, ownership, contracts, security, or user preference. Ask the user with `clarify`.

When uncertain, do not silently convert a decision into an agent preference. State the evidence and ask.

## Investigation capabilities

Load only the specialist skill that matches the uncertainty. The specialist owns its procedure; `grilling` owns the trigger and reintegrates its evidence into the design tree.

- Load `how` for current code flow, ownership, layering, and runtime walkthroughs.
- Load `why` for rationale, historical decisions, regressions, ADRs, and non-obvious constraints.
- Load `investigation` for a read-only question, unknown cause, or bug reproduction.
- Load `prototype` when an empirical technical fork is cheaper to test than discuss.
- Load `runtime-forensics` when the symptom exists in a live process.
- Load `trace-forensics` when the user supplies an existing profile, trace, snapshot, or spindump.
- Load `perf-issue` for one measured performance problem.
- Load `hillclimb` for sustained improvement against a fixed metric and stop predicate.

Completion criterion: the specialist returns sourced evidence, a reproducible observation, or an explicit unresolved uncertainty; the design tree records what changed and recomputes the frontier.

## Architecture escalation

When investigation reveals an unsettled data shape, module boundary, ownership model, dependency direction, public interface, bounded context, or security boundary, activate `architect`.

`architect` grounds the system, creates the sketch, uses `arena` for genuinely contested alternatives, and proceeds without an automatic checkpoint. Ask for a checkpoint only when the user explicitly wants to review the sketch before implementation.

## User questions

For each decision round, use `clarify`. Do not ask decision questions directly in the response text.

- Include concrete choices.
- Put alternatives only in `choices`.
- Put the most likely current path first, without presenting it as mandatory.
- Batch independent frontier questions in one `clarify` call.
- Do not ask a question whose answer depends on another question still open in the same round.
- If the user adds context or corrects an assumption, stop the current round and regenerate the affected frontier.

## Checkpoint and handoff

The grilling session ends only when every reachable branch of the design tree is settled and the user confirms shared understanding.

Then stop. Report:

- decisions made;
- evidence gathered;
- alternatives rejected;
- principles that changed choices;
- unresolved risks;
- the recommended next phase.

Do not start `to-spec`, `to-tickets`, `implement`, or `code-review` automatically. The user invokes the next phase.

## Verification

Before handing off, confirm:

- every question asked was a genuine user-owned decision;
- every investigated fact has a source or reproducible observation;
- hypotheses are marked confirmed, rejected, or unresolved;
- the frontier is empty;
- no silent product, scope, architecture, or security choice remains;
- the handoff names the next completion criterion.
