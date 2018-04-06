#!/bin/bash

# Placeholder file with some notes...

# DONE: fetch subrepos (skip dmenu if it can be found or installed globally (using apt-get)
# DONE: compile helpers (again skip dmenu if its not needed)
# DONE: run :helptags for vim-fugitive

# TODO: consider global git options (hooks) that may interfere with this local git repo and/or other repos
# TODO: consider dmenu versions in vim and bash. some versions do not recognize the -w flag
# TODO: update vim config so it can detect dmenu path
# TODO: do some SED magic for paths and install template files. gonna need some interactivity if files exists
# TODO: consider adding index_repo to path and/or as an alias in configs/bashrc
# TODO: sudo apt-get install exuberant-ctags vim-gtk gitk. what else??
# TODO: check repo root hash in vimrc_template. set up indentation style to comply with repo coding standards
# TODO: consider different indentation styles in different paths within a repo?

CONFIGS_PATH=$(dirname $0)

# dmenu
which dmenu > /dev/null || { # first try systme-wide dmenu
	printf $'\e[1mTrying to install dmenu...\e[0m\n'
	sudo apt-get install dmenu
}
# did we get a dmenu with a satisfactory version?
which dmenu > /dev/null && DMENU_VER=$(dmenu -v) || DMENU_VER=0.0
DMENU_VER=${DMENU_VER##dmenu-}
if [ "${DMENU_VER%%.*}" -lt 4 -o "${DMENU_VER##*.}" -lt 7 ]; then
	${CONFIGS_PATH}/build_dmenu.sh
fi
which dmenu > /dev/null || test -x ${CONFIGS_PATH}/submodules/dmenu/dmenu || {
  printf $'\n\e[1mFAILED to install and/or build dmenu from source. Sorry!\n\n\e[0m'
}

# fugitive vim plugin
git -C ${CONFIGS_PATH} submodule update --init submodules/vim-fugitive
vim -n -e --noplugin --cmd  "helptags submodules/vim-fugitive|quit"

# c-program helpers
(
	make -C ${CONFIGS_PATH}/c-programs insdirs2 prefix dumptags || {
		printf $'\n\e[1mFAILED to build helper programs for shell dmenu integration. Sorry!\n\n'
	}
)
