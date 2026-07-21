# ARE Development Guide

## Introducción

Este documento define la metodología oficial de desarrollo de ARE (Abuse Reputation Engine).

Su objetivo es garantizar una evolución controlada del proyecto mediante una arquitectura estable, documentación sincronizada y cambios pequeños, verificables y trazables.

Toda funcionalidad deberá seguir el proceso definido en este documento antes de incorporarse a una versión estable.

---

# Filosofía

El desarrollo de ARE se basa en un principio fundamental:

> **Comprender antes de implementar.**

Antes de escribir código deberá comprenderse completamente el problema, analizar su impacto sobre la arquitectura y definir claramente la responsabilidad del cambio.

La documentación forma parte del desarrollo y evoluciona junto con el código.

---

# Objetivos

La metodología busca garantizar:

- estabilidad del núcleo;
- evolución incremental;
- arquitectura consistente;
- bajo acoplamiento;
- alta cohesión;
- documentación sincronizada;
- ausencia de deuda técnica innecesaria.

---

# Flujo de desarrollo

Toda funcionalidad seguirá el siguiente proceso.

```text
Idea
 │
 ▼
Análisis técnico
 │
 ▼
Clasificación
(BUG / TASK / FEATURE / RFC / IDEA)
 │
 ▼
Actualización del TODO
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
Merge
```

Ninguna etapa deberá omitirse.

---

# Desarrollo incremental

ARE evoluciona mediante iteraciones pequeñas.

Antes de comenzar una nueva funcionalidad deberá verificarse que la anterior se encuentre:

- implementada;
- validada;
- documentada;
- integrada.

No deberán desarrollarse funcionalidades paralelas que generen dependencias innecesarias.

---

# Clasificación de cambios

## BUG

Corrección de un comportamiento incorrecto.

No incorpora nuevas funcionalidades.

---

## TASK

Refactorización, reorganización o mantenimiento técnico.

No modifica el comportamiento funcional del sistema.

---

## FEATURE

Nueva funcionalidad compatible con la arquitectura existente.

---

## RFC

Propuesta que modifica la arquitectura del proyecto.

Toda modificación arquitectónica requiere aprobación previa.

---

## IDEA

Propuesta aún no planificada para una versión específica.

Las ideas no forman parte automáticamente del Roadmap.

---

# Principios de implementación

Toda implementación deberá respetar los siguientes principios.

## Responsabilidad única

Cada módulo deberá implementar una única responsabilidad.

---

## Reutilización

Siempre que sea posible se reutilizarán componentes existentes.

No deberá duplicarse lógica.

---

## Modularidad

Las nuevas funcionalidades deberán integrarse mediante módulos independientes.

---

## Simplicidad

Se priorizarán soluciones simples antes que implementaciones complejas.

---

## Compatibilidad

Toda modificación deberá preservar la compatibilidad con la arquitectura existente salvo que corresponda a una nueva versión mayor.

---

# Arquitectura

Toda implementación deberá respetar la separación entre:

- Sensor Framework;
- Reputation Engine;
- State Engine;
- Policy Engine;
- Firewall Backend;
- Installer Engine.

No deberán introducirse dependencias circulares entre motores.

---

# Documentación

La documentación forma parte del proceso de desarrollo.

Toda modificación importante deberá actualizar los documentos correspondientes.

Según el cambio podrá ser necesario actualizar:

- README.md
- PROJECT.md
- ARCHITECTURE.md
- DESIGN.md
- INSTALL.md
- CHANGELOG.md
- ROADMAP.md
- CONTRIBUTING.md
- GOVERNANCE.md
- SECURITY.md
- USER_GUIDE.md

Una funcionalidad no se considerará terminada hasta que su documentación refleje el mismo estado que el código.

---

# Pruebas

Toda modificación deberá validarse antes de integrarse.

Las pruebas deberán demostrar:

- funcionamiento correcto;
- ausencia de regresiones;
- consistencia arquitectónica;
- preservación de datos persistentes cuando corresponda.

Las modificaciones relacionadas con el Installer deberán validar:

- install;
- upgrade;
- repair;
- verify;
- uninstall.

---

# Commits

Cada commit representará una única responsabilidad.

Ejemplos:

```text
BUG-008  Fix reputation calculation

TASK-012  Refactor installer manifest

FEAT-005  Add Sensor Framework

DOC-006  Rewrite installation guide
```

Los commits deberán ser:

- pequeños;
- autocontenidos;
- descriptivos;
- trazables.

---

# Versiones

Las ramas de desarrollo deberán permanecer funcionales en todo momento.

Política recomendada:

```text
main
```

Versión estable.

```text
v1.x-dev
```

Desarrollo de la siguiente versión.

---

# Calidad

Antes de cerrar una tarea deberá verificarse:

- código funcional;
- pruebas satisfactorias;
- documentación actualizada;
- consistencia arquitectónica;
- actualización del CHANGELOG cuando corresponda;
- actualización del TODO cuando corresponda.

---

# Principios finales

Toda información de ARE pertenece exactamente a una de las siguientes categorías:

1. Definición del producto.
2. Configuración de la instalación.
3. Estado de ejecución.

Estas categorías nunca deberán mezclarse.

La metodología de desarrollo tiene como objetivo preservar una arquitectura estable que permita la evolución continua del proyecto sin introducir deuda técnica ni duplicación de responsabilidades.
