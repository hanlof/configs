import bpy
from math import pi, tau, radians, inf
from mathutils import Vector, Matrix
import bmesh

import math

import sys
import mathutils
import astropy
import astropy.coordinates
from astropy.coordinates import get_body, get_sun, get_moon, EarthLocation, Longitude, Latitude, GCRS
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
    for w in bpy.data.curves:
        bpy.data.grease_pencils.remove(w, do_unlink=True)
    for w in bpy.data.collections:
        bpy.data.collections.remove(w, do_unlink=True)


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
    bpy.context.scene.collection.objects.link(o)
    return o

def create_plane_noops():
    mesh=bpy.data.meshes.new("Moonmesh")
    #mesh.use_auto_smooth = True
    mesh.from_pydata(
        (( -2, 0, -1), (2, 0, -1), (2, 0, 1), (-2, 0, 1), ( 0, 0, -1), (0, 0, 1)),
        (),
        ((0, 4, 5, 3), (4, 1, 2, 5)) )
    o = bpy.data.objects.new("Moon", mesh)
    bpy.context.scene.collection.objects.link(o)
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
    'camfov': 0.7,
    'resx': 1024,
    'resy': 1024,
    'sunstr': 7.5,
    'colormap': '/home/hlofving/Downloads/lroc_color_poles_4k.tif',
    'heightmap': '/home/hlofving/Downloads/ldem_16_uint.tif',
    'skip_drivers': False, }

# TODO: clear world data from scene
# TODO: adjust sun strength
# TODO: add earthlight
# TODO: switch to proper height displacement mesh
# TODO: adjust bump map to scale the height correctly
# TODO: probably use linear colorspace for bump map?!
# TODO: get the shading/colors correct

moonscene = bpy.context.scene

moonprops = default_props
if 'moon_params' in moonscene:
    moonprops.update(moonscene['moon_params'])

print(moonprops)

moonscene.render.film_transparent = True
moonscene.render.resolution_x = moonprops['resx']
moonscene.render.resolution_y = moonprops['resy']
    
clear_scene()

# Camera
cam = make_camera("Earth Viewpoint", lens_unit='FOV', angle=radians(moonprops['camfov']), clip_end=500,
                      object_props={'location': Vector( (0, 0, 0) )})
moonscene.camera = cam

# Origin (center of earth)
origin_obj = bpy.data.objects.new("Origin", None)
origin_obj.empty_display_size = 0.05
moonscene.collection.objects.link(origin_obj)

origin_obj = bpy.data.objects.new("Observer Location", None)
origin_obj.empty_display_size = 0.05
moonscene.collection.objects.link(origin_obj)

origin_obj = bpy.data.objects.new("Observer Down Point", None)
origin_obj.empty_display_size = 0.05
moonscene.collection.objects.link(origin_obj)

origin_obj = bpy.data.objects.new("Moon North", None)
origin_obj.empty_display_size = 0.05
moonscene.collection.objects.link(origin_obj)

origin_obj = bpy.data.objects.new("Moon East", None)
origin_obj.empty_display_size = 0.05
moonscene.collection.objects.link(origin_obj)

# Moon object
moon_obj = create_plane_noops()
#moon_obj.data.use_auto_smooth = True
make_uv_from_faces(moon_obj)
add_mod(moon_obj, "Subsurf", "SUBSURF",
    { 'subdivision_type': 'SIMPLE', 'levels': 6, 'render_levels': 6 } )
add_mod(moon_obj, "Bend X", "SIMPLE_DEFORM",
    { 'deform_axis': 'X', 'deform_method': 'BEND', 'origin': origin_obj, 'angle': pi } )
add_mod(moon_obj, "Bend Z", "SIMPLE_DEFORM",
    { 'deform_axis': 'Z', 'deform_method': 'BEND', 'origin': origin_obj, 'angle': tau } )
apply_mods(moon_obj)
offset = get_center(moon_obj) # center verticies around object origin
for v in moon_obj.data.vertices:
    v.co -= offset
    v.co.length = moon_radius

# Material
moonmat = bpy.data.materials.new(name = 'Moon Surface')
moon_obj.data.materials.append(moonmat)


moonmat.use_nodes = True # This is a magic operator which creates a node tree with a principled BSDF...

