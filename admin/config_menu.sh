#!/usr/bin/env bash
# ============================================================
# admin/config_menu.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Configuración
#
# Permite ver y validar la configuración desacoplada
# (config/config.conf, config/policy.conf, config/whitelist.conf).
# No embebe configuración en el código de los motores.
# Sufijo "_menu" para no colisionar con config/*.conf.
# ============================================================

config_menu() {
    while true; do
        echo
        echo "  -- Configuración --"
        echo "  1) Ver"
        echo "  2) Validar"
        echo "  3) Estado del sistema"
        echo "  0) Volver"
        echo "  x) Salir"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) config_view ;;
            2) config_validate ;;
            3) config_system_status ;;
            0) return 0 ;;
            x|X) admin_exit ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

config_view() {
    echo "=================================================="
    echo "CONFIGURACIÓN - config.conf"
    echo "=================================================="
    if [ -f "${ARE_CONFIG}" ]; then
        grep -Ev '^\s*(#|$)' "${ARE_CONFIG}"
    else
        echo "  No encontrado: ${ARE_CONFIG}"
    fi

    echo
    echo "=================================================="
    echo "CONFIGURACIÓN - policy.conf"
    echo "=================================================="
    if [ -f "${ARE_POLICY_CONFIG}" ]; then
        grep -Ev '^\s*(#|$)' "${ARE_POLICY_CONFIG}"
    else
        echo "  No encontrado: ${ARE_POLICY_CONFIG}"
    fi

    echo
    echo "=================================================="
    echo "CONFIGURACIÓN - whitelist.conf"
    echo "=================================================="
    if [ -f "${ARE_WHITELIST}" ]; then
        local count
        count=$(grep -Ev '^\s*(#|$)' "${ARE_WHITELIST}" | wc -l)
        echo "  Entradas activas: ${count}"
        echo
        grep -Ev '^\s*(#|$)' "${ARE_WHITELIST}"
    else
        echo "  No encontrado: ${ARE_WHITELIST}"
    fi
    echo "=================================================="
    admin_pause
}

config_validate() {
    local ok=1

    echo "=================================================="
    echo "CONFIGURACIÓN - Validación"
    echo "=================================================="

    for f in "${ARE_CONFIG}" "${ARE_POLICY_CONFIG}" "${ARE_WHITELIST}"; do
        if [ -f "$f" ] && [ -r "$f" ]; then
            echo "  [OK]    $f"
        else
            echo "  [FALTA] $f"
            ok=0
        fi
    done

    if [ -f "${ARE_POLICY_CONFIG}" ]; then
        # shellcheck source=/dev/null
        source "${ARE_POLICY_CONFIG}"
        if [ -n "$WATCH_SCORE" ] && [ -n "$TEMP_BAN_SCORE" ] && [ -n "$PERMANENT_BAN_SCORE" ]; then
            if [ "$WATCH_SCORE" -lt "$TEMP_BAN_SCORE" ] && [ "$TEMP_BAN_SCORE" -lt "$PERMANENT_BAN_SCORE" ]; then
                echo "  [OK]    Umbrales en orden ascendente (WATCH < TEMP_BAN < PERMANENT_BAN)"
            else
                echo "  [ERROR] Umbrales fuera de orden: WATCH_SCORE=$WATCH_SCORE TEMP_BAN_SCORE=$TEMP_BAN_SCORE PERMANENT_BAN_SCORE=$PERMANENT_BAN_SCORE"
                ok=0
            fi
        else
            echo "  [ERROR] Faltan variables de umbral en policy.conf"
            ok=0
        fi
    fi

    echo "=================================================="
    if [ "$ok" -eq 1 ]; then
        echo "  Resultado: CONFIGURACIÓN VÁLIDA"
    else
        echo "  Resultado: SE ENCONTRARON PROBLEMAS"
    fi
    echo "=================================================="
    admin_pause
}

config_system_status() {
    dashboard_status
    admin_pause
}
