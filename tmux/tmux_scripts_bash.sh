#!/tool/pandora64/bin/bash -f
# Function to simplify using tmux

unset -f _tmux_kill-window-others
function _tmux_kill-window-others(){
  while tmux next-window 2> /dev/null; do
    tmux kill-window
  done
}
