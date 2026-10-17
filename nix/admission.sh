# shellcheck shell=bash
# Shared by the native bootstrap and the Nix-owned activation runner.
# No command in this file mutates the target or invokes a package manager.

dotfiles_refuse() { printf 'bootstrap: refusing %s\n' "$*" >&2; return 1; }

dotfiles_resolve() {
    local path=$1 target hops=0
    while [[ -L "$path" ]]; do
        ((hops += 1))
        [[ $hops -le 40 ]] || return 1
        target=$(readlink "$path") || return 1
        if [[ $target = /* ]]; then path=$target
        else path=$(dirname "$path")/$target; fi
    done
    [[ -e "$path" ]] || return 1
    (cd -P -- "$(dirname "$path")" && printf '%s/%s\n' "$PWD" "$(basename "$path")")
}

dotfiles_plain_parents() {
    local home=$1 path=$2
    while [[ "$path" != "$home" ]]; do
        [[ "$path" = "$home/"* ]] || { dotfiles_refuse "destination outside home: $path"; return 1; }
        [[ ! -L "$path" ]] || { dotfiles_refuse "symlinked destination parent: $path"; return 1; }
        path=$(dirname "$path")
    done
    [[ ! -L "$home" ]] || { dotfiles_refuse "symlinked home: $home"; return 1; }
}

# Prints the distinct native generations behind the given links, one per line;
# absent links are skipped. Activation records its generation in the system
# profile once admission passes, so an interrupted activation stays owned.
# Callers pass the active system and the profile, plus the profile history
# (system-*-link) where ownership is proven by exact store paths: Home Manager
# and native links. Casks prove ownership by declaration and receipt only, so
# they use the active system and the profile alone; an older generation never
# vouches for a cask that was dropped and later installed by hand.
# Any link that is not an immutable generation of this home refuses.
dotfiles_generations() {
    local home=$1 store=$2 link native
    local -a found=()
    shift 2
    for link in "$@"; do
        [[ -e "$link" || -L "$link" ]] || continue
        store=$(cd -P -- "$store" && pwd) || return 1
        native=$(dotfiles_resolve "$link") || { dotfiles_refuse "unresolvable native generation: $link"; return 1; }
        [[ "$native" = "$store/"* && -f "$native/dotfiles/identity" ]] || {
            dotfiles_refuse "native generation not owned by this setup: $link"; return 1;
        }
        [[ $(<"$native/dotfiles/identity") = "taekwondodev/dotfiles:$home" ]] || {
            dotfiles_refuse "native generation identity mismatch: $link"; return 1;
        }
        found+=("$native")
    done
    [[ ${#found[@]} -eq 0 ]] || printf '%s\n' "${found[@]}" | sort -u
}

# Succeeds when one owned generation's dotfiles/<file> satisfies the jq test.
dotfiles_generation_declares() {
    local generations=$1 file=$2 candidate
    shift 2
    while IFS= read -r candidate; do
        [[ -n "$candidate" && -f "$candidate/dotfiles/$file" ]] || continue
        jq -e "$@" "$candidate/dotfiles/$file" >/dev/null && return 0
    done <<< "$generations"
    return 1
}

# roots is a conservative pre-install boundary, not a second package catalog.
# destinations is the new native generation's complete link/seed manifest, when
# available. generations comes from dotfiles_generations. A managed rerun is
# admitted using the generation whose Home Manager output is installed, never a
# mutable marker copied into the home.
dotfiles_admit() {
    local home=$1 generations=$2 store=$3 roots=$4 destinations=${5:-}
    local native='' manager='' gcroot='' active='' expected='' kind relative path old_kind root candidate
    [[ "$home" = /* && -d "$home" ]] || { dotfiles_refuse 'invalid home'; return 1; }
    dotfiles_plain_parents "$home" "$home" || return 1

    # Current integrated Home Manager uses driver v1: the active GC root, not
    # the optional legacy nix-env profile, identifies the installed home. With
    # no GC root, Home Manager never activated and the home is treated as fresh.
    gcroot=$home/.local/state/home-manager/gcroots/current-home
    if [[ -e "$gcroot" || -L "$gcroot" ]]; then
        store=$(cd -P -- "$store" && pwd) || return 1
        if [[ -L "$gcroot" ]]; then active=$(dotfiles_resolve "$gcroot") || active=''; fi
        while IFS= read -r candidate; do
            [[ -n "$candidate" && -n "$active" ]] || continue
            manager=$(dotfiles_resolve "$candidate/dotfiles/home-manager") || continue
            if [[ "$manager" == "$active" ]]; then native=$candidate; break; fi
        done <<< "$generations"
        [[ -n "$native" ]] || {
            dotfiles_refuse 'Home Manager generation differs from the native generations'; return 1;
        }
        [[ "$manager" = "$store/"* && -d "$manager/home-files" ]] || {
            dotfiles_refuse 'invalid native Home Manager reference'; return 1;
        }
        [[ -f "$native/dotfiles/destinations" ]] || { dotfiles_refuse 'missing native destination inventory'; return 1; }
    fi

    while IFS= read -r root || [[ -n "$root" ]]; do
        [[ -n "$root" && "$root" != \#* ]] || continue
        path=$home/$root
        dotfiles_plain_parents "$home" "$(dirname "$path")" || return 1
        if [[ -z "$native" && ( -e "$path" || -L "$path" ) ]]; then
            dotfiles_refuse "unmanaged destination: $path (no takeover or backup)"; return 1
        fi
    done < "$roots"

    # Check all old targets even if a later configuration removes a declaration.
    # Home Manager must not unlink a path which has since changed ownership.
    if [[ -n "$native" ]]; then
        while IFS=$'\t' read -r kind relative; do
            path=$home/$relative
            dotfiles_plain_parents "$home" "$(dirname "$path")" || return 1
            if [[ "$kind" = link ]]; then
                expected=$manager/home-files/$relative
                [[ -L "$path" && -e "$path" && -e "$expected" && $(dotfiles_resolve "$path") = "$(dotfiles_resolve "$expected")" ]] || {
                    dotfiles_refuse "changed managed link: $path"; return 1;
                }
            elif [[ "$kind" = seed ]]; then
                [[ ! -L "$path" && ( ! -e "$path" || -f "$path" ) ]] || {
                    dotfiles_refuse "changed writable seed: $path"; return 1;
                }
            else dotfiles_refuse "unknown destination kind: $kind"; return 1; fi
        done < "$native/dotfiles/destinations"
    fi

    # The native font copier uses rsync --delete inside its own directory.
    # Prove that directory still equals the previous immutable font tree first;
    # never let that copier remove an unrelated font or follow a user symlink.
    if [[ -n "$manager" && -f "$manager/home-files/Library/Fonts/.home-manager-fonts-version" ]]; then
        local fonts_source fonts_target
        fonts_source=$(dotfiles_resolve "$(<"$manager/home-files/Library/Fonts/.home-manager-fonts-version")") || return 1
        fonts_target=$home/Library/Fonts/HomeManager
        dotfiles_plain_parents "$home" "$fonts_target" || return 1
        [[ "$fonts_source" = "$store/"* && -d "$fonts_target" ]] || { dotfiles_refuse 'unknown font tree'; return 1; }
        [[ -z $(find "$fonts_target" -type l -print -quit) ]] || { dotfiles_refuse 'symlink in managed font tree'; return 1; }
        /usr/bin/diff -qr "$fonts_source/share/fonts" "$fonts_target" >/dev/null || {
            dotfiles_refuse 'managed font tree contains changed or unrelated files'; return 1;
        }
    fi

    if [[ -n "$destinations" ]]; then
        while IFS=$'\t' read -r kind relative; do
            [[ "$relative" != /* && "$relative" != *'..'* && -n "$relative" ]] || {
                dotfiles_refuse 'invalid declared destination'; return 1;
            }
            path=$home/$relative
            dotfiles_plain_parents "$home" "$(dirname "$path")" || return 1
            old_kind=''
            if [[ -n "$native" ]]; then
                old_kind=$(awk -F '\t' -v target="$relative" '$2 == target { print $1 }' "$native/dotfiles/destinations")
            fi
            if [[ -n "$old_kind" ]]; then
                [[ "$old_kind" = "$kind" ]] || { dotfiles_refuse "ownership mode change: $path"; return 1; }
            elif [[ -e "$path" || -L "$path" ]]; then
                dotfiles_refuse "new destination is unmanaged: $path"; return 1
            fi
        done < "$destinations"
    fi
}
