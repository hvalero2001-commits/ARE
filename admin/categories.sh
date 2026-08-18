#!/usr/bin/env bash
# ============================================================
# admin/categories.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Categorías
#
# Expone en modo solo lectura el modelo de reputación
# (RECON, EXPLOIT, CREDENTIAL, PROTOCOL, BOT, ANOMALY,
# MALWARE, DOS, SOCIAL). No escribe sobre `reputation`.
# ============================================================

categories_menu() {
    while true; do
        echo
        echo "  -- Categorías --"
        echo "  1) Listar"
        echo "  2) Ver puntuaciones"
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) categories_list ;;
            2) categories_scores ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

categories_list() {
    echo "  [Categorías] Listar"
    # TODO: listar categorías soportadas por el Reputation Engine.
    # Fuente: constante compartida en database.sh (misma lista
    # usada por dashboard/reputation.sh y dashboard/score.sh).
    echo "  (stub) RECON, EXPLOIT, CREDENTIAL, PROTOCOL, BOT,"
    echo "         ANOMALY, MALWARE, DOS, SOCIAL"
    admin_pause
}

categories_scores() {
    echo "  [Categorías] Ver puntuaciones"
    read -rp "  IP a consultar: " ip
    # TODO: reutilizar dashboard/score.sh (misma función que
    # ya usa `are score <ip>`), no reimplementar el cálculo.
    echo "  (stub) Puntuaciones por categoría para ${ip}"
    admin_pause
}
