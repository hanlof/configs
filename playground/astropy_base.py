import astropy
import astropy.coordinates
import astropy.units as u
import astropy.time
import datetime
from astropy.coordinates import Angle, GeocentricMeanEcliptic, GeocentricTrueEcliptic, SkyCoord


now = astropy.time.Time(datetime.datetime.utcnow())
hansbtime = astropy.time.Time(datetime.datetime(1980, 5, 1, 12, 2))
gbg = astropy.coordinates.EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)
altazframe = astropy.coordinates.AltAz(obstime=now, location=gbg)
btimealtaz = altazframe = astropy.coordinates.AltAz(obstime=hansbtime, location=gbg)


pallasnow=astropy.coordinates.get_body_barycentric(body=[(10, 2000002)], time=now, ephemeris='https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/asteroids/a_old_versions/pallas_1900_2100.bsp')

pallasgcrs=astropy.coordinates.GCRS(pallasnow, obstime=now)

def find_period_time(planetname, starttime):
    teststep = datetime.timedelta(days=10)
    skypos = astropy.coordinates.get_body(planetname, now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    skypos2 = astropy.coordinates.get_body(planetname, now + teststep).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    angle = skypos2.lon.degree - skypos.lon.degree
    angle = (angle + 360) % 360
    return 0

def make_planet_path(planetname, points=24,):
    period_time = find_period_time(planetname, now)
    teststep = datetime.timedelta(days=10)
    skypos = astropy.coordinates.get_body(planetname, now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    skypos2 = astropy.coordinates.get_body(planetname, now + teststep).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    angle = skypos2.lon.degree - skypos.lon.degree
    alnge = (angle + 360) % 360
    totsteps = 360 / angle
    tottime = totsteps * teststep

    timestep =  tottime / points
    output = list()
    for i in range(0, points):
        skypos = astropy.coordinates.get_body(planetname, now + i * timestep).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
        output.append(skypos.spherical)

    return output

spicacoords = (201.29824736, -11.16131948)
spicaicrs = SkyCoord(ra=201.29824736*u.deg, dec=-11.16131948*u.deg, distance=260.9*u.lightyear)

astropy.coordinates.get_body("Mercury", now).transform_to(GeocentricMeanEcliptic(equinox=now))
spicalongitude = spicaicrs.transform_to(astropy.coordinates.GeocentricTrueEcliptic(equinox=now)).lon.value

hansspica = spicaicrs.transform_to(astropy.coordinates.GeocentricMeanEcliptic(obstime=hansbtime, equinox=hansbtime))
hanssun = astropy.coordinates.get_sun(time=hansbtime).transform_to(astropy.coordinates.GeocentricMeanEcliptic(obstime=hansbtime, equinox=hansbtime))

def eclipticpos(planet):
    angle = planet.lon - hansspica.lon
    angle += (180 + 360) * u.deg
    return angle.wrap_at(360 * u.deg)

planets = [ 'Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune' ]
signs = (
    "Aries", "Taurus", "Gemini", "Cancer",
    "Leo", "Virgo", "Libra", "Scorpio",
    "Sagitarius", "Capricorn", "Aquarius", "Pisces" )

bar = 0
class NatalChitra():
    spicacoords = (201.29824736, -11.16131948)
    spicaicrs = SkyCoord(ra=201.29824736*u.deg, dec=-11.16131948*u.deg, distance=260.9*u.lightyear)
    angles = dict()
    bar = 0
    def __init__(self, time=None, geoloc=None):
        if time is None:
            time = astropy.time.Time(hansbtime)
        if geoloc is None:
            geoloc = gbg
        self.time = time
        self.geoloc = geoloc
        self.geocentricframe = GeocentricMeanEcliptic(obstime=time, equinox=time)
        self.chitraecliptic = spicaicrs.transform_to(self.geocentricframe)
    def get_angle(self, point):
        if point in self.angles:
            return self.angles[point]
        ephemeris = "builtin"
        if point == "pluto":
            ephemeris="https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de430.bsp"
        if point == "ceres":
            point = [(10, 2000001)]
            ephemeris='https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/asteroids/a_old_versions/ceres_1900_2100.bsp'
        if point == "pallas":
            point = [(10, 2000002)]
            ephemeris='https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/asteroids/a_old_versions/pallas_1900_2100.bsp'
        if point == "vesta":
            point = [(10, 2000004)]
            ephemeris='https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/asteroids/a_old_versions/vesta_1900_2100.bsp'
        planetecliptic = astropy.coordinates.get_body(point, time=self.time, ephemeris=ephemeris).transform_to(self.geocentricframe)
        angle = planetecliptic.lon - self.chitraecliptic.lon
        angle += (180 + 360) * u.deg # Start of the zodiac is 180 deg from Chitra
        self.angles[point] = angle.wrap_at(360  * u.deg)
        return self.angles[point]
    def get_angle_bary(self, point):
        ephemeris = "builtin"
        if point == "pluto":
            ephemeris="https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de430.bsp"
        if point == "pallas":
            point = [(10, 2000002)]
            ephemeris='https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/asteroids/a_old_versions/pallas_1900_2100.bsp'
        print(point)
        print("planetbary = astropy.coordinates.get_body_barycentric(body=point, time=self.time, ephemeris=ephemeris)")
        planetbary = astropy.coordinates.get_body_barycentric(body=point, time=self.time, ephemeris=ephemeris)
        planetbary = astropy.coordinates.ICRS(planetbary)
        planetfrombary = planetbary.transform_to(self.geocentricframe)
        angle = planetfrombary.lon - self.chitraecliptic.lon
        angle += (180 + 360) * u.deg # Start of the zodiac is 180 deg from Chitra
        return angle.wrap_at(360  * u.deg)
    def get_point(self, point):
        angle = self.get_angle(point)
#plansigndegree=[(n, signs[int(d.value // 30)], Angle((d.deg % 30) * u.deg).to_string(sep="°'\"", precision=0)) for n, d in zodiac]
        return (point, signs[int(angle.value // 30)], (angle % (30 * u.deg)).to_string(sep="°'\"", precision=0))
    def get_point_bary(self, point):
        angle = self.get_angle_bary(point)
#plansigndegree=[(n, signs[int(d.value // 30)], Angle((d.deg % 30) * u.deg).to_string(sep="°'\"", precision=0)) for n, d in zodiac]
        return (point, signs[int(angle.value // 30)], (angle % (30 * u.deg)).to_string(sep="°'\"", precision=0))

def truecitradegree(planet, time=None, geoloc=None):
    if time is None:
        time = astropy.time.Time(datetime.datetime.utcnow())
    if geoloc is None:
        geoloc = gbg
    geocentricframe = GeocentricTrueEcliptic(obstime=time, equinox=time)
    chitraecliptic = spicaicrs.transform_to(geocentricframe)
    planetecliptic = astropy.coordinates.get_body(planet, time=time, location=geoloc).transform_to(geocentricframe)
    angle = planetecliptic.lon - chitraecliptic.lon
    angle += (180 + 360) * u.deg # Start of the zodiac is 180 deg from Chitra
    return angle.wrap_at(360  * u.deg)

zodiac = [(p, truecitradegree(p, hansbtime, gbg)) for p in planets]
c = NatalChitra(time=hansbtime, geoloc=gbg)
plansigndegree=[(n, signs[int(d.value // 30)], Angle((d.deg % 30) * u.deg).to_string(sep="°'\"", precision=0)) for n, d in zodiac]
plansigndegree=[(n, signs[int(d.value // 30)], (d % (30 * u.deg)).to_string(sep="°'\"", precision=0)) for n, d in zodiac]

# swisseph calc_ut
# xx       = array of 6 doubles for longitude, latitude, distance, speed in long., speed in lat., and speed in dist.
