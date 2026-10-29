if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

# True color
set -gx COLORTERM truecolor
set -gx TERM xterm-256color

# Explicit colors keep valid paths distinct from errors across terminal palettes.
set -g fish_color_param normal
set -g fish_color_valid_path 9ccfd8 --underline
set -g fish_color_error eb6f92

# Cargo
fish_add_path ~/.cargo/bin

# Go 
fish_add_path ~/go/bin

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

# Kill Java process after quit Android Studio
if type -q android-studio
    alias cleanup-as='pkill -u (whoami) java 2>/dev/null; and echo "✅ Processi Java terminati"'
end


# Rex greeting: Wall-E fastfetch in top-level panes large enough for the logo.
# The exported flag skips shells nested inside one, e.g. nvim's :terminal.
function fish_greeting
    set -q REX_SESSION; and not set -q __rex_greeted; or return
    test $COLUMNS -ge 80 -a $LINES -ge 20; or return
    type -q fastfetch; or return
    set -gx __rex_greeted 1
    fastfetch
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

# Added by Android Studio
set -gx ANDROID_HOME $HOME/Library/Android/sdk

set -gx CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND /Users/taekwondodev/.local/bin/claude
