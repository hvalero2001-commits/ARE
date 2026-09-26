#!/bin/bash
#############################################################
# Module : Sensor - Mail Antivirus (polling-based)
#
# Responsibility
#   Leer de forma incremental /var/log/exim_mainlog y
#   reportar a ARE las IPs cuyo mensaje entrante fue
#   rechazado por el motor antivirus configurado en Exim
#   (av_scanner ACL: ClamAV, Sophos, u otro backend
#   soportado por Exim - el mensaje de rechazo es generico
#   de Exim, no especifico de un motor).
#
#   Solo aplica a correo entrante real vía SMTP (P=SMTP en
#   el mainlog). Un mensaje generado localmente (P=local,
#   via `mail`/`sendmail` en el propio servidor) no pasa por
#   esta ACL y no debe reportarse - evidencia real: pruebas
#   de laboratorio confirmaron que send-mail local NO activa
#   el escaneo, mientras que una conexion SMTP externa
#   genuina si lo hace (ver evidencia EICAR via swaks, sesion
#   de diseño de este sensor).
#
#   Evento detectado (evidencia real, exim_mainlog):
#     ... rejected after DATA: This message contains a virus
#     or other harmful content (Eicar-Test-Signature)
#   con la IP de origen en el mismo bloque de conexion:
#     H=<rdns> (<helo>) [<IP>]:<port>
#
# Dependencies
#   - config/config.conf (ARE_DATA, ARE_BIN, DB_FILE,
#     MAIL_ANTIVIRUS_LOG_FILE)
#   - sqlite3 (consulta directa a jail_profile, mismo criterio
#     que sensors/fail2ban.sh / sensors/syslog.sh)
#   - /var/log/exim_mainlog (o el path configurado)
#
# Exports
#   (no exporta funciones; script de ejecucion directa via
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

LOG_FILE="${MAIL_ANTIVIRUS_LOG_FILE:-/var/log/exim_mainlog}"
JAIL_NAME="${MAIL_ANTIVIRUS_JAIL:-mail-antivirus}"
OFFSET_FILE="$ARE_DATA/mail_antivirus.offset"

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

# Filtro dinámico: solo procesar si el jail tiene perfil
# administrado en jail_profile, mismo criterio que el resto
# de los sensores livianos.
PROFILE_EXISTS=$(sqlite3 -cmd ".timeout 3000" "$DB_FILE" "SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL_NAME';" 2>/dev/null)
PROFILE_EXISTS="${PROFILE_EXISTS:-0}"
if [ "$PROFILE_EXISTS" -eq 0 ]; then
    echo "ERROR: No existe perfil jail_profile para '$JAIL_NAME'"
    exit 1
fi

sed -n "${START_LINE},${TOTAL_LINES}p" "$LOG_FILE" | while read -r LINE
do
    # Solo lineas de rechazo por virus (mensaje generico de
    # la ACL av_scanner de Exim, cualquier motor backend).
    echo "$LINE" | grep -qi "rejected after DATA:.*\(virus\|harmful content\)" || continue

    # IP de origen: formato "H=<rdns> (<helo>) [<IP>]:<port>"
    IP=$(echo "$LINE" | sed -n 's/.*\[\([0-9a-fA-F:.]*\)\]:[0-9]*.*/\1/p')

    [ -z "$IP" ] && continue

    if [ "$MODE" = "--execute" ]; then
        "$ARE_BIN" found "$IP" "$JAIL_NAME"
    else
        echo "FOUND detected: IP=$IP JAIL=$JAIL_NAME"
    fi
done

if [ "$MODE" = "--execute" ]; then
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
fi
