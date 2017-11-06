#!/bin/bash


monitor_configs=(
  "DP-1-1-8 eDP-1-1 DP-1-1-1"
  "DP-0.8 eDP-1-1 DP-0.1"
  "eDP-1-1"
)
commands=(
  "xrandr --output DP-1-1-8 --primary --mode 1920x1200 --pos 0x0 --rotate normal --output DP-1-1-1 --mode 1920x1200 --pos 1920x0 --rotate normal --output HDMI-1-1 --off --output eDP-1-1 --mode 1920x1080 --pos 3840x768 --rotate normal --output DP-1 --off --output DP-1-1-1 --off --output DP-1-1-8 --off --output DP-1-1 --off --output DP-0 --off"
  "xrandr --output DP-0.8 --primary --mode 1920x1200 --pos 0x0 --rotate normal --output DP-0.1 --mode 1920x1200 --pos 1920x0 --rotate normal --output HDMI-1-1 --off --output eDP-1-1 --mode 1920x1080 --pos 3840x768 --rotate normal --output DP-1 --off --output DP-1-1-1 --off --output DP-1-1-8 --off --output DP-1-1 --off --output DP-0 --off"
  "xrandr --output eDP-1-1 --mode 1920x1080 --pos 0x0 --rotate normal"
)
names=(
  "port 1"
  "port 2"
  "No external monitors"
)

XRANDR_OUTPUT="$(xrandr | grep '\<connected\>')"
select_configuration=-1
echo -n "Have screens: "
while read name _; do
  test -z "$name" && continue
  echo -n "$name "
  for (( i = 0; i < ${#monitor_configs[@]}; i++ )); do
    orig=${monitor_configs[$i]}
    tmp=${orig/$name}
    if [ "$tmp" == "$orig" ]; then
      monitor_configs[$i]+=" $name"
    else
      monitor_configs[$i]="$tmp"
    fi
    if [ -z ${monitor_configs[$i]// } ]; then
      select_configuration=$i
    fi
  done

  #echo $name
done <<< "$XRANDR_OUTPUT"

for (( i = 0; i < ${#monitor_configs[@]}; i++ )); do
  if [ -z ${monitor_configs[$i]// } ]; then
    select_configuration=$i
    break
  fi
done

echo

if [ $select_configuration -ge 0 ]; then
  echo Detected configuration: ${names[$select_configuration]}
  echo command is ${commands[$i]}
fi
