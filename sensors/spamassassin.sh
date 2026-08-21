#!/bin/bash
#############################################################
# Module : Sensor - SpamAssassin (polling-based)
#
# Responsibility
#   Leer el log del MTA de forma incremental (offset persistente)
#   y reportar a ARE (categoria SOCIAL) los mensajes marcados como
#   spam, clasificados en tres jails virtuales por banda de score
#   (spamassassin-low / spamassassin-med / spamassassin-high), cada
#   uno con su propio jail_profile administrado en ARE ADMIN.
#
#   La extraccion de IP+score esta aislada por adaptador de MTA
#   (extract_spam_event_<mta>). Unico adaptador implementado y
#   validado hasta el momento: exim. Sumar otro MTA es agregar una
#   funcion nueva, sin tocar el resto del sensor.
#
# Dependencies
#   - config/config.conf (ARE_DATA, ARE_BIN, DB_FILE, SPAMASSASSIN_*)
#   - sqlite3 (consulta directa a jail_profile, mismo criterio que
#     sensors/fail2ban.sh — sensor liviano, sin cargar bootstrap.sh)
#
# Exports
#   (no exporta funciones; script de ejecucion directa via
#   systemd timer)
#############################################################
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$BASE/config/config.conf"
POLICY="$BASE/config/policy.conf"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Configuración no encontrada: $CONFIG"
    exit 1
fi
source "$CONFIG"

if [ ! -f "$POLICY" ]; then
    echo "ERROR: Política no encontrada: $POLICY"
    exit 1
fi
source "$POLICY"

# --- Infraestructura (config.conf) ---
SPAMASSASSIN_MTA="${SPAMASSASSIN_MTA:-exim}"
LOG_FILE="${SPAMASSASSIN_LOG_FILE:-/var/log/exim_mainlog}"
OFFSET_FILE="$ARE_DATA/spamassassin.offset"

# --- Calibración de decisión (policy.conf) ---
# Umbral minimo para considerar el evento (default: required_score
# estandar de SpamAssassin). Por debajo de esto no se reporta nada.
SPAMASSASSIN_MIN_SCORE="${SPAMASSASSIN_MIN_SCORE:-5.0}"

# Limites de banda — mismo tipo de valor que un *_THRESHOLD de
# categoria, a calibrar con trafico real (ver ANOMALY_THRESHOLD /
# DOS_THRESHOLD como precedente).
SPAMASSASSIN_BAND_MED_FROM="${SPAMASSASSIN_BAND_MED_FROM:-10.0}"
SPAMASSASSIN_BAND_HIGH_FROM="${SPAMASSASSIN_BAND_HIGH_FROM:-15.0}"

MODE="${1:---dry-run}"

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log no encontrado: $LOG_FILE"
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

# ------------------------------------------------------------------
# Adaptadores de MTA
#
# Cada adaptador recibe una linea de log y, si corresponde, imprime
# "IP|SCORE". Si la linea no matchea, no imprime nada.
# ------------------------------------------------------------------

extract_spam_event_exim() {
    local line="$1"

    # Formato real observado en produccion:
    #   ... H=(host) [IP]:port ... Warning: "SpamAssassin as X detected message as spam (SCORE)"
    #
    # El filtro por "as spam (" (no solo "spam (") excluye las lineas
    # "detected message as NOT spam (...)" sin negacion explicita: el
    # substring "as spam (" no aparece dentro de "as NOT spam (".
    case "$line" in
        *"detected message as spam ("*)
            local ip score
            ip=$(echo "$line" | grep -oP '\[\K[0-9a-fA-F:.]+(?=\]:)' | head -1)
            score=$(echo "$line" | grep -oP 'detected message as spam \(\K[0-9.\-]+(?=\))')
            if [ -n "$ip" ] && [ -n "$score" ]; then
                echo "${ip}|${score}"
            fi
        ;;
    esac
}

extract_spam_event() {
    case "$SPAMASSASSIN_MTA" in
        exim)
            extract_spam_event_exim "$1"
        ;;
        *)
            : # adaptador no implementado — la linea se descarta sin error
        ;;
    esac
}

score_to_jail() {
    local score="$1"
    awk -v s="$score" -v med="$SPAMASSASSIN_BAND_MED_FROM" -v high="$SPAMASSASSIN_BAND_HIGH_FROM" '
        BEGIN {
            if (s >= high)      print "spamassassin-high";
            else if (s >= med)  print "spamassassin-med";
            else                print "spamassassin-low";
        }
    '
}

sed -n "${START_LINE},${TOTAL_LINES}p" "$LOG_FILE" | while read -r LINE
do
    RESULT=$(extract_spam_event "$LINE")
    [ -z "$RESULT" ] && continue

    IP="${RESULT%%|*}"
    SCORE="${RESULT##*|}"

    # Comparacion float via awk (bash no soporta floats nativamente,
    # mismo cuidado que BUG-021 con PROFILE_EXISTS).
    BELOW_MIN=$(awk -v s="$SCORE" -v min="$SPAMASSASSIN_MIN_SCORE" 'BEGIN{print (s < min) ? 1 : 0}')
    [ "$BELOW_MIN" -eq 1 ] && continue

    JAIL=$(score_to_jail "$SCORE")

    # Filtro dinámico: solo reportar si el jail virtual tiene perfil
    # administrado en jail_profile — mismo criterio que TASK-016.
    PROFILE_EXISTS=$(sqlite3 -cmd ".timeout 3000" "$DB_FILE" "SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL';" 2>/dev/null)
    PROFILE_EXISTS="${PROFILE_EXISTS:-0}"
    if [ "$PROFILE_EXISTS" -eq 0 ]; then
        continue
    fi

    if [ "$MODE" = "--execute" ]; then
        "$ARE_BIN" found "$IP" "$JAIL"
    else
        echo "FOUND detected: IP=$IP JAIL=$JAIL SCORE=$SCORE"
    fi
done

if [ "$MODE" = "--execute" ]; then
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
fi