mat_nodes = moonmat.node_tree.nodes
clear_nodes(mat_nodes)

mynodes = {
    0: mat_nodes.new("ShaderNodeOutputMaterial"),
    1: mat_nodes.new("ShaderNodeBsdfPrincipled"),
    2: mat_nodes.new("ShaderNodeTexImage"),
    3: mat_nodes.new("ShaderNodeTexImage"),
    4: mat_nodes.new("ShaderNodeBump") }

mynodes[0].name = "Material Output"
mynodes[0].is_active_output = True

#mynodes[1].inputs["Specular"].default_value = 1
mynodes[1].inputs["Roughness"].default_value = 1
mynodes[1].location = mynodes[0].location + Vector ( ( -300, 0 ) )

mynodes[2].location = mynodes[1].location + Vector ( ( -300, 0 ) )
mynodes[2].image = bpy.data.images.load(moonprops['colormap'])
mynodes[2].label = "Moon Color Image"

mynodes[3].location = mynodes[1].location + Vector ( ( -600, -300 ) )
mynodes[3].image = bpy.data.images.load(moonprops['heightmap'])
mynodes[3].label = "Moon Height Map"

mynodes[4].location = mynodes[1].location + Vector ( ( -300, -300 ) )
mynodes[4].inputs["Strength"].default_value = 0.10

moonmat.node_tree.links.new(mynodes[2].outputs["Color"],  mynodes[1].inputs['Base Color'])
moonmat.node_tree.links.new(mynodes[4].outputs["Normal"], mynodes[1].inputs['Normal'])
moonmat.node_tree.links.new(mynodes[3].outputs["Color"],  mynodes[4].inputs['Height'])
moonmat.node_tree.links.new(mynodes[1].outputs["BSDF"],   mynodes[0].inputs['Surface'])

# Light
moonscene.collection.objects.link(bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")))
bpy.data.lights["Sun"].energy = moonprops['sunstr']
bpy.data.lights["Sun"].angle = 0

moonscene.collection.objects.link(bpy.data.objects.new("Earthlight", bpy.data.lights.new("Earthlight", "SUN")))
bpy.data.lights["Earthlight"].energy = 0.1
bpy.data.lights["Earthlight"].angle = 0

# updating positions!

bodycache = {}
def gcrs_from_bodylocation(body, time, unit):
    key = (body, time, unit)
    if key in bodycache: return bodycache[key]
    time = astropy.time.Time(time, format="jd")
    bodycache[key] = Vector(get_body(body, time).cartesian.xyz.to(unit).value)
    return bodycache[key]

elcache = {}
def gcrs_from_earthlocation(time, height=0):
    key = (time, height)
    if key in elcache: return elcache[key]
    time = astropy.time.Time(time, format="jd")
    height = height * u.m
    el = EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=height)
    elcache[key] = Vector(el.get_gcrs(time).cartesian.without_differentials().xyz.to(u.Mm).value)
    return elcache[key]

mlcache = {}
def gcrs_from_moonlocation(lon, lat, time):
    key = (lon, lat, time)
    if key in mlcache: return mlcache[key]
    time = astropy.time.Time(time, format="jd")
    ml = MoonLocation(Longitude(lon * u.deg), Latitude(lat * u.deg)).get_mcmf(obstime=time).transform_to(GCRS(obstime=time))
    mlcache[key] = Vector(ml.cartesian.without_differentials().xyz.to(u.Mm).value)
    return mlcache[key]

# find coordinates for sun, moon, gbg
now = astropy.time.Time(datetime.datetime.utcnow())
sunvec = gcrs_from_bodylocation("Sun", now.jd, u.au)
moonvec = gcrs_from_bodylocation("Moon", now.jd, u.Mm)
observervec = gcrs_from_earthlocation(now.jd)
observer_down_vec=Vector( (0, 0, 0) )

# Update placeholders for moons position
moon_north_vec = gcrs_from_moonlocation(0, 90, now)
moon_east_vec = gcrs_from_moonlocation(90, 0, now)

gothenburg_el = EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)

