#!/usr/bin/env bash
# ============================================================
# admin/core.sh
# ------------------------------------------------------------
# Loop principal y dispatcher de ARE ADMIN.
#
# Responsabilidad única: mostrar el árbol de navegación y
# delegar cada opción a la función correspondiente del módulo
# responsable (jails.sh, categories.sh, sensors_menu.sh, etc.).
#
# core.sh no implementa lógica de negocio. Únicamente rutea.
# Cada submenú (jails_menu, categories_menu, etc.) sigue el
# mismo estilo de loop simple, para mantener el código legible
# y evitar indirección innecesaria.
# ============================================================

admin_print_banner() {
    cat <<'EOF'

  ┌─────────────────────────────────────────┐
  │                ARE ADMIN                 │
  │      Abuse Reputation Engine - CLI       │
  └─────────────────────────────────────────┘

  1) Jails / Perfiles
  2) Categorías
  3) Sensores
  4) Política
  5) Estado / Reputación
  6) Decay
  7) Configuración
  0) Salir

EOF
}

admin_main() {
    while true; do
        admin_print_banner
        read -rp "  Seleccione una opción: " admin_opt

        case "$admin_opt" in
            1) jails_menu ;;
            2) categories_menu ;;
            3) sensors_menu ;;
            4) policy_menu ;;
            5) state_menu ;;
            6) decay_menu ;;
            7) config_menu ;;
            0)
                echo "Saliendo de ARE ADMIN."
                exit 0
                ;;
            *)
                echo "Opción inválida."
                ;;
        esac
    done
}

# ------------------------------------------------------------
# admin_pause
# Utilidad común: pausa de lectura tras mostrar un resultado,
# para que el usuario pueda leerlo antes de volver al menú.
# ------------------------------------------------------------
admin_pause() {
    read -rp "  Presione ENTER para continuar..." _
}
