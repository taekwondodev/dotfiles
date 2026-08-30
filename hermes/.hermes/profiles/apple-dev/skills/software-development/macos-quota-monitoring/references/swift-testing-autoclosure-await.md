# Swift Testing: hoist await/try out of `#expect`

## The trap

`#expect(...)` is a non-async autoclosure (`() throws -> Bool`). Writing
`#expect(await service.canStart(...))`, `#expect(!await ...)`, or
`#expect(await ... == false)` fails to compile with confusing errors:
"cannot find 'await' in scope", "expected ',' separator", and
"cannot convert value of type 'Bool' to expected argument type 'Comment?'".

## The fix

Resolve the awaited/try value into a `let` first, then assert the plain value:

```swift
let exhausted = await service.canStart(manualReset: live, subscriptions: exhausted)
#expect(exhausted)
```

This also covers combinations like `!await` (negate the name or assign `let notExhausted`).
Assign once, assert once, and give the local a name that reads well in the `#expect`.

## When it bites

- Actor (`public actor`) methods are called with `await`, so any assertion on their result must
  be hoisted.
- `try` inside `#expect` is allowed, but `try` + `await` together still must be hoisted.
- This is a pure syntax/mechanics issue, not a test-quality problem: a hoisted `let` + assert is
  just as valid a Spec-derived assertion as an inline one.

## Also: construct enum cases with the full type name

For `enum X { case live(Inner) }`, write `X.live(try Inner(...))` (or `X.stale(summary)`) when
called from a helper. Relying on `.live(...)` inference can produce "X.type does not have a
member 'live'" in test helpers, and `.stale` expects the payload type, not a state value.