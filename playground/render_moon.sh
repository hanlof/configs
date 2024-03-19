#!/bin/bash

MOONPARAMS="{'camfov': 1.2, 'resx': 3840, 'resy': 2160, 'sunstr': 7.5, 'skip_drivers': True }"
time nice -n 19 /snap/bin/blender --python-expr "import bpy; bpy.context.window.scene['moon_params']=${MOONPARAMS}" -y -P ~/configs/playground/make_moon_scene.py -b -o "/tmp/moon_rendered_##" -f 1
cp /tmp/moon_rendered_01.png /home/hans/.cache/hanlof/moon.png
