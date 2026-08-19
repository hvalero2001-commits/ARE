#!/bin/bash
#############################################################
# Module : Dashboard - Trends
#
# Responsibility
#   Mostrar la evolución diaria de la actividad registrada en
#   la tabla events (eventos totales, por tipo de acción, e
#   IPs distintas), para dar visibilidad temporal que las
#   vistas de estado actual (stats, top, score) no cubren.
#
# Dependencies
#   - database.sh (db_exec)
#
# Exports
#   dashboard_trends()
#############################################################

dashboard_trends() {

    local DIAS="${1:-7}"

    INFO "========== TENDENCIA (últimos ${DIAS} días) =========="
    echo ""
    printf "%-12s %10s %8s %6s %8s %6s\n" "DIA" "EVENTOS" "FOUND" "BAN" "UNBAN" "IPs"
    echo "--------------------------------------------------------------"

    db_exec "
        SELECT
            date(fecha, 'unixepoch') || '|' ||
            COUNT(*) || '|' ||
            SUM(CASE WHEN action='FOUND' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN action='BAN' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN action='EXTERNAL_UNBAN' THEN 1 ELSE 0 END) || '|' ||
            COUNT(DISTINCT ip)
        FROM events
        WHERE fecha >= strftime('%s','now') - ($DIAS * 86400)
        GROUP BY date(fecha, 'unixepoch')
        ORDER BY date(fecha, 'unixepoch') DESC;
    " | while IFS='|' read -r dia eventos found bans unbans ips; do
        printf "%-12s %10s %8s %6s %8s %6s\n" "$dia" "$eventos" "$found" "$bans" "$unbans" "$ips"
    done

    echo ""
}
