# Hermes profile inventory

These profiles are selected for declarative versioning in this dotfiles package:

| Profile | Versioned declaration | Excluded local state |
| --- | --- | --- |
| `macos-dev` | `config.yaml` | `.env`, auth, `SOUL.md`, profile-local skills, cron, memory, sessions, state database, caches |
| `release-reviewer` | `config.yaml` | `.env`, auth, `SOUL.md`, profile-local skills, cron, memory, sessions, state database, caches |
| `swiftui-reviewer` | `config.yaml` | `.env`, auth, `SOUL.md`, profile-local skills, cron, memory, sessions, state database, caches |
| `testing-reviewer` | `config.yaml` | `.env`, auth, `SOUL.md`, profile-local skills, cron, memory, sessions, state database, caches |
| `wiki-dev` | `config.yaml` | `.env`, auth, `SOUL.md`, profile-local skills, cron, memory, sessions, state database, caches |

The selected declaration contains non-secret profile settings and points the profile at the shared Hermes skill directory. The profile configs are restored through the Hermes dotfiles layout and are not copied into the repository from runtime state.

The user explicitly selected all five profiles for this inventory. No bot declaration was selected or copied. The installed `profile.yaml` format was inspected: its `ui_meta.hermes-bots.chat` value is a runtime chat identifier, so `profile.yaml` and bot UI metadata remain excluded. Bot runtime state and credentials are excluded. If a future portable bot declaration is selected, identify its installed Hermes format before adding it here.

Do not add profile `.env` files, auth files, memory, sessions, state databases, caches, or other generated runtime data to this package.
