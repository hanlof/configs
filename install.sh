#!/bin/bash

# Placeholder file with some notes...

# DONE: fetch subrepos (skip dmenu if it can be found or installed globally (using apt-get)
# DONE: set up dmenu. local and/or compiled from subrepo
# DONE: compile helpers (again skip dmenu if its not needed)
# DONE: run :helptags for vim-fugitive
# DONE: install gitconfig include using git config mechanism

# TODO: consider global (system-wide) git options (hooks) that may interfere with this local git repo and/or other repos
# TODO: sudo apt-get install vim vim-gtk3 git gitk gcc make. what else??
# TODO: build universal-ctags
# TODO: do some SED magic for paths and install template files. gonna need some interactivity if files exists
# TODO: set up ~/.vimrc to properly include $CONFIGS_PATH/dotvim/vimrc
# TODO: set up ~/.bashrc to properly include $CONFIGS_PATH/bashrc
# TODO: maybe set up github username for configs repo in git configuration (local or global?)
# TODO: proper information printing while running install.sh. sort out coloring properly using tput
# TODO: consider what dependencies we have in install.sh. git?! apt-get ?! LOLz. vim... make...
# TODO: MAKEFLAGS -j <n> for builds in here

CONFIGS_PATH=$(dirname $0)
CONFIGS_PATH_ABS=$(readlink -m ${CONFIGS_PATH})

# submodules
git -C ${CONFIGS_PATH} submodule update --init submodules/vim-fugitive
git -C ${CONFIGS_PATH} submodule update --init submodules/vim-bitbake
git -C ${CONFIGS_PATH} submodule update --init submodules/universal-ctags
git -C ${CONFIGS_PATH} submodule update --init submodules/dmenu

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


echo Set up vim plugins
# fugitive documentation
vim -n -e --noplugin --cmd  'helptags submodules/vim-fugitive/doc|quit'

echo Build helper programs
# c-program helpers
(
	make -C ${CONFIGS_PATH}/c-programs insdirs2 prefix dumptags || {
		printf $'\n\e[1mFAILED to build helper programs for shell dmenu integration. Sorry!\n\n'
	}
)

echo Git config
INSTALL_GIT_INCLUDE=true
GITCONFIG_PATH=${CONFIGS_PATH_ABS}/gitconfig
while read CFG_VALUE; do
	if [ "$CFG_VALUE" = "$GITCONFIG_PATH" ]; then
		INSTALL_GIT_INCLUDE=false
	fi
done <<< "$(git config --global --get-all include.path)"

${INSTALL_GIT_INCLUDE} && git config --global --add include.path "$GITCONFIG_PATH"

echo vimrc
test -e ~/.vimrc || cp ${CONFIGS_PATH_ABS}/vimrc_template ~/.vimrc

echo Xresources
test -e ~/.Xresources || ln -s ${CONFIGS_PATH_ABS}/Xresources ~/.Xresources
