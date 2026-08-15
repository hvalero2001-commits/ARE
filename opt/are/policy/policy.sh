#!/bin/bash
#############################################################
#
# ARE Policy Engine
#
#############################################################

policy_load() {

    source "$ARE_POLICY_CONFIG"

}

source "$ARE_POLICY_DIR/core.sh"
source "$ARE_POLICY_DIR/exploit.sh"
source "$ARE_POLICY_DIR/recon.sh"
source "$ARE_POLICY_DIR/bruteforce.sh"
source "$ARE_POLICY_DIR/bot.sh"
source "$ARE_POLICY_DIR/protocol.sh"


#############################################################

policy_action() {

    local SCORE="$1"

    if [ "$SCORE" -ge "$PERMANENT_BAN_SCORE" ]
    then
        echo "PERMANENT_BAN"

    elif [ "$SCORE" -ge "$TEMP_BAN_SCORE" ]
    then
        echo "TEMP_BAN"

    elif [ "$SCORE" -ge "$WATCH_SCORE" ]
    then
        echo "WATCH"

    else
        echo "IGNORE"

    fi
}

#############################################################

policy_timeout() {

    case "$1" in

        WATCH)

            echo "$WATCH_TIMEOUT"

        ;;

        TEMP_BAN)

            echo "$TEMP_BAN_TIMEOUT"

        ;;

        PERMANENT_BAN)

            echo "$PERMANENT_BAN_TIMEOUT"

        ;;

        *)

            echo 0

        ;;

    esac

}

#############################################################

policy_should_block() {

    local SCORE="$1"

    [ "$SCORE" -ge "$TEMP_BAN_SCORE" ]
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

POLICY_RULES=(
    policy_rule_exploit
    policy_rule_bruteforce
    policy_rule_recon
    policy_rule_protocol
    policy_rule_bot
)

