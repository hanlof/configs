RASTER_DIR=raster
OVERLAY_DIR=raster_overlay

# output directory creation shenanigans
raster_dir_stamp=$(RASTER_DIR)/.STAMP
overlay_dir_stamp=$(OVERLAY_DIR)/.STAMP

# don't remove in-between targets (png:s)
.SECONDARY: $(RASTER_DIR)/%.png $(OVERLAY_DIR)/%.png
.PRECIOUS: $(RASTER_DIR)/%.png $(OVERLAY_DIR)/%.png

# get a stupid non 1:1 aspect-ratio SVG to become 1:1 while stil looking sane:
# convert /usr/share/icons/Humanity/apps/128/bash.svg -resize 64x64 -background none -gravity center -extent 64x64 ~/xterm.xpm
#
# blend an image on top of another
# convert -channel A -evaluate multiply 0.8 /usr/share/icons/hicolor/scalable/apps/gvim.svg png: | composite -compose blend -gravity center -geometry 32x32-0-0 png: -resize 48x48 +channel /usr/share/icons/Humanity/apps/128/bash.svg apa.png
# convert -channel A -evaluate multiply 0.8 /usr/share/icons/hicolor/scalable/apps/ipython3.svg png: | composite -compose blend -gravity center -geometry 32x32-0-0 png: -resize 48x48 +channel /usr/share/icons/Humanity/apps/128/bash.svg apa.png

DEFAULT_SIZE?=64x64
# XXX TODO make geom return default size, maybe $(DEFAULT_SIZE), if last part is not valid size
#          or just give a proper error
#     TODO make overlay more generic, have a base_image-WxH/overlayed_image-WxH.bgra file scructure
#          remove hard-coded term-base-centered base image filename
geom = $(word $(words $(subst -, , $1)),$(subst -, ,$1))
base = $(1:-$(call geom,$1)=)

$(raster_dir_stamp):
	mkdir -p $(RASTER_DIR)
	touch $@

$(overlay_dir_stamp):
	mkdir -p $(OVERLAY_DIR)
	touch $@

$(RASTER_DIR)/%.bgra: $(RASTER_DIR)/%.png $(raster_dir_stamp) Makefile
	convert $< -resize $(call geom,$*) -background none -gravity center -extent $(call geom,$*) -depth 8 $@

$(OVERLAY_DIR)/%.bgra: $(RASTER_DIR)/term-base-centered-64x64.png $(RASTER_DIR)/%.png $(overlay_dir_stamp) Makefile
	convert -depth 8 -background none -extent $(call geom,$*) \
		\( -gravity center $(RASTER_DIR)/term-base-centered-$(call geom,$*).png \) \
		\( -gravity SouthEast -resize 70% $(RASTER_DIR)/$(call base,$*)-$(call geom,$*).png \) -composite $@
#	convert -depth 8 -compose blend -background none -extent $(call geom,$*) \( -gravity center $(RASTER_DIR)/term-base-centered-$(call geom,$*).png \) \( -gravity SouthEast -resize 60% -channel A -evaluate multiply 0.9 $(OVERLAY_DIR)/$(call base,$*)-$(call geom,$*).png \) -composite $@

# Need .SECONDEXPANSION and double $ because it's the only way to evaluate % before the function call
# why inkscape? Old imagemagick don't do transparency well! :-/
.SECONDEXPANSION:
$(RASTER_DIR)/%.png: $$(call base,$$*).svg $(raster_dir_stamp)
	inkscape -z -e $@ -w $(call geom,$*) $(call base,$*).svg

.PHONY:
print:
	@echo output
