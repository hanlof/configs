#!/bin/bash

set -e

CONFIGS_PATH=$(dirname $0)

git -C ${CONFIGS_PATH} submodule update --init submodules/dmenu

make -C ${CONFIGS_PATH}/submodules/dmenu || {
	printf 'Missing headers/libs or other build error. Attempting to use apt-get to retrieve them...\n'
	printf 'sudo: '
	sudo -v || {
		printf 'Please authenticate using sudo and try again to apt-get needed headers\n'
		printf 'E.g: sudo -v'
		return
	}
	sudo apt-get install build-essential libx11-dev libxinerama-dev libxft-dev
	make -C ${CONFIGS_PATH}/submodules/dmenu dmenu
}

