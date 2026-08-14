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
    local WHITELISTED=0

    if [ -z "$IP" ]; then
        ERROR "Uso: score <IP>"
        return 1
    fi

    if is_whitelisted "$IP"; then
        WHITELISTED=1
    fi

    # Obtener reputación sin crear registros para IPs whitelistadas
    local REP

    if [ "$WHITELISTED" -eq 1 ]; then
        REP=$(db_get_reputation "$IP")
    else
        db_init_reputation "$IP"
        REP=$(db_get_reputation "$IP")
    fi

    local SANCTION

    SANCTION=$(db_get_sanction "$IP")

    if [ -z "$SANCTION" ]; then
        SANCTION="0|0|0|0|0|0|0"
    fi

    local ban_level ban_count ban_until permanent last_ban last_unban

    ban_level=$(echo "$SANCTION" | cut -d'|' -f1)
    ban_count=$(echo "$SANCTION" | cut -d'|' -f2)
    ban_until=$(echo "$SANCTION" | cut -d'|' -f3)
    permanent=$(echo "$SANCTION" | cut -d'|' -f4)
    last_ban=$(echo "$SANCTION" | cut -d'|' -f5)
    last_unban=$(echo "$SANCTION" | cut -d'|' -f6)

    if [ -z "$REP" ]; then
        if [ "$WHITELISTED" -eq 1 ]; then
            echo "=================================================="
            echo "ARE - REPUTATION DASHBOARD"
            echo "=================================================="
                echo ""
            echo "IP.................... $IP"
            echo "Estado................ WHITELIST"
            echo "Reputación............ Sin datos"
            echo ""
            echo "=================================================="
            return 0
        fi
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
    if [ "$WHITELISTED" -eq 1 ]; then
        echo "Estado................ WHITELIST"
        echo ""
    fi
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
    echo "Última actividad...... $(date -d "@$updated" '+%Y-%m-%d %H:%M:%S')"
    echo "Antigüedad............ $(time_elapsed "$updated")"
    echo ""
    echo "SANCIÓN:"
    echo "  Nivel actual......... $ban_level"
    echo "  Sanciones totales.... $ban_count"
    if [ "$permanent" -eq 1 ]; then
        echo "  Tipo................. Permanente"
        echo "  Vigente hasta........ Permanente"
    else
        echo "  Tipo................. Temporal"

    if [ "$ban_until" -gt 0 ]; then
            echo "  Vigente hasta........ $(date -d "@$ban_until" '+%Y-%m-%d %H:%M:%S')"
        else
            echo "  Vigente hasta........ Sin sanción activa"
        fi
    fi

    if [ "$last_ban" -gt 0 ]; then
        echo "  Último ban........... $(date -d "@$last_ban" '+%Y-%m-%d %H:%M:%S')"
    else
        echo "  Último ban........... Nunca"
    fi

    if [ "$last_unban" -gt 0 ]; then
        echo "  Último unban......... $(date -d "@$last_unban" '+%Y-%m-%d %H:%M:%S')"
    else
        echo "  Último unban......... Nunca"
    fi
    echo ""
    echo "=================================================="
} 
