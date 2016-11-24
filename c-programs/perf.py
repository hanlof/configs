#!/usr/bin/python

import sys
import re
import subprocess

try:
  print ""
  up = "%c[A" % 27
  tot_systime = 0.0
  tot_usertime = 0.0
  tot_realtime = 0.0
  samples = 0
  while True:
    (_, out) = subprocess.Popen(["bash", "-c", "TIMEFORMAT=S%3S\" U%3U \"R%3R; time ./insdirs2 -a 40m -r 4p < all-files > /dev/null"], stderr=subprocess.PIPE).communicate()
    
    m=re.match("S([0123456789.]+) U([0123456789.]+) R([0123456789.]+)", out)
    if m is None:
        print "wtf> %s" % out
        sys.exit()
    systime = float(m.group(1))
    usertime = float(m.group(2))
    realtime = float(m.group(3))
    samples = samples + 1
    tot_systime = tot_systime + systime
    tot_usertime = tot_usertime + usertime
    tot_realtime = tot_realtime + realtime
    print up + "avg %.3f %.3f %.3f" % (tot_systime / samples, tot_usertime / samples, tot_realtime / samples)
except KeyboardInterrupt as k:
  print "Stopped after %i iterations" % samples
  sys.exit(1)
