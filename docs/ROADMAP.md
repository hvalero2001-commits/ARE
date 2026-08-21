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
v2.1.0
```

Versión en desarrollo activo:

```text
v2.2 (rama v2.2-dev)
```

Estado:

```text
Producción
```

La versión estable actual se encuentra operativa en el servidor de producción principal y continúa siendo objeto de consolidación y mantenimiento. El desarrollo activo avanza sobre `v2.2-dev`, documentado en detalle en `docs/TODO.md`.

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

# v2.1

## Objetivo

Administración avanzada de perfiles, extensibilidad del modelo de reputación, visibilidad operativa, y robustecimiento de la persistencia del Firewall Backend.

## Estado

✔ Completado — liberado como release oficial (`v2.1.0`)

## Funcionalidades incorporadas

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

---

# v2.2

## Objetivo

Incorporar una nueva fuente de datos real al modelo de reputación (categoría SOCIAL), completar el catálogo de umbrales de categoría, y resolver la fricción de distribución del producto hacia otros servidores de la flota.

## Estado

✔ Completado — liberado como release oficial (`v2.2.0`)

## Funcionalidades incorporadas

### Sensor SpamAssassin

* Categoría `SOCIAL` con sensor real, alimentado por scores de SpamAssassin sobre tráfico de correo saliente, clasificados en tres bandas de severidad calibradas por `jail_profile`
* Arquitectura por adaptador de MTA — único adaptador implementado y validado: Exim
* `policy/rules/social.sh`, existente desde una fase anterior del proyecto sin umbral definido, activo por primera vez

### Catálogo de categorías

* Las 9 categorías del modelo de reputación cuentan con umbral definido — incluida `MALWARE`, calibrada de forma proactiva pese a no contar con sensor local, como decisión de motor genérico útil para cualquier servidor con superficie de malware real

### Dashboard

* Desglose de tendencias por categoría y exportación a CSV, extendiendo la vista temporal incorporada en v2.1

### Empaquetado y distribución

* Script de empaquetado que genera un artefacto distribuible a partir del manifiesto del producto, con verificación de integridad
* Automatización de la generación y publicación del paquete en cada versión etiquetada
* Instalación remota de una sola línea, sin depender de clonar el repositorio

## Pendiente, fuera del alcance de esta versión

* Fase de auto-actualización del Installer contra el repositorio de releases (estilo `apt`/`yum`), dependiente de que la distribución vía paquete esté en uso real
* Habilitar/deshabilitar sensores desde ARE ADMIN, con auto-provisión de `jail_profile` al activar
* Integración completa de `mod_evasive` como única vía de bloqueo — investigación en curso sugiere que el patrón de amenaza real de servidores detrás de un proxy como Cloudflare (tráfico distribuido, no floods concentrados de una sola IP) puede no coincidir con lo que este sensor está diseñado para detectar; sin evidencia real de disparo hasta la fecha
* Eliminación de las columnas de categoría redundantes en `reputation` (pospuesta por limitación de versión de SQLite en el servidor de producción, sin fecha)

---

# Próximas líneas de trabajo

## Sensores adicionales

Previstos, sin implementación iniciada:

* ModSecurity como sensor propio (hoy reporta indirectamente vía jails de Fail2Ban)
* Suricata
* Zeek
* CrowdSec
* DNS
* APIs externas

Evaluado y descartado: un sensor "syslog genérico" con contrato propio de mensaje (`ip=X jail=Y`). Le pediría a cada herramienta externa reformatear su salida a un formato inventado por ARE, duplicando estructuras de logueo que cada herramienta ya tiene — el mismo problema que ARE existe para evitar, no para resolver. El camino correcto para sumar una herramienta nueva sigue siendo un sensor que lea el log real de esa herramienta tal cual es (mismo criterio que `spamassassin.sh` con el log de Exim), no pedirle que hable el idioma de ARE.

## Motor de decisión

* Regla propia para la categoría `MALWARE`, cuando exista una fuente real de datos que la alimente — el umbral (`MALWARE_THRESHOLD`) ya está calibrado de forma proactiva desde v2.2, a la espera del sensor
* Integración completa de `mod_evasive` como única vía de bloqueo (hoy corre en modo doble escritura, ipset directo + reporte a ARE, como medida de transición) — ver nota de investigación en la sección v2.2

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
