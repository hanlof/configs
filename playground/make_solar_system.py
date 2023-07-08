import bpy
from math import pi, tau, radians
from mathutils import Vector, Matrix
import bmesh

import sys
import mathutils
import astropy
import astropy.coordinates
from astropy.coordinates import get_sun, get_moon, EarthLocation, Longitude, Latitude, GCRS, ICRS, HeliocentricTrueEcliptic
from astropy.coordinates import AltAz
import astropy.units as u
import datetime
import lunarsky
from lunarsky import MoonLocation
from itertools import pairwise
import yaml

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

moonscene = bpy.context.scene

moonprops = default_props
if 'moon_params' in moonscene:
    moonprops.update(moonscene['moon_params'])

#for o in moonscene.collection.all_objects:
#    if o is not None:
#        bpy.data.objects.remove(o, do_unlink=True)

clear_scene()

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
    gp.data.stroke_thickness_space = 'SCREENSPACE'
    gp.data.layers[0].use_lights = False
    for p in gp.data.layers[0].frames[0].strokes[0].points:
        p.pressure = 0.1
        p.strength = 0.5
        p.vertex_color = color
    return gp

     
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

    # to_gp(obj, color=(0.651406, 0.0368892, 0.223228, 1))
    to_gp(obj, color=(0.0, 0.0, 1.0, 1))
    

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


def make_earth_marker(earthlocation, color=(0, 0, 0, 1)):
    elh = earthlocation.get_itrs(now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic(obstime=now))
    elvec = Vector(elh.cartesian.xyz.to(u.au).value)
    eldir = elvec - bpy.data.objects['Earth'].location
    eldir.length = 0.2

    curve = bpy.data.objects.new("EL", bpy.data.curves.new("EL", "CURVE"))
    curve.location = bpy.data.objects['Earth'].location
    moonscene.collection.objects.link(curve)
    spline = curve.data.splines.new("BEZIER")
    spline.bezier_points.add(1)
    spline.bezier_points[0].co = Vector( [0, 0, 0] )
    spline.bezier_points[1].co = eldir
    to_gp(curve, color=color)

# Get a bunch of earth related vectors
gbg = astropy.coordinates.EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)
en = astropy.coordinates.EarthLocation(lat=90*u.deg, lon=0*u.deg, height=80*u.m)
es = astropy.coordinates.EarthLocation(lat=-90*u.deg, lon=-0*u.deg, height=80*u.m)
ee = astropy.coordinates.EarthLocation(lat=0*u.deg, lon=90*u.deg, height=80*u.m)
#make_earth_marker(gbg, color=(1, 0, 0, 1))
#make_earth_marker(en, color=(1, 1, 1, 1))
#make_earth_marker(ee, color=(1, 1, 1, 1))
#make_earth_marker(es, color=(1, 1, 0, 1))

enh = en.get_itrs(now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic(obstime=now))
envec = Vector(enh.cartesian.xyz.to(u.au).value)
eeh = ee.get_itrs(now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic(obstime=now))
eevec = Vector(eeh.cartesian.xyz.to(u.au).value)
gbgh = gbg.get_itrs(now).transform_to(astropy.coordinates.HeliocentricTrueEcliptic(obstime=now))
gbgpos = Vector(gbgh.cartesian.xyz.to(u.au).value)

earth_up_vector = envec - bpy.data.objects['Earth'].location
gbg_up_vector = gbgpos - bpy.data.objects['Earth'].location
earth_up_vector.length = 1
gbg_up_vector.length = 1
gbgeast = earth_up_vector.cross(gbg_up_vector)
gbgeast.length = 1

earth_east_vector = eevec - bpy.data.objects['Earth'].location
gbgnorth = gbgeast.cross(gbg_up_vector)

earth_east_vector.length = 1
gbgnorth.length = 1

# Set up an empty at earths location with earths rotation/tilt
earthmarker = bpy.data.objects.new("Earthmarker", None)
earthmarker.location = bpy.data.objects['Earth'].location
earthmarker.empty_display_size = .2
moonscene.collection.objects.link(earthmarker)
# ROTATE Z
rotdiff = Vector( [0, 0, 1] ).rotation_difference(earth_up_vector)
earthmarker.rotation_euler.rotate(rotdiff)
# ROTATE X
(translation, rotation, scale) = earthmarker.matrix_world.decompose()
local_x = rotation @ Vector([1, 0, 0])
rotdiff = local_x.rotation_difference(earth_east_vector)
earthmarker.rotation_euler.rotate(rotdiff)

# Set up an empty at gbg location with gbg rotation/tilt
gbgmarker = bpy.data.objects.new("Gbgmarker", None)
gbgmarker.location = gbgpos
gbgmarker.empty_display_size = .2
moonscene.collection.objects.link(gbgmarker)
bpy.context.view_layer.update()
# ROTATE X
(translation, rotation, scale) = gbgmarker.matrix_world.decompose()
local_x = rotation @ Vector([1, 0, 0])
rotdiff = local_x.rotation_difference(gbgeast)
gbgmarker.rotation_euler.rotate(rotdiff)
bpy.context.view_layer.update()
# ROTATE Z
(translation, rotation, scale) = gbgmarker.matrix_world.decompose()
local_x = rotation @ Vector([0, 0, 1])
rotdiff = local_x.rotation_difference(gbg_up_vector)
gbgmarker.rotation_euler.rotate(rotdiff)



gbgeast.length = 0.1
gbgnorth.length = 0.1

# Gbg east west north south
curve = bpy.data.objects.new("Gbg", bpy.data.curves.new("Gbg", "CURVE"))
moonscene.collection.objects.link(curve)
spline = curve.data.splines.new("BEZIER")
spline.bezier_points.add(1)
spline.bezier_points[0].co = Vector( [0, 0, 0] )
spline.bezier_points[1].co = Vector( [.1, 0, 0] )
curve.parent = earthmarker
g=to_gp(curve, color=(1, 0, 1, .5) )
g.parent = gbgmarker
curve = bpy.data.objects.new("Gbg", bpy.data.curves.new("Gbg", "CURVE"))
moonscene.collection.objects.link(curve)
spline = curve.data.splines.new("BEZIER")
spline.bezier_points.add(1)
spline.bezier_points[0].co = Vector( [0, 0, 0] )
spline.bezier_points[1].co = Vector( [-.1, 0, 0] )
curve.parent = earthmarker
g=to_gp(curve, color=(1, 0, 1, .5) )
g.parent = gbgmarker
curve = bpy.data.objects.new("Gbg", bpy.data.curves.new("Gbg", "CURVE"))
moonscene.collection.objects.link(curve)
spline = curve.data.splines.new("BEZIER")
spline.bezier_points.add(1)
spline.bezier_points[0].co = Vector( [0, 0, 0] )
spline.bezier_points[1].co = Vector( [0, .1, 0] )
g=to_gp(curve, color=(1, 0, 1, .5) )
g.parent = gbgmarker
curve = bpy.data.objects.new("Gbg", bpy.data.curves.new("Gbg", "CURVE"))
moonscene.collection.objects.link(curve)
spline = curve.data.splines.new("BEZIER")
spline.bezier_points.add(1)
spline.bezier_points[0].co = Vector( [0, 0, 0] )
spline.bezier_points[1].co = Vector( [0, -.1, 0] )
g=to_gp(curve, color=(1, 0, 1, .5) )
g.parent = gbgmarker

