---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

## Pre-flight: use existing project context first

Before asking the first question, inspect the repository's project context file (`AGENTS.md`), `CONTEXT.md`, relevant ADRs, README/design docs, and the current conversation. Treat a decision as **already settled** when the answer is explicit and unambiguous in those sources. Do not ask the user to reconfirm it, and do not ask a differently worded version of a question already answered there or earlier in the conversation. Carry those decisions into the tree and cite the source briefly when useful.

If sources disagree, are stale/ambiguous, or leave a meaningful decision genuinely open, ask about the conflict/open choice instead. Facts are not questions: look them up with tools. Only ask the user for a fact when it cannot be retrieved. Keep a short internal ledger of settled decisions and asked questions so later rounds do not repeat them.

When the user provides an issue reference, first read `docs/agents/issue-tracker.md`, then fetch that issue's full body, comments, and labels through the configured tracker before asking questions. Treat it as the working context, preserve its original intent, and hand the same issue to `to-spec` rather than creating a duplicate. This skill only interviews; it does not write the issue.

## User questions

For every decision round, use the `clarify` tool to ask the user the frontier questions. Do not ask bare questions directly in the response text. Every decision question must include concrete answer options; if the space is open-ended, include plausible alternatives plus `Altro (specifica tu)`. Put options only in `clarify.choices`, never inline in the question text. The first option is displayed as the recommended/default choice by the UI, so order choices deliberately and do not imply that the user must accept it.

A `clarify` response is not automatically a decision to be made. If the user writes that they need to add context, correct an assumption, or discuss something before answering the displayed questions, treat that message as direct steering/context: not as “skipped”, not as acceptance of a default, and not as a queued follow-up. Stop the current grilling round, incorporate the message, and regenerate the relevant questions only after addressing that context. Never choose an option on the user's behalf merely because they interrupted or declined the `clarify` prompt.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round, then wait for the user's answers before the next round. Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding. **Then STOP and hand off**. Report the decisions and ask the user how to proceed. Never start to-spec/to-tickets/implement on your own: the pipeline, its checkpoints, and the invocation rules live in the `dev-cycle` skill; read it before proceeding.
