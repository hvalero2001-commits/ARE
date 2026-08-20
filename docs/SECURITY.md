# Security Policy

## Introducción

La seguridad constituye uno de los principios fundamentales de ARE (Abuse Reputation Engine).

Este documento define la política oficial para el reporte, análisis, corrección y divulgación de vulnerabilidades relacionadas con el proyecto.

El objetivo es garantizar una gestión responsable de los incidentes de seguridad y mantener la estabilidad del núcleo antes de publicar cualquier corrección.

---

# Versiones soportadas

| Versión | Estado |
|---------|:------:|
| 2.1.x (en desarrollo) | ✅ Soportada |
| 2.0.x | ✅ Soportada |
| 1.1.x | ✅ Soporte limitado |
| 1.0.x | ❌ No soportada |
| < 1.0 | ❌ No soportada |

---

# Reporte de vulnerabilidades

Si descubres una vulnerabilidad en ARE, evita su divulgación pública antes de que pueda ser analizada.

Todo reporte debería incluir, siempre que sea posible:

- descripción del problema;
- pasos para reproducirlo;
- impacto esperado;
- componentes afectados;
- evidencia disponible;
- propuesta de mitigación (opcional).

Los reportes deberán permitir reproducir el comportamiento observado.

---

# Clasificación

Toda vulnerabilidad será evaluada considerando:

- impacto sobre la disponibilidad;
- impacto sobre la integridad;
- impacto sobre la confidencialidad;
- facilidad de explotación;
- alcance del problema;
- posibilidad de explotación remota.

Esta clasificación determinará la prioridad de corrección.

---

# Proceso de gestión

Todo incidente seguirá el siguiente proceso.

```text
Reporte
 │
 ▼
Análisis
 │
 ▼
Validación
 │
 ▼
Clasificación
 │
 ▼
Corrección
 │
 ▼
Pruebas
 │
 ▼
Actualización documental
 │
 ▼
Nueva versión
 │
 ▼
CHANGELOG
```

Las correcciones deberán validarse antes de formar parte de una versión estable.

---

# Divulgación responsable

ARE promueve la divulgación responsable.

Una vulnerabilidad sólo deberá hacerse pública cuando:

- haya sido analizada;
- exista una corrección disponible o una mitigación documentada;
- la versión corregida haya sido publicada.

---

# Alcance

Esta política aplica a todos los componentes oficiales del proyecto.

Incluye:

- Sensor Framework;
- Reputation Engine;
- State Engine;
- Policy Engine;
- Ban Lifecycle Engine;
- Apply Engine;
- Firewall Backend;
- ARE ADMIN;
- Installer Engine;
- Dashboard;
- SQLite;
- scripts oficiales;
- documentación distribuida con el producto.

---

# Correcciones de seguridad

Las correcciones deberán cumplir los mismos principios que el resto del proyecto.

- una responsabilidad por cambio;
- documentación sincronizada;
- pruebas obligatorias;
- ausencia de regresiones;
- preservación de la arquitectura.

No deberán introducirse cambios funcionales no relacionados dentro de una corrección de seguridad.

---

# Calidad

Antes de publicar una corrección deberán verificarse:

- funcionamiento correcto;
- pruebas satisfactorias;
- documentación actualizada;
- ausencia de nuevos problemas;
- actualización del CHANGELOG cuando corresponda.

---

# Filosofía

La seguridad no consiste únicamente en corregir vulnerabilidades.

Consiste en mantener una arquitectura simple, verificable y preparada para evolucionar.

Cada corrección debe fortalecer el proyecto sin comprometer la estabilidad del núcleo.

ARE prioriza la prevención, la evidencia y la evolución incremental como principios fundamentales de su estrategia de seguridad.
