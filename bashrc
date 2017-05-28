[[ $- == *i* ]] || return

CONFIGS_PATH=~/configs

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
    git submodule foreach --quiet --recursive "PREFIX=\${PWD##$SUPERREPO}/; git ls-files | ~/configs/c-programs/prefix \$PREFIX"
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

# Prompt stuff: format the number of jobs and hide if 0
disp_jobs()
{
  a="$*"
  b=${a%0}
  printf "${b:+[$a] }"
  #printf ${b:+\\e[1;34m<\\e[0m}${b:=$*}
}

# Prompt stuff: shrink the CWD string to max 30 chars
cut_path()
{
  a="$*"
  b=${a:0-30}
  printf ${b:+<}${b:=$*}
  #printf ${b:+\\e[1;34m<\\e[0m}${b:=$*}
}

# Prompt stuff: get git repo and branch into the xterm title
disp_gitinfo ()
{
  t=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ $? != 0 ]; then
    printf "No git repo"
    return
  fi
  b=$(git rev-parse --abbrev-ref HEAD)
  printf "${t} :: ${b}"
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

  gvim ${s}/${fname}
}

function xxvim()
{
  xterm -tn xterm-256color -fa "Bitstream Vera Sans Mono" -fg Black -bg White -fs 10 +sb -e vim "$@" &
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
  done < /home/hans/bin/xx
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
  done < /home/hans/bin/xx
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

  fname=$(git ls-files --full-name ${gittop} | ${CONFIGS_PATH}/c-programs/insdirs | ${DMENU_PATH} -i -l 50 -p ">" 2> /dev/null)
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

find_dmenu

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
export PATH=/home/hans/bin:${PATH}
export EDITOR="gvim -f"
#export GITTOP='git rev-parse --show-toplevel'

alias xvim='xterm -tn xterm-256color -fa "Bitstream Vera Sans Mono" -fg Black -bg White -fs 10 +sb -e vim &'
alias vp='gvim -c "set buftype=nofile|0put *"'

#export PS1='$(ppwd \l)\[\033[1m\]\h\[\033[0m\033]2;$(cleartool pwv -short)\h \a \]  $(cut_path \w) \$ '
export PS1='\[\033]2;$(disp_gitinfo)\a\033[1m\]\h\[\033[0m\] $(disp_jobs \j)$(cut_path \w) \[\033[1m\]\$\[\033[0m\] '
export MANPATH=${MANPATH}:/usr/share/man

alias ls="ls --color"
alias ll="ls -l --color"
alias gitk-a="gitk --all ^refs/notes/test_results ^refs/notes/test_results_with_errors"
alias gitk-a='git for-each-ref --format="^%(refname:short)" -- refs/notes/ | xargs gitk --all'
