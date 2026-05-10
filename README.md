# My Dotfiles
Claude Code, Kali, Ghostty, Vim, Neovim, Fish and Starship configuration files

## Install

Clone the repo:

```bash
git clone https://github.com/taekwondodev/dotfiles ~/dotfiles
cd ~/dotfiles
```

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

For a custom subset, stow packages directly:

```bash
stow vim nvim fish
stow -D ghostty   # remove a package
```

> **Neovim 0.12.0 or later required** for the nvim config.
>
> `tree-sitter-cli` is required by nvim-treesitter to build parsers:
> ```bash
> cargo install tree-sitter-cli
> ```
> Requires [Rust/cargo](https://rustup.rs) to be installed.

> **Fonts required:**
>
> - [JetBrainsMono Nerd Font](https://www.nerdfonts.com/) — needed for Ghostty and Starship icons.
>   - macOS: installed automatically by bootstrap.
>   - Linux:
>     ```bash
>     curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
>     mkdir -p ~/.local/share/fonts && tar -xf JetBrainsMono.tar.xz -C ~/.local/share/fonts && fc-cache -fv
>     ```
>
> - [termicons](https://github.com/mskelton/termicons) — needed for Neovim Material icon theme. See the repo for installation instructions.

## Kali setup

```bash
chmod +x scripts/setup_kali.sh
./scripts/setup_kali.sh
```

Then run `./scripts/bootstrap.sh linux` to link the dotfiles.

## Package manager support

The `linux` profile auto-detects `apt` (Debian/Ubuntu/Kali) and `dnf` (Fedora/RHEL/Amazon Linux).
Other package managers (`apk`, `pacman`, etc.) are not yet supported — add a case in `scripts/bootstrap.sh` if needed.
