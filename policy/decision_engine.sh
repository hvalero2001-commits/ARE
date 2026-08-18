#!/bin/bash
#############################################################
# Module : Policy - Decision Engine
#
# Responsibility
#   Traducir el riesgo total acumulado (ver risk.sh) en una
#   decisión de acción (ALLOW/WATCH/FILTER/TEMP_BAN/BAN),
#   según los umbrales configurados en policy.conf. Aplica un
#   hard override si el estado de la IP ya es BANNED.
#
# Dependencies
#   - config/policy.conf (WATCH_SCORE, TEMP_BAN_SCORE,
#     PERMANENT_BAN_SCORE)
#   - bc (comparación de valores decimales)
#
# Exports
#   policy_decide()
#############################################################

policy_decide() {

    local TOTAL="$1"
    local STATUS="$2"

    # HARD OVERRIDE
    if [ "$STATUS" = "BANNED" ]; then
        echo "BAN|0|STATE_BANNED"
        return 0
    fi

    if [ -n "${PERMANENT_BAN_SCORE:-}" ] && (( $(echo "$TOTAL >= $PERMANENT_BAN_SCORE" | bc -l) )); then
        echo "BAN|0|HIGH_RISK"
        return 0
    fi

    if [ -n "${TEMP_BAN_SCORE:-}" ] && (( $(echo "$TOTAL >= $TEMP_BAN_SCORE" | bc -l) )); then
        echo "TEMP_BAN|3600|MEDIUM_RISK"
        return 0
    fi

    if [ -n "${WATCH_SCORE:-}" ] && (( $(echo "$TOTAL >= $WATCH_SCORE" | bc -l) )); then
        echo "FILTER|0|LOW_RISK"
        return 0
    fi

    if (( $(echo "$TOTAL > 0" | bc -l) )); then
        echo "WATCH|0|MINIMAL_RISK"
        return 0
    fi

    echo "ALLOW|0|NO_RISK"
}
