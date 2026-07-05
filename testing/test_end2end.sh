#!/bin/bash
test_end2end() {

    local IP="$1"
    local EVENT="$2"

    if [ -z "$IP" ] || [ -z "$EVENT" ]; then
        echo "[ERROR] missing args"
        return 1
    fi

    echo "[INFO] STATE INIT IP=$IP"
    state_set "$IP" NEW

    risk_reset
    risk_add_from_event "$EVENT"

    local TOTAL=$(risk_total)
    echo "[INFO] RISK TOTAL=$TOTAL"

    local DECISION=$(policy_decide "$TOTAL" NEW)
    echo "[INFO] DECISION=$DECISION"

    apply_decision "$IP" "$DECISION"

    state_get "$IP"
}
