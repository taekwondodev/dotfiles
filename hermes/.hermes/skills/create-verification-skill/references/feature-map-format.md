# Capability Map Format

Use this format for the public capabilities covered by a generated verification skill. Adapt the map's title to the surface, but preserve the information contract.

## Index

Create `references/features/README.md` with one row per capability:

```markdown
| Capability | Public entry point | Proof |
| --- | --- | --- |
| Passkey login | `POST /auth/login/start` | A protected request accepts the issued token. |
```

Every row links to one sibling file. Every sibling file appears once in the index.

## Capability file

```markdown
# Passkey login

One sentence describing the result visible to the user or client.

## Public path

Describe how the user or client reaches the capability. Point to the repository-owned route, command, selector, or manifest that establishes the path.

## Drive

Give the exact verification-helper invocation and required isolated inputs. Use public interfaces and stable handles.

## Proof

Name the observable pass condition, the evidence artifact, and any side effect that must also hold. Expected values come from the product contract, specification, or established fixture rather than the implementation under test.

## Gotchas

Record only prerequisites, entitlement or platform limits, known state hazards, and recovery steps that change how the drive runs.
```

## Source-of-truth boundary

The map owns expensive operational knowledge: public journeys, proof contracts, and non-obvious hazards. The repository owns routes, scripts, configuration defaults, and command help. Link to cheap repository facts rather than copying them.

## Coverage boundary

Start with the top three to five public capabilities. Mark a capability uncovered when no safe public drive exists. A named gap is more useful than a placeholder command or an internal shortcut presented as proof.
