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
v2.5.0
```

Versión en desarrollo activo:

```text
v2.6 (rama v2.6-dev)
```

Estado:

```text
Producción
```

La versión estable actual se encuentra operativa en el servidor de producción principal y continúa siendo objeto de consolidación y mantenimiento. El desarrollo activo avanza sobre `v2.6-dev`, documentado en detalle en `docs/TODO.md`.

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

* Fase de auto-actualización del Installer contra el repositorio de releases (estilo `apt`/`yum`) — resuelta en v2.3
* Habilitar/deshabilitar sensores desde ARE ADMIN, con auto-provisión de `jail_profile` al activar — resuelta en v2.3
* Integración completa de `mod_evasive` como única vía de bloqueo — investigación en curso sugiere que el patrón de amenaza real de servidores detrás de un proxy como Cloudflare (tráfico distribuido, no floods concentrados de una sola IP) puede no coincidir con lo que este sensor está diseñado para detectar; sin evidencia real de disparo hasta la fecha
* Eliminación de las columnas de categoría redundantes en `reputation` (pospuesta por limitación de versión de SQLite en el servidor de producción, sin fecha)

---

# v2.3

## Objetivo

Administración operativa de sensores desde ARE ADMIN, cierre de la línea de auto-actualización del Installer Engine, y visibilidad ampliada con detección de anomalías.

## Estado

✔ Completado — liberado como release oficial (`v2.3.0`)

## Funcionalidades incorporadas

### Activar/desactivar sensores

* Registro dinámico de sensores (`sensor_registry`), leído por ARE ADMIN sin código nuevo por cada sensor agregado
* Sensores de polling (Fail2Ban, SpamAssassin): activar/desactivar controla directamente el timer de systemd
* Sensor de callback (`apache_evasive`): activar/desactivar mediante archivo flag, sin tocar la configuración externa de Apache/mod_evasive — solo se detiene el bloqueo y el reporte a ARE, con aviso por email en su lugar
* Auto-provisión de `jail_profile` al habilitar SpamAssassin, idempotente
* Detección de jails de Fail2Ban con actividad real sin perfil administrado, solo lectura — sin auto-creación de categoría ni peso

### Cierre de la línea de auto-actualización

* Consulta de versión disponible contra la API de releases, sin tocar el sistema
* Actualización remota de una instalación existente, reutilizando el bootstrap ya existente
* Instalación automática de dependencias del sistema faltantes (apt-get/dnf/yum)

### Visibilidad ampliada

* Detección automática de anomalías en las tendencias diarias por categoría, comparando la actividad del día contra el promedio reciente

## Correcciones

* Workflow de publicación de release fallaba si la Release de GitHub no existía previamente
* Extracción del paquete de instalación remota fallaba en servidores con `/tmp` montado sin permiso de ejecución
* El sensor de SpamAssassin podía reprocesar el mismo tramo del log ante corridas solapadas, inflando la reputación de una IP
* Revertir una sanción no persistía el cambio en el estado de sanciones, exponiendo a que se reaplicara tras un reinicio del sistema
* El sensor de SpamAssassin delegaba en el veredicto interno de la herramienta en vez de decidir por su propio criterio de riesgo, perdiendo eventos reales

---

# v2.4

## Objetivo

Completar el modelo de reputación extensible (RFC-008), y corregir la instalación remota para que funcione realmente de punta a punta, sin intervención manual — validado con instalaciones limpias reales en dos distros distintas.

## Estado

✔ Completado — liberado como release oficial (`v2.4.0`)

## Funcionalidades incorporadas

### Modelo de reputación extensible completo (RFC-008, Fase 4)

* Las 9 columnas de categoría redundantes y `total_score` eliminadas de la tabla `reputation` — el score por categoría vive únicamente en `reputation_scores` (normalizada) desde entonces
* 6 funciones de estadísticas reescritas para calcular sobre `reputation_scores`, sin depender de columnas eliminadas
* Instalaciones nuevas ya no crean las columnas redundantes en absoluto, sin importar la versión de SQLite del servidor

### Instalación remota corregida de fondo

* El Installer nunca creaba los conjuntos IPSet ni las reglas de firewall durante la instalación — dependía de que alguien ejecutara `are.sh` manualmente después. Corregido para inicializarlos como parte del propio `install`/`upgrade`/`repair`
* Las 4 unidades `.service` de sensores de polling tenían una dependencia dura sobre servicios externos (Fail2Ban, Exim) que pueden no estar instalados — un servidor legítimo sin esas herramientas quedaba con la instalación rota. Ablandada a una dependencia de orden, no de bloqueo
* `reputation_scores` no se creaba en una instalación genuinamente nueva sin datos previos

### Desinstalación simplificada

* `uninstall` elimina Core, datos y logs — sin conservar nada por defecto; quien quiera preservar información lo hace por su cuenta antes de desinstalar

### Otras correcciones

* `are.sh` no verificaba privilegios de root — una corrida sin `sudo` fallaba en silencio, sin ningún mensaje, en vez de indicar claramente el problema

## Nota de proceso

Esta versión reveló que la instalación remota, documentada como validada en el cierre de `v2.3.0`, en realidad nunca se había probado de punta a punta sin intervención manual — cada validación previa incluía comandos ejecutados a mano durante las pruebas, ocultando fallas reales en el Installer. Corregido con instalaciones limpias reales, repetidas hasta confirmar 11/11 sin ningún paso manual entre la instalación y la verificación.

---

# v2.5

## Objetivo

Incorporar un nuevo sensor al Sensor Framework capaz de detectar un tipo de amenaza que Fail2Ban no puede ver por diseño: correlación de comportamiento entre múltiples IPs distintas, en vez de evaluación aislada por IP individual.

## Estado

✔ Completado — liberado como release oficial (`v2.5.0`)

## Funcionalidades incorporadas

### Web Correlation Sensor

Surgido de una investigación real sobre un ataque de scraping distribuido de catálogo confirmado en producción, con evidencia reunida antes de escribir una sola línea de código: `fail2ban-regex` confirmando que el filtro existente no detectaba nada de ese tráfico, correlación real por minuto entre decenas de IPs distintas, y `whois` confirmando infraestructura de datacenter/proxy como origen.

* Agrupa eventos por marcador de ruta configurable (por defecto, `cart` — generaliza el sensor a cualquier sitio con catálogo/carrito de e-commerce, no atado a un negocio específico) y ventana de tiempo, contando IPs distintas involucradas.
* Reporta cada IP del grupo correlacionado al contrato existente (`are.sh found <IP> <JAIL>`), sin introducir un concepto nuevo de "grupo/campaña" en el modelo de datos — toda la complejidad de correlación queda encapsulada dentro del sensor.
* Registrado en `sensor_registry` (`RFC-017`) — visible y controlable desde ARE ADMIN sin código adicional, mismo mecanismo genérico que el resto de los sensores de polling.
* Log dedicado, siguiendo el precedente ya establecido por `apache_evasive.sh`/`mod_evasive_report.log`.

## Validación

Lógica de correlación probada en aislamiento antes de tocar producción; corrida real contra el `access_log` completo confirmó grupos genuinos de más de 100 IPs distintas por minuto, coincidiendo con el ataque real ya conocido. Backlog histórico completo (más de 14.000 IPs únicas) procesado en producción sin pérdida de progreso.

---

# v2.6

## Objetivo

Permitir compartir reputación entre servidores de la misma flota — una IP maliciosa ya confirmada en un servidor no debería tener que acumular evidencia desde cero en el siguiente.

## Estado

Implementado y validado en producción real — pendiente de fusión a `main` y publicación del tag `v2.6.0`

## Funcionalidades incorporadas

### Exportar / Importar reputación entre servidores

Surgida directamente de la validación de la versión anterior: un ataque confirmado contra un servidor no implica que la misma infraestructura maliciosa no ataque a otros servidores de la flota por una superficie distinta.

* Exportación filtrada por categoría (checklist, default `BOT`/`RECON`/`EXPLOIT`) y score mínimo configurable, evitando exportar eventos aislados de bajo valor.
* La reputación se acumula al importar, no se sobrescribe — misma función que usa cualquier sensor real, sin mecanismo de conflicto nuevo que aprender.
* Filtro de relevancia automático por rol del servidor: una categoría solo se aplica al importar si ya tiene presencia en el `jail_profile` local — sin que el administrador tenga que decidir manualmente qué servidor necesita qué categoría.
* Dos opciones nuevas en la rama "Estado / Reputación" de ARE ADMIN.

## Validación

Probado en producción real con datos genuinos del ataque de scraping detectado en la versión anterior: exportación de 1192 IPs reales, e importación confirmando las dos rutas del filtro de relevancia (una categoría con presencia local se aplicó, una sin presencia local se omitió sin abortar el resto del archivo).

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
