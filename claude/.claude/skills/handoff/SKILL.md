---
name: handoff
description: >
  Context bridge for session continuity. When context is nearly full and the current task is
  incomplete, synthesizes all session state into a structured HANDOFF.md file and produces
  a copy-paste prompt to resume seamlessly in a new session.
argument-hint: "What will the next session focus on?"
---

## Steps

### 1. Gather State

Run: `git status && git diff HEAD && git log --oneline -10`

### 2. Synthesize

Extract from conversation + git state:

- **Task:** goal in 1-3 sentences. If args given, weight toward that focus.
- **Progress:** done items (file names, functions, decisions)
- **What Didn't Work:** failed approaches — prevents next agent repeating them
- **Pending:** ordered, most critical first
- **Decisions & Context:** non-obvious choices, constraints, gotchas fresh Claude can't derive from code
- **Files Changed:** path → one-line description
- **Blockers:** stuck or unclear items
- **Active Skills:** skills active in current session (e.g. `/caveman full`, `/design`)
- **Suggested Skills:** skills the next agent should invoke (e.g. `/design`, `/testing`)

Policies:
- Don't duplicate PRDs, plans, ADRs, issues, commits — reference by path or URL
- Redact secrets, API keys, PII

### 3. Write & Output

Write to `.claude/HANDOFF.md` (create `.claude/` if missing).

Add `## Resume Prompt` at bottom — self-contained, copy-paste ready:
```
Read `.claude/HANDOFF.md` first. We're working on <project> — <task goal>.
Continue from the Pending section. Invoke active skills listed in Active Skills section immediately.
Ask me nothing until you've read the handoff.
```

Then: confirm path, print Resume Prompt in chat, say "Open new session, paste prompt above."
