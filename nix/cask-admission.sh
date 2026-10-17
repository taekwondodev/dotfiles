# shellcheck shell=bash
# Native Brew receipts establish package ownership only in conjunction with the
# previous generation's declared cask catalog. Presence alone never permits adoption.

# Inert form of Homebrew's Caskroom.cask_installed_caskfile: `brew list --cask`
# would load every installed cask, including unrelated ones.
dotfiles_cask_receipt() {
    local room=$1/Caskroom/$2 latest='' entry ext
    [[ -d "$room" && ! -L "$room" ]] || return 1
    for entry in "$room"/.metadata/*/*; do
        [[ -e "$entry" || -L "$entry" ]] || continue
        if [[ -z "$latest" || "${entry##*/}" > "${latest##*/}" ]]; then latest=$entry; fi
    done
    [[ -n "$latest" ]] || return 1
    for ext in json internal.json rb; do
        [[ -e "$latest/Casks/$2.$ext" ]] && return 0
    done
    return 1
}

# Cask#initialize reuses the stored .metadata/config.json; its appdir (explicit,
# then env, then stored default) decides where an upgrade removes the previous
# version from. The new version's appdir comes from the stored explicit value and
# the activation environment (sudo-reset; brew.env overrides are refused).
dotfiles_cask_config() {
    local applications=$1 config=$2/.metadata/config.json appdir
    dotfiles_native_parents "$2/.metadata" || return 1
    [[ -e "$config" || -L "$config" ]] || return 0
    [[ -f "$config" && ! -L "$config" ]] || { dotfiles_refuse "changed cask configuration: $config"; return 1; }
    appdir=$(jq -er '[.explicit.appdir, .env.appdir, .default.appdir, "/Applications"] | map(select(. != null)) | first | strings' "$config") || {
        dotfiles_refuse "unreadable cask configuration: $config"; return 1;
    }
    [[ "$appdir" == "$applications" ]] || {
        dotfiles_refuse "cask configuration redirects applications to $appdir: $config"; return 1;
    }
}

# generations comes from dotfiles_generations.
dotfiles_admit_casks() {
    local generations=$1 applications=$2 prefix=$3 desired=$4 artifacts=$5
    local name app path
    jq -e 'type == "object" and all(to_entries[]; (.key | type == "string") and (.value | type == "string"))' "$desired" >/dev/null || {
        dotfiles_refuse 'invalid cask inventory'; return 1;
    }
    [[ ! -L "$applications" ]] || { dotfiles_refuse "symlinked application directory: $applications"; return 1; }
    dotfiles_native_parents "$prefix/Caskroom" || return 1
    while IFS=$'\t' read -r name app; do
        [[ "$app" = *.app && "$app" != */* ]] || { dotfiles_refuse "invalid application declaration: $name"; return 1; }
        path=$applications/$app
        dotfiles_native_parents "$prefix/Caskroom/$name" || return 1
        [[ ! -L "$path" ]] || { dotfiles_refuse "symlinked application: $path"; return 1; }
        [[ ! -e "$path" || -d "$path" ]] || { dotfiles_refuse "changed application target: $path"; return 1; }
        if [[ -e "$path" || -e "$prefix/Caskroom/$name" ]]; then
            # shellcheck disable=SC2016 # jq variables, not shell expansions
            if ! dotfiles_generation_declares "$generations" casks.json --arg name "$name" --arg app "$app" '.[$name] == $app' ||
                ! dotfiles_cask_receipt "$prefix" "$name"; then
                dotfiles_refuse "unmanaged application/cask: $name ($path)"; return 1;
            fi
            dotfiles_cask_config "$applications" "$prefix/Caskroom/$name" || return 1
        fi
    done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$desired")
    jq -e --slurpfile desired "$desired" 'keys == ($desired[0] | keys)' "$artifacts" >/dev/null || {
        dotfiles_refuse 'incomplete cask artifact inventory'; return 1;
    }
    while IFS=$'\t' read -r name path; do
        dotfiles_native_parents "$(dirname "$path")" || return 1
        if [[ -e "$path" || -L "$path" ]]; then
            # shellcheck disable=SC2016 # jq variables, not shell expansions
            if [[ ! -L "$path" ]] || ! dotfiles_cask_receipt "$prefix" "$name" ||
                ! dotfiles_generation_declares "$generations" cask-artifacts.json --arg name "$name" --arg path "$path" \
                    --arg source "$(readlink "$path")" '.[$name][$path].source == $source'; then
                dotfiles_refuse "unmanaged cask link: $name ($path)"; return 1
            fi
        fi
    done < <(jq -r 'to_entries[] as $cask | $cask.value | to_entries[] | select(.value.kind == "link") | [$cask.key, .key] | @tsv' "$artifacts")
    # Standard Spotify is never a second installation next to SpotX-Nix.
    if [[ -e "$applications/Spotify.app" || -L "$applications/Spotify.app" || -e "$prefix/Caskroom/spotify" || -L "$prefix/Caskroom/spotify" ]]; then
        dotfiles_refuse 'existing standard Spotify installation (no removal performed)'; return 1
    fi
}
