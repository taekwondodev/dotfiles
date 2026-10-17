#!/bin/bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
mkdir "$fixture/source" "$fixture/bin"
printf '[package]\nname = "fixture"\nversion = "0.0.0"\n' > "$fixture/source/Cargo.toml"
cat > "$fixture/bin/cargo" <<'SH'
#!/bin/bash
set -euo pipefail
[[ $# == 3 && $1 == generate-lockfile && $2 == --manifest-path && -f $3 ]]
manifest_dir=$(dirname -- "$3")
[[ $PWD != "$manifest_dir" && $HOME == "$PWD/"* && $CARGO_HOME == "$PWD/"* ]]
[[ -z ${DOTFILES_TEST_SECRET+x} && -z ${CARGO_REGISTRIES_CRATES_IO_TOKEN+x} ]]
printf 'generated metadata fixture\n' > "$manifest_dir/Cargo.lock"
SH
chmod +x "$fixture/bin/cargo"
export PATH="$fixture/bin:$PATH"
export DOTFILES_TEST_SECRET=not-a-real-secret CARGO_REGISTRIES_CRATES_IO_TOKEN=not-a-real-token
bash "$repo/nix/resolve-port-kill-lock.sh" "$fixture/source" "$fixture/generated"
[[ $(< "$fixture/generated/Cargo.lock") == 'generated metadata fixture' ]]
[[ ! -e "$fixture/source/Cargo.lock" && ! -e "$fixture/generated/source/target" ]]

# A real resolver failure must propagate, not become a manual exception.
printf '#!/bin/sh\nexit 42\n' > "$fixture/bin/cargo"
status=0
bash "$repo/nix/resolve-port-kill-lock.sh" "$fixture/source" "$fixture/failed" || status=$?
[[ $status == 42 && ! -e "$fixture/failed/Cargo.lock" ]]

# Publisher lock bytes have priority, without executing the failing resolver.
printf 'publisher-owned metadata fixture\n' > "$fixture/source/Cargo.lock"
bash "$repo/nix/resolve-port-kill-lock.sh" "$fixture/source" "$fixture/preserved"
cmp "$fixture/source/Cargo.lock" "$fixture/preserved/Cargo.lock"
[[ ! -e "$fixture/preserved/source" ]]

# Reusing a work directory must fail without replacing its lock.
status=0
bash "$repo/nix/resolve-port-kill-lock.sh" "$fixture/source" "$fixture/preserved" 2>/dev/null || status=$?
[[ $status != 0 ]]
cmp "$fixture/source/Cargo.lock" "$fixture/preserved/Cargo.lock"
printf 'PASS: isolated metadata resolution, exact upstream lock, nonzero failures and occupied-work refusal\n'
