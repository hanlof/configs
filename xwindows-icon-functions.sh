function set_xwindows_icon()
{
  printf -v X "%q" "${1}"
# Add text to image:
# convert term-base-centered-64x64.png -font FreeMono-Bold -pointsize 32 -fill white -draw 'text 8,35 ls' -background none -resize 64x64 -depth 8 -extent 64x64 -geometry 64x64 -size 64x64 bgra:
  if [ ! -f "${CONFIGS_PATH}/graphics/${X}.svg" ]; then
    return 1
  fi
  # produce term-base.bgra
  SIZE=64x64
  if [ -z "$2" ]; then
    BGRA_NAME=raster/"${1}-${SIZE}.bgra"
  else
    BGRA_NAME=raster_overlay/"${1}-${SIZE}.bgra"
  fi
  make --quiet -C ${CONFIGS_PATH}/graphics ${BGRA_NAME}
  # set it using xseticon
  ${CONFIGS_PATH}/c-programs/xseticon -s ${SIZE} -w $WINDOWID < ${CONFIGS_PATH}/graphics/${BGRA_NAME}
}


