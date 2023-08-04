#!/bin/bash

date > /tmp/log

read child1 _ < /proc/${PPID}/task/${PPID}/children

OUTPUT=/proc/${child1}/fd/0

exec > ${OUTPUT}

source /home/hlofving/configs/bash/xterm-functions.sh

rand_xterm_geometry <> ${OUTPUT}
