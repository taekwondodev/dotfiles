# My Dotfiles
Claude Code, Kali, Ghostty, Vim and Fish configuration files

## Requirements

```bash
brew install stow   # macOS
apt install stow    # Kali/Debian
```

## Install

Clone the repo and run stow from inside it:

```bash
git clone https://github.com/taekwondodev/dotfiles ~/dotfiles
cd ~/dotfiles
```

Link all packages:

```bash
stow vim fish ghostty claude
```

Or link a single package:

```bash
stow vim
```

Remove symlinks:

```bash
stow -D vim
stow -D vim fish ghostty claude
```

## Kali setup

```bash
chmod +x scripts/setup_kali.sh
./scripts/setup_kali.sh
```
