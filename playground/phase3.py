#/usr/bin/env python
# coding: utf-8
# moon.py, based on code by John Walker (http://www.fourmilab.ch/)
# ported to Python by Kevin Turner <acapnotic@twistedmatrix.com>
# on June 6, 2001 (JDN 2452066.52491), under a full moon.
#
# This program is in the public domain: "Do what thou wilt shall be
# the whole of the law".

"""Functions to find the phase of the moon.

Ported from \"A Moon for the Sun\" (aka moontool.c), a program by the
venerable John Walker.  He used algoritms from \"Practical Astronomy
With Your Calculator\" by Peter Duffett-Smith, Second Edition.

For the full history of the code, as well as references to other
reading material and other entertainments, please refer to John
Walker's website,
http://www.fourmilab.ch/
(Look under the Science/Astronomy and Space heading.)

The functions of primary interest provided by this module are phase(),
which gives you a variety of data on the status of the moon for a
given date; and phase_hunt(), which given a date, finds the dates of
the nearest full moon, new moon, etc.
"""

import datetime
from bisect import bisect
from math import sin, cos, floor, sqrt, pi, tan, atan
import sys
import imagesize
from getopt import getopt


__TODO__ = [
    'Add command-line interface.',
    'Make front-end modules for ASCII and various GUIs.',
    ]

# Precision used when describing the moon's phase in textual format,
# in phase_string().
PRECISION = 0.05
NEW = 0 / 4.0
FIRST = 1 / 4.0
FULL = 2 / 4.0
LAST = 3 / 4.0
NEXTNEW = 4 / 4.0


class MoonPhase:
    """I describe the phase of the moon.

    I have the following properties:
        date - a datetime instance
        phase - my phase, in the range 0.0 .. 1.0
        phase_text - a string describing my phase
        illuminated - the percentage of the face of the moon illuminated
        angular_diameter - as seen from Earth, in degrees.
        sun_angular_diameter - as seen from Earth, in degrees.

        new_date - the date of the most recent new moon
        q1_date - the date the moon reaches 1st quarter in this cycle
        full_date - the date of the full moon in this cycle
        q3_date - the date the moon reaches 3rd quarter in this cycle
        nextnew_date - the date of the next new moon
    """

    def __init__(self, date=datetime.datetime.now()):
        """MoonPhase constructor.

        Give me a date, as either a Julian Day Number or a datetime
        object."""

        self.date = date

        self.__dict__.update(phase(self.date))

        self.phase_text = phase_string(self.phase)

    def __getattr__(self, a):
        # Called when a lookup has not found the attribute in the usual places
        if a in ['new_date', 'q1_date', 'full_date', 'q3_date',
                 'nextnew_date']:
            (
                self.new_date,
                self.q1_date,
                self.full_date,
                self.q3_date,
                self.nextnew_date
                ) = phase_hunt(self.date)
            return getattr(self, a)
        raise AttributeError(a)

    def __repr__(self):
        if type(self.date) is int:
            jdn = self.date
        else:
            jdn = self.date.jdn

        return "<%s(%d)>" % (self.__class__, jdn)

    def __str__(self):
        d = self.date
        s = "%s for %s, %s (%%%.2f illuminated)" %\
            (self.__class__, d.strftime(), self.phase_text,
             self.illuminated * 100)

        return s


class AstronomicalConstants:

    # JDN stands for Julian Day Number
    # Angles here are in degrees

    # 1980 January 0.0 in JDN
    # XXX: datetime(1980).jdn yields 2444239.5 -- which one is right?
    epoch = 2444238.5

    # Ecliptic longitude of the Sun at epoch 1980.0
    ecliptic_longitude_epoch = 278.833540

    # Ecliptic longitude of the Sun at perigee
    ecliptic_longitude_perigee = 282.596403

    # Eccentricity of Earth's orbit
    eccentricity = 0.016718

    # Semi-major axis of Earth's orbit, in kilometers
    sun_smaxis = 1.49585e8

    # Sun's angular size, in degrees, at semi-major axis distance
    sun_angular_size_smaxis = 0.533128

    # Elements of the Moon's orbit, epoch 1980.0

    # Moon's mean longitude at the epoch
    moon_mean_longitude_epoch = 64.975464
    # Mean longitude of the perigee at the epoch
    moon_mean_perigee_epoch = 349.383063

    # Mean longitude of the node at the epoch
    node_mean_longitude_epoch = 151.950429

    # Inclination of the Moon's orbit
    moon_inclination = 5.145396

    # Eccentricity of the Moon's orbit
    moon_eccentricity = 0.054900

    # Moon's angular size at distance a from Earth
    moon_angular_size = 0.5181

    # Semi-mojor axis of the Moon's orbit, in kilometers
    moon_smaxis = 384401.0
    # Parallax at a distance a from Earth
    moon_parallax = 0.9507

    # Synodic month (new Moon to new Moon), in days
    synodic_month = 29.53058868

    # Base date for E. W. Brown's numbered series of lunations
    # (1923 January 16)
    lunations_base = 2423436.0

    # Properties of the Earth
    earth_radius = 6378.16

c = AstronomicalConstants()


# Little handy mathematical functions.
def fixangle(a):
    return a - 360.0 * floor(a / 360.0)


def torad(d):
    return d * pi / 180.0


def todeg(r):
    return r * 180.0 / pi


def dsin(d):
    return sin(torad(d))


def dcos(d):
    return cos(torad(d))


def phase_string(p):
    phase_strings = (
        (NEW + PRECISION, "new"),
        (FIRST - PRECISION, "waxing crescent"),
        (FIRST + PRECISION, "first quarter"),
        (FULL - PRECISION, "waxing gibbous"),
        (FULL + PRECISION, "full"),
        (LAST - PRECISION, "waning gibbous"),
        (LAST + PRECISION, "last quarter"),
        (NEXTNEW - PRECISION, "waning crescent"),
        (NEXTNEW + PRECISION, "new"))

    i = bisect([a[0] for a in phase_strings], p)

    return phase_strings[i][1]


def phase(phase_date=datetime.datetime.now()):
    """Calculate phase of moon as a fraction:

    The argument is the time for which the phase is requested,
    expressed in either a datetime or by Julian Day Number.

    Returns a dictionary containing the terminator phase angle as a
    percentage of a full circle (i.e., 0 to 1), the illuminated
    fraction of the Moon's disc, the Moon's age in days and fraction,
    the distance of the Moon from the centre of the Earth, and the
    angular diameter subtended by the Moon as seen by an observer at
    the centre of the Earth."""

    # Calculation of the Sun's position

    # date within the epoch

    dayx = phase_date - datetime.datetime(1979, 12, 31, 0, 0, 0)
    day = dayx.total_seconds() / (60 * 60 * 24)

    # Mean anomaly of the Sun
    N = fixangle((360 / 365.2422) * day)
    # Convert from perigee coordinates to epoch 1980
    M = fixangle(N + c.ecliptic_longitude_epoch - c.ecliptic_longitude_perigee)

    # Solve Kepler's equation
    Ec = kepler(M, c.eccentricity)
    Ec = sqrt((1 + c.eccentricity) / (1 - c.eccentricity)) * tan(Ec / 2.0)
    # True anomaly
    Ec = 2 * todeg(atan(Ec))
    # Suns's geometric ecliptic longuitude
    lambda_sun = fixangle(Ec + c.ecliptic_longitude_perigee)

    # Orbital distance factor
    F = ((1 + c.eccentricity * cos(torad(Ec))) / (1 - c.eccentricity**2))

    # Distance to Sun in km
    sun_dist = c.sun_smaxis / F
    sun_angular_diameter = F * c.sun_angular_size_smaxis

    ########
    #
    # Calculation of the Moon's position

    # Moon's mean longitude
    moon_longitude = fixangle(13.1763966 * day + c.moon_mean_longitude_epoch)

    # Moon's mean anomaly
    MM = fixangle(moon_longitude - 0.1114041 * day - c.moon_mean_perigee_epoch)

    # Moon's ascending node mean longitude
    # MN = fixangle(c.node_mean_longitude_epoch - 0.0529539 * day)

    evection = 1.2739 * sin(torad(2 * (moon_longitude - lambda_sun) - MM))

    # Annual equation
    annual_eq = 0.1858 * sin(torad(M))

    # Correction term
    A3 = 0.37 * sin(torad(M))

    MmP = MM + evection - annual_eq - A3

    # Correction for the equation of the centre
    mEc = 6.2886 * sin(torad(MmP))

    # Another correction term
    A4 = 0.214 * sin(torad(2 * MmP))

    # Corrected longitude
    lP = moon_longitude + evection + mEc - annual_eq + A4

    # Variation
    variation = 0.6583 * sin(torad(2 * (lP - lambda_sun)))

    # True longitude
    lPP = lP + variation

    #
    # Calculation of the Moon's inclination
    # unused for phase calculation.

    # Corrected longitude of the node
    # NP = MN - 0.16 * sin(torad(M))

    # Y inclination coordinate
    # y = sin(torad(lPP - NP)) * cos(torad(c.moon_inclination))

    # X inclination coordinate
    # x = cos(torad(lPP - NP))

    # Ecliptic longitude (unused?)
    # lambda_moon = todeg(atan2(y,x)) + NP

    # Ecliptic latitude (unused?)
    # BetaM = todeg(asin(sin(torad(lPP - NP)) *
    #   sin(torad(c.moon_inclination))))

    #######
    #
    # Calculation of the phase of the Moon

    # Age of the Moon, in degrees
    moon_age = lPP - lambda_sun

    # Phase of the Moon
    moon_phase = (1 - cos(torad(moon_age))) / 2.0

    # Calculate distance of Moon from the centre of the Earth
    moon_dist = (
        (c.moon_smaxis * (1 - c.moon_eccentricity**2)) /
        (1 + c.moon_eccentricity * cos(torad(MmP + mEc))))

    # Calculate Moon's angular diameter
    moon_diam_frac = moon_dist / c.moon_smaxis
    moon_angular_diameter = c.moon_angular_size / moon_diam_frac

    # Calculate Moon's parallax (unused?)
    # moon_parallax = c.moon_parallax / moon_diam_frac

    res = {
        'phase': fixangle(moon_age) / 360.0,
        'illuminated': moon_phase,
        'age': c.synodic_month * fixangle(moon_age) / 360.0,
        'distance': moon_dist - 6371, # adjust for earth radius
        'angular_diameter': moon_angular_diameter,
        'sun_distance': sun_dist,
        'sun_angular_diameter': sun_angular_diameter,
        'true_long': lPP
        }

    return res
# phase()


def phase_hunt(sdate=datetime.datetime.now()):
    """Find time of phases of the moon which surround the current date.

    Five phases are found, starting and ending with the new moons
    which bound the current lunation.
    """


    #adate = sdate + DateTime.RelativeDateTime(days=-45)
    adate = sdate + datetime.timedelta(days=-45)

    k1 = floor((adate.year +
                ((adate.month - 1) * (1.0 / 12.0)) -
                1900) * 12.3685)

    nt1 = meanphase(adate, k1)
    adate = nt1

    dayx = sdate - datetime.datetime(1990, 1, 1, 12, 0, 0)
    sdate = dayx.total_seconds() / (60 * 60 * 24)
    sdate += 2447892.0

    while 1:
        adate = adate + c.synodic_month
        k2 = k1 + 1
        nt2 = meanphase(adate, k2)
        if nt1 <= sdate < nt2:
            break
        nt1 = nt2
        k1 = k2

    phases = list(map(truephase,
                      [k1,    k1,    k1,    k1,    k2],
                      [0/4.0, 1/4.0, 2/4.0, 3/4.0, 0/4.0]))

    return phases
# phase_hunt()


def meanphase(sdate, k):
    """Calculates time of the mean new Moon for a given base date.

    This argument K to this function is the precomputed synodic month
    index, given by:

                        K = (year - 1900) * 12.3685

    where year is expressed as a year and fractional year.
    """

    # sdate is either datetime or float
    # Time in Julian centuries from 1900 January 0.5
    if hasattr(sdate, 'day'):
        dayx = sdate - datetime.datetime(1900, 1, 1, 12)
        t = dayx.days / 36525
    else:
        t = sdate - 2415021.0
        #day = t.total_seconds() / (60 * 60 * 24)
        t = t / 36525

    # square for frequent use
    t2 = t * t
    # and cube
    t3 = t2 * t

    nt1 = (
        2415020.75933 + c.synodic_month * k + 0.0001178 * t2 -
        0.000000155 * t3 + 0.00033 *
        dsin(166.56 + 132.87 * t - 0.009173 * t2)
        )

    return nt1
# meanphase()


