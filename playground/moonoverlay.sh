#!/bin/bash

cd /home/hlofving/configs/playground

STARBGCOLOR="002b36"
BGCOLOR="073642"
COL_ORANGE="b58900"

python3.9 kery-svg-chart.py

# background stars. use pngphoon with 0 moons drawn.
BGCMD="""pngphoon -w 1920 -h 1080 -s 111 -x 0 -B '${STARBGCOLOR}' -F '${COL_ORANGE}' -f -"""

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
MOONCMD="""convert /home/hlofving/configs/playground/fullmoon-template.png -channel RGB +level 20%,40% -draw 'fill #${STARBGCOLOR}f0 stroke #00000000 path \"${moonshadepath}\"' png:-"""

# fetch sun and make a nice alpha channel and tint it with foreground color
# best awesomest: https://services.swpc.noaa.gov/images/animations/suvi/primary/171/latest.png
SUN_RAW_FNAME='sun-raw.png'
wget https://services.swpc.noaa.gov/images/animations/suvi/primary/171/latest.png -O ${SUN_RAW_FNAME}
SUNCMD="""convert -crop 1280x1222+0+0 ${SUN_RAW_FNAME} -separate -average -colorspace gray -level 0,80% -alpha off -fill '#${COL_ORANGE}' -tint 100 \
       \( -clone 0 -colorspace gray -brightness-contrast 30,30 -level 30%,60% -draw 'fill white stroke none circle 640,640 640,250' \) \
       -alpha off -compose copyopacity -composite -brightness-contrast 15,15 png:-"""

# compose everything together
convert <(eval "$BGCMD") \
    \( -gravity northeast -geometry +50+70   -background none -resize 90% now.svg \) -composite \
    \( -gravity southeast -geometry +10+160  -background none -density 150 -size 150x150 grid.svg \)  -composite \
    \( -gravity center    -geometry +300+180 -resize 555x  <(eval "$MOONCMD") \) -composite \
    \( -gravity northwest -geometry -50-100  -resize 1111x <(eval "$SUNCMD") \) -composite \
    \( -gravity southeast -geometry +10+30                 <(eval "$MOONPHASECMD") \) -composite \
    /tmp/desktop-finished.png

cp /tmp/desktop-finished.png /home/hlofving/moon.png

# fix tint and opacity for sun
#convert latest_1024_0304.jpg -crop 990x940+12+45 \( -clone 0 -alpha off  -colorspace Gray -level 0,70% \) \( -clone 1 -alpha off -draw 'fill white stroke none circle 500,467 500,874' \) -delete 1 -alpha off -compose copyopacity -composite -depth 8 -colorspace gray -separate -average -level 0,70% -fill "#b58900" -tint 100

# wget https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0193.jpg -O sun-raw.jpg
# wget https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0304.jpg -O sun-raw.jpg
# base https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0304.jpg

#convert sun-raw.jpg -crop 990x940+12+45 -colorspace gray -separate -average -level 0,80% -alpha off -fill "#b58900" -tint 100 \( -clone 0 -colorspace gray -average -separate -level 0,70% -draw 'fill white stroke none circle 500,467 500,874' \) -alpha off -delete 1,2 -compose copyopacity -composite -depth 8 -brightness-contrast 10,10 -channel alpha -level 0,20% -blur 20x20 /tmp/sun-finished.png

# moon original: https://theskylive.com/images/fullmoon.jpg
# convert fullmoon.jpg -level 0,70% \( -clone 0 +level-colors "#002b3600","#b58900ff" \) \( -clone 1 -alpha off -fill white -draw 'circle 400,400 2,400' \) \( -clone 1,2 -alpha off -compose copyopacity -composite \) -delete 0,1,2 +append fullmoon-template.png

# decent moon + sun (Ulrica layout)
# convert  ~/moon.png \( -fill "#b58900" -tint 60 -fill "#b58900" -gravity center -resize 640x640 -geometry +260+150 ~/fullmoon-alpha.png \) -composite \( -gravity northwest -geometry 1200x1200-100-50 /tmp/sun-final.png \) -composite png:- | display