bpy.data.objects["Sun"].location = moonvec + (sunvec * 10)
bpy.data.objects["Earthlight"].location = origin_obj.location
bpy.data.objects['Moon'].location = moonvec
bpy.data.objects["Moon North"].location = moon_north_vec
bpy.data.objects["Moon East"].location = moon_east_vec
bpy.data.objects["Observer Location"].location = observervec
bpy.data.objects["Observer Down Point"].location = observer_down_vec

# make sun track the moon
c = bpy.data.objects['Sun'].constraints.new("TRACK_TO")
c.target = bpy.data.objects['Moon']

# make earthlight track the moon
c = bpy.data.objects['Earthlight'].constraints.new("TRACK_TO")
c.target = bpy.data.objects['Moon']

# align a helper axis from earth center to the observer
c = bpy.data.objects['Observer Down Point'].constraints.new("TRACK_TO")
c.target = bpy.data.objects["Observer Location"]
c.up_axis = 'UP_X'
c.track_axis = 'TRACK_Y'

# make camera "up" vector align with earth center
c = cam.constraints.new("COPY_LOCATION")
c.target = bpy.data.objects['Observer Location']

c = cam.constraints.new("TRACK_TO")
c.target = bpy.data.objects['Observer Down Point']
c.track_axis = 'TRACK_NEGATIVE_Y'
c.up_axis = 'UP_X'
c = cam.constraints.new("LOCKED_TRACK")
c.target = bpy.data.objects['Moon']
c.track_axis = 'TRACK_NEGATIVE_Z'
c.lock_axis = 'LOCK_Y'
c = cam.constraints.new("LOCKED_TRACK")
c.target = bpy.data.objects['Moon']
c.track_axis = 'TRACK_NEGATIVE_Z'
c.lock_axis = 'LOCK_X'

# adjust the moons rotation with the help of north and east point
c = moon_obj.constraints.new("LOCKED_TRACK")
c.target = bpy.data.objects['Moon North']
c.track_axis = 'TRACK_Z'
c.lock_axis = 'LOCK_X'
c = moon_obj.constraints.new("LOCKED_TRACK")
c.target = bpy.data.objects['Moon East']
c.track_axis = 'TRACK_X'
c.lock_axis = 'LOCK_Z'


# Add moon trajectory path
def get_moon_trajectory_coords(nowtime, delta_time, points_on_each_side):
    """Returns a list of moon positions relative to @param nowtime"""
    camdirection = moon_obj.location - observervec
    rotaxis_alt = camdirection.cross(observervec)
    rotaxis_az = Vector(observervec)
    rotaxis_az.negate() # get the correct positive rotation orientation

    moon_altaz_now = get_moon(now).transform_to(AltAz(obstime=now, location=gothenburg_el))

    coordlist = list()
    POINTS = 1 + points_on_each_side * 2
    TIMESPAN = delta_time
    for i in range(POINTS):
        time = now - (TIMESPAN / 2) + (TIMESPAN / POINTS) * (i + 0.5)
        moonaltaz = get_moon(time).transform_to(AltAz(obstime=time, location=gothenburg_el))
        alt_delta = moonaltaz.alt - moon_altaz_now.alt
        az_delta = moonaltaz.az - moon_altaz_now.az
        dist_delta = moonaltaz.distance - moon_altaz_now.distance
        dist_delta = dist_delta.to(u.Mm).value
        #print(az_delta.degree, alt_delta.degree, moonaltaz.distance.to(u.km))

        M = (
          # Matrix.Diagonal( (1,) * 3).to_4x4() @ # Scaling can be fun?!
            Matrix.Translation(observervec) @
            Matrix.Rotation(alt_delta.rad, 4, rotaxis_alt) @
            Matrix.Rotation(az_delta.rad, 4, rotaxis_az) @
            Matrix.Translation(moon_obj.location - observervec) )

        pointcoords = (M @ Vector( [0, 0, 0] )) - moon_obj.location
        coordlist.append(pointcoords)
    return coordlist

# clear out the old!
for i in bpy.data.curves:
    bpy.data.curves.remove(i, do_unlink=True)

def make_curve():
    moonscene.collection.objects.link(
        bpy.data.objects.new("Moon Trajectory", bpy.data.curves.new('Moon Trajectory', "CURVE")))
    bpy.data.objects['Moon Trajectory'].location = moon_obj.location
    spline = bpy.data.curves['Moon Trajectory'].splines.new("BEZIER")
    spline.bezier_points.add(POINTS -1)
