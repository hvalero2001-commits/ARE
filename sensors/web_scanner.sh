#!/bin/bash
#############################################################
# Module : Sensor - Web Scanner (polling-based)
#
# Responsibility
#   Detectar reconocimiento (RECON) sobre un servidor web: una IP
#   que solicita rutas que ningún visitante legítimo pide
#   (.env, .git, .ssh, credenciales, respaldos, phpinfo, etc.)
#   en busca de archivos expuestos. A diferencia de
#   web_correlation.sh (muchas IPs, una misma ruta), este sensor
#   evalúa UNA IP contra su propio comportamiento en la corrida.
#
#   Lee un access_log en formato combined (nginx o Apache):
#   $1=IP, $4=[fecha:hora, $7=URL. En nginx detrás de un proxy o
#   túnel, $1 solo es la IP real si nginx usa real_ip
#   (set_real_ip_from / real_ip_header). Las IPs locales y
#   privadas se descartan SIEMPRE, para no reportar al propio
#   proxy como si fuera el atacante.
#
#   WEB_SCANNER_LOG_FILE admite varias rutas y/o globs separados por
#   espacios (ej. "/usr/local/apache/domlogs/*-ssl_log" en cPanel,
#   un log por dominio). Cada archivo tiene su propio offset; el
#   conteo de rutas sensibles distintas se hace sobre la corrida
#   completa, de modo que una IP que sondea varios dominios acumula
#   en conjunto.
#
#   Origen: escáner real capturado en nginx (unas 140 peticiones
#   en 2 minutos a .env, .git, .ssh, backups, phpinfo; todas 404).
#
# Dependencies
#   - config/config.conf (ARE_DATA, ARE_BIN, DB_FILE,
#     WEB_SCANNER_*)
#   - sqlite3 (consulta directa a jail_profile)
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
LOG_SPEC="${WEB_SCANNER_LOG_FILE:?WEB_SCANNER_LOG_FILE no configurado}"
OFFSET_FILE="$ARE_DATA/web_scanner.offset"       # offset heredado (un solo log)
OFFSET_DIR="$ARE_DATA/web_scanner.offsets"        # un offset por archivo
LOCK_FILE="$ARE_DATA/web_scanner.lock"
REPORT_LOG="${WEB_SCANNER_REPORT_LOG:-/var/log/are/web_scanner.log}"
JAIL_NAME="${WEB_SCANNER_JAIL:-web-scanner}"

# --- Calibración de decisión (config.conf) ---
# Cantidad de rutas sensibles DISTINTAS que una IP debe pedir en
# una misma corrida para ser reportada.
HIT_THRESHOLD="${WEB_SCANNER_HIT_THRESHOLD:-5}"

# Rutas sensibles (ERE, sin distinguir mayúsculas). Deben ser
# rutas que un visitante legítimo no solicita.
DEFAULT_PATTERN='(^|/)\.(env|git|svn|hg|aws|ssh|docker|dockerenv|npmrc|yarnrc|htpasswd|htaccess|pgpass|netrc|s3cfg|boto|idea|vscode|gitconfig|git-credentials|bash_history|my\.cnf)(/|$|\.|\?)|php-?info|(^|/)info\.php|docker-compose\.ya?ml|\.env(\.[a-z]+)?(\?|$)|(^|/)aws[_.]|(^|/)(wp-config|xmlrpc)|(^|/)(config|settings|database|credentials|secrets|application|appsettings[^/]*|firebase-config|firebase|web)\.(php|py|js|json|ya?ml|properties|config)|(^|/)actuator/|(^|/)_profiler|(^|/)phpmyadmin|\.(sql|bak|old|orig|zip|tar|tar\.gz|tgz|7z|rar)(\?|$)|(^|/)(error|debug|laravel|app)([_.])?log'
PROBE_PATTERN="${WEB_SCANNER_PATTERN:-$DEFAULT_PATTERN}"

MODE="${1:---dry-run}"

# Resolver rutas y globs en la lista de logs a leer
LOG_FILES=()
set -f
for spec in $LOG_SPEC; do
    set +f
    for f in $spec; do
        [ -f "$f" ] && LOG_FILES+=("$f")
    done
    set -f
done
set +f

if [ "${#LOG_FILES[@]}" -eq 0 ]; then
    echo "ERROR: Ningún log encontrado para: $LOG_SPEC"
    exit 1
fi

mkdir -p "$ARE_DATA" "$OFFSET_DIR"

