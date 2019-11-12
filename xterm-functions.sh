#!/bin/bash

_query_xterm_debug() {
  #echo -n $'\e['9\;1t # maximize window
  #echo -n $'\e['9\;0t # unmaximize window
  # 19 = height, width in characters
  echo -n $'\e['${1}t
  # -t    -- timeout (seconds)
  # -s    -- silent
  # -d t  -- read until 't' is received
  IFS=";" read -t 0.1 -d t a b c d e f
  if [ $? -gt 128 ]; then
    echo empty reply
  else
    echo
  fi
  #echo "$a $b $c $d $e $f"
}

_get_workarea() {
  cd_prop=($(xprop -notype -root _NET_CURRENT_DESKTOP))
  desktop_number=${cd_prop[2]}
  IFS=", " wa_prop=($(xprop -notype -root _NET_WORKAREA))
  let ofs=2+desptop_number*4
  let x=wa_prop[ofs+0]
  let y=wa_prop[ofs+1]
  let w=wa_prop[ofs+2]
  let h=wa_prop[ofs+3]
  declare -g x y w h
}

# TODO: replace wl, wr commands with awesome generic window manipulation function
#       Example: window_manip 2/1 3/2 to partition the screen in 2 equal parts for X
#                and 3 equal parts for y, and use first slot for x and second slot for y
# TODO: put in in-path/ ?
res() {
  _get_workarea
  echo -n $'\e['18t
  IFS=";" read -t 0.1 -d t -s _ h w _
  mode=SIZE
  while true; do
    case $mode in
      SIZE) let _x=w; let _y=h ;;
      POS) let _x=x; let _y=y ;;
    esac
    echo -n $'\x0d\e[2K'$mode $_x, $_y
    read -n 1 -s -d '' i
    printf -v key_index %d \'$i\'
    case $key_index in
      10) i=q;;
      13) i=q;;
      27) i=q;; # maybe parse escape seq here?!
    esac
    case $i in
      j) let _y+=1;;
      J) let _y+=5;;
      k) let _y-=1;;
      K) let _y-=5;;
      l) let _x+=1;;
      L) let _x+=5;;
      h) let _x-=1;;
      H) let _x-=5;;
      o|O)
        case $mode in POS) mode=SIZE;; SIZE) mode=POS ;; esac
        echo -n $'\e['18t
        IFS=";" read -t 0.1 -d t -s _ h w _
        echo -n $'\e['13t
        IFS=";" read -t 0.1 -d t -s _ x y _
        continue ;;
      x|X|q|Q) break;;
      *) echo "$key_index";;
    esac
    case $mode in
      SIZE) let h=_y w=_x; echo -ne "\e[8;${h};${w}t" ;;
      POS) let x=_x y=_y; echo -ne "\e[3;${x};${y}t"
    esac
  done
  echo " Bye!"
}

wl() {
  _get_workarea
  echo $x $y $w $h
  let neww=w/2
  echo $newx $y $neww $h
  # set new size
  echo -ne "\e[4;${h};${neww}t"
  # set new pos
  echo -ne "\e[3;${newx};${y}t"
}

wr() {
  _get_workarea
  echo $x $y $w $h
  let neww=w/2
  let newx=x+w/2
  echo $newx $y $neww $h
  # set new pos
  echo -ne "\e[4;${h};${neww}t"
  # set new size
  echo -ne "\e[3;${newx};${y}t"
}

function rand_xterm_geometry()
{
  _get_workarea # in pixels

  # xmargin and ymargin is being used as both the "margin" and the "random"
  # part of the offset from the edge of the screen
  # could change that... possibly... maybe
  let xmargin="((w*100)/(10))/100" # fixed point math is being employed because bash can't handle decimals
  let ymargin="((h*100)/(10))/100"
  xpos=$((xmargin+(RANDOM*xmargin)/32767))
  ypos=$((ymargin+(RANDOM*ymargin)/32767))
  rightdist=$((xmargin+(RANDOM*xmargin)/32767))
  botdist=$((ymargin+(RANDOM*ymargin)/32767))
  xsize=$((w-xpos-rightdist))
  ysize=$((h-ypos-botdist))

  # set new position
  echo -ne "\e[3;${xpos};${ypos}t"
  # set new size
  echo -ne "\e[4;${ysize};${xsize}t"
}

function set_xterm_title()
{
  echo -ne "\033]0;${1}\a"
}

function set_xterm_cursor_color()
{
  echo -ne "\033]12;${1}\a"
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