#    spline.bezier_points[i].co = pathobj.location - moon_obj.location
#    spline.bezier_points[i].handle_left_type = 'AUTO'
#    spline.bezier_points[i].handle_right_type = 'AUTO'

# bpy.context.object.data.pixel_factor = 30

# Clear out the old grease pencils
for i in bpy.data.grease_pencils:
    bpy.data.grease_pencils.remove(i, do_unlink=True)

gpencil_data = bpy.data.grease_pencils.new("Moon Trajectory")
gpencil = bpy.data.objects.new(gpencil_data.name, gpencil_data)
gpencil.location =  moon_obj.location
bpy.context.scene.collection.objects.link(gpencil)
gp_layer = gpencil_data.layers.new("lines")
gp_layer.use_lights = False
gp_layer.opacity = 1.0
gp_frame = gp_layer.frames.new(bpy.context.scene.frame_current)
gp_stroke = gp_frame.strokes.new()
gp_stroke.line_width = 12
gp_stroke.start_cap_mode = 'ROUND'
gp_stroke.end_cap_mode = 'ROUND'
gp_stroke.use_cyclic = False


def add_gp_stroke(gpf, points, s_attr, p_attr):
    gp_stroke = gpf.strokes.new()
    for n, v in s_attr.items():
        setattr(gp_stroke, n, v)
    gp_stroke.points.add(len(points))
    for i, p in enumerate(points):
        gp_stroke.points[i].co = p
        for n, v in p_attr.items():
            setattr(gp_stroke.points[i], n, v)
    return gp_stroke
tc = get_moon_trajectory_coords(now, datetime.timedelta(seconds=300), 3)
gp_stroke.points.add(len(tc))
for i, value in enumerate(tc):
    gp_stroke.points[i].co = value
    gp_stroke.points[i].pressure = 0.5
    gp_stroke.points[i].vertex_color = (0.0193818, 0.258183, 0.64448, 1)


# moon location indicator
gpencil_data = bpy.data.grease_pencils.new("Moon Position")
gpencil = bpy.data.objects.new(gpencil_data.name, gpencil_data)
bpy.context.scene.collection.objects.link(gpencil)
gp_layer = gpencil_data.layers.new("lines")
gp_layer.use_lights = False
gp_layer.opacity = 1.0
gp_frame = gp_layer.frames.new(bpy.context.scene.frame_current)

ofs = Vector( [0, 0.5, 0] )
pts = [
    Vector( [0,  1, 0] ),
    Vector( (-1, .3, 0) ),
    Vector( (0, .6, 0) ), ]
pts2=[p * 0.05 + ofs for p in pts]
add_gp_stroke(gp_frame, pts2, {'use_cyclic': False }, { } )
pts = [
    Vector( [0,  1, 0] ),
    Vector( (1,  .3, 0) ),
    Vector( (0, .6, 0) ), ]
pts2=[p * 0.05 + ofs for p in pts]
add_gp_stroke(gp_frame, pts2, {'use_cyclic': False }, { } )

mat = bpy.data.materials.new(name="GP_Arrow")
bpy.data.materials.create_gpencil_data(mat)
gpencil.data.materials.append(mat)
mat.grease_pencil.show_fill = True
mat.grease_pencil.show_stroke = False
mat.grease_pencil.fill_color = (0.14996, 0.165132, 0.552011, 1) # Solarized purple

w = get_moon(now).transform_to(AltAz(obstime=now, location=gothenburg_el))
angle = math.atan2(math.sin(w.alt.rad), math.sin(w.az.rad))

gpencil.parent = bpy.data.objects['Earth Viewpoint']
gpencil.location = Vector( [0, 0, -100] )
gpencil.rotation_euler = Vector( [0, 0, angle - math.pi / 2] )




"""
mat = bpy.data.materials.new(name="Black")
bpy.data.materials.create_gpencil_data(mat)
gpencil.data.materials.append(mat)

mat.grease_pencil.show_fill = False
mat.grease_pencil.fill_color = (1.0, 0.0, 1.0, 1.0)
"""
#mat.grease_pencil.color = (0.0193818, 0.258183, 0.64448, 1) # solarized blue

