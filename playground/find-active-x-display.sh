read myuid <<< $(id -u)
display="XXX"
while read sid uid _; do
    if [ "$uid" == "$myuid" ]; then
        read state <<< $(loginctl show-session $sid -P State)
        if [ "$state" == "active" ]; then
            read display <<< $(loginctl show-session $sid -P Display)
            break
        fi
    fi
done <<< $(loginctl list-sessions --no-legend)

echo $display
