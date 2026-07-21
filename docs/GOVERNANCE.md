# ARE Governance

## Introducción

Este documento define el modelo de gobierno de ARE (Abuse Reputation Engine).

Su objetivo es establecer un proceso claro para la evolución del proyecto, garantizando estabilidad, coherencia arquitectónica y calidad durante todo su ciclo de vida.

El gobierno del proyecto define cómo se toman las decisiones técnicas y cómo evolucionan las distintas versiones de ARE.

---

# Principios

Toda decisión deberá respetar los siguientes principios:

- arquitectura antes que implementación;
- estabilidad antes que nuevas funcionalidades;
- una responsabilidad por componente;
- bajo acoplamiento;
- alta cohesión;
- documentación sincronizada con el código;
- evolución incremental.

Toda decisión deberá ser consistente con:

- PHILOSOPHY.md
- ARCHITECTURE.md
- DESIGN.md
- DEVELOPMENT.md

---

# Evolución del proyecto

Toda nueva capacidad seguirá el siguiente proceso.

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
Versión estable
```

Las modificaciones arquitectónicas nunca deberán implementarse directamente sin análisis previo.

---

# Clasificación

Toda propuesta deberá clasificarse antes de comenzar.

## BUG

Corrección de un comportamiento incorrecto.

---

## TASK

Mantenimiento, reorganización o refactorización.

---

## FEATURE

Nueva funcionalidad compatible con la arquitectura vigente.

---

## RFC

Propuesta que modifica o amplía la arquitectura del proyecto.

Todo RFC deberá aprobarse antes de iniciar su implementación.

---

## IDEA

Propuesta sin planificación para una versión específica.

Las ideas no forman parte automáticamente del Roadmap.

---

# RFC

Todo RFC deberá documentar al menos:

- objetivo;
- justificación;
- impacto;
- compatibilidad;
- alternativas;
- estado.

Estados posibles:

- Draft
- Accepted
- Rejected
- Implemented

---

# Política de versiones

ARE evoluciona mediante versiones incrementales.

## Versiones de mantenimiento

```text
v1.0.x
```

Correcciones y estabilización.

---

## Versiones funcionales

```text
v1.1.x
```

Nuevas funcionalidades compatibles con la arquitectura existente.

---

## Versiones mayores

```text
v2.x
```

Cambios incompatibles o modificaciones arquitectónicas.

---

# Criterios para cerrar una versión

Antes de publicar una versión deberán verificarse:

- código funcional;
- pruebas satisfactorias;
- documentación actualizada;
- arquitectura consistente;
- CHANGELOG actualizado;
- TODO revisado;
- ausencia de errores críticos.

Una versión estable deberá representar un estado coherente del proyecto.

---

# Documentación

La documentación forma parte del gobierno del proyecto.

Toda modificación relevante deberá actualizar la documentación correspondiente antes de considerarse finalizada.

Ningún cambio importante deberá incorporarse dejando documentación desactualizada.

---

# Calidad

La aceptación de una modificación dependerá de:

- consistencia con la arquitectura;
- calidad de implementación;
- simplicidad;
- reutilización;
- ausencia de lógica duplicada;
- impacto sobre el núcleo;
- cobertura documental.

---

# Responsabilidad arquitectónica

La arquitectura oficial del proyecto está definida por:

- PHILOSOPHY.md
- ARCHITECTURE.md
- DESIGN.md

Toda nueva funcionalidad deberá respetar dichos documentos.

Las implementaciones nunca deberán redefinir la arquitectura.

---

# Filosofía

ARE evoluciona mediante mejoras pequeñas, verificables y documentadas.

Cada versión debe dejar una base más sólida que la anterior.

Las decisiones técnicas se toman priorizando la estabilidad del proyecto sobre la incorporación acelerada de nuevas funcionalidades.

La evolución continua constituye uno de los principios fundamentales del gobierno de ARE.
