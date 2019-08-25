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
# TODO: put in in-path/ ?
res() {
	_get_workarea
	echo -n $'\e['18t
	IFS=";" read -t 0.1 -d t -s _ h w _
	mode=SIZE
	while true; do
		case $mode in
			SIZE) let _x=w; let _y=h ;;
			POS) let _x=x; let _y=y ;;
		esac
		echo -n $'\x0d\e[2K'$mode $_x, $_y
		read -n 1 -s i
		case $i in
			j) let _y+=1;;
			J) let _y+=5;;
			k) let _y-=1;;
			K) let _y-=5;;
			l) let _x+=1;;
			L) let _x+=5;;
			h) let _x-=1;;
			H) let _x-=5;;
			o|O) case $mode in POS) mode=SIZE;; SIZE) mode=POS ;; esac; continue ;;
			x|X|q|Q) break;;
		esac
		case $mode in
			SIZE) let h=_y w=_x; echo -ne "\e[8;${h};${w}t" ;;
			POS) let x=_x y=_y; echo -ne "\e[3;${x};${y}t"
		esac
	done
	echo " Bye!"
}

wl() {
	_get_workarea
	echo $x $y $w $h
	let neww=w/2
	echo $newx $y $neww $h
	# set new size
	echo -ne "\e[4;${h};${neww}t"
	# set new pos
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
