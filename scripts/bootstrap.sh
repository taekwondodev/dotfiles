#!/bin/bash
set -euo pipefail
fail() { printf 'bootstrap: %s\n' "$*" >&2; exit 1; }
[[ $# -eq 0 ]] || fail 'profiles are not supported; run without arguments'
[[ $(uname -s) = Darwin && $(uname -m) = arm64 ]] || fail 'only Apple Silicon macOS is supported'
[[ $(id -u) -ne 0 ]] || fail 'run as the intended user, not root'
repo=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/admission.sh
source "$repo/nix/admission.sh"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../nix/native-admission.sh
source "$repo/nix/native-admission.sh"
generations=$(dotfiles_generations "$HOME" /nix/store /run/current-system /nix/var/nix/profiles/system /nix/var/nix/profiles/system-*-link)
dotfiles_admit "$HOME" "$generations" /nix/store "$repo/nix/protected-roots"
dotfiles_admit_account "$(id -un)" "$HOME"
dotfiles_admit_native "$HOME" "$(id -un)" "$generations" /private/etc /nix/var/nix/profiles/system /opt/homebrew

nix=/nix/var/nix/profiles/default/bin/nix
if [[ ! -x "$nix" ]]; then
    installer=$(mktemp)
    trap 'rm -f "$installer"' EXIT
    curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install -o "$installer"
    sh "$installer" --daemon
    rm -f "$installer"
    trap - EXIT
fi
[[ -x "$nix" ]] || fail 'Nix installer returned without installing Nix'
export DOTFILES_USER
DOTFILES_USER=$(id -un)
# Refresh through Nix itself. The resulting local lock is an ignored technical
# resolution shared by this runner and its build, not a committed personal pin.
# Relative flake references avoid URL-encoding bugs for checkout paths with spaces.
cd "$repo"
exec "$nix" --extra-experimental-features 'nix-command flakes' run \
    --impure --refresh --recreate-lock-file .#bootstrap -- "$repo"
