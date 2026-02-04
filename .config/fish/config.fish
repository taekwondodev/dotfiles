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
if test "$TERM_PROGRAM" != "zed"
	cd ~/Desktop
end

# Python Virtual Environment Auto Activate
function __auto_venv --on-variable PWD
    if test -e .venv/bin/activate.fish
        source .venv/bin/activate.fish
    else if set -q VIRTUAL_ENV
        deactivate
    end
end

alias cleanup-as='pkill -u (whoami) java 2>/dev/null; and echo "✅ Processi Java terminati"'
