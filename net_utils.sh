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
