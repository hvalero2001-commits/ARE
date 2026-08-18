#!/usr/bin/env bash
# ============================================================
# admin/jails.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Jails / Perfiles
#
# Administra la relación jail -> categoría de reputación
# (jail_profile). NO modifica la tabla `reputation` ni
# `sanction_state` (ver docs/DESIGN.md, Sección 13.5).
# ============================================================

jails_menu() {
    while true; do
        echo
        echo "  -- Jails / Perfiles --"
        echo "  1) Listar"
        echo "  2) Crear"
        echo "  3) Modificar"
        echo "  4) Eliminar"
        echo "  5) Validar"
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) jails_list ;;
            2) jails_create ;;
            3) jails_modify ;;
            4) jails_delete ;;
            5) jails_validate ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

jails_list() {
    echo "=================================================="
    echo "JAILS / PERFILES"
    echo "=================================================="

    local profiles
    profiles=$(db_list_jail_profiles)

    if [ -z "$profiles" ]; then
        echo "  No hay perfiles registrados."
        echo "=================================================="
        admin_pause
        return 0
    fi

    printf "  %-20s %-12s %-8s %-10s %-8s %s\n" "NOMBRE" "CATEGORÍA" "PESO" "CONFIANZA" "DECAY" "DESCRIPCIÓN"
    echo "  --------------------------------------------------------------------------"

    echo "$profiles" | while IFS='|' read -r name category weight confidence decay description; do
        printf "  %-20s %-12s %-8s %-10s %-8s %s\n" "$name" "$category" "$weight" "$confidence" "$decay" "$description"
    done

    echo "=================================================="
    admin_pause
}

