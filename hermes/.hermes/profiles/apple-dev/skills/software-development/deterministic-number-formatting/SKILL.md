---
name: deterministic-number-formatting
description: "Use when Swift UI numbers need explicit display formatting."
---

# Deterministic Number Formatting

Use this skill when a user-visible numeric value must follow a specific separator, grouping rule, rounding rule, or missing-value representation across machines, locales, and build modes.

## Scope

This skill governs presentation formatting only. Keep the source value typed and unchanged in the domain, repository, service, and serialization layers. Apply formatting at the narrowest display boundary that owns the label or view model.

## Procedure

1. Identify the exact fields covered by the display contract. Do not generalize a request for token counts to requests, costs, percentages, dates, or unrelated metrics.
2. Trace the display path from the typed source value to the rendered `Text` or display model. Confirm that formatting does not alter parsing, aggregation, persistence, or provider data.
3. State the missing-value behavior separately from the numeric formatting behavior. Preserve distinctions such as absent versus zero.
4. Choose the smallest implementation that guarantees the required output on the target platform. A system formatter is appropriate only when its locale and grouping behavior are part of the contract and verified on the target. For a literal separator contract, a small deterministic grouping helper may be safer than platform defaults.
5. Add tests from the acceptance criteria, not from the implementation. Cover a representative multi-group value, the first grouping boundary, a value below the boundary, zero, and the missing-value path when applicable.
6. Run the focused tests first, then the repository's canonical full test, check, and build commands. If an install script needs an interactive confirmation, resolve the running application state explicitly and rerun the canonical command rather than treating compilation as delivery proof.
7. Review the diff for scope: only the specified display fields should change, and unrelated numeric labels must retain their existing representation.

## Swift implementation guidance

For nonnegative `Int` values with a literal `.` grouping contract, grouping the decimal string into right-aligned chunks of three avoids locale-dependent output and preserves the original integer. The domain constructor remains responsible for rejecting negative values; the display helper should not become a second validation boundary.

Prefer a pure, private helper owned by the display model when one UI surface needs the rule. Extract a shared utility only after multiple display surfaces demonstrably share the same contract.

## Pitfalls

- `NumberFormatter` configuration can appear correct while target execution still produces ungrouped output; verify its actual string result rather than trusting configuration.
- Do not format `0` as missing, and do not use a fallback that hides a real formatting failure as `Non disponibile` unless the product contract explicitly allows that loss of information.
- Do not place presentation separators into domain values, JSON fixtures, database rows, or provider contracts.
- Do not silently apply the new grouping to neighboring fields whose display contract was not changed.
- Compilation alone does not prove the rendered value. A display-model test should assert the exact visible string, and the installed artifact should be verified when the workflow requires installation.

## Verification checklist

- [ ] Source type remains numeric and unchanged.
- [ ] Covered fields are enumerated explicitly.
- [ ] Zero and missing values remain distinct.
- [ ] Grouping boundary and multi-group cases have exact assertions.
- [ ] Unrelated numeric labels remain unchanged.
- [ ] Focused tests pass.
- [ ] Full test, check, and build/installation verification pass.

## References

- `references/italian-thousands-grouping.md` — verified pattern and regression cases for literal dot grouping in Swift display models.
