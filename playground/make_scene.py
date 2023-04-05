import sys
print(sys.path)
import bpy
import mathutils
import astropy
import astropy.coordinates
import astropy.units as u
import datetime
import lunarsky

# find coordinates for sun, moon, gbg
now = astropy.time.Time(datetime.datetime.utcnow())
#now = astropy.time.Time(datetime.datetime(2023, 4, 2, 19, 0, 0 ))

# TODO: create nothing in the script. let all objects and tracking be in the .blend but set their locations in here.
# TODO: embed the script in the .blend

# TODO: make a minimal .blend without textures
# TODO: make script for downloading textures / displacement map


gothenburg_a = astropy.coordinates.EarthLocation(lat=57.71788*u.deg, lon=11.93394*u.deg, height=80*u.m)
gothenburg_t = gothenburg_a.get_gcrs(now).cartesian.without_differentials().xyz.to(u.km).value
gothenburgvec = mathutils.Vector(gothenburg_t)
sun_a = astropy.coordinates.get_sun(now)
sunvec=mathutils.Vector(sun_a.cartesian.xyz.to(u.au).value)
moon_a = astropy.coordinates.get_moon(now)
moonvec=mathutils.Vector(moon_a.cartesian.xyz.to(u.km).value)

moonvec /= 1000
gothenburgvec /= 1000

print("Sun", sunvec, sunvec.length)
print("Moon", moonvec, moonvec.length)
print("Gothenburg", gothenburgvec, gothenburgvec.length)


bpy.data.objects['Moon'].location=moonvec
bpy.data.objects['Camera'].location=gothenburgvec

bpy.ops.object.light_add(type='SUN', radius=1, align='WORLD', location=(0, -10, 0), scale=(1, 1, 1))
sun = bpy.context.object
bpy.ops.object.constraint_add(type='TRACK_TO')
bpy.context.object.constraints["Track To"].target = bpy.data.objects["Moon"]
bpy.context.object.location = moonvec + (sunvec * 10)
bpy.context.object.data.energy = 8.4


# this arrow represents the direction from center of earth to tho position on earth (camera location)
# we track its Y axis to the camera keeping the X axis pointing "up" in the scene
# TODO: make another empty at gothenburg and track instead of the camera to avoid dependency cycles
bpy.ops.object.empty_add(type='SINGLE_ARROW', align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
bpy.ops.object.constraint_add(type='TRACK_TO')
bpy.context.object.constraints["Track To"].target = bpy.data.objects["Camera"]
bpy.context.object.constraints["Track To"].up_axis = 'UP_X'
bpy.context.object.constraints["Track To"].track_axis = 'TRACK_Y'

# make a camera at the observer location with really far clipping range and zoomed in to fit the moon
bpy.ops.object.select_camera()
bpy.context.object.data.clip_end = 500
bpy.context.object.data.lens = 3000

bpy.context.scene.render.resolution_x = 1024
bpy.context.scene.render.resolution_y = 1024

bpy.ops.object.constraint_add(type='TRACK_TO')
bpy.context.object.constraints["Track To"].target = bpy.data.objects["Empty"]
bpy.context.object.constraints["Track To"].track_axis = 'TRACK_NEGATIVE_Y'
bpy.context.object.constraints["Track To"].up_axis = 'UP_X'
bpy.ops.object.constraint_add(type='LOCKED_TRACK')
bpy.context.object.constraints["Locked Track"].target = bpy.data.objects["Moon"]
bpy.context.object.constraints["Locked Track"].lock_axis = 'LOCK_Y'
bpy.context.object.constraints["Locked Track"].track_axis = 'TRACK_NEGATIVE_Z'
bpy.ops.object.constraint_add(type='LOCKED_TRACK')
bpy.context.object.constraints["Locked Track.001"].target = bpy.data.objects["Moon"]
bpy.context.object.constraints["Locked Track.001"].lock_axis = 'LOCK_X'
bpy.context.object.constraints["Locked Track.001"].track_axis = 'TRACK_NEGATIVE_Z'

moon_north_pole = lunarsky.MoonLocation(astropy.coordinates.Longitude(0*u.deg), astropy.coordinates.Latitude(90*u.deg))
north_mcmf = moon_north_pole.get_mcmf(obstime=now)
north_gcrs = north_mcmf.transform_to(astropy.coordinates.GCRS(obstime=now))

north_vec = mathutils.Vector(north_gcrs.cartesian.without_differentials().xyz.to(u.km).value)

north_vec /= 1000

moon_east = lunarsky.MoonLocation(astropy.coordinates.Longitude(90*u.deg), astropy.coordinates.Latitude(0*u.deg))
east_mcmf = moon_east.get_mcmf(obstime=now)
east_gcrs = east_mcmf.transform_to(astropy.coordinates.GCRS(obstime=now))

north_vec = mathutils.Vector(north_gcrs.cartesian.without_differentials().xyz.to(u.km).value)
east_vec = mathutils.Vector(east_gcrs.cartesian.without_differentials().xyz.to(u.km).value)

north_vec /= 1000
east_vec /= 1000

# TODO: make just an empty point instead of arrows for moon locations
bpy.ops.object.empty_add(type='SINGLE_ARROW', align='WORLD', location=north_vec, scale=(10, 10, 10))
bpy.context.object.name = "Moon North Pole"

bpy.ops.object.empty_add(type='SINGLE_ARROW', align='WORLD', location=east_vec, scale=(10, 10, 10))
bpy.context.object.name = "Moon East"

moon = bpy.data.objects["Moon"]
moon.select_set(True)
bpy.context.view_layer.objects.active = moon

bpy.ops.object.constraint_add(type='LOCKED_TRACK')
bpy.context.object.constraints["Locked Track"].track_axis = 'TRACK_Z'
bpy.context.object.constraints["Locked Track"].target = bpy.data.objects["Moon North Pole"]
bpy.context.object.constraints["Locked Track"].lock_axis = 'LOCK_Y'
bpy.context.object.constraints["Locked Track"].lock_axis = 'LOCK_X'
bpy.ops.object.constraint_add(type='LOCKED_TRACK')
bpy.context.object.constraints["Locked Track.001"].target = bpy.data.objects["Moon East"]
bpy.context.object.constraints["Locked Track.001"].track_axis = 'TRACK_X'
bpy.context.object.constraints["Locked Track.001"].track_axis = 'TRACK_NEGATIVE_X'

bpy.ops.render.render(write_still=True)
