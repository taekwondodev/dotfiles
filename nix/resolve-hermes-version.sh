#!/bin/bash
set -euo pipefail
revision=${1:?Hermes source revision required}
work=${2:?fresh metadata directory required}
[[ $revision =~ ^[0-9a-f]{40}$ ]] || { printf 'Invalid Hermes revision\n' >&2; exit 1; }
mkdir "$work"
work=$(cd "$work" && pwd)
# Git metadata only: no checkout, hooks, user configuration or authentication.
# Keep the publisher's dependency locks untouched.
env -i PATH="$PATH" HOME="$work" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
    git init --bare --template= "$work/repository" >/dev/null
git_metadata() {
    env -i PATH="$PATH" HOME="$work" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
        git -C "$work/repository" "$@"
}
git_metadata fetch --filter=blob:none --tags https://github.com/NousResearch/hermes-agent.git "$revision" >&2
[[ $(git_metadata rev-parse FETCH_HEAD) == "$revision" ]] || exit 1
description=$(git_metadata describe --tags --long --match 'v[0-9]*' --exclude '*[!0-9v.]*' --exclude 'v2[0-9][0-9][0-9].*' "$revision")
[[ $description =~ ^v([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+)-g[0-9a-f]+$ ]] || {
    printf 'Cannot establish Hermes stable release provenance: %s\n' "$description" >&2
    exit 1
}
jq -n --arg revision "$revision" --arg version "${BASH_REMATCH[1]}" \
    --argjson distance "${BASH_REMATCH[2]}" \
    '{revision: $revision, version: $version, distance: $distance}' > "$work/version.json"
