---
name: handoff
description: >
  Context bridge for session continuity. When context is nearly full and the current task is
  incomplete, synthesizes all session state into a structured HANDOFF.md file and produces
  a copy-paste prompt to resume seamlessly in a new session.
---

## Purpose

Generate a complete context handoff so a new session can continue exactly where this one left off.

## Steps

### 1. Gather State

Run these in parallel:
- `git status` — unstaged/staged changes
- `git diff HEAD` — full diff of all changes
- `git log --oneline -10` — recent commits for context
- Read any existing `.claude/HANDOFF.md` — check what was the previous handoff if any

### 2. Synthesize

From the current conversation and git state, extract:

- **Task:** What is the user trying to accomplish? (1-3 sentences, goal-focused)
- **Progress:** What is already done? (bullet list, specific — file names, functions, decisions)
- **Pending:** What is NOT done yet? (ordered list, most critical first)
- **Decisions & Context:** Non-obvious choices made, constraints discovered, gotchas, architectural decisions, anything a fresh Claude would NOT know from reading the code alone
- **Files Changed:** List of modified/created files with one-line description of change
- **Blockers:** Anything that was stuck or unclear at handoff time

### 3. Write HANDOFF.md

Write to `.claude/HANDOFF.md` in the current working directory (create `.claude/` dir if missing).

Use this exact format:

```markdown
# Handoff — <date YYYY-MM-DD>

## Task
<1-3 sentences: what the user is building/fixing and why>

## Progress
- <done item 1>
- <done item 2>

## Pending
1. <next step — most critical first>
2. <step 2>

## Decisions & Context
- <decision or constraint>: <why it was made>

## Files Changed
- `path/to/file` — <what changed>

## Blockers
- <blocker or open question, if any>

## Resume Prompt
<see section below>
```

### 4. Generate Resume Prompt

At the bottom of HANDOFF.md, under `## Resume Prompt`, write a self-contained prompt the user can paste into a new session to resume. It must:

- Reference `read .claude/HANDOFF.md first`
- State the project and task goal in one sentence
- Tell Claude to continue from the "Pending" section
- Be copy-paste ready, no placeholders

Example shape (adapt content):
```
Read `.claude/HANDOFF.md` first. We're working on <project> — <task goal>. 
Continue from the Pending section. Ask me nothing until you've read the handoff.
```

### 5. Output to User

After writing the file:
1. Confirm path written
2. Print the Resume Prompt directly in chat so user can copy it immediately without opening the file
3. One line: what to do next ("Open new session, paste prompt above.")
