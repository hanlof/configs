#!/bin/bash

_query_xterm_debug() {
	# 19 = height, width in characters
	echo -n $'\e['${1}t
	# -t    -- timeout (seconds)
	# -s    -- silent
	# -d t  -- read until 't' is received
	IFS=";" read -t 0.1 -d t a b c d e f
	if [ $? -gt 128 ]; then
		echo empty reply
	else
		echo
	fi
	#echo "$a $b $c $d $e $f"
}

_get_workarea() {
	cd_prop=($(xprop -notype -root _NET_CURRENT_DESKTOP))
	desktop_number=${cd_prop[2]}
	IFS=", " wa_prop=($(xprop -notype -root _NET_WORKAREA))
	let ofs=2+desptop_number*4
	let x=wa_prop[ofs+0]
	let y=wa_prop[ofs+1]
	let w=wa_prop[ofs+2]
	let h=wa_prop[ofs+3]
	declare -g x y w h
}

# TODO: replace wl, wr commands with awesome generic window manipulation function
#       Example: window_manip 2/1 3/2 to partition the screen in 2 equal parts for X
#                and 3 equal parts for y, and use first slot for x and second slot for y
wl() {
	_get_workarea
	echo $x $y $w $h
	let neww=w/2
	echo $newx $y $neww $h
	# set new pos
	echo -ne "\e[4;${h};${neww}t"
	# set new size
	echo -ne "\e[3;${x};${y}t"
}

wr() {
	_get_workarea
	echo $x $y $w $h
	let neww=w/2
	let newx=x+w/2
	echo $newx $y $neww $h
	# set new pos
	echo -ne "\e[4;${h};${neww}t"
	# set new size
	echo -ne "\e[3;${newx};${y}t"
}
