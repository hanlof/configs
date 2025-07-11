[[ $- == *i* ]] || return

if [[ "$0" != "$BASH_SOURCE" ]]; then
	CONFIGS_PATH=$(realpath $(dirname "$BASH_SOURCE"))
else
	CONFIGS_PATH=$(realpath $(dirname "$0"))
fi

source ${CONFIGS_PATH}/bash/xwindows-icon-functions.sh
source ${CONFIGS_PATH}/bash/xterm-functions.sh
source ${CONFIGS_PATH}/bash/prompt-functions.sh

_complete_repos() {
  local cur
  test -d ~/sources || return
  pushd ~/sources > /dev/null
  COMPREPLY=( $(compgen -G "*${2}*") )
  popd > /dev/null
}

_complete_htdock() {
  local cur
  cd ~/sources/haleytek-dhu
  COMPREPLY=( $(compgen -W "di qnx aosp aosp-intel safety nonhlos polyspace gradle device-testing cts emulator yocto" "$2"))
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

check_cwd_in_reporepo()
{
  s=$(repo --show-toplevel 2> /dev/null)
  if [ "$?" -ne 0 ]; then
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
  check_cwd_in_gitrepo || {
    check_cwd_in_reporepo "Enter git repo or repo repo" || return 1
    find_dmenu
    dirname=$(repo list -p | ${DMENU_PATH} -w $WINDOWID -i -l 50 -p ">" 2> /dev/null)
    if [ -z "$dirname" ]; then return; fi

    history -s cd ${dirname}
    fc -s
    return
  }

  check_cwd_in_gitrepo "Enter git repo first." || return 1
  find_dmenu
  gittop=$(git rev-parse --show-toplevel 2> /dev/null)
  fname=$(git ls-files "${gittop}" | ${DMENU_PATH} -w $WINDOWID -i -l 50 -p ">" 2> /dev/null)
  if [ -z "$fname" ]; then return; fi

  history -s vim ${fname}
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

# TODO: redo this so it modifies READLINE_LINE and READLINE_POINT instead of playing with eval
#       and then add accept-line to the key binding so this stuff shows shows properly on the screen
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

  declare -g EXTENDED_PROMPT
  # reset window icon to standard bash when prompt is shown

  if [ -z "$TERM_EMU_MSG" ]; then
    set_xwindows_icon term-base-centered
  fi
  # Xterm title
  _git_repo=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ $? != 0 ]; then
    xterm_title="${PWD}/"
  else
    xterm_title="<${_git_repo##*/}>"
  fi
  set_xterm_title "$ ${xterm_title}"                 # xterm title

  PS1=""
  # Sanitise terminal just in case any app left in in a bad state
  PS1+='\[\[\033[?1000l\033[?9l\033[>4;m\]'
  if [ "$EXTENDED_PROMPT" -eq 1 ]; then
    PS1+='\[\033[0;40m\]'
    PS1+='\D{} '
    s=$(git rev-parse --show-toplevel 2> /dev/null)
    if [ -z "$s" ]; then
      PS1+="<no git repo>"
    else
      branch=$(git branch --show-current)
      if [ -z "$branch" ]; then
        branch="D:$(git rev-parse --short HEAD)"
      else
        branch=$(git branch --list "${branch}" --format="%(refname:short) %(upstream:track)")
      fi
      PS1+="$branch"
    fi
    PS1+='\[\033[0m\]\r\n'
  fi
  if [ ! -z "$VIRTUAL_ENV_PROMPT" ]; then
    PS1+='\[\033[32m\]VENV:${VIRTUAL_ENV_PROMPT}'
  fi
  PS1+='\[\033[0m\]'                                     # reset all color
  NPS=(/proc/[123456789]*)
  if [ "${#NPS[*]}" -lt 20 ]; then
    PS1+='\[\033[32m\]DOCK(\h) '                                  # hostname
  else
    PS1+='\[\033[33m\]\h '                                  # hostname
  fi

  PS1+=${TERM_EMU_MSG}

  PS1+='\[\033[0m\]'                                     # reset color
  PS1+="${OECORE_SDK_VERSION:+{$OECORE_SDK_VERSION\} }"  # build env
  PS1+="${BUILDDIR:+{${BUILDDIR##*/build}\} }"           # bitbake env
  PS1+='$(__prompt_format_jobs \j)'                      # active jobs

  # TODO trim long path? may have to do it inside __git_color_path
  PS1+="$(__git_color_path)"
  PS1+="$(__prompt_exit_status ${__exit_status})"

  PS1+=' \[\033[1;38;5;6m\]\$\[\033[0m\] '               # display the $ and reset color
  PS1+='\[\033[2 q\]'                                    # set the cursor to blinking block
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
  if [ -z "$TERM_EMU_MSG" ]; then
    set_xwindows_icon "${BASH_COMMAND%% *}" o
  fi
}
trap "__debug_command; " DEBUG

restore_readline_state()
{
	READLINE_LINE="$READLINE_LINE_"
	READLINE_POINT="$READLINE_POINT_"
}

save_readline_state()
{
	READLINE_LINE_="$READLINE_LINE"
	READLINE_POINT_="$READLINE_POINT"
}

export EXTENDED_PROMPT=0
__toggle_extended_prompt()
{
	save_readline_state
	declare -g EXTENDED_PROMPT
	echo -ne '\e[2K\e[100D'
	echo -ne '\e[1A\e[2K\e[100D'
	if [ "$EXTENDED_PROMPT" -eq 1 ]; then
		echo -ne '\e[1A\e[2K\e[100D'
	fi
	let EXTENDED_PROMPT^=1
	export EXTENDED_PROMPT
	true
	__prompt_command
}

bind "set convert-meta off"
bind "set input-meta on"
bind "set output-meta on"
bind 'set enable-bracketed-paste off'

MAGIC_BIND_NUM=135 # 0x87 0o207

get_next_mapping_char()
{
	declare -n OUTPUT_VAR=$1
	hexcode=$(printf %x $MAGIC_BIND_NUM)
	OUTPUT_VAR=$(printf \\x"$hexcode")
	let MAGIC_BIND_NUM+=1
}

# take a key sequence (arg1) and bind it to something (arg2) via intermediate single-character sequence
magic_bind_x()
{
	term_code="$1"
	get_next_mapping_char __char
	if [ "$term_code" != "" ]; then
		bind \""$term_code"\":\""$__char"\"
	fi
	if [ "$#" -gt 2 ]; then
		declare -n varref=$3
		varref="$__char"
	fi
	bind -x \""$__char"\":"$2"
}

magic_bind()
{
	term_code="$1"
	get_next_mapping_char __char
	if [ "$term_code" != "" ]; then
		bind \""$term_code"\":\""$__char"\"
	fi
	if [ "$#" -gt 2 ]; then
		declare -n varref=$3
		varref="$__char"
	fi
	bind \""$__char"\":"$2"
}

magic_bind_x $(tput kf3)  "find_git_file"
magic_bind_x $(tput kf4)  "ft"
magic_bind_x $(tput kf7)  "insert_from_file ~/bin/paths"
magic_bind_x $(tput kf8)  "insert_git_top"
magic_bind_x $(tput kf9)  "run_menu"
magic_bind_x $(tput kf20) "insert_filename" # kf20 = S-F8
magic_bind_x "" "__pre_line_accept_command" __pre_line_accept_char
magic_bind_x "" "__toggle_extended_prompt" __toggle_extended_prompt_char
magic_bind_x "" "restore_readline_state" __restore_readline_state_char
magic_bind_x "\e[68~" "mouse-reporting.sh"        # ctrl-shift-RMB (bound in Xresources)
magic_bind "" "kill-whole-line" __kill_line_char
magic_bind "" "accept-line" __accept_line_char
bind "\"$(tput kf12)\": \"${__toggle_extended_prompt_char}${__kill_line_char}${__accept_line_char}$__restore_readline_state_char\""
bind '"\ep": history-search-backward'
bind '"\en": history-search-forward'
# Remap enter to run the "pre-command" hook.
bind $'"\C-m": "'"${__pre_line_accept_char}${__accept_line_char}"'"'
# C-j is backup "accept-line" just in case...
bind $'"\C-j": accept-line'

