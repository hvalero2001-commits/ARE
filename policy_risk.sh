#!/bin/bash

#
# ARE Risk Engine
#

RISK_TOTAL=0
RISK_REASONS=""


risk_reset() {

    RISK_TOTAL=0
    RISK_REASONS=""
    RISK_SIGNALS=""
}

risk_add() {

    local NAME="$1"
    local VALUE="${2:-0}"

    RISK_TOTAL=$((RISK_TOTAL + VALUE))

    if [ -z "$RISK_REASONS" ]; then
        RISK_REASONS="${NAME}:${VALUE}"
    else
        RISK_REASONS="${RISK_REASONS},${NAME}:${VALUE}"
    fi

    STATE="${STATUS:-NEW}"
    MULT=1

    if [ "$STATE" = "WATCH" ]; then
        MULT=1.5
    elif [ "$STATE" = "BANNED" ]; then
        MULT=2
    fi

VALUE=$(awk "BEGIN {print $2 * $MULT}")
}

risk_total() {

    echo "$RISK_TOTAL"
}

risk_reason() {

    echo "$RISK_REASONS"
}
