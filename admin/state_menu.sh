#!/usr/bin/env bash
# ============================================================
# admin/state_menu.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Estado / Reputación
#
# Permite consultar el conocimiento acumulado y el historial
# de eventos de una IP, y obtener un listado priorizado (Top).
# Solo lectura, salvo Exportar/Importar reputación (IDEA-011),
# que escribe reputation_scores vía db_add_score() ya existente
# — mismo mecanismo que cualquier sensor, sin ruta nueva de
# escritura.
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
        echo "  9) Exportar reputación"
        echo "  10) Importar reputación"
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
            9) state_export_reputation ;;
            10) state_import_reputation ;;
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

#############################################################
# IDEA-011: Exportar reputación
#
# Exporta IPs con score >= umbral en las categorías elegidas,
# a un archivo portable en ${ARE_DATA}/backups/reputation/ —
# mismo patrón que jail_profile (RFC-011), timestamp
# automático, cabecera de comentarios.
#############################################################
state_export_reputation() {

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
        admin_pause
        return 1
    fi

    echo
    echo "  -- Exportar reputación --"
    echo "  Categorías disponibles:"

    local -a cat_arr
    local i=1
    local cat
    for cat in $REPUTATION_CATEGORIES; do
        echo "    $i) $cat"
        cat_arr[$i]="$cat"
        i=$((i + 1))
    done
    local total=$((i - 1))

    read -rp "  Categorías a exportar (números separados por espacio, o 'all') [default: BOT RECON EXPLOIT]: " selection

    local -a selected_categories=()

    if [ -z "$selection" ]; then
        selected_categories=(BOT RECON EXPLOIT)
    elif [ "$selection" = "all" ]; then
        selected_categories=("${cat_arr[@]}")
    else
        local n
        for n in $selection; do
            if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "$total" ]; then
                echo "  Opción inválida: $n — se omite."
                continue
            fi
            selected_categories+=("${cat_arr[$n]}")
        done
    fi

    if [ ${#selected_categories[@]} -eq 0 ]; then
        echo "  No se seleccionó ninguna categoría válida."
        admin_pause
        return 1
    fi

    read -rp "  Score mínimo para exportar [default 10]: " min_score
    min_score="${min_score:-10}"
    if ! [[ "$min_score" =~ ^[0-9]+$ ]]; then
        echo "  Valor inválido, usando 10 por defecto."
        min_score=10
    fi

    local categories_str="${selected_categories[*]}"

    local rows
    rows=$(db_export_reputation "$categories_str" "$min_score")

    if [ -z "$rows" ]; then
        echo "  No hay IPs que cumplan el criterio (categorías: $categories_str, score >= $min_score)."
        admin_pause
        return 0
    fi

    local export_dir="${ARE_DATA}/backups/reputation"
    mkdir -p "$export_dir"

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local hostname_str
    hostname_str=$(hostname)
    local file="${export_dir}/reputation-${timestamp}.txt"

    {
        echo "# ARE - Exportación de reputación"
        echo "# Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Origen: $hostname_str"
        echo "# Categorías: $categories_str"
        echo "# Score mínimo: $min_score"
        echo "$rows"
    } > "$file"

    local count
    count=$(echo "$rows" | grep -c .)

    echo "  Exportación completada: $file"
    echo "  IPs exportadas: $count"

    admin_audit_log "reputation_export" "archivo=$file categorias=$categories_str score_min=$min_score ips=$count"
    admin_pause
}

#############################################################
# IDEA-011: Importar reputación
#
# Aplica un archivo exportado por otro servidor. Solo se
# aplican filas cuya categoría ya tenga presencia en el
# jail_profile local (filtro de relevancia por rol) — el
# resto se omite, sin abortar el resto del archivo. Acumula
# vía db_add_score(), igual que cualquier sensor real.
#############################################################
state_import_reputation() {

    local import_dir="${ARE_DATA}/backups/reputation"

    if [ ! -d "$import_dir" ] || [ -z "$(ls -A "$import_dir" 2>/dev/null)" ]; then
        echo "  No hay archivos de reputación disponibles para importar en $import_dir"
        admin_pause
        return 0
    fi

    echo
    echo "  -- Importar reputación --"
    echo "  Archivos disponibles:"

    local -a files
    local i=1
    local f
    for f in "$import_dir"/*; do
        echo "    $i) $(basename "$f")"
        files[$i]="$f"
        i=$((i + 1))
    done
    local total=$((i - 1))

    read -rp "  Seleccione un archivo (número): " n
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "$total" ]; then
        echo "  Selección inválida."
        admin_pause
        return 1
    fi

    local file="${files[$n]}"

    local applied=0
    local skipped=0
    local errors=0

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        case "$line" in
            \#*) continue ;;
        esac

        IFS='|' read -r ip category score updated <<< "$line"

        if [ -z "$ip" ] || [ -z "$category" ] || [ -z "$score" ]; then
            errors=$((errors + 1))
            continue
        fi

        if ! [[ "$score" =~ ^[0-9]+$ ]]; then
            errors=$((errors + 1))
            continue
        fi

        local valid_category=0
        local c
        for c in $REPUTATION_CATEGORIES; do
            if [ "$c" = "$category" ]; then
                valid_category=1
                break
            fi
        done

        if [ "$valid_category" -eq 0 ]; then
            errors=$((errors + 1))
            continue
        fi

        local has_local
        has_local=$(db_category_exists_locally "$category")

        if [ -z "$has_local" ] || [ "$has_local" -eq 0 ]; then
            skipped=$((skipped + 1))
            continue
        fi

        db_add_score "$ip" "$category" "$score"
        applied=$((applied + 1))

    done < "$file"

    echo "  Importación completada."
    echo "  Aplicadas: $applied"
    echo "  Omitidas (categoría no aplicable localmente): $skipped"
    echo "  Errores de formato: $errors"

    admin_audit_log "reputation_import" "archivo=$(basename "$file") aplicadas=$applied omitidas=$skipped errores=$errors"
    admin_pause
}
