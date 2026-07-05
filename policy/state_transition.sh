#!/bin/bash
#############################################################
# ARE - State Transition Engine
#
# Responsable:
#   Validar transiciones entre estados.
#
# No modifica base de datos.
# No modifica firewall.
# Solo responde si una transición es válida.
#############################################################
state_can_transition() {

    local FROM="$1"
    local TO="$2"

    if [ "$FROM" = "$TO" ]; then
        return 0
    fi

    case "$FROM:$TO" in

        NEW:WATCH) return 0 ;;
        NEW:FILTER) return 0 ;;
        NEW:BANNED_TEMP) return 0 ;;
        NEW:BANNED) return 0 ;;

        WATCH:FILTER) return 0 ;;
        WATCH:BANNED_TEMP) return 0 ;;
        WATCH:BANNED) return 0 ;;

        FILTER:BANNED_TEMP) return 0 ;;
        FILTER:BANNED) return 0 ;;

        BANNED_TEMP:WATCH) return 0 ;;
        BANNED_TEMP:NEW) return 0 ;;
        BANNED_TEMP:BANNED) return 0 ;;

        BANNED:BANNED) return 0 ;;

        *)
            return 1
        ;;
    esac
}
