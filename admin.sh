#!/usr/bin/env bash
# ============================================================
# admin.sh
# ------------------------------------------------------------
# Entrypoint de ARE ADMIN.
#
# Sigue el mismo patrón que dashboard.sh: resuelve su propia
# ubicación mediante BASH_SOURCE, carga bootstrap.sh y delega
# el control al dispatcher de admin/core.sh.
#
# ARE ADMIN no decide, no aplica y no sanciona. Solo consulta
# y administra configuración a través de los componentes ya
# existentes (ver docs/DESIGN.md, Sección 13).
# ============================================================

set -euo pipefail

ARE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ARE_HOME

# ------------------------------------------------------------
# TODO (integración pendiente):
# Descomentar cuando se integre con el proyecto real.
# El contexto "admin" le indica a bootstrap.sh que debe cargar
# también los módulos de admin/ (ver propuesta de bootstrap.sh
# más abajo en este mismo mensaje).
#
# export ARE_CONTEXT="admin"
# source "${ARE_HOME}/bootstrap.sh"
# ------------------------------------------------------------

# Mientras tanto, para poder probar el esqueleto de forma
# aislada, se cargan directamente los módulos de admin/.
for f in "${ARE_HOME}/admin/"*.sh; do
    # shellcheck source=/dev/null
    source "$f"
done

admin_main "$@"
