policy_get_context() {

    local IP="$1"
    local REP

    REP=$(db_get_reputation "$IP")
    REP=${REP:-0|0|0|0|0|0|0|0|0|0|0}

    local RECON EXPLOIT CRED PROTO BOT TOTAL UPDATED

    IFS='|' read -r         RECON         EXPLOIT         CRED         PROTO         BOT         _ANOMALY         _MALWARE         _DOS         _SOCIAL         TOTAL         UPDATED <<< "$REP"

    local EVENTS_24H
    EVENTS_24H=$(db_exec "
        SELECT COUNT(*)
        FROM events
        WHERE ip='$IP'
          AND fecha >= strftime('%s','now') - 86400;
    ")

    local LAST
    LAST=$(db_get_last_event "$IP")

    echo "CTX_V1|${RECON:-0}|${EXPLOIT:-0}|${CRED:-0}|${PROTO:-0}|${BOT:-0}|${TOTAL:-0}|${EVENTS_24H:-0}|${UPDATED:-0}|$LAST"
}
