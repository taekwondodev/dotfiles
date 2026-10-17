#!/usr/bin/env bash
# Read-only native mutation-boundary checks. Source admission.sh first.

dotfiles_admit_account() {
    local user=$1 home=$2 record
    record=$(dscl . -read "/Users/$user" NFSHomeDirectory) || return 1
    [[ "$record" == "NFSHomeDirectory: $home" ]] || {
        dotfiles_refuse "configured HOME differs from the macOS account: $user"; return 1;
    }
}

dotfiles_native_parents() {
    local path=$1
    while [[ "$path" != / ]]; do
        [[ ! -L "$path" && ( ! -e "$path" || -d "$path" ) ]] || {
            dotfiles_refuse "unsafe native parent: $path"; return 1;
        }
        path=$(dirname "$path")
    done
}

# An existing target must resolve to <generation><suffix> for an owned generation.
dotfiles_native_target() {
    local generations=$1 target=$2 suffix=$3 actual candidate
    dotfiles_native_parents "$(dirname "$target")" || return 1
    [[ -e "$target" || -L "$target" ]] || return 0
    if [[ -L "$target" && -e "$target" ]]; then
        actual=$(dotfiles_resolve "$target") || return 1
        while IFS= read -r candidate; do
            [[ -n "$candidate" && -e "$candidate$suffix" ]] || continue
            [[ "$actual" == "$(dotfiles_resolve "$candidate$suffix")" ]] && return 0
        done <<< "$generations"
    fi
    dotfiles_refuse "unowned or changed native target: $target"; return 1
}

# Succeeds when the prefix holds exactly the management links listed in links.
dotfiles_brew_links() {
    local prefix=$1 links=$2 relative expected target
    while IFS=$'\t' read -r relative expected; do
        target=$prefix/$relative
        [[ -L "$target" && -e "$target" && -e "$expected" ]] || return 1
        [[ $(dotfiles_resolve "$target") == "$(dotfiles_resolve "$expected")" ]] || return 1
    done < "$links"
}

# generations comes from dotfiles_generations.
dotfiles_admit_native() {
    local home=$1 user=$2 generations=$3 etc=$4 system_profile=$5 prefix=$6
    local target relative repo entry candidate owned=''
    dotfiles_native_target "$generations" "$etc/static" /etc || return 1
    dotfiles_native_target "$generations" "$etc/profiles/per-user/$user" "/etc/profiles/per-user/$user" || return 1
    dotfiles_native_target "$generations" "$system_profile" '' || return 1
    # These files can override the wrapper's immutable tap/API selection.
    for target in "$etc/homebrew/brew.env" "$home/.homebrew/brew.env" "$home/.config/homebrew/brew.env" "$prefix/etc/homebrew/brew.env"; do
        [[ ! -e "$target" && ! -L "$target" ]] || {
            dotfiles_refuse "unreviewed Homebrew environment overrides: $target"; return 1;
        }
    done
    dotfiles_native_parents "$prefix" || return 1
    if [[ ! -e "$prefix" ]]; then
        return 0
    fi
    [[ -n "$generations" && -f "$prefix/.managed_by_nix_darwin" && ! -L "$prefix/.managed_by_nix_darwin" ]] || {
        dotfiles_refuse "unowned Homebrew prefix: $prefix"; return 1;
    }
    while IFS= read -r candidate; do
        [[ -n "$candidate" && -f "$candidate/dotfiles/homebrew-links" ]] || continue
        while IFS=$'\t' read -r relative _; do
            dotfiles_native_parents "$(dirname "$prefix/$relative")" || return 1
        done < "$candidate/dotfiles/homebrew-links"
        if dotfiles_brew_links "$prefix" "$candidate/dotfiles/homebrew-links"; then owned=1; break; fi
    done <<< "$generations"
    [[ -n "$owned" ]] || { dotfiles_refuse "missing or changed native Homebrew links: $prefix"; return 1; }
    # nix-homebrew recreates this synthetic repository with rm -rf. Only its
    # known empty scaffold is admitted; never delete unrelated data inside it.
    repo=$prefix/Library/.homebrew-is-managed-by-nix
    dotfiles_native_parents "$repo/.git" || return 1
    [[ -f "$repo/.git/HEAD" && ! -L "$repo/.git/HEAD" && ! -s "$repo/.git/HEAD" ]] || {
        dotfiles_refuse "changed synthetic Homebrew repository: $repo"; return 1;
    }
    entry=$(find "$repo" -mindepth 1 ! -path "$repo/.git" ! -path "$repo/.git/HEAD" -print -quit) || return 1
    [[ -z "$entry" ]] || { dotfiles_refuse "unowned data in synthetic Homebrew repository: $entry"; return 1; }
}
