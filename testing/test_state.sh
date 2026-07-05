#!/bin/bash

test_state() {

    local IP="$1"
    local EXPECTED="$2"

    if [ -z "$IP" ] || [ -z "$EXPECTED" ]; then
        echo "[ERROR] usage: test_state <IP> <EXPECTED_STATE>"
        return 1
    fi

    state_set "$IP" "$EXPECTED"

    assert_state "$IP" "$EXPECTED"
}
