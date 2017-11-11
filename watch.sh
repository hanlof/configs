#!/bin/bash

TERM_SPACING=332

sigchld_handler()
{
	echo sigchld
}

sigintr_handler()
{
	echo sigint
}

launch_xterms_and_listener()
{
	t=$(mktemp -d /tmp/hansXXXXXXXXX)

	astyle_fifo=$t/astyle
	build_fifo=$t/build
	mkfifo ${astyle_fifo}
	mkfifo ${build_fifo}
	#astyle_fifo=$(mkfifo $t/astyle)
	#astyle_fifo=$(mkfifo $t/astyle)
	#astyle_fifo=$(mkfifo $t/astyle)
	#astyle_fifo=$(mkfifo $t/astyle)

	trap sigchld_handler SIGCHLD
	trap sigintr_handler SIGINT

	exec 3<> ${astyle_fifo} 4<> $build_fifo
	xterm -geometry 65x150+$(($TERM_SPACING * 0))+0 -font -*-*-*-*-*-*-7-*-*-*-*-*-*-* -e "$0 listen $astyle_fifo" &
	xterm -geometry 65x150+$(($TERM_SPACING * 1))+0 -font -*-*-*-*-*-*-7-*-*-*-*-*-*-* -e "$0 listen $build_fifo" &

	inotifywait -m -r -e modify -e close_write modules/ --exclude '.*.sw.$' | while read eventstring; do
		# Time to start jobs in slave terminals
		# We are not interested in additional buffered events so flush stdin bedore continuing
		while read -t 0.1 slask; do echo -n .; done; echo
		echo $eventstring
		echo ./run.py astyle >&3
		echo ./run.py build >&4
	done
	trap - SIGCHLD
	rm -v ${astyle_fifo}
	rm -v ${build_fifo}
	rmdir -v ${t}
	for i in `jobs -p`; do
		kill -9 $i
	done
}

listen_on_fifo()
{
	exec 3<> ${1}
	while true; do
		read -u 3 command
		# Received command to launch. This is a good point at which to clear buffered input.
		# If we recieve more commands
		while read -t 0.1 -u 3 slask; do echo -n .; done; echo
		${command}
	done
}


if [ "$1" == "launch" ]; then
	launch_xterms_and_listener
elif [ "$1" == "listen" -a -n "$2" ]; then
	listen_on_fifo $2
else
	echo use \"$0 launch\" to start activities...
fi
