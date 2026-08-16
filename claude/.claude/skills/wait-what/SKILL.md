---
name: wait-what
description: >
  Stop. The last message did not land — the user is confused or asked for clarification.
  Re-pitch it: give a little context, talk in ASD-STE100 Simplified Technical English,
  and use the ubiquitous language from CONTEXT.md. Use when the user says the last
  response was unclear, "wait", "what?", "re-pitch", "I don't get it", or repeats
  a question you already answered. User-invoked; never trigger this on your own initiative.
---

Wait — I don't understand where you've got to here. Re-pitch that.

## Trigger

User-side only: "wait", "what?", "re-pitch that", "I don't understand", "unclear",
"again but simpler", or a repeated question. This skill is invoked explicitly by the
user — do not fire it unilaterally.

## Re-pitch protocol

1. **One sentence of context**: where we are, what the last message was about.
2. **ASD-STE100 Simplified Technical English**:
   - Short sentences (≤ 20 words), one idea per sentence
   - One word = one meaning: no synonyms, no idioms, no metaphors
   - Active voice, present tense where possible
   - Approved technical vocabulary; keep technical terms, code, and names EXACT
   - No hedging, no filler, no "basically/simply/just"
3. **Ubiquitous language**: if a `CONTEXT.md` exists in the project, read it first
   (skills/domain-modeling writes it) and use its terms exactly — never invent
   synonyms for domain concepts.
4. Keep the re-pitch SHORT: the user already saw the full version; re-pitch
   the part that did not land, not the whole answer.

## Boundaries

- This is a re-pitch, not a new answer — same content, clearer form.
- If the confusion is real (the user asks something new), answer the new question
  normally instead; do not force an STE re-pitch.
- Never use STE for: error messages, code, CLI output — quote those verbatim.