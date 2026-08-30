# Animating DisclosureGroup open/close on macOS

Goal: animate a `DisclosureGroup`'s content in/out (fade + slight vertical slide,
~0.2s) identically across multiple sections, respecting Reduce Motion.

## Reliable pattern

Drive the toggle with `withAnimation` in the binding's `set`, and put a `.transition`
on the content node that is inserted/removed:

```swift
DisclosureGroup(
    isExpanded: Binding(
        get: { isExpanded },
        set: { newValue in
            withAnimation(motion(reduceMotion: reduceMotion)) { isExpanded = newValue }
        }
    )
) {
    content.transition(transition)   // transition must sit on the content node
} label: { ... }
```

- Name the setter parameter (e.g. `newValue`), do NOT use `$0` inside: `withAnimation`'s
  own closure shadows `$0` and the code will not compile.
- The `.transition` must be on the CONTENT (the node that is inserted/removed), not on
  the `DisclosureGroup` itself.

## Gotcha

`DisclosureGroup(...).animation(_:value:)` animates a section whose expansion binding is
a plain `@State` Bool, but **silently shows the content instantly** when the expansion
binding is a computed one derived from parent state, e.g. `expandedSubscriptions.contains(...)`.
Two sections with visually identical code can then behave differently (one animates, the
other pops). `withAnimation` in the setter is binding-kind-agnostic, so it keeps both
sections identical.

## Reduce Motion

Read `@Environment(\.accessibilityReduceMotion)` and pass `nil` when active so the content
appears/disappears instantly. `withAnimation(nil)` also suppresses the offset-bearing
transition before it can be seen, so bounding with a nil animation is enough; no need to
strip the transition.

## DRY

Centralize `duration`, `slide`, the `AnyTransition`, and the reduce-motion helper once
(e.g. a `PopoverSectionMotion` enum plus a small `View` extension for `.transition`) and
reuse on every section so they cannot drift apart.

## Verification

SwiftUI UI interaction is not covered by Swift Testing. Confirm expand/collapse animation
in the running popover. For this project the user verifies the popover visually and reports
the outcome; do not drive desktop/computer-use automation for this.