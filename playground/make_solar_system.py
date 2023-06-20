import bpy
from math import pi, tau, radians
from mathutils import Vector, Matrix
import bmesh

import sys
import mathutils
import astropy
import astropy.coordinates
from astropy.coordinates import get_sun, get_moon, EarthLocation, Longitude, Latitude, GCRS
from astropy.coordinates import AltAz
import astropy.units as u
import datetime
import lunarsky
from lunarsky import MoonLocation



# worlds cameras meshes objects lights images textures materials
def clear_scene():
    for w in bpy.data.worlds:
        bpy.data.worlds.remove(w, do_unlink=True)
    for w in bpy.data.cameras:
        bpy.data.cameras.remove(w, do_unlink=True)
    for w in bpy.data.meshes:
        bpy.data.meshes.remove(w, do_unlink=True)
    for w in bpy.data.objects:
        bpy.data.objects.remove(w, do_unlink=True)
    for w in bpy.data.lights:
        bpy.data.lights.remove(w, do_unlink=True)
    for w in bpy.data.images:
        bpy.data.images.remove(w, do_unlink=True)
    for w in bpy.data.textures:
        bpy.data.textures.remove(w, do_unlink=True)
    for w in bpy.data.materials:
        bpy.data.materials.remove(w, do_unlink=True)
    for w in bpy.data.curves:
        bpy.data.curves.remove(w, do_unlink=True)


def clear_nodes(nodes):
    for n in nodes:
        nodes.remove(n)

def make_camera(name, object_props=None, **kwargs):
    c = bpy.data.cameras.new(name)
    for propname, val in kwargs.items():
        setattr(c, propname, val)
    o = bpy.data.objects.new(name, c)
    for propname, val in object_props.items():
        setattr(o, propname, val)
    bpy.context.collection.objects.link(o)
    return o

def create_plane_noops():
    mesh=bpy.data.meshes.new("Moonmesh")
    mesh.use_auto_smooth = True
    mesh.from_pydata(
        (( -2, 0, -1), (2, 0, -1), (2, 0, 1), (-2, 0, 1),
         (  0, 0, -1), (0, 0, 1)),
        (),
        ((0, 4, 5, 3), (4, 1, 2, 5)) )
    o = bpy.data.objects.new("Moon", mesh)
    bpy.context.collection.objects.link(o)
    return o

