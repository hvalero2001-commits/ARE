# Contributing to ARE

## Introducción

Gracias por tu interés en contribuir a ARE (Abuse Reputation Engine).

ARE es un proyecto desarrollado bajo principios de simplicidad, modularidad y evolución controlada.

Toda contribución deberá respetar la arquitectura, la filosofía de diseño y la metodología oficial de desarrollo del proyecto.

Para comprender el funcionamiento interno de ARE se recomienda leer previamente:

- README.md
- ARCHITECTURE.md
- DESIGN.md
- DEVELOPMENT.md

---

# Principios

Toda contribución deberá seguir los siguientes principios:

- Simplicidad.
- Responsabilidad única.
- Modularidad.
- Compatibilidad hacia atrás siempre que sea posible.
- Documentación sincronizada con el código.
- Estabilidad antes que nuevas funcionalidades.

---

# Antes de comenzar

Antes de escribir código deberá verificarse:

- Que la funcionalidad no exista.
- Que la idea no haya sido documentada previamente.
- Que corresponda a la versión objetivo del proyecto.
- Que exista una justificación técnica.

Si la propuesta modifica la arquitectura deberá abrirse previamente un RFC.

---

# Clasificación de cambios

Toda contribución deberá clasificarse antes de comenzar su implementación.

## BUG

Corrección de un comportamiento incorrecto.

## TASK

Trabajo técnico, reorganización o refactorización sin incorporar nuevas funcionalidades.

## FEATURE

Nueva funcionalidad para el proyecto.

## RFC

Propuesta que modifica o amplía la arquitectura de ARE.

## IDEA

Propuesta aún no planificada para una versión específica.

---

# Flujo de contribución

Toda contribución seguirá el siguiente proceso:

```
Idea
   ↓

Análisis técnico
   ↓

Clasificación

BUG
TASK
FEATURE
RFC
IDEA

   ↓

Actualización del TODO

   ↓

Diseño (si aplica)

   ↓

Implementación

   ↓

Pruebas

   ↓

Actualización de documentación

   ↓

Commit

   ↓

Pull Request
```

---

# Un cambio, una responsabilidad

Cada contribución deberá resolver una única responsabilidad.

Ejemplos válidos:

- Corregir un bug.
- Incorporar una nueva funcionalidad.
- Mejorar la documentación.
- Refactorizar un módulo.

Se evitará mezclar múltiples cambios no relacionados dentro de una misma contribución.

---

# Documentación

La documentación forma parte del proyecto.

Toda modificación importante deberá reflejarse en los documentos correspondientes antes de considerarse finalizada.

Dependiendo del cambio podrá ser necesario actualizar:

- CHANGELOG.md
- TODO.md
- ARCHITECTURE.md
- DESIGN.md
- DEVELOPMENT.md
- ROADMAP.md
- SECURITY.md

---

# Pruebas

Toda nueva funcionalidad deberá validarse antes de enviarse.

Las pruebas deberán demostrar que:

- El cambio funciona correctamente.
- No introduce regresiones.
- Mantiene la compatibilidad con el resto del sistema.

---

# Commits

Los commits deberán ser pequeños, claros y representar una única responsabilidad.

Ejemplos:

```
BUG-006 - Fix anomaly category

TASK-005 - Extend reputation categories

FEAT-003 - Add top jails dashboard

DOC-002 - Rewrite contributing guide
```

---

# Pull Requests

Antes de enviar un Pull Request deberá verificarse:

- Código funcional.
- Pruebas realizadas.
- Documentación actualizada.
- Consistencia con la arquitectura.
- Cumplimiento de la metodología de desarrollo.

Las revisiones podrán solicitar modificaciones antes de aceptar una contribución.

---

# Filosofía

ARE evoluciona mediante pequeñas mejoras continuas.

Las buenas ideas no implican su implementación inmediata.

Toda propuesta deberá analizarse, documentarse y clasificarse antes de incorporarse al proyecto.

El objetivo principal es preservar un núcleo estable sobre el cual continuar evolucionando de forma ordenada.
