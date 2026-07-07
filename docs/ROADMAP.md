# ARE Roadmap

## Introducción

Este documento describe la evolución planificada de ARE (Abuse Reputation Engine).

El objetivo del Roadmap es mostrar la dirección técnica del proyecto, permitiendo conocer las capacidades actuales y las funcionalidades previstas para futuras versiones.

Las fechas podrán variar según las necesidades del proyecto y la estabilidad de cada versión.

---

# Version 1.0.x

## Objetivo

Consolidar el núcleo del motor de reputación.

### Estado

✔ Completado

### Funcionalidades

- Reputation Engine
- State Engine
- Policy Engine
- Firewall Backend (IPSet)
- Persistencia SQLite
- Dashboard
- Integración con Fail2Ban
- Integración con ModSecurity
- Soporte IPv4 / IPv6

---

# Version 1.1

## Objetivo

Ampliar la capacidad de observación y mejorar la arquitectura interna.

### Estado

🚧 En desarrollo

### Funcionalidades

- Sensor Framework
- Fail2Ban Sensor (FOUND)
- Cursor persistente para sensores
- Renombrar CLI oficial a `are`
- Reorganización del código por módulos
- Mejoras de documentación
- Corrección de bugs detectados en producción

---

# Version 1.2

## Objetivo

Incrementar la inteligencia del motor de decisión.

### Funcionalidades previstas

- Reputation Decay Engine
- Correlación entre sensores
- Mejor clasificación de amenazas
- Optimización del Policy Engine
- Dashboard ampliado

---

# Version 2.0

## Objetivo

Convertir ARE en un motor independiente de reputación y decisión.

### Funcionalidades previstas

### Sensores

- ModSecurity Sensor
- Apache Sensor
- Syslog Sensor
- Suricata Sensor
- Zeek Sensor
- CrowdSec Sensor

### Backends

- nftables
- firewalld
- pf
- Cloud Firewall

### Plataforma

- API REST
- Exportación de métricas
- Integración con SIEM
- Backend Manager
- Alta disponibilidad

---

# Filosofía de evolución

ARE evoluciona mediante pequeñas iteraciones.

Cada versión debe mantener la estabilidad del núcleo antes de incorporar nuevas capacidades.

Las nuevas funcionalidades deberán respetar los principios definidos en `DESIGN.md` y la arquitectura descrita en `ARCHITECTURE.md`.

El crecimiento del proyecto estará orientado a mantener una arquitectura modular, desacoplada y fácilmente extensible.
