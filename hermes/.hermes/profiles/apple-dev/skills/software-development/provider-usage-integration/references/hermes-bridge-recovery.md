# Hermes bridge recovery checklist

Use when a macOS companion suddenly shows every provider as unavailable after packaging, branch changes, or a Hermes Agent update.

## Red-capable probes

Run the producer directly before changing Swift UI code:

```bash
HERMES_HOME="$HOME/.hermes" "$HOME/.hermes/hermes-agent/venv/bin/hermes" usage --json \
  --provider nous --provider openai-codex --provider opencode-go
```

The probe must exit 0 and expose provider statuses/windows. If the CLI says `invalid choice: usage`, the producer checkout no longer contains the bridge; restore/reapply the producer-side CLI change before debugging the app adapter.

Never print the API key or authorization headers. It is safe to print provider names, status, window kinds, percentages, reset timestamps, and HTTP status/schema keys.

## Root/profile resolution

A shell-launched development process may have `HERMES_HOME=~/.hermes/profiles/<profile>`, while a Finder-launched `.app` normally has no inherited `HERMES_HOME`. The companion must resolve both:

- root: `~/.hermes/hermes-agent/venv/bin/hermes`;
- profile: `~/.hermes/profiles/<name>/../../hermes-agent/venv/bin/hermes`.

Set the command environment to the canonical Hermes root when querying account-global usage, while using the active profile path for profile-local readers as required by the domain contract.

## Provider schema drift

Do not assume a generic `windows` array. OpenCode Go's verified usage response can be shaped as:

```json
{
  "usage": {
    "rolling": {"percent": 4, "resetsAt": "..."},
    "weekly": {"percent": 41, "resetsAt": "..."},
    "monthly": {"percent": 25, "resetsAt": "..."}
  }
}
```

Map `rolling` to the domain rolling-5h window and preserve weekly/monthly windows. The endpoint requires both `Authorization: Bearer <key>` and `x-api-key: <key>`; never expose either value in logs or test output.

## Verification order

1. Probe the current Hermes executable.
2. Confirm the bridge command exists in the current producer branch, not only in an orphan/stale commit.
3. Confirm the provider credential resolver returns a key/base URL without printing the key.
4. Probe the provider endpoint and inspect the actual response schema.
5. Test the producer's machine-readable JSON.
6. Test the Swift adapter with a fixture for the observed schema.
7. Test `swift run` and the installed `.app` separately; their environment and resource roots differ.

A successful parser test alone does not prove the installed `.app` can locate Hermes or that the current producer exposes the command.
