BASE="/opt/f2b-ipset"

source "$BASE/policy_env.sh"
source "$BASE/logger.sh"
source "$BASE/policy_context.sh"
source "$BASE/policy_context_api.sh"
source "$BASE/policy_rules/exploit.sh"
source "$BASE/policy_rules/recon.sh"
source "$BASE/policy_rules/bruteforce.sh"
source "$BASE/policy_rules/protocol.sh"
source "$BASE/policy_rules/bot.sh"
source "$BASE/policy_decision_engine.sh"
source "$BASE/policy_risk.sh"
source "$BASE/policy_decision.sh"
source "$BASE/policy_apply.sh"
source "$BASE/policy/state_engine.sh"

RULES=(
    "exploit"
    "bot"
    "bruteforce"
    "recon"
    "protocol"
)

policy_evaluate() {

    local IP="$1"
    local CTX STATUS RESULT FINAL_DECISION

    INFO "[POLICY] Evaluating IP=$IP" >&2

    # 1. STATE FIRST (hard gate)
    STATUS=$(db_get_status "$IP")

    if [ "$STATUS" = "BANNED" ]; then
        INFO "[POLICY] HARD BLOCK (STATE=BANNED)" >&2
        echo "BAN|0|STATE_BANNED"
        return 0
    fi

    # 2. CONTEXT (solo si no está bloqueado)
    CTX=$(policy_get_context "$IP")
    risk_reset

    # 3. RULES
    for rule in "${RULES[@]}"; do
        FUNC="policy_rule_${rule}"
        declare -F "$FUNC" >/dev/null && $FUNC "$IP" "$CTX"
    done

    TOTAL=$(risk_total)
    REASON=$(risk_reason)

    INFO "[RISK] TOTAL=$TOTAL" >&2
    INFO "[RISK] REASON=$REASON" >&2

    if [ "$TOTAL" -eq 0 ]; then
	    echo "ALLOW|0|DEFAULT" 
    else
    	DECISION=$(policy_decide "$TOTAL" "$STATUS")
    	echo "$DECISION"
    fi

    return 0
}

