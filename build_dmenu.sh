#!/bin/bash

set -e

CONFIGS_PATH=$(dirname $0)

set -x

git -C ${CONFIGS_PATH} submodule update --init submodules/dmenu

make -C ${CONFIGS_PATH}/submodules/dmenu || {
	# if build fails, assume we are missing headers,
	# so attempt to fetch them and try again
	sudo apt-get install libx11-dev libxinerama-dev libxft-dev
	make -C ${CONFIGS_PATH}/submodules/dmenu
}

