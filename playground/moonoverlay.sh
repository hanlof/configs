#!/bin/bash

cd /home/hlofving/configs/playground

STARBGCOLOR="002b36"
BGCOLOR="073642"
COL_ORANGE="b58900"

python3.9 kery-svg-chart.py

# background stars. use pngphoon with 0 moons drawn.
BGCMD="""pngphoon -w 1920 -h 1080 -s 111 -x 0 -B '${STARBGCOLOR}' -F '${COL_ORANGE}' -f -"""

# TODO: decrease size of moon, sun and chart
# TODO: somehow use the circle sizes at the absolute measurement for the images and not the bounding boxes

# TODO: Sun image is updated every ~3.9 minutes (measured in the morning of 2023-04-20)
# TODO: check date on raw-sun image before downloading it (don't refresh too often)
# TODO: tweak the sun so that more of the corona shows up clearly

# $ curl https://services.swpc.noaa.gov/images/animations/suvi/primary/171/
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
# <html>
# [.....]
# <a href="latest.png">latest.png</a>              2023-04-20 08:12  644K
# <a href="or_suvi-l2-ci171_g16_s20230420T051200Z_e20230420T051600Z_v1-0-1.png">or_suvi-l2-ci171_g16..&gt;</a> 2023-04-20 05:23  646K
# <a href="or_suvi-l2-ci171_g16_s20230420T051600Z_e20230420T052000Z_v1-0-1.png">or_suvi-l2-ci171_g16..&gt;</a> 2023-04-20 05:27  646K
# [.....]

# moon phase info box
label="$(python3 phase3.py --phase)"
MOONPHASECMD="""convert \
 -background '#${BGCOLOR}' -trim +repage \
 -pointsize 14 -font 'FreeMono' -fill '#$COL_ORANGE' -strokewidth 0.1 \
 -bordercolor '#${BGCOLOR}' -border 8x8 \
 -bordercolor '#${COL_ORANGE}80' -border 2x2 \
 label:'\\${label}' png:-"""

# call python script to get the svg path for moon shadow and overlay it onto raw moon image, plus some fiddling with colors!
moonshadepath=$(python3 ./phase3.py --shade-svgpath ./fullmoon-template.png)
MOONCMD="""convert /home/hlofving/configs/playground/fullmoon-template.png -channel RGB +level 20%,40% -draw 'fill #${STARBGCOLOR}80 stroke #00000000 path \"${moonshadepath}\"' png:-"""

# fetch sun and make a nice alpha channel and tint it with foreground color
# best awesomest: https://services.swpc.noaa.gov/images/animations/suvi/primary/171/latest.png
SUN_RAW_FNAME='sun-raw.png'
if [ "$1" != "fast" ]; then
    wget https://services.swpc.noaa.gov/images/animations/suvi/primary/171/latest.png -O ${SUN_RAW_FNAME}
fi
SUNCMD="""convert ${SUN_RAW_FNAME} -draw 'fill black rectangle 0,1222,1279,1279' -separate -average -colorspace gray -level 0,80% -alpha off -fill '#${COL_ORANGE}' -tint 100 \
       \( -clone 0 -colorspace gray -brightness-contrast 30,30 -level 5%,90% -draw 'fill white stroke none circle 640,640 640,250' \) \
       -alpha off -compose copyopacity -composite -brightness-contrast 15,15 png:-"""


# blender --python-expr "import bpy; bpy.context.scene['moon_props'] = {'colormap': 'what', 'heightmap': 'rly?', 'camera_fov': 0.6}; exit(0)"
#DISPLAY=:0.0 blender -b /home/hlofving/playground/mymoon.blend -o /home/hlofving/playground/moon_rendered.png -P /home/hlofving/playground/moon3d/make_scene.py
MOONPARAMS="{'camfov': 0.7, 'resx': 640, 'resy': 640, 'sunstr': 7.5, 'skip_drivers': True }"
if [ "$1" != "fast" ]; then
    DISPLAY=:0.0 /snap/bin/blender --python-expr "import bpy; bpy.context.window.scene['moon_params']=${MOONPARAMS}" -y -P /home/hlofving/configs/playground/make_moon_scene.py -b -o "/home/hlofving/playground/moon_rendered_##" -f 1
fi

RESX=1920
DISC_WIDTH_RATIO=70 # given in percent!
BASE_Y_OFFSET=-50
let WANTED_DISC_WIDTH="((RESX / 3) * DISC_WIDTH_RATIO) / 100"

let SPACING="(RESX - ((1920 * DISC_WIDTH_RATIO) / 100)) / 4"

# ---  DIMENSIONS ---
# sun disc is 780 pixels in the original out of 1280x1280
# moon disc is between 835 and 953 pixels (with FOV 0.6 deg) out of 1024x1024
# the chart covers the whole image and size is controllable

SUN_DISC_SIZE=780
SUN_ORIGINAL_SIZE=1280
SUN_RESIZE_FACTOR=$(( (WANTED_DISC_WIDTH * 100) / SUN_DISC_SIZE ))
SUN_RESCALED_SIZE=$(( (SUN_ORIGINAL_SIZE * SUN_RESIZE_FACTOR) / 100 ))
SUN_X_OFFSET=$(( SPACING - ((SUN_RESCALED_SIZE - WANTED_DISC_WIDTH) / 2) ))
SUN_Y_OFFSET=$(( BASE_Y_OFFSET + SPACING - ((SUN_RESCALED_SIZE - WANTED_DISC_WIDTH) / 2) ))

