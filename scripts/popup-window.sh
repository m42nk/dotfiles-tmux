#!/usr/bin/env bash

DIR="${DIR:-}"
WINDOW_NAME="${WINDOW_NAME:-}"
SHELL_CMD="${SHELL_CMD:-}"
OPTS="${OPTS:-}"

get_session_name() {
    local base_name window_key

    base_name="${SESSION_NAME:-scratch}"
    if [ -z "$WINDOW_NAME" ]; then
        printf '%s\n' "$base_name"
        return
    fi

    window_key="$(printf '%s' "$WINDOW_NAME" | tr -cs '[:alnum:]_.-' '-')"
    window_key="${window_key#-}"
    window_key="${window_key%-}"

    if [ -z "$window_key" ]; then
        printf '%s\n' "$base_name"
        return
    fi

    printf '%s-%s\n' "$base_name" "$window_key"
}

SESSION_NAME="$(get_session_name)"

if [ "$(tmux display-message -p -F "#{session_name}")" = "$SESSION_NAME" ];then
    tmux detach-client
    exit 0
fi

tmux_cmd=(tmux)
new_cmd=(tmux)

if [ -n "$OPTS" ]; then
    # Preserve existing behavior for caller-provided raw tmux flags.
    # shellcheck disable=SC2206
    extra_opts=($OPTS)
    tmux_cmd+=("${extra_opts[@]}")
    new_cmd+=("${extra_opts[@]}")
fi

has_session_cmd=("${tmux_cmd[@]}" has-session -t "${SESSION_NAME}")
create_session_cmd=("${new_cmd[@]}" new-session -d -s "${SESSION_NAME}")
if [ -n "$DIR" ]; then
    create_session_cmd+=(-c "$DIR")
fi
if [ -n "$SHELL_CMD" ]; then
    create_session_cmd+=("$SHELL_CMD")
fi
set_option_cmd=("${tmux_cmd[@]}" set-option -t "${SESSION_NAME}" detach-on-destroy on)
attach_cmd=("${tmux_cmd[@]}" attach -t "${SESSION_NAME}")

# Debug
# tmux display-message "$(printf '%q ' "${has_session_cmd[@]}") || $(printf '%q ' "${create_session_cmd[@]}") ; $(printf '%q ' "${set_option_cmd[@]}") ; exec $(printf '%q ' "${attach_cmd[@]}")"

# Run
tmux popup -E -h '90%' -w '95%' "$(printf '%q ' "${has_session_cmd[@]}") >/dev/null 2>&1 || $(printf '%q ' "${create_session_cmd[@]}"); $(printf '%q ' "${set_option_cmd[@]}"); exec $(printf '%q ' "${attach_cmd[@]}")"
