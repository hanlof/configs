#!/usr/bin/python3
import itertools

print("\x1b[0m")
print("\x1b[2J", end="")

def d(x, y, col):
    xs = 20
    ys = 10
    print("\x1b[48;5;%dm" % (16 + col[0] + col[1] * 6 + col[2] * 36), end="")
    ypos = ys * y + 1
    xpos = (xs * 5) / 2 + xs * x - y * (xs / 2)
    xpos = int(xpos)
    i = 0
    while i < ys:
        print("\x1b[%d;%dH" % (ypos + i, xpos), end="")
        print(" " * xs, end="")
        i = i + 1
    print("\x1b[%d;%dH" % (ypos, xpos), end="")
    print(xpos, ypos, end="")
    print("\x1b[%d;%dH" % (ypos + 1, xpos), end="")
    print(x, "|||", y, " ", end="")
    print("\x1b[%d;%dH" % (ypos + 2, xpos), end="")
    print(col, end="")

def pb(n):
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
        d(xpos, ypos, i)
    print("\x1b[0mXXXXXXXXXXXXXXX", xoffset, yoffset)

def p(n):
    a = set([0, 1, 2, 3, 4, 5])
    b = itertools.product(a, a, a)
    c = [i for i in b if sum(i) == n]
    # $color = 16 + ($red * 36) + ($green * 6) + $blue;
    for i in c:
        ypos = 20 - i[0]
        xpos = i[1] * 2 + i[0]
        xpos = xpos + n * 14
        print("\x1b[%d;%dH" % (ypos, xpos), end="")
        print("\x1b[48;5;%dm  " % (16 + i[0] + i[1] * 6 + i[2] * 36), end="")

pb(5)
print("\x1b[%d;%dH" % (50, 50), end="")
