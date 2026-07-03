#!/usr/bin/env bash

DIR="${DIR:-}"
SESSION_KEY="${SESSION_KEY:-}"
SHELL_CMD="${SHELL_CMD:-}"
OPTS="${OPTS:-}"

get_session_name() {
    local base_name scratch_key

    base_name="${SESSION_NAME:-scratch}"
    if [ -z "$SESSION_KEY" ]; then
        printf '%s\n' "$base_name"
        return
    fi

    scratch_key="$(printf '%s' "$SESSION_KEY" | tr -cs '[:alnum:]_.-' '-')"
    scratch_key="${scratch_key#-}"
    scratch_key="${scratch_key%-}"

    if [ -z "$scratch_key" ]; then
        printf '%s\n' "$base_name"
        return
    fi

    printf '%s-%s\n' "$base_name" "$scratch_key"
}

is_current_scratch_session() {
    local base_name current_session

    base_name="${SESSION_NAME:-scratch}"
    current_session="$(tmux display-message -p -F "#{session_name}")"

    [ "$current_session" = "$base_name" ] || [[ "$current_session" == "$base_name"-* ]]
}

SESSION_NAME="$(get_session_name)"

if is_current_scratch_session; then
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
