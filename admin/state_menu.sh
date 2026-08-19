#!/usr/bin/env bash
# ============================================================
# admin/state_menu.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Estado / Reputación
#
# Permite consultar el conocimiento acumulado y el historial
# de eventos de una IP, y obtener un listado priorizado (Top).
# Solo lectura.
# ============================================================

state_menu() {
    while true; do
        echo
        echo "  -- Estado / Reputación --"
        echo "  1) Consultar IP"
        echo "  2) Eventos"
        echo "  3) Top"
        echo "  4) Estadísticas"
        echo "  5) Tendencias"
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) state_lookup_ip ;;
            2) state_events ;;
            3) state_top ;;
            4) state_stats ;;
            5) state_trends ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

state_lookup_ip() {
    read -rp "  IP a consultar: " ip
    dashboard_score "$ip"
    admin_pause
}

state_events() {
    read -rp "  IP a consultar: " ip
    dashboard_events "$ip"
    admin_pause
}

state_top() {
    dashboard_top
    admin_pause
}

state_stats() {
    dashboard_stats
    admin_pause
}

state_trends() {
    read -rp "  Cantidad de días a mostrar [default 7]: " dias
    dias="${dias:-7}"
    if ! [[ "$dias" =~ ^[0-9]+$ ]] || [ "$dias" -lt 1 ]; then
        echo "  Valor inválido, usando 7 días por defecto."
        dias=7
    fi
    dashboard_trends "$dias"
    admin_pause
}
