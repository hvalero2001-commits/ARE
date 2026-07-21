#!/bin/bash

policy_decide() {

    local RISK="${1:-0}"
    local STATUS="${2:-NEW}"

    # HARD OVERRIDE
    if [ "$STATUS" = "BANNED" ]; then
        echo "BAN|0|STATE_BANNED"
        return 0
    fi

    # CRITICAL 24H
    if [ "$RISK" -ge 200 ]; then
        echo "TEMP_BAN|3600|CRITICAL"
	return 0
    fi

    # CRITICAL
    if [ "$RISK" -ge 150 ]; then
        echo "BAN|0|RISK_HIGH"
        return 0
    fi


    # MEDIUM
    if [ "$RISK" -ge 100 ]; then
        echo "WATCH|0|RISK_MEDIUM"
        return 0
    fi

    # DEFAULT
    echo "ALLOW|0|DEFAULT"
    return 0
}
