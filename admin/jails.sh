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
    echo "  [Jails/Perfiles] Listar"
    # TODO: leer jail_profile desde database.sh
    # Ejemplo esperado: db_list_jail_profiles
    admin_pause
}

jails_create() {
    echo "  [Jails/Perfiles] Crear"
    read -rp "  Nombre del jail: " jail_name
    read -rp "  Categoría de reputación: " category
    # TODO: validar categoría contra el modelo de reputación
    # (Reputation Engine, ver DESIGN.md Sección 3.2) antes de
    # insertar. No crear columnas nuevas en `reputation`.
    # Ejemplo esperado: db_create_jail_profile "$jail_name" "$category"
    echo "  (stub) Se crearía el perfil: ${jail_name} -> ${category}"
    admin_pause
}

jails_modify() {
    echo "  [Jails/Perfiles] Modificar"
    read -rp "  Nombre del jail a modificar: " jail_name
    read -rp "  Nueva categoría: " category
    # TODO: db_update_jail_profile "$jail_name" "$category"
    echo "  (stub) Se actualizaría el perfil: ${jail_name} -> ${category}"
    admin_pause
}

jails_delete() {
    echo "  [Jails/Perfiles] Eliminar"
    read -rp "  Nombre del jail a eliminar: " jail_name
    # TODO: db_delete_jail_profile "$jail_name"
    # Confirmar antes de eliminar; no afecta eventos históricos.
    echo "  (stub) Se eliminaría el perfil: ${jail_name}"
    admin_pause
}

jails_validate() {
    echo "  [Jails/Perfiles] Validar"
    # TODO: reutilizar el concepto de verificación de
    # consistencia ya usado por el Installer Engine
    # (ver validator.sh / install_validate).
    # Debe comprobar: jails sin categoría asignada,
    # categorías inexistentes, duplicados.
    echo "  (stub) Validación de consistencia de jail_profile"
    admin_pause
}
