import numpy as np
import matplotlib.pyplot as plt
from astropy import units as u
from astropy.time import Time
from astropy.coordinates import SkyCoord, EarthLocation, AltAz, get_sun
import astropy.time
from astropy.coordinates import get_moon
import math
from math import sin, cos, atan2

#supress the warning about vector transforms so as not to clutter the doc build log
import warnings
warnings.filterwarnings('ignore',module='astropy.coordinates.baseframe')

#m33 = SkyCoord.from_name('M33')

now=astropy.time.Time.now()
import datetime

# XXX figure out astropy local time stuff
#now=astropy.time.Time().now()
now -= datetime.timedelta(hours=2)

gothenburg = EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)
altazframe = AltAz(obstime=now, location=gothenburg)

sunaltaz = get_sun(now).transform_to(altazframe)
moonaltaz = get_moon(now).transform_to(altazframe)

print(sunaltaz.alt.deg, sunaltaz.az.deg, moonaltaz.alt.deg, moonaltaz.az.deg)

# Thank you https://stackoverflow.com/questions/59183372/calculate-the-tilt-of-the-moon-crescent !
dlon = sunaltaz.az.deg - moonaltaz.az.deg
y = sin(math.radians(dlon)) * cos(sunaltaz.alt.rad)
x = cos(moonaltaz.alt.rad) * sin(sunaltaz.alt.rad) - sin(moonaltaz.alt.rad) * cos(sunaltaz.alt.rad) * cos(math.radians(dlon))
brng = atan2(y, x)
print(math.degrees(brng) - 90)
#x = math.cos(math.radians(moonaltaz.alt.deg)) * 
