# Card surface & typography consistency inside one popover

Session learning (HermesUsageMonitor, refs #34): the manual reset card was written by a
different agent that introduced its own `ManualResetDesignToken` with bespoke colors
(`Color.white`, `#8E8E93` header gray, custom text tokens) and a plain `.caption` title.
The user rejected it as "not our style" and asked to migrate it to match the existing
"Uso osservato da Hermes" accounting card (`AccountingDetail`) exactly.

## The contract the user wants

When several expandable cards live in one popover, they must share a single surface and
typography language. For HermesUsageMonitor this meant:

| Aspect | Value |
| --- | --- |
| Primary/title label | `.font(.caption.weight(.semibold))`, default primary color (no custom token) |
| Secondary lines (applicability, expiration) | `.font(.caption2)` + `.foregroundStyle(.secondary)` |
| Surface | `Color.primary.opacity(0.06)` in `RoundedRectangle(cornerRadius: 8)` |
| Insets | `.padding(.vertical, 6)` then `.padding(.horizontal, 8)` (match the reference block) |
| Left edge | identical — no extra `.padding(.leading, …)` on one card vs the other |
| Disclosure chevron | same tint treatment as the reference card (accounting applies no `.tint`; do not add one just to the new card) |

The header row uses a `Label("…", systemImage:)` styled `.font(.caption.weight(.semibold))`
+ `.secondary`, mirroring the reference header's SF-symbol treatment — do not hand-roll a
plain `Image`+`Text` stack with a custom tint.

## Why adaptive colors

The popover does not force a color scheme. Hard-coded `Color.white` / `Color.white.opacity`
text on the adaptive `Color.primary.opacity(0.06)` surface is unreadable in light mode.
Use adaptive semantic colors (`.primary`, `.secondary`, `.tertiary`) so the same appearance
holds in dark and stays legible in light. Remove custom text tokens once the card mirrors
the reference.

## Verification pitfall

- Treat the reference card's actual SwiftUI source as the spec, not the ADR prose alone.
  A reviewer (or subagent) that reads only the ADR can miss real divergences (chevron tint,
  inset, left edge).
- Confirm parity on the real running app, not just `swift build`/`swift test`.