# Hermes Bot Credential and Launch Verification

Use this reference when provisioning or auditing a persistent Hermes Bot fleet.

## Safe inspection

- Resolve the active profile home from `HERMES_HOME`; it may point to a profile such as `~/.hermes/profiles/macos-dev`, not the global Hermes root.
- If `HERMES_HOME` points to a profile, discover sibling profiles from its parent directory.
- Inspect `.env` files by key names, existence, and permissions only. Never print credential values.
- Keep `.env` files at mode `0600`.
- Propagate only the already-authorized provider variables required by the bot. Do not blindly copy the global `.env`, because it may contain unrelated settings or secrets.

## Verification sequence

```bash
hermes profile show <profile>
hermes -p <profile> chat -q 'Reply with exactly READY.'
```

Run the real query from the project worktree, not an arbitrary desktop directory. A successful `READY` response verifies that the profile can launch and reach its configured model/provider; it does not verify the bot’s task behavior or code quality.

## Existing-bot failures

If an existing bot has credentials but its provider rejects the configured model as unsupported:

1. Treat the model catalog error as distinct from a missing credential.
2. Preserve the intended provider when possible.
3. Fetch the provider’s current supported-model catalog before changing the model.
4. Do not silently switch provider/model when the catalog is unavailable or the replacement is ambiguous; request a user decision.

## Terminal working directory

Use a stable, existing project `workdir` for verification. If no `terminal cwd` warning appears, do not invent a permanent workaround. A one-off cwd/setup issue is environmental, not a durable capability limitation.
