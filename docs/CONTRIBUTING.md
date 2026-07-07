# ARE Governance

## Introducción

Este documento define el modelo de gobierno del proyecto ARE (Abuse Reputation Engine).

Su objetivo es establecer un proceso claro para la evolución del proyecto, garantizando estabilidad, coherencia técnica y calidad del código.

---

# Principios

ARE se desarrolla siguiendo los siguientes principios:

- Simplicidad
- Modularidad
- Responsabilidad única
- Compatibilidad hacia atrás siempre que sea posible
- Estabilidad antes que nuevas funcionalidades

Toda decisión deberá respetar los principios definidos en `DESIGN.md`.

---

# Evolución del proyecto

Toda nueva capacidad deberá seguir un proceso de evolución controlado.

```
Idea
    ↓

RFC
    ↓

Diseño

    ↓

Implementación

    ↓

Pruebas

    ↓

Documentación

    ↓

Versión estable
```

No deberán incorporarse funcionalidades directamente al código sin haber sido previamente analizadas cuando impliquen cambios de arquitectura.

---

# RFC

Los RFC (Request For Comments) representan propuestas técnicas que modifican o amplían la arquitectura del proyecto.

Un RFC deberá incluir como mínimo:

- Objetivo
- Justificación
- Impacto esperado
- Compatibilidad
- Estado

Estados posibles:

- Draft
- Accepted
- Rejected
- Implemented

---

# Versiones

Las versiones estables deberán contener únicamente funcionalidades completamente validadas.

Las ramas de desarrollo podrán contener funcionalidades experimentales mientras permanezcan documentadas.

---

# Calidad

Antes de cerrar una versión deberán verificarse:

- Código funcional
- Pruebas satisfactorias
- Documentación actualizada
- Bugs críticos resueltos

---

# Documentación

La documentación forma parte del proyecto.

Todo cambio importante deberá reflejarse en los documentos correspondientes antes de considerarse finalizado.

---

# Filosofía

ARE evoluciona mediante pequeñas mejoras continuas.

Se prioriza la estabilidad del núcleo antes de incorporar nuevas capacidades.

Cada versión deberá dejar una base sólida para la siguiente.
