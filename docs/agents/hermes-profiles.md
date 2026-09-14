# Hermes profile inventory

These profiles are selected for declarative versioning in this dotfiles package:

| Profile | Versioned declarations | Excluded local state |
| --- | --- | --- |
| `apple-dev` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, all profile-local skills, cron runtime, memory, state database, caches |
| `wiki-dev` | `config.yaml`, `profile.yaml`, `SOUL.md`, `assets/avatar.png` | `.env`, auth, chat history, session dumps, all profile-local skills, cron runtime, memory, state database, caches |

The selected declarations contain non-secret profile settings. Stow links the versioned configuration into each local profile; runtime state remains outside this repository.

The selected declarations include the bot identity and chat metadata needed to restore each bot's assignment. Both `apple-dev` and `wiki-dev` are direct-chat bots with no group assignment or group protocol. The `profile.yaml` `ui_meta.hermes-bots.chat` value is a persistent bot-chat pointer, not chat history; it is intentionally versioned. Chat history, session dumps, and runtime room state remain excluded. If a future environment does not contain the referenced room, the pointer must be recreated or updated before use.

## Skill ownership and isolation

Shared skills belong to [taekwondodev/skills](https://github.com/taekwondodev/skills), checked out at `~/Developer/skills`. The `~/.agents/skills` symlink points to `~/Developer/skills/skills`. This is independent of the dotfiles Stow package.

The default, `apple-dev`, and `wiki-dev` configs use only `~/.agents/skills` in `skills.external_dirs`. Hermes also loads each profile's own local `skills/` directory automatically. `apple-dev` and `wiki-dev` do not include the default profile's `~/.hermes/skills` as an external directory.

Keep profile-specific skills in real, unversioned directories at `~/.hermes/profiles/<name>/skills/`, not in dotfiles or symlinks back into it. This applies to bundled, installed, and agent-created skills. New skills remain in the active profile unless deliberately promoted to the shared repository.

Do not add profile skills, `.env` files, auth files, memory, sessions, state databases, caches, or other generated runtime data to this package.