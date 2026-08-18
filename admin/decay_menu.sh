#!/usr/bin/env bash
# ============================================================
# admin/decay_menu.sh
# ------------------------------------------------------------
# ARE ADMIN - Módulo: Decay
#
# Wrapper directo sobre decay.sh. Sin lógica propia:
#   - Estado   -> consulta last_decay
#   - Dry-run  -> decay-dry-run (no modifica reputation)
#   - Ejecutar -> decay-apply (Decay -> Reputation -> State
#                 -> Policy; la aplicación efectiva de
#                 cualquier decisión queda a cargo del
#                 mecanismo de Apply, no de este módulo)
# ============================================================

decay_menu() {
    while true; do
        echo
        echo "  -- Decay --"
        echo "  1) Estado"
        echo "  2) Dry-run"
        echo "  3) Ejecutar"
        echo "  0) Volver"
        read -rp "  Seleccione una opción: " opt

        case "$opt" in
            1) decay_status ;;
            2) decay_dry_run ;;
            3) decay_execute ;;
            0) return 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

decay_status() {
    echo "  [Decay] Estado"
    # TODO: consultar last_decay por IP o resumen general.
    echo "  (stub) Estado del Decay Engine (last_decay)"
    admin_pause
}

decay_dry_run() {
    echo "  [Decay] Dry-run"
    # TODO: invocar directamente ./decay.sh decay-dry-run
    # No modifica `reputation` ni provoca reevaluación real.
    echo "  (stub) Ejecutando decay-dry-run..."
    admin_pause
}

decay_execute() {
    echo "  [Decay] Ejecutar"
    read -rp "  Confirma ejecución real de decay-apply (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        # TODO: invocar directamente ./decay.sh decay-apply
        echo "  (stub) Ejecutando decay-apply..."
    else
        echo "  Operación cancelada."
    fi
    admin_pause
}
