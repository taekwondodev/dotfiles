---
name: commit
description: >
  Stage all changes and commit with a Conventional Commits message.
  Pass "push" to also push. Never adds a commit body.
argument-hint: "push"
---

## Steps

### 1. Gather
Run in parallel:
- `git status --porcelain`
- `git diff HEAD`

### 2. Stage
```
git add $(git ls-files --modified --others --exclude-standard)
```
Respects .gitignore — never stages ignored files.

### 3. Generate Message

Conventional Commits format:
- `<type>(<scope>): <summary>` — scope optional
- Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`
- Imperative mood: "add", "fix", "remove"
- Subject ≤50 chars, hard cap 72
- No trailing period
- Never add a body. Subject line only, always.

Never include: "This commit does X", emoji.

### 4. Commit
```
git commit -m "<message>"
```

### 5. Push (only if args contain "push")
```
git push
```
