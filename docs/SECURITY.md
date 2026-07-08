# Política de Seguridad

## Objetivo

La seguridad constituye uno de los principios fundamentales de ARE (Abuse Reputation Engine).

Esta política describe el procedimiento oficial para reportar vulnerabilidades y gestionar incidentes relacionados con la seguridad del proyecto.

---

# Versiones Soportadas

| Versión | Soporte |
| ------- | :-----: |
| 1.x     |   ✅ Sí  |
| < 1.0   |   ❌ No  |

---

# Reporte de Vulnerabilidades

Si descubres una vulnerabilidad de seguridad en **ARE**, te solicitamos que **no la publiques inmediatamente**.

En su lugar, repórtala de forma privada al responsable del proyecto para permitir su análisis y corrección antes de su divulgación pública.

El reporte debería incluir, en la medida de lo posible:

- Descripción de la vulnerabilidad.
- Pasos para reproducir el problema.
- Impacto estimado.
- Componentes afectados.
- Evidencia disponible (registros, capturas o ejemplos).
- Posible mitigación, si aplica.

---

# Clasificación

Los reportes serán evaluados considerando, entre otros aspectos:

- Impacto sobre la disponibilidad.
- Impacto sobre la integridad.
- Impacto sobre la confidencialidad.
- Facilidad de explotación.
- Alcance del problema.

Esta clasificación permitirá establecer la prioridad de corrección.

---

# Proceso de Gestión

Cada reporte seguirá el siguiente proceso:

```
Reporte
    ↓

Análisis

    ↓

Validación

    ↓

Clasificación

    ↓

Corrección

    ↓

Pruebas

    ↓

Nueva versión

    ↓

Actualización del CHANGELOG
```

---

# Divulgación Responsable

El proyecto promueve la divulgación responsable de vulnerabilidades.

Se agradece la colaboración de investigadores, administradores de sistemas y miembros de la comunidad que contribuyan a mejorar la seguridad y estabilidad de ARE.

---

# Alcance

Esta política aplica a todos los componentes oficiales del proyecto, incluyendo:

- Reputation Engine
- State Engine
- Policy Engine
- Sensores
- Firewall Backends
- Dashboard
- Base de datos
- Scripts oficiales

---

# Filosofía

La seguridad no consiste únicamente en corregir vulnerabilidades.

El objetivo de ARE es evolucionar mediante pequeñas mejoras continuas, manteniendo un núcleo estable, documentado y verificable antes de incorporar nuevas capacidades.

Toda corrección de seguridad deberá validarse antes de formar parte de una versión estable.

