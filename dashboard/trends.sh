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
#   dashboard_trends_by_category()
#   dashboard_trends_export()
#   dashboard_trends_anomalies()
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

dashboard_trends_by_category() {
    local DIAS="${1:-7}"
    INFO "========== TENDENCIA POR CATEGORÍA (últimos ${DIAS} días) =========="
    echo ""
    printf "%-12s %5s %5s %5s %5s %5s %5s %5s %5s %5s\n" \
        "DIA" "REC" "EXP" "CRE" "PRO" "BOT" "ANO" "MAL" "DOS" "SOC"
    echo "----------------------------------------------------------------------"
    db_exec "
        SELECT
            date(e.fecha,'unixepoch') || '|' ||
            SUM(CASE WHEN jp.category='RECON' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='EXPLOIT' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='CREDENTIAL' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='PROTOCOL' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='BOT' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='ANOMALY' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='MALWARE' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='DOS' THEN 1 ELSE 0 END) || '|' ||
            SUM(CASE WHEN jp.category='SOCIAL' THEN 1 ELSE 0 END)
        FROM events e
        JOIN jail_profile jp ON jp.name = e.jail
        WHERE e.fecha >= strftime('%s','now') - ($DIAS * 86400)
        GROUP BY date(e.fecha,'unixepoch')
        ORDER BY date(e.fecha,'unixepoch') DESC;
    " | while IFS='|' read -r dia rec exp cre pro bot ano mal dos soc; do
        printf "%-12s %5s %5s %5s %5s %5s %5s %5s %5s %5s\n" \
            "$dia" "$rec" "$exp" "$cre" "$pro" "$bot" "$ano" "$mal" "$dos" "$soc"
    done
    echo ""
}

dashboard_trends_export() {
    local DIAS="${1:-7}"
    local OUTDIR="${ARE_DATA}/backups/trends"
    mkdir -p "$OUTDIR"
    local TS
    TS=$(date '+%Y%m%d_%H%M%S')
    local OUTFILE="${OUTDIR}/trends_${TS}.csv"

    {
        echo "dia,eventos,found,ban,unban,ips_distintas"
        db_exec "
            SELECT
                date(fecha, 'unixepoch') || ',' ||
                COUNT(*) || ',' ||
                SUM(CASE WHEN action='FOUND' THEN 1 ELSE 0 END) || ',' ||
                SUM(CASE WHEN action='BAN' THEN 1 ELSE 0 END) || ',' ||
                SUM(CASE WHEN action='EXTERNAL_UNBAN' THEN 1 ELSE 0 END) || ',' ||
                COUNT(DISTINCT ip)
            FROM events
            WHERE fecha >= strftime('%s','now') - ($DIAS * 86400)
            GROUP BY date(fecha, 'unixepoch')
            ORDER BY date(fecha, 'unixepoch') DESC;
        "
    } > "$OUTFILE"

    INFO "Tendencias exportadas: $OUTFILE"
    echo "Archivo generado: $OUTFILE"
}

#############################################################
# IDEA-008: Detección de anomalías en tendencias
#
# Compara el valor de HOY de cada categoría contra el promedio
# de los N días anteriores (sin incluir hoy). Marca con ⚠
# cuando hoy es al menos 3 veces ese promedio, con un piso
# mínimo (hoy >= 10) para no marcar ruido cuando los números
# son chicos. Puramente estadístico sobre datos ya existentes
# — no toca policy.conf ni el modelo de decisión, no bloquea
# nada, solo hace visible algo que ya estaba en events.
#############################################################
dashboard_trends_anomalies() {
    local DIAS="${1:-7}"
    local MULTIPLIER="3"
    local MIN_TODAY="10"

    INFO "========== ANOMALÍAS EN TENDENCIAS (hoy vs. promedio de ${DIAS} días previos) =========="
    echo ""

    local categories="RECON EXPLOIT CREDENTIAL PROTOCOL BOT ANOMALY MALWARE DOS SOCIAL"
    local found_any=0

    local cat
    for cat in $categories; do

        local today avg
        today=$(db_exec "
            SELECT COUNT(*)
            FROM events e
            JOIN jail_profile jp ON jp.name = e.jail
            WHERE jp.category='$cat'
              AND date(e.fecha,'unixepoch') = date('now');
        ")
        today="${today:-0}"

        avg=$(db_exec "
            SELECT COALESCE(ROUND(AVG(daily_count), 1), 0)
            FROM (
                SELECT COUNT(*) AS daily_count
                FROM events e
                JOIN jail_profile jp ON jp.name = e.jail
                WHERE jp.category='$cat'
                  AND date(e.fecha,'unixepoch') < date('now')
                  AND e.fecha >= strftime('%s','now') - ($DIAS * 86400)
                GROUP BY date(e.fecha,'unixepoch')
            );
        ")
        avg="${avg:-0}"

        [ "$today" -lt "$MIN_TODAY" ] && continue

        local is_anomaly
        is_anomaly=$(awk -v t="$today" -v a="$avg" -v m="$MULTIPLIER" 'BEGIN{print (a == 0 || t >= a * m) ? 1 : 0}')

        if [ "$is_anomaly" -eq 1 ]; then
            printf "  ⚠  %-12s hoy=%-6s promedio(%sd previos)=%-8s\n" "$cat" "$today" "$DIAS" "$avg"
            found_any=1
        fi
    done

    if [ "$found_any" -eq 0 ]; then
        echo "  Sin anomalías detectadas — ninguna categoría se aleja del patrón reciente."
    fi

    echo ""
}
