#!/bin/bash
#############################################################
# Module : Sensor - Web Correlation (polling-based)
#
# Responsibility
#   Detectar scraping distribuido de catálogo (e-commerce): una
#   campaña coordinada donde muchas IPs distintas, potencialmente
#   desde infraestructura de datacenter/proxy, navegan rutas de
#   catálogo/carrito (marcadas por WEB_CORRELATION_PATH_MARKER)
#   dentro de la misma ventana de tiempo. Ninguna IP individual
#   cruza un umbral de reincidencia — la señal solo existe al
#   correlacionar entre IPs, algo que Fail2Ban no puede ver por
#   diseño (evalúa una IP contra su propio historial, no contra
#   el de otras).
#
#   Origen: IDEA-010, con evidencia real de campaña de scraping
#   contra catálogo de e-commerce (correlación por minuto,
#   decenas de IPs distintas, infraestructura de datacenter
#   confirmada por ASN vía whois).
#
# Dependencies
#   - config/config.conf (ARE_DATA, ARE_BIN, DB_FILE,
#     WEB_CORRELATION_*)
#   - sqlite3 (consulta directa a jail_profile, mismo criterio
#     que el resto de los sensores livianos)
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

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: este sensor requiere privilegios de root." >&2
    exit 1
fi

# --- Infraestructura (config.conf) ---
LOG_FILE="${WEB_CORRELATION_LOG_FILE:?WEB_CORRELATION_LOG_FILE no configurado}"
OFFSET_FILE="$ARE_DATA/web_correlation.offset"
LOCK_FILE="$ARE_DATA/web_correlation.lock"
JAIL_NAME="${WEB_CORRELATION_JAIL:-web-correlation}"

# --- Calibración de decisión (config.conf) ---
PATH_MARKER="${WEB_CORRELATION_PATH_MARKER:-cart}"
IP_THRESHOLD="${WEB_CORRELATION_IP_THRESHOLD:-10}"
WINDOW_MINUTES="${WEB_CORRELATION_WINDOW_MINUTES:-1}"

MODE="${1:---dry-run}"

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log no encontrado: $LOG_FILE"
    exit 1
fi

mkdir -p "$(dirname "$OFFSET_FILE")"

# Protección contra corridas solapadas (mismo criterio que
# sensors/spamassassin.sh, ver BUG-026)
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    echo "Otra instancia del sensor ya está corriendo — se omite esta corrida."
    exit 0
fi

TOTAL_LINES=$(wc -l < "$LOG_FILE")
LAST_LINE=0
if [ -f "$OFFSET_FILE" ]; then
    LAST_LINE=$(cat "$OFFSET_FILE")
fi
if [ "$LAST_LINE" -gt "$TOTAL_LINES" ]; then
    LAST_LINE=0
fi
START_LINE=$((LAST_LINE + 1))

# ------------------------------------------------------------------
# Correlación: agrupar por (bucket de tiempo, presencia del
# marcador de ruta), contar IPs distintas por grupo. Formato real
# de access_log (Apache combined): $1=IP, $4=[fecha:hora, $5=tz],
# $7=URL. WINDOW_MINUTES=1 trunca a minuto exacto; para ventanas
# mayores habría que dividir los minutos entre WINDOW_MINUTES,
# fuera de alcance de esta primera versión.
# ------------------------------------------------------------------

CANDIDATES=$(sed -n "${START_LINE},${TOTAL_LINES}p" "$LOG_FILE" | awk -v marker="$PATH_MARKER" '
    $7 ~ ("/" marker "/") || $7 ~ ("/" marker "$") {
        split($4, t, ":")
        bucket = t[1] ":" t[2] ":" t[3]
        print bucket "|" $1
    }
')

if [ -z "$CANDIDATES" ]; then
    if [ "$MODE" = "--execute" ]; then
        echo "$TOTAL_LINES" > "$OFFSET_FILE"
    fi
    exit 0
fi

echo "$CANDIDATES" | sort -u | awk -F'|' '{ count[$1]++; ips[$1] = ips[$1] " " $2 } END { for (b in count) print b "|" count[b] "|" ips[b] }' | \
while IFS='|' read -r bucket count ip_list
do
    if [ "$count" -lt "$IP_THRESHOLD" ]; then
        continue
    fi

    # Filtro dinámico: solo reportar si el jail tiene perfil
    # administrado en jail_profile — mismo criterio que TASK-016.
    PROFILE_EXISTS=$(sqlite3 -cmd ".timeout 3000" "$DB_FILE" "SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL_NAME';" 2>/dev/null)
    PROFILE_EXISTS="${PROFILE_EXISTS:-0}"
    if [ "$PROFILE_EXISTS" -eq 0 ]; then
        continue
    fi

    for IP in $ip_list; do
        [ -z "$IP" ] && continue
        if [ "$MODE" = "--execute" ]; then
            "$ARE_BIN" found "$IP" "$JAIL_NAME" >> /var/log/are/web_correlation.log 2>&1
        else
            echo "FOUND detected: IP=$IP JAIL=$JAIL_NAME BUCKET=$bucket IPS_EN_GRUPO=$count"
        fi
    done
done

if [ "$MODE" = "--execute" ]; then
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
fi
