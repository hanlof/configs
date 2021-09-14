#!/bin/bash

print_and_run() {
	echo $1
	$1
}

set_panel_value() {

	print_and_run "xfconf-query -c xfce4-panel -p ${prefix}/$1 -t $2 -n -s $3"
}

find_highest() {
	sub="$2"
	_o=$(xfconf-query -l -c xfce4-panel -p $1)
	high=0
	set -a existing
	while IFS=/ read _ _ pan _; do
		if [ "${pan:0:${#sub}}" != "$sub" ]; then continue; fi
		n=${pan#$sub}
		existing[$n]=$n
		if [ "$n" -ge "$high" ]; then high="$n"; fi
	done <<< "$_o"
}

new_plugin() {

	echo xfconf-query -c xfce4-panel -p /plugins/plugin-$next_plugin -n -t string -s $1
	xfconf-query -c xfce4-panel -p /plugins/plugin-$next_plugin -n -t string -s $1
	plugin_ids+=" -t int -s $next_plugin "
	next_plugin=$((next_plugin + 1))
}

plugin_property() {
	echo xfconf-query -c xfce4-panel -p /plugins/plugin-$((next_plugin - 1))/$1 -n -t $2 -n -s $3
	xfconf-query -c xfce4-panel -p /plugins/plugin-$((next_plugin - 1))/$1 -n -t $2 -n -s $3
}

find_highest "/panels" "panel-"
echo high $high
new_panel_number=$((high + 1))
echo new panel $new_panel_number
active_panels=""
for i in ${existing[*]}; do
	active_panels+="-t int -s $i "
done

active_panels+="-t int -s ${new_panel_number}"

find_highest "/plugins" "plugin-"

next_plugin=$((high + 1))
new_plugin=plugin-${next_plugin}

echo $new_plugin
new_panel=panel-${new_panel_number}
prefix=/panels/${new_panel}
set_panel_value size uint 32
set_panel_value icon-size uint 0
set_panel_value autohide-behavior int 0
set_panel_value disable-struts bool true
set_panel_value icon-size int 16
set_panel_value length int 100
set_panel_value length-adjust bool false
set_panel_value mode int 0
set_panel_value position string "p=8;x=960;y=1055"
set_panel_value position-locked bool true
echo xfconf-query -c xfce4-panel -p /panels ${active_panels}
xfconf-query -c xfce4-panel -p /panels ${active_panels}

#TODO then make a plugin_property function! :-D

plugin_ids=""

new_plugin applicationsmenu
plugin_property show-button-title bool false
new_plugin pager
plugin_property nows uint 1
new_plugin tasklist
new_plugin separator
plugin_property expand bool true
plugin_property style uint 0
# INTERESTING! xkb can only exist on one panel. not multiple :O
new_plugin xkb
plugin_property display-name uint 1
plugin_property display-type uint 1
plugin_property group-policy uint 0
new_plugin notification-plugin
new_plugin battery
new_plugin pulseaudio
new_plugin systray
new_plugin clock
#TODO make sure all plugins are installed :$

xfconf-query -c xfce4-panel -p $prefix/plugin-ids -n $plugin_ids

# restart xfce4-panel in order to make it honor the new panel
xfce4-panel -r

# not panel related
#  Desktop Theme
xfconf-query -c xsettings -p /Net/ThemeName -s Yaru-light

#  Keyboard
xfconf-query -c keyboard-layout -p /Default/XkbDisable -t bool -n -s false
xfconf-query -c keyboard-layout -p /Default/XkbLayout -t string -n -s "dvorak,se,se"
xfconf-query -c keyboard-layout -p /Default/XkbVariant -t string -n -s ",dvorak,"
xfconf-query -c keyboard-layout -p /Default/XkbOptions/Group -t string -n -s "grp:alt_caps_toggle"

