#!/usr/bin/env bash

last_session="$(tmux display-message -p "#{client_last_session}")"

if [[ -n "$last_session" ]]; then
	tmux switch-client -l
fi
