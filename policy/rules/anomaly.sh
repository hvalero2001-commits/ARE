#!/bin/bash

source "$BASE/policy_context.sh"

policy_anomaly() {

    local IP="$1"

    local SCORE=0
    local REASON="ANOMALY"

    # ejemplos de heurística
    SCORE=$(get_modsec_anomaly_score "$IP")

    if [ "$SCORE" -ge 5 ]; then
        echo "WATCH|$SCORE|$REASON"
        return 0
    fi

    if [ "$SCORE" -ge 10 ]; then
        echo "BLOCK|$SCORE|$REASON"
        return 0
    fi

    return 1
}
