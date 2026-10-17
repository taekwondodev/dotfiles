if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

# True color
set -gx COLORTERM truecolor
set -gx TERM xterm-256color

# User-built tools remain available without shadowing Nix-owned executables.
fish_add_path --append ~/.cargo/bin ~/go/bin

# Working Directory
if status is-interactive && test -d ~/Developer
    cd ~/Developer
end

# Python Virtual Environment Auto Activate
function __auto_venv --on-variable PWD
    set -l activated 0
    for venv_dir in .venv venv venv311
        if test -e $venv_dir/bin/activate.fish
            source $venv_dir/bin/activate.fish
            set activated 1
            break
        end
    end
    if test $activated -eq 0 && set -q VIRTUAL_ENV
        deactivate
    end
end

# Divider after command output
function fish_postexec --on-event fish_postexec
    set_color '#394260'
    string repeat -n (tput cols) ─
    set_color normal
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

if type -q claude
    set -gx CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND (command -s claude)
end
