#!/usr/bin/python

import sys
import re
import subprocess

try:
  tot_systime = 0.0
  tot_usertime = 0.0
  samples = 0
  while True:
    (_, out) = subprocess.Popen(["bash", "-c", "TIMEFORMAT=S%3S\" \"U%3U; time ./insdirs2 < all-files > /dev/null"], stderr=subprocess.PIPE).communicate()
    
    m=re.match("S([0123456789.]+) U([0123456789.]+)", out)
    systime = float(m.group(1))
    usertime = float(m.group(2))
    samples = samples + 1
    tot_systime = tot_systime + systime
    tot_usertime = tot_usertime + usertime
    
    print "avg %.3f %.3f" % (tot_systime / samples, tot_usertime / samples)
    up = "%c[A" % 27
    print up,
except KeyboardInterrupt as k:
  print "Stopped after %i iterations" % samples
  sys.exit(1)
