#!/bin/bash
#############################################################
# Module : Infrastructure - Restore IPSet on boot
#
# Responsibility
#   Repoblar los ipset de ARE desde sanction_state al arrancar
#   el sistema, preservando el tiempo restante exacto de cada
#   sanción temporal activa (no lo reinicia). ipset no persiste
#   nativamente entre reinicios; esta es la fuente de verdad
#   real (la base de datos), no un snapshot congelado del
#   firewall.
#
# Dependencies
#   - config/config.conf (ARE_DATA, IPSET_MAX_TIMEOUT, BAN_SET4,
#     BAN_SET6)
#   - logger.sh
#   - database.sh (db_exec)
#   - policy/whitelist.sh (is_whitelisted)
#   - infrastructure/ipset.sh (banIP, init_ipsets)
#
# Exports
#   (script de ejecución directa, invocado una sola vez al
#   arrancar, vía systemd oneshot — no se invoca desde are.sh)
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
source "$BASE/logger.sh"
source "$BASE/database.sh"
source "$BASE/policy/whitelist.sh"
source "$BASE/infrastructure/ipset.sh"

init_ipsets

INFO "Restaurando sanciones activas desde la base de datos..."

NOW=$(date +%s)
COUNT=0

ROWS=$(db_exec "
    SELECT
        ip || '|' ||
        CASE WHEN permanent=1 THEN 0 ELSE (ban_until - $NOW) END
    FROM sanction_state
    WHERE permanent=1
       OR (ban_until > $NOW);
")

while IFS='|' read -r IP REMAINING; do
    [ -z "$IP" ] && continue

    if is_whitelisted "$IP"; then
        continue
    fi

    if [ "$REMAINING" -gt "$IPSET_MAX_TIMEOUT" ]; then
        REMAINING="$IPSET_MAX_TIMEOUT"
    fi

    if [[ "$IP" =~ : ]]; then
        SET="$BAN_SET6"
    else
        SET="$BAN_SET4"
    fi

    banIP "$SET" "$IP" "$REMAINING"
    COUNT=$((COUNT + 1))
done <<< "$ROWS"

INFO "Restauración completada. IPs restauradas=$COUNT"