def truephase(k, tphase):
    """Given a K value used to determine the mean phase of the new
    moon, and a phase selector (0.0, 0.25, 0.5, 0.75), obtain the
    true, corrected phase time."""

    # add phase to new moon time
    k = k + tphase
    # Time in Julian centuries from 1900 January 0.5
    t = k / 1236.85

    t2 = t * t
    t3 = t2 * t

    # Mean time of phase
    pt = (
        2415020.75933 + c.synodic_month * k + 0.0001178 * t2 -
        0.000000155 * t3 + 0.00033 *
        dsin(166.56 + 132.87 * t - 0.009173 * t2)
        )

    # Sun's mean anomaly
    m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3

    # Moon's mean anomaly
    mprime = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3

    # Moon's argument of latitude
    f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3

    if (tphase < 0.01) or (abs(tphase - 0.5) < 0.01):
        # Corrections for New and Full Moon
        pt = pt + (
            (0.1734 - 0.000393 * t) * dsin(m)
            + 0.0021 * dsin(2 * m)
            - 0.4068 * dsin(mprime)
            + 0.0161 * dsin(2 * mprime)
            - 0.0004 * dsin(3 * mprime)
            + 0.0104 * dsin(2 * f)
            - 0.0051 * dsin(m + mprime)
            - 0.0074 * dsin(m - mprime)
            + 0.0004 * dsin(2 * f + m)
            - 0.0004 * dsin(2 * f - m)
            - 0.0006 * dsin(2 * f + mprime)
            + 0.0010 * dsin(2 * f - mprime)
            + 0.0005 * dsin(m + 2 * mprime)
            )
    elif (abs(tphase - 0.25) < 0.01) or (abs(tphase - 0.75) < 0.01):
        pt = pt + (
            (0.1721 - 0.0004 * t) * dsin(m)
            + 0.0021 * dsin(2 * m)
            - 0.6280 * dsin(mprime)
            + 0.0089 * dsin(2 * mprime)
            - 0.0004 * dsin(3 * mprime)
            + 0.0079 * dsin(2 * f)
            - 0.0119 * dsin(m + mprime)
            - 0.0047 * dsin(m - mprime)
            + 0.0003 * dsin(2 * f + m)
            - 0.0004 * dsin(2 * f - m)
            - 0.0006 * dsin(2 * f + mprime)
            + 0.0021 * dsin(2 * f - mprime)
            + 0.0003 * dsin(m + 2 * mprime)
            + 0.0004 * dsin(m - 2 * mprime)
            - 0.0003 * dsin(2 * m + mprime)
            )
        if (tphase < 0.5):
            #  First quarter correction
            pt = pt + 0.0028 - 0.0004 * dcos(m) + 0.0003 * dcos(mprime)
        else:
            #  Last quarter correction
            pt = pt + -0.0028 + 0.0004 * dcos(m) - 0.0003 * dcos(mprime)
    else:
        raise ValueError(
            "TRUEPHASE called with invalid phase selector",
            tphase)

    d = pt - 2447892.0
    date = datetime.datetime(1990, 1, 1, 12, 0, 0) + datetime.timedelta(days=d)
    return date
# truephase()


def kepler(m, ecc, epsilon=1e-6):
    """Solve the equation of Kepler."""

    e = m = torad(m)
    while 1:
        delta = e - ecc * sin(e) - m
        e -= delta / (1.0 - ecc * cos(e))
        if abs(delta) <= epsilon:
            break
    return e

def get_sign(degree):
    signs = [ [ "aries", "♈" ],
              [ "taurus", "♉" ],
              [ "gemini", "♊" ],
              [ "cancer", "♋" ],
              [ "leo", "♌" ],
              [ "virgo", "♍" ],
              [ "libra", "♎" ],
              [ "scorpio", "♏" ],
              [ "saggitarius", "♐" ],
              [ "capricorn", "♑" ],
              [ "aquarius", "♒" ],
              [ "pisces", "♓" ], ]
    degree = degree % 360
    sign_index = int(floor(degree / 30))
    return signs[sign_index][1] # [degree, sign_index] + signs[(sign_index)]

def get_sign_and_degrees(degree):
    signs = [ [ "aries", "♈" ],
              [ "taurus", "♉" ],
              [ "gemini", "♊" ],
              [ "cancer", "♋" ],
              [ "leo", "♌" ],
              [ "virgo", "♍" ],
              [ "libra", "♎" ],
              [ "scorpio", "♏" ],
              [ "saggitarius", "♐" ],
              [ "capricorn", "♑" ],
              [ "aquarius", "♒" ],
              [ "pisces", "♓" ], ]
    degree = degree % 360
    sign_index = int(floor(degree / 30))
    return (signs[sign_index][1] + "%6.2f" % (degree % 30)) # [degree, sign_index] + signs[(sign_index)]

def moon_size(dist):
    # return actual size in degrees OR +/- percentages or both??
    return "dist"

def format_timediff(diff):
    S_PER_W = 60 * 60 * 24 * 7
    S_PER_D = 60 * 60 * 24
    S_PER_H = 60 * 60
    S_PER_M = 60
    seconds = abs(diff.total_seconds())
    output = dict()
    if seconds >= S_PER_W:
        weeks = floor(seconds / S_PER_W)
        output['w'] = weeks
        seconds -= weeks * S_PER_W
    if seconds >= S_PER_D or output:
        days = floor(seconds / S_PER_D)
        output['d'] = days
        seconds -= days * S_PER_D
    if seconds >= S_PER_H or output:
        hours = floor(seconds / S_PER_H)
        output['h'] = hours
        seconds -= hours * S_PER_H
    if seconds >= S_PER_M or output:
        minutes = floor(seconds / S_PER_M)
        output['m'] = minutes
        seconds -= minutes * S_PER_M
    output_string = ""
    if 'w' in output: return "%dw %dd" % (output['w'], output['d'])
    if 'd' in output: return "%dd %dh" % (output['d'], output['h'])
    if 'h' in output: return "%dh %dm" % (output['h'], output['m'])
    return "%dm %ds" % (output['m'], seconds)

