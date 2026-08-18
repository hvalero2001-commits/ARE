#!/usr/bin/env bash
# ============================================================
# admin.sh
# ------------------------------------------------------------
# Atajo directo a ARE ADMIN, equivalente a `are.sh admin`.
#
# Sigue el mismo patrón de carga que are.sh: config.conf +
# bootstrap.sh. bootstrap.sh ya se encarga de cargar admin/*.sh
# (ver bloque #ADMIN agregado a bootstrap.sh), por lo que este
# archivo no necesita cargar sus propios módulos.
#
# ARE ADMIN no decide, no aplica y no sanciona. Solo consulta
# y administra configuración a través de los componentes ya
# existentes (ver docs/DESIGN.md, Sección 13).
# ============================================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
CONFIG="$SCRIPT_DIR/config/config.conf"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Configuración no encontrada: $CONFIG"
    exit 1
fi

source "$CONFIG"

BASE="$ARE_HOME"

source "$BASE/bootstrap.sh"

admin_main "$@"
