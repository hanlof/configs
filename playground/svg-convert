find -name "*.svg" | while read svgfile; do inkscape ${svgfile} --export-plain-svg=../Solarized-Fixed-Size/${svgfile} --export-area-drawing; done
find ./ | while read f; do if [ ! -e ../Solarized-Fixed-Size/${f} ]; then cp ${f} ../Solarized-Fixed-Size/${f} -v; fi; done
find ./ -name "*.svg" | while read svgfile; do scour ${svgfile}
find ./ -type d | while read dir; do mkdir -p ../Solarized-Scour/${dir}; done
find ./ -name "*.svg" | while read f; do
  scour ${f} ../Solarized-Scour/${f} \
    --create-groups \
    --renderer-workaround \
    --strip-xml-prolog \
    --remove-descriptive-elements \
    --enable-comment-stripping \
    --indent=none \
    --no-line-breaks \
    --strip-xml-space \
    --enable-id-stripping \
    --shorten-ids \
    --set-precision=2
done

# XXX: MUST CONSIDER SYMBOLIC LINKS!
# --enable-viewboxing ??!?

target_dir=A
source_dir=B

mkdir "${target_dir}"
find "${source_dir}" -printf '%P\n' | while read fn; do
  if [ -l "${source_dir}/${fn}" ]; then # symbolic link? -> recreate the link and continue
    cp -P "${source_dir}/${fn}" "${target_dir}/${fn}"
    continue
  fi
  if [ -d "${fn}" ]; then # directory -> create directory and continue
    mkdir "${target_dir}"/"${fn}"
    continue
  fi
  if [[ "${source_dir}/${fn}" == *.svg ]]; then # svg file? scour and continue
    # scour .....
  fi
  # else -> verbatim copy file
done