def make_uv_from_faces(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    uv_layer = bm.loops.layers.uv.verify()
    uv_scale  = Vector( (0.25, 0.5) )
    uv_offset = Vector( (0.5, 0.5) )
    for face in bm.faces:
        face.smooth = True
        for loop in face.loops:
            loop[uv_layer].uv = loop.vert.co.xz * uv_scale + uv_offset
    bm.to_mesh(obj.data)

def add_mod(obj, name, type, opts):
    mod = obj.modifiers.new(name, type)
    for key, val in opts.items():
        setattr(mod, key, val)

def apply_mods(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    object_eval = obj.evaluated_get(depsgraph)
    mesh_from_eval = bpy.data.meshes.new_from_object(object_eval)
    obj.modifiers.clear()
    obj.data = mesh_from_eval

def get_center(obj):
    sum = Vector( (0, 0, 0) )
    for v in obj.data.vertices:
        sum += v.co
    return sum / len(obj.data.vertices)

# clear and unlink stuff from bpy.data
def clear_data(*args):
    for field in [getattr(bpy.data, name) for name in args]:
        for w in field:
            field.remove(w, do_unlink=True)

# Constants
moon_radius=1.7371
moon_diameter = 2 * moon_radius

default_props = {
    'camfov': 0.6,
    'resx': 1024,
    'resy': 1024,
    'sunstr': 7.5,
    'colormap': '/home/hlofving/Downloads/lroc_color_poles_4k.tif',
    'heightmap': '/home/hlofving/Downloads/ldem_16_uint.tif', }

# TODO: clear world data from scene
# TODO: adjust sun strength
# TODO: add earthlight
# TODO: adjust bump map to scale correctly
# TODO: probably use linear colorspace for bump map?!
# TODO: get the shading/colors correct

moonscene = bpy.context.scene

moonprops = default_props
if 'moon_params' in moonscene:
    moonprops.update(moonscene['moon_params'])

#for o in moonscene.collection.all_objects:
#    if o is not None:
#        bpy.data.objects.remove(o, do_unlink=True)

clear_scene()


# Moon object


# Light
moonscene.collection.objects.link(bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")))
bpy.data.lights["Sun"].energy = moonprops['sunstr']
bpy.data.lights["Sun"].angle = 0

now = astropy.time.Time(datetime.datetime.utcnow())


bpy.data.objects["Sun"].location = Vector( [0,0,0] )

# return shortest angle (positive or negative) from p1 to p2
def relang(p1, p2):
    return (((p2 - p1 - 180) + 360) % 360) - 180

def bisectang(planetname, time, targetangle, step):
    TOTSTEPS = 0
    testangle = astropy.coordinates.get_body(planetname, time).transform_to(astropy.coordinates.HeliocentricTrueEcliptic).lon.degree
    delta = relang(targetangle, testangle)
    dir = 1 if delta <= 0 else -1
    step = abs(step)
    while abs(delta) > 0.01:
        print(planetname, time)
        time += dir * step
        testangle = astropy.coordinates.get_body(planetname, time).transform_to(astropy.coordinates.HeliocentricTrueEcliptic).lon.degree
        delta = relang(targetangle, testangle)
        if (delta < 0 and dir < 0) or (delta > 0 and dir > 0):
            step /= 2
            dir *= -1
        TOTSTEPS += 1
        if TOTSTEPS > 50:
            break
        
    return time

def to_gp(obj, color=(0.0193818, 0.258183, 0.64448, 1)):
    n = obj.name
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target='GPENCIL')
    gp = bpy.context.object
    gp.name = "GP_" + n
    gp.data.layers[0].use_lights = False
    for p in gp.data.layers[0].frames[0].strokes[0].points:
        p.pressure = 4
        p.vertex_color = color


     
def make_planet(planetname):
    teststep = datetime.timedelta(days=10)
    skypos = astropy.coordinates.get_body(planetname, now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    skypos2 = astropy.coordinates.get_body(planetname, now + teststep).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    angle = skypos2.lon.degree - skypos.lon.degree
    alnge = (angle + 360) % 360
    totsteps = 360 / angle
    tottime = totsteps * teststep
    skypos2 = astropy.coordinates.get_body(planetname, now + tottime).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    endtime = bisectang(planetname, now + tottime, skypos.lon.degree, tottime / 24)
    tottime = endtime - now

    obj = bpy.data.objects.new(planetname, None)
    obj.location = Vector(skypos.cartesian.xyz.to(u.au).value)
    obj.empty_display_size = 0.1
    moonscene.collection.objects.link(obj)

    # LABEL
    curve = bpy.data.objects.new(planetname + "_label", bpy.data.curves.new(planetname + "_label", "CURVE"))
    curve.location = obj.location
    moonscene.collection.objects.link(curve)
    spline = curve.data.splines.new("BEZIER")
    spline.bezier_points.add(1)
    spline.bezier_points[0].co = Vector( [0, 0, 0] )
    spline.bezier_points[1].co = Vector( [0, 0, 0.05] )
    to_gp(curve, color=(0.0193818, 0.258183, 0.64448, 1))
    
    # ORBIT
    obj = bpy.data.objects.new(planetname + "_orbit", bpy.data.curves.new(planetname + "_orbit", "CURVE"))
    curve = obj.data
    moonscene.collection.objects.link(obj)
    spline = curve.splines.new("BEZIER")
    POINTS = 24
    spline.bezier_points.add(POINTS)
    
    timestep =  tottime.datetime / POINTS
    for i in range(0, POINTS + 1):
        skypos = astropy.coordinates.get_body(planetname, now + i * timestep).transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
        spline.bezier_points[i].co = Vector(skypos.cartesian.xyz.to(u.au).value)
        spline.bezier_points[i].handle_left_type = 'AUTO'
        spline.bezier_points[i].handle_right_type = 'AUTO'

    to_gp(obj, color=(0.651406, 0.0368892, 0.223228, 1))
    

    

# clear out the old!
for i in bpy.data.curves:
    bpy.data.curves.remove(i, do_unlink=True)

#bpy.context.view_layer.objects.active = bpy.data.objects['Earth.001']
#bpy.ops.object.convert(target='GPENCIL')

# Add moon trajectory path
make_planet("Mercury")
make_planet("Venus")
make_planet("Earth")
make_planet("Mars")
make_planet("Jupiter")
make_planet("Saturn")
make_planet("Uranus")
make_planet("Neptune")
astropy.coordinates.solar_system_ephemeris.set("https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de440.bsp")
make_planet("Pluto")

#POINTS = 7
#TIMESPAN = datetime.timedelta(seconds=300)

spicaicrs = astropy.coordinates.SkyCoord(ra=201.29824736*u.deg, dec=-11.16131948*u.deg, distance=260.9*u.lightyear)
spicapos = spicaicrs.transform_to(astropy.coordinates.GeocentricTrueEcliptic)
print(spicapos)
spicavec = Vector(spicapos.cartesian.xyz.to(u.au).value)
print(spicavec)
spicavec.length = 10
print(spicavec)

chitra = bpy.data.objects.new("Chitra", bpy.data.curves.new("Chitra", "CURVE"))
curve = chitra.data
moonscene.collection.objects.link(chitra)
spline = curve.splines.new("BEZIER")
POINTS = 24
spline.bezier_points.add(1)
spline.bezier_points[0].co = Vector( [0, 0, 0] )
spline.bezier_points[1].co = spicavec
chitra.location = bpy.data.objects["Earth"].location
to_gp(chitra, color=(0, 0, 0, 0),)

# Camera
cam = make_camera("Cam", lens_unit='FOV', angle=0.888, clip_end=500,
                         object_props={'location': 3.8 * bpy.data.objects['Earth'].location})
moonscene.camera = cam
cam.location.z = 0.4
# make sun track the moon
c = bpy.data.objects['Cam'].constraints.new("TRACK_TO")
c.target = bpy.data.objects['Sun']


    

#moonscene.collection.objects.link(
#    bpy.data.objects.new("Moon Trajectory", bpy.data.curves.new('Moon Trajectory', "CURVE")))
#spline = bpy.data.curves['Moon Trajectory'].splines.new("BEZIER")
#spline.bezier_points.add(POINTS -1)

"""
for i in range(POINTS):
    time = now - (TIMESPAN / 2) + (TIMESPAN / POINTS) * (i + 0.5)

    moonaltaz = get_moon(time).transform_to(AltAz(obstime=time, location=gothenburg_el))
    alt_delta = moonaltaz.alt - moon_altaz_now.alt
    az_delta = moonaltaz.az - moon_altaz_now.az
    dist_delta = moonaltaz.distance - moon_altaz_now.distance
    dist_delta = dist_delta.to(u.Mm).value
    print(az_delta.degree, alt_delta.degree, moonaltaz.distance.to(u.km))

    pathobj = bpy.data.objects.new("Moon Path " + str(i), None)
#    pathobj.empty_display_size = 0.05
#    moonscene.collection.objects.link(pathobj)

    M = (
        Matrix.Translation(observervec) @
        Matrix.Rotation(alt_delta.rad, 4, rotaxis_alt) @
        Matrix.Rotation(az_delta.rad, 4, rotaxis_az) @
#        Matrix.Diagonal( (1,) * 3).to_4x4() @
        Matrix.Translation(moon_obj.location - observervec) )

    pathobj.matrix_world = M @ pathobj.matrix_world
    spline.bezier_points[i].co = pathobj.location - moon_obj.location
    spline.bezier_points[i].handle_left_type = 'AUTO'
    spline.bezier_points[i].handle_right_type = 'AUTO'

    print(spline.bezier_points[i].co)
"""
