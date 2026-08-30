# Semantic disabled colors

## Decision table

| Visual problem | Preferred correction | Avoid |
| --- | --- | --- |
| Disabled fill still reads enabled | Keep the native shape and use an adaptive neutral semantic fill | Replacing the control with a custom geometry or hard-coded gray |
| Disabled label is too close to active labels | Move from `.secondary` to `.tertiary` / `NSColor.tertiaryLabelColor` | Arbitrary RGB values or unexplained opacity multipliers |
| Enabled and disabled variants drift | Keep the enabled tint and label explicit; branch only the disabled visual token | Changing action logic or accessibility text to solve a color problem |
| Light/dark appearance differs | Prefer semantic colors (`Color.primary`, `.secondary`, `.tertiary`) and inspect both appearances | Assuming a value that works in dark mode also works in light mode |

## Practical rule

The screenshot is evidence about hierarchy, not a demand for a literal sampled pixel. If the user says the fill is correct but the label looks active, leave the fill alone and darken only the label's semantic tier. Update the design record after the user accepts the visual result.
