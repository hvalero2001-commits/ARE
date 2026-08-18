#!/bin/bash
policy_decide() {

    local TOTAL="$1"
    local STATUS="$2"

    # HARD OVERRIDE
    if [ "$STATUS" = "BANNED" ]; then
        echo "BAN|0|STATE_BANNED"
        return 0
    fi

    if [ "$TOTAL" -ge 80 ]; then
        echo "BAN|0|HIGH_RISK"
        return 0
    fi

    if [ "$TOTAL" -ge 50 ]; then
        echo "TEMP_BAN|3600|MEDIUM_RISK"
        return 0
    fi

    if [ "$TOTAL" -ge 20 ]; then
        echo "FILTER|0|LOW_RISK"
        return 0
    fi

    if [ "$TOTAL" -gt 0 ]; then
        echo "WATCH|0|MINIMAL_RISK"
        return 0
    fi

    echo "ALLOW|0|NO_RISK"
}
