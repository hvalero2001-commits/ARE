#!/bin/bash
#############################################################
# Module : Policy - Rule ANOMALY
#
# Responsibility
#   Evaluar el score acumulado de la categoría ANOMALY contra
#   su umbral configurado y, si lo supera, aportarlo al Risk
#   Accumulator. No decide ninguna acción por sí misma.
#
# Dependencies
#   - policy/context_api.sh (ctx_get_anomaly)
#   - policy/risk.sh (risk_add)
#   - config/policy.conf (ANOMALY_THRESHOLD)
#
# Exports
#   policy_rule_anomaly()
#############################################################
policy_rule_anomaly() {

    local IP="$1"
    local CTX="$2"

    local VALUE
    VALUE=$(ctx_get_anomaly "$CTX")
    VALUE="${VALUE:-0}"

    [ -z "${ANOMALY_THRESHOLD:-}" ] && return 1

    if [ "$VALUE" -ge "$ANOMALY_THRESHOLD" ]; then
        risk_add ANOMALY "$VALUE"
    fi
}
