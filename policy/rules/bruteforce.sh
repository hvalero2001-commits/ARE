#!/bin/bash
policy_rule_bruteforce() {

    local IP="$1"
    local CTX="$2"

    local SCORE
    local EVENTS


    SCORE=$(ctx_get_total "$CTX")
    EVENTS=$(ctx_get_events_24h "$CTX")

    SCORE=${SCORE:-0}
    EVENTS=${EVENTS:-0}

    if [ "$EVENTS" -ge 50 ]; then
        echo "BAN|86400|BRUTEFORCE_DETECTED"
        return 0
    fi

    if [ "$EVENTS" -ge 20 ]; then
        echo "TEMP_BAN|3600|BRUTEFORCE_SUSPICIOUS"
        return 0
    fi

    return 1
}
