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

La versión actual se encuentra operativa y continúa siendo objeto de consolidación y mantenimiento.

---

# v1.0.x

## Objetivo

Construcción y estabilización del núcleo de ARE.

## Estado

✔ Completado

## Capacidades incorporadas

* Reputation Engine
* State Engine
* Policy Engine
* Firewall Backend
* SQLite
* Dashboard
* Integración con Fail2Ban
* Integración con ModSecurity
* Soporte IPv4
* Soporte IPv6

---

# v1.1

## Objetivo

Consolidar el producto y ampliar su ciclo de vida operativo.

## Estado

✔ Completado

## Funcionalidades

### Installer Engine

* install
* upgrade
* repair
* verify
* uninstall
* detección del estado de instalación
* protección de configuración persistente
* conservación de datos persistentes
* validación de la instalación
* desinstalación conservando configuración, datos y logs

Las operaciones `install`, `upgrade` y `repair` utilizan un Core fuente separado de la instalación activa cuando requieren copiar los componentes del producto.

La generación, descarga, extracción y staging automático de paquetes no forman parte del Installer actual.

### Sensor Framework

* arquitectura de sensores
* primer Sensor oficial de Fail2Ban (`FOUND`)
* procesamiento mediante offset persistente
* ejecución `--dry-run`
* ejecución `--execute`

### Installer Manifest

* definición oficial de los componentes administrados
* estructura centralizada del producto

### Dashboard

* TOP JAILS
* ampliación de estadísticas
* separación entre eventos y reputación

### Reputation Engine

Nuevas categorías:

* ANOMALY
* MALWARE
* DOS
* SOCIAL

### Documentación

* reorganización completa
* normalización documental
* documentación sincronizada con el código

---

# v1.2

## Objetivo

Incrementar la inteligencia del motor de decisión y continuar la consolidación del sistema.

## Funcionalidades previstas

### Reputation

* Decay Engine completo
* optimización del cálculo de reputación
* mejora de perfiles

### Policy Engine

* reglas dinámicas
* correlación de categorías
* optimización del modelo de decisión

### Sensor Framework

Nuevos sensores previstos:

* ModSecurity
* SSH
* Apache
* Syslog

### Dashboard

* gráficos históricos
* métricas ampliadas
* consultas avanzadas

---

# v1.3

## Objetivo

Ampliar la integración con sistemas externos y las capacidades de observación del motor.

## Funcionalidades previstas

* exportación de métricas
* eventos externos
* APIs
* integración con plataformas SIEM

---

# v2.0

## Objetivo

Evolucionar ARE hacia una arquitectura de reputación y decisión con mayor independencia de un mecanismo específico de Firewall.

## Sensores previstos

* ModSecurity
* Suricata
* Zeek
* CrowdSec
* Apache
* Syslog
* DNS
* APIs externas

---

## Backends previstos

* IPSet
* nftables
* firewalld
* pf
* Cloud Firewall

---

## Plataforma

* API REST
* Backend Manager
* métricas
* alta disponibilidad
* replicación
* integración distribuida

---

# Principios de evolución

Toda evolución deberá respetar los siguientes principios.

* estabilidad antes que nuevas funcionalidades;
* arquitectura antes que implementación;
* reutilización antes que duplicación;
* documentación sincronizada;
* evolución incremental.

Las versiones mayores podrán introducir cambios arquitectónicos cuando éstos hayan sido previamente analizados y documentados.

---

# Criterios para incorporar funcionalidades

Toda nueva capacidad deberá:

* responder a una necesidad técnica;
* mantener la arquitectura existente o justificar formalmente cualquier modificación;
* encontrarse documentada;
* haber sido validada;
* formar parte del Roadmap antes de comenzar su implementación.

La presencia de una funcionalidad en este documento no implica que se encuentre implementada.

---

# Visión

ARE evoluciona hacia una plataforma de reputación y decisión capaz de integrar múltiples fuentes de eventos y múltiples mecanismos de respuesta manteniendo un núcleo único de inteligencia.

La arquitectura continuará creciendo mediante componentes desacoplados, reutilizables y documentados.
