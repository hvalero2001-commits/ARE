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
        echo "  4) Jails sin perfil"
        echo "  0) Volver"
        echo "  x) Salir"
        read -rp "  Seleccione una opción: " opt
        case "$opt" in
            1) sensors_status ;;
            2) sensors_config ;;
            3) sensors_toggle ;;
            4) sensors_detect_unmanaged_jails ;;
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
#############################################################
# RFC-017: Auto-provisión de jail_profile al habilitar
# SpamAssassin desde ARE ADMIN. Duplicada respecto a la lista
# semilla de database.sh::db_init() en vez de sourcear
# sensors/spamassassin.sh — evita ejecutar por efecto
# secundario la lógica de procesamiento del sensor (lectura de
# log, flock, offset) solo por querer esta función puntual.
# Idempotente: si el jail ya existe, no lo toca.
#############################################################
sensors_provision_spamassassin() {

    local jails=(
        "spamassassin-low|SOCIAL|10|0.6|0.95|Rango de score SpamAssassin 5.0 – 9.99"
        "spamassassin-med|SOCIAL|25|0.75|0.95|Rango de score SpamAssassin 10.0 – 14.99"
        "spamassassin-high|SOCIAL|50|0.9|0.95|Rango de score SpamAssassin ≥ 15.0"
    )

    local entry name category weight confidence decay description

    for entry in "${jails[@]}"; do
        IFS='|' read -r name category weight confidence decay description <<< "$entry"

        if db_jail_profile_exists "$name"; then
            continue
        fi

        db_create_jail_profile "$name" "$category" "$weight" "$confidence" "$decay" "$description"
        echo "  Perfil creado: $name"
    done
}
#############################################################
# Detectar jails de Fail2Ban activos (con actividad real en su
# log) sin jail_profile administrado en ARE. Solo lectura — no
# crea nada, no asigna categoría ni peso. La creación queda
# 100% a mano del administrador, vía Jails/Perfiles → Crear.
# Compara contra actividad real del log, no contra la
# configuración de Fail2Ban — un jail configurado pero nunca
# disparado no es ruido útil para esta lista.
#############################################################
sensors_detect_unmanaged_jails() {
    local log_file="${FAIL2BAN_LOG_FILE:-/var/log/fail2ban.log}"

    if [ ! -f "$log_file" ]; then
        echo "Log de Fail2Ban no encontrado: $log_file"
        admin_pause
        return 0
    fi

    echo "=================================================="
    echo "JAILS DE FAIL2BAN SIN PERFIL EN ARE"
    echo "=================================================="

    local active_jails jail found_any=0

    active_jails=$(grep -oP '(?:INFO|NOTICE)\s+\K\[[a-zA-Z0-9_-]+\]' "$log_file" | tr -d '[]' | sort -u)

    for jail in $active_jails; do
        if ! db_jail_profile_exists "$jail"; then
            echo "  - $jail"
            found_any=1
        fi
    done

    if [ "$found_any" -eq 0 ]; then
        echo "  Ninguno — todos los jails activos ya tienen perfil administrado."
    else
        echo ""
        echo "  Estos jails aparecen activos en el log de Fail2Ban, pero"
        echo "  no tienen jail_profile en ARE — sus eventos se descartan"
        echo "  en silencio. Para darlos de alta: Jails/Perfiles → Crear."
    fi

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
            if [ "$target" = "spamassassin" ]; then
                sensors_provision_spamassassin
            fi
            systemctl enable --now "$current_timer" >/dev/null 2>&1
            echo "Sensor '$target' habilitado — timer '$current_timer' activado."
        else
            systemctl disable --now "$current_timer" >/dev/null 2>&1
            echo "Sensor '$target' deshabilitado — timer '$current_timer' detenido."
        fi
    elif [ "$current_pattern" = "callback" ]; then
        local flag_file="$ARE_DATA/${target}.disabled"
        if [ "$new_state" = "1" ]; then
            rm -f "$flag_file"
            echo "Sensor '$target' habilitado — bloqueo directo y reporte a ARE restaurados."
        else
            touch "$flag_file"
            echo "Sensor '$target' deshabilitado — no se aplicará bloqueo ni se reportará"
            echo "reputación para nuevas detecciones. Se sigue enviando un email"
            echo "informativo por cada detección, sin acción tomada sobre la IP."
        fi
    fi

    if command -v admin_log >/dev/null 2>&1; then
        admin_log "sensor_toggle" "$target -> enabled=$new_state"
    fi

    admin_pause
}
