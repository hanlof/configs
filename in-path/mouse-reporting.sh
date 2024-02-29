#!/bin/bash

trap "{ echo -e '\e[?1000l' ; }" EXIT
echo -ne "\e[?1000h"

COMMANDS="""\
ls -l
echo hej
DDDDDDD
xxxxxxxxxxxxxxxxxxxx
EEEE
CCC\
"""

get_cursor() {
	echo -ne '\e[6n'
	read -s -n 99 -t 0.01 POS
	# aoeuntheaou45;3
	[[ "$POS" =~ ([[:digit:]]+)\;([[:digit:]]+) ]] && {
		CURSOR_Y="${BASH_REMATCH[1]}"
		CURSOR_X="${BASH_REMATCH[2]}"
		#echo Cursor pos $CURSOR_X $CURSOR_Y
	}
	read -s -n 99 -t 0.01 _
}

declare -ga LINES_ARRAY

draw_menu() {
	CNT=0
	LINE_ARRAY=()
	while read LINE; do
		if [ $CNT -ne 0 ]; then echo; fi
		LINES_ARRAY+=("$LINE")
		let CNT+=1
		echo -n $CNT "$LINE"
	done <<< "${COMMANDS}"
	get_cursor
	STARTING_LINE=$((CURSOR_Y - CNT))
}

draw_menu

while true; do

        read -s -n 1 _KEY
        if [ "$_KEY" != $'\e' ]; then
		case "$_KEY" in
			q) break ;;
		esac
	fi

        read -s -t 0.01 -n 1 _KEY
        if [ "$_KEY" != $'[' ]; then continue; fi

        read -s -n 1 _KEY
        if [ "$_KEY" != $'M' ]; then continue; fi

	WHAT=""
	while read -s -n 1 -t 0.01 _X; do
		WHAT+="$_X"
	done

	if [ ${#WHAT} == "2" ]; then
		PRESS=1
		printf -v X %d \'${WHAT:0:1}\'
		printf -v Y %d \'${WHAT:1:1}\'
	else
		PRESS=0
		printf -v X %d \'${WHAT:1:1}\'
		printf -v Y %d \'${WHAT:2:1}\'
	fi
	let X-=33
	let Y-=33
	LINE_INDEX=$((Y-STARTING_LINE))
	if [ $PRESS -eq 1 -a $LINE_INDEX -ge 0 -a $LINE_INDEX -le $CNT ]; then
		echo -e '\n>>>' "${LINES_ARRAY[$LINE_INDEX]}"
		eval "${LINES_ARRAY[$LINE_INDEX]}"
		draw_menu
	fi
done

