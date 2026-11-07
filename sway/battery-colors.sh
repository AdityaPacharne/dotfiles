#!/bin/bash
[ "$(pgrep -c -f battery-colors.sh)" -gt 1 ] && exit

BATTERY="/sys/class/power_supply/macsmc-battery/capacity"
PREV=""
while true; do
    LEVEL=$(cat "$BATTERY")
    STATE=$([ "$LEVEL" -le 20 ] && echo "low" || echo "ok")
    if [ "$STATE" != "$PREV" ]; then
        if [ "$STATE" = "low" ]; then
            swaymsg "client.focused #cc241d #cc241d #ebdbb2 #cc241d #cc241d"
        else
            swaymsg "client.focused #458588 #458588 #ebdbb2 #83a598 #458588"
        fi
        PREV="$STATE"
    fi
    sleep 30
done
