policy_get_context() {

    local IP="$1"

    local REP
    REP=$(db_get_reputation "$IP")

    # fallback seguro si DB falla
    REP=${REP:-0|0|0|0|0|0}

    local RECON EXPLOIT CRED PROTO BOT TOTAL
    RECON=$(echo "$REP" | cut -d'|' -f1)
    EXPLOIT=$(echo "$REP" | cut -d'|' -f2)
    CRED=$(echo "$REP" | cut -d'|' -f3)
    PROTO=$(echo "$REP" | cut -d'|' -f4)
    BOT=$(echo "$REP" | cut -d'|' -f5)
    TOTAL=$(echo "$REP" | cut -d'|' -f6)

    local EVENTS_24H
    EVENTS_24H=$(db_exec "
        SELECT COUNT(*)
        FROM events
        WHERE ip='$IP'
        AND fecha >= strftime('%s','now') - 86400;
    ")

    local LAST
    LAST=$(db_get_last_event "$IP")

    echo "CTX_V1|$RECON|$EXPLOIT|$CRED|$PROTO|$BOT|$TOTAL|$EVENTS_24H|$(date +%s)|$LAST"
}
