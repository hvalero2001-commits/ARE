#!/bin/bash
#############################################################
# Module : scripts/sync_whitelist.sh
#
# Responsibility
#   Sincronizar un bloque de config/whitelist.conf contra una
#   fuente externa de rangos IP publicados (ej. Cloudflare),
#   sin tocar el resto del archivo (entradas manuales del
#   administrador). Genérico — la URL de origen es configurable,
#   no está atada a ningún proveedor específico.
#
#   Origen: necesidad real de mantener actualizados los rangos
#   de un proxy inverso delante del servidor, sin copiar/pegar
#   manualmente cada vez que el proveedor los cambia.
#
# Dependencies
#   - config/config.conf (WHITELIST_SYNC_URL_V4,
#     WHITELIST_SYNC_URL_V6, WHITELIST_SYNC_MARKER)
#   - curl
#
# Exports
#   (script de ejecución directa, sin funciones exportadas)
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
    echo "ERROR: este script requiere privilegios de root." >&2
    exit 1
fi

WHITELIST_FILE="$BASE/config/whitelist.conf"
URL_V4="${WHITELIST_SYNC_URL_V4:-}"
URL_V6="${WHITELIST_SYNC_URL_V6:-}"
MARKER="${WHITELIST_SYNC_MARKER:-CLOUDFLARE}"

if [ -z "$URL_V4" ] && [ -z "$URL_V6" ]; then
    echo "ERROR: WHITELIST_SYNC_URL_V4 / WHITELIST_SYNC_URL_V6 no configuradas en config.conf — sincronización deshabilitada."
    exit 1
fi

if [ ! -f "$WHITELIST_FILE" ]; then
    echo "ERROR: Whitelist no encontrada: $WHITELIST_FILE"
    exit 1
fi

BEGIN_TAG="# BEGIN ${MARKER} AUTO-SYNC (gestionado por scripts/sync_whitelist.sh — no editar a mano)"
END_TAG="# END ${MARKER} AUTO-SYNC"

TMP_BLOCK=$(mktemp)
trap 'rm -f "$TMP_BLOCK"' EXIT

FETCH_OK=1

if [ -n "$URL_V4" ]; then
    RANGES_V4=$(curl -fsSL --max-time 15 "$URL_V4" 2>/dev/null)
    if [ -z "$RANGES_V4" ] || ! echo "$RANGES_V4" | head -1 | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$'; then
        echo "ERROR: Descarga de IPv4 falló o no tiene formato CIDR válido: $URL_V4"
        FETCH_OK=0
    fi
fi

if [ -n "$URL_V6" ]; then
    RANGES_V6=$(curl -fsSL --max-time 15 "$URL_V6" 2>/dev/null)
    if [ -z "$RANGES_V6" ] || ! echo "$RANGES_V6" | head -1 | grep -qE '^[0-9a-fA-F:]+/[0-9]{1,3}$'; then
        echo "ERROR: Descarga de IPv6 falló o no tiene formato CIDR válido: $URL_V6"
        FETCH_OK=0
    fi
fi

if [ "$FETCH_OK" -eq 0 ]; then
    echo "Sincronización abortada — la whitelist actual no fue modificada."
    exit 1
fi

{
    echo "$BEGIN_TAG"
    [ -n "$URL_V4" ] && echo "$RANGES_V4"
    [ -n "$URL_V6" ] && echo "$RANGES_V6"
    echo "$END_TAG"
} > "$TMP_BLOCK"

if grep -qF "$BEGIN_TAG" "$WHITELIST_FILE"; then
    # Bloque ya existe: reemplazarlo, preservando todo lo demás.
    awk -v begin="$BEGIN_TAG" -v end="$END_TAG" -v block="$TMP_BLOCK" '
        $0 == begin { inside=1; while ((getline line < block) > 0) print line; close(block); next }
        $0 == end { inside=0; next }
        inside { next }
        { print }
    ' "$WHITELIST_FILE" > "${WHITELIST_FILE}.new"
else
    # Primera sincronización: agregar el bloque al final.
    cat "$WHITELIST_FILE" "$TMP_BLOCK" > "${WHITELIST_FILE}.new"
fi

mv "${WHITELIST_FILE}.new" "$WHITELIST_FILE"

COUNT=$(grep -cE '^[0-9a-fA-F:.]+/[0-9]{1,3}$' "$TMP_BLOCK")
echo "Sincronización completada: $COUNT rangos ($MARKER) actualizados en $WHITELIST_FILE"
