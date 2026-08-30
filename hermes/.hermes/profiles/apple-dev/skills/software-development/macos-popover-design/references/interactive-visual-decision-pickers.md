# Interactive visual decision pickers for macOS popovers

Use this pattern when a grilling question is primarily spatial or visual and prose choices are insufficient.

## Prototype set

Create 2–3 disposable variants that preserve the real app’s:

- popover width and height contract;
- provider/card hierarchy;
- system typography and restrained macOS surfaces;
- existing semantic order outside the decision under review;
- realistic current data and unavailable states.

Vary a real design stance, not decoration. Useful axes for compact menu-bar apps include:

- always-visible inline section;
- compact badge with disclosed detail;
- action-emphasis panel.

## Picker behavior

Wrap the variants in one picker artifact with named tabs and a concise trade-off for each. Include:

1. a preview at the actual popover width;
2. a control to simulate the decisive state transition (for example unavailable → applicable, disabled → enabled, or loading → success);
3. interactive affordances such as disclosure, confirmation, or success feedback;
4. one “Choose this” action that returns the exact named choice to the agent (`window.hermes.send(...)` in an inline Hermes widget).

The simulation must not call real services or mutate project state.

## Grilling integration

- Treat a request to see prototypes as context, not as a skipped answer or acceptance of the recommended prose option.
- Preserve answers already settled in the same round; regenerate only the unresolved visual decision.
- Do not ask the user to choose from prose after they explicitly requested a visual picker.
- After selection, resume the decision tree and ask only newly unblocked questions.
- Remove the disposable artifact after the direction is selected; transfer the decision, not the prototype code, into the spec.

## Verification

Open the picker in Hermes Preview, enumerate its controls, switch through every variant, and exercise the simulated state. If a separate automated browser is blocked by a local permission prompt, verify through the already-available Preview surface rather than recording the transient setup failure as a design constraint.
