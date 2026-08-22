# My Dotfiles
Hermes Agent, GitHub CLI, Kali, Ghostty, tmux, Vim, Neovim, Fish and Starship configuration files

## Install

Clone the repo:

```bash
git clone https://github.com/taekwondodev/dotfiles ~/dotfiles
cd ~/dotfiles
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
| tmux     | ✓ | ✓ | — |
| starship | ✓ | ✓ | — |
| vim      | ✓ | ✓ | ✓ |
| hermes   | ✓ | ✓ | — |
| gh       | ✓ | ✓ | — |

--- 
## Custom subset

For a custom subset, install `stow` first:

```bash
brew install stow                  # macOS
apt install -y stow                # Debian / Ubuntu / Kali
dnf install -y stow                # Amazon Linux / Fedora / RHEL
```

Then link packages directly:

```bash
stow vim nvim fish
stow -D ghostty   # remove a package
```

The `macos` and `linux` profiles handle automatically:
- **JetBrainsMono Nerd Font** — via `brew` on macOS, via `curl` + `fc-cache` on Linux
- **tree-sitter-cli** — via `cargo`; installs Rust/rustup first if not present
- **[Hermes Agent](https://hermes-agent.nousresearch.com/docs/getting-started/installation)** — via the official installer on macOS and Linux
- **[GitHub CLI](https://cli.github.com/)** (`gh`) — via Homebrew on macOS, via `apt`/`dnf` on Linux
- **[termicons](https://github.com/mskelton/termicons)** — cannot be automated; the script opens the repo in the browser and waits for you to install it before continuing

After the bootstrap completes, authenticate GitHub CLI if needed:

```bash
gh auth login
```

The `macos` and `linux` profiles also stow the tracked Hermes configuration into `~/.hermes`.

## Kali setup

```bash
./scripts/setup_kali.sh
```

Then run `./scripts/bootstrap.sh linux` to link the dotfiles.

## Package manager support

The `linux` profile auto-detects `apt` (Debian/Ubuntu/Kali) and `dnf` (Fedora/RHEL/Amazon Linux).
Other package managers (`apk`, `pacman`, etc.) are not yet supported — add a case in `scripts/bootstrap.sh` if needed.
