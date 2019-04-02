[[ $- == *i* ]] || return

CONFIGS_PATH=~/configs

_complete_repos() {
  local cur
  pushd ~/repos > /dev/null
  COMPREPLY=( $(compgen -d -- ${2}) )
  popd > /dev/null
}
complete -F _complete_repos rcd
alias rcd="cd ~/repos; cd "

find_dmenu()
{
  # system-wide installed? if found we return immediately
  DMENU_PATH=$(which dmenu) && return

  # plan-b: look under configs.
  DMENU_PATH="${CONFIGS_PATH}/submodules/dmenu/dmenu"
  # if that guy is executable we already have a good value in DMENU_PATH and so we just return
  test -x ${DMENU_PATH} && return

  # plan-c: bail! (TODO: try to compile it)
  printf 'Dmenu not found\n'
  DMENU_PATH='DMENU_NOT_FOUND'
}

# git helpers

fr ()
{
  SUPERREPO="$PWD"/
  {
    git ls-files
    git submodule foreach --quiet --recursive "PREFIX=\${PWD##$SUPERREPO}/; git ls-files | ${CONFIGS_PATH}/c-programs/prefix \$PREFIX"
  } | ${DMENU_PATH} -l 40 -i | xargs gvim
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
  s=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ -z "$s" ]; then
    echo "Enter a git repo first."
    return 1
  fi
  tagname=$(${CONFIGS_PATH}/c-programs/dumptags -t ${s}/.git/tags -l | ${DMENU_PATH} -sb purple -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$tagname" ]; then return; fi

  gvim --cmd set\ tags+=${s}/.git/tags -t ${tagname}
}

ff()
{
  s=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ -z "$s" ]; then
    echo "Enter a git repo first."
    return 1
  fi
  fname=$(git ls-files --full-name ${s} | ${DMENU_PATH} -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$fname" ]; then return; fi

  vim ${s}/${fname}
}

function xxvim()
{
  xterm -tn xterm-256color -fa "Monospace" -fg Black -bg White -fs 11 +sb -e vim "$@" &
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
    eval ${cmds[$index]}
    history -s ${cmds[$index]}
  fi
}


