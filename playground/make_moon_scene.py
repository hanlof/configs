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
    'camfov': 0.7,
    'resx': 1024,
    'resy': 1024,
    'sunstr': 7.5,
    'colormap': '/home/hlofving/Downloads/lroc_color_poles_4k.tif',
    'heightmap': '/home/hlofving/Downloads/ldem_16_uint.tif', }

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

#print("This loop crashes sometimes.")
#for o in moonscene.collection.all_objects:
#    if o is not None:
#        bpy.data.objects.remove(o, do_unlink=True)

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
moon_obj.data.use_auto_smooth = True
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

mynodes[1].inputs["Specular"].default_value = 1
mynodes[1].inputs["Roughness"].default_value = 1
mynodes[1].location = mynodes[0].location + Vector ( ( -300, 0 ) )

mynodes[2].location = mynodes[1].location + Vector ( ( -300, 0 ) )
mynodes[2].image = bpy.data.images.load(moonprops['colormap'])
mynodes[2].label = "Moon Color Image"

mynodes[3].location = mynodes[1].location + Vector ( ( -600, -300 ) )
mynodes[3].image = bpy.data.images.load(moonprops['heightmap'])
mynodes[3].label = "Moon Height Map"

mynodes[4].location = mynodes[1].location + Vector ( ( -300, -300 ) )
mynodes[4].inputs["Strength"].default_value = 0.25

moonmat.node_tree.links.new(mynodes[2].outputs["Color"],  mynodes[1].inputs['Base Color'])
moonmat.node_tree.links.new(mynodes[4].outputs["Normal"], mynodes[1].inputs['Normal'])
moonmat.node_tree.links.new(mynodes[3].outputs["Color"],  mynodes[4].inputs['Height'])
moonmat.node_tree.links.new(mynodes[1].outputs["BSDF"],   mynodes[0].inputs['Surface'])

# Light
moonscene.collection.objects.link(bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")))
bpy.data.lights["Sun"].energy = moonprops['sunstr']
bpy.data.lights["Sun"].angle = 0


# updating positions!
now = astropy.time.Time(datetime.datetime.utcnow())

# find coordinates for sun, moon, gbg
sunvec = Vector(get_sun(now).cartesian.xyz.to(u.au).value)
moonvec = Vector(get_moon(now).cartesian.xyz.to(u.Mm).value)

gothenburg_el = EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)
observervec = Vector(gothenburg_el.get_gcrs(now).cartesian.without_differentials().xyz.to(u.Mm).value)
observer_down_vec=Vector( (0, 0, 0) )

# Update placeholders for moons position
moon_north_point = MoonLocation(Longitude(0*u.deg), Latitude(90*u.deg))
moon_north_gcrs = moon_north_point.get_mcmf(obstime=now).transform_to(GCRS(obstime=now))
moon_north_vec = Vector(moon_north_gcrs.cartesian.without_differentials().xyz.to(u.Mm).value)
moon_east_point = MoonLocation(Longitude(90*u.deg), Latitude(0*u.deg))
moon_east_gcrs = moon_east_point.get_mcmf(obstime=now).transform_to(GCRS(obstime=now))
moon_east_vec = Vector(moon_east_gcrs.cartesian.without_differentials().xyz.to(u.Mm).value)

#print("Sun", sunvec, sunvec.length)
#print("Moon", moonvec, moonvec.length)
#print("Observer", observervec, observervec.length)
#print("Moon North", moon_north_vec, moon_north_vec.length)
#print("Moon East", moon_east_vec, moon_east_vec.length)

bpy.data.objects["Sun"].location = moonvec + (sunvec * 10)
bpy.data.objects['Moon'].location = moonvec
bpy.data.objects["Moon North"].location = moon_north_vec
bpy.data.objects["Moon East"].location = moon_east_vec
bpy.data.objects["Observer Location"].location = observervec
bpy.data.objects["Observer Down Point"].location = observer_down_vec

# make sun track the moon
c = bpy.data.objects['Sun'].constraints.new("TRACK_TO")
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
camdirection = moon_obj.location - observervec
rotaxis_alt = camdirection.cross(observervec)
rotaxis_az = Vector(observervec)
rotaxis_az.negate() # get the correct positive rotation orientation

