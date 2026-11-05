#!/bin/bash
set -euo pipefail

# Pin the Rust continuation that was verified with Neovim 0.12 and Rex.
REVISION=066c0da5b3b4cc518c33f3fb0d17d2996752cbd9
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
for tool in git cargo; do
    command -v "$tool" >/dev/null || { echo "Missing $tool. Install Git and Rust 1.88+ first." >&2; exit 1; }
done

# Build inside dotfiles, then remove the disposable checkout on success or failure.
mkdir -p "$DOTFILES_DIR/.build" "$HOME/.local/bin"
build="$(mktemp -d "$DOTFILES_DIR/.build/neorex.XXXXXX")"
trap 'rm -rf "$build"' EXIT

git clone --filter=blob:none https://github.com/ian-pascoe/neorex.git "$build/source"
git -C "$build/source" checkout --detach "$REVISION"
cargo build --release --locked --manifest-path "$build/source/Cargo.toml" --target-dir "$build/target"
install -m 755 "$build/target/release/neorex" "$HOME/.local/bin/neorex"
printf 'Installed neorex (%s) at %s\n' "$REVISION" "$HOME/.local/bin/neorex"
