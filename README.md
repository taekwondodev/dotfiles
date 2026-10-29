# My Dotfiles
Hermes Agent, Ghostty, Rex, Vim, Neovim, Fish and Starship configuration files

## Install

Clone the repo:

```bash
git clone https://github.com/taekwondodev/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
```

Prerequisites:

- **`macos`** — [Homebrew](https://brew.sh):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- **`linux`** — `curl` and `sudo` (usually pre-installed; if not: `apt install curl` / `dnf install curl`)

Run the bootstrap script with a profile:

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh macos    # macOS — installs brew deps + all packages
./scripts/bootstrap.sh linux    # Linux desktop — installs apt/dnf deps + all packages
./scripts/bootstrap.sh server   # Remote server — vim only, no deps needed
```

| Package  | macos | linux | server |
|----------|:-----:|:-----:|:------:|
| nvim     | ✓ | ✓ | — |
| fish     | ✓ | ✓ | — |
| ghostty  | ✓ | ✓ | — |
| rex      | ✓ | — | — |
| starship | ✓ | ✓ | — |
| vim      | ✓ | ✓ | ✓ |
| hermes   | ✓ | ✓ | — |

--- 
## Custom subset

For a custom subset, install `stow` first:

```bash
brew install stow                  # macOS
apt install -y stow                # Debian / Ubuntu
dnf install -y stow                # Amazon Linux / Fedora / RHEL
```

Then link packages directly:

```bash
stow --target="$HOME" vim nvim fish
stow --target="$HOME" -D ghostty   # remove a package
```

The `macos` and `linux` profiles handle automatically:
- **JetBrainsMono Nerd Font** — via `brew` on macOS, via `curl` + `fc-cache` on Linux
- **tree-sitter-cli** — via `cargo`; installs Rust/rustup first if not present
- **[Hermes Agent](https://hermes-agent.nousresearch.com/docs/getting-started/installation)** — via the official installer on macOS and Linux
- **[termicons](https://github.com/mskelton/termicons)** — cannot be automated; the script opens the repo in the browser and waits for you to install it before continuing

The `macos` and `linux` profiles also stow the tracked Hermes configuration into `~/.hermes`.

## Rex (macOS)

Install [Rex](https://www.superlogical.com/rex/docs/installation), then link its configuration:

```bash
stow --simulate --verbose --target="$HOME" rex  # check for conflicts first
stow --target="$HOME" rex
rex config check
rex config reload
bash scripts/configure-rex-macos.sh           # run from a Rex terminal
# With multiple connected apps: bash scripts/configure-rex-macos.sh CLIENT_ID
```

The macOS bootstrap also stows `rex`; it does not install Rex or apply its app preferences.
Ghostty remains installed/configured independently.

- `rex/.config/rex/init.lua`: Ghostty-compatible **Cmd+Shift+T** (new tab),
  **Cmd+D** (split right), **Cmd+Shift+D** (split down), **Cmd+W** (close pane).
  **Cmd+C / Cmd+V** retain Rex's native copy/paste handling.
- `rex/.config/rex/themes/rose-pine-moon`: the same palette as Ghostty, imported
  and selected by the macOS script without requiring Ghostty to be installed.
- `scripts/configure-rex-macos.sh`: sets JetBrainsMono Nerd Font Mono at 15 pt,
  +35% line height, ligatures, a block cursor (applications may override its shape),
  left Option as Alt, and copy-on-select. These use native app preference keys observed in Rex Beta
  **0.1.0 (1541)**, not a documented Lua API; recheck them after Rex updates.
  The script does not restart Rex. If preferences do not update live, quit/reopen
  the app when convenient. It never replaces/symlinks the whole app plist, which
  also contains session and connection state.

Migration limits: add **termicons** in Rex's terminal font fallback picker manually.
Per-codepoint font overrides and the explicit OpenType `zero` feature are not ported.
There is no documented equivalent for Ghostty's global quick terminal, opacity/blur,
initial window dimensions, `window-save-state`, scrollback byte limit, vsync, or
secure-input indicator. Fish/Starship stay shared through their existing packages;
Ghostty-specific shell integration settings are not copied into Rex.

## Package manager support

The `linux` profile auto-detects `apt` (Debian/Ubuntu) and `dnf` (Fedora/RHEL/Amazon Linux).
Other package managers (`apk`, `pacman`, etc.) are not yet supported — add a case in `scripts/bootstrap.sh` if needed.