def make_star_pointer(ra=0, dec=0, dist=10, col=(0, 0, 0, 0)):
    spicaicrs = astropy.coordinates.SkyCoord(ra=ra*u.deg, dec=dec*u.deg, distance=dist*u.lightyear)
    spicapos = spicaicrs.transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    spicavec = Vector(spicapos.cartesian.xyz.to(u.au).value)
    spicavec.length = 300

    starobj = bpy.data.objects.new("Star", bpy.data.curves.new("Star", "CURVE"))
    curve = starobj.data
    moonscene.collection.objects.link(starobj)
    spline = curve.splines.new("BEZIER")

    spline.bezier_points.add(1)
    spline.bezier_points[0].co = Vector( [0, 0, 0] )
    spline.bezier_points[1].co = spicavec
    starobj.location = bpy.data.objects["Earth"].location
    to_gp(starobj, color=col,)

def make_star_pointer_flat(ra=0, dec=0, dist=10, col=(0, 0, 0, 0)):
    spicaicrs = astropy.coordinates.SkyCoord(ra=ra*u.deg, dec=dec*u.deg, distance=dist*u.lightyear)
    spicapos = spicaicrs.transform_to(astropy.coordinates.HeliocentricTrueEcliptic)
    spicavec = Vector(spicapos.cartesian.xyz.to(u.au).value)
    spicavec.length = 300
    spicavec.z = 0

    starobj = bpy.data.objects.new("Star_ecl", bpy.data.curves.new("Star_ecl", "CURVE"))
    curve = starobj.data
    moonscene.collection.objects.link(starobj)
    spline = curve.splines.new("BEZIER")

    spline.bezier_points.add(1)
    spline.bezier_points[0].co = Vector( [0, 0, 0] )
    spline.bezier_points[1].co = spicavec
    starobj.location = bpy.data.objects["Earth"].location
    to_gp(starobj, color=col,)
    
# make_star_pointer(ra=201.29824736, dec=-11.16131948, dist=260.9) # Spica
# make_star_pointer_flat(ra=201.29824736, dec=-11.16131948, dist=260.9) # Spica
# make_star_pointer(ra=101.28715533, dec=-16.71611586, dist=8) # Sirius
# make_star_pointer(ra=279.23473479, dec=38.78368896, dist=25) # Vega
# make_star_pointer(ra=10.6847083, dec=41.26875, col=(0, 0, 1, 1) ) # Andromeda
# make_star_pointer(ra=266.41500889, dec=-29.00611111) # Galactic Center


# Camera
cam = make_camera("Cam", lens_unit='FOV', angle=radians(90), clip_end=500,
                         object_props={'location': 2.1 * bpy.data.objects['Earth'].location})

cam.location.z = 0.30
cam.data.shift_y = 0.1
cam.data.shift_x = -0.05
moonscene.camera = cam

# Track Sun
c = bpy.data.objects['Cam'].constraints.new("TRACK_TO")
c.target = bpy.data.objects['Sun']

# Background!



class Node(dict):
    aliases = dict()    
    _slot = 0
    def __rmatmul__(s, o):
        s._slot = o
        return s

class ShaderNodeOutputWorld(Node): pass
class ShaderNodeBackground(Node): pass
class ShaderNodeMix(Node): pass
class ShaderNodeTexImage(Node): pass
class ShaderNodeMapping(Node): pass
class ShaderNodeVectorRotate(Node): pass
class ShaderNodeVectorMath(Node): pass
class ShaderNodeTexCoord(Node): pass
class ShaderNodeReference(Node): pass

def makenode(nodetree, n, loc=Vector( [0, 0] )):
    if isinstance(n, ShaderNodeReference):
        return Node.aliases[n["_target"]]
    typestr = str(n.__class__).split("'")[-2].split(".")[-1]
    curnode = nodetree.nodes.new(type=typestr)
    loc = Vector( [loc.x - curnode.width - 20, loc.y] )
    curnode.location = Vector( [loc.x, loc.y] )
    for name, val in n.items():
        if name == "_alias":
            Node.aliases[val] = n, curnode
            continue
        obj = curnode
        attrname = name
        if name.startswith("input_"):
            inputidx = int(name.split("_")[-1])
            obj = curnode.inputs[inputidx]
            attrname = "default_value"
        if isinstance(val, Node):
            wrapper, childnode = makenode(nodetree, val, loc=Vector( [loc.x, loc.y] ) )
            print(childnode, childnode.height)
            loc = Vector( [loc.x, loc.y - childnode.height - 200] ) # XXX .height is always 100 as of version 3.5
            nodetree.links.new(childnode.outputs[wrapper._slot], obj)
        else:
            setattr(obj, attrname, val)
    return n, curnode


