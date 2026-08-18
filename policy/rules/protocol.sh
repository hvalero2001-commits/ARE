#!/bin/bash
#############################################################
# Module : Policy - Rule PROTOCOL
#
# Responsibility
#   Evaluar el score acumulado de la categoría EXPLOIT contra
#   su umbral configurado y, si lo supera, aportarlo al Risk
#   Accumulator. No decide ninguna acción por sí misma.
#
# Dependencies
#   - policy/context_api.sh (ctx_get_exploit)
#   - policy/risk.sh (risk_add)
#   - config/policy.conf (EXPLOIT_THRESHOLD)
#
# Exports
#   policy_rule_exploit()
#############################################################

policy_rule_protocol() {

    local IP="$1"
    local CTX="$2"

    local VALUE
    VALUE=$(ctx_get_protocol "$CTX")
    VALUE="${VALUE:-0}"

    [ -z "${PROTOCOL_THRESHOLD:-}" ] && return 1

    if [ "$VALUE" -ge "$PROTOCOL_THRESHOLD" ]; then
        risk_add PROTOCOL "$VALUE"
    fi
}