moon_altaz_now = get_moon(now).transform_to(AltAz(obstime=now, location=gothenburg_el))

POINTS = 7
TIMESPAN = datetime.timedelta(seconds=300)

# clear out the old!
for i in bpy.data.curves:
    bpy.data.curves.remove(i, do_unlink=True)

moonscene.collection.objects.link(
    bpy.data.objects.new("Moon Trajectory", bpy.data.curves.new('Moon Trajectory', "CURVE")))
bpy.data.objects['Moon Trajectory'].location = moon_obj.location
spline = bpy.data.curves['Moon Trajectory'].splines.new("BEZIER")
spline.bezier_points.add(POINTS -1)

# bpy.context.object.data.pixel_factor = 30


gpencil_data = bpy.data.grease_pencils.new("Moon Trajectory")
gpencil = bpy.data.objects.new(gpencil_data.name, gpencil_data)
bpy.context.collection.objects.link(gpencil)
gp_layer = gpencil_data.layers.new("lines")
gp_layer.use_lights = False
gp_layer.opacity = 0.5
gp_frame = gp_layer.frames.new(bpy.context.scene.frame_current)
gp_stroke = gp_frame.strokes.new()

gp_stroke.line_width = 12
gp_stroke.start_cap_mode = 'ROUND'
gp_stroke.end_cap_mode = 'ROUND'
gp_stroke.use_cyclic = False

gp_stroke.points.add(POINTS)

for i in range(POINTS):
    time = now - (TIMESPAN / 2) + (TIMESPAN / POINTS) * (i + 0.5)

    moonaltaz = get_moon(time).transform_to(AltAz(obstime=time, location=gothenburg_el))
    alt_delta = moonaltaz.alt - moon_altaz_now.alt
    az_delta = moonaltaz.az - moon_altaz_now.az
    dist_delta = moonaltaz.distance - moon_altaz_now.distance
    dist_delta = dist_delta.to(u.Mm).value
    print(az_delta.degree, alt_delta.degree, moonaltaz.distance.to(u.km))

    pathobj = bpy.data.objects.new("Moon Path " + str(i), None)

#    moonscene.collection.objects.link(pathobj)

    M = (
#        Matrix.Diagonal( (1,) * 3).to_4x4() @ # Scaling can be fun?!
        Matrix.Translation(observervec) @
        Matrix.Rotation(alt_delta.rad, 4, rotaxis_alt) @
        Matrix.Rotation(az_delta.rad, 4, rotaxis_az) @
        Matrix.Translation(moon_obj.location - observervec) )

    pathobj.matrix_world = M @ pathobj.matrix_world
#    spline.bezier_points[i].co = pathobj.location - moon_obj.location
    spline.bezier_points[i].handle_left_type = 'AUTO'
    spline.bezier_points[i].handle_right_type = 'AUTO'
    
    gp_stroke.points[i].co = pathobj.location - moon_obj.location
    gp_stroke.points[i].pressure = 1
    gp_stroke.points[i].vertex_color = (0.0193818, 0.258183, 0.64448, 0.5)


gpencil.location =  moon_obj.location
#pts = [(0.0, 0.0, -1.0), (0.0, 0.0, 1.0), (-1.0, 0.0, -0.5), (0.5, 0.0, -0.5)]
#for item, value in enumerate(pts):
#    gp_stroke.points[item].co = value

mat = bpy.data.materials.new(name="Black")
bpy.data.materials.create_gpencil_data(mat)
gpencil.data.materials.append(mat)

mat.grease_pencil.show_fill = False
mat.grease_pencil.fill_color = (1.0, 0.0, 1.0, 1.0)
mat.grease_pencil.color = (0.0193818, 0.258183, 0.64448, 1) # solarized blue

bpy.context.scene.view_layers["ViewLayer"].use_pass_z = True # needed for grease pencil

def jdn():
    return astropy.time.Time(datetime.datetime.now()).jd

moonscene['jdn'] = astropy.time.Time(datetime.datetime.now()).jd
what=moonscene.id_properties_ui('jdn')
what.update(min=0, step=1)
bpy.app.driver_namespace['jdn'] = jdn