bg_correction = HeliocentricTrueEcliptic(lon=0*u.deg, lat=90*u.deg, distance=1*u.lyr).transform_to(ICRS)
ra, dec, dist = 201.29824736, -11.16131948, 260.9 # Spica
spicaicrs = astropy.coordinates.SkyCoord(ra=ra*u.deg, dec=dec*u.deg, distance=dist*u.lightyear)
spicapos = spicaicrs.transform_to(astropy.coordinates.HeliocentricTrueEcliptic)

world = bpy.data.worlds.new("Milky Way")
bpy.context.scene.world = world
world.use_nodes = True
nodes = bpy.context.scene.world.node_tree.nodes
links = bpy.context.scene.world.node_tree.links
for n in nodes: nodes.remove(n)

n = ShaderNodeOutputWorld(
    is_active_output = 1,
    input_0 = 0 @ ShaderNodeBackground(
        input_1 = 2.5,
        input_0 = 2 @ ShaderNodeMix(
            data_type = "RGBA", blend_type = "ADD", input_0 = .05,
            input_7 = 0 @ ShaderNodeTexImage(
                projection =  'SPHERE',
                image = bpy.data.images.load("/home/hlofving/signs_overlay.png"),
                input_0 = 0 @ ShaderNodeMapping(
                    vector_type = 'TEXTURE', input_3 = Vector( [-1, 1, 1] ),
                    input_0 = ShaderNodeVectorRotate(
                        rotation_type = 'EULER_XYZ', input_1 = Vector( [-0.5, 0.5, 0.5] ),
                        input_4 = Vector( [0, 0, (pi / 2) - spicapos.lon.rad] ),
                        input_0 = 0 @ ShaderNodeVectorMath(
                            operation = 'ADD',
                            input_1 = Vector( [-0.5, 0.5, 0.65] ),
                            input_0 = 0 @ ShaderNodeTexCoord() ) ) ) ),
            input_6 = 2 @ ShaderNodeMix(
                data_type = "RGBA", blend_type = "ADD", input_0 = 0,
                input_7 = 0 @ ShaderNodeTexImage(
                    projection =  'SPHERE',
                    image = bpy.data.images.load("/home/hlofving/Downloads/constellation_figures_4k.tif"),
                    input_0 = 0 @ ShaderNodeMapping( _alias="ICRS_CORRECTION",
                        vector_type = 'TEXTURE', input_3 = Vector( [-1, 1, 1] ),
                        input_0 = ShaderNodeVectorRotate(
                            rotation_type = 'EULER_XYZ', input_1 = Vector( [-0.5, 0.5, 0.5] ),
                            input_4 = Vector( [radians(90 - bg_correction.dec.deg), 0, -bg_correction.ra.rad] ),
                            input_0 = 0 @ ShaderNodeVectorMath(
                                operation = 'ADD', input_1 = Vector( [-0.5, 0.5, 0.5] ),
                                input_0 = 0 @ ShaderNodeTexCoord() ) ) ) ),
                input_6 = 0 @ ShaderNodeTexImage(
                    projection =  'SPHERE',
                    image = bpy.data.images.load("/home/hlofving/Downloads/starmap_2020_8k.exr"),
                    input_0 = 0 @ ShaderNodeReference(_target="ICRS_CORRECTION") ) ) ) ) )

makenode(bpy.context.scene.world.node_tree, n, loc=Vector( [0, -200] ) )

bpy.app.driver_namespace['links'] = links
bpy.app.driver_namespace['nodes'] = nodes
bpy.app.driver_namespace['mynodes'] = nodes
