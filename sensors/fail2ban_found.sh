#!/bin/bash

LOG_FILE="/var/log/fail2ban.log"
ARE_BIN="/opt/f2b-ipset/f2b-ipset.sh"
OFFSET_FILE="/var/lib/f2b-ipset/fail2ban_found.offset"

MODE="${1:---dry-run}"

mkdir -p "$(dirname "$OFFSET_FILE")"

TOTAL_LINES=$(wc -l < "$LOG_FILE")
LAST_LINE=0

if [ -f "$OFFSET_FILE" ]; then
    LAST_LINE=$(cat "$OFFSET_FILE")
fi

# Si el log rotó o fue truncado, reiniciar cursor
if [ "$LAST_LINE" -gt "$TOTAL_LINES" ]; then
    LAST_LINE=0
fi

START_LINE=$((LAST_LINE + 1))

sed -n "${START_LINE},${TOTAL_LINES}p" "$LOG_FILE" | grep " Found " | while read -r LINE
do
    JAIL=$(echo "$LINE" | sed -n 's/.*\[\([^]]*\)\] Found .*/\1/p')
    IP=$(echo "$LINE" | sed -n 's/.* Found \([^ ]*\) .*/\1/p')

    [ -z "$JAIL" ] && continue
    [ -z "$IP" ] && continue

    case "$JAIL" in
        modsec-*|recidive|sshd)
            ;;
        *)
            continue
            ;;
    esac

    if [ "$MODE" = "--execute" ]; then
        "$ARE_BIN" found "$IP" "$JAIL"
    else
        echo "FOUND detected: IP=$IP JAIL=$JAIL"
    fi
done

if [ "$MODE" = "--execute" ]; then
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
fi
