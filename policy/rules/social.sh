#!/bin/bash
#############################################################
# Module : Policy - Rule SOCIAL
#
# Responsibility
#   Evaluar el score acumulado de la categoría SOCIAL contra
#   su umbral configurado y, si lo supera, aportarlo al Risk
#   Accumulator. No decide ninguna acción por sí misma.
#
# Dependencies
#   - policy/context_api.sh (ctx_get_social)
#   - policy/risk.sh (risk_add)
#   - config/policy.conf (SOCIAL_THRESHOLD)
#
# Exports
#   policy_rule_social()
#############################################################
policy_rule_social() {

    local IP="$1"
    local CTX="$2"

    local VALUE
    VALUE=$(ctx_get_social "$CTX")
    VALUE="${VALUE:-0}"

    [ -z "${SOCIAL_THRESHOLD:-}" ] && return 1

    if [ "$VALUE" -ge "$SOCIAL_THRESHOLD" ]; then
        risk_add SOCIAL "$VALUE"
    fi
}
