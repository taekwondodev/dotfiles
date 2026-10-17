#!/usr/bin/env bash
# Assemble public/build inputs only; no app execution, signing or installation.
set -euo pipefail
binary=$1
source=$2
app=$3
if [[ -e "$app" || -L "$app" ]]; then
  printf 'Refusing occupied bundle output: %s\n' "$app" >&2
  exit 1
fi
icon="$source/macos/notifier/AppIcon.png"
if [[ $(magick identify -format '%wx%h' "$icon") != 1024x1024 ]]; then
  printf 'Expected 1024x1024 app icon artwork\n' >&2
  exit 1
fi
mkdir -p "$(dirname "$app")"
mkdir "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp -p "$binary" "$app/Contents/MacOS/lavagna-notifier"
cp "$source/macos/notifier/Info.plist" "$app/Contents/Info.plist"
cp "$source/LICENSE" "$app/Contents/Resources/LICENSE"

# Keep upstream artwork; use Nix converters instead of host sips/iconutil.
icon_work=$(mktemp -d)
trap 'rm -rf "$icon_work"' EXIT
images=()
for size in 16 32 128 256 512 1024; do
  image="$icon_work/$size.png"
  magick "$icon" -resize "${size}x${size}" "PNG32:$image"
  images+=("$image")
done
png2icns "$app/Contents/Resources/AppIcon.icns" "${images[@]}"
test -s "$app/Contents/Resources/AppIcon.icns"
