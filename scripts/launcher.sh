#!/usr/bin/env bash

###
# Launch a tmux session, window, or pane with a predefined starting directory that picked using a fzf (fuzzy finder)
# This give you the ability to separate projects (directory/repo) as tmux session (that you can jump back and forth to)
# but still give the ability to open them in the panes or windows of current session.
# Demo: https://asciinema.org/a/oxcdmOdhXJom1eB2plpfvmPVL
#
# Usage:
# $ ./launcher.sh
# Fuzzy find directory and session
#
# $ ./launcher.sh -initial-dir /some/path
# Fuzzy find child dirs of /some/path
#
# $ ./launcher.sh -mode <pane|window|session>
# Fuzzy find directory and session and start either pane, window, or session starting from selected entry
#
# -mode and -initial-dir can be combined
#
# Usage in config (tmux.conf):
# bind n display-popup -E -h '80%' -w '80%' "path/to/launcher.sh"
#
# Usage in scripts/shell:
# $ alias ts='~/.config/tmux/scripts/launcher.sh -mode session'
# $ ts
#
# Requirements:
# - tmux (v 3.4)
# - fzf (v 0.54.3)
###

INITIAL_DIR=""
MODE=""

# These directories will be listed as is
LITERAL_DIRS=(
	"$HOME/Work"
	"$HOME/Codes"
	"$HOME/.config"
	"$HOME/.local/share/nvim/lazy/LazyVim"
	"$HOME/GoVault"
	"$HOME/GoVault/00 Scratch"
	"$HOME/Dotfiles"
)

# Direct child (one level deep) of this directories will be listed
CHILD_DIRS=(
	"$HOME/.config"
	"$HOME/Codes"
	"$HOME/Dotfiles"
	"$HOME/Work"
)

### Home path utils {{{

# Replaces '/home/username' to '~'
shrinkHome() {
	sed -E "s#^$HOME#~#"
}

# Replaces '~' to '/home/username'
expandHome() {
	sed -E "s#^~#$HOME#"
}
# }}}

### Dirs utils {{{

# If tmux is running, show it's pane start path
# else, show current dir
getCurrentDir() {
	# Skip if INITIAL_DIR is passed
	if [[ -n $INITIAL_DIR ]]; then
		return
	fi

	if [[ -n $TMUX ]]; then
		tmux display-message -p "#{pane_start_path}"
	else
		pwd
	fi

	printf "\n"
}

getLiteralDirs() {
	# Skip if array is empty
	if [[ ${#LITERAL_DIRS} -lt 1 ]]; then
		return
	fi

	# Use `printf` to print the array
	printf "%s\n" "${LITERAL_DIRS[@]}"

	printf "\n"
}

getChildDirs() {
	# Use `fd` to list down child dirs
	fd \
		--type=directory \
		--type=symlink \
		--max-depth=1 \
		--color=never \
		. "${CHILD_DIRS[@]}"
}
# }}}

### Tmux utils {{{
isTmuxRunning() {
	[[ -n $(pgrep tmux) ]] && return 0 || return 1
}

# Get all existing tmux sessions
# A sessions will be marked with '>>' at the start of the line
getSessions() {
	# skip if tmux is not running
	if ! isTmuxRunning; then
		return
	fi

	# skip if initial dir exists
	if [[ -n $INITIAL_DIR ]]; then
		return
	fi

	_currSessName=$(tmux display -p '#{session_name}')
	tmux list-session -F '#{session_name}|#{session_path}' |
		while read -r row; do
			_sessName=$(echo "$row" | cut -d '|' -f 1)
			_sessPath=$(echo "$row" | cut -d '|' -f 2 | shrinkHome)

			_colorBlack=$(git config --get-color "" "black")
			_colorBlue=$(git config --get-color "" "blue bold")
			_colorDefault=$(git config --get-color "" "white")
			_colorReset='\033[0m'

			if [[ "$_sessName" = "$_currSessName" ]]; then
				echo -ne "${_colorBlue}"
			fi

			# Format: >> <session_path> :: <session_name>
			echo -ne ">> "
			echo -ne "${_colorDefault}"
			echo -ne "${_sessPath}"
			echo -ne "${_colorBlack}"
			echo -ne "::"
			echo -ne "${_colorDefault}"
			echo -ne "${_sessName}"
			echo -ne "${_colorReset}"

			echo ""
		done

	printf "\n"
}

# Split the entry string and get the 2nd section
getSessionNameFromEntry() {
	echo -n "$1" | awk -F "::" '{print $2}'
}

# Check if an entry is a tmux session
isSessionEntry() {
	if [[ $1 =~ ^\>\>.* ]]; then
		return 0
	else
		return 1
	fi
}

isSessionExists() {
	if tmux has-session -t "$1" 2>/dev/null; then
		return 0
	fi

	return 1
}

sessionSwitch() {
	_targetName=$1

	tmux switch-client -t "$_targetName"
}

sessionAttach() {
	_targetName=$1

	tmux attach-session -t "$_targetName"
}

sessionCreate() {
	_targetDir="$1"
	_targetName="$2"

	tmux new-session -s "$_targetName" -c "$_targetDir"
}

sessionCreateDetached() {
	_targetDir="$1"
	_targetName="$2"

	tmux new-session -ds "$_targetName" -c "$_targetDir"
}

paneCreate() {
	_targetPaneDir="$1"
	tmux split-window -h -c "$_targetPaneDir"
}

windowCreate() {
	_targeWindowDir="$1"
	tmux new-window -c "$_targeWindowDir"
}

# }}}

### Main utils {{{

fuzzyFind() {
	# Get header
	_header="Select an entry; '>>' is an existing session to switch, other is a directory"
	if [[ -n $INITIAL_DIR ]]; then
		_header="Selecting from $INITIAL_DIR (ctrl-h to go back)"
	fi

	# use ctrl-l to go into highlighted directory
	# use ctrl-h to go back to parent directory
	fzf \
		--ansi \
		--header="$_header" \
		--bind="ctrl-l:become($0 -initial-dir {})" \
		--bind="ctrl-h:become($0)" \
		--bind="ctrl-s:change-query(>>)"
}

getMode() {
	# Return preselected mode if exists
	if [[ -n $MODE ]]; then
		echo "$MODE"
		return
	fi

	# Select mode using fzf
	modeOrder=(
		"pane"
		"window"
		"session"
	)
	_selected=$(
		echo -e "${modeOrder[@]}" |
			tr ' ' '\n' |
			fzf --multi --bind 'result:jump,jump:accept' --jump-labels="pws"
	)

	if [[ -z $_selected ]]; then
		echo "Mode is required"
	fi

	echo "$_selected"
}

# Entry list builder
getEntries() {
	(
		getSessions
		# getCurrentDir
		getLiteralDirs
		getChildDirs
	) | shrinkHome | uniq
}

# }}}

### Shell parse utils {{{

usage() {
	echo "Usage: $0 [-initial-dir <directory>] [-mode <pane|session|window>]"
	exit 1
}

parseOpts() {
	while [[ "$#" -gt 0 ]]; do
		case $1 in
		-initial-dir)
			if [[ -z $2 ]]; then
				echo "$1 required an argument"
				usage
			fi

			# Skip if initial dir is not a directory
			if ! stat "$(echo "$2" | expandHome)" >/dev/null 2>&1; then
				exec "$0"
				exit 0
			fi

			INITIAL_DIR="$2"
			shift 2
			;;
		-mode)
			if [[ -z $2 ]]; then
				echo "$1 required an argument"
				usage
			fi
			MODE="$2"
			shift 2
			;;
		*)
			echo "Unknown parameter passed: $1"
			usage
			;;
		esac
	done

	# Validate mode
	if [[ -n "$MODE" ]]; then
		if [[ "$MODE" != "pane" && "$MODE" != "window" && "$MODE" != "session" ]]; then
			echo "Invalid mode: $MODE. Allowed values are: pane, window, session."
			usage
		fi
	fi
}

