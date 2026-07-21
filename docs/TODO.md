# ARE TODO

## Introducción

Este documento mantiene el registro oficial del trabajo pendiente de ARE (Abuse Reputation Engine).

El objetivo del TODO no es documentar el historial del proyecto, sino representar el estado actual del desarrollo.

Las tareas resueltas permanecen registradas únicamente como referencia técnica hasta formar parte de una versión estable.

---

# Clasificación

El trabajo del proyecto se organiza mediante cinco categorías.

## BUG

Corrección de un comportamiento incorrecto.

---

## TASK

Mantenimiento, reorganización o mejoras internas.

---

## FEATURE

Nueva funcionalidad compatible con la arquitectura vigente.

---

## RFC

Propuestas que modifican o amplían la arquitectura del proyecto.

---

## IDEA

Propuestas futuras aún sin planificación.

---

# Estado

Cada elemento deberá utilizar uno de los siguientes estados.

- OPEN
- IN PROGRESS
- RESOLVED
- DEFERRED
- CANCELLED

---

# Prioridades

- LOW
- MEDIUM
- HIGH
- CRITICAL

---

# BUGS

## BUG-002

**Título**

Verificar sincronización Backend ↔ Fail2Ban

**Estado**

OPEN

**Prioridad**

MEDIUM

**Objetivo**

Continuar validando en producción que todos los eventos generados por Fail2Ban sean procesados correctamente por ARE.

---

# TASKS

## TASK-002

**Título**

Cursor persistente para sensores

**Estado**

OPEN

**Prioridad**

HIGH

**Objetivo**

Implementar un mecanismo persistente de offset que impida reprocesar eventos previamente leídos.

---

## TASK-004

**Título**

Estadísticas por Jail

**Estado**

OPEN

**Prioridad**

MEDIUM

**Objetivo**

Ampliar el Dashboard para mostrar actividad agrupada por Jail utilizando exclusivamente la tabla `events`.

---

# RFC

## RFC-001

**Título**

CLI oficial `are`

**Estado**

DRAFT

**Objetivo**

Completar la migración desde la identidad histórica `f2b-ipset` hacia la identidad oficial del proyecto.

---

## RFC-003

**Título**

Identity Migration

**Estado**

DRAFT

**Objetivo**

Migrar progresivamente:

- comandos;
- rutas;
- configuración;
- documentación;
- estructura del proyecto.

La compatibilidad con instalaciones existentes deberá mantenerse durante toda la transición.

---

## RFC-004

**Título**

ARE como autoridad principal de decisión

**Estado**

DRAFT

**Objetivo**

Convertir ARE en el único responsable de decidir:

- ALLOW;
- WATCH;
- FILTER;
- TEMP_BAN;
- BAN;
- recuperación.

Fail2Ban deberá actuar únicamente como fuente de eventos.

---

## RFC-005

**Título**

Reputation Decay y recuperación autónoma

**Estado**

DRAFT

**Objetivo**

Completar el ciclo de vida de una dirección IP mediante recuperación progresiva basada en reputación.

---

# IDEAS

## IDEA-001

Exportación de métricas.

---

## IDEA-002

API REST.

---

## IDEA-003

Backend Manager.

---

## IDEA-004

Dashboard avanzado.

---

## IDEA-005

Correlación entre múltiples sensores.

---

## IDEA-006

Motor de perfiles dinámicos.

---

## IDEA-007

Integración con plataformas SIEM.

---

## Política

Este documento únicamente contiene trabajo pendiente.

Las funcionalidades implementadas pertenecen a:

- CHANGELOG.md
- ROADMAP.md
- documentación técnica correspondiente.

Una vez publicada una versión estable, las tareas resueltas deberán eliminarse del TODO y permanecer únicamente como parte del historial del proyecto.

El TODO representa siempre el estado actual del desarrollo.
