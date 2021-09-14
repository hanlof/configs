[[ $- == *i* ]] || return

CONFIGS_PATH=~/configs

source ${CONFIGS_PATH}/bash/xwindows-icon-functions.sh
source ${CONFIGS_PATH}/bash/xterm-functions.sh
source ${CONFIGS_PATH}/bash/prompt-functions.sh

_complete_repos() {
  local cur
  pushd ~/repos > /dev/null
  COMPREPLY=( $(compgen -d -- ${2}) )
  popd > /dev/null
}

find_dmenu()
{
  # system-wide installed? if found we return immediately
  DMENU_PATH=$(which dmenu 2>/dev/null) && return

  # plan-b: look under configs.
  DMENU_PATH="${CONFIGS_PATH}/submodules/dmenu/dmenu"
  # if that guy is executable we already have a good value in DMENU_PATH and so we just return
  test -x ${DMENU_PATH} && return

  # plan-c: bail! (TODO: try to compile it)
  printf 'Dmenu not found\n'
  DMENU_PATH='DMENU_NOT_FOUND'
}

# git helpers
check_cwd_in_gitrepo()
{
  s=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ -z "$s" ]; then
    echo "$*"
    return 1
  fi
}

fr ()
{
  SUPERREPO="$PWD"/
  {
    git ls-files
    git submodule foreach --quiet --recursive "PREFIX=\${PWD##$SUPERREPO}/; git ls-files | ${CONFIGS_PATH}/c-programs/prefix \$PREFIX"
  } | ${DMENU_PATH} -w $WINDOWID -l 40 -i | xargs vim
}

ggrep ()
{
  printf -v GREP_ARGS ' %q' "${@}"
  # this expression searches for "Entering '<path>'" and stores path in "hold buffer",
  # then it will insert the path at the beginning of every line.
  # if another "Entering ..." line is found then the hold pattern will be updated
  SED_EXPR="/Entering/{s/^Entering '\(.*\)'$/\\1/;h;d};{G;s/\(.*\)\\n\(.*\)/\\2\/\\1/;}"
  {
    git --no-pager grep "${@}" "$(git rev-parse --show-toplevel)"
    git submodule foreach --recursive "git --no-pager grep ${GREP_ARGS} ; true" | sed -e "$SED_EXPR"
  } | grep --color=yes "${@}" | less -FRX
}

gls()
{
  A=()
  D=""
  N=""
  for i in *; do
    tree=$(git ls-tree --name-only HEAD -- "$i")
    if [[ "$tree"x == ""x ]]; then
      echo -n "$i"
      #N+="? $i"/$'\n'
      E=""
      if [ -d "$i" -a ! -h "$i" ]; then
          E="/"
          #D+="  $i"/$'\n'
      fi
      echo $E
    fi
    #A+=( "$i" )
  done
  #echo -n "$D"
  #echo -n "$N"
  #git ls-files -cdmoktv "${A[@]}"
  #git ls-files -icdmoktv --exclude-standard "${A[@]}" | sed 's/^\?/x/'
}

