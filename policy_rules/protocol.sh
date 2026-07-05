#!/bin/bash
policy_rule_protocol() {

    local IP="$1"
    local CTX="$2"

    local SCORE
    local PROTOCOL

    SCORE=$(ctx_get_total "$CTX")
    PROTOCOL=$(ctx_get_protocol "$CTX")

    SCORE=${SCORE:-0}
    PROTOCOL=${PROTOCOL:-0}

    if [ "$PROTOCOL" -ge 100 ]; then
        echo "WATCH|0|PROTOCOL_ANOMALY"
        return 0
    fi

    return 1
}
