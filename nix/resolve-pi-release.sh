#!/bin/bash
set -euo pipefail
version=${1:?Pi version required}
work=${2:?fresh metadata directory required}
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]] || {
    printf 'Invalid upstream Pi release version\n' >&2
    exit 1
}
mkdir "$work"
# Fetch publisher-owned metadata only. Never run the Pi installer or npm here.
for name in package.json package-lock.json; do
    curl --disable --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
        "https://pi.dev/api/installer/releases/$version/$name" -o "$work/$name"
done
# Some Pi-owned tarballs have no integrity in the publisher lock. Obtain their
# exact published hashes separately, without changing any lock bytes/versions.
printf '{}\n' > "$work/source-integrity.json"
jq -r '.packages | to_entries[] | select(.value.resolved != null and .value.integrity == null) |
    [.key, (.key | split("node_modules/") | last), .value.version, .value.resolved] | @tsv' \
    "$work/package-lock.json" > "$work/missing-integrity"
while IFS=$'\t' read -r module name dependency_version url; do
    [[ $name =~ ^(@[a-zA-Z0-9_-]+/)?[a-zA-Z0-9][a-zA-Z0-9_.-]*$ && $dependency_version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]] || exit 1
    curl --disable --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
        "https://registry.npmjs.org/$name/$dependency_version" -o "$work/registry.json"
    integrity=$(jq -er --arg version "$dependency_version" --arg url "$url" \
        'select(.version == $version and .dist.tarball == $url) | .dist.integrity | strings | select(startswith("sha512-"))' "$work/registry.json")
    jq --arg module "$module" --arg integrity "$integrity" '. + {($module): $integrity}' \
        "$work/source-integrity.json" > "$work/source-integrity.next"
    mv "$work/source-integrity.next" "$work/source-integrity.json"
done < "$work/missing-integrity"
rm -f "$work/missing-integrity" "$work/registry.json"