ft()
{
  # TODO if not in git repo try just ./tags then
  check_cwd_in_gitrepo "Enter git repo first." || return 1
  tagname=$(${CONFIGS_PATH}/c-programs/dumptags -t ${s}/.git/tags -l | ${DMENU_PATH} -w $WINDOWID -sb purple -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$tagname" ]; then return; fi

  vim --cmd set\ tags+=${s}/.git/tags -t ${tagname}
}

find_git_file()
{
  find_dmenu
  check_cwd_in_gitrepo "Enter git repo first." || return 1
  fname=$(git ls-files --full-name ${s} | ${DMENU_PATH} -w $WINDOWID -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$fname" ]; then return; fi

  history -s vim ${s}/${fname}
  fc -s
}

run-prompt()
{
  printf "> "

  for (( i=0; ; i++)) do
    if read input; then
      cmds[$i]="$input"
      _ascii=$((0x61+$i))
    else
      break
    fi
  done < ~/bin/xx
  read -s -n1 -d '' _KEY
  printf -v index %d \'$_KEY\'
  index=$(($index-97))


  if [ $index -lt 0 -o $index -ge ${#cmds[*]} ]; then
    echo "Abort"
  else
    echo ${cmds[$index]}
    history -s ${cmds[$index]}
    eval ${cmds[$index]}
  fi
}

run_menu ()
{
  printf "\e[?1049h" >&2
  # clear display
  printf "\e[2K" >&2
  # set cursor at column 1 row 1
  printf "\e[1;1H" >&2

  color=0
  for (( i=0; ; i++)) do
    if read input; then
      cmds[$i]="$input"
      _ascii=$((0x61+$i))
      #the below line may be used to get alternating colors
      if [ $color == 0 ]; then ansi="\\033[48;5;195m"; color=1; else ansi="\\033[48;5;231m"; color=0; fi
      printf "\\"x`printf %x $_ascii`"\e[1m)\e[0m %s\n" "$input" >&2
    else
      break
    fi
  done < ~/bin/xx
  read -s -n1 -d '' _KEY
  printf -v index %d \'$_KEY\'
  index=$(($index-97))

  printf "\e[?1049l" >&2

  if [ $index -lt 0 -o $index -ge ${#cmds[*]} ]; then
    echo "Aborted"
  else
    history -s ${cmds[$index]}
    set_xterm_title "${cmds[$index]}"
    eval ${cmds[$index]}
  fi
}

insert_git_top ()
{
  gittop=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ -z "$gittop" ]; then
    echo "Enter a git repo first."
    return 1
  fi
  s=${READLINE_LINE:0:$READLINE_POINT}
  e=${READLINE_LINE:$READLINE_POINT}
  READLINE_LINE="$s$gittop/$e"
  let READLINE_POINT+=${#gittop}
  let READLINE_POINT++
}

insert_filename ()
{
  gittop=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ -z "$gittop" ]; then
    echo "Enter a git repo first."
    return 1
  fi

  fname=$(git ls-files --full-name ${gittop} | ${CONFIGS_PATH}/c-programs/insdirs2 | ${DMENU_PATH} -w $WINDOWID -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$fname" ]; then
    echo "'git ls-files' returned nothing"
    return
  fi

  start=${READLINE_LINE:0:$READLINE_POINT}
  end=${READLINE_LINE:$READLINE_POINT}
  READLINE_LINE="${start}${gittop}/${fname}${end}"
  let READLINE_POINT+=${#gittop}
  let READLINE_POINT+=${#fname}
  let READLINE_POINT++
}

insert_from_file ()
{

  fname=$(< ${1} ${DMENU_PATH} -w $WINDOWID -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$fname" ]; then
    echo "The file ${1} was empty"
    return
  fi

  start=${READLINE_LINE:0:$READLINE_POINT}
  end=${READLINE_LINE:$READLINE_POINT}
  READLINE_LINE="${start}${fname}${end}"
  let READLINE_POINT+=${#fname}
}

function v()
{
  filedir=$(dirname "$1")
  gitdir=$(git -C "${dir}" rev-parse --show-toplevel)

  vim --servername ${gitdir} --remote-tab-silent "$1"
}

function __prompt_command()
{
  __exit_status="$?"

  # reset window icon to standard bash when prompt is shown

  set_xwindows_icon term-base-centered
  # Xterm title
  _git_repo=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ $? != 0 ]; then
    xterm_title="${PWD}/"
  else
    xterm_title="<${_git_repo##*/}>"
  fi
  set_xterm_title "BASH: ${xterm_title}"                 # xterm title

  PS1=""
  PS1+='\[\033[0m\]'                                     # reset all color
  PS1+='\[\033[1m\]\h '                                  # hostname
  PS1+=${TERM_EMU_MSG}

  PS1+='\[\033[0m\]'                                     # reset color
  PS1+="${OECORE_SDK_VERSION:+{$OECORE_SDK_VERSION\} }"  # build env
  PS1+="${BUILDDIR:+{${BUILDDIR##*/build}\} }"           # bitbake env
  PS1+='$(__prompt_format_jobs \j)'                      # active jobs

  # TODO trim long path? may have to do it inside __git_color_path
  PS1+="$(__git_color_path)"
  PS1+="$(__prompt_exit_status ${__exit_status})"

  PS1+=' \[\033[36;1m\]\$\[\033[0m\] '                       # display the $ and reset color
  export PS1
}

# rebind 'enter' to set xterm title to the whole command being typed, regardless of pipes
__pre_line_accept_command()
{
  set_xterm_title "${READLINE_LINE}"
}

# use DEBUG trap for changing icon properly when starting stuff in a pipe
__debug_command()
{
  set_xwindows_icon "${BASH_COMMAND%% *}" o
}
trap "__debug_command; " DEBUG

# dummy bindings to work around shortcomings in libreadline
# TODO Maybe have a look at the numbers some time :)
bind -x $'"\200": "__pre_line_accept_command"'
bind -x $'"\201": "run_menu"'
bind -x $'"\202": "find_git_file"'
bind -x $'"\203": "insert_git_top"'
bind -x $'"\204": "insert_from_file ~/bin/paths"'
bind -x $'"\205": "insert_filename"'
bind -x $'"\206": "ft"'
bind $'"\307": accept-line'

# real bindings, maps to intermediate bindings above to work around libreadline limitations
bind '"\e[20~":'$'"\201"'        # F9
bind '"\eOR":'$'"\202"'          # F3
bind '"\e[19~":'$'"\203"'        # F8
bind '"\e[18~":'$'"\204"'        # F7
bind '"\e[19;2~":'$'"\205"'      # S-F8
bind '"\eOS":'$'"\206"'          # F4
bind '"\ep": history-search-backward'
bind '"\en": history-search-forward'
# Remap enter to run the "pre-command" hook.
bind $'"\C-m": "\200\307"'
bind $'"\C-j": accept-line'

function xvim() { xterm -e vim "$@" & }
alias tvim='vim -c "set buftype=nofile"'
alias cvim='vim -c "set buftype=nofile|0put *"'
alias ls="ls --color"
alias ll="ls -l --color"
alias gitk-a='git for-each-ref --format="^%(refname:short)" -- refs/notes/ | xargs gitk --all'
alias rcd="cd ~/repos; cd "

complete -F _complete_repos rcd

find_dmenu

PROMPT_COMMAND="__prompt_command"

export SHELL=/bin/bash
export MAKEFLAGS="-j $(nproc)"
export MAN_POSIXLY_CORRECT=1
export MANPATH=${MANPATH}:/usr/share/man
export PATH=${CONFIGS_PATH}/in-path:${PATH}
export EDITOR="vim"

# if xterm do xterm stuff
read PARENT_CMD < /proc/$PPID/comm
if [ "$PARENT_CMD" == "xterm" ]; then
  TERM_EMU_MSG=""
  rand_xterm_bg white
  rand_xterm_geometry
else
  TERM_EMU_MSG='\[\033[31m\]!${PARENT_CMD}!\[\033[0m\] '
fi
