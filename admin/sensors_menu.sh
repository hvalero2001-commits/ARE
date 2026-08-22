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
#
# RFC-017: "Estado" ahora lee sensor_registry dinámicamente, en
# vez de texto fijo por sensor — un sensor nuevo aparece solo,
# sin código nuevo en este archivo. Se agrega "Activar/Desactivar".
# ============================================================
sensors_menu() {
    while true; do
        echo
        echo "  -- Sensores --"
        echo "  1) Estado"
        echo "  2) Configuración"
        echo "  3) Activar/Desactivar"
        echo "  0) Volver"
        echo "  x) Salir"
        read -rp "  Seleccione una opción: " opt
        case "$opt" in
            1) sensors_status ;;
            2) sensors_config ;;
            3) sensors_toggle ;;
            0) return 0 ;;
            x|X) admin_exit ;;
            *) echo "Opción inválida." ;;
        esac
    done
}
sensors_status() {
    echo "=================================================="
    echo "SENSORES - ESTADO"
    echo "=================================================="

    db_list_sensor_registry | while IFS='|' read -r name pattern enabled timer description; do
        local estado="Deshabilitado"
        [ "$enabled" = "1" ] && estado="Habilitado"

        echo ""
        echo "Sensor: $name (patrón $pattern) — $estado"
        echo "  $description"

        if [ "$pattern" = "polling" ] && [ -n "$timer" ] && command -v systemctl >/dev/null 2>&1; then
            echo ""
            echo "  Timer systemd ($timer):"
            systemctl status "$timer" --no-pager 2>&1 | head -n 5 | sed 's/^/  /'
        elif [ "$pattern" = "callback" ]; then
            echo "  Invocado directamente (sin timer systemd)."
        fi
    done

    echo ""
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
    echo "spamassassin (polling):"
    echo "  MTA..................... ${SPAMASSASSIN_MTA:-exim}"
    echo "  Log fuente.............. ${SPAMASSASSIN_LOG_FILE:-/var/log/exim_mainlog}"
    echo "  Score mínimo............ ${SPAMASSASSIN_MIN_SCORE:-5.0}"
    echo "  Banda media desde....... ${SPAMASSASSIN_BAND_MED_FROM:-10.0}"
    echo "  Banda alta desde........ ${SPAMASSASSIN_BAND_HIGH_FROM:-15.0}"
    echo ""
    echo "apache_evasive (callback):"
    echo "  Invocado por............ DOSSystemCommand (mod_evasive)"
    echo "  Reporta a categoría..... DOS"
    echo "=================================================="
    admin_pause
}
sensors_toggle() {
    echo "=================================================="
    echo "SENSORES - ACTIVAR/DESACTIVAR"
    echo "=================================================="

    local -a names=()
    local i=1
    local name pattern enabled timer description estado

    while IFS='|' read -r name pattern enabled timer description; do
        estado="deshabilitado"
        [ "$enabled" = "1" ] && estado="habilitado"
        echo "  $i) $name ($estado)"
        names+=("$name")
        i=$((i + 1))
    done < <(db_list_sensor_registry)

    echo "  0) Volver"
    echo "  x) Salir"
    read -rp "  Seleccione un sensor: " sel

    if [ "$sel" = "0" ]; then
        return 0
    fi

    if [ "$sel" = "x" ] || [ "$sel" = "X" ]; then
        admin_exit
    fi

    if ! [[ "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt "${#names[@]}" ]; then
        echo "Opción inválida."
        admin_pause
        return 0
    fi

    local target="${names[$((sel - 1))]}"
    local current_data
    current_data=$(db_get_sensor "$target")

    local current_enabled current_pattern current_timer
    current_pattern=$(echo "$current_data" | cut -d'|' -f1)
    current_enabled=$(echo "$current_data" | cut -d'|' -f2)
    current_timer=$(echo "$current_data" | cut -d'|' -f3)

    local new_state=1
    [ "$current_enabled" = "1" ] && new_state=0

    db_set_sensor_enabled "$target" "$new_state"

    if [ "$current_pattern" = "polling" ] && [ -n "$current_timer" ] && command -v systemctl >/dev/null 2>&1; then
        if [ "$new_state" = "1" ]; then
            systemctl enable --now "$current_timer" >/dev/null 2>&1
            echo "Sensor '$target' habilitado — timer '$current_timer' activado."
        else
            systemctl disable --now "$current_timer" >/dev/null 2>&1
            echo "Sensor '$target' deshabilitado — timer '$current_timer' detenido."
        fi
    elif [ "$current_pattern" = "callback" ]; then
        echo "Sensor '$target' marcado como $([ "$new_state" = "1" ] && echo habilitado || echo deshabilitado) en el registro."
        echo "AVISO: los sensores de patrón callback todavía no verifican este"
        echo "estado por sí mismos (RFC-017, Fase 2 pendiente) — para"
        echo "desactivar '$target' de verdad, hay que retirar la invocación"
        echo "correspondiente en su configuración externa (por ejemplo,"
        echo "DOSSystemCommand en mod_evasive.conf para apache_evasive)."
    fi

    if command -v admin_log >/dev/null 2>&1; then
        admin_log "sensor_toggle" "$target -> enabled=$new_state"
    fi

    admin_pause
}
