# Private mirror Desktop update integration

For a managed Hermes checkout with `origin` pointing to a private personal mirror and `upstream` pointing to NousResearch/hermes-agent:

- Desktop passive update checks must prefer the official upstream when the `upstream` remote exists; do not compare only `origin/main`.
- Official passive probes can use the public HTTPS remote/compare API to avoid SSH/FIDO prompts.
- Every Desktop/gateway apply path must invoke `hermes update-safe --yes --json`, including POSIX/Windows handoffs and staged/bootstrap updater code.
- Keep interactive confirmation for direct CLI use; `--yes` is only for an already-confirmed Desktop action.
- Treat only `ok` and `already-current` as successful. Partial degradation, validation failure, rebase conflict, or push failure must prevent the Desktop rebuild/relaunch.
- Rebuild `apps/desktop` only after the update-safe result is successful.
- Official installs without `upstream` may fall back to `origin/main`, but must never push the official remote.
- Add tests for private-origin + official-upstream remote selection and for the absence of legacy `hermes update` in apply commands.
