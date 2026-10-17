{ pkgs, portKillSource, brewCore, brewCask }:
pkgs.writeShellApplication {
  name = "dotfiles-bootstrap";
  runtimeInputs = [ pkgs.nix pkgs.jq pkgs.coreutils pkgs.python3 pkgs.nodejs_latest pkgs.cargo pkgs.rustc pkgs.curl pkgs.git ];
  text = ''
    repo="''${1:?repository path required}"
    cd -- "$repo"
    # Git flakes omit the ignored technical lock from their source snapshot.
    # Explicitly reuse the resolution created by this deliberate bootstrap.
    lockArgs=(--reference-lock-file "$repo/flake.lock" --no-update-lock-file)
    export NIX_CONFIG="experimental-features = nix-command flakes"
    export DOTFILES_USER DOTFILES_HOME DOTFILES_JAVA_SKIPS DOTFILES_NPM_SOURCE DOTFILES_PORT_KILL_LOCK DOTFILES_PI_SOURCE DOTFILES_HERMES_VERSION
    DOTFILES_HERMES_VERSION=""
    DOTFILES_PI_SOURCE=""
    DOTFILES_PORT_KILL_LOCK=""
    DOTFILES_JAVA_SKIPS='{}'
    export DOTFILES_BREW_POLICY=""
    DOTFILES_USER=$(id -un)
    DOTFILES_HOME=$HOME
    # shellcheck source=/dev/null
    source ${./admission.sh}
    # shellcheck source=/dev/null
    source ${./native-admission.sh}
    # shellcheck source=/dev/null
    source ${./cask-admission.sh}
    generations=$(dotfiles_generations "$HOME" ${builtins.storeDir} /run/current-system /nix/var/nix/profiles/system /nix/var/nix/profiles/system-*-link)
    dotfiles_admit "$HOME" "$generations" ${builtins.storeDir} ${./protected-roots}
    dotfiles_admit_account "$DOTFILES_USER" "$HOME"
    dotfiles_admit_native "$HOME" "$DOTFILES_USER" "$generations" /private/etc /nix/var/nix/profiles/system /opt/homebrew
    stage=$(mktemp -d)
    trap 'rm -rf -- "$stage"' EXIT
    trap 'printf "FAILED: bootstrap did not complete; no failure is reported as a manual skip.\n" >&2' ERR
    bash ${./resolve-port-kill-lock.sh} ${portKillSource} "$stage/port-kill"
    DOTFILES_PORT_KILL_LOCK=$stage/port-kill/Cargo.lock
    piVersion=$(nix eval --impure "''${lockArgs[@]}" --raw .#piRelease)
    bash ${./resolve-pi-release.sh} "$piVersion" "$stage/pi"
    DOTFILES_PI_SOURCE=$stage/pi
    hermesRevision=$(nix eval --impure "''${lockArgs[@]}" --raw .#hermesRevision)
    bash ${./resolve-hermes-version.sh} "$hermesRevision" "$stage/hermes"
    DOTFILES_HERMES_VERSION=$stage/hermes/version.json
    mkdir "$stage/npm"
    DOTFILES_NPM_SOURCE=$stage/npm
    nix eval --impure "''${lockArgs[@]}" --json .#npmRequests > "$stage/npm/package.json"
    # Resolve public metadata only. No lifecycle hooks, installation, user npmrc,
    # auth, or global cache is involved. Nix builds the resulting locked package.
    (cd "$stage/npm"; env -i HOME="$stage" PATH=${pkgs.lib.makeBinPath [ pkgs.nodejs_latest pkgs.coreutils ]} \
      npm install --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund \
        --cache "$stage/npm-cache" --userconfig "$stage/user.npmrc" --globalconfig "$stage/global.npmrc" \
        --registry https://registry.npmjs.org)
    nix eval --impure "''${lockArgs[@]}" --json .#caskRequests > "$stage/cask-requests.json"
    python3 ${./check-dependencies.py} --homebrew "$stage/cask-requests.json" \
      ${brewCore} ${brewCask} "$(/usr/bin/sw_vers -productVersion)" > "$stage/brew-policy.json"
    DOTFILES_BREW_POLICY=$stage/brew-policy.json
    nix eval --impure "''${lockArgs[@]}" --json .#inventoryStatus > "$stage/inventory.json"
    if [[ $(jq '.pending | length' "$stage/inventory.json") != 0 ]]; then
      printf 'Refusing incomplete inventory (not manual exceptions):\n' >&2
      jq -r '.pending[]' "$stage/inventory.json" >&2
      exit 1
    fi
    nix eval --impure "''${lockArgs[@]}" --json .#packageDerivations > "$stage/packages.json"
    derivations=()
    while IFS= read -r drv; do derivations+=("$drv"); done < <(jq -r '.[]' "$stage/packages.json")
    nix derivation show --recursive "''${derivations[@]}" > "$stage/derivations.json"
    DOTFILES_JAVA_SKIPS=$(python3 ${./check-dependencies.py} "$stage/packages.json" "$stage/derivations.json")
    nix eval --impure "''${lockArgs[@]}" --json .#inventoryStatus > "$stage/inventory.json"
    nix eval --impure "''${lockArgs[@]}" --raw .#admissionManifest > "$stage/destinations"
    dotfiles_admit "$HOME" "$generations" ${builtins.storeDir} ${./protected-roots} "$stage/destinations"
    nix eval --impure "''${lockArgs[@]}" --json .#caskDestinations > "$stage/casks.json"
    jq '.artifacts' "$stage/brew-policy.json" > "$stage/cask-artifacts.json"
    recorded=$(dotfiles_generations "$HOME" ${builtins.storeDir} /run/current-system /nix/var/nix/profiles/system)
    dotfiles_admit_casks "$recorded" /Applications /opt/homebrew "$stage/casks.json" "$stage/cask-artifacts.json"
    native=$(nix build --impure "''${lockArgs[@]}" --no-link --print-out-paths .#darwinConfigurations.fresh-mac.system)
    # Admission is against the actual built artifact, not an earlier plan.
    # Activation repeats it and records the generation only once it passes.
    generations=$(dotfiles_generations "$HOME" ${builtins.storeDir} /run/current-system /nix/var/nix/profiles/system /nix/var/nix/profiles/system-*-link)
    dotfiles_admit "$HOME" "$generations" ${builtins.storeDir} ${./protected-roots} "$native/dotfiles/destinations"
    dotfiles_admit_account "$DOTFILES_USER" "$HOME"
    dotfiles_admit_native "$HOME" "$DOTFILES_USER" "$generations" /private/etc /nix/var/nix/profiles/system /opt/homebrew
    recorded=$(dotfiles_generations "$HOME" ${builtins.storeDir} /run/current-system /nix/var/nix/profiles/system)
    dotfiles_admit_casks "$recorded" /Applications /opt/homebrew "$native/dotfiles/casks.json" "$native/dotfiles/cask-artifacts.json"
    /usr/bin/sudo "$native/sw/bin/darwin-rebuild" activate
    # Deliberate plugin refresh; lock/state are in writable XDG state/data.
    # `Lazy! sync` exits 0 even when a plugin fails; report failures as non-success.
    "$native/dotfiles/home-manager/home-path/bin/nvim" --headless "+lua require('lazy').sync({ wait = true, show = false })" \
      "+lua for _, p in pairs(require('lazy.core.config').spec.plugins) do if require('lazy.core.plugin').has_errors(p) or not p._.installed then vim.cmd.cquit(1) end end" +qa
    printf 'Installed/updated managed components:\n'
    jq -r '.packages[], .casks[]' "$stage/inventory.json"
    printf '\nMANUAL ACTION REQUIRED (not performed by bootstrap):\n'
    jq -r '.manual | to_entries[] | "  - \(.key): \(.value)"' "$stage/inventory.json"
  '';
}
