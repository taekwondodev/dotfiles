#!/usr/bin/env bash
# Extract exact management outputs from the native setup script's Nix closure.
# Run during the native build, never by observing a mutable host prefix.
set -euo pipefail
brew='' code='' taps=''
while IFS= read -r path; do
    if [[ -f "$path" && "$path" = *-brew ]]; then
        [[ -z "$brew" ]] || { echo 'Ambiguous native Brew launcher' >&2; exit 1; }
        brew=$path
    fi
    if [[ -d "$path/Library/Homebrew" ]]; then
        [[ -z "$code" ]] || { echo 'Ambiguous native Brew source' >&2; exit 1; }
        code=$path/Library/Homebrew
    fi
    if [[ -L "$path/homebrew/homebrew-core" && -L "$path/homebrew/homebrew-cask" ]]; then
        [[ -z "$taps" ]] || { echo 'Ambiguous native Brew tap tree' >&2; exit 1; }
        taps=$path
    fi
done < "${1:?native setup closure required}"
[[ -n "$brew" && -n "$code" && -n "$taps" ]] || { echo 'Incomplete native Brew management outputs' >&2; exit 1; }
printf 'bin/brew\t%s\nLibrary/Homebrew\t%s\nLibrary/Taps\t%s\n' "$brew" "$code" "$taps"
