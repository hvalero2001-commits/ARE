#!/bin/bash

BASE="$ARE_HOME"

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
    local FAMILY BAN_SET FILTER_SET

    if isIPv4 "$IP"; then
        FAMILY="inet"
        BAN_SET="$BAN_SET4"
        FILTER_SET="$FILTER_SET4"
    elif isIPv6 "$IP"; then
        FAMILY="inet6"
        BAN_SET="$BAN_SET6"
        FILTER_SET="$FILTER_SET6"
    else
        ERROR "[APPLY] INVALID IP: $IP"
        return 1
    fi

    # asegurar set existe
    createSet "$BAN_SET" "$FAMILY"
    createSet "$FILTER_SET" "$FAMILY"

    case "$ACTION" in

        BAN)

            INFO "[APPLY] EXECUTE: PERMANENT BAN"

	    ipset add "$BAN_SET" "$IP" 2>/dev/null

            db_add_event "$IP" "BAN" "policy_apply" "$TIMEOUT"
	    db_set_status "$IP" "BANNED"

            ;;

        TEMP_BAN)

            local LIFECYCLE_DECISION
            local SANCTION_ACTION
            local SANCTION_TIME
            local SANCTION_REASON
            local BAN_UNTIL
            local NOW

	    LIFECYCLE_DECISION=$(ban_lifecycle_calculate "$IP" | tail -n 1)

            SANCTION_ACTION=$(echo "$LIFECYCLE_DECISION" | cut -d'|' -f1)
            SANCTION_TIME=$(echo "$LIFECYCLE_DECISION" | cut -d'|' -f2)
            SANCTION_REASON=$(echo "$LIFECYCLE_DECISION" | cut -d'|' -f3)

            INFO "[APPLY] Ban Lifecycle: $LIFECYCLE_DECISION"

            if [ "$SANCTION_ACTION" = "BAN" ]; then

                INFO "[APPLY] EXECUTE: PERMANENT ESCALATION"
                INFO "[APPLY] SANCTION LEVEL: $SANCTION_REASON"

                db_increment_ban_level "$IP" "$BAN_LEVEL_MAX"
                db_set_permanent "$IP" "1"
                db_set_ban_until "$IP" "0"

                # Eliminar contenciones anteriores
                ipset del "$FILTER_SET" "$IP" 2>/dev/null
                ipset del "$BAN_SET" "$IP" 2>/dev/null

                # Incorporar sin timeout
                ipset add "$BAN_SET" "$IP" 2>/dev/null

                db_add_event "$IP" "BAN" "$SANCTION_REASON" "0"
                db_set_status "$IP" "BANNED"

                INFO "[APPLY] PERMANENT BAN APPLIED"

                return 0
            fi

            NOW=$(date +%s)
            BAN_UNTIL=$((NOW + SANCTION_TIME))

            db_increment_ban_level "$IP" "$BAN_LEVEL_MAX"
            db_set_ban_until "$IP" "$BAN_UNTIL"

            INFO "[APPLY] EXECUTE: TEMP BAN ($SANCTION_TIME sec)"
            INFO "[APPLY] SANCTION LEVEL: $SANCTION_REASON"

	    ipset add "$BAN_SET" "$IP" timeout "$SANCTION_TIME" 2>/dev/null

            db_add_event "$IP" "TEMP_BAN" "$SANCTION_REASON" "$SANCTION_TIME"
            db_set_status "$IP" "BANNED"

            ;;

        FILTER)

            INFO "[APPLY] EXECUTE: FILTER"

            ipset add "$FILTER_SET" "$IP" 2>/dev/null

            db_add_event "$IP" "FILTER" "policy_apply" "0"
            db_set_status "$IP" "FILTER"

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
