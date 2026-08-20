#!/usr/bin/env bash
# ============================================================
# admin/policy_menu.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Política
#
# Permite inspeccionar y validar la configuración del Policy
# Engine. NO ejecuta una decisión sobre una IP concreta.
# Sufijo "_menu" para no colisionar con policy/policy.sh.
# ============================================================

policy_menu() {
    while true; do
        echo
        echo "  -- Política --"
        echo "  1) Ver configuración"
        echo "  2) Validar"
        echo "  0) Volver"
        echo "  x) Salir"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) policy_view_config ;;
            2) policy_validate ;;
            0) return 0 ;;
            x|X) admin_exit ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

policy_view_config() {
    echo "=================================================="
    echo "POLÍTICA - Configuración"
    echo "=================================================="

    echo
    echo "Umbrales de decisión global:"
    echo "  WATCH_SCORE............. ${WATCH_SCORE:-N/D}"
    echo "  TEMP_BAN_SCORE........... ${TEMP_BAN_SCORE:-N/D}"
    echo "  PERMANENT_BAN_SCORE...... ${PERMANENT_BAN_SCORE:-N/D}"

    echo
    echo "Umbrales por categoría (policy/rules/*.sh):"
    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
    else
        for cat in $REPUTATION_CATEGORIES; do
            local var="${cat}_THRESHOLD"
            printf "  %-14s %s\n" "$cat" "${!var:-N/D}"
        done
    fi

    echo
    echo "Señal temporal (no ligada a categoría):"
    echo "  BRUTEFORCE_EVENTS_24H_THRESHOLD... ${BRUTEFORCE_EVENTS_24H_THRESHOLD:-N/D}"

    echo
    echo "Amplificación por reincidencia (risk.sh):"
    echo "  RISK_MULT_WATCH........... ${RISK_MULT_WATCH:-1 (neutro, sin definir)}"
    echo "  RISK_MULT_BANNED.......... ${RISK_MULT_BANNED:-1 (neutro, sin definir)}"

    echo
    echo "Ban Lifecycle (escalada por reincidencia):"
    echo "  Nivel máximo (BAN_LEVEL_MAX)... ${BAN_LEVEL_MAX:-N/D}"
    local i
    for i in 1 2 3 4 5 6; do
        local var="BAN_LEVEL_${i}_TIME"
        local secs="${!var:-}"
        if [ -n "$secs" ]; then
            printf "  Nivel %d........................ %ss (%s)\n" "$i" "$secs" "$(_policy_fmt_duration "$secs")"
        else
            printf "  Nivel %d........................ N/D\n" "$i"
        fi
    done
    echo "  Nivel ${BAN_LEVEL_MAX:-?}........................ Permanente"

    echo "=================================================="
    admin_pause
}

# Helper interno: formatea segundos a una unidad legible (h/d)
_policy_fmt_duration() {
    local secs="$1"
    if [ "$secs" -ge 86400 ]; then
        echo "$((secs / 86400))d"
    elif [ "$secs" -ge 3600 ]; then
        echo "$((secs / 3600))h"
    else
        echo "${secs}s"
    fi
}

policy_validate() {
    echo "=================================================="
    echo "POLÍTICA - Validación"
    echo "=================================================="

    local ok=1

    echo
    echo "1) Umbrales de decisión global (orden ascendente):"
    if [ -n "${WATCH_SCORE:-}" ] && [ -n "${TEMP_BAN_SCORE:-}" ] && [ -n "${PERMANENT_BAN_SCORE:-}" ]; then
        if (( $(echo "$WATCH_SCORE < $TEMP_BAN_SCORE" | bc -l) )) && \
           (( $(echo "$TEMP_BAN_SCORE < $PERMANENT_BAN_SCORE" | bc -l) )); then
            echo "  [OK]    WATCH_SCORE($WATCH_SCORE) < TEMP_BAN_SCORE($TEMP_BAN_SCORE) < PERMANENT_BAN_SCORE($PERMANENT_BAN_SCORE)"
        else
            echo "  [ERROR] Umbrales fuera de orden: WATCH=$WATCH_SCORE TEMP_BAN=$TEMP_BAN_SCORE PERMANENT_BAN=$PERMANENT_BAN_SCORE"
            ok=0
        fi
    else
        echo "  [ERROR] Falta definir uno o más umbrales globales en policy.conf"
        ok=0
    fi

    echo
    echo "2) Cobertura de categorías (informativo, no es error):"
    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  [ERROR] REPUTATION_CATEGORIES no está definida en policy.conf"
        ok=0
    else
        local cat with_threshold=0 without_threshold=0
        for cat in $REPUTATION_CATEGORIES; do
            local var="${cat}_THRESHOLD"
            if [ -n "${!var:-}" ]; then
                with_threshold=$((with_threshold + 1))
            else
                echo "  [INFO]  $cat sin umbral definido (regla inactiva por diseño)"
                without_threshold=$((without_threshold + 1))
            fi
        done
        echo "  Categorías con umbral activo: $with_threshold / $((with_threshold + without_threshold))"
    fi

    echo
    echo "3) Reglas correspondientes a cada categoría activa (policy/rules/):"
    if [ -n "${REPUTATION_CATEGORIES:-}" ]; then
        for cat in $REPUTATION_CATEGORIES; do
            local var="${cat}_THRESHOLD"
            if [ -n "${!var:-}" ]; then
                local lower
                lower=$(echo "$cat" | tr '[:upper:]' '[:lower:]')
                local rule_file="${ARE_HOME}/policy/rules/${lower}.sh"
                local func="policy_rule_${lower}"
                if [ -f "$rule_file" ] && declare -F "$func" >/dev/null; then
                    echo "  [OK]    $cat -> $func()"
                else
                    echo "  [ERROR] $cat tiene umbral definido pero falta la regla ($rule_file / $func)"
                    ok=0
                fi
            fi
        done
    fi

    echo
    echo "=================================================="
    if [ "$ok" -eq 1 ]; then
        echo "  Resultado: CONFIGURACIÓN DE POLÍTICA VÁLIDA"
    else
        echo "  Resultado: SE ENCONTRARON PROBLEMAS"
    fi
    echo "=================================================="
    admin_pause
}
