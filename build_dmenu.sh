#!/bin/bash

set -e
CONFIGS_PATH=$(dirname $0)

# fetch and build dmenu
git -C ${CONFIGS_PATH} submodule update --init submodules/dmenu

make -C ${CONFIGS_PATH}/submodules/dmenu || {
	# if build fails, assume we are missing headers and attempt to fetch them
	sudo apt-get install libx11-dev libxinerama-dev libxft-dev
	make -C ${CONFIGS_PATH}/submodules/dmenu
}

