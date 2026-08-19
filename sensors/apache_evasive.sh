#!/bin/bash
#############################################################
# Module : Sensor - Apache mod_evasive (callback-based)
#
# Responsibility
#   Recibir el callback de mod_evasive cuando detecta un flood
#   confirmado, y reportarlo a ARE como categoría DOS. A
#   diferencia del Sensor Fail2Ban (polling por systemd timer),
#   este sensor es invocado directamente por Apache en el
#   instante del bloqueo — patrón "callback", no "polling".
#
# Dependencies
#   - database.sh (vía are.sh ban)
#   - ipset (bloqueo directo, redundante con ARE durante la
#     ventana de transición de RFC-010)
#
# Exports
#   (no exporta funciones; es un script de ejecución directa,
#   invocado por Apache mediante DOSSystemCommand)
#############################################################
[ -z $1 ] && (echo "Usage: $0 <sourceip>"; exit 1)
[ -x /usr/bin/at ] || (echo "Please, install 'at'"; exit 1)
SOURCEIP="$1"
HOSTNAME=$(/bin/hostname -f)
BODYMAIL="/tmp/bodymailddos"
MODEVASIVE_DOSLogDir="/var/log/apache2/mod_evasive/"
FROM="Anti DDOS System <noreply@service4mobile.me>"
TO="support@service4mobile.me"
BANNEDTIME="4 weeks"

{
echo "Massive connections has been detected from this source IP: $SOURCEIP
The system has blocked the IP in the firewall for $BANNEDTIME. If the problem persist you should block that IP permanently.
- Anti DDOS System -"
} > $BODYMAIL

if [[ "$SOURCEIP" =~ : ]]; then
    if ! /sbin/ipset test are-blacklist6 "$SOURCEIP" >/dev/null 2>&1; then
        /sbin/ipset add are-blacklist6 "$SOURCEIP" timeout 2147483
        /opt/are/are.sh ban "$SOURCEIP" mod_evasive >> /var/log/are/mod_evasive_report.log 2>&1
        cat "$BODYMAIL" | /usr/bin/mail -r "$FROM" -s "DDOS Attack Detected (IPv6) - $HOSTNAME" "$TO"
        mv -f "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP" "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered"
        echo "rm -f $MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered" | at now + "$BANNEDTIME" 2>> /var/log/at-error.log
    fi
else
    if ! /sbin/ipset test are-blacklist "$SOURCEIP" >/dev/null 2>&1; then
        /sbin/ipset add are-blacklist "$SOURCEIP" timeout 2147483
        /opt/are/are.sh ban "$SOURCEIP" mod_evasive >> /var/log/are/mod_evasive_report.log 2>&1
        cat $BODYMAIL | /usr/bin/mail -r "$FROM" -s "DDOS Attack Detected - $HOSTNAME" $TO
        mv -f "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP" "$MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered"
        echo "rm -f $MODEVASIVE_DOSLogDir/dos-$SOURCEIP.filtered" | at now + $BANNEDTIME 2>> /var/log/at-error.log
    fi
fi
