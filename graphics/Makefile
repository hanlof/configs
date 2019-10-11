RASTER_DIR=raster

# output directory creation shenanigans
raster_dir_stamp=$(RASTER_DIR)/.STAMP
.SECONDARY: $(RASTER_DIR)/%.png
.PRECIOUS: $(RASTER_DIR)/%.png

# wanted format: raster/base-WxH.bgra
#
# Set this to output different output size, can be done from cmdline SIZE=AxB
# XXX if the .bgra already exists it will not be remade because the target name is the same
SIZE?=64x64

# get a stupid non 1:1 aspect-ratio SVG to become 1:1 while stil looking sane:
# convert /usr/share/icons/Humanity/apps/128/bash.svg -resize 64x64 -background none -gravity center -extent 64x64 ~/xterm.xpm
#
# blend an image on top of another
# convert -channel A -evaluate multiply 0.8 /usr/share/icons/hicolor/scalable/apps/gvim.svg png: | composite -compose blend -gravity center -geometry 32x32-0-0 png: -resize 48x48 +channel /usr/share/icons/Humanity/apps/128/bash.svg apa.png
# convert -channel A -evaluate multiply 0.8 /usr/share/icons/hicolor/scalable/apps/ipython3.svg png: | composite -compose blend -gravity center -geometry 32x32-0-0 png: -resize 48x48 +channel /usr/share/icons/Humanity/apps/128/bash.svg apa.png

# XXX TODO make geom return default size, maybe $(SIZE), if last part is not valid size
geom = $(word $(words $(subst -, , $1)),$(subst -, ,$1))
base = $(1:-$(call geom,$1)=)

$(raster_dir_stamp):
	mkdir -p $(RASTER_DIR)
	touch $@

$(RASTER_DIR)/%.bgra: $(RASTER_DIR)/%.png $(raster_dir_stamp)
	convert $< -resize $(call geom,$*) -background none -gravity center -extent $(call geom,$*) -depth 8 $@

# Need .SECONDEXPANSION because it's the only way to evaluate % before the function call
.SECONDEXPANSION:
$(RASTER_DIR)/%.png: $$(call base,$$*).svg $(raster_dir_stamp)
	# why inkscape? Old imagemagick don't do transparency well! :-/
	inkscape -z -e $@ -w $(call geom,$*) $(call base,$*).svg

