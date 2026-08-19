#!/bin/bash
#############################################################
# Module : Policy - Apply
#
# Responsibility
#   Ejecutar en el Firewall Backend (ipset) la decisión que ya
#   tomó el Policy Engine, y registrar el evento y el estado
#   correspondiente en la base de datos. No decide nada por sí
#   mismo — solo traduce una decisión ya tomada en acción real.
#
# Dependencies
#   - logger.sh
#   - validator.sh (isIPv4, isIPv6)
#   - database.sh (db_add_event, db_set_status, db_set_permanent,
#     db_set_ban_until, db_increment_ban_level, is_whitelisted)
#   - infrastructure/ipset.sh (createSet)
#   - policy/ban_lifecycle.sh (ban_lifecycle_calculate)
#   - config/config.conf (BAN_SET4, BAN_SET6, FILTER_SET4,
#     FILTER_SET6, BAN_LEVEL_MAX, IPSET_MAX_TIMEOUT)
#
# Exports
#   policy_apply()
#   apply_decision()
#############################################################

BASE="$ARE_HOME"
source "$BASE/logger.sh"
source "$BASE/validator.sh"
source "$BASE/database.sh"

policy_apply() {
    local IP="$1"
    local ACTION="$2"
    local TIMEOUT="$3"
    local REASON="$4"

    if is_whitelisted "$IP"; then
        case "$ACTION" in
            BAN|TEMP_BAN|FILTER)
            INFO "[APPLY] IP whitelistada: $IP - sanción bloqueada"
                return 0
                ;;
        esac
    fi

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
            if ! ipset add "$BAN_SET" "$IP" -exist; then
                ERROR "[APPLY] Fallo al aplicar BAN permanente en ipset para $IP"
            fi
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
                ipset del "$FILTER_SET" "$IP" -exist
                ipset del "$BAN_SET" "$IP" -exist
                # Incorporar sin timeout
                if ! ipset add "$BAN_SET" "$IP" -exist; then
                    ERROR "[APPLY] Fallo al aplicar escalación permanente en ipset para $IP"
                fi
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

            if [ "$SANCTION_TIME" -gt "$IPSET_MAX_TIMEOUT" ]; then
                WARN "[APPLY] SANCTION_TIME ($SANCTION_TIME) supera IPSET_MAX_TIMEOUT, se capea a $IPSET_MAX_TIMEOUT"
                SANCTION_TIME="$IPSET_MAX_TIMEOUT"
            fi

            if ! ipset add "$BAN_SET" "$IP" timeout "$SANCTION_TIME" -exist; then
                ERROR "[APPLY] Fallo al aplicar TEMP_BAN en ipset para $IP (timeout=$SANCTION_TIME)"
            fi
            db_add_event "$IP" "TEMP_BAN" "$SANCTION_REASON" "$SANCTION_TIME"
            db_set_status "$IP" "BANNED"
            ;;

        FILTER)
            INFO "[APPLY] EXECUTE: FILTER"
            if ! ipset add "$FILTER_SET" "$IP" -exist; then
                ERROR "[APPLY] Fallo al aplicar FILTER en ipset para $IP"
            fi
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
