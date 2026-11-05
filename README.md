# My Dotfiles
Hermes Agent, Rex, Fastfetch, Vim, Neovim, Fish and Starship configuration files

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

Run the bootstrap script:

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh macos    # installs brew deps + all packages
```

It stows `nvim`, `fish`, `rex`, `fastfetch`, `starship`, `vim` and `hermes`.

--- 
## Custom subset

For a custom subset, install `stow` first:

```bash
brew install stow
```

Then link packages directly:

```bash
stow --target="$HOME" vim nvim fish
stow --target="$HOME" -D vim      # remove a package
```

The `macos` profile handles automatically:
- **JetBrainsMono Nerd Font** — via `brew`
- **tree-sitter-cli** — via `cargo`; installs Rust/rustup first if not present
- **[Hermes Agent](https://hermes-agent.nousresearch.com/docs/getting-started/installation)** — via the official installer
- **[neorex](https://github.com/ian-pascoe/neorex)** — built with `cargo` at a pinned revision into `~/.local/bin`
- **[termicons](https://github.com/mskelton/termicons)** — cannot be automated; the script opens the repo in the browser and waits for you to install it before continuing
- **[Rex](https://www.superlogical.com/rex/docs/installation)** — cannot be automated (beta); like termicons, the script opens the install page and waits; then it sets up terminfo, theme and app preferences

The `macos` profile also stows the tracked Hermes configuration into `~/.hermes`.
