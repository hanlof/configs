#!/bin/bash

echo $1 >> /tmp/xterm-event-handler-log
date >> /tmp/xterm-event-handler-log

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
        source /home/hans/configs/bash/xterm-functions.sh
        rand_xterm_geometry <> ${OUTPUT}
        ;;
    Prop)
        echo prop >> /tmp/xterm-event-handler-timestamp
        #echo property event handler > ${OUTPUT}
        #echo -n '<P>' > ${OUTPUT}
        ;;
esac
