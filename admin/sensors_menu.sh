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
    local offset_file="${ARE_DATA}/fail2ban.offset"
    local timer_name="are-fail2ban-found.timer"

    echo "=================================================="
    echo "SENSORES - ESTADO"
    echo "=================================================="
    echo "Sensor: fail2ban"
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
    echo "Sensores no implementados aún: apache, crowdsec,"
    echo "modsecurity, suricata, zeek (roadmap de próximas"
    echo "versiones)."
    echo "=================================================="
    admin_pause
}

sensors_config() {
    echo "=================================================="
    echo "SENSORES - CONFIGURACIÓN"
    echo "=================================================="
    echo "Directorio de sensores.... ${ARE_SENSOR_DIR}"
    echo ""
    echo "fail2ban:"
    echo "  Log fuente............. /var/log/fail2ban.log"
    echo "  Archivo de offset...... ${ARE_DATA}/fail2ban.offset"
    echo "  Jails admitidos........ modsec-*, recidive, sshd, telnet"
    echo ""
    echo "NOTA: la ruta del log de fail2ban está fija dentro"
    echo "de sensors/fail2ban.sh, no proviene de config.conf."
    echo "=================================================="
    admin_pause
}
