---
name: handoff
description: >
  Context bridge for session continuity. Synthesizes conversation state, git status, and pending
  work into a structured HANDOFF.md, then produces a copy-paste resume prompt for the next session.
  Invoke when user says "save context", "new session", "continue later", "save progress",
  "running out of context", "handoff", "context limit", or when context window is nearly full
  and the current task is incomplete.
argument-hint: "What will the next session focus on?"
---

## Steps

Read `writing-for-agents` before writing `HANDOFF.md` or its resume prompt. Its general writing rules govern the handoff; this skill adds only handoff-specific structure.

### 1. Gather State

Run: `git status && git diff HEAD && git log --oneline -10`

### 2. Synthesize

Extract from conversation + git state:

- **Task:** goal in 1-3 sentences. If args given, weight toward that focus.
- **Progress:** done items (file names, functions, decisions)
- **What Didn't Work:** failed approaches that the next agent should not repeat
- **Pending:** ordered, most critical first
- **Decisions & Context:** non-obvious choices, constraints, gotchas a fresh agent can't derive from code
- **Files Changed:** path: one-line description
- **Blockers:** stuck or unclear items
- **Active Skills:** skills active in current session (e.g. `/grilling`, `/design`)
- **Suggested Skills:** skills the next agent should read (e.g. `design`, `testing`)

Policies:
- Don't duplicate PRDs, plans, ADRs, issues, or commits. Reference them by path or URL
- Redact secrets, API keys, PII

### 3. Write & Output

Write to `.claude/HANDOFF.md` (create `.claude/` if missing).

Add `## Resume Prompt` at bottom. It must be self-contained and copy-paste ready.
Expand Active Skills into direct invocations at the top, one per line:
```
/<skill1> <args>
/<skill2> <args>
Read `.claude/HANDOFF.md`. We're working on <project>: <task goal>.
Continue from the Pending section. Ask me nothing until you've read the handoff.
```

Then confirm the path, print the Resume Prompt in chat, and say "Open new session, paste prompt above."
