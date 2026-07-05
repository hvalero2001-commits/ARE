#!/bin/bash

assert_state() {

    local IP="$1"
    local EXPECTED="$2"

    local ACTUAL
    ACTUAL=$(state_get "$IP")

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        echo "[ASSERT OK] STATE=$ACTUAL"
        return 0
    else
        echo "[ASSERT FAIL] expected=$EXPECTED got=$ACTUAL"
        return 1
    fi
}

assert_risk() {

    local EXPECTED="$1"
    local ACTUAL
    ACTUAL=$(risk_total)

    if [ "$ACTUAL" -eq "$EXPECTED" ]; then
        echo "[ASSERT OK] RISK=$ACTUAL"
        return 0
    else
        echo "[ASSERT FAIL] expected=$EXPECTED got=$ACTUAL"
        return 1
    fi
}

assert_decision() {

    local EXPECTED="$1"
    local ACTUAL="$DECISION"

    if [[ "$ACTUAL" == "$EXPECTED"* ]]; then
        echo "[ASSERT OK] DECISION=$ACTUAL"
        return 0
    else
        echo "[ASSERT FAIL] expected=$EXPECTED got=$ACTUAL"
        return 1
    fi
}
