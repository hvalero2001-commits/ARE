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
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) policy_view_config ;;
            2) policy_validate ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

policy_view_config() {
    echo "  [Política] Ver configuración"
    # TODO: mostrar umbrales efectivos del Policy Engine
    # (policy/policy.sh, policy/engine.sh, config/policy.conf).
    # Solo lectura: no permite editar umbrales desde aquí.
    echo "  (stub) Umbrales y reglas actuales del Policy Engine"
    admin_pause
}

policy_validate() {
    echo "  [Política] Validar"
    # TODO: reutilizar validator.sh para comprobar
    # consistencia de policy/rules/*.sh contra policy.conf.
    echo "  (stub) Validación de configuración de política"
    admin_pause
}
