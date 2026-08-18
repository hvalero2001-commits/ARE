#!/bin/bash
#############################################################
# Module : Policy - Rule BRUTEFORCE
#
# Responsibility
#   Evaluar la frecuencia de eventos en las últimas 24 horas
#   (señal temporal, no un score de categoría) contra su
#   umbral configurado y, si lo supera, aportarla al Risk
#   Accumulator.
#
# Dependencies
#   - policy/context_api.sh (ctx_get_events_24h)
#   - policy/risk.sh (risk_add)
#   - config/policy.conf (BRUTEFORCE_EVENTS_24H_THRESHOLD)
#
# Exports
#   policy_rule_bruteforce()
#############################################################

policy_rule_bruteforce() {

    local IP="$1"
    local CTX="$2"

    local EVENTS
    EVENTS=$(ctx_get_events_24h "$CTX")
    EVENTS="${EVENTS:-0}"

    [ -z "${BRUTEFORCE_EVENTS_24H_THRESHOLD:-}" ] && return 1

    if [ "$EVENTS" -ge "$BRUTEFORCE_EVENTS_24H_THRESHOLD" ]; then
        risk_add BRUTEFORCE "$EVENTS"
    fi
}
