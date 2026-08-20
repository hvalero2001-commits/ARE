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
        echo "  x) Salir"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) sensors_status ;;
            2) sensors_config ;;
            0) return 0 ;;
            x|X) admin_exit ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

sensors_status() {
    local offset_file="${ARE_DATA}/fail2ban.offset"
    local timer_name="are-fail2ban-found.timer"

    echo "=================================================="
    echo "SENSORES - ESTADO"
    echo "=================================================="
    echo "Sensor: fail2ban (patrón polling)"
    echo ""

    if [ -f "$offset_file" ]; then
        echo "Offset actual (línea de log)... $(cat "$offset_file")"
    else
        echo "Offset actual (línea de log)... Sin ejecución previa"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        echo ""
        echo "Timer systemd (${timer_name}):"
        systemctl status "$timer_name" --no-pager 2>&1 | head -n 5
    fi

    echo ""
    echo "Sensor: apache_evasive (patrón callback)"
    echo "  Invocado directamente por Apache/mod_evasive,"
    echo "  no por systemd timer."
    echo ""
    echo "Sensores no implementados aún: crowdsec, modsecurity"
    echo "propio, suricata, zeek (roadmap de próximas versiones)."
    echo "=================================================="
    admin_pause
}

sensors_config() {
    echo "=================================================="
    echo "SENSORES - CONFIGURACIÓN"
    echo "=================================================="
    echo "Directorio de sensores.... ${ARE_SENSOR_DIR}"
    echo ""
    echo "fail2ban (polling):"
    echo "  Log fuente............. ${FAIL2BAN_LOG_FILE:-/var/log/fail2ban.log}"
    echo "  Archivo de offset...... ${ARE_DATA}/fail2ban.offset"
    echo "  Jails admitidos........ dinámico (según jail_profile)"
    echo ""
    echo "apache_evasive (callback):"
    echo "  Invocado por............ DOSSystemCommand (mod_evasive)"
    echo "  Reporta a categoría..... DOS"
    echo "=================================================="
    admin_pause
}
