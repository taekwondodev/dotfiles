---
name: commit
description: >
  Generate a concise commit message and stage + commit changes.
  Optionally push if "push" is passed as argument.
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
- Body only if why isn't obvious, breaking change, or migration note
- Wrap body at 72 chars

Never include: "This commit does X", emoji.

### 4. Commit
```
git commit -m "<message>"
```

### 5. Push (only if args contain "push")
```
git push
```
