#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/admission.sh
source nix/admission.sh
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/native-admission.sh
source nix/native-admission.sh
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/cask-admission.sh
source nix/cask-admission.sh
fixture=$(mktemp -d)
fixture=$(cd "$fixture" && pwd -P)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/Applications" "$fixture/current/dotfiles"
printf '{"ghostty":"Ghostty.app"}\n' > "$fixture/desired.json"
mkdir "$fixture/bin"
meta=$fixture/Caskroom/ghostty/.metadata
receipt() { mkdir -p "$meta/1.3.1/$1/Casks" && : > "$meta/1.3.1/$1/Casks/ghostty.json"; }
jq -n --arg app "$fixture/Applications/Ghostty.app" --arg link "$fixture/bin/ghostty" \
    '{ghostty: {($app): {kind: "app"}, ($link): {kind: "link", source: ($app + "/Contents/MacOS/ghostty")}}}' > "$fixture/artifacts.json"
generations=$fixture/current
admit() {
    dotfiles_admit_casks "$generations" "$fixture/Applications" "$fixture" "$fixture/desired.json" "$fixture/artifacts.json"
}
refuse() {
    if admit 2> "$fixture/error"; then printf 'FAIL: accepted %s\n' "$1" >&2; exit 1; fi
}
admit
mkdir -p "$fixture/Caskroom/ghostty"
refuse 'an unowned Caskroom entry'
rmdir "$fixture/Caskroom/ghostty" "$fixture/Caskroom"
ln -s "$fixture/Applications" "$fixture/Caskroom"
refuse 'a symlinked Caskroom parent'
rm "$fixture/Caskroom"
mkdir "$fixture/Applications/Ghostty.app"
refuse 'an unmanaged app'
receipt 20260101000000.000
refuse 'a pre-existing Brew install without native ownership'
cp "$fixture/desired.json" "$fixture/current/dotfiles/casks.json"
admit
mkdir -p "$meta/1.3.2/20270101000000.000/Casks"
refuse 'an app whose latest Brew receipt is missing'
receipt 20270101000000.000
admit
# Any owned generation may declare it, e.g. an interrupted one in the profile history.
mkdir -p "$fixture/newer/dotfiles"
printf '{}\n' > "$fixture/newer/dotfiles/casks.json"
generations=$(printf '%s\n' "$fixture/newer" "$fixture/current")
admit
generations=$fixture/newer
refuse 'a cask declared by no owned generation'
generations=$fixture/current
# Production composition: only the active system and the recorded profile vouch
# for casks. A history generation that once declared a dropped cask does not.
store=$fixture/store
mkdir -p "$store/old/dotfiles" "$store/recorded/dotfiles" "$fixture/profiles"
for generation in old recorded; do printf 'taekwondodev/dotfiles:%s\n' "$fixture/home" > "$store/$generation/dotfiles/identity"; done
cp "$fixture/desired.json" "$store/old/dotfiles/casks.json"
printf '{}\n' > "$store/recorded/dotfiles/casks.json"
ln -s "$store/old" "$fixture/profiles/system-1-link"
ln -s "$store/recorded" "$fixture/profiles/system-2-link"
ln -s system-2-link "$fixture/profiles/system"
generations=$(dotfiles_generations "$fixture/home" "$store" "$fixture/no-current-system" "$fixture/profiles/system")
refuse 'a dropped cask vouched for only by a history generation'
generations=$(dotfiles_generations "$fixture/home" "$store" "$fixture/no-current-system" "$fixture/profiles/system" "$fixture/profiles/system"-*-link)
admit
generations=$fixture/current
printf '{"default":{"appdir":"/Applications"},"env":{},"explicit":{"appdir":"%s"}}\n' "$fixture/Applications" > "$meta/config.json"
admit
printf '{"default":{"appdir":"%s"},"env":{"appdir":"/Elsewhere"},"explicit":{}}\n' "$fixture/Applications" > "$meta/config.json"
refuse 'a stored cask configuration redirecting the appdir'
printf '{"default":{"appdir":"/Elsewhere"}}\n' > "$meta/config.json"
refuse 'a stored default appdir override'
printf 'not json\n' > "$meta/config.json"
refuse 'an unreadable stored cask configuration'
rm "$meta/config.json"
ln -s "$fixture/desired.json" "$meta/config.json"
refuse 'a symlinked stored cask configuration'
rm "$meta/config.json"
mv "$meta" "$fixture/real-meta"
ln -s "$fixture/real-meta" "$meta"
refuse 'a symlinked cask metadata directory'
rm "$meta"
mv "$fixture/real-meta" "$meta"
rmdir "$fixture/Applications/Ghostty.app"
ln -s "$fixture/current" "$fixture/Applications/Ghostty.app"
refuse 'a replaced application symlink'
rm "$fixture/Applications/Ghostty.app"
mkdir "$fixture/Applications/Spotify.app"
refuse 'standard Spotify alongside SpotX'
rmdir "$fixture/Applications/Spotify.app"
mkdir "$fixture/Caskroom/spotify"
refuse 'a standard Spotify Caskroom entry'
rmdir "$fixture/Caskroom/spotify"
printf 'unrelated executable' > "$fixture/bin/ghostty"
refuse 'an unowned extra cask binary'
rm "$fixture/bin/ghostty"
ln -s "$fixture/Applications/Ghostty.app/Contents/MacOS/ghostty" "$fixture/bin/ghostty"
refuse 'an extra cask link without a native declaration'
cp "$fixture/artifacts.json" "$fixture/current/dotfiles/cask-artifacts.json"
admit
rm "$fixture/bin/ghostty"
ln -s /unrelated "$fixture/bin/ghostty"
refuse 'a replaced extra cask link'
rm "$fixture/bin/ghostty"
mv "$fixture/bin" "$fixture/real-bin"
ln -s "$fixture/Applications" "$fixture/bin"
refuse 'a symlinked cask link parent'
rm "$fixture/bin"
mv "$fixture/real-bin" "$fixture/bin"
printf 'not json\n' > "$fixture/desired.json"
refuse 'invalid inventory'
printf '%s\n' 'PASS: fresh casks, native+receipt ownership by the active or recorded generation only, stored cask configuration, unmanaged apps, changed targets, standard Spotify and invalid inventory'
