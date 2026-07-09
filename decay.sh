#!/bin/bash

#############################################################
# Module : Reputation - Decay Engine
#
# Responsibility
#   Reduce reputation score for IPs without recent activity.
#
# Dependencies
#   - database.sh
#   - logger.sh
#
# Exports
#   reputation_decay_run()
#############################################################

reputation_decay_dry_run() {

    local NOW
    local MIN_AGE="${DECAY_MIN_AGE:-86400}"
    local FACTOR="${DECAY_FACTOR:-0.95}"

    NOW=$(date +%s)

    INFO "Decay dry-run iniciado MIN_AGE=$MIN_AGE FACTOR=$FACTOR"

    sqlite3 "$DB_FILE" "
        SELECT
            ip || '|' ||
            total_score || '|' ||
            CAST(total_score * $FACTOR AS INTEGER) || '|' ||
            status || '|' ||
            ($NOW - updated)
        FROM reputation
        WHERE total_score > 0
          AND updated IS NOT NULL
          AND ($NOW - updated) >= $MIN_AGE
        ORDER BY total_score DESC
        LIMIT 10;
    "

}

reputation_decay_apply() {

    local NOW
    local MIN_AGE="${DECAY_MIN_AGE:-86400}"
    local FACTOR="${DECAY_FACTOR:-0.95}"

    NOW=$(date +%s)

    INFO "Decay apply iniciado MIN_AGE=$MIN_AGE FACTOR=$FACTOR"

    local COUNT=0

    local IPS
    IPS=$(sqlite3 "$DB_FILE" "
        SELECT ip
        FROM reputation
        WHERE total_score > 0
          AND updated IS NOT NULL
          AND ($NOW - updated) >= $MIN_AGE;
    ")

    for IP in $IPS; do

        local OLD_SCORE NEW_SCORE STATUS DECISION ACTION REASON

        OLD_SCORE=$(db_get_score "$IP")

        sqlite3 "$DB_FILE" "
            UPDATE reputation
            SET
                recon_score = CAST(recon_score * $FACTOR AS INTEGER),
                exploit_score = CAST(exploit_score * $FACTOR AS INTEGER),
                credential_score = CAST(credential_score * $FACTOR AS INTEGER),
                protocol_score = CAST(protocol_score * $FACTOR AS INTEGER),
                bot_score = CAST(bot_score * $FACTOR AS INTEGER),
                anomaly_score = CAST(anomaly_score * $FACTOR AS INTEGER),
                malware_score = CAST(malware_score * $FACTOR AS INTEGER),
                dos_score = CAST(dos_score * $FACTOR AS INTEGER),
                social_score = CAST(social_score * $FACTOR AS INTEGER),
                total_score = CAST(total_score * $FACTOR AS INTEGER)
            WHERE ip='$IP';
        "

        state_update "$IP"

        NEW_SCORE=$(db_get_score "$IP")
        STATUS=$(db_get_status "$IP")
        DECISION=$(policy_decide "$NEW_SCORE" "$STATUS")

        ACTION=$(echo "$DECISION" | cut -d'|' -f1)
        REASON=$(echo "$DECISION" | cut -d'|' -f3)

        INFO "[DECAY] IP=$IP SCORE=$OLD_SCORE->$NEW_SCORE STATUS=$STATUS POLICY=$ACTION REASON=$REASON"

	COUNT=$((COUNT + 1))

    done

    INFO "Decay apply finalizado. IPs procesadas=$COUNT"
}