import datetime
import os

def ftime(t):
    tzofs = datetime.datetime.now() - datetime.datetime.utcnow()
    # now sure why the day is 1-off
    tzofs += datetime.timedelta(days=-1)
    return (t + tzofs)

def get_phases():
    m = MoonPhase()
    tzofs = datetime.datetime.now() - datetime.datetime.utcnow()
    new = m.new_date + tzofs
    now = datetime.datetime.now()
    now += tzofs
    ret = ""
    for symbol, date in [
            (u"○", ftime(m.new_date)),
            (u"◑", ftime(m.q1_date)),
            (u"●", ftime(m.full_date)),
            (u"◐", ftime(m.q3_date)),
            (u"○", ftime(m.nextnew_date))]:
        diff = date - datetime.datetime.now()
        a = datetime.datetime(date.year, date.month, date.day, date.hour, date.minute)
        diffX = a - datetime.datetime.now()
        moon_dist_mean=385000
        moon_dist_min=356500
        moon_dist_max=406700
        if date > now:
            sign = get_sign_and_degrees(MoonPhase(now).true_long)
            ret += "%.0f%% " % (m.illuminated * 100)
            ret += "%s %s\n" % (sign,  now.strftime("%b %d "))
            now = datetime.datetime(now.year + 10,1,1)
        sign = get_sign_and_degrees(MoonPhase(date).true_long)
        dist = MoonPhase(date).distance
        #print "", symbol, "", sign, "", date.strftime("%b %d  %H:%M"), " [ %1.0fw %1.0fd ]" % (floor(abs(diff.days) / 7), abs(diff.days) % 7), "%+3.0f" % (100 - 200*(dist - moon_dist_min) / (moon_dist_max - moon_dist_min))
        ret += f" {symbol}  {sign} %s [ %-6s ] %+3.0f\n" % (date.strftime("%b %d %H:%M"), format_timediff(diffX), (100 - 200*(dist - moon_dist_min) / (moon_dist_max - moon_dist_min)))
        #print("", symbol, "", sign, "", date.strftime("%b %d  %H:%M"), "[", format_timediff(diffX), "]", "%+3.0f" % (100 - 200*(dist - moon_dist_min) / (moon_dist_max - moon_dist_min)))

    phaselen = m.nextnew_date - m.new_date
    #sys.stdout.write(u"Len %.02f aoeu" % len.days)
    ret += "Len %.02f" % (phaselen.total_seconds() / (60 * 60 * 24))

    return ret

def shade_svgpath(width):
    m = MoonPhase(datetime.datetime.now())
    curphase = m.phase
    radii = abs(cos(m.phase*pi*2))
    if curphase < .25:
        bigsweep = 1
        smallsweep = 1
    elif curphase < .50:
        bigsweep = 1
        smallsweep = 0
    elif curphase < .75:
        bigsweep = 0
        smallsweep = 1
    else:
        bigsweep = 0
        smallsweep = 0

    radii *= width / 2
    pathstring = "M %d,0 " % (width / 2)
    pathstring += "A %d,%d 0 0,%d %d,%d " % \
                  (radii, width / 2, smallsweep, width / 2, width)
    pathstring += "A %d,%d 0 0,%d %d,0" % \
                  (width / 2, width / 2, bigsweep, width / 2)
    return pathstring


if __name__ == '__main__':
    m = MoonPhase(datetime.datetime.now())
    s = """The moon is %s, %.2f%% illuminated, %.1f days old. Phase:%f""" %\
        (m.phase_text, m.illuminated * 100, m.age, m.phase)
    phases_emoji=u"🌑🌓🌕🌗"
    phases_utf8="○●◐◑"

    try:
        parsed = getopt(sys.argv[1:], "ps:", ["shade-svgpath=", "phases"])
    except Exception as e:
        print(e)
        exit(1)

    opts, args = parsed
    for opt, val in opts:
        if opt == "-s" or opt == "--shade-svgpath":
            width, height = imagesize.get(val)
            print(shade_svgpath(width))
            exit(0)
        if opt == "-p" or opt == "--phases":
            print(get_phases())

