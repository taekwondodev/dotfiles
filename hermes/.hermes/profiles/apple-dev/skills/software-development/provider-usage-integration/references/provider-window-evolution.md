# Provider window evolution

Use this reference when a provider introduces a new quota window or changes a technical label while the app already has a typed quota model.

## Boundary placement

Normalize provider-specific technical labels at the provider bridge or repository adapter, not in SwiftUI. The adapter should emit the commercial display label for a known window while keeping provider data and lifecycle identity aligned. A UI-only rename leaves reset matching, ordering, and notifications coupled to the old label.

Keep normalization provider-specific. A label such as `Session` may mean a five-hour rolling limit for one provider and something else for another. Do not turn a generic classifier into a global commercial-label rule unless the providers share an authoritative contract.

## Unknown windows

When the provider sends a valid window that the app does not recognize:

1. Preserve the original display label.
2. Preserve provider-reported percentage and reset fields.
3. Assign a stable opaque kind, preferring the provider technical kind and falling back to normalized label text.
4. Feed the opaque kind through the same refresh, countdown, reset detection, and notification paths as known kinds.
5. Preserve provider order after the explicitly ordered known windows.
6. Preserve distinct observations. If candidate identities collide, append a deterministic provider-order occurrence to the identity rather than aggregating or dropping data.

The domain kind must be a typed, Codable, Hashable, and Sendable representation that can encode known cases and an opaque string. Unknown values are not automatically malformed: validate the surrounding invariants, such as non-empty labels, finite percentages in the provider range, and valid timestamps. The opaque identity itself must reject whitespace-only values, control characters, and unbounded length at construction and decoding boundaries.

Unknown-window support must be scoped to the provider that requires it. Reject opaque kinds for providers whose existing contract is closed, both in the live bridge/command path and in file-based readers. If a provider supplies a technical kind, never classify or replace it from the display label. Use the label fallback only when the technical kind is absent.

Collision disambiguation must be collision-safe, not only suffix-based: reserve every emitted identity and advance the occurrence until the generated candidate is unused.

## Contract and tests

The bridge and reader are shipped together, so change the single final contract atomically rather than adding compatibility versions. Test the producer and consumer seams independently:

- bridge tests for known-label normalization, unknown preservation, fallback identity, and collisions;
- domain tests for opaque-kind construction and wire round-trip;
- service tests proving ordering and lifecycle behavior for opaque kinds;
- integration tests decoding the bridge payload into the domain model.

Use fixtures with independent expected values. Do not test only the rendered text, because a UI-only assertion can miss a broken lifecycle identity.