# }}}

main() {
	# Parse the command line arguments
	parseOpts "$@"

	# If INITIAL_DIR is passed,
	# remove all predefined dirs and set initial dir to the selected one
	if [[ -n "$INITIAL_DIR" ]]; then
		_newDir=$(echo "$INITIAL_DIR" | expandHome)
		CHILD_DIRS=("$_newDir")
		LITERAL_DIRS=()
	fi

	# Select item, item can be: session entry or directory
	_selectedItem=$(getEntries | fuzzyFind)
	if [[ -z $_selectedItem ]]; then
		exit 1
	fi

	#####
	## If item is a session entry, switch to them
	#####
	if isSessionEntry "$_selectedItem"; then
		_targetName=$(getSessionNameFromEntry "$_selectedItem")

		if [[ -z $TMUX ]]; then
			sessionAttach "$_targetName"
			exit 0
		fi

		sessionSwitch "$_targetName"
		exit 0
	fi

	# Get target session name, basically get deepest dir in path (tail)
	_targetName=$(basename "$_selectedItem" | tr . _)
	_targetDir="$(echo "$_selectedItem" | expandHome)"

	#####
	## If tmux is not running,
	## create and attach to new session
	#####
	if ! isTmuxRunning; then
		sessionCreate "$_targetDir" "$_targetName"
		exit 0
	fi

	#####
	## If tmux is running, but current shell is outside tmux
	## attach to them
	#####
	if [[ -z $TMUX ]]; then
		if isSessionExists "$_targetName"; then
			sessionAttach "$_targetName"
			exit 0
		fi

		sessionCreate "$_targetDir" "$_targetName"
		exit 0
	fi

	#####
	## If tmux is running, and current shell is inside tmux,
	## switch to them, and choose mode
	#####

	_selectedMode=$(getMode)
	if [[ -z $_selectedMode ]]; then
		exit 1
	fi

	case "$_selectedMode" in
	pane)
		paneCreate "$_targetDir"
		exit 0
		;;
	window)
		windowCreate "$_targetDir"
		exit 0
		;;
	session)
		if isSessionExists "$_targetName"; then
			sessionSwitch "$_targetName"
			exit 0
		fi

		sessionCreateDetached "$_targetDir" "$_targetName"
		sessionSwitch "$_targetName"
		;;
	*)
		exit 1
		;;

	esac

}

main "$@"

# vim: foldmethod=marker:foldlevel=0
