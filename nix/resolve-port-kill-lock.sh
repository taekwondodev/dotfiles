#!/bin/bash
set -euo pipefail
source_dir=${1:?source directory required}
work=${2:?fresh resolution directory required}
mkdir "$work"
if [[ -f "$source_dir/Cargo.lock" ]]; then
    cp "$source_dir/Cargo.lock" "$work/Cargo.lock"
else
    cp -R "$source_dir" "$work/source"
    chmod -R u+w "$work/source"
    mkdir "$work/home" "$work/cargo-home"
    # Stay outside the source directory so Cargo does not load project config.
    # Use the caller's Nix toolchain PATH, never the user's Cargo home or rustup.
    (cd "$work"; env -i HOME="$work/home" CARGO_HOME="$work/cargo-home" PATH="$PATH" \
        cargo generate-lockfile --manifest-path "$work/source/Cargo.toml")
    cp "$work/source/Cargo.lock" "$work/Cargo.lock"
fi
