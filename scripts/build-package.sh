#!/bin/bash
#############################################################
# Module : build-package.sh (empaquetado manual)
#
# Responsibility
#   Generar un .tar.gz distribuible de ARE a partir del árbol
#   fuente, respetando PRODUCT_EXCLUDED del manifiesto y
#   sincronizando el archivo VERSION desde PRODUCT_VERSION en
#   vez de depender de edición manual.
#
#   Primera version: ejecución manual, para validar el
#   contenido del paquete antes de automatizar via GitHub
#   Actions (IDEA-007, fase 2).
#
# Dependencies
#   - manifest/product.sh (PRODUCT_VERSION, PRODUCT_EXCLUDED)
#   - rsync, tar, sha256sum
#
# Usage
#   ./scripts/build-package.sh
#   (genera are-v<VERSION>.tar.gz y su .sha256 en el directorio
#   actual)
#############################################################
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MANIFEST="$SOURCE_DIR/manifest/product.sh"

if [ ! -f "$MANIFEST" ]; then
    echo "[ERROR] Manifiesto no encontrado: $MANIFEST" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$MANIFEST"

if [ -z "${PRODUCT_VERSION:-}" ]; then
    echo "[ERROR] PRODUCT_VERSION no está definido en el manifiesto." >&2
    exit 1
fi

VERSION="$PRODUCT_VERSION"
PACKAGE_NAME="are-v${VERSION}"
BUILD_ROOT="$(mktemp -d)"
BUILD_DIR="${BUILD_ROOT}/${PACKAGE_NAME}"
OUTPUT_DIR="$SOURCE_DIR"
OUTPUT="${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz"

cleanup() {
    rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

echo "[BUILD] Version: $VERSION"
echo "[BUILD] Origen : $SOURCE_DIR"
echo "[BUILD] Destino temporal: $BUILD_DIR"

mkdir -p "$BUILD_DIR"

# Construir argumentos --exclude a partir de PRODUCT_EXCLUDED,
# mismo array que ya usa el Installer Engine — sin duplicar la
# lista en un segundo lugar.
EXCLUDE_ARGS=()
for item in "${PRODUCT_EXCLUDED[@]}"; do
    EXCLUDE_ARGS+=("--exclude=$item")
done

echo "[BUILD] Copiando árbol fuente (excluyendo: ${PRODUCT_EXCLUDED[*]})"

rsync -a "${EXCLUDE_ARGS[@]}" "$SOURCE_DIR/" "$BUILD_DIR/"

# VERSION se genera desde PRODUCT_VERSION, no se edita a mano —
# evita que el archivo suelto vuelva a desincronizarse del
# manifiesto, como pasó antes de esta corrección.
echo "$VERSION" > "$BUILD_DIR/VERSION"
echo "[BUILD] VERSION sincronizado: $VERSION"

echo "[BUILD] Generando tarball..."
tar -czf "$OUTPUT" -C "$BUILD_ROOT" "$PACKAGE_NAME"

echo "[BUILD] Generando checksum..."
(cd "$OUTPUT_DIR" && sha256sum "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256")

echo
echo "[BUILD] Paquete generado: $OUTPUT"
echo "[BUILD] Checksum        : ${OUTPUT}.sha256"
echo "[BUILD] Tamaño          : $(du -h "$OUTPUT" | cut -f1)"
