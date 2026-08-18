#!/usr/bin/env bash
# ============================================================
# admin/sensors_menu.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Sensores
#
# Expone estado y configuración del Sensor Framework.
# No decide política ni modifica reputación de forma directa.
# Nombre de archivo con sufijo "_menu" para no colisionar con
# sensors/*.sh (implementación real de cada sensor).
# ============================================================

sensors_menu() {
    while true; do
        echo
        echo "  -- Sensores --"
        echo "  1) Estado"
        echo "  2) Configuración"
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) sensors_status ;;
            2) sensors_config ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

sensors_status() {
    echo "  [Sensores] Estado"
    # TODO: por cada sensor en sensors/*.sh, reportar:
    #   - si el timer/systemd unit está activo
    #   - último offset procesado
    #   - último evento recibido
    echo "  (stub) Estado de sensores registrados"
    admin_pause
}

sensors_config() {
    echo "  [Sensores] Configuración"
    # TODO: mostrar la configuración de sensores desde
    # config/config.conf (solo lectura desde este submenú;
    # la edición pertenece a la rama 7. Configuración).
    echo "  (stub) Configuración actual de sensores"
    admin_pause
}
