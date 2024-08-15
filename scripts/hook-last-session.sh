#!/usr/bin/env bash

tmp_filename="$(echo "$TMUX" | cut -d',' -f1 | sed -E 's|/|-|g')"
# tmp_path="$TMPDIR/$tmp_filename"
tmp_path="/tmp/$tmp_filename"

if [[ "$1" == "save" ]]; then
	last_session="$(tmux display-message -p "#{client_last_session}")"

	if [[ -n "$last_session" ]]; then
		echo "$last_session" >"$tmp_path"
	fi

	exit 0
fi

last_session="$(cat "$tmp_path")"

if [[ -n "$last_session" ]]; then
	tmux switch-client -t "$last_session"
fi
