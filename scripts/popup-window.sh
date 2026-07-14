#!/usr/bin/env bash

LOG_FILE="${TMUX_LOG_FILE:-${TMPDIR:-/tmp}/tmux-popup-window.log}"
POPUP_SESSION_NAME="${SESSION_NAME:-scratch}"
CURRENT_SESSION="${CURRENT_SESSION:-}"
DIR="${DIR:-}"
SHELL_CMD="${SHELL_CMD:-}"
OPTS=${OPTS:-}

log() {
  printf '%s [%s] %s\n' \
    "$(date '+%Y-%m-%dT%H:%M:%S%z')" \
    "$$" \
    "$*" >>"$LOG_FILE"
}

log "started session=$POPUP_SESSION_NAME current=${CURRENT_SESSION:-<empty>} dir=${DIR:-<empty>} shell_cmd=${SHELL_CMD:-<empty>}"

if [ "$CURRENT_SESSION" = "$POPUP_SESSION_NAME" ]; then
  tmux detach-client -s "$POPUP_SESSION_NAME"
  exit 0
fi

_OPTS=""

if [ -n "$DIR" ]; then
  _OPTS="$_OPTS -c $DIR"
fi

CMD="tmux attach -t ${POPUP_SESSION_NAME} ${_OPTS} ${SHELL_CMD} || tmux new -s ${POPUP_SESSION_NAME} ${_OPTS} ${SHELL_CMD}"

# Debug
# tmux display-message "$CMD"
# tmux run "echo '$CMD' | pbcopy"

# Run
tmux popup -E -h '90%' -w '95%' "$CMD"
