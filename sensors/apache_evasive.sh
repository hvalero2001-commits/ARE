#!/bin/bash
#############################################################
# Module : Sensor - Apache mod_evasive (callback-based)
#
# Responsibility
#   Recibir el callback de mod_evasive cuando detecta un flood
#   confirmado, y reportarlo a ARE como categoria DOS. A
#   diferencia del Sensor Fail2Ban (polling por systemd timer),
#   este sensor es invocado directamente por Apache en el
#   instante del bloqueo — patron "callback", no "polling".
#
#   RFC-017, Fase 2: si el sensor esta deshabilitado (archivo
#   flag presente en $ARE_DATA), no se aplica ningun bloqueo —
#   ni el directo de mod_evasive (ipset), ni el reporte a ARE —
#   solo se envia un aviso por email de la actividad detectada,
#   sin accion. No se toca la configuracion de Apache/mod_evasive
#   en si (DOSSystemCommand sigue invocando este script siempre);
#   el chequeo vive adentro del sensor, no en el sistema externo.
#
#   Historial: movido desde /usr/local/bin/ddos_system.sh a
#   sensors/apache_evasive.sh en RFC-012, con cambios minimos en
#   ese momento (solo ruta y limpieza de un mecanismo obsoleto).
#   Nunca se habia alineado con la convencion de config.conf que
#   ya usan fail2ban.sh/spamassassin.sh — corregido en este mismo
#   cambio, ya que se estaba modificando el archivo de todos modos.
#
# Dependencies
#   - config/config.conf (ARE_DATA, ARE_BIN)
#   - database.sh (vía are.sh ban, a traves de $ARE_BIN)
#   - ipset (bloqueo directo, redundante con ARE durante la
#     ventana de transicion de RFC-010)
#   - $ARE_DATA/apache_evasive.disabled (archivo flag, escrito
#     por admin/sensors_menu.sh vía ARE ADMIN — chequeo por
#     archivo, no por sqlite3, porque este script puede invocarse
#     con mucha frecuencia durante un flood real; una consulta a
#     la base en cada invocacion seria costosa justo en el peor
#     momento)
#
# Exports
#   (no exporta funciones; es un script de ejecucion directa,
#   invocado por Apache mediante DOSSystemCommand)
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

[ -z $1 ] && (echo "Usage: $0 <sourceip>"; exit 1)
[ -x /usr/bin/at ] || (echo "Please, install 'at'"; exit 1)
SOURCEIP="$1"
HOSTNAME=$(/bin/hostname -f)
BODYMAIL="/tmp/bodymailddos"
MODEVASIVE_DOSLogDir="/var/log/apache2/mod_evasive/"
FROM="Anti DDOS System <noreply@service4mobile.me>"
TO="support@service4mobile.me"
BANNEDTIME="4 weeks"

DISABLED_FLAG="$ARE_DATA/apache_evasive.disabled"

if [ -f "$DISABLED_FLAG" ]; then
    {
    echo "Actividad sospechosa detectada desde este origen: $SOURCEIP
El sensor apache_evasive de ARE está deshabilitado — no se aplicó
ningún bloqueo ni se registró reputación para esta IP. Este email es
solo informativo.
- Anti DDOS System -"
    } > $BODYMAIL
    cat "$BODYMAIL" | /usr/bin/mail -r "$FROM" -s "DDOS Activity Detected (sensor deshabilitado) - $HOSTNAME" "$TO"
    mv -f "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP" "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered" 2>/dev/null
    exit 0
fi

{
echo "Massive connections has been detected from this source IP: $SOURCEIP
The system has blocked the IP in the firewall for $BANNEDTIME. If the problem persist you should block that IP permanently.
- Anti DDOS System -"
} > $BODYMAIL
if [[ "$SOURCEIP" =~ : ]]; then
    if ! /sbin/ipset test are-blacklist6 "$SOURCEIP" >/dev/null 2>&1; then
        /sbin/ipset add are-blacklist6 "$SOURCEIP" timeout 2147483
        "$ARE_BIN" ban "$SOURCEIP" mod_evasive >> /var/log/are/mod_evasive_report.log 2>&1
        cat "$BODYMAIL" | /usr/bin/mail -r "$FROM" -s "DDOS Attack Detected (IPv6) - $HOSTNAME" "$TO"
        mv -f "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP" "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered"
        echo "rm -f $MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered" | at now + "$BANNEDTIME" 2>> /var/log/at-error.log
    fi
else
    if ! /sbin/ipset test are-blacklist "$SOURCEIP" >/dev/null 2>&1; then
        /sbin/ipset add are-blacklist "$SOURCEIP" timeout 2147483
        "$ARE_BIN" ban "$SOURCEIP" mod_evasive >> /var/log/are/mod_evasive_report.log 2>&1
        cat $BODYMAIL | /usr/bin/mail -r "$FROM" -s "DDOS Attack Detected - $HOSTNAME" $TO
        mv -f "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP" "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered"
        echo "rm -f $MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered" | at now + $BANNEDTIME 2>> /var/log/at-error.log
    fi
fi
