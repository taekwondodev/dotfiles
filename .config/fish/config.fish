if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

# True color
set -gx COLORTERM truecolor
set -gx TERM xterm-256color

# Working Directory

cd ~/Desktop