#############################################################
# jails_select_weight_confidence <category> [current_weight] [current_confidence]
#
# Prompt interactivo compartido por jails_create() y
# jails_modify() para elegir peso/confianza con criterio:
# 1) si existe una escala curada para la categoría
#    (config/jail_scale.conf), la muestra como opciones;
# 2) si no, pero hay perfiles históricos en la categoría,
#    muestra min/máx/promedio como referencia;
# 3) si no hay nada, pide los valores a mano.
#
# En modo "modificar" (current_weight/current_confidence
# presentes) agrega la opción "mantener valor actual".
#
# No usa command substitution para no perder el diálogo
# interactivo; deja el resultado en SEL_WEIGHT/SEL_CONFIDENCE.
#############################################################
jails_select_weight_confidence() {
    local category="$1"
    local cur_weight="${2:-}"
    local cur_confidence="${3:-}"

    SEL_WEIGHT=""
    SEL_CONFIDENCE=""

    local stats
    stats=$(db_category_weight_stats "$category")
    local w_min w_max w_avg w_count
    w_min=$(echo "$stats" | cut -d'|' -f1)
    w_max=$(echo "$stats" | cut -d'|' -f2)
    w_avg=$(echo "$stats" | cut -d'|' -f3)
    w_count=$(echo "$stats" | cut -d'|' -f4)

    local scale_file="${ARE_JAIL_SCALE_CONFIG:-}"
    local scale_lines=""
    if [ -n "$scale_file" ] && [ -f "$scale_file" ]; then
        scale_lines=$(grep "^${category}|" "$scale_file" 2>/dev/null || true)
    fi

    echo

    if [ -n "$scale_lines" ]; then
        echo "  Escala de referencia para $category:"
        echo
        local -a levels=()
        local i=1
        while IFS='|' read -r lvl_cat lvl_name lvl_weight lvl_conf; do
            printf "    %d) %-30s peso=%-6s confianza=%s\n" "$i" "$lvl_name" "$lvl_weight" "$lvl_conf"
            levels+=("$lvl_weight|$lvl_conf")
            i=$((i + 1))
        done <<< "$scale_lines"

        if [ -n "$cur_weight" ]; then
            echo "    m) Mantener valores actuales (peso=$cur_weight confianza=$cur_confidence)"
        fi
        echo "    0) Ingresar valores manualmente"
        echo
        read -rp "  Seleccione nivel: " lvl_idx

        if [ "$lvl_idx" = "m" ] && [ -n "$cur_weight" ]; then
            SEL_WEIGHT="$cur_weight"
            SEL_CONFIDENCE="$cur_confidence"
        elif [[ "$lvl_idx" =~ ^[0-9]+$ ]] && [ "$lvl_idx" -ge 1 ] && [ "$lvl_idx" -le "${#levels[@]}" ]; then
            SEL_WEIGHT=$(echo "${levels[$((lvl_idx - 1))]}" | cut -d'|' -f1)
            SEL_CONFIDENCE=$(echo "${levels[$((lvl_idx - 1))]}" | cut -d'|' -f2)
            echo "  Seleccionado: peso=$SEL_WEIGHT confianza=$SEL_CONFIDENCE"
        else
            read -rp "  Peso (weight, número > 0)${cur_weight:+ [actual: $cur_weight]}: " SEL_WEIGHT
            SEL_WEIGHT="${SEL_WEIGHT:-$cur_weight}"
            read -rp "  Confianza (confidence, 0.0 - 1.0)${cur_confidence:+ [actual: $cur_confidence]}: " SEL_CONFIDENCE
            SEL_CONFIDENCE="${SEL_CONFIDENCE:-$cur_confidence}"
        fi

    elif [ "$w_count" -gt 0 ]; then
        echo "  Referencia de peso para $category (basada en $w_count perfil(es) existente(s)):"
        echo "    Mínimo: $w_min   Máximo: $w_max   Promedio: $w_avg"
        local default_w="${cur_weight:-$w_avg}"
        read -rp "  Peso (weight, número > 0) [default $default_w]: " SEL_WEIGHT
        SEL_WEIGHT="${SEL_WEIGHT:-$default_w}"
        read -rp "  Confianza (confidence, 0.0 - 1.0)${cur_confidence:+ [actual: $cur_confidence]}: " SEL_CONFIDENCE
        SEL_CONFIDENCE="${SEL_CONFIDENCE:-$cur_confidence}"

    else
        echo "  Sin referencia disponible para $category."
        read -rp "  Peso (weight, número > 0)${cur_weight:+ [actual: $cur_weight]}: " SEL_WEIGHT
        SEL_WEIGHT="${SEL_WEIGHT:-$cur_weight}"
        read -rp "  Confianza (confidence, 0.0 - 1.0)${cur_confidence:+ [actual: $cur_confidence]}: " SEL_CONFIDENCE
        SEL_CONFIDENCE="${SEL_CONFIDENCE:-$cur_confidence}"
    fi
}

