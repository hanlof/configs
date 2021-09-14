#!/bin/bash

xprop -root _NET_CLIENT_LIST | {
	read -d \#
	IFS=" ,"; read WINDOWS
	for W in ${WINDOWS}; do
		PID=$(xprop -id $W _NET_WM_PID | cut -d " " -f 3 2> /dev/null) && {
			echo $PID $PPID
#			cat /proc/${K}/task/${K}/children
#			echo 
		}
	done
}