bpy.context.scene.view_layers["ViewLayer"].use_pass_z = True # needed for grease pencil

#def jdn():
#    return astropy.time.Time(datetime.datetime.utcnow()).jd
#bpy.app.driver_namespace['jdn'] = jdn

#what = moonscene.id_properties_ui('jdn')
#what.update(min=0, step=1)

bpy.app.driver_namespace['gcrs_from_bodylocation'] = gcrs_from_bodylocation
bpy.app.driver_namespace['gcrs_from_earthlocation'] = gcrs_from_earthlocation
bpy.app.driver_namespace['gcrs_from_moonlocation'] = gcrs_from_moonlocation
bpy.app.driver_namespace['u'] = u

def make_jd_based_location_driver(obj, expr):
    curves=obj.driver_add("location")
    for fc, axis in zip(curves, ('x', 'y', 'z')):
        fc.driver.type="SCRIPTED"
        v = fc.driver.variables.new()
        v.name = "jd1"
        v.type = "SINGLE_PROP"
        v.targets[0].id_type = 'SCENE'
        v.targets[0].id = bpy.data.scenes['Scene']
        v.targets[0].data_path = 'jd1'
        v=fc.driver.variables.new()
        v.name = "jd2"
        v.type = "SINGLE_PROP"
        v.targets[0].id_type = 'SCENE'
        v.targets[0].id = bpy.data.scenes['Scene']
        v.targets[0].data_path = 'jd2'
        fc.driver.expression="%s.%s" % (expr, axis)

# set camera view in outliner
def set_camera_view():
    for area in bpy.context.screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces[0].region_3d.view_perspective = 'CAMERA'
            break


set_camera_view()
#import calendar_widget
#calendar_widget.register()

class MySettings(bpy.types.PropertyGroup):
    my_bool: bpy.props.BoolProperty()
    my_int: bpy.props.IntProperty()
    my_float: bpy.props.FloatProperty()

bpy.utils.register_class(MySettings)
bpy.types.Scene.my_tool = bpy.props.PointerProperty(type=MySettings)

class SCENE_PT_moon(bpy.types.Panel):
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "scene"
    bl_label = "Moon"
    def draw(self, context):
        layout = self.layout
        layout.use_property_split = True
        scene = context.scene
        layout.prop(scene, "jd1")
        layout.prop(scene, "jd2")
        #layout.prop(scene, scene.my_tool.my_int)

bpy.types.Scene.jd1 = bpy.props.FloatProperty(
    int(astropy.time.Time(datetime.datetime.utcnow()).jd1),
    min = 0,
    soft_min = 0,
    max = inf,
    soft_max = inf,
    step = 1,
    precision = 0
)

# TODO: when adjusted above or below min/max it should increase jd1
bpy.types.Scene.jd2 = bpy.props.FloatProperty(
    astropy.time.Time(datetime.datetime.utcnow()).jd2,
    min = 0,
    soft_min = 0,
    max = 1,
    soft_max = 1,
    step = 1,
    precision = 6
)

moonscene['jd1'] = astropy.time.Time(datetime.datetime.utcnow()).jd1
moonscene['jd2'] = astropy.time.Time(datetime.datetime.utcnow()).jd2

classes = [ SCENE_PT_moon ]
from bpy.utils import register_class
for cls in classes:
        register_class(cls)

if moonprops['skip_drivers']:
    print("Skipping drivers")
else:
    make_jd_based_location_driver(bpy.data.objects['Sun'], 'gcrs_from_bodylocation("Sun", jd1 + jd2, u.Mm)')
    make_jd_based_location_driver(bpy.data.objects['Moon'], 'gcrs_from_bodylocation("Moon", jd1 + jd2, u.Mm)')
    make_jd_based_location_driver(bpy.data.objects['Moon North'], 'gcrs_from_moonlocation(0, 90, jd1 + jd2)')
    make_jd_based_location_driver(bpy.data.objects['Moon East'], 'gcrs_from_moonlocation(90, 0, jd1 + jd2)')
    make_jd_based_location_driver(bpy.data.objects['Observer Location'], 'gcrs_from_earthlocation(jd1 + jd2)')
