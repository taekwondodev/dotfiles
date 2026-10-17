#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/admission.sh
source nix/admission.sh
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/native-admission.sh
source nix/native-admission.sh
fixture=$(mktemp -d)
fixture=$(cd "$fixture" && pwd -P)
trap 'rm -rf "$fixture"' EXIT
home=$fixture/home
native=$fixture/store/system
etc=$fixture/etc
profile=$fixture/profiles/system
prefix=$fixture/opt/homebrew
mkdir -p "$home" "$etc" "$(dirname "$profile")" "$native/etc/profiles/per-user/person" "$native/dotfiles" "$fixture/store/foreign/dotfiles"
printf 'taekwondodev/dotfiles:%s\n' "$home" > "$native/dotfiles/identity"
admit() {
    local generations
    generations=$(dotfiles_generations "$home" "$fixture/store" "$fixture/current" "$profile" "$profile"-*-link) &&
        dotfiles_admit_native "$home" person "$generations" "$etc" "$profile" "$prefix"
}
refuse() { if admit 2> "$fixture/error"; then printf 'FAIL: accepted %s\n' "$1" >&2; exit 1; fi; }
# The account query is the sole mocked OS input, not an actual setting change.
dscl() { printf 'NFSHomeDirectory: %s\n' "$fixture/home"; }
dotfiles_admit_account person "$home"
if dotfiles_admit_account person "$fixture/wrong" 2> "$fixture/error"; then exit 1; fi
admit
ln -s "$fixture/store/foreign" "$profile"
refuse 'a system profile of another setup'
rm "$profile"
mkdir "$etc/static"
refuse 'an unowned etc/static directory'
rmdir "$etc/static"
mkdir -p "$prefix"
: > "$prefix/.managed_by_nix_darwin"
refuse 'a copied marker without a native generation'
rm "$prefix/.managed_by_nix_darwin"
rmdir "$prefix"
ln -s "$native" "$fixture/current"
ln -s "$native" "$fixture/profiles/system-1-link"
ln -s system-1-link "$profile"
ln -s "$native/etc" "$etc/static"
mkdir -p "$etc/profiles/per-user"
ln -s "$native/etc/profiles/per-user/person" "$etc/profiles/per-user/person"
admit
rm "$profile"
ln -s "$home" "$profile"
refuse 'an unrelated profile even with a valid current generation'
rm "$profile"
ln -s system-1-link "$profile"
rm "$etc/profiles/per-user/person"
ln -s "$home" "$etc/profiles/per-user/person"
refuse 'a replaced per-user profile'
rm "$etc/profiles/per-user/person"
ln -s "$native/etc/profiles/per-user/person" "$etc/profiles/per-user/person"
mkdir -p "$prefix/bin" "$prefix/Library/.homebrew-is-managed-by-nix/.git"
: > "$prefix/.managed_by_nix_darwin"
: > "$prefix/Library/.homebrew-is-managed-by-nix/.git/HEAD"
mkdir -p "$fixture/store/code/Library/Homebrew" "$fixture/store/taps/homebrew" "$fixture/store/core" "$fixture/store/cask"
printf 'fixture launcher\n' > "$fixture/store/hash-brew"
ln -s "$fixture/store/core" "$fixture/store/taps/homebrew/homebrew-core"
ln -s "$fixture/store/cask" "$fixture/store/taps/homebrew/homebrew-cask"
printf '%s\n' "$fixture/store/hash-brew" "$fixture/store/code" "$fixture/store/taps" > "$fixture/closure"
bash nix/homebrew-links.sh "$fixture/closure" > "$native/dotfiles/homebrew-links"
printf 'bin/brew\t%s\nLibrary/Homebrew\t%s\nLibrary/Taps\t%s\n' \
    "$fixture/store/hash-brew" "$fixture/store/code/Library/Homebrew" "$fixture/store/taps" > "$fixture/expected"
cmp "$fixture/expected" "$native/dotfiles/homebrew-links"
ln -s "$fixture/store/hash-brew" "$prefix/bin/brew"
ln -s "$fixture/store/code/Library/Homebrew" "$prefix/Library/Homebrew"
ln -s "$fixture/store/taps" "$prefix/Library/Taps"
admit
# Interrupted first activation: only the recorded profile generation exists.
rm "$fixture/current"
admit
# A newer recorded generation keeps the interrupted one's links owned.
newer=$fixture/store/newer
mkdir -p "$newer/dotfiles" "$newer/etc/profiles/per-user/person"
cp "$native/dotfiles/identity" "$newer/dotfiles/"
printf 'bin/brew\t%s\n' "$fixture/store/core" > "$newer/dotfiles/homebrew-links"
ln -s "$newer" "$fixture/profiles/system-2-link"
rm "$profile"
ln -s system-2-link "$profile"
admit
rm "$profile"
ln -s system-1-link "$profile"
rm "$fixture/profiles/system-2-link"
ln -s "$native" "$fixture/current"
# A different store path does not establish this generation's ownership.
rm "$prefix/bin/brew"
ln -s "$fixture/store/core" "$prefix/bin/brew"
refuse 'an arbitrary store target in the managed prefix'
rm "$prefix/bin/brew"
ln -s "$fixture/store/hash-brew" "$prefix/bin/brew"
printf 'precious data\n' > "$prefix/Library/.homebrew-is-managed-by-nix/keep"
refuse 'unrelated data in the recreated synthetic repository'
[[ -f "$prefix/Library/.homebrew-is-managed-by-nix/keep" ]]
rm "$prefix/Library/.homebrew-is-managed-by-nix/keep"
mkdir -p "$home/.homebrew"
: > "$home/.homebrew/brew.env"
refuse 'an environment file overriding immutable tap selection'
rm "$home/.homebrew/brew.env"
admit
printf '%s\n' "$fixture/store/hash-brew" >> "$fixture/closure"
if bash nix/homebrew-links.sh "$fixture/closure" 2> "$fixture/error"; then
    printf 'FAIL: ambiguous native output discovery\n' >&2; exit 1
fi
printf '%s\n' 'PASS: account, native profiles, recorded and interrupted generations, exact Brew management links, protected scaffold and environment overrides'
