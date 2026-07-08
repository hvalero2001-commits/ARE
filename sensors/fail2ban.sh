#!/bin/bash

LOG_FILE="/var/log/fail2ban.log"
ARE_BIN="/opt/f2b-ipset/f2b-ipset.sh"
OFFSET_FILE="/var/lib/f2b-ipset/fail2ban.offset"

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
        ;;

        *" NOTICE  ["*" Unban "*)
            ACTION="EXTERNAL_UNBAN"
            JAIL=$(echo "$LINE" | sed -n 's/.*\[\([^]]*\)\] Unban .*/\1/p')
            IP=$(echo "$LINE" | sed -n 's/.* Unban \([^ ]*\).*/\1/p')
        ;;

        *)
            continue
        ;;
    esac

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
