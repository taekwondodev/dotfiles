# Validated Hermes Bot Room Pattern

This session verified a working local Bot Mode setup in Hermes Desktop.

## Profiles and roles

Use separate profiles for reusable specialists. The validated roles were:

- `macos-dev`: lead/orchestrator and implementation/runtime owner.
- `hermes`: workflow and evidence coordinator.
- `wiki-dev`: research and documentation context.
- `swiftui-reviewer`: read-only SwiftUI and native macOS UI review.
- `testing-reviewer`: read-only tests, provider/domain transitions, bundle and runtime verification.
- `release-reviewer`: read-only integration, packaging, installation, and regression review.

Create profiles with concise role descriptions. A profile can be created with:

```bash
hermes profile create <profile-name> --description '<one- or two-sentence role description>'
hermes profile list
```

The `hermes profile list` result is the verification that the profiles exist; it also shows their model/gateway state.

## Group creation

In Hermes Desktop:

1. Open **Bots**.
2. Open **New agent or group chat**.
3. Choose **New Group Chat**.
4. Pick 2–6 relevant Bots.
5. Give the room a project-level name.
6. Create the group and verify the room shows the expected member count.

The validated room was named **Hermes Mac Development Council** and contained six Bots. The UI displayed the room in the Bots roster with `6 bots`.

## Kickoff message

Post a short kickoff instead of immediately assigning code:

```text
Riunione iniziale. Io coordino il lavoro e l'utente decide ai checkpoint.
@everyone: presentate il vostro ruolo in una riga e proponete come collaborare.
Regole: review read-only salvo incarico esplicito, nessun dato inventato,
ogni conclusione importante deve avere evidenza verificabile.
```

Use the room for discussion and threads, but keep the lead agent responsible for synthesis and decisions. The room can show bots as thinking or working; wait for responses as needed, but treat replies as input rather than proof of completed work.

## Pitfalls

- Do not create more specialists than the group can remain legible with; 2–6 is the supported group-room size.
- Do not let a group discussion bypass the user’s dev-cycle checkpoint.
- Do not describe a bot as verified merely because it replied.
- Keep write access isolated; reviewers should be read-only by default.
- Profile creation may report that the wrapper directory is not on PATH. This is informational for direct shell aliases and is not required for the Desktop Bots roster when the profile itself was created successfully.
