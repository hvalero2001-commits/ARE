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
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) state_lookup_ip ;;
            2) state_events ;;
            3) state_top ;;
	    4) state_stats ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

state_lookup_ip() {
    echo "  [Estado/Reputación] Consultar IP"
    read -rp "  IP a consultar: " ip
    # TODO: reutilizar dashboard/lookup.sh y dashboard/score.sh
    # (misma lógica que ya usa `are score <ip>`).
    echo "  (stub) Estado, score y sanción actual de ${ip}"
    admin_pause
}

state_events() {
    echo "  [Estado/Reputación] Eventos"
    read -rp "  IP a consultar: " ip
    # TODO: reutilizar dashboard/events.sh
    # (misma lógica que ya usa `are events <ip>`).
    echo "  (stub) Historial de eventos de ${ip}"
    admin_pause
}

state_top() {
    echo "  [Estado/Reputación] Top"
    # TODO: reutilizar dashboard/top.sh
    # (misma lógica que ya usa `are top`).
    echo "  (stub) Listado priorizado por reputación / sanción"
    admin_pause
}
