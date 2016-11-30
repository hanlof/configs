#!/usr/bin/python

import sys
import re
import subprocess
import resource
import os
import time

# DONE eliminate os.system() it spaws an extra /bin/sh and we want to avoid that. 
# DONE measure real time for total time instead of adding user time and system time
# TODO add parameter for quitting after N iterations or after M seconds or after stabilized value
# TODO add parameter for infile/outfile
# TODO print other statistics from the stat structure
# TODO store stuff in database. or make a wrapper that does that??
#  --- will need to think about parameters into the executed program and how to store them properly in tables or whatever
# TODO handle all the different performance measurements in a generic way. make it easier to add measuring points
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

FNULL = open("/dev/null", 'wb')
try:
  print ""
  up = "%c[A" % 27
  tot_systime = 0.0
  tot_usertime = 0.0
  tot_realtime = 0.0
  tot_cputime = 0.0
  samples = 0
  while True:
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
        tot_cputime = 0.0
        samples = 0
    #i=os.system(command)
    FIN = open("./all-files", 'rwb')
    before=time.time()
    p=subprocess.Popen(sys.argv[1:], stdin=FIN, stdout=FNULL)
    i=p.wait()
    after=time.time()
    FIN.close()
    status, sig = (i >> 8, i & 255)
    status = 0
    sig = 0
    if sig != 0:
        print "Stopped after %i iterations" % samples
        print "sig:%d status:%d" % (sig, status)
        sys.exit(1)
    if status >= 126:
        print "failed to execute. trying again..."
        time.sleep(0.5)
        continue
    elif status > 0:
        print "program returned %d" % status
        sys.exit(1)
    res_after=resource.getrusage(resource.RUSAGE_CHILDREN)
    systime = res_after.ru_stime - res_before.ru_stime
    usertime = res_after.ru_utime - res_before.ru_utime
    realtime = after - before
    cputime = systime + usertime
    samples = samples + 1
    tot_systime = tot_systime + systime
    tot_usertime = tot_usertime + usertime
    tot_realtime = tot_realtime + realtime
    tot_cputime = tot_cputime + cputime
    print up + "%d - %.1f %.1f %.1f %.1f" % (samples, 1000 * tot_systime / samples, 1000 * tot_usertime / samples, 1000 * tot_realtime / samples, 100 * tot_cputime / tot_realtime)
except KeyboardInterrupt as k:
  print "Stopped after %i iterations" % samples
  sys.exit(1)
