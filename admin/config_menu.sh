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
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) config_view ;;
            2) config_validate ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

config_view() {
    echo "  [Configuración] Ver"
    # TODO: mostrar config/config.conf, config/policy.conf y
    # config/whitelist.conf. Solo lectura desde este submenú;
    # la edición se realiza fuera de ARE ADMIN (archivo directo
    # o mecanismo de instalación/repair).
    echo "  (stub) Configuración operativa actual"
    admin_pause
}

config_validate() {
    echo "  [Configuración] Validar"
    # TODO: reutilizar validator.sh contra los templates de
    # templates/config/, igual que hace el Installer Engine
    # (install_install_configs) al detectar plantillas
    # obligatorias faltantes.
    echo "  (stub) Validación de configuración operativa"
    admin_pause
}