MOON_DISC_SIZE=500 # (558.75 mean size @ 640x640px FOV 0.6deg)
MOON_ORIGINAL_SIZE=640
MOON_RESIZE_FACTOR=$(( (WANTED_DISC_WIDTH * 100) / MOON_DISC_SIZE ))
MOON_RESCALED_SIZE=$(( (MOON_ORIGINAL_SIZE * MOON_RESIZE_FACTOR) / 100 ))
MOON_X_OFFSET=$(( (2 * SPACING + WANTED_DISC_WIDTH) - ((MOON_RESCALED_SIZE - WANTED_DISC_WIDTH) / 2) ))
MOON_Y_OFFSET=$(( BASE_Y_OFFSET + SPACING - ((MOON_RESCALED_SIZE - WANTED_DISC_WIDTH) / 2) ))

CHART_RESIZE_FACTOR=$(( (WANTED_DISC_WIDTH * 100) / 640 ))
CHART_RESCALED_SIZE=$(( (640 * CHART_RESIZE_FACTOR) / 100 ))
CHART_X_OFFSET=$(( (3 * SPACING + 2 * WANTED_DISC_WIDTH) - ((CHART_RESCALED_SIZE - WANTED_DISC_WIDTH) / 2) ))
CHART_Y_OFFSET=$(( BASE_Y_OFFSET + SPACING - ((CHART_RESCALED_SIZE - WANTED_DISC_WIDTH) / 2) ))

printf -v SUN_X_OFFSET %+d ${SUN_X_OFFSET}
printf -v SUN_Y_OFFSET %+d ${SUN_Y_OFFSET}
printf -v MOON_X_OFFSET %+d ${MOON_X_OFFSET}
printf -v MOON_Y_OFFSET %+d ${MOON_Y_OFFSET}
printf -v CHART_X_OFFSET %+d ${CHART_X_OFFSET}
printf -v CHART_Y_OFFSET %+d ${CHART_Y_OFFSET}

# compose everything together
# convert <(eval "$BGCMD") -draw 'fill none stroke #80808080 rectangle 640,0 1280,640' \
convert <(eval "$BGCMD") \
    \( -resize ${SUN_RESCALED_SIZE}x   -geometry ${SUN_X_OFFSET}${SUN_Y_OFFSET}  <(eval "$SUNCMD") -gravity northwest \) -composite \
    \( -resize ${MOON_RESCALED_SIZE}x  -geometry ${MOON_X_OFFSET}${MOON_Y_OFFSET}  /home/hlofving/playground/moon_rendered_01.png -gravity northwest \) -composite \
    \( -resize ${CHART_RESCALED_SIZE}x -geometry ${CHART_X_OFFSET}${CHART_Y_OFFSET}   -background none now.svg -gravity northwest \) -composite \
    \( -gravity southeast -geometry +10+160  -background none -density 150 -size 150x150 grid.svg \)  -composite \
    \( -gravity southeast -geometry +10+30              <(eval "$MOONPHASECMD") \) -composite \
    /tmp/desktop-finished.png

    #\( -gravity northwest -geometry +640+0   -resize 640x -background none /home/hlofving/playground/moon_rendered.png \) -composite \

#    \( -gravity center    -geometry +300+180 -resize 555x -background none -rotate 45.5 <(eval "$MOONCMD") \) -composite \
cp /tmp/desktop-finished.png /home/hlofving/moon.png

# fix tint and opacity for sun
#convert latest_1024_0304.jpg -crop 990x940+12+45 \( -clone 0 -alpha off  -colorspace Gray -level 0,70% \) \( -clone 1 -alpha off -draw 'fill white stroke none circle 500,467 500,874' \) -delete 1 -alpha off -compose copyopacity -composite -depth 8 -colorspace gray -separate -average -level 0,70% -fill "#b58900" -tint 100

# wget https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0193.jpg -O sun-raw.jpg
# wget https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0304.jpg -O sun-raw.jpg
# base https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0304.jpg

#convert sun-raw.jpg -crop 990x940+12+45 -colorspace gray -separate -average -level 0,80% -alpha off -fill "#b58900" -tint 100 \( -clone 0 -colorspace gray -average -separate -level 0,70% -draw 'fill white stroke none circle 500,467 500,874' \) -alpha off -delete 1,2 -compose copyopacity -composite -depth 8 -brightness-contrast 10,10 -channel alpha -level 0,20% -blur 20x20 /tmp/sun-finished.png

# moon original: https://theskylive.com/images/fullmoon.jpg
# convert fullmoon.jpg -level 0,70% \( -clone 0 +level-colors "#002b3600","#b58900ff" \) \( -clone 1 -alpha off -fill white -draw 'circle 400,400 2,400' \) \( -clone 1,2 -alpha off -compose copyopacity -composite \) -delete 0,1,2 +append fullmoon-template.png

