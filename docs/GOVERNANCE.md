# ARE Governance

## Objetivo

Este documento define las reglas básicas de gobierno, mantenimiento y evolución del proyecto **ARE (Abuse Reputation Engine)**.

ARE es un proyecto de ciberseguridad orientado a reputación, análisis de eventos y aplicación automática de decisiones defensivas.

---

## Principios del Proyecto

* La estabilidad tiene prioridad sobre la complejidad.
* Todo cambio debe ser pequeño, claro y verificable.
* La arquitectura debe mantenerse modular.
* Cada módulo debe tener una responsabilidad única.
* No se deben incorporar funcionalidades sin análisis previo.
* Toda decisión importante debe documentarse.
* El proyecto evoluciona un paso a la vez.

---

## Flujo de Desarrollo

Todo cambio debe seguir este ciclo:

1. Analizar el problema.
2. Diseñar la solución.
3. Documentar en `TODO.md` o RFC.
4. Implementar el cambio.
5. Probar el comportamiento.
6. Actualizar documentación si corresponde.
7. Registrar en `CHANGELOG.md`.
8. Sincronizar con Git.

---

## Versionado

ARE utiliza versionado semántico:

* `v1.0.x` — correcciones y estabilización.
* `v1.1.x` — mejoras compatibles.
* `v2.x` — cambios mayores de arquitectura.

Las versiones publicadas deben mantenerse estables.
Los cambios experimentales deben realizarse en ramas de desarrollo.

---

## RFC

Las propuestas importantes deben registrarse como RFC antes de implementarse.

Un RFC puede estar en uno de estos estados:

* Draft
* Accepted
* Rejected
* Implemented

Ejemplos:

* RFC-001: Renombrar CLI oficial a `are`
* RFC-002: Backend Manager
* RFC-003: Reputation Decay Engine
* RFC-004: Captura de eventos `Found` desde Fail2Ban

---

## Bugs y Tareas

Los bugs deben registrarse con identificadores únicos:

* BUG-001
* BUG-002
* BUG-003

Las tareas técnicas deben registrarse como:

* TASK-001
* TASK-002

Las nuevas funcionalidades deben registrarse como:

* FEAT-001
* FEAT-002

---

## Criterios de Aceptación

Un cambio no se considera terminado hasta que:

* cumple el objetivo definido;
* no rompe funcionalidades existentes;
* fue probado;
* fue documentado;
* fue registrado en Git.

---

## Filosofía

ARE debe mantenerse simple, modular y operativo.

El objetivo no es agregar complejidad, sino mejorar la capacidad del sistema para observar, analizar, decidir y aplicar respuestas de seguridad.

**Primero estable. Después potente.**

