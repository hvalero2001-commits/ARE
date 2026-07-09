#!/bin/bash

BASE="/opt/f2b-ipset"

source "$BASE/logger.sh"
source "$BASE/validator.sh"
source "$BASE/database.sh"

policy_apply() {

    local IP="$1"
    local ACTION="$2"
    local TIMEOUT="$3"
    local REASON="$4"

    INFO "[APPLY] RECEIVED DECISION"
    INFO "[APPLY] IP............. $IP"
    INFO "[APPLY] ACTION......... $ACTION"
    INFO "[APPLY] TIMEOUT........ $TIMEOUT"
    INFO "[APPLY] REASON......... $REASON"

    # detectar familia IP
    local FAMILY SET

    if isIPv4 "$IP"; then
        FAMILY="inet"
        SET="$IPSET4"
    elif isIPv6 "$IP"; then
        FAMILY="inet6"
        SET="$IPSET6"
    else
        ERROR "[APPLY] INVALID IP: $IP"
        return 1
    fi

    # asegurar set existe
    createSet "$SET" "$FAMILY"

    case "$ACTION" in

        BAN)

            INFO "[APPLY] EXECUTE: PERMANENT BAN"

            ipset add "$SET" "$IP" 2>/dev/null

            db_add_event "$IP" "BAN" "policy_apply" "$TIMEOUT"
	    db_set_status "$IP" "BANNED"

            ;;

        TEMP_BAN)

            INFO "[APPLY] EXECUTE: TEMP BAN ($TIMEOUT sec)"

            if [ -n "$TIMEOUT" ] && [ "$TIMEOUT" -gt 0 ]; then
                ipset add "$SET" "$IP" timeout "$TIMEOUT" 2>/dev/null
            else
                ipset add "$SET" "$IP" 2>/dev/null
            fi

            db_add_event "$IP" "TEMP_BAN" "policy_apply" "$TIMEOUT"

            ;;

        WATCH)

            INFO "[APPLY] ACTION: WATCH (no blocking)"

            db_add_event "$IP" "WATCH" "policy_apply" "0"

            ;;

        ALLOW)

            INFO "[APPLY] ACTION: ALLOW (no action)"

            db_add_event "$IP" "ALLOW" "policy_apply" "0"

            ;;

        *)

            WARN "[APPLY] UNKNOWN ACTION: $ACTION"
            return 1
            ;;

    esac

    INFO "[APPLY] ACTION COMPLETED SUCCESSFULLY"

    return 0
}

apply_decision() {

    local IP="$1"
    local DECISION="$2"

    local ACTION TIMEOUT REASON

    ACTION=$(echo "$DECISION" | cut -d'|' -f1)
    TIMEOUT=$(echo "$DECISION" | cut -d'|' -f2)
    REASON=$(echo "$DECISION" | cut -d'|' -f3)

    policy_apply "$IP" "$ACTION" "$TIMEOUT" "$REASON"
}
