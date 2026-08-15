#!/bin/bash

#############################################################
# Module : Policy - Ban Lifecycle Engine
#
# Responsibility
#   Calculate the next sanction for an IP according to its
#   current ban level and the configured escalation policy.
#
# Dependencies
#   - database.sh
#   - policy.conf
#
# Exports
#   ban_lifecycle_calculate()
#############################################################

ban_lifecycle_calculate() {

    local IP="$1"
    local LEVEL NEXT_LEVEL TIME

    db_init_sanction "$IP"

    LEVEL=$(db_get_ban_level "$IP")
    LEVEL="${LEVEL:-0}"

    NEXT_LEVEL=$((LEVEL + 1))

    if [ "$NEXT_LEVEL" -ge "$BAN_LEVEL_MAX" ]; then
        echo "BAN|0|BAN_LEVEL_MAX"
        return 0
    fi

    case "$NEXT_LEVEL" in
        1)
            TIME="$BAN_LEVEL_1_TIME"
        ;;
        2)
            TIME="$BAN_LEVEL_2_TIME"
        ;;
        3)
            TIME="$BAN_LEVEL_3_TIME"
        ;;
        4)
            TIME="$BAN_LEVEL_4_TIME"
        ;;
        5)
            TIME="$BAN_LEVEL_5_TIME"
        ;;
        6)
            TIME="$BAN_LEVEL_6_TIME"
        ;;
        *)
            echo "BAN|0|BAN_LEVEL_MAX"
            return 0
        ;;
    esac

    echo "TEMP_BAN|$TIME|BAN_LEVEL_$NEXT_LEVEL"
}
