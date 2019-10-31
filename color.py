#!/bin/env python3
import itertools

print("\x1b[0m")
print("\x1b[2J", end="")

def drawbox(x, y, rgb):
    xs = 20
    ys = 10
    colnum = 16 + rgb[0] + rgb[1] * 6 + rgb[2] * 36
    print("\x1b[48;5;%dm" % (colnum), end="")
    ypos = ys * y + 1
    xpos = (xs * 5) / 2 + xs * x - y * (xs / 2)
    xpos = int(xpos)
    i = 0
    while i < ys:
        print("\x1b[%d;%dH" % (ypos + i, xpos), end="")
        print(" " * xs, end="")
        i = i + 1
    #print("\x1b[%d;%dH" % (ypos, xpos), end="")
    #print("\x1b[%d;%dH" % (ypos + 1, xpos), end="")
    print("\x1b[%d;%dH" % (ypos + 1, xpos + 1), end="")
    print(colnum, rgb, end="")

def draw_intensity_level(n):
    zero_to_five = set(range(6))
    all_comb = [i for i in itertools.product(zero_to_five, zero_to_five, zero_to_five)]
    c = [i for i in all_comb if sum(i) == n]
    # $color = 16 + ($red * 36) + ($green * 6) + $blue;
    #offset = min([i + j for i, j in itertools.combinations(c, 2)]) - 1
    xoffset = min([i + j for i, j, k in c])
    yoffset = min([i for i, j, k in c])
    for i in c:
        ypos = i[0] - yoffset
        xpos = i[1] + i[0] - xoffset
        drawbox(xpos, ypos, i)
    print("\x1b[%d;%dH" % (ypos, xpos), end="")
    print("\x1b[0m")

import sys
level = -1
try:
    level = int(sys.argv[1])
except:
    print("Which color intensity?")
    exit(1)
draw_intensity_level(level)
print("\x1b[%d;%dH" % (61, 1), end="")
