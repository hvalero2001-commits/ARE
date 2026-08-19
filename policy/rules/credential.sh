#!/bin/bash
#############################################################
# Module : Policy - Rule CREDENTIAL
#
# Responsibility
#   Evaluar el score acumulado de la categoría CREDENTIAL contra
#   su umbral configurado y, si lo supera, aportarlo al Risk
#   Accumulator. No decide ninguna acción por sí misma.
#
# Dependencies
#   - policy/context_api.sh (ctx_get_credential)
#   - policy/risk.sh (risk_add)
#   - config/policy.conf (CREDENTIAL_THRESHOLD)
#
# Exports
#   policy_rule_credential()
#############################################################
policy_rule_credential() {

    local IP="$1"
    local CTX="$2"

    local VALUE
    VALUE=$(ctx_get_credential "$CTX")
    VALUE="${VALUE:-0}"

    [ -z "${CREDENTIAL_THRESHOLD:-}" ] && return 1

    if [ "$VALUE" -ge "$CREDENTIAL_THRESHOLD" ]; then
        risk_add CREDENTIAL "$VALUE"
    fi
}
