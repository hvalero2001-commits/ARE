#!/bin/bash
source "$BASE/policy_context.sh"
source "$BASE/policy_context_api.sh"

policy_evaluate() {

    local IP="$1"

    local RESULT

    RESULT=$(policy_run_rules "$IP")

    if [ -n "$RESULT" ]; then
        echo "$RESULT"
        return 0
    fi

    echo "ALLOW|0|DEFAULT"
}

policy_run_rules() {

    local IP="$1"

    local RESULT=""

    for rule in "${POLICY_RULES[@]}"; do

        RESULT=$($rule "$IP")

        if [ -n "$RESULT" ]; then
            echo "$RESULT"
            return 0
        fi

    done
}
