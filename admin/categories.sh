#!/usr/bin/env bash
# ============================================================
# admin/categories.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Categorías
#
# Expone en modo solo lectura el modelo de reputación
# (RECON, EXPLOIT, CREDENTIAL, PROTOCOL, BOT, ANOMALY,
# MALWARE, DOS, SOCIAL). No escribe sobre `reputation`.
# ============================================================

categories_menu() {
    while true; do
        echo
        echo "  -- Categorías --"
        echo "  1) Listar"
        echo "  2) Ver puntuaciones"
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) categories_list ;;
            2) categories_scores ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

categories_list() {
    echo "=================================================="
    echo "CATEGORÍAS - Catálogo"
    echo "=================================================="

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
        admin_pause
        return 1
    fi

    for cat in $REPUTATION_CATEGORIES; do
        local threshold_var="${cat}_THRESHOLD"
        local threshold="${!threshold_var:-N/D}"
        printf "  %-12s umbral: %s\n" "$cat" "$threshold"
    done

    echo "=================================================="
    admin_pause
}

categories_scores() {
    read -rp "  IP a consultar: " ip

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
        admin_pause
        return 1
    fi

    local REP
    REP=$(db_get_reputation "$ip")

    if [ -z "$REP" ]; then
        echo "  IP sin datos: $ip"
        admin_pause
        return 0
    fi

    echo "=================================================="
    echo "CATEGORÍAS - Puntuaciones de $ip"
    echo "=================================================="

    local i=1
    for cat in $REPUTATION_CATEGORIES; do
        local value
        value=$(echo "$REP" | cut -d'|' -f"$i")
        printf "  %-12s %s\n" "$cat" "$value"
        i=$((i + 1))
    done

    echo "=================================================="
    admin_pause
}
