#!/bin/bash
policy_rule_recon() {

    local IP="$1"
    local CTX="$2"

    local SCORE
    local RECON

    SCORE=$(ctx_get_total "$CTX")
    RECON=$(ctx_get_recon "$CTX")

    SCORE=${SCORE:-0}
    RECON=${RECON:-0}

    if [ "$RECON" -ge 150 ]; then
        echo "TEMP_BAN|3600|HIGH_RECON_ACTIVITY"
        return 0
    fi

    if [ "$SCORE" -ge 100 ]; then
        echo "WATCH|0|RECON_ACTIVITY"
        return 0
    fi

    return 1
}
