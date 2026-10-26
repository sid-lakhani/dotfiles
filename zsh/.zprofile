# PATH
export PATH="$HOME/.local/bin:$PATH"

# Session selector on the first TTY only
if [ -z "$DISPLAY" ] &&
   [ -z "$WAYLAND_DISPLAY" ] &&
   [ "$XDG_VTNR" = "1" ] &&
   [ -z "$SESSION_SELECT_SKIP" ]; then
  exec ~/.local/bin/session-select
fi