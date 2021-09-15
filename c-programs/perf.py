#!/usr/bin/python

import sys
import re
import subprocess
import resource
import os
import time
import argparse
# DONE eliminate os.system() it spaws an extra /bin/sh and we want to avoid that. 
# DONE measure real time for total time instead of adding user time and system time
# DONE add parameter for infile/outfile
# TODO add parameter for quitting after N iterations or after M seconds or after stabilized value
# TODO print other statistics from the stat structure
#  --- handle all the different performance measurements in a generic way? make it easier to add measuring points
# TODO store stuff in database. or make a wrapper that does that??
#  --- will need to think about parameters into the executed program and how to store them properly in tables or whatever

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='infile', type=argparse.FileType('rb'), default=sys.stdin)
parser.add_argument('-o', dest='outfile', type=argparse.FileType('wb'), default=sys.stdout)
parser.add_argument('program')
parser.add_argument('program_args', nargs=argparse.REMAINDER)

args = parser.parse_args(sys.argv[1:])
print args

old_mtime = os.stat(args.program).st_mtime

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
            stat=os.stat(args.program)
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
  tot_cputime = 0.0
  samples = 0
  while True:
    res_before=resource.getrusage(resource.RUSAGE_CHILDREN)
    try:
        mtime=os.stat(args.program).st_mtime
    except OSError as e:
        mtime=wait_for_file(args.program)
    if mtime != old_mtime:
        print args.program + " changed!\n"
        old_mtime = mtime
        tot_systime = 0.0
        tot_usertime = 0.0
        tot_realtime = 0.0
        tot_cputime = 0.0
        samples = 0

    args.infile.seek(0)
    before=time.time()
    p=subprocess.Popen([args.program] + args.program_args, stdin=args.infile, stdout=args.outfile)
    i=p.wait()
    after=time.time()

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
    print up + "%d - S%.1f U%.1f R%.1f CPU%.1f" % (samples, 1000 * tot_systime / samples, 1000 * tot_usertime / samples, 1000 * tot_realtime / samples, 100 * tot_cputime / tot_realtime)
except KeyboardInterrupt as k:
  print "Stopped after %i iterations" % samples
  sys.exit(1)
