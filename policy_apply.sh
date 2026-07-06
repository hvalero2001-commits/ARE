export DB_FILE="/var/lib/f2b-ipset/f2b.db"

apply_decision() {

    local IP="$1"

    local DECISION="$2"

    local ACTION TIME REASON
    local FAMILY
    local SET_FILTER
    local SET_BAN

    # Detectar familia IP
    if [[ "$IP" == *:* ]]; then
        FAMILY="6"
    else
        FAMILY="4"
    fi

    SET_FILTER=$([ "$FAMILY" = 6 ] && echo "$FILTER_SET6" || echo "$FILTER_SET4")
    SET_BAN=$([ "$FAMILY" = 6 ] && echo "$BAN_SET6" || echo "$BAN_SET4")

    ACTION=$(echo "$DECISION" | cut -d'|' -f1)
    TIME=$(echo "$DECISION" | cut -d'|' -f2)
    REASON=$(echo "$DECISION" | cut -d'|' -f3)


    [ "$DEBUG" = "1" ] && echo "[DEBUG RAW IP] '$IP'"
    [ "$DEBUG" = "1" ] && echo "[DEBUG FAMILY] '$FAMILY'"
    [ "$DEBUG" = "1" ] && echo "[DEBUG SET_FILTER] '$SET_FILTER'"
    [ "$DEBUG" = "1" ] && echo "[DEBUG SET_BAN] '$SET_BAN'"
    [ "$DEBUG" = "1" ] && echo "[DEBUG DB_FILE] '$DB_FILE'"

    INFO "[APPLY] IP=$IP ACTION=$ACTION TIME=$TIME REASON=$REASON"

    case "$ACTION" in

        ALLOW)
            INFO "[APPLY] NO ACTION"
        ;;

        WATCH)
            db_set_status "$IP" "WATCH"
        ;;

        FILTER)
	    banIP "$SET_FILTER" "$IP" 0
    	    db_set_status "$IP" "FILTER"
        ;;

        TEMP_BAN)
	    banIP "$SET_BAN" "$IP" "$TIME"
            db_set_status "$IP" "BANNED_TEMP"
        ;;

        BAN)
	    banIP "$SET_BAN" "$IP" 0
            db_set_status "$IP" "BANNED"
        ;;

        *)
            WARN "[APPLY] UNKNOWN ACTION"
        ;;
    esac
}

############################################################
# Apply UNBAN
############################################################

apply_unban() {

    local IP="$1"

    local FAMILY
    local SET_FILTER
    local SET_BAN

    # Detectar familia IP
    if [[ "$IP" == *:* ]]; then
        FAMILY="6"
    else
        FAMILY="4"
    fi

    SET_FILTER=$([ "$FAMILY" = 6 ] && echo "$FILTER_SET6" || echo "$FILTER_SET4")
    SET_BAN=$([ "$FAMILY" = 6 ] && echo "$BAN_SET6" || echo "$BAN_SET4")

    INFO "[UNBAN] IP=$IP"

    unbanIP "$SET_FILTER" "$IP"
    unbanIP "$SET_BAN" "$IP"

}
