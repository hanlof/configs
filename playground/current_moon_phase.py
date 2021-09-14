#!/bin/python3

# ORIGINAL: http://github.com/pjain03/moon_phases

from lunar_phases_library import *
import time

current_time = time.localtime()
fraction_of_day = current_time.tm_hour * 60.0 + current_time.tm_min
fraction_of_day = fraction_of_day + (time.timezone / 60.0)
fraction_of_day = fraction_of_day / (60.0 * 24.0)
y = current_time.tm_year
m = current_time.tm_mon
d = current_time.tm_mday + fraction_of_day

import sys
try:
    d += float(sys.argv[1])
except:
    pass

out = get_illuminated_fraction_moon(y, m, d, do_print=False)
#print("\nPhase Information:")
#print("Illuminated Fraction: ", out["illuminated_fraction"])
#print("Position Angle: ", out["position_angle"])
# print("\n")
#lunar_phase_ascii_art(out)
dir = "?"
if 0 <= out["position_angle"] < 180:
    dir = "-"
    old_dir = False
else:
    dir = "+"
    old_dir = True
test = 5
days = 1
delta = 1
while abs(1 - (test % 1.0)) > 0.001 and abs(delta) > 0.001:
    out2 = get_illuminated_fraction_moon(y, m, d + days, do_print=False)
    test = out2['illuminated_fraction']
    #print "mday, angle, fract", d + days, out2["position_angle"], test
    if out2["position_angle"] < 180:
        dirr = False
    else:
        dirr = True
    if dirr != old_dir:
        delta = delta * -0.5
        #print "delta", delta
    old_dir = dirr
    days += delta
days = days - delta
print("%3.1f%s %.2f" % (out['illuminated_fraction'] * 100.0, dir, days))

#print("\n----------------------------------------------------\n")

# Mercury 58.6 days 87.97 days
# Venus 243 days 224.7 days
# Earth 0.99 days 365.26 days
# Mars 1.03 days 1.88 years
# Jupiter 0.41 days 11.86 years
# Saturn 0.45 days 29.46 years
# Uranus 0.72 days 84.01 years
# Neptune 0.67 days 164.79 years
# Pluto 6.39 days 248.59 years

planets = []
days = 1.0
years = 365.26
planets.append({'name': "Mercury", 'time': 87.97 * days})
planets.append({'name': 'Venus',   'time': 224.7 * days})
planets.append({'name': 'Earth',   'time': 365.26 * days})
planets.append({'name': 'Mars',    'time': 1.88 * years})
planets.append({'name': 'Jupiter', 'time': 11.86 * years})
planets.append({'name': 'Saturn',  'time': 29.46 * years})
planets.append({'name': 'Uranus',  'time': 84.01 * years})
planets.append({'name': 'Neptune', 'time': 164.79 * years})
planets.append({'name': 'Pluto',   'time': 248.59 * years})

def lcm(x, y):
    from math import gcd # or can import gcd from `math` in Python 3
    x = round(x)
    y = round(y)
    return x * y // gcd(x, y)

