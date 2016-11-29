#!/usr/bin/python

import sys
import re
import subprocess
import resource
import os
import time

# TODO add parameter for quitting after N iterations or after M seconds or after stabilized value
# TODO eliminate os.system() it spaws an extra /bin/sh and we want to avoid that
# TODO measure real time for total time instead of adding user time and system time
# TODO print other statistics from the stat structure
# TODO store stuff in database. or make a wrapper that does that??
#  --- will need to think about parameters into the executed program and how to store them properly in tables or whatever
if len(sys.argv) < 2:
    print("what do you want to run?")
    sys.exit(0)

command = " ".join(sys.argv[1:])
old_mtime = os.stat(sys.argv[1]).st_mtime

def wait_for_file(f):
    back = "%c[5D" % 27
    ani=[".....",
         "o....",
         "Oo...",
         "oOo..",
         ".oOo.",
         "..oOo",
         "...oO",
         "....o", ]
    anistep = 0
    sys.stdout.write("%s is gone. waiting for it to come back ....." % f)
    sys.stdout.flush()
    mtime = None
    while mtime is None:
        try:
            stat=os.stat(sys.argv[1])
            mtime=stat.st_mtime
        except OSError as e:
            time.sleep(0.1)
            sys.stdout.write(back)
            anistep += 1
            anistep &= 7
            sys.stdout.write(ani[anistep])
            sys.stdout.flush()
            continue
    print " Got it!"
    return mtime

try:
  print ""
  up = "%c[A" % 27
  tot_systime = 0.0
  tot_usertime = 0.0
  tot_realtime = 0.0
  samples = 0
  while True:
#    (_, out) = subprocess.Popen(["bash", "-c", "TIMEFORMAT=S%3S\" U%3U \"R%3R; time ./insdirs2 -a 40m -r 4p < all-files > /dev/null"], stderr=subprocess.PIPE).communicate()  
#    m=re.match("S([0123456789.]+) U([0123456789.]+) R([0123456789.]+)", out)
#    if m is None:
#        print "wtf> %s" % out
#        sys.exit()
#    systime = float(m.group(1))
#    usertime = float(m.group(2))
#    realtime = float(m.group(3))
    res_before=resource.getrusage(resource.RUSAGE_CHILDREN)
    try:
        mtime=os.stat(sys.argv[1]).st_mtime
    except OSError as e:
        mtime=wait_for_file(sys.argv[1])
    if mtime != old_mtime:
        print sys.argv[1] + " changed!\n"
        old_mtime = mtime
        tot_systime = 0.0
        tot_usertime = 0.0
        tot_realtime = 0.0
        samples = 0
    i=os.system(command)
    status, sig = (i >> 8, i & 255)
    if sig != 0:
        print "Stopped after %i iterations" % samples
        print "sig:%d status:%d" % (sig, status)
        sys.exit(1)
    if status >= 126:
        print "failed to execute. trying again..."
        time.sleep(0.5)
        continue
    res_after=resource.getrusage(resource.RUSAGE_CHILDREN)
    systime = res_after.ru_stime - res_before.ru_stime
    usertime = res_after.ru_utime - res_before.ru_utime
    realtime = systime + usertime
    samples = samples + 1
    tot_systime = tot_systime + systime
    tot_usertime = tot_usertime + usertime
    tot_realtime = tot_realtime + realtime
    print up + "avg %.3f %.3f %.3f" % (tot_systime / samples, tot_usertime / samples, tot_realtime / samples)
except KeyboardInterrupt as k:
  print "Stopped after %i iterations" % samples
  sys.exit(1)
