#!/bin/bash

#############################################################
# ARE - Network Utilities
# IPv4 / IPv6 detection
#############################################################

get_ip_family() {

    local IP="$1"

    # IPv6 detecta ":" obligatorio
    if [[ "$IP" == *:* ]]; then
        echo "6"
        return 0
    fi

    # IPv4 default
    echo "4"
}

time_elapsed() {

    local TS="$1"
    local NOW DIFF

    [ -z "$TS" ] && echo "desconocido" && return 0

    NOW=$(date +%s)
    DIFF=$((NOW - TS))

    if [ "$DIFF" -lt 60 ]; then
        echo "hace ${DIFF} segundos"
    elif [ "$DIFF" -lt 3600 ]; then
        echo "hace $((DIFF / 60)) minutos"
    elif [ "$DIFF" -lt 86400 ]; then
        echo "hace $((DIFF / 3600)) horas"
    else
        echo "hace $((DIFF / 86400)) días"
    fi
}
