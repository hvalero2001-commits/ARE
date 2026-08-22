#!/bin/bash
#############################################################
# Module : install.sh (bootstrap de instalación remota)
#
# Responsibility
#   Descargar el paquete de la release más reciente de ARE
#   (o una versión específica via ARE_VERSION), verificar su
#   checksum, extraerlo, y delegar en are-installer — sin
#   requerir git ni clonar el repositorio.
#
#   Reemplaza el flujo manual "git clone + are-installer install"
#   por un único comando (IDEA-007, Fase 2).
#
# Usage
#   curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- upgrade
#   ARE_VERSION=v2.1.0 curl -fsSL .../install.sh | bash
#
# Dependencies
#   - curl, tar, sha256sum
#   - root (delegado, are-installer lo exige también)
#############################################################
set -euo pipefail

REPO="hvalero2001-commits/ARE"
ACTION="${1:-install}"
VERSION="${ARE_VERSION:-latest}"

log() {
    printf '[BOOTSTRAP] %s\n' "$*"
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || error "Este script requiere privilegios de root."

for dependency in curl tar sha256sum; do
    command -v "$dependency" >/dev/null 2>&1 || error "Dependencia no encontrada: $dependency"
done

if [ "$VERSION" = "latest" ]; then
    API_URL="https://api.github.com/repos/${REPO}/releases/latest"
else
    API_URL="https://api.github.com/repos/${REPO}/releases/tags/${VERSION}"
fi

log "Consultando release: $VERSION"

RELEASE_JSON="$(curl -fsSL "$API_URL")" || error "No se pudo consultar la release ($API_URL)"

TAG="$(echo "$RELEASE_JSON" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
[ -n "$TAG" ] || error "No se pudo determinar el tag de la release."

PACKAGE_NAME="are-${TAG}.tar.gz"
DOWNLOAD_BASE="https://github.com/${REPO}/releases/download/${TAG}"

log "Release encontrada: $TAG"
log "Paquete: $PACKAGE_NAME"

WORK_DIR="$(mktemp -d /root/.are-install.XXXXXX)"
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

cd "$WORK_DIR"

log "Descargando paquete..."
curl -fsSL -o "$PACKAGE_NAME" "${DOWNLOAD_BASE}/${PACKAGE_NAME}" \
    || error "No se pudo descargar el paquete."

log "Descargando checksum..."
curl -fsSL -o "${PACKAGE_NAME}.sha256" "${DOWNLOAD_BASE}/${PACKAGE_NAME}.sha256" \
    || error "No se pudo descargar el checksum."

log "Verificando integridad..."
sha256sum -c "${PACKAGE_NAME}.sha256" || error "Checksum inválido — descarga corrupta o manipulada."

log "Extrayendo..."
tar -xzf "$PACKAGE_NAME"

EXTRACTED_DIR="$(find . -maxdepth 1 -type d -name 'are-v*' | head -1)"
[ -n "$EXTRACTED_DIR" ] || error "No se encontró el directorio extraído esperado."

cd "$EXTRACTED_DIR"

[ -x "./are-installer" ] || error "are-installer no encontrado o sin permiso de ejecución en el paquete."

log "Ejecutando: are-installer $ACTION"
./are-installer "$ACTION"
