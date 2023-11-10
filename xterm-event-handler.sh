#!/bin/bash

date >> /tmp/xterm-event-handler-log
echo $1 >> /tmp/xterm-event-handler-log

read child1 _ < /proc/${PPID}/task/${PPID}/children
read _ _ _ parentpid _ < /proc/${PPID}/stat
OUTPUT=/proc/${child1}/fd/0

read parentcmd _ < /proc/${parentpid}/comm
echo -n parent: $parentpid $parentcmd >> /tmp/xterm-event-handler-log

test "$parentcmd" = "tabbed" && exit

case $1 in
    Map)
        exec > ${OUTPUT}
        source /home/hlofving/configs/bash/xterm-functions.sh
        rand_xterm_geometry <> ${OUTPUT}
        ;;
    Prop)
        echo prop >> /tmp/xterm-event-handler-timestamp
        #echo property event handler > ${OUTPUT}
        #echo -n '<P>' > ${OUTPUT}
        ;;
esac
date >> /tmp/xterm-event-handler-log
