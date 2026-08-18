#!/bin/bash
#############################################################
# Module : Policy - Decision Orchestrator
#
# Responsibility
#   Orquestar la evaluación de riesgo completa de una IP:
#   verificar whitelist, aplicar el hard gate de estado
#   BANNED, construir su contexto, reiniciar el acumulador de
#   riesgo, invocar dinámicamente la regla de cada categoría
#   (desde REPUTATION_CATEGORIES) más la señal temporal de
#   bruteforce, y traducir el riesgo resultante en una
#   decisión final. El riesgo efectivo nunca es menor que el
#   score total acumulado (db_get_score), de modo que el motor
#   por categoría solo puede ser igual o más estricto que el
#   comportamiento del motor anterior, nunca menos.
#
# Dependencies
#   - policy/whitelist.sh (is_whitelisted)
#   - policy/context.sh (policy_get_context)
#   - policy/risk.sh (risk_reset, risk_total)
#   - policy/decision_engine.sh (policy_decide)
#   - policy/rules/*.sh (policy_rule_<categoria>, policy_rule_bruteforce)
#   - config/policy.conf (REPUTATION_CATEGORIES)
#   - database.sh (db_get_status, db_get_score)
#
# Exports
#   policy_evaluate()
#############################################################

policy_evaluate() {

    local IP="$1"

    if is_whitelisted "$IP"; then
        INFO "[POLICY] IP whitelistada: $IP" >&2
        echo "ALLOW|0|WHITELISTED"
        return 0
    fi

    local STATUS
    STATUS=$(db_get_status "$IP")

    # HARD GATE: si ya está BANNED, no se evalúa nada más.
    if [ "$STATUS" = "BANNED" ]; then
        INFO "[POLICY] HARD BLOCK (STATE=BANNED)" >&2
        echo "BAN|0|STATE_BANNED"
        return 0
    fi

    local CTX
    CTX=$(policy_get_context "$IP")

    risk_reset

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        WARN "[POLICY] REPUTATION_CATEGORIES no está definida en policy.conf" >&2
    else
        local cat func
        for cat in $REPUTATION_CATEGORIES; do
            func="policy_rule_$(echo "$cat" | tr '[:upper:]' '[:lower:]')"
            if declare -F "$func" >/dev/null; then
                "$func" "$IP" "$CTX"
            fi
        done
    fi

    # Señal temporal, no ligada a una categoría de reputación.
    if declare -F policy_rule_bruteforce >/dev/null; then
        policy_rule_bruteforce "$IP" "$CTX"
    fi

    local CATEGORY_RISK
    CATEGORY_RISK=$(risk_total)

    local RAW_TOTAL
    RAW_TOTAL=$(db_get_score "$IP")

    # La decisión nunca debe ser menos estricta que el score
    # total acumulado (comportamiento del motor actual). El
    # motor por categoría puede ser más estricto (detecta
    # señales que el score simple no distingue, como
    # bruteforce), pero nunca menos.
    local EFFECTIVE_TOTAL
    if (( $(echo "$RAW_TOTAL > $CATEGORY_RISK" | bc -l) )); then
        EFFECTIVE_TOTAL="$RAW_TOTAL"
    else
        EFFECTIVE_TOTAL="$CATEGORY_RISK"
    fi

    INFO "[POLICY] CATEGORY_RISK=$CATEGORY_RISK RAW_TOTAL=$RAW_TOTAL EFFECTIVE=$EFFECTIVE_TOTAL" >&2

    policy_decide "$EFFECTIVE_TOTAL" "$STATUS"
}
