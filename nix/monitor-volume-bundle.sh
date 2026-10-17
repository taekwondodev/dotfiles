#!/usr/bin/env bash
# Assemble build/public inputs only. Never execute, sign or install the app.
set -euo pipefail
products=$1
source=$2
app=$3

if [[ -e "$app" || -L "$app" ]]; then
  printf 'Refusing occupied bundle output: %s\n' "$app" >&2
  exit 1
fi
shopt -s nullglob
artwork=("$source"/Resources/Media.xcassets/AppIcon.appiconset/*.png)
if [[ ${#artwork[@]} != 1 || ! -f "${artwork[0]}" || -L "${artwork[0]}" ]]; then
  printf 'Expected exactly one regular app icon PNG\n' >&2
  exit 1
fi
if [[ $(magick identify -format '%wx%h' "${artwork[0]}") != 1024x1024 ]]; then
  printf 'Expected 1024x1024 app icon artwork\n' >&2
  exit 1
fi

mkdir -p "$(dirname "$app")"
mkdir "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp -p "$products/MonitorVolume" "$app/Contents/MacOS/MonitorVolume"
cp "$source/Resources/Info.plist" "$app/Contents/Info.plist"
cp "$source/LICENSE" "$source/THIRD_PARTY_NOTICES.md" "$app/Contents/Resources/"

# Nix-owned converters, rather than host sips/iconutil or a fallback image.
icon_work=$(mktemp -d)
trap 'rm -rf "$icon_work"' EXIT
images=()
for size in 16 32 128 256 512 1024; do
  image="$icon_work/$size.png"
  magick "${artwork[0]}" -resize "${size}x${size}" "PNG32:$image"
  images+=("$image")
done
png2icns "$app/Contents/Resources/AppIcon.icns" "${images[@]}"
test -s "$app/Contents/Resources/AppIcon.icns"