# Protección contra corridas solapadas (mismo criterio que
# sensors/web_correlation.sh y sensors/spamassassin.sh, ver BUG-026)
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    echo "Otra instancia del sensor ya está corriendo — se omite esta corrida."
    exit 0
fi

offset_path() {
    # Un archivo de offset por log, nombrado por su ruta
    echo "$OFFSET_DIR/$(echo "$1" | sed 's#/#_#g')"
}

# Offset heredado de versiones con un solo log: se adopta para ese
# archivo la primera vez y se elimina.
if [ -f "$OFFSET_FILE" ] && [ "${#LOG_FILES[@]}" -ge 1 ]; then
    first="${LOG_FILES[0]}"
    [ -f "$(offset_path "$first")" ] || cp "$OFFSET_FILE" "$(offset_path "$first")"
    [ "$MODE" = "--execute" ] && rm -f "$OFFSET_FILE"
fi

# Emite las líneas nuevas de todos los logs y registra el total de
# cada uno para guardarlo al final de la corrida.
declare -A NEW_OFFSET
read_new_lines() {
    local f total last
    for f in "${LOG_FILES[@]}"; do
        total=$(wc -l < "$f")
        last=0
        [ -f "$(offset_path "$f")" ] && last=$(cat "$(offset_path "$f")")
        # Log rotado o truncado: reiniciar desde el principio
        [ "$last" -gt "$total" ] && last=0
        NEW_OFFSET["$f"]=$total
        sed -n "$((last + 1)),${total}p" "$f"
    done
}

save_offsets() {
    [ "$MODE" = "--execute" ] || return 0
    local f
    for f in "${LOG_FILES[@]}"; do
        echo "${NEW_OFFSET[$f]}" > "$(offset_path "$f")"
    done
}

# ------------------------------------------------------------------
# Detección: por cada IP pública, contar las rutas sensibles
# DISTINTAS solicitadas. Se descartan IPs locales/privadas:
# loopback, RFC 1918, link-local y ULA IPv6. Si el log todavía
# registra la IP del proxy, el sensor no reporta nada en vez de
# señalar al propio servidor.
# ------------------------------------------------------------------

# El patrón se pasa por entorno (no con -v): awk -v interpreta las
# barras invertidas y degradaría \. a "cualquier carácter".
STREAM=$(mktemp)
trap 'rm -f "$STREAM"' EXIT
read_new_lines > "$STREAM"

CANDIDATES=$(PROBE_PATTERN="$PROBE_PATTERN" awk -v thr="$HIT_THRESHOLD" '
    BEGIN { pat = ENVIRON["PROBE_PATTERN"] }
    function es_local(ip) {
        return (ip ~ /^127\./ || ip ~ /^10\./ || ip ~ /^192\.168\./ \
             || ip ~ /^172\.(1[6-9]|2[0-9]|3[01])\./ || ip ~ /^169\.254\./ \
             || ip == "::1" || tolower(ip) ~ /^(fe80|fc|fd)/ || ip == "-" || ip == "")
    }
    {
        ip = $1
        url = tolower($7)
        if (es_local(ip)) next
        if (url ~ pat && !((ip SUBSEP url) in seen)) {
            seen[ip, url] = 1
            hits[ip]++
        }
    }
    END {
        for (ip in hits) if (hits[ip] >= thr) print ip "|" hits[ip]
    }
' "$STREAM")

if [ -z "$CANDIDATES" ]; then
    save_offsets
    exit 0
fi

# Filtro dinámico: solo reportar si el jail tiene perfil
# administrado en jail_profile — mismo criterio que TASK-016.
PROFILE_EXISTS=$(sqlite3 -cmd ".timeout 3000" "$DB_FILE" "SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL_NAME';" 2>/dev/null)
PROFILE_EXISTS="${PROFILE_EXISTS:-0}"
if [ "$PROFILE_EXISTS" -eq 0 ]; then
    save_offsets
    exit 0
fi

echo "$CANDIDATES" | sort | while IFS='|' read -r IP HITS
do
    [ -z "$IP" ] && continue
    if [ "$MODE" = "--execute" ]; then
        "$ARE_BIN" found "$IP" "$JAIL_NAME" >> "$REPORT_LOG" 2>&1
    else
        echo "FOUND detected: IP=$IP JAIL=$JAIL_NAME RUTAS_SENSIBLES=$HITS"
    fi
done

save_offsets
