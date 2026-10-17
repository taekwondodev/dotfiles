#!/bin/bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd -P)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/admission.sh
source "$repo/nix/admission.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home with spaces"
store="$tmp/store with spaces"
current="$tmp/current-system"
profile="$tmp/profiles/system"
mkdir -p "$home/.config" "$store" "$tmp/profiles"
roots="$repo/nix/protected-roots"
manifest="$tmp/desired"
printf 'link\t.vimrc\nlink\tApplications/Lavagna.app\nlink\t.claude/skills/example\nseed\t.claude/settings.json\nseed\t.hermes/config.yaml\n' > "$manifest"
early() { local generations; generations=$(dotfiles_generations "$home" "$store" "$current" "$profile" "$profile"-*-link) && dotfiles_admit "$home" "$generations" "$store" "$roots"; }
admit() { local generations; generations=$(dotfiles_generations "$home" "$store" "$current" "$profile" "$profile"-*-link) && dotfiles_admit "$home" "$generations" "$store" "$roots" "$manifest"; }
refuses() {
    local output
    if output=$(admit 2>&1); then printf 'Unexpected admission: %s\n' "$1" >&2; exit 1; fi
    [[ "$output" == *"$1"* ]] || { printf 'Wrong refusal: %s\n' "$output" >&2; exit 1; }
}

# Fresh target; no native installation, installer, profile or host setting touched.
admit
# Xcode customization is excluded: existing app-owned data is not our target.
xcode="$home/Library/Developer/Xcode/UserData"
mkdir -p "$xcode"
printf 'personal Xcode settings\n' > "$xcode/marker"
early
admit
[[ $(<"$xcode/marker") = 'personal Xcode settings' ]]
# The early guard has no evaluated manifest yet, but must protect these roots.
for relative in Applications/Lavagna.app .claude/skills; do
    mkdir -p "$home/$relative"
    printf 'unmanaged content\n' > "$home/$relative/marker"
    if output=$(early 2>&1); then
        printf 'Unexpected early admission for existing %s\n' "$relative" >&2; exit 1
    fi
    [[ "$output" == *"unmanaged destination: $home/$relative"* && $(<"$home/$relative/marker") = 'unmanaged content' ]]
    rm "$home/$relative/marker"
    rmdir "$home/$relative"
done
printf 'preserve me\n' > "$home/.vimrc"
refuses 'unmanaged destination'
[[ $(<"$home/.vimrc") = 'preserve me' ]]
# A stale/copied mutable marker grants no ownership.
printf 'taekwondodev/dotfiles nix-darwin + home-manager\n' > "$home/.config/.dotfiles-nix-owner"
refuses 'unmanaged destination'
rm "$home/.vimrc" "$home/.config/.dotfiles-nix-owner"
# Legacy link through a parent must not be followed for writes.
rmdir "$home/.config"
mkdir "$tmp/live-config"
ln -s "$tmp/live-config" "$home/.config"
refuses 'symlinked destination parent'
[[ -L "$home/.config" && $(readlink "$home/.config") = "$tmp/live-config" ]]
rm "$home/.config"
mkdir "$home/.config"

