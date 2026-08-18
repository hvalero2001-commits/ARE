policy_rule_bot() {
    local IP="$1"
    local CTX="$2"

    local BOT
    BOT=$(ctx_get_bot "$CTX")

    BOT=${BOT:-0}

    if [ "$BOT" -ge 50 ]; then
        risk_add BOT 60
    fi
}
