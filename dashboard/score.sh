#############################################################
# Module : Dashboard - Score
#
# Responsibility
#   Show reputation information for one IP.
#
# Dependencies
#   - database.sh
#   - logger.sh
#
# Exports
#   dashboard_score()
#############################################################
dashboard_score() {

    local IP="$1"

    if [ -z "$IP" ]; then
        ERROR "Uso: score <IP>"
        return 1
    fi

    db_init_reputation "$IP"

    # Obtener reputación
    local REP
    REP=$(db_get_reputation "$IP")

    if [ -z "$REP" ]; then
        WARN "IP sin datos: $IP"
        return 0
    fi
   
    local recon exploit credential protocol bot anomaly malware dos social total updated

    recon=$(echo "$REP" | cut -d'|' -f1)
    exploit=$(echo "$REP" | cut -d'|' -f2)
    credential=$(echo "$REP" | cut -d'|' -f3)
    protocol=$(echo "$REP" | cut -d'|' -f4)
    bot=$(echo "$REP" | cut -d'|' -f5)
    anomaly=$(echo "$REP" | cut -d'|' -f6)
    malware=$(echo "$REP" | cut -d'|' -f7)
    dos=$(echo "$REP" | cut -d'|' -f8)
    social=$(echo "$REP" | cut -d'|' -f9)
    total=$(echo "$REP" | cut -d'|' -f10)
    updated=$(echo "$REP" | cut -d'|' -f11)

    local THREAT
    THREAT=$(calc_threat_level "$total")

    local LAST_EVENT
    LAST_EVENT=$(db_get_last_event "$IP")

    echo "=================================================="
    echo "ARE - REPUTATION DASHBOARD"
    echo "=================================================="
    echo ""
    echo "IP.................... $IP"
    echo ""
    echo "Recon................. $recon"
    echo "Exploit............... $exploit"
    echo "Credential............ $credential"
    echo "Protocol.............. $protocol"
    echo "Bot................... $bot"
    echo "Anomaly............... $anomaly"
    echo "Malware............... $malware"
    echo "Dos................... $dos"
    echo "Social................ $social"
    echo ""
    echo "TOTAL................. $total"
    echo "Threat Level.......... $THREAT"
    echo ""
    echo "Último evento......... $LAST_EVENT"
    echo ""
    echo "Última actualización.. $updated"
    echo ""
    echo "=================================================="
} 
