#############################################################
# Module : Dashboard - Stats
#
# Responsibility
#   Show reputation information for one IP.
#
# Dependencies
#   - database.sh
#   - logger.sh
#
# Exports
#   dashboard_stats()
#############################################################
dashboard_stats() {

    echo "========== ARE STATS =========="

    echo ""
    echo "TOP JAILS:"
        db_top_jails | while IFS='|' read -r JAIL COUNT
    do
        printf "  %-22s %s\n" "$JAIL" "$COUNT"
    done

    local IPS TOTAL ACTIVE BANNED EVENTS TODAY AVG CAT

    IPS=$(db_count_ips)
    ACTIVE=$(db_count_active_ips)
    BANNED=$(db_count_banned_ips)
    EVENTS=$(db_count_events)
    TODAY=$(db_count_events_today)
    AVG=$(db_avg_score)
    CAT=$(db_sum_categories)

    local R E C P B A M D S
    R=$(echo "$CAT" | cut -d'|' -f1)
    E=$(echo "$CAT" | cut -d'|' -f2)
    C=$(echo "$CAT" | cut -d'|' -f3)
    P=$(echo "$CAT" | cut -d'|' -f4)
    B=$(echo "$CAT" | cut -d'|' -f5)
    A=$(echo "$CAT" | cut -d'|' -f6)
    M=$(echo "$CAT" | cut -d'|' -f7)
    D=$(echo "$CAT" | cut -d'|' -f8)
    S=$(echo "$CAT" | cut -d'|' -f9)

    echo ""
    echo "IPs totales............. $IPS"
    echo "IPs activas............. $ACTIVE"
    echo "IPs baneadas............ $BANNED"
    echo ""
    echo "Eventos totales......... $EVENTS"
    echo "Eventos hoy............. $TODAY"
    echo ""
    echo "Score promedio.......... ${AVG%.*}"
    echo ""
    echo "ATAQUES:"
    echo "  Recon................. $R"
    echo "  Exploit............... $E"
    echo "  Credential............ $C"
    echo "  Protocol.............. $P"
    echo "  Bot................... $B"
    echo "  Anomaly............... $A"
    echo "  Malware............... $M"
    echo "  Dos................... $D"
    echo "  Social................ $S" 
    echo ""
    echo "================================"
}
