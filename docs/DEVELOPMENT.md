# ARE Development Guide

## Introducción

Este documento describe la metodología oficial de desarrollo de ARE (Abuse Reputation Engine).

El objetivo es mantener un proceso consistente, modular y fácilmente mantenible durante toda la evolución del proyecto.

---

# Filosofía

Antes de escribir código se debe comprender el problema.

Las nuevas funcionalidades deberán diseñarse antes de implementarse.

La documentación forma parte del desarrollo y deberá mantenerse sincronizada con el código.

---

# Flujo de desarrollo

Todo cambio importante seguirá el siguiente proceso:

```
Idea
   ↓

RFC (si modifica arquitectura)
   ↓

Diseño
(DESIGN.md)
   ↓

Implementación
   ↓

Pruebas
   ↓

Corrección de bugs
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

Antes de comenzar una nueva funcionalidad deberá verificarse que la anterior se encuentre correctamente validada.

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

---

# Gestión de cambios

Las nuevas funcionalidades podrán originarse mediante:

- Ideas
- RFC
- Bugs
- Tasks
- Features

Cada elemento deberá mantenerse actualizado durante su ciclo de vida.

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

El objetivo principal es mantener un núcleo estable sobre el cual continuar evolucionando.
