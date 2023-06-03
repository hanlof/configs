import astropy
import astropy.coordinates
import astropy.units as u
import astropy.time
import datetime


now = astropy.time.Time(datetime.datetime.utcnow())
hansbtime = astropy.time.Time(datetime.datetime(1980, 5, 1, 14, 2))
gbg = astropy.coordinates.EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)
altazframe = astropy.coordinates.AltAz(obstime=now, location=gbg)

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

spica = astropy.coordinates.SkyCoord.from_name("Spica")
spicalongitude = spica.transform_to(astropy.coordinates.GeocentricTrueEcliptic(equinox=now)).lon.value
astropy.coordinates.get_body("Mercury", now).transform_to(astropy.coordinates.GeocentricMeanEcliptic(equinox=now))




