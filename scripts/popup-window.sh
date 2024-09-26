#!/usr/bin/env bash

SESSION_NAME="${SESSION_NAME:-scratch}"
DIR="${DIR:-}"
SHELL_CMD="${SHELL_CMD:-}"
OPTS=${OPTS:-}

if [ "$(tmux display-message -p -F "#{session_name}")" = "$SESSION_NAME" ];then
    tmux detach-client
    exit 0
fi

_OPTS=""

if [ -n "$DIR" ]; then
    _OPTS="$_OPTS -c $DIR"
fi

CMD="tmux attach -t ${SESSION_NAME} ${_OPTS} ${SHELL_CMD} || tmux new -s ${SESSION_NAME} ${_OPTS} ${SHELL_CMD}"

# Debug
# tmux display-message "$CMD"
# tmux run "echo '$CMD' | pbcopy"

# Run
tmux popup -E -h '90%' -w '95%' "$CMD"