function xvim() { xterm -e vim "$@" & }
alias tvim='vim -c "set buftype=nofile"'
alias cvim='vim -c "set buftype=nofile|0put *"'
alias ls="ls --color=auto"
alias ll="ls -l --color=auto"
alias gitk-a='git for-each-ref --format="^%(refname:short)" -- refs/notes/ | xargs gitk --all'
alias rcd="cd ~/sources; cd "
alias dock="cd ~/sources/haleytek-dhu; ./tools/haleytek/docker-images/run.py --target "
alias vims="vim -S"
alias screen="LC_ALL=en_US.UTF-8 screen"
alias edxr="vim ~/.Xresources ; xrdb -merge ~/.Xresources"

function gstatus()
{
  check_cwd_in_gitrepo "Enter git repo first." || return 1
  vim -c "call FugitiveDetect('.') | tab 1G | 1tabclose"
}

alias gstat=gstatus

complete -F _complete_repos rcd
complete -F _complete_htdock dock

find_dmenu

PROMPT_COMMAND="__prompt_command"

export SHELL=/bin/bash
export MAN_POSIXLY_CORRECT=1
export MANPATH=${MANPATH}:/usr/share/man
export PATH=${CONFIGS_PATH}/in-path:${PATH}
export EDITOR=vim
export LESSCHARSET=utf-8
export MAKEFLAGS="-j $(nproc)"
export HISTSIZE=10000
export HISTFILESIZE=10000

history -n

