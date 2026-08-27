# ARE Project

## Introducción

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para transformar eventos de seguridad en respuestas inteligentes basadas en evidencia.

El proyecto desacopla completamente la detección de amenazas de la toma de decisiones, permitiendo integrar múltiples fuentes de eventos y múltiples mecanismos de respuesta sin modificar el núcleo del sistema.

ARE no pretende sustituir herramientas como Fail2Ban o ModSecurity.

Su objetivo es convertirlas en fuentes de información para construir una visión unificada del comportamiento de una dirección IP.

---

# Visión

Construir un motor de reputación independiente capaz de interpretar el comportamiento histórico de una dirección IP y decidir la respuesta más adecuada según el riesgo observado.

ARE busca convertirse en una plataforma de decisión reutilizable por cualquier sistema de seguridad.

---

# Misión

Centralizar la inteligencia de seguridad.

Los sistemas externos generan eventos.

ARE interpreta esos eventos.

ARE conserva el conocimiento.

ARE toma las decisiones.

Los mecanismos de protección únicamente ejecutan dichas decisiones.

---

# Objetivos

El proyecto persigue los siguientes objetivos.

- Construir reputación persistente.
- Evaluar comportamiento histórico.
- Separar observación y decisión.
- Mantener arquitectura modular.
- Permitir crecimiento incremental.
- Facilitar integración con nuevos sensores.
- Facilitar integración con nuevos Backends.
- Mantener un núcleo estable y reutilizable.

---

# Alcance

ARE administra:

- reputación;
- estados;
- políticas;
- ciclo de sanciones;
- persistencia;
- instalación;
- observación mediante sensores.

ARE no sustituye:

- Firewalls;
- WAF;
- IDS;
- IPS;
- Fail2Ban;
- ModSecurity.

Estos componentes continúan desempeñando su función natural y actúan como productores de eventos.

---

# Arquitectura

El proyecto está compuesto por los siguientes motores.

- Sensor Framework
- Reputation Engine
- State Engine
- Policy Engine
- Ban Lifecycle Engine
- Firewall Backend
- Installer Engine

Cada componente implementa una única responsabilidad.

---

# Componentes principales

## Sensor Framework

Normaliza eventos provenientes de sistemas externos.

---

## Reputation Engine

Construye conocimiento persistente mediante categorías de reputación.

---

## State Engine

Representa la evolución operativa de una dirección IP.

---

## Policy Engine

Determina la respuesta adecuada según reputación y estado.

---

## Ban Lifecycle Engine

Administra la evolución de las sanciones.

---

## Firewall Backend

Ejecuta las decisiones sobre el sistema operativo.

---

## Installer Engine

Administra el ciclo de vida del producto.

---

# Estado actual

Versión estable liberada:

```text
v2.4.1
```

Versión en desarrollo activo:

```text
v2.5 (rama v2.5-dev)
```

Capacidades implementadas.

- Reputation Engine, con modelo de reputación por categoría extensible sin migración de esquema.
- State Engine.
- Policy Engine, con evaluación de riesgo por categoría.
- Ban Lifecycle Engine.
- Sensor Framework, con los patrones polling y callback, y control operativo de activación/desactivación por sensor desde ARE ADMIN.
- Fail2Ban Sensor.
- Apache/mod_evasive Sensor.
- SpamAssassin Sensor (categoría SOCIAL).
- Firewall Backend (IPSet), con restauración automática al arrancar el sistema.
- Dashboard, con estadísticas, tendencias temporales por categoría, y detección de anomalías.
- Installer Engine, con empaquetado, distribución, y auto-actualización (consulta de versión disponible, actualización remota, instalación automática de dependencias del sistema).
- SQLite.
- Integración con ModSecurity.
- Integración con Fail2Ban.

---

# Organización del proyecto

La documentación oficial se encuentra organizada mediante documentos especializados.

| Documento | Propósito |
|-----------|-----------|
| README.md | Presentación del proyecto |
| PHILOSOPHY.md | Principios fundamentales |
| PROJECT.md | Definición del proyecto |
| ARCHITECTURE.md | Arquitectura |
| DESIGN.md | Decisiones de diseño |
| INSTALL.md | Ciclo de vida del Installer |
| DEVELOPMENT.md | Metodología de desarrollo |
| CONTRIBUTING.md | Guía para colaboradores |
| GOVERNANCE.md | Gobierno del proyecto |
| ROADMAP.md | Evolución prevista |
| CHANGELOG.md | Historial de versiones |
| SECURITY.md | Política de seguridad |
| BAN_LIFECYCLE.md | Ciclo de sanciones |
| USER_GUIDE.md | Guía del administrador |
| TODO.md | Trabajo pendiente |

---

# Evolución

ARE evoluciona mediante pequeñas iteraciones.

Cada versión fortalece el núcleo antes de incorporar nuevas capacidades.

Las modificaciones arquitectónicas se realizan mediante RFC y la implementación sólo comienza una vez aprobadas.

---

# Principios

Los principios fundamentales del proyecto están documentados en `docs/PHILOSOPHY.md`, fuente única — evita que esta lista se desincronice de esa, como ocurría hasta ahora (dos listas de "principios" distintas entre ambos documentos).

---

# Filosofía

ARE interpreta comportamiento.

No responde únicamente a eventos.

Cada dirección IP construye una reputación.

Cada decisión representa la consecuencia del conocimiento acumulado.

La inteligencia reside en ARE.

Los sistemas externos únicamente proporcionan información o ejecutan las decisiones generadas por el motor.
