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
    reputation_decay_status
    admin_pause
}

decay_dry_run() {
    reputation_decay_dry_run
    admin_pause
}

decay_execute() {
    read -rp "  Confirma ejecución real de decay-apply (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        reputation_decay_apply
	admin_audit_log "decay_execute" "confirmado"
    else
        echo "  Operación cancelada."
    fi
    admin_pause
}
