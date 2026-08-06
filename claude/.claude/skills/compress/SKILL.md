---
name: compress
description: >
  Compress a natural language file (CLAUDE.md, notes, preferences, todos) into terse caveman
  format to reduce input tokens. Invoke when user says "compress this file", "reduce tokens",
  or runs /compress <filepath>. Overwrites original. Never modifies code files.
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

Apply `/caveman`'s Rules section — drop articles/filler/pleasantries/hedging, short synonyms, fragments OK, preserve code/technical terms/proper nouns/numbers/errors exact — to the file's prose instead of a chat reply. `/caveman`'s own Boundaries section already names this file-compression case (`/caveman-compress`) as its counterpart, not a competing rule set; don't re-derive the list here.

### File-specific, beyond what /caveman covers

- Redundant phrasing unique to written docs: "in order to" → "to", "make sure to" → "ensure", "the reason is because" → "because"
- Preserve YAML/frontmatter headers untouched

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
