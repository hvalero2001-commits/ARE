#!/bin/bash
#############################################################
# Module : Policy - Risk Accumulator
#
# Responsibility
#   Acumular el riesgo aportado por cada regla de política
#   evaluada, aplicando un multiplicador de reincidencia según
#   el estado actual de la IP (WATCH/BANNED), configurable vía
#   policy.conf.
#
# Dependencies
#   - config/policy.conf (RISK_MULT_WATCH, RISK_MULT_BANNED)
#   - awk (aritmética con decimales)
#
# Exports
#   risk_reset(), risk_add(), risk_total(), risk_reason()
#############################################################

RISK_TOTAL=0
RISK_REASONS=""

risk_reset() {
    RISK_TOTAL=0
    RISK_REASONS=""
}

risk_add() {

    local NAME="$1"
    local VALUE="${2:-0}"

    local STATE="${STATUS:-NEW}"
    local MULT=1

    if [ "$STATE" = "WATCH" ] && [ -n "${RISK_MULT_WATCH:-}" ]; then
        MULT="$RISK_MULT_WATCH"
    elif [ "$STATE" = "BANNED" ] && [ -n "${RISK_MULT_BANNED:-}" ]; then
        MULT="$RISK_MULT_BANNED"
    fi

    VALUE=$(awk "BEGIN {print $VALUE * $MULT}")
    RISK_TOTAL=$(awk "BEGIN {print $RISK_TOTAL + $VALUE}")

    if [ -z "$RISK_REASONS" ]; then
        RISK_REASONS="${NAME}:${VALUE}"
    else
        RISK_REASONS="${RISK_REASONS},${NAME}:${VALUE}"
    fi
}

risk_total() {
    echo "$RISK_TOTAL"
}

risk_reason() {
    echo "$RISK_REASONS"
}
