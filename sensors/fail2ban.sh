#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$BASE/config/config.conf"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Configuración no encontrada: $CONFIG"
    exit 1
fi

source "$CONFIG"

LOG_FILE="/var/log/fail2ban.log"
OFFSET_FILE="$ARE_DATA/fail2ban.offset"

MODE="${1:---dry-run}"

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

    case "$JAIL" in
        modsec-*|recidive|sshd|telnet)
            ;;
        *)
            continue
            ;;
    esac

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
