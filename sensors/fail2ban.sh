#!/bin/bash
#############################################################
# Module : Sensor - Fail2Ban (polling-based)
#
# Responsibility
#   Leer el log de Fail2Ban de forma incremental (offset
#   persistente) y reportar a ARE los eventos FOUND y
#   EXTERNAL_UNBAN de los jails que tengan un jail_profile
#   administrado, sin necesidad de mantener una lista fija de
#   jails permitidos en el código.
#
# Dependencies
#   - config/config.conf (ARE_DATA, ARE_BIN, FAIL2BAN_LOG_FILE)
#   - sqlite3 (consulta directa a jail_profile, sin cargar
#     bootstrap.sh completo — este sensor corre cada minuto
#     por systemd timer y se mantiene liviano a propósito)
#
# Exports
#   (no exporta funciones; script de ejecución directa vía
#   systemd timer)
#############################################################
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$BASE/config/config.conf"
if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Configuración no encontrada: $CONFIG"
    exit 1
fi
source "$CONFIG"

LOG_FILE="${FAIL2BAN_LOG_FILE:-/var/log/fail2ban.log}"
OFFSET_FILE="$ARE_DATA/fail2ban.offset"
MODE="${1:---dry-run}"

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log de Fail2Ban no encontrado: $LOG_FILE"
    exit 1
fi

mkdir -p "$(dirname "$OFFSET_FILE")"
TOTAL_LINES=$(wc -l < "$LOG_FILE")
LAST_LINE=0
if [ -f "$OFFSET_FILE" ]; then
    LAST_LINE=$(cat "$OFFSET_FILE")
fi
if [ "$LAST_LINE" -gt "$TOTAL_LINES" ]; then
    LAST_LINE=0
fi
START_LINE=$((LAST_LINE + 1))

sed -n "${START_LINE},${TOTAL_LINES}p" "$LOG_FILE" | while read -r LINE
do
    case "$LINE" in
        *" Found "*)
            ACTION="FOUND"
            JAIL=$(echo "$LINE" | sed -n 's/.*\[\([^]]*\)\] Found .*/\1/p')
            IP=$(echo "$LINE" | sed -n 's/.* Found \([^ ]*\) .*/\1/p')
            IP="${IP%,}"
        ;;
        *" NOTICE  ["*" Unban "*)
            ACTION="EXTERNAL_UNBAN"
            JAIL=$(echo "$LINE" | sed -n 's/.*\[\([^]]*\)\] Unban .*/\1/p')
            IP=$(echo "$LINE" | sed -n 's/.* Unban \([^ ]*\).*/\1/p')
            IP="${IP%,}"
        ;;
        *)
            continue
        ;;
    esac

    [ -z "$JAIL" ] && continue
    [ -z "$IP" ] && continue

    # Filtro dinámico: solo procesar jails con perfil administrado
    # en jail_profile, en vez de una lista fija en el código.
    PROFILE_EXISTS=$(sqlite3 -cmd ".timeout 3000" "$DB_FILE" "SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL';" 2>/dev/null)
    PROFILE_EXISTS="${PROFILE_EXISTS:-0}"
    if [ "$PROFILE_EXISTS" -eq 0 ]; then
        continue    
    fi

    if [ "$MODE" = "--execute" ]; then
        case "$ACTION" in
            FOUND)
                "$ARE_BIN" found "$IP" "$JAIL"
            ;;
            EXTERNAL_UNBAN)
                "$ARE_BIN" external-unban "$IP" "$JAIL"
            ;;
        esac
    else
        echo "$ACTION detected: IP=$IP JAIL=$JAIL"
    fi
done

if [ "$MODE" = "--execute" ]; then
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
fi
