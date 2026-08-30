---
name: swiftui-disabled-state-design
description: "Use when designing disabled SwiftUI controls."
version: 1.0.0
metadata:
  hermes:
    tags: [SwiftUI, macOS, accessibility, HIG, visual-review]
---

# SwiftUI Disabled-State Design

Use this skill when a native SwiftUI control is visually correct while enabled but needs a clearer disabled state, especially in a macOS popover or quota-monitoring utility.

## Design decision order

1. Preserve the app's established surface, spacing, typography, and native control shape.
2. Keep the enabled tint, label, action, and accessibility name unchanged.
3. Reduce disabled prominence with adaptive semantic colors rather than hard-coded grays or arbitrary opacity values.
4. Use the real runtime appearance as the final authority for legibility and hierarchy; compilation and unit tests cannot prove visual contrast.

## Disabled-control rules

- Treat disabled as its own visual variant, not as enabled styling plus a generic opacity reduction.
- A disabled control should remain recognizable as the same control while no longer competing with enabled controls.
- Start with `.secondary` for disabled text when it is visibly subordinate. If a real screenshot shows it still reads like an active control, move one semantic tier darker to `.tertiary` or `Color(nsColor: .tertiaryLabelColor)`.
- Prefer semantic adaptive colors to literal RGB values so light and dark appearances remain coherent.
- Avoid adding borders, icons, or explanatory decorations solely to signal disabled state when the existing layout and explanatory text already provide that context.
- Keep the native SwiftUI button style whenever possible; do not replace it with a custom geometry implementation just to control color.

## Runtime review loop

1. Inspect the supplied screenshot or the running popover and separate fill, label, and surrounding text hierarchy.
2. Identify whether the problem is the control surface, label brightness, or both.
3. Change only the smallest visual token/modifier that addresses the problem.
4. Rebuild and inspect both light and dark appearances. Ask the user for visual confirmation when the agent is not performing visual desktop control.
5. Update the relevant ADR/design record when the accepted visual rule changes.

## Build and install pitfall

The repository's app build script can refuse to replace the installed bundle while the app is already running. Close the running app before invoking the install step, then run the project's canonical build and verification targets again. A successful Swift compilation alone does not prove the installed `.app` contains the latest visual change.

## Review evidence

- Treat delegated review output as valid only when the reviewer actually inspected the diff and returned findings. Authentication or provider failures are not review results and must be reported as unavailable.
- If a review worker fails before analysis, perform a local diff review or retry with a working reviewer; never summarize the failed response as a pass.

## References

- See `references/semantic-disabled-colors.md` for the compact rationale and decision table for `.secondary`, `.tertiary`, and appearance-adaptive fills.
