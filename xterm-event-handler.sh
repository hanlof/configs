#!/bin/bash

CONFIGS_PATH=$(dirname "$0")
date >> /tmp/xterm-event-handler-log
echo $0 $1 >> /tmp/xterm-event-handler-log

read child1 _ < /proc/${PPID}/task/${PPID}/children
OUTPUT=/proc/${child1}/fd/0
read childcmd _ < /proc/${child1}/comm

read _ _ _ parentpid _ < /proc/${PPID}/stat
read parentcmd _ < /proc/${parentpid}/comm
echo parent: $parentpid $parentcmd - child: ${childcmd} >> /tmp/xterm-event-handler-log

test "$parentcmd" = "tabbed" && exit

case $1 in
    Map)
        exec > ${OUTPUT}
        source "${CONFIGS_PATH}"/bash/xterm-functions.sh
	# XXX does not play nice with awesome, skip for now
        # rand_xterm_geometry <> ${OUTPUT}
        ;;
    Prop)
        echo prop >> /tmp/xterm-event-handler-timestamp
        #echo property event handler > ${OUTPUT}
        #echo -n '<P>' > ${OUTPUT}
        ;;
esac
