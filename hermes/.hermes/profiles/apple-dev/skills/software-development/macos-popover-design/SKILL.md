---
name: macos-popover-design
description: "Use for native macOS popover design grilling."
---

# macOS Popover Design

Use this skill when a native macOS menu-bar utility needs a UI redesign, visual exploration, or a grilling session before implementation.

## Workflow

1. Read the issue, domain glossary, existing SwiftUI view, layout constants, and relevant tests before proposing a design.
2. Treat user-provided screenshots as structural references: preserve semantic ordering, data relationships, and existing interaction placement unless the user explicitly changes them.
3. During grilling, present the design frontier with short picker choices. When the user asks to see alternatives, create two or three interactive disposable mockups rather than only describing them.
4. Refine the selected direction against the real app's typography, spacing, surface hierarchy, corner radii, and control language. A polished mockup that looks like an unrelated dashboard is not a successful native-macOS design.
5. Record concrete decisions before handoff: structure, color family, expansion default, missing-data treatment, maximum height, scroll ownership, and invariants whose position must not move.
6. Remove disposable prototype artifacts after the user chooses a direction. Do not leave exploration HTML in the implementation tree.
7. Stop at the dev-cycle grilling checkpoint. Do not start `to-spec`, `to-tickets`, or implementation until the user invokes the next phase.

## Native visual stance

- Prefer adaptive semantic surfaces over fixed colors sampled from a reference image. For dark popovers, a neutral graphite elevation is usually safer than a saturated blue panel.
- Keep the existing app's visual grammar: system typography, subtle dividers, restrained corner radii, native disclosure controls, and limited accent color.
- Avoid gradients, decorative chips, dashboard cards, and invented iconography unless the user explicitly asks for them.
- Keep primary provider quota/status content visually primary; secondary local accounting should be distinct but subordinate.
- Preserve existing metadata order when the user calls it out. Moving freshness or snapshot-age text while redesigning a nearby section is a semantic regression.

## Data-display safety

- Design the UI around the domain's observation granularity. If the source contains aggregate metrics for a `LocalAccounting` entry, keep those metrics in one display block; never duplicate totals under multiple model names merely to make the layout look more granular.
- Missing fields remain visible as an explicit unavailable value such as `Non disponibile`; never render zero, an estimate, or an empty omission when the distinction matters.
- An unavailable source may expose a concise state badge while keeping technical failure reasons out of a compact popover when the user requests that treatment.
- Separate provider identity from technical provider identifiers. Do not repeat a technical source label inside every accounting block when the containing subscription card already establishes identity.
- For expandable secondary content, default to closed unless the user chooses otherwise. Keep one outer popover scroll owner; avoid nested scroll containers.

## Sizing and verification

- Use explicit `minHeight`, `idealHeight`, and `maxHeight` for `MenuBarExtra` popovers with scrolling content. Treat numeric bounds as acceptance decisions when the user selected them, not as arbitrary implementation details.
- Test the layout contract and pure display-model transformations at the highest seam available. Do not unit-test private SwiftUI view structure or repositories.
- Run focused tests, then the full suite with warnings-as-errors when possible, plus `git diff --check`.
- Before claiming a visual pass, launch the actual menu-bar executable and inspect the popover if the environment permits. If only compilation/tests were verified, say so explicitly.

## References

- `references/per-model-accounting.md` — safe patterns for mapping aggregate accounting observations into native popover blocks without duplicating metrics.
