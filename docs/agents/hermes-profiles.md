# Hermes profile inventory

These profiles are selected for declarative versioning in this dotfiles package:

| Profile | Versioned declarations | Excluded local state |
| --- | --- | --- |
| `macos-dev` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, profile-local bundled skills, cron runtime, memory, state database, caches |
| `release-reviewer` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, profile-local bundled skills, cron runtime, memory, state database, caches |
| `swiftui-reviewer` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, profile-local bundled skills, cron runtime, memory, state database, caches |
| `testing-reviewer` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, profile-local bundled skills, cron runtime, memory, state database, caches |
| `wiki-dev` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, profile-local bundled skills, cron runtime, memory, state database, caches |

The selected declaration contains non-secret profile settings and points the profile at the shared Hermes skill directory. The profile configs are restored through the Hermes dotfiles layout and are not copied into the repository from runtime state.

The selected declarations include the bot identity and group/chat metadata needed to restore each bot's assignment. `wiki-dev` is intentionally a direct-chat bot with no group assignment or group protocol. The `profile.yaml` `ui_meta.hermes-bots.chat` values are persistent bot-chat pointers, not chat history; they are intentionally versioned because the user selected the bot group association. Chat history, session dumps, and runtime room state remain excluded. If a future environment does not contain the referenced room, the pointer must be recreated or updated before use.

Do not add profile `.env` files, auth files, memory, sessions, state databases, caches, or other generated runtime data to this package.
