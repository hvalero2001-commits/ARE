# ARE Roadmap

## Introducción

Este documento define la evolución prevista de ARE (Abuse Reputation Engine).

El Roadmap describe la dirección técnica del proyecto y sirve como referencia para planificar nuevas capacidades sin comprometer la estabilidad del núcleo.

Las versiones representan objetivos técnicos y no fechas de publicación.

Toda nueva funcionalidad deberá respetar la arquitectura y la metodología oficial del proyecto.

---

# Estado del proyecto

Versión estable actual:

```text
v1.1
```

Estado:

```text
Producción
```

La prioridad continúa siendo consolidar el núcleo antes de ampliar capacidades.

---

# v1.0.x

## Objetivo

Construcción del núcleo de ARE.

## Estado

✔ Completado

## Capacidades incorporadas

- Reputation Engine
- State Engine
- Policy Engine
- Firewall Backend
- SQLite
- Dashboard
- Integración con Fail2Ban
- Integración con ModSecurity
- Soporte IPv4
- Soporte IPv6

---

# v1.1

## Objetivo

Consolidar el producto y completar el ciclo de vida operativo.

## Estado

✔ Completado

## Funcionalidades

### Installer Engine

- install
- upgrade
- repair
- verify
- uninstall

### Sensor Framework

- arquitectura de sensores
- primer Sensor oficial de Fail2Ban (`FOUND`)

### Installer Manifest

- definición oficial del paquete
- estructura centralizada del producto

### Dashboard

- TOP JAILS
- ampliación de estadísticas
- separación entre eventos y reputación

### Reputation Engine

Nuevas categorías:

- ANOMALY
- MALWARE
- DOS
- SOCIAL

### Documentación

- reorganización completa
- normalización documental
- documentación sincronizada con el código

---

# v1.2

## Objetivo

Incrementar la inteligencia del motor de decisión.

## Funcionalidades previstas

### Reputation

- Decay Engine completo
- optimización del cálculo de reputación
- mejora de perfiles

### Policy Engine

- reglas dinámicas
- correlación de categorías
- optimización del modelo de decisión

### Sensor Framework

Nuevos sensores previstos:

- ModSecurity
- SSH
- Apache
- Syslog

### Dashboard

- gráficos históricos
- métricas ampliadas
- consultas avanzadas

---

# v1.3

## Objetivo

Ampliar la integración con sistemas externos.

## Funcionalidades previstas

- exportación de métricas
- eventos externos
- APIs
- integración con plataformas SIEM

---

# v2.0

## Objetivo

Convertir ARE en un motor de reputación completamente independiente del Firewall.

## Sensores previstos

- ModSecurity
- Suricata
- Zeek
- CrowdSec
- Apache
- Syslog
- DNS
- APIs externas

---

## Backends previstos

- IPSet
- nftables
- firewalld
- pf
- Cloud Firewall

---

## Plataforma

- API REST
- Backend Manager
- métricas
- alta disponibilidad
- replicación
- integración distribuida

---

# Principios de evolución

Toda evolución deberá respetar los siguientes principios.

- estabilidad antes que nuevas funcionalidades;
- arquitectura antes que implementación;
- reutilización antes que duplicación;
- documentación sincronizada;
- evolución incremental.

Las versiones mayores únicamente deberán introducir cambios arquitectónicos incompatibles con versiones anteriores.

---

# Criterios para incorporar funcionalidades

Toda nueva capacidad deberá:

- responder a una necesidad técnica;
- mantener la arquitectura existente;
- encontrarse documentada;
- haber sido validada;
- formar parte del Roadmap antes de comenzar su implementación.

---

# Visión

ARE evoluciona hacia una plataforma de reputación y decisión capaz de integrar múltiples fuentes de eventos y múltiples mecanismos de respuesta manteniendo un núcleo único de inteligencia.

La arquitectura continuará creciendo mediante componentes desacoplados, reutilizables y documentados.
