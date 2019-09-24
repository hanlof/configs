RASTER_DIR=raster

# output directory creation shenanigans
raster_dir_stamp=$(RASTER_DIR)/.STAMP
$(raster_dir_stamp):
	mkdir -p $(RASTER_DIR)
	touch $@

.SECONDARY: $(RASTER_DIR)/%.png
.PRECIOUS: $(RASTER_DIR)/%.png

$(RASTER_DIR)/%.bgra: $(RASTER_DIR)/%.png $(raster_dir_stamp)
	convert $< -size 64x64 -depth 8 $@

$(RASTER_DIR)/%.png: %.svg $(raster_dir_stamp)
	inkscape -z -e $@ -w 64x64 $<
