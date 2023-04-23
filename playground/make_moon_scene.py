import bpy
#import bpy.context
from math import pi, tau
from mathutils import Vector
import bmesh

#bpy.ops.object.mode_set(mode='OBJECT')
transform_opts = {
    'orient_type': 'GLOBAL',
    'orient_matrix': ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
    'orient_matrix_type': 'GLOBAL',
    'constraint_axis': (True, True, True),
    'mirror': False,
    'use_proportional_edit': False,
    'proportional_edit_falloff': 'SMOOTH',
    'proportional_size': 1,
    'use_proportional_connected': False,
    'use_proportional_projected': False }

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
     

moon_radius=1.7371
moon_diameter = 2 * moon_radius

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


# Origin 
origin_obj = bpy.data.objects.new("Origin", None)
bpy.context.collection.objects.link(origin_obj)

# Camera    
c=bpy.data.cameras.new("Earth Viewpoint")
o=bpy.data.objects.new("Earth Viewpoint", c)
o.location = Vector( (0, -10, 0) )
bpy.context.scene.camera = o
bpy.context.collection.objects.link(o)


moon_obj = create_plane_noops()
moon_obj.data.use_auto_smooth = True

# create the UV map (have to use bmesh i guess...)
bm = bmesh.new()
bm.from_mesh(moon_obj.data)
uv_layer = bm.loops.layers.uv.verify()
uv_scale  = Vector( (0.25, 0.5) )
uv_offset = Vector( (0.5, 0.5) )
for face in bm.faces:
    face.smooth = True
    for loop in face.loops:
        loop[uv_layer].uv = loop.vert.co.xz * uv_scale + uv_offset
bm.to_mesh(moon_obj.data)

add_mod(moon_obj, "Subsurf", "SUBSURF", \
    { 'subdivision_type': 'SIMPLE', 'levels': 6, 'render_levels': 6 } )
add_mod(moon_obj, "Bend X", "SIMPLE_DEFORM",
    { 'deform_axis': 'X', 'deform_method': 'BEND',
      'origin': bpy.data.objects['Origin'], 'angle': pi } )
add_mod(moon_obj, "Bend Z", "SIMPLE_DEFORM",
    { 'deform_axis': 'Z', 'deform_method': 'BEND',
      'origin': bpy.data.objects['Origin'], 'angle': tau } )
apply_mods(moon_obj)

# translate the verticies so the origin is in the middle of the sphere
offset = get_center(moon_obj)
for v in moon_obj.data.vertices:
    v.co -= offset
    v.co.length = moon_radius
    
# Material
mat = bpy.data.materials.new(name='Moon Surface')
mat.use_nodes=True
moon_obj.data.materials.append(mat)

mat_nodes = mat.node_tree.nodes

bsd=mat_nodes["Principled BSDF"]
bsd.inputs["Specular"].default_value = 1
bsd.inputs["Roughness"].default_value = 1


colors_input_node = mat_nodes.new("ShaderNodeTexImage")
colors_input_node.location = bsd.location + Vector ( ( -300, 0 ) )
colors_input_node.image=bpy.data.images.load("/home/hlofving/Downloads/MoonColorMap.png")

height_input_node=mat_nodes.new("ShaderNodeTexImage")
height_input_node.location = bsd.location + Vector ( ( -600, -300 ) )
height_input_node.image=bpy.data.images.load("/home/hlofving/Downloads/MoonReliefMap.png")

vector_disp_node=mat_nodes.new("ShaderNodeVectorDisplacement")
vector_disp_node.location = bsd.location + Vector ( ( -300, -300 ) )
vector_disp_node.inputs["Scale"].default_value = 0.02

mat.node_tree.links.new(colors_input_node.outputs["Color"], bsd.inputs['Base Color'])
mat.node_tree.links.new(vector_disp_node.outputs["Displacement"], mat_nodes["Material Output"].inputs['Displacement'])
mat.node_tree.links.new(height_input_node.outputs["Color"], vector_disp_node.inputs['Vector'])

bpy.ops.object.light_add(type='SUN', radius=1, align='WORLD', location=(0, -10, 0), scale=(1, 1, 1))
bpy.context.object.data.energy = 7
bpy.context.object.data.angle = 0

bpy.context.scene.render.film_transparent = True

