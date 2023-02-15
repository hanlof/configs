#!/bin/bash

cd /home/hlofving/configs/playground
python3.9 kery-svg-chart.py
convert -background none -resize 90% now.svg /tmp/chart.png
convert -background none -density 150 -size 150x150 grid.svg /tmp/grid.png

export PYTHONIOENCODING=utf8
export PYTHONPATH=/usr/local/lib/python2.7/dist-packages

label="$(python2 /home/hlofving/gh/PyMoon/moon.py)"

STARBGCOLOR="002b36"
BGCOLOR="073642"
COL_ORANGE="b58900"

#/home/hlofving/Downloads/pngphoon-1.2/pngphoon -w 1920 -h 1080 -s 111 -B 002b36 -F "$COL_ORANGE" -f - | {
pngphoon -w 1920 -h 1080 -s 111 -B "${STARBGCOLOR}" -F "${COL_ORANGE}" -f - | {
    convert png:- \
      \( -background "#${BGCOLOR}" -trim +repage \
         -pointsize 14 -font "FreeMono" -fill "#$COL_ORANGE" -strokewidth 0.1 \
         -bordercolor "#${BGCOLOR}" -border 8x8 \
         -bordercolor "#${COL_ORANGE}80" -border 2x2 \
         label:"\\${label}" -gravity southeast -geometry +10+30 \) \
      -composite /tmp/moon.png
}

convert /tmp/moon.png \( -gravity northeast -geometry +50+70 /tmp/chart.png \) -composite /tmp/moon_chart.png
convert /tmp/moon_chart.png \( -gravity southeast -geometry +10+160 /tmp/grid.png \) -composite /tmp/moon_chart_grid.png
cp /tmp/moon_chart_grid.png /home/hlofving/moon.png

# decent moon + sun (Ulrica layout)
# convert  ~/moon.png \( -fill "#b58900" -tint 60 -fill "#b58900" -gravity center -resize 640x640 -geometry +260+150 ~/fullmoon-alpha.png \) -composite \( -gravity northwest -geometry 1200x1200-100-50 /tmp/sun-final.png \) -composite png:- | display

# convert sun-blue.jpg -crop 2048x1777+0+77 -set colorspace Gray -separate -average -fill white -draw 'translate 1030,842 circle 0,0 444,444' sun-alpha.png
# convert sun-blue.jpg -crop 2048x1777+0+77 -set colorspace Gray -separate -average sun-grey.png
# convert sun-grey.png -fill "#b58900" -tint 80 sun-colorized.png
# convert sun-alpha.png sun-colorized.png +swap -alpha off -compose copyopacity -composite -depth 8 -resize 1024x sun-final.png