# Model native immutable generation outputs and its actual active HM GC root.
# The injected filesystem roots are the same inputs the production callers use;
# no Nix/store/profile/activation operation runs in these fixtures.
native="$store/old-darwin-system"
hm="$store/old-home-manager-generation"
mkdir -p "$native/dotfiles" "$hm/home-files/Applications/Lavagna.app" "$home/.local/state/home-manager/gcroots" "$home/.hermes"
printf 'taekwondodev/dotfiles:%s\n' "$home" > "$native/dotfiles/identity"
printf 'fixture-user\n' > "$native/dotfiles/user"
cp "$manifest" "$native/dotfiles/destinations"
printf 'managed config\n' > "$hm/home-files/.vimrc"
ln -s "$hm" "$native/dotfiles/home-manager"
ln -s "$native" "$current"
ln -s "$hm" "$home/.local/state/home-manager/gcroots/current-home"
ln -s "$hm/home-files/.vimrc" "$home/.vimrc"
ln -s "$hm/home-files/Applications/Lavagna.app" "$home/Applications/Lavagna.app"
printf 'personal edit\n' > "$home/.hermes/config.yaml"
mkdir -p "$hm/home-files/.claude/skills/example" "$home/.claude/skills/synced"
ln -s "$hm/home-files/.claude/skills/example" "$home/.claude/skills/example"
printf '{"model":"personal choice"}\n' > "$home/.claude/settings.json"
printf 'private synced content\n' > "$home/.claude/skills/synced/marker"
admit
[[ $(<"$home/.hermes/config.yaml") = 'personal edit' ]]
[[ ! -L "$home/.claude/settings.json" && $(<"$home/.claude/settings.json") = '{"model":"personal choice"}' ]]
[[ $(<"$home/.claude/skills/synced/marker") = 'private synced content' ]]
rm "$home/Applications/Lavagna.app"
mkdir "$home/Applications/Lavagna.app"
printf 'replacement app\n' > "$home/Applications/Lavagna.app/marker"
refuses 'changed managed link'
[[ $(<"$home/Applications/Lavagna.app/marker") = 'replacement app' ]]
rm "$home/Applications/Lavagna.app/marker"
rmdir "$home/Applications/Lavagna.app"
ln -s "$hm/home-files/Applications/Lavagna.app" "$home/Applications/Lavagna.app"
# A matching identity alone cannot authorize the wrong active HM generation.
rm "$home/.local/state/home-manager/gcroots/current-home"
ln -s "$store/other-home-manager" "$home/.local/state/home-manager/gcroots/current-home"
refuses 'Home Manager generation differs'
rm "$home/.local/state/home-manager/gcroots/current-home"
ln -s "$hm" "$home/.local/state/home-manager/gcroots/current-home"
# Recheck detects a target replaced after a previous successful admission.
rm "$home/.vimrc"
printf 'replaced since admission\n' > "$home/.vimrc"
refuses 'changed managed link'
[[ $(<"$home/.vimrc") = 'replaced since admission' ]]
rm "$home/.vimrc"
ln -s "$hm/home-files/.vimrc" "$home/.vimrc"
# An interrupted first activation: no active system, but the generation was
# recorded in the system profile before activating. A rerun resumes it.
rm "$current"
ln -s "$native" "$tmp/profiles/system-1-link"
ln -s system-1-link "$profile"
admit
# Home Manager never ran: its links are not owned, even with a recorded generation.
mv "$home/.local/state/home-manager/gcroots/current-home" "$tmp/saved-gcroot"
refuses 'unmanaged destination'
mv "$tmp/saved-gcroot" "$home/.local/state/home-manager/gcroots/current-home"
# A rerun records a newer generation; the interrupted one stays in the history.
newer="$store/new-darwin-system"
mkdir -p "$newer/dotfiles"
cp "$native/dotfiles/identity" "$native/dotfiles/destinations" "$newer/dotfiles/"
ln -s "$store/new-home-manager-generation" "$newer/dotfiles/home-manager"
mkdir -p "$store/new-home-manager-generation/home-files"
ln -s "$newer" "$tmp/profiles/system-2-link"
rm "$profile"
ln -s system-2-link "$profile"
admit
# An old generation whose Home Manager reference no longer resolves is skipped,
# not fatal, while another generation still matches the installed home.
broken="$store/broken-darwin-system"
mkdir -p "$broken/dotfiles"
cp "$native/dotfiles/identity" "$broken/dotfiles/"
ln -s "$store/missing-home-manager" "$broken/dotfiles/home-manager"
ln -s "$broken" "$tmp/profiles/system-0-link"
admit
rm "$tmp/profiles/system-0-link"
# A profile generation of another setup is refused, not ignored.
foreign="$store/foreign-darwin-system"
mkdir -p "$foreign/dotfiles"
printf 'someone/else:%s\n' "$home" > "$foreign/dotfiles/identity"
ln -s "$foreign" "$tmp/profiles/system-3-link"
refuses 'native generation identity mismatch'
rm "$tmp/profiles/system-3-link"
ln -s "$tmp/outside-store" "$tmp/profiles/system-3-link"
mkdir -p "$tmp/outside-store/dotfiles"
cp "$native/dotfiles/identity" "$tmp/outside-store/dotfiles/"
refuses 'not owned by this setup'
rm "$tmp/profiles/system-3-link"
admit
# New declarations cannot adopt a pre-existing file on a managed host.
printf 'link\t.config/new-file\n' >> "$manifest"
printf 'unowned\n' > "$home/.config/new-file"
refuses 'new destination is unmanaged'
[[ $(<"$home/.config/new-file") = 'unowned' ]]

printf 'PASS: fresh, unmanaged, legacy parent, stale marker, native ownership, changed target, interrupted activation, profile history, foreign generation, new conflict and writable seed\n'