run-menu ()
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
    eval ${cmds[$index]}
    history -s ${cmds[$index]}
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

  fname=$(git ls-files --full-name ${gittop} | ${CONFIGS_PATH}/c-programs/insdirs2 | ${DMENU_PATH} -i -l 50 -p ">" 2> /dev/null)
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

  fname=$(< ${1} ${DMENU_PATH} -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$fname" ]; then
    echo "The file ${1} was empty"
    return
  fi

  start=${READLINE_LINE:0:$READLINE_POINT}
  end=${READLINE_LINE:$READLINE_POINT}
  READLINE_LINE="${start}${fname}${end}"
  let READLINE_POINT+=${#fname}
}

xr ()
{
  xterm -geometry 65x150+10+10 -font -*-*-*-*-*-*-7-*-*-*-*-*-*-* -e "$* ; read i " &
}

xw ()
{
  xterm -geometry 130x150+10+10 -font -*-*-*-*-*-*-7-*-*-*-*-*-*-* -e "$* ; read i " &
}

function rand_xterm_bg()
{
  # Beautiful green: 4 36 48
  if [ -z $1 ]; then
    C=50
    let base=0
  else
    C=30
    let base=256-C
  fi
  r=$((base + (RANDOM * C) / 32767))
  g=$((base + (RANDOM * C) / 32767))
  b=$((base + (RANDOM * C) / 32767))

  # next line sets bg color
  printf "\e]11;#%02x%02x%02x\a" $r $g $b
  # make sure we have a readable foreground color as well
  if [ $base -gt 128 ]; then
    bgcolor=0
  else
    bgcolor=255
  fi
  printf "\e]10;#%02x%02x%02x\a" $bgcolor $bgcolor $bgcolor
  printf "\e]17;#%02x%02x%02x\a" $r $g $b
  printf "\e]19;#%02x%02x%02x\a" $bgcolor $bgcolor $bgcolor

  #echo $r $g $b
}

function get_xterm_bg()
{
  echo -en '\e]11;?\a'; IFS=\; read -s -d $'\a' _ col _
  echo $col
}

function v()
{
  filedir=$(dirname "$1")
  gitdir=$(git -C "${dir}" rev-parse --show-toplevel)

  gvim --servername ${gitdir} --remote-tab-silent "$1"
}

find_dmenu
read PCMD < /proc/$PPID/comm
if [ "$PCMD" == "xterm" ]; then rand_xterm_bg; fi
# TODO XXX set window position here as well!
#  echo -ne '\e[3;200;100t'
#  X resource allowWindowOps must be set

# dummy bindings to work around shortcomings in libreadline
bind $'"\201": "run-menu'
bind -x $'"\202": "ff"'
bind -x $'"\204": "insert_from_file ~/bin/paths"'
bind -x $'"\205": "insert_filename"'
bind -x $'"\203": "insert_git_top"'
bind -x $'"\206": "ft"'

# real bindings, make use of dummy bindings above to get something done
bind '"\e[20~":'$'"\201"'        # F9
bind '"\eOR":'$'"\202"'          # F3
bind '"\eOS":'$'"\206"'          # F4
bind '"\e[19~":'$'"\203"'        # F8
bind '"\e[19;2~":'$'"\205"'      # S-F8
bind '"\e[18~":'$'"\204"'        # F7

bind '"p": history-search-backward'
bind '"n": history-search-forward'

export MAN_POSIXLY_CORRECT=1
export MANPATH=${MANPATH}:/usr/share/man
export PATH=${CONFIGS_PATH}/in-path:${PATH}
export EDITOR="gvim -f"

alias xvim='xterm -tn xterm-256color -fa "Bitstream Vera Sans Mono" -fg Black -bg White -fs 10 +sb -e vim &'
alias vp='gvim -c "set buftype=nofile|0put *"'

# Prompt stuff: format the number of jobs and hide if 0
__prompt_format_jobs()
{
  a="$*"
  b=${a%0}
  printf "${b:+[$a] }"
  #printf ${b:+\\e[1;34m<\\e[0m}${b:=$*}
}

function __prompt_command()
{
  __exit_status="$?"
  _git_repo=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ $? != 0 ]; then
    xterm_title="$PWD"
  else
    xterm_title="${_git_repo##*/}"
  fi
  PS1='\[\033]0;${xterm_title}\a\]'                      # xterm title
  PS1+='\[\033[0m\]'                                     # reset all color
  PS1+='\[\033[1m\]\h '                                  # hostname

  PS1+='\[\033[0m\]'                                     # reset color
  PS1+="${OECORE_SDK_VERSION:+{$OECORE_SDK_VERSION\} }"  # bitbake env
  PS1+="${BUILDDIR:+{${BUILDDIR##*/build}\} }"           # build env

  PS1+='$(__prompt_format_jobs \j)'                      # active jobs

  _trimmed_pwd=${PWD:0-30}                               # trim path (this line returns empty string of not enough characters are available)
  PS1+="${_trimmed_pwd:+<}${_trimmed_pwd:=$PWD}"

  if [ "$__exit_status" != "0" ]; then                   # exit status from previous command
    if [ "$__exit_status" -gt 128 ]; then                # find signal name if exit status > 128
      signame=$(2>/dev/null kill -l $((__exit_status - 128)))
      if [ "$?" == "0" ]; then                           # verify that signal name could be found
        M=SIG${signame}
      else
        M=$__exit_status
      fi
    else
      M=$__exit_status
    fi
      PS1+=' [\[\e[1;31m\]'"$M"'\[\e[0m\]]'
  fi

  PS1+=' \[\033[1m\]\$\[\033[0m\] '                       # display the $ and reset color
  export PS1
}

PROMPT_COMMAND="__prompt_command"

alias ls="ls --color"
alias ll="ls -l --color"
alias gitk-a='git for-each-ref --format="^%(refname:short)" -- refs/notes/ | xargs gitk --all'
