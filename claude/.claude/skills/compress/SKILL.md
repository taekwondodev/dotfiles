---
name: compress
description: >
  Compress a natural language file (CLAUDE.md, notes, preferences, todos) into terse
  format to reduce input tokens. Invoke when user says "compress this file", "reduce tokens",
  or runs /compress <filepath>. Overwrites original. Never modifies code files.
argument-hint: "<filepath>"
---

# Compress

## Purpose

Reduce token cost of natural language files by rewriting prose in terse style.
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

Apply this exact rule set to the file's prose (a file is not a chat reply; be conservative):

- Drop articles (a/an/the) where grammar stays unambiguous; keep them where case markers carry meaning
- Drop filler: just, really, basically, actually, simply, in order to, make sure to
- Short synonyms (big not extensive, fix not "implement a solution for")
- Fragments OK in bullet bodies; keep full sentences in numbered/procedural steps
- Preserve EXACT: code, technical terms, proper nouns, numbers, units, error strings, API/CLI names
- Never drop not/never/no/only/except — flips meaning
- No invented abbreviations (cfg/impl/req) — zero token saved, costs decode clarity

### File-specific

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
