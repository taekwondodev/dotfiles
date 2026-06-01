---
name: compress
description: >
  Compress natural language files (CLAUDE.md, todos, preferences, notes) into caveman format
  to reduce input tokens. Preserves all technical substance, code, URLs, and structure.
  Compressed version overwrites original.
  Trigger: /compress FILEPATH or "compress this file"
argument-hint: "<filepath>"
---

# Compress

## Purpose

Reduce token cost of natural language files by rewriting prose in caveman-speak.
Compressed version overwrites original.

## Trigger

`/compress <filepath>` or when user asks to compress a memory/config file.

## Process

1. Read file at absolute path via Read tool.
2. Check file type. Allowed: `.md`, `.txt`, `.typ`, `.typst`, `.tex`, extensionless.
   Disallowed type: stop, tell user.
3. Reject files > 500KB. Warn if very large.
4. Apply compression rules below.
5. Overwrite original path with compressed content via Write tool.
6. Report: original line count, compressed line count, estimated token reduction.

## Compression Rules

### Remove
- Articles: a, an, the
- Filler: just, really, basically, actually, simply, essentially, generally
- Pleasantries: "sure", "certainly", "of course", "happy to", "I'd recommend"
- Hedging: "it might be worth", "you could consider", "it would be good to"
- Redundant phrasing: "in order to" → "to", "make sure to" → "ensure", "the reason is because" → "because"
- Connective fluff: however, furthermore, additionally, in addition

### Preserve EXACTLY (never modify)
- Code blocks (fenced ``` and indented)
- Inline code (`backtick content`)
- URLs and markdown links
- File paths
- Shell commands
- Technical terms (library names, API names, protocols, algorithms)
- Proper nouns (project names, people, companies)
- Dates, version numbers, numeric values
- Environment variables (`$HOME`, `NODE_ENV`)
- YAML/frontmatter headers

### Compress Prose
- Short synonyms: "big" not "extensive", "fix" not "implement a solution for", "use" not "utilize"
- Fragments OK: "Run tests before commit" not "You should always run tests before committing"
- Drop "you should", "make sure to", "remember to" — state action directly
- Merge redundant bullets that say the same thing differently
- Keep one example where multiple show same pattern

### Structure: Preserve
- All markdown headings (keep exact heading text, compress body below)
- Bullet hierarchy (keep nesting)
- Numbered lists
- Tables (compress cell text, keep structure)

## Boundaries

- ONLY compress: `.md`, `.txt`, `.typ`, `.typst`, `.tex`, extensionless files
- NEVER modify: `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.toml`, `.env`, `.lock`, `.css`, `.html`, `.xml`, `.sql`, `.sh`
- Mixed files (prose + code): compress ONLY prose sections
- Unsure if code or prose → leave unchanged
