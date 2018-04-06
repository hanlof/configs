#!/bin/bash

# Placeholder file with some notes...

# DONE: fetch subrepos (skip dmenu if it can be found or installed globally (using apt-get)
# DONE: compile helpers (again skip dmenu if its not needed)

# TODO: consider dmenu versions. some versions do not recognize the -w flag
# TODO: modify template files so "configs"-path can easily be sed:ed into them
# TODO: update vim config so it can detect dmenu path
# TODO: find path to this git repo and sed real path into template files
# TODO: add sed:ed template files to users real dotfiles. gonna need some interactivity if files exists
# TODO: consider adding index_repo to path and/or as an alias in configs/bashrc
# TODO: run :helptags ALL in vim once (ignore error about system-wide write permission)
# TODO: sudo apt-get install exuberant-ctags vim-gtk gitk. what else??
# TODO: check repo root hash in vimrc_template. set up indentation style to comply with repo coding standards
# TODO: consider different indentation styles in different paths within a repo?

# alternative1: screw system-wide dmenu. always compile. why not? if compilation fails for whatever reason we need to fall back to system-wide anyway.
# alternative2: check system-wide dmenu version after install. compile if it not > 4.6

# install system-wide dmenu
# check version of system-wide dmenu. if it has -w then we are fine!
# if we cannot install dmenu or if we dont have -w we compile
# if system-wide install and/or compilation fails then we are screwed
# vim and bash need to check dmen version either way

install_dmenu()
{
	printf $'\e[1mTrying to install dmenu...\e[0m\n'
	if sudo apt-get install dmenu; then
		VER=$(dmenu -v)
	fi
        # check that dmenu was installed and version is less than 4.7
	# otherwise build it!
        if [ -z "$VER" -o ${VER%%.*} -lt 4 -o ${VER##*.} -lt 7 ]; then
		${CONFIGS_PATH}/build_dmenu.sh
        fi
}

CONFIGS_PATH=$(dirname $0)

# dmenu
which dmenu > /dev/null || install_dmenu
which dmenu > /dev/null || test -x ${CONFIGS_PATH}/submodules/dmenu/dmenu || {
  printf $'\n\e[1mFAILED to install and/or build dmenu from source. Sorry!\n\n\e[0m'
}

git -C ${CONFIGS_PATH} submodule update --init submodules/vim-fugitive

# c-program helpers
(
	make -C ${CONFIGS_PATH}/c-programs insdirs2 prefix dumptags || {
		printf $'\n\e[1mFAILED to build helper programs for shell dmenu integration. Sorry!\n\n'
	}
)
