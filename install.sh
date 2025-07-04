#!/bin/bash

set -e
# Placeholder file with some notes...

# DONE: fetch subrepos (skip dmenu if it can be found or installed globally (using apt-get)
# DONE: set up dmenu. local and/or compiled from subrepo
# DONE: compile helpers (again skip dmenu if its not needed)
# DONE: run :helptags for vim-fugitive
# DONE: install gitconfig include using git config mechanism

# TODO: consider global (system-wide) git options (hooks) that may interfere with this local git repo and/or other repos
# TODO: sudo apt-get install vim vim-gtk3 git gitk build-essential gcc make incscape ipython3 dmenu fonts-jetbrains-mono. what else?? 
# TODO: build universal-ctags (in background process?!)
# TODO: do some SED magic for paths and install template files. gonna need some interactivity if files exists
# TODO: set up ~/.vimrc to properly include $CONFIGS_PATH/dotvim/vimrc
# TODO: set up ~/.bashrc to properly include $CONFIGS_PATH/bashrc
# TODO: maybe set up github username for configs repo in git configuration (local or global?)
# TODO: proper information printing while running install.sh. sort out coloring properly using tput
# TODO: consider what dependencies we have in install.sh. git?! apt-get ?! LOLz. vim... make...
# TODO: MAKEFLAGS -j <n> for builds in here

# PACKAGES
# -- YouCompleteMe
# sudo apt install libclang-dev
# sudo apt install go
# sudo apt install golang-go
# sudo apt install npm
# sudo apt install openjdk-17-jre
# sudo apt install ipython3
#
# -- random
# sudo apt-get install inkscape
# sudo apt-get install xubuntu-desktop xterm
# sudo apt-get install xterm vim
# sudo apt-get install libx11-dev
# sudo apt-get install dmenu
# sudo apt-get install cmake
# sudo apt-get install libpython3.10-dev
# sudo apt-get install python3-pip pqiv
# /snap/blender/4300/4.0/python/bin/python3.10 -m pip install astropy
# /snap/blender/4301/4.0/python/bin/python3.10 -m pip install lunarsky

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
	if sudo -v; then
		sudo apt-get install dmenu
	else
		printf 'Unsuccessful.'
	fi
}
# did we get a dmenu with a satisfactory version?
which dmenu > /dev/null && DMENU_VER=$(dmenu -v) || DMENU_VER=0.0
DMENU_VER=${DMENU_VER##dmenu-}
if [ "${DMENU_VER%%.*}" -lt 4 -o "${DMENU_VER##*.}" -lt 7 ]; then
	if ${CONFIGS_PATH}/install/build_dmenu.sh; then
		ln -s ../submodules/dmenu/dmenu ${CONFIGS_PATH}/in-path/dmenu
	fi
fi
which dmenu > /dev/null || test -x ${CONFIGS_PATH}/submodules/dmenu/dmenu || {
  printf $'\n\e[1mFAILED to install and/or build dmenu from source. Sorry!\n\n\e[0m'
}


echo Build helper programs
# c-program helpers
(
	make -s -C ${CONFIGS_PATH}/c-programs all || {
		printf $'\n\e[1mFAILED to build helper programs for shell dmenu integration. Sorry!\n\n'
	}
	make -s -C ${CONFIGS_PATH}/c-programs/mmenu mmenu || {
		printf $'\n\e[1mFAILED to build mmenu. Sorry!\n\n'
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

echo Set up vim plugins
# fugitive documentation
vim -n -e --noplugin --cmd  'helptags submodules/vim-fugitive/doc|quit' > /dev/null

echo vimrc
test -e ~/.vimrc || cp ${CONFIGS_PATH_ABS}/vimrc_template ~/.vimrc

echo Xresources
test -e ~/.Xresources || ln -s ${CONFIGS_PATH_ABS}/Xresources ~/.Xresources
xrdb -merge ~/.Xresources

echo MATE configuration
dconf load / < ${CONFIGS_PATH_ABS}/install/mate-dconf-options
