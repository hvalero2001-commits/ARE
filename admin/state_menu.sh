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
        echo "  6) Tendencias por categoría"
        echo "  7) Exportar tendencias (CSV)"
        echo "  8) Anomalías en tendencias"
        echo "  0) Volver"
        echo "  x) Salir"
        read -rp "  Seleccione una opción: " opt
        case "$opt" in
            1) state_lookup_ip ;;
            2) state_events ;;
            3) state_top ;;
            4) state_stats ;;
            5) state_trends ;;
            6) state_trends_category ;;
            7) state_trends_export ;;
            8) state_trends_anomalies ;;
            0) return 0 ;;
            x|X) admin_exit ;;
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
state_trends_category() {
    read -rp "  Cantidad de días a mostrar [default 7]: " dias
    dias="${dias:-7}"
    if ! [[ "$dias" =~ ^[0-9]+$ ]] || [ "$dias" -lt 1 ]; then
        echo "  Valor inválido, usando 7 días por defecto."
        dias=7
    fi
    dashboard_trends_by_category "$dias"
    admin_pause
}
state_trends_export() {
    read -rp "  Cantidad de días a exportar [default 7]: " dias
    dias="${dias:-7}"
    if ! [[ "$dias" =~ ^[0-9]+$ ]] || [ "$dias" -lt 1 ]; then
        echo "  Valor inválido, usando 7 días por defecto."
        dias=7
    fi
    dashboard_trends_export "$dias"
    admin_pause
}
state_trends_anomalies() {
    read -rp "  Días de referencia para el promedio [default 7]: " dias
    dias="${dias:-7}"
    if ! [[ "$dias" =~ ^[0-9]+$ ]] || [ "$dias" -lt 1 ]; then
        echo "  Valor inválido, usando 7 días por defecto."
        dias=7
    fi
    dashboard_trends_anomalies "$dias"
    admin_pause
}
