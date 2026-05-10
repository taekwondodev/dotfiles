# My Dotfiles
Claude Code, Kali, Ghostty, Vim, Neovim, Fish and Starship configuration files

## Install

Clone the repo:

```bash
git clone https://github.com/taekwondodev/dotfiles ~/dotfiles
cd ~/dotfiles
```

Prerequisites:

| Profile | Requires |
|---------|----------|
| `macos` | [Homebrew](https://brew.sh) |
| `linux` | `curl`, `sudo` |
| `server` | `stow` |

Run the bootstrap script with a profile:

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh macos    # macOS — installs brew deps + all packages
./scripts/bootstrap.sh linux    # Linux desktop — installs apt/dnf deps + all packages except claude
./scripts/bootstrap.sh server   # Remote server — vim only, no deps needed
```

| Package  | macos | linux | server |
|----------|:-----:|:-----:|:------:|
| nvim     | ✓ | ✓ | — |
| fish     | ✓ | ✓ | — |
| ghostty  | ✓ | ✓ | — |
| starship | ✓ | ✓ | — |
| vim      | ✓ | ✓ | ✓ |
| claude   | ✓ | — | — |

For a custom subset, install `stow` first, then link packages directly:

```bash
stow vim nvim fish
stow -D ghostty   # remove a package
```

> **Neovim 0.12.0 or later required** for the nvim config.

The `macos` and `linux` profiles handle automatically:
- **JetBrainsMono Nerd Font** — via `brew` on macOS, via `curl` + `fc-cache` on Linux
- **tree-sitter-cli** — via `cargo`; installs Rust/rustup first if not present
- **[termicons](https://github.com/mskelton/termicons)** — cannot be automated; the script opens the repo in the browser and waits for you to install it before continuing

## Kali setup

```bash
chmod +x scripts/setup_kali.sh
./scripts/setup_kali.sh
```

Then run `./scripts/bootstrap.sh linux` to link the dotfiles.

## Package manager support

The `linux` profile auto-detects `apt` (Debian/Ubuntu/Kali) and `dnf` (Fedora/RHEL/Amazon Linux).
Other package managers (`apk`, `pacman`, etc.) are not yet supported — add a case in `scripts/bootstrap.sh` if needed.
