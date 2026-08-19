# ARE Roadmap

## Introducción

Este documento define la evolución prevista de ARE (Abuse Reputation Engine).

El Roadmap describe la dirección técnica del proyecto y sirve como referencia para planificar nuevas capacidades sin comprometer la estabilidad del núcleo.

Las versiones representan objetivos técnicos y no fechas de publicación.

Toda nueva funcionalidad deberá respetar la arquitectura y la metodología oficial del proyecto.

---

# Estado del proyecto

Versión estable liberada:

```text
v2.0.0
```

Versión en desarrollo activo:

```text
v2.1 (rama v2.1-dev)
```

Estado:

```text
Producción
```

La versión estable actual se encuentra operativa en el servidor de producción principal y continúa siendo objeto de consolidación y mantenimiento. El desarrollo activo avanza sobre `v2.1-dev`, documentado en detalle en `docs/TODO.md`.

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

# v2.0

## Objetivo

Consolidar la identidad propia del producto (migración desde `f2b-ipset`), incorporar una interfaz de administración completa, y evolucionar el motor de decisión de un modelo por score total a uno de evaluación por categoría.

## Estado

✔ Completado — liberado como release oficial (`v2.0.0`)

## Funcionalidades incorporadas

Reemplazan y superan lo originalmente previsto para `v1.2`/`v1.3` en este mismo documento (Decay Engine, reglas dinámicas, correlación de categorías, métricas ampliadas) — ver detalle completo en `docs/CHANGELOG.md` y `docs/TODO.md`.

### Product Manifest e Installer

* `manifest/product.sh` como fuente única de verdad de los componentes del producto
* Instalación oficial en `/opt/are`, abandonando la identidad histórica `f2b-ipset`

### Reputation Decay

* Decay Engine completo (`dry-run` / `apply`), con ejecución programada vía systemd

### Interfaz de Administración (ARE ADMIN)

* CLI completo (`are.sh admin`), 7 ramas: Jails/Perfiles, Categorías, Sensores, Política, Estado/Reputación, Decay, Configuración
* Registro de auditoría de operaciones de escritura
* Banner con identificación de servidor, para entornos con múltiples nodos

### Policy Engine basado en categorías

* Evaluación de riesgo por categoría de reputación, con regla propia y umbral configurable por categoría
* Multiplicador de riesgo por reincidencia
* Piso de seguridad: nunca menos estricto que el score total agregado
* Herramienta de comparación (`policy-compare`) para validar el motor antes de aplicarlo en producción

### Integración de mod_evasive

* Protección anti-flood de Apache incorporada al modelo de reputación de ARE (categoría DOS), en reemplazo de un bloqueo de duración fija desconectado del sistema

### Consolidación

* Eliminación del código de generaciones anteriores del Policy Engine

---

# v2.1 (en desarrollo)

## Objetivo

Administración avanzada de perfiles, extensibilidad del modelo de reputación, visibilidad operativa, y robustecimiento de la persistencia del Firewall Backend.

## Estado

En progreso — rama `v2.1-dev`

## Funcionalidades incorporadas hasta el momento

### Jails / Perfiles

* Exportar / Importar `jail_profile` entre servidores, con resolución de conflictos y auditoría

### Sensores

* `apache_evasive.sh` formalizado como sensor oficial del framework — segundo patrón documentado (callback, invocado directo por Apache), junto al ya existente (polling, Fail2Ban)
* Filtro de jails de Fail2Ban reemplazado por consulta dinámica contra `jail_profile`, en vez de una lista fija en el código

### Modelo de reputación

* Migración del modelo de categorías de columnas fijas a esquema normalizado (`reputation_scores`), permitiendo agregar categorías nuevas como operación de datos, sin migración de esquema ni cambios de código
* Corrección de deriva de truncamiento en el cálculo de reputación (almacenamiento y cálculo de Decay)
* Redistribución proporcional del Decay Engine entre categorías, evitando que la diversidad de técnicas de ataque acelere la liberación de una IP

### Dashboard

* Tendencias diarias de actividad (eventos, bans, IPs distintas por día), primera vista temporal del sistema

### Firewall Backend

* Restauración automática del estado del firewall (`ipset`) desde la base de datos al arrancar el sistema, preservando el tiempo restante exacto de sanciones temporales activas — antes, un reinicio del servidor podía perder sanciones activas sin cumplir su plazo
* Corrección de un límite de rango no controlado en `ipset`, que impedía aplicar correctamente sanciones de larga duración (nivel más alto de reincidencia previo a la sanción permanente)

## Pendiente en la rama actual

* Exportación de tendencias a CSV
* Desglose de tendencias por categoría
* Definir umbrales de riesgo para las categorías `MALWARE` y `SOCIAL`, a la espera de un jail o sensor real que reporte a esas categorías
* Eliminación de las columnas de categoría redundantes en `reputation` (pospuesta por limitación de versión de SQLite en el servidor de producción, sin fecha)

---

# Próximas líneas de trabajo

## Sensores adicionales

Previstos, sin implementación iniciada:

* ModSecurity como sensor propio (hoy reporta indirectamente vía jails de Fail2Ban)
* Suricata
* Zeek
* CrowdSec
* Syslog genérico
* DNS
* APIs externas

## Motor de decisión

* Regla propia para las categorías `MALWARE` y `SOCIAL`, cuando exista una fuente real de datos
* Integración completa de `mod_evasive` como única vía de bloqueo (hoy corre en modo doble escritura, ipset directo + reporte a ARE, como medida de transición)

---

# Visión de largo plazo

Objetivos de arquitectura de mayor alcance, sin planificación de versión concreta todavía. Su inclusión aquí no implica compromiso de implementación — deben incorporarse formalmente a una versión del Roadmap antes de iniciar su desarrollo, según los criterios de la sección siguiente.

## Backends de Firewall alternativos

* nftables
* firewalld
* pf
* Cloud Firewall

## Plataforma

* API REST
* Backend Manager (administración de múltiples backends de firewall)
* Alta disponibilidad
* Replicación entre nodos
* Integración distribuida (múltiples servidores compartiendo inteligencia de reputación)

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
