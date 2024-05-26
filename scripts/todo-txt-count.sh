#!/usr/bin/env bash

todo_count="0"

if which todo.sh >/dev/null; then
	todo_count=$(todo.sh list | grep -v '^x ' | grep -c '^[0-9]\+ ')
else
	todo_count="0"
fi

if [[ $todo_count != "0" ]]; then
	echo "$todo_count Outstanding task"
else
	echo "No task, yay!"
fi
