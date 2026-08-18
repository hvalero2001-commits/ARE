#!/bin/bash
#############################################################
# Module : Policy - Rule DOS
#
# Responsibility
#   Evaluar el score acumulado de la categoría DOS contra su
#   umbral configurado y, si lo supera, aportarlo al Risk
#   Accumulator. No decide ninguna acción por sí misma.
#
# Dependencies
#   - policy/context_api.sh (ctx_get_dos)
#   - policy/risk.sh (risk_add)
#   - config/policy.conf (DOS_THRESHOLD)
#
# Exports
#   policy_rule_dos()
#############################################################
policy_rule_dos() {

    local IP="$1"
    local CTX="$2"

    local VALUE
    VALUE=$(ctx_get_dos "$CTX")
    VALUE="${VALUE:-0}"

    [ -z "${DOS_THRESHOLD:-}" ] && return 1

    if [ "$VALUE" -ge "$DOS_THRESHOLD" ]; then
        risk_add DOS "$VALUE"
    fi
}
