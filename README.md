# My Dotfiles
Hermes Agent, Ghostty, Rex, Fastfetch, Vim, Neovim, Fish and Starship configuration files

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
| fastfetch | ✓ | — | — |
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

Shell greeting: inside Rex, `fish_greeting` runs `fastfetch` with
`fastfetch/.config/fastfetch/config.jsonc`, laid out like macOS "About This Mac":
the Wall-E avatar (`walle.png`, a circular PNG drawn via the kitty graphics
protocol) next to name, model, chip, memory, macOS, uptime, shell and terminal,
in Rose Pine colors. It is skipped outside Rex (`REX_SESSION` unset), in panes
smaller than 80×20, and in shells nested inside a greeted one (e.g. nvim's
`:terminal`). `fish/.hushlogin` hides macOS's `Last login` line in every terminal.

### Neorex and native LazyGit

The editor frontend is [ian-pascoe/neorex](https://github.com/ian-pascoe/neorex),
pinned to `066c0da5b3b4cc518c33f3fb0d17d2996752cbd9`. It requires Rex,
Neovim **0.12+** and Rust **1.88+** to build. The macOS bootstrap installs it;
to install or rebuild it separately:

```bash
brew install neovim lazygit python3           # Git and Cargo must also be available
bash scripts/install-neorex.sh
rex terminfo setup                         # account terminfo + SSH fallback guard
rex terminfo status
neorex README.md                           # run inside a Rex pane
```

The installer builds a temporary checkout inside `.build/`, removes it afterward,
and installs only the executable at `~/.local/bin/neorex`. Fish adds that directory
to PATH. No alternate Neovim config, trial wrapper or duplicate source tree is needed.
The ordinary `nvim` command remains available, and Ghostty stays independently configured.
Fish preserves the terminal-provided `TERM`; the official terminfo setup installs
`xterm-rex` before Rex selects it. It also adds a targeted include to `~/.ssh/config`
for hosts without the entry. Generated Rex SSH guards/host records are machine-local
and ignored by Git. No remote host is provisioned. Existing terminals keep their
current TERM; restart Rex's server when convenient if it still advertises
`xterm-256color`. Do not interrupt active work just to switch terminal types.

- `:split` and `:vsplit` become native Rex editor panes with one shared Neovim backend.
  Use Rex for pane navigation. A normal Rex split opens a shell, not a view of that backend.
- **Space g g / Space g s** open LazyGit as a Rex-owned process in a centered 90% float;
  **Space g l** opens its log view. The project root follows the current buffer, falling
  back to Neovim's working directory. These mappings require Rex, including in ordinary `nvim`.
- **e** in LazyGit opens the file in the originating Neovim window, then closes the
  floating block. Line-based edits also position the cursor. **q** closes the float,
  restores editor focus, checks changed files and refreshes Gitsigns.
- Snacks remains for explorer, pickers and other UI, not terminal/LazyGit hosting.
  The custom Neovim pane mappings and **Cmd+J** are removed. Automatic `qa!` and
  window-count-based exit hooks are removed so they cannot discard buffers or
  misinterpret external windows. These removals also apply to ordinary `nvim` and
  the Linux profile; standard Neovim `Ctrl+w` commands remain available there.

Configuration: `nvim/.config/nvim/lua/config/rex_lazygit.lua`,
`nvim/.config/nvim/lazygit-rex.yml`, and
`nvim/.config/nvim/bin/lazygit-editor.py`. LazyGit's state is under
Neovim's state directory, separate from a standalone LazyGit installation.

Neorex is experimental. Neovim tabpages do **not** map transparently to Rex tabs;
a new Rex tab with another `neorex` starts another editor backend. Closing an
individual editor pane can leave its modified buffer hidden; use Neovim's save/quit
commands before closing the last pane. Noice compatibility and exact placement of
window-layout plugins are not guaranteed.

Migration limits: add **termicons** in Rex's terminal font fallback picker manually.
Per-codepoint font overrides and the explicit OpenType `zero` feature are not ported.
There is no documented equivalent for Ghostty's global quick terminal, opacity/blur,
initial window dimensions, `window-save-state`, scrollback byte limit, vsync, or
secure-input indicator. Fish/Starship stay shared through their existing packages;
Ghostty-specific shell integration settings are not copied into Rex.

## Package manager support

The `linux` profile auto-detects `apt` (Debian/Ubuntu) and `dnf` (Fedora/RHEL/Amazon Linux).
Other package managers (`apk`, `pacman`, etc.) are not yet supported — add a case in `scripts/bootstrap.sh` if needed.
