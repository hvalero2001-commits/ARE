ARE TODO

BUGS

[ ] BUG-001
Implementar handle_unban()

[ ] BUG-002
Verificar eliminación correcta en backend IPSet.

----------------------------

MEJORAS

[ ] Dashboard más completo.

[ ] Reputation Decay Engine.

[ ] Backend Manager.

----------------------------

IDEAS

[ ] Evaluar captura de eventos "Found" de Fail2Ban.

[ ] Exportación de métricas.

[ ] API REST.

# TODO

## Versión 1.0.1

### BUG-001

**Título:** Implementar `handle_unban()`

**Estado:** Pendiente

**Prioridad:** Alta

**Descripción:**
Actualmente ARE procesa correctamente los eventos de ban, pero la acción `unban` invoca una función inexistente (`handle_unban`), impidiendo completar el ciclo de vida de una IP.

**Impacto:**

* El backend no elimina la IP.
* No se registra el evento UNBAN.
* El flujo Ban → Unban queda incompleto.

---

### BUG-002

**Título:** Revisar sincronización Backend ↔ Fail2Ban

**Estado:** Observación

**Prioridad:** Media

**Descripción:**
Validar durante la operación en producción que todas las acciones generadas por Fail2Ban sean procesadas correctamente por ARE.

---

## Observaciones

Las nuevas funcionalidades no se incorporarán en esta rama.

La versión 1.0.1 estará destinada exclusivamente a estabilización y corrección de errores detectados en producción.

---

### TASK-001
**Título:** Mover reglas del Policy Engine a `policy/rules/`

**Estado:** ✔ Resuelto

**Versión:** v1.0.1

**Descripción:**
Se reorganizaron las reglas de política desde `policy_rules/` hacia `policy/rules/` para mantenerlas dentro del módulo Policy Engine.

**Validación:**
- `score` probado correctamente.
- `ban recidive` probado correctamente.

---


