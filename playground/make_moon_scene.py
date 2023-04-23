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

def create_plane_easy():
    bpy.ops.mesh.primitive_plane_add(
        size=1, align='WORLD',
        location=(0, 0, 0),
        rotation=(pi/2, 0, 0))
    moon_obj = bpy.context.active_object
    moon_obj.name="Moon"
    bpy.ops.transform.resize(value=(2, 1, 1), **transform_opts)
    return moon_obj

def create_plane_noops():
    mesh=bpy.data.meshes.new("Moonmesh")
    mesh.from_pydata( 
        (( -2, 0, -1), (2, 0, -1), (2, 0, 1), (-2, 0, 1),
         (  0, 0, -1), (0, 0, 1)),
        (),
        ((0, 4, 5, 3), (4, 1, 2, 5)) )
    o = bpy.data.objects.new("Moon", mesh)
    bpy.context.collection.objects.link(o)
    return o

def apply_mods(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    object_eval = obj.evaluated_get(depsgraph)
    mesh_from_eval = bpy.data.meshes.new_from_object(object_eval)
    obj.modifiers.clear()
    obj.data = mesh_from_eval

def get_center(obj):
#    mean length
#    lengths=[v.co.length for v in obj.data.vertices]
#    return sum(lengths) / len(lengths)
    sum = Vector( (0, 0, 0) )
    for v in obj.data.vertices:
        sum += v.co
    return sum / len(obj.data.vertices)
     
def add_mod(obj, name, type, opts):
    mod = obj.modifiers.new(name, type)
    for key, val in opts.items():
        setattr(mod, key, val)

moon_radius=1.7371
moon_diameter = 2 * moon_radius

# clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

origin_obj = bpy.data.objects.new("Origin", None)
bpy.context.collection.objects.link(origin_obj)


moon_obj = create_plane_noops()

# create the UV map (have to use bmesh i guess...)
bm = bmesh.new()
bm.from_mesh(moon_obj.data)
uv_layer = bm.loops.layers.uv.verify()
uv_scale  = Vector( (0.25, 0.5) )
uv_offset = Vector( (0.5, 0.5) )
for face in bm.faces:
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

"""
print("----")
print(moon_obj.dimensions)
print(moon_obj.dimensions/moon_radius)
moon_obj.dimensions=Vector((moon_diameter, moon_diameter, moon_diameter))

bpy.context.view_layer.objects.active = moon_obj
bpy.ops.object.select_pattern(pattern="Moon")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
#bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_MASS', center='MEDIAN')

print(get_center(moon_obj))
"""
# translate the verticies so the origin is in the middle of the sphere
for v in moon_obj.data.vertices:
    v.co += Vector( (0, -moon_radius, 0) )
    
print(get_center(moon_obj))
moon_obj.location = Vector( (0, 0, 0) )

# Material
mat = bpy.data.materials.new(name='Moon Surface')
mat.use_nodes=True
moon_obj.data.materials.append(mat)

mat_nodes = mat.node_tree.nodes


bsd=mat_nodes["Principled BSDF"]
bsd.inputs["Base Color"]

colors_img = bpy.data.images.load("/home/hlofving/Downloads/MoonColorMap.png")
height_img = bpy.data.images.load("/home/hlofving/Downloads/MoonReliefMap.png")

colors_input_node = mat_nodes.new("ShaderNodeTexImage")
colors_input_node.location = bsd.location + Vector ( ( -300, 0 ) )
colors_input_node.image=colors_img

# bpy.data.images['MoonReliefMap.png'].filepath="/home/hlofving/Downloads/MoonColorMap.png"

height_input_node=mat_nodes.new("ShaderNodeTexImage")
height_input_node.location = bsd.location + Vector ( ( -600, -300 ) )
height_input_node.image=height_img
vector_disp_node=mat_nodes.new("ShaderNodeVectorDisplacement")
vector_disp_node.location = bsd.location + Vector ( ( -300, -300 ) )
vector_disp_node.inputs["Scale"].default_value = 0.01

mat.node_tree.links.new(colors_input_node.outputs["Color"], bsd.inputs['Base Color'])
mat.node_tree.links.new(vector_disp_node.outputs["Displacement"], mat_nodes["Material Output"].inputs['Displacement'])
mat.node_tree.links.new(height_input_node.outputs["Color"], vector_disp_node.inputs['Vector'])

bpy.ops.object.light_add(type='SUN', radius=1, align='WORLD', location=(0, -10, 0), scale=(1, 1, 1))

