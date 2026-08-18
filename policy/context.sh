#!/bin/bash
#############################################################
# Module : Policy - Context Builder
#
# Responsibility
#   Construir el contexto de una IP a partir de su reputación
#   acumulada (9 categorías) y su actividad reciente, para que
#   las reglas de política lo evalúen sin consultar la base de
#   datos directamente.
#
# Dependencies
#   - database.sh (db_get_reputation, db_exec, db_get_last_event)
#
# Exports
#   policy_get_context()
#############################################################
policy_get_context() {

    local IP="$1"
    local REP

    REP=$(db_get_reputation "$IP")
    REP=${REP:-0|0|0|0|0|0|0|0|0|0|0}

    local RECON EXPLOIT CRED PROTO BOT ANOMALY MALWARE DOS SOCIAL TOTAL UPDATED

    IFS='|' read -r \
        RECON EXPLOIT CRED PROTO BOT ANOMALY MALWARE DOS SOCIAL TOTAL UPDATED <<< "$REP"

    local EVENTS_24H
    EVENTS_24H=$(db_exec "
        SELECT COUNT(*)
        FROM events
        WHERE ip='$IP'
          AND fecha >= strftime('%s','now') - 86400;
    ")

    local LAST
    LAST=$(db_get_last_event "$IP")

    echo "CTX_V2|${RECON:-0}|${EXPLOIT:-0}|${CRED:-0}|${PROTO:-0}|${BOT:-0}|${ANOMALY:-0}|${MALWARE:-0}|${DOS:-0}|${SOCIAL:-0}|${TOTAL:-0}|${EVENTS_24H:-0}|${UPDATED:-0}|$LAST"
}