LS_COLORS="no=00;38;5;244:rs=0:di=00;38;5;33:ln=01;38;5;37:mh=00:pi=48;5;230;38;5;136;01:so=48;5;230;38;5;136;01:"
LS_COLORS+="do=48;5;230;38;5;136;01:bd=48;5;230;38;5;244;01:cd=48;5;230;38;5;244;01:or=48;5;235;38;5;160:"
LS_COLORS+="su=48;5;160;38;5;230:sg=48;5;136;38;5;230:ca=30;41:tw=48;5;64;38;5;230:ow=48;5;235;38;5;33:st=48;5;33;38;5;230:"
LS_COLORS+="ex=01;38;5;64:*.tar=00;38;5;61:*.tgz=01;38;5;61:*.arj=01;38;5;61:*.taz=01;38;5;61:*.lzh=01;38;5;61:*.lzma=01;38;5;61:"
LS_COLORS+="*.tlz=01;38;5;61:*.txz=01;38;5;61:*.zip=01;38;5;61:*.z=01;38;5;61:*.Z=01;38;5;61:*.dz=01;38;5;61:*.gz=01;38;5;61:"
LS_COLORS+="*.lz=01;38;5;61:*.xz=01;38;5;61:*.bz2=01;38;5;61:*.bz=01;38;5;61:*.tbz=01;38;5;61:*.tbz2=01;38;5;61:*.tz=01;38;5;61:"
LS_COLORS+="*.deb=01;38;5;61:*.rpm=01;38;5;61:*.jar=01;38;5;61:*.rar=01;38;5;61:*.ace=01;38;5;61:*.zoo=01;38;5;61:"
LS_COLORS+="*.cpio=01;38;5;61:*.7z=01;38;5;61:*.rz=01;38;5;61:*.apk=01;38;5;61:*.gem=01;38;5;61:*.jpg=00;38;5;136:"
LS_COLORS+="*.JPG=00;38;5;136:*.jpeg=00;38;5;136:*.gif=00;38;5;136:*.bmp=00;38;5;136:*.pbm=00;38;5;136:*.pgm=00;38;5;136:"
LS_COLORS+="*.ppm=00;38;5;136:*.tga=00;38;5;136:*.xbm=00;38;5;136:*.xpm=00;38;5;136:*.tif=00;38;5;136:*.tiff=00;38;5;136:"
LS_COLORS+="*.png=00;38;5;136:*.svg=00;38;5;136:*.svgz=00;38;5;136:*.mng=00;38;5;136:*.pcx=00;38;5;136:*.dl=00;38;5;136:"
LS_COLORS+="*.xcf=00;38;5;136:*.xwd=00;38;5;136:*.yuv=00;38;5;136:*.cgm=00;38;5;136:*.emf=00;38;5;136:*.eps=00;38;5;136:"
LS_COLORS+="*.CR2=00;38;5;136:*.ico=00;38;5;136:*.tex=01;38;5;245:*.rdf=01;38;5;245:*.owl=01;38;5;245:*.n3=01;38;5;245:"
LS_COLORS+="*.ttl=01;38;5;245:*.nt=01;38;5;245:*.torrent=01;38;5;245:*.xml=01;38;5;245:*Makefile=01;38;5;245:"
LS_COLORS+="*Rakefile=01;38;5;245:*build.xml=01;38;5;245:*rc=01;38;5;245:*1=01;38;5;245:*.nfo=01;38;5;245:*README=01;38;5;245:"
LS_COLORS+="*README.txt=01;38;5;245:*readme.txt=01;38;5;245:*.md=01;38;5;245:*README.markdown=01;38;5;245:*.ini=01;38;5;245:"
LS_COLORS+="*.yml=01;38;5;245:*.cfg=01;38;5;245:*.conf=01;38;5;245:*.c=01;38;5;245:*.cpp=01;38;5;245:*.cc=01;38;5;245:"
LS_COLORS+="*.log=00;38;5;240:*.bak=00;38;5;240:*.aux=00;38;5;240:*.lof=00;38;5;240:*.lol=00;38;5;240:*.lot=00;38;5;240:"
LS_COLORS+="*.out=00;38;5;240:*.toc=00;38;5;240:*.bbl=00;38;5;240:*.blg=00;38;5;240:*~=00;38;5;240:*#=00;38;5;240:"
LS_COLORS+="*.part=00;38;5;240:*.incomplete=00;38;5;240:*.swp=00;38;5;240:*.tmp=00;38;5;240:*.temp=00;38;5;240:*.o=00;38;5;240:"
LS_COLORS+="*.pyc=00;38;5;240:*.class=00;38;5;240:*.cache=00;38;5;240:*.aac=00;38;5;166:*.au=00;38;5;166:*.flac=00;38;5;166:"
LS_COLORS+="*.mid=00;38;5;166:*.midi=00;38;5;166:*.mka=00;38;5;166:*.mp3=00;38;5;166:*.mpc=00;38;5;166:*.ogg=00;38;5;166:"
LS_COLORS+="*.ra=00;38;5;166:*.wav=00;38;5;166:*.m4a=00;38;5;166:*.axa=00;38;5;166:*.oga=00;38;5;166:*.spx=00;38;5;166:"
LS_COLORS+="*.xspf=00;38;5;166:*.mov=01;38;5;166:*.mpg=01;38;5;166:*.mpeg=01;38;5;166:*.m2v=01;38;5;166:*.mkv=01;38;5;166:"
LS_COLORS+="*.ogm=01;38;5;166:*.mp4=01;38;5;166:*.m4v=01;38;5;166:*.mp4v=01;38;5;166:*.vob=01;38;5;166:*.qt=01;38;5;166:"
LS_COLORS+="*.nuv=01;38;5;166:*.wmv=01;38;5;166:*.asf=01;38;5;166:*.rm=01;38;5;166:*.rmvb=01;38;5;166:*.flc=01;38;5;166:"
LS_COLORS+="*.avi=01;38;5;166:*.fli=01;38;5;166:*.flv=01;38;5;166:*.gl=01;38;5;166:*.m2ts=01;38;5;166:*.divx=01;38;5;166:"
LS_COLORS+="*.webm=01;38;5;166:*.axv=01;38;5;166:*.anx=01;38;5;166:*.ogv=01;38;5;166:*.ogx=01;38;5;166:"
export LS_COLORS

# if xterm do xterm stuff
read PARENT_CMD < /proc/$PPID/comm
if [ "$PARENT_CMD" == "xterm" ]; then
  TERM_EMU_MSG=""
else
  TERM_EMU_MSG='\[\033[31m\]!${PARENT_CMD}!\[\033[0m\] '
fi

# never again be terrorized by locale BS
export -n LANG LANGUAGE LC_NUMERIC LC_CTYPE LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION LC_ALL
unset LANG LANGUAGE LC_NUMERIC LC_CTYPE LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION LC_ALL
# but apparently CTYPE is useful or readline will be confused about multibyte characters
locales=$(locale -a)
while read l # find the apropriate utf8 locale in available locales
    do if [[ $l =~ (C.UTF-8|C.utf8) ]]; then
        export LC_ALL=$l
        break
    fi
done <<< "$locales"

