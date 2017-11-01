#!/bin/bash

# Placeholder file with some notes...

# TODO: fetch subrepos (skip dmenu if it can be found or installed globally (using apt-get)
# TODO: compile helpers (again skip dmenu if its not needed)
# TODO: consider dmenu versions. some versions do not recognize the -w flag
# TODO: consider dmenu dependencies: libx11-dev libxinerama-dev libxft-dev
# TODO: modify template files so "configs"-path can easily be sed:ed into them
# TODO: update template files so they can use globally installed dmenu if it exists
# TODO: find path to this git repo and sed real path into template files
# TODO: add sed:ed template files to users real dotfiles. gonna need some interactivity if files exists
# TODO: consider adding index_repo to path and/or as an alias in configs/bashrc
# TODO: run :helptags ALL in vim once (ignore error about system-wide write permission)
# TODO: sudo apt-get install exuberant-ctags vim-gtk gitk. what else??

git submodule update --init
(cd c-programs
make insdirs2
make prefix)
(cd submodules/dmenu
sudo apt-get install libx11-dev libxinerama-dev libxft-dev
make)
