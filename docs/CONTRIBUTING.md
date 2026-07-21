# Contributing to ARE

## Introducción

Gracias por tu interés en contribuir a ARE (Abuse Reputation Engine).

ARE evoluciona mediante una metodología incremental basada en estabilidad, simplicidad y arquitectura modular.

Toda contribución deberá respetar la arquitectura del proyecto, la filosofía de diseño y el proceso oficial de desarrollo.

Antes de realizar cualquier modificación se recomienda leer:

- README.md
- PROJECT.md
- PHILOSOPHY.md
- ARCHITECTURE.md
- DESIGN.md
- DEVELOPMENT.md

---

# Principios

Toda contribución deberá respetar los siguientes principios.

- Una única responsabilidad por cambio.
- Arquitectura antes que implementación.
- Estabilidad antes que nuevas funcionalidades.
- Bajo acoplamiento.
- Alta cohesión.
- Compatibilidad hacia atrás cuando sea posible.
- Documentación sincronizada con el código.
- Código simple antes que código complejo.

---

# Antes de comenzar

Antes de implementar cualquier cambio deberá verificarse:

- que la funcionalidad no exista;
- que no exista una tarea equivalente documentada;
- que la propuesta corresponda a la versión objetivo;
- que exista una justificación técnica.

Si la modificación afecta la arquitectura deberá documentarse previamente mediante un RFC.

---

# Clasificación de cambios

Toda contribución deberá clasificarse antes de comenzar.

## BUG

Corrección de un comportamiento incorrecto.

---

## TASK

Refactorización, reorganización o mantenimiento sin incorporar nuevas funcionalidades.

---

## FEATURE

Nueva funcionalidad compatible con la arquitectura existente.

---

## RFC

Propuesta que modifica la arquitectura del proyecto.

Toda modificación arquitectónica deberá aprobarse antes de comenzar su implementación.

---

## IDEA

Propuesta sin planificación para una versión específica.

Las ideas no forman parte automáticamente del Roadmap.

---

# Flujo de contribución

Toda contribución seguirá el siguiente proceso.

```text
Idea
 │
 ▼
Análisis técnico
 │
 ▼
Clasificación
 │
 ▼
Documentación
 │
 ▼
Diseño
 │
 ▼
Implementación
 │
 ▼
Pruebas
 │
 ▼
Actualización documental
 │
 ▼
Commit
 │
 ▼
Pull Request
```

Ninguna etapa deberá omitirse.

---

# Una responsabilidad por cambio

Cada cambio deberá resolver un único problema.

Ejemplos válidos:

- corregir un bug;
- implementar una funcionalidad;
- mejorar la documentación;
- reorganizar un módulo;
- optimizar un algoritmo.

Se evitará mezclar responsabilidades diferentes dentro del mismo cambio.

---

# Arquitectura

Toda modificación deberá respetar la separación entre:

- Sensor Framework;
- Reputation Engine;
- State Engine;
- Policy Engine;
- Firewall Backend;
- Installer Engine.

No deberán introducirse dependencias innecesarias entre motores.

---

# Documentación

La documentación forma parte del código fuente.

Toda modificación relevante deberá actualizar la documentación correspondiente.

Según el cambio podrá ser necesario actualizar:

- README.md
- CHANGELOG.md
- ROADMAP.md
- ARCHITECTURE.md
- DESIGN.md
- DEVELOPMENT.md
- SECURITY.md
- INSTALL.md
- USER_GUIDE.md

Una funcionalidad no se considera finalizada hasta que su documentación haya sido actualizada.

---

# Pruebas

Toda modificación deberá validarse antes de integrarse al proyecto.

Las pruebas deberán demostrar:

- funcionamiento correcto;
- ausencia de regresiones;
- compatibilidad con la arquitectura;
- conservación de datos persistentes cuando corresponda.

Las funcionalidades relacionadas con el Installer deberán validar:

- install;
- upgrade;
- repair;
- verify;
- uninstall.

---

# Commits

Los commits deberán representar una única responsabilidad.

Ejemplos:

```text
BUG-006  Fix anomaly category

TASK-008  Refactor installer manifest

FEAT-004  Add Installer Engine

DOC-005  Update installation guide
```

Los mensajes deberán ser claros, específicos y trazables.

---

# Pull Requests

Antes de enviar un Pull Request deberá verificarse:

- código funcional;
- pruebas completadas;
- documentación actualizada;
- cumplimiento de la arquitectura;
- cumplimiento de la metodología oficial.

Las revisiones podrán solicitar cambios antes de aceptar la integración.

---

# Filosofía

ARE evoluciona mediante mejoras pequeñas, verificables y documentadas.

La incorporación de nuevas funcionalidades nunca deberá comprometer la estabilidad del núcleo.

Cada versión deberá representar un estado consistente del proyecto.

La prioridad de ARE es mantener una arquitectura sólida que permita evolucionar el sistema durante múltiples versiones sin introducir deuda técnica.