jails_create() {
    echo "=================================================="
    echo "JAILS / PERFILES - Crear"
    echo "=================================================="

    read -rp "  Nombre del jail: " name

    if [ -z "$name" ]; then
        echo "  Nombre vacío, operación cancelada."
        admin_pause
        return 1
    fi

    if db_jail_profile_exists "$name"; then
        echo "  Ya existe un perfil para '$name'. Use Modificar en su lugar."
        admin_pause
        return 1
    fi

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
        admin_pause
        return 1
    fi

    echo
    echo "  Categorías disponibles:"
    local -a cats=($REPUTATION_CATEGORIES)
    local i=1
    for c in "${cats[@]}"; do
        echo "    $i) $c"
        i=$((i + 1))
    done

    read -rp "  Seleccione categoría (número): " cat_idx

    if ! [[ "$cat_idx" =~ ^[0-9]+$ ]] || [ "$cat_idx" -lt 1 ] || [ "$cat_idx" -gt "${#cats[@]}" ]; then
        echo "  Selección inválida, operación cancelada."
        admin_pause
        return 1
    fi

    local category="${cats[$((cat_idx - 1))]}"

    jails_select_weight_confidence "$category"
    local weight="$SEL_WEIGHT"
    local confidence="$SEL_CONFIDENCE"

    if ! [[ "$weight" =~ ^[0-9]+([.][0-9]+)?$ ]] || (( $(echo "$weight <= 0" | bc -l) )); then
        echo "  Peso inválido, operación cancelada."
        admin_pause
        return 1
    fi

    if ! [[ "$confidence" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
       (( $(echo "$confidence < 0" | bc -l) )) || \
       (( $(echo "$confidence > 1" | bc -l) )); then
        echo "  Confianza inválida (debe estar entre 0.0 y 1.0), operación cancelada."
        admin_pause
        return 1
    fi

    read -rp "  Decay (0.0 - 1.0) [default 0.95]: " decay
    decay="${decay:-0.95}"
    if ! [[ "$decay" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
       (( $(echo "$decay < 0" | bc -l) )) || \
       (( $(echo "$decay > 1" | bc -l) )); then
        echo "  Decay inválido (debe estar entre 0.0 y 1.0), operación cancelada."
        admin_pause
        return 1
    fi

    read -rp "  Descripción: " description

    echo
    echo "  Se creará el siguiente perfil:"
    echo "    Nombre....... $name"
    echo "    Categoría.... $category"
    echo "    Peso......... $weight"
    echo "    Confianza.... $confidence"
    echo "    Decay........ $decay"
    echo "    Descripción.. $description"
    read -rp "  Confirma (s/N): " confirm

    if [[ "$confirm" =~ ^[sS]$ ]]; then
        db_create_jail_profile "$name" "$category" "$weight" "$confidence" "$decay" "$description"
        echo "  Perfil creado: $name -> $category"
    else
        echo "  Operación cancelada."
    fi

    admin_pause
}

jails_modify() {
    echo "=================================================="
    echo "JAILS / PERFILES - Modificar"
    echo "=================================================="

    local profiles
    profiles=$(db_list_jail_profiles)

    if [ -z "$profiles" ]; then
        echo "  No hay perfiles registrados."
        admin_pause
        return 0
    fi

    echo "  Perfiles existentes:"
    echo
    local -a names=()
    local i=1
    while IFS='|' read -r p_name p_category p_weight p_confidence p_decay p_description; do
        printf "    %d) %-20s %-12s peso=%-6s confianza=%s\n" "$i" "$p_name" "$p_category" "$p_weight" "$p_confidence"
        names+=("$p_name")
        i=$((i + 1))
    done <<< "$profiles"

    echo "    0) Cancelar"
    echo
    read -rp "  Seleccione el jail a modificar (número): " sel_idx

    if [[ "$sel_idx" == "0" ]] || [ -z "$sel_idx" ]; then
        echo "  Operación cancelada."
        admin_pause
        return 0
    fi

    if ! [[ "$sel_idx" =~ ^[0-9]+$ ]] || [ "$sel_idx" -lt 1 ] || [ "$sel_idx" -gt "${#names[@]}" ]; then
        echo "  Selección inválida."
        admin_pause
        return 1
    fi

    local name="${names[$((sel_idx - 1))]}"

    if ! db_jail_profile_exists "$name"; then
        echo "  No existe un perfil para '$name'. Use Crear en su lugar."
        admin_pause
        return 1
    fi

    local current
    current=$(db_get_jail_profile_full "$name")
    local cur_category cur_weight cur_confidence cur_decay cur_description
    cur_category=$(echo "$current" | cut -d'|' -f1)
    cur_weight=$(echo "$current" | cut -d'|' -f2)
    cur_confidence=$(echo "$current" | cut -d'|' -f3)
    cur_decay=$(echo "$current" | cut -d'|' -f4)
    cur_description=$(echo "$current" | cut -d'|' -f5)

    echo
    echo "  Valores actuales de '$name':"
    echo "    Categoría.... $cur_category"
    echo "    Peso......... $cur_weight"
    echo "    Confianza.... $cur_confidence"
    echo "    Decay........ $cur_decay"
    echo "    Descripción.. $cur_description"
    echo
    echo "  Presione ENTER en cualquier campo para conservar el valor actual."
    echo

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
        admin_pause
        return 1
    fi

    echo "  Categorías disponibles:"
    local -a cats=($REPUTATION_CATEGORIES)
    local i=1
    for c in "${cats[@]}"; do
        echo "    $i) $c"
        i=$((i + 1))
    done

    read -rp "  Seleccione categoría (número) [actual: $cur_category]: " cat_idx

    local category="$cur_category"
    if [ -n "$cat_idx" ]; then
        if [[ "$cat_idx" =~ ^[0-9]+$ ]] && [ "$cat_idx" -ge 1 ] && [ "$cat_idx" -le "${#cats[@]}" ]; then
            category="${cats[$((cat_idx - 1))]}"
        else
            echo "  Selección inválida, se conserva la categoría actual."
        fi
    fi

    jails_select_weight_confidence "$category" "$cur_weight" "$cur_confidence"
    local weight="$SEL_WEIGHT"
    local confidence="$SEL_CONFIDENCE"

    read -rp "  Decay (0.0 - 1.0) [actual: $cur_decay]: " decay
    decay="${decay:-$cur_decay}"

    read -rp "  Descripción [actual: $cur_description]: " description
    description="${description:-$cur_description}"

    if ! [[ "$weight" =~ ^[0-9]+([.][0-9]+)?$ ]] || (( $(echo "$weight <= 0" | bc -l) )); then
        echo "  Peso inválido, operación cancelada."
        admin_pause
        return 1
    fi

    if ! [[ "$confidence" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
       (( $(echo "$confidence < 0" | bc -l) )) || \
       (( $(echo "$confidence > 1" | bc -l) )); then
        echo "  Confianza inválida (debe estar entre 0.0 y 1.0), operación cancelada."
        admin_pause
        return 1
    fi

    if ! [[ "$decay" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
       (( $(echo "$decay < 0" | bc -l) )) || \
       (( $(echo "$decay > 1" | bc -l) )); then
        echo "  Decay inválido (debe estar entre 0.0 y 1.0), operación cancelada."
        admin_pause
        return 1
    fi

    echo
    echo "  Se actualizará el perfil de la siguiente manera:"
    printf "    %-12s %-15s -> %s\n" "Categoría:" "$cur_category" "$category"
    printf "    %-12s %-15s -> %s\n" "Peso:" "$cur_weight" "$weight"
    printf "    %-12s %-15s -> %s\n" "Confianza:" "$cur_confidence" "$confidence"
    printf "    %-12s %-15s -> %s\n" "Decay:" "$cur_decay" "$decay"
    printf "    %-12s %-15s -> %s\n" "Descripción:" "$cur_description" "$description"
    read -rp "  Confirma (s/N): " confirm

    if [[ "$confirm" =~ ^[sS]$ ]]; then
        db_update_jail_profile "$name" "$category" "$weight" "$confidence" "$decay" "$description"
        echo "  Perfil actualizado: $name"
    else
        echo "  Operación cancelada."
    fi

    admin_pause
}

jails_delete() {
    echo "=================================================="
    echo "JAILS / PERFILES - Eliminar"
    echo "=================================================="

    local profiles
    profiles=$(db_list_jail_profiles)

    if [ -z "$profiles" ]; then
        echo "  No hay perfiles registrados."
        admin_pause
        return 0
    fi

    echo "  Perfiles existentes:"
    echo
    local -a names=()
    local i=1
    while IFS='|' read -r p_name p_category p_weight p_confidence p_decay p_description; do
        printf "    %d) %-20s %-12s peso=%-6s confianza=%s\n" "$i" "$p_name" "$p_category" "$p_weight" "$p_confidence"
        names+=("$p_name")
        i=$((i + 1))
    done <<< "$profiles"

    echo "    0) Cancelar"
    echo
    read -rp "  Seleccione el jail a eliminar (número): " sel_idx

    if [[ "$sel_idx" == "0" ]] || [ -z "$sel_idx" ]; then
        echo "  Operación cancelada."
        admin_pause
        return 0
    fi

    if ! [[ "$sel_idx" =~ ^[0-9]+$ ]] || [ "$sel_idx" -lt 1 ] || [ "$sel_idx" -gt "${#names[@]}" ]; then
        echo "  Selección inválida."
        admin_pause
        return 1
    fi

    local name="${names[$((sel_idx - 1))]}"

    local current
    current=$(db_get_jail_profile_full "$name")
    local cur_category cur_weight cur_confidence cur_decay cur_description
    cur_category=$(echo "$current" | cut -d'|' -f1)
    cur_weight=$(echo "$current" | cut -d'|' -f2)
    cur_confidence=$(echo "$current" | cut -d'|' -f3)
    cur_decay=$(echo "$current" | cut -d'|' -f4)
    cur_description=$(echo "$current" | cut -d'|' -f5)

    echo
    echo "  Se eliminará el siguiente perfil:"
    echo "    Nombre....... $name"
    echo "    Categoría.... $cur_category"
    echo "    Peso......... $cur_weight"
    echo "    Confianza.... $cur_confidence"
    echo "    Decay........ $cur_decay"
    echo "    Descripción.. $cur_description"
    echo
    echo "  NOTA: esto elimina únicamente el perfil (jail_profile)."
    echo "  Los eventos históricos ya registrados para este jail NO"
    echo "  se ven afectados — permanecen en la tabla events."
    echo
    echo "  Esta acción no se puede deshacer desde el propio admin."
    read -rp "  Escriba el nombre exacto del jail para confirmar ('$name'): " confirm_name

    if [ "$confirm_name" != "$name" ]; then
        echo "  El nombre no coincide. Operación cancelada."
        admin_pause
        return 1
    fi

    db_delete_jail_profile "$name"
    echo "  Perfil eliminado: $name"

    admin_pause
}

jails_validate() {
    echo "=================================================="
    echo "JAILS / PERFILES - Validación"
    echo "=================================================="

    if [ -z "${REPUTATION_CATEGORIES:-}" ]; then
        echo "  ERROR: REPUTATION_CATEGORIES no está definida en policy.conf"
        admin_pause
        return 1
    fi

    local profiles
    profiles=$(db_validate_jail_profiles)

    if [ -z "$profiles" ]; then
        echo "  No hay perfiles registrados."
        admin_pause
        return 0
    fi

    local -a valid_cats=($REPUTATION_CATEGORIES)
    local ok=1
    local checked=0

    while IFS='|' read -r name category weight confidence; do
        checked=$((checked + 1))
        local problems=""

        local cat_valid=0
        for vc in "${valid_cats[@]}"; do
            [ "$vc" = "$category" ] && cat_valid=1 && break
        done
        if [ "$cat_valid" -eq 0 ]; then
            problems="categoría '$category' no está en REPUTATION_CATEGORIES"
        fi

        if [[ "$weight" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
            if (( $(echo "$weight <= 0" | bc -l) )); then
                [ -n "$problems" ] && problems="$problems; "
                problems="${problems}peso ($weight) debe ser > 0"
            fi
        else
            [ -n "$problems" ] && problems="$problems; "
            problems="${problems}peso ($weight) no es numérico"
        fi

        if [[ "$confidence" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
            if (( $(echo "$confidence < 0" | bc -l) )) || (( $(echo "$confidence > 1" | bc -l) )); then
                [ -n "$problems" ] && problems="$problems; "
                problems="${problems}confianza ($confidence) fuera de rango 0.0-1.0"
            fi
        else
            [ -n "$problems" ] && problems="$problems; "
            problems="${problems}confianza ($confidence) no es numérica"
        fi

        if [ -n "$problems" ]; then
            echo "  [ERROR] $name: $problems"
            ok=0
        fi
    done <<< "$profiles"

    echo
    echo "  Perfiles revisados: $checked"
    echo "=================================================="
    if [ "$ok" -eq 1 ]; then
        echo "  Resultado: TODOS LOS PERFILES SON VÁLIDOS"
    else
        echo "  Resultado: SE ENCONTRARON PROBLEMAS"
    fi
    echo "=================================================="
    admin_pause
}
