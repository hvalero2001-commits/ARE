#############################################################
# Module : Dashboard - Top
#
# Responsibility
#   Show reputation information for one IP.
#
# Dependencies
#   - database.sh
#   - logger.sh
#
# Exports
#   dashboard_top()
#############################################################
dashboard_top() {

    INFO "========== TOP THREATS =========="

    echo ""
    echo "TOP 10 IPs más peligrosas:"
    echo ""

    db_top_attackers | while IFS='|' read ip total recon exploit cred proto bot; do
        echo "$ip | SCORE=$total | EXP=$exploit | BOT=$bot"
    done

    echo ""
}
