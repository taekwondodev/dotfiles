if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

# True color
set -gx COLORTERM truecolor
set -gx TERM xterm-256color

# Cargo
fish_add_path ~/.cargo/bin

# Working Directory
if status is-interactive && test "$TERM_PROGRAM" != "zed"
	cd ~/Desktop
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
alias cleanup-as='pkill -u (whoami) java 2>/dev/null; and echo "✅ Processi Java terminati"'
# Claude Path
fish_add_path ~/.local/bin
# Claude Code alias
function cc
    claude $argv
end
# Claude Code md file template
alias ccinit='cp ~/.claude/templates/project-claude.md ./CLAUDE.md'

# Divider after command output
function fish_postexec --on-event fish_postexec
    set_color '#394260'
    string repeat -n (tput cols) ─
    set_color normal
end
