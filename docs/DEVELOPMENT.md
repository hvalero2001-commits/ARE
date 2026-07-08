# ARE Development Guide

## Introducción

Este documento describe la metodología oficial de desarrollo de ARE (Abuse Reputation Engine).

El objetivo es mantener un proceso consistente, modular y fácilmente mantenible durante toda la evolución del proyecto.

---

# Filosofía

Antes de escribir código se debe comprender el problema.

Toda modificación deberá responder a una necesidad técnica claramente identificada.

La documentación forma parte del desarrollo y deberá mantenerse sincronizada con el código durante todo el ciclo de vida de una funcionalidad.

ARE prioriza la estabilidad, la trazabilidad y la evolución controlada sobre la incorporación rápida de nuevas funcionalidades.

---

# Flujo de desarrollo

Todo cambio importante seguirá el siguiente proceso:

```
Idea
   ↓

Análisis técnico
   ↓

Clasificación
(BUG / TASK / FEAT / RFC)
   ↓

Documentación inicial
(TODO.md)
   ↓

Diseño
(si aplica)
   ↓

Implementación
   ↓

Pruebas
   ↓

Actualización de documentación
   ↓

Commit
   ↓

Push
```

Este flujo garantiza que el diseño del proyecto evolucione de forma controlada.

---

# Desarrollo incremental

ARE evoluciona mediante pequeñas iteraciones.

Se prioriza:

- estabilidad
- simplicidad
- modularidad

Antes de iniciar una nueva funcionalidad deberá verificarse que la funcionalidad anterior se encuentre completamente finalizada, documentada y validada.

No se desarrollarán funcionalidades en paralelo salvo que exista una dependencia técnica claramente identificada.

---

# Principios de implementación

Cada módulo deberá cumplir una única responsabilidad.

Se evitarán funciones excesivamente largas.

Siempre que sea posible, los cambios deberán realizarse mediante módulos independientes para minimizar el impacto sobre el núcleo del sistema.

---

# Documentación

Toda modificación importante deberá reflejarse en la documentación correspondiente.

| Documento | Contenido |
|-----------|-----------|
| README.md | Introducción al proyecto |
| ARCHITECTURE.md | Arquitectura del sistema |
| DESIGN.md | Decisiones de diseño |
| ROADMAP.md | Evolución prevista |
| CHANGELOG.md | Versiones publicadas |
| TODO.md | Trabajo pendiente |
| SECURITY.md | Política de seguridad |
| CONTRIBUTING.md | Guía para colaboradores |
| DEVELOPMENT.md | Metodología de desarrollo |

La documentación deberá actualizarse antes de cerrar una funcionalidad.

Cada documento posee una responsabilidad única.

La información no deberá duplicarse entre documentos.

Cuando una modificación afecte varias áreas del proyecto deberán actualizarse todos los documentos correspondientes antes de cerrar la tarea.

---

# Gestión de cambios

Las nuevas funcionalidades podrán originarse mediante:

- Ideas
- RFC
- Bugs
- Tasks
- Features

Clasificación:

BUG
Corrección de un comportamiento incorrecto.

TASK
Trabajo técnico o refactorización sin incorporar nuevas capacidades.

FEATURE
Nueva funcionalidad visible para el usuario.

RFC
Propuesta que modifica o puede modificar la arquitectura del proyecto.

IDEA
Propuesta aún no planificada para una versión específica.

---

# Commits

Los commits deberán ser pequeños, autocontenidos y representar un único cambio lógico.

Ejemplos:

```
BUG-005 - Fix duplicated backend initialization

TASK-001 - Move policy rules into policy module

FEAT-001 - Implement Fail2Ban Sensor

DOC-001 - Normalize project documentation
```

Cada commit deberá representar una única responsabilidad.

No deberán mezclarse correcciones, nuevas funcionalidades y cambios de documentación no relacionados dentro del mismo commit.

---

# Ramas

Se recomienda mantener una estrategia sencilla de ramas.

```
main
```

Versión estable.

```
v1.x-dev
```

Desarrollo de la siguiente versión.

Las ramas de desarrollo deberán mantenerse funcionales en todo momento.

---

# Calidad

Antes de realizar un commit deberán verificarse:

- funcionamiento
- pruebas
- documentación
- consistencia del código
- actualización del CHANGELOG
- actualización del TODO (si corresponde)
- impacto sobre la arquitectura

Ninguna funcionalidad se considerará finalizada hasta que el código, las pruebas y la documentación reflejen el mismo estado del proyecto.
