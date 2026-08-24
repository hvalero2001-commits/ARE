# Changelog

Todos los cambios relevantes de ARE (Abuse Reputation Engine) serán documentados en este archivo.

El proyecto sigue un versionado basado en versiones estables.

---

# v2.4.0

**Fecha:** 2026-08-23

## Resumen

Versión enfocada en completar el modelo de reputación extensible y, sobre todo, en corregir la instalación remota para que funcione realmente de punta a punta — la versión anterior la había dado por validada sin haberla probado nunca sin intervención manual.

## Modelo de reputación extensible completo

Cuarta y última fase de la migración iniciada en v2.1: las columnas de categoría redundantes en `reputation` (y `total_score`, derivada) eliminadas por completo. El score por categoría vive únicamente en `reputation_scores` desde entonces.

* Instalaciones nuevas ya no crean las columnas redundantes, en ninguna versión de SQLite — la limitación real solo aplicaba a eliminarlas de una base ya existente.
* Seis funciones de estadísticas reescritas para calcular sobre el esquema normalizado.

## Instalación remota corregida de fondo

Encontrado al validar por primera vez una instalación genuinamente limpia, sin ningún comando manual entre el instalador y la verificación, en dos distros distintas.

* El Installer nunca creaba los conjuntos IPSet ni las reglas de firewall — dependía en silencio de que alguien ejecutara `are.sh` manualmente después de instalar.
* Cuatro unidades de systemd tenían una dependencia dura sobre servicios externos (Fail2Ban, Exim) que pueden legítimamente no estar instalados — un servidor de correo puro, sin Fail2Ban, quedaba con la instalación rota.
* `reputation_scores` no se creaba en una instalación nueva sin datos previos.

## Desinstalación simplificada

`uninstall` elimina Core, datos y logs sin conservar nada por defecto — quien quiera preservar información lo hace por su cuenta antes de desinstalar.

## Correcciones

* `are.sh` no verificaba privilegios de root — una corrida sin `sudo` fallaba en silencio, sin ningún mensaje.

## Documentación

Contradicción real entre `PHILOSOPHY.md` y `PROJECT.md`, cada uno con su propia lista de "principios" del proyecto, sin apenas superposición entre ambas — corregida: `PHILOSOPHY.md` queda como fuente única, `PROJECT.md` la referencia en vez de duplicarla.

## Nota de proceso

Esta versión existe en gran parte porque la instalación remota, dada por cerrada y documentada en v2.3.0, nunca se había probado realmente de punta a punta. Cada validación anterior incluyó comandos manuales durante las pruebas, ocultando fallas reales del Installer. El tag `v2.3.0` se corrigió y republicó varias veces el mismo día en que se descubrió esto, antes de decidir formalizar el trabajo pendiente como esta versión.

## Compatibilidad

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.3.0

**Fecha:** 2026-08-23

## Resumen

Versión enfocada en administración operativa de sensores desde ARE ADMIN, cierre de la línea de auto-actualización del Installer Engine, y una ronda de correcciones de producción con impacto real confirmado y revertido.

## Activar/desactivar sensores

ARE ADMIN incorpora control operativo directo sobre cada sensor, con registro dinámico — un sensor nuevo aparece solo en el menú, sin código adicional.

* Sensores de polling (Fail2Ban, SpamAssassin): activar/desactivar controla directamente su timer de systemd.
* Sensor de callback (apache_evasive): activar/desactivar mediante archivo flag, sin tocar la configuración externa de Apache/mod_evasive.
* Auto-provisión de perfiles al habilitar SpamAssassin, idempotente.
* Nueva vista: jails de Fail2Ban con actividad real que todavía no tienen perfil administrado — solo lectura, sin creación automática de categoría ni peso.

## Cierre de la línea de auto-actualización

El Installer Engine completa su camino hacia la independencia de git: consulta de actualizaciones disponibles, actualización remota de una instalación existente, y auto-instalación de dependencias del sistema faltantes.

## Visibilidad ampliada

Detección automática de anomalías en las tendencias diarias por categoría, comparando la actividad del día contra el promedio reciente — sin instrumentación nueva, reutilizando datos ya existentes.

## Correcciones

* Workflow de publicación de release fallaba si la Release de GitHub no existía previamente.
* Extracción del paquete de instalación remota fallaba en servidores con /tmp montado sin permiso de ejecución.
* El sensor de SpamAssassin podía reprocesar el mismo tramo del log ante corridas solapadas, inflando la reputación de una IP.
* Revertir una sanción no persistía el cambio en el estado de sanciones, exponiendo a que se reaplicara tras un reinicio del sistema.
* El sensor de SpamAssassin delegaba en el veredicto interno de la herramienta en vez de decidir por su propio criterio de riesgo, perdiendo eventos reales con score por encima del umbral configurado.

## Documentación

Cierre de una tarea de sincronización de umbrales documentados, resuelta de forma incidental en una versión anterior sin que quedara registrado en su momento. Patrón de referencia documentado para futuros sensores de IDS externos.

## Compatibilidad

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.2.0

**Fecha:** 2026-08-21

## Resumen

Versión enfocada en incorporar una nueva fuente de datos real al modelo de reputación, completar el catálogo de categorías, y resolver la fricción de distribución del producto hacia otros servidores de la flota.

## Sensor SpamAssassin

Primera categoría heurística de la línea v2.2. `SOCIAL` cuenta ahora con un sensor real, alimentado por scores de SpamAssassin sobre tráfico de correo saliente, clasificados en tres bandas de severidad calibradas por jail_profile.

* Arquitectura por adaptador de MTA — único adaptador implementado y validado: Exim. Sumar otro MTA es agregar una función, no reescribir el sensor.
* Automatización vía systemd timer, con dependencia explícita del servicio de correo real en vez del genérico usado por el resto de los sensores.
* `policy/rules/social.sh`, existente desde una fase anterior del proyecto sin umbral definido, queda activo por primera vez.

## Catálogo de categorías completo

Las 9 categorías del modelo de reputación cuentan ahora con umbral definido — incluida `MALWARE`, calibrada de forma proactiva pese a no contar con sensor local, como decisión consciente de motor genérico: útil para cualquier servidor con superficie de malware real, no solo el propio.

## Visibilidad temporal ampliada

La vista de tendencias diarias, incorporada en la versión anterior, se extiende con desglose por categoría y exportación a CSV — sin instrumentación nueva, reutilizando exclusivamente los datos ya existentes.

* El desglose por categoría reveló picos de actividad reales previamente indetectables, correlacionados con ventanas de exposición directa sin protección de borde.

## Empaquetado y distribución

El motor de instalación, existente desde versiones anteriores, incorpora su primera capa de distribución real.

* Script de empaquetado que genera un artefacto distribuible a partir del manifiesto del producto, con verificación de integridad.
* Automatización de la generación y publicación del paquete en cada versión etiquetada.
* Instalación remota de una sola línea, sin depender de clonar el repositorio.

## Correcciones

* Observación de sincronización entre Fail2Ban y el motor de decisión, abierta desde una versión temprana del proyecto, cerrada con evidencia acumulada de operación real sostenida.
* Manifiesto del producto incompleto tras la incorporación del sensor de SpamAssassin: dos archivos quedaban sin permiso de ejecución en una instalación nueva — corregido y verificado antes de afectar ninguna instalación real.

## Documentación

Revisión de consistencia entre entradas del historial técnico: reordenamiento de una entrada fuera de secuencia, cierre de pendientes ya resueltos que seguían documentados como abiertos, y sincronización del número de versión entre las distintas fuentes del dato.

## Compatibilidad

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync.

---

# v2.1.0

**Fecha:** 2026-08-20

## Resumen

Versión de consolidación estructural sobre v2.0. Incorpora administración de perfiles entre servidores, un modelo de reputación por categoría extensible sin migración de esquema, visibilidad temporal de la actividad del sistema, persistencia del Firewall Backend a través de reinicios, un segundo patrón de sensor formalizado, y una revisión completa de la documentación del proyecto.

## Administración de perfiles entre servidores

Se incorpora exportación e importación de `jail_profile` desde ARE ADMIN, permitiendo replicar la calibración de perfiles entre servidores sin recrearlos manualmente.

* Exportación con nombre de archivo generado automáticamente, sin sobrescribir backups anteriores.
* Importación con selección de archivo por lista numerada y resolución de conflictos en un único paso (sobrescribir o conservar).
* Ambas operaciones auditadas.

## Modelo de reputación extensible

El almacenamiento de reputación por categoría transiciona de columnas fijas en la tabla `reputation` hacia un esquema normalizado, `reputation_scores`, donde incorporar una categoría nueva es una operación de datos y no una migración de estructura ni de código.

* Funciones de lectura y escritura reescritas sobre el nuevo esquema, validadas en producción sin cambio de comportamiento observable.
* `db_add_score()` reemplaza nueve ramas de asignación por categoría por una única sentencia genérica.
* `total_score` se deriva siempre como suma de las categorías, eliminando estructuralmente la posibilidad de que se desincronice del dato real.
* El Decay Engine redistribuye la reducción proporcionalmente entre categorías, en lugar de truncar cada una de forma independiente.

## Segundo sensor: patrón callback

`apache_evasive.sh` se formaliza como sensor oficial del framework, invocado directamente por Apache/`mod_evasive` en el instante del evento, junto al patrón de polling ya existente (Fail2Ban).

## Visibilidad temporal

Primera vista temporal del sistema: tendencias diarias de actividad (eventos, bans, IPs distintas por día).

## Firewall Backend persistente

* Restauración automática del estado del firewall (`ipset`) desde la base de datos al arrancar el sistema, preservando el tiempo restante exacto de sanciones temporales activas — antes, un reinicio del servidor podía perder sanciones activas sin cumplir su plazo.
* Corrección de un límite de rango no controlado en `ipset`, que impedía aplicar correctamente sanciones de larga duración.

## Policy Engine basado en categorías

* Cada categoría cuenta con una regla propia, con umbral configurable en `policy.conf`.
* Se incorpora un multiplicador de riesgo por reincidencia, aplicado a IPs en estado de observación o sanción activa.
* La decisión final nunca es menos estricta que la evaluación por score total, preservando como piso de seguridad el comportamiento ya validado del motor anterior.
* Se incorpora un comando de comparación entre motores, para validar el comportamiento del motor nuevo contra datos reales antes de aplicarlo en producción.

## Integración de mod_evasive

La protección anti-flood de Apache (`mod_evasive`) pasa a reportar a ARE como categoría DOS, incorporando reputación acumulable, recuperación gradual mediante Decay y escalado de sanciones mediante Ban Lifecycle, en reemplazo de un bloqueo de duración fija.

## Consolidación del Policy Engine

Se elimina el código de generaciones anteriores del Policy Engine que había quedado sin uso tras la incorporación del motor basado en categorías.

## Compatibilidad

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity.

---

# v2.0.0

**Fecha:** 2026-08-15

## Resumen

Segunda versión mayor de ARE.

La versión 2.0 consolida la identidad propia del producto, abandona la estructura histórica de `f2b-ipset` y establece `/opt/are` como instalación oficial de ARE. Incorpora además la interfaz de administración ARE ADMIN, un motor de decisión basado en evaluación de riesgo por categoría, y la integración de la protección anti-flood de Apache al modelo de reputación de ARE.

## Estructura del producto

La estructura oficial queda definida mediante `manifest/product.sh`.

Componentes principales:

* `/opt/are` — producto;
* `/opt/are/config` — configuración;
* `/var/lib/are` — datos persistentes;
* `/var/log/are` — logs;
* `/usr/local/sbin` — enlaces ejecutables;
* `/etc/systemd/system` — servicios;
* `/etc/logrotate.d` — configuración logrotate.

La base de datos operativa queda establecida en:

```text
/var/lib/are/are.db
```

## Product Manifest

`manifest/product.sh` se establece como definición oficial de los componentes administrados por ARE.

Define:

* nombre del producto;
* versión;
* estructura;
* archivos;
* configuración;
* datos persistentes;
* servicios;
* enlaces ejecutables;
* ejecutables;
* logrotate;
* exclusiones.

La versión del producto queda establecida en `2.0.0`.

## Installer Engine

El Installer Engine administra:

* `install`;
* `upgrade`;
* `repair`;
* `verify`;
* `uninstall`.

`install`, `upgrade` y `repair` utilizan el mismo Installer Core.

Las operaciones utilizan `manifest/product.sh` como fuente de los componentes administrados por ARE.

## Enlaces oficiales

Se establecen los enlaces:

```text
/usr/local/sbin/are
/usr/local/sbin/are-installer
/usr/local/sbin/are-fail2ban-sensor
```

El comando principal queda definido como:

```text
/usr/local/sbin/are -> /opt/are/are.sh
```

## Datos persistentes

ARE v2 utiliza:

```text
/var/lib/are/are.db
```

La base contiene:

* `hosts`;
* `events`;
* `config`;
* `jails`;
* `reputation`;
* `jail_profile`;
* `sanction_state`.

La estructura persistente se separa del Core del producto.

## Reputation Engine

Se mantiene el modelo de reputación incorporado en v1.1.

Categorías:

* RECON;
* EXPLOIT;
* CREDENTIAL;
* PROTOCOL;
* BOT;
* ANOMALY;
* MALWARE;
* DOS;
* SOCIAL.

## Reputation Decay

Se incorpora el ciclo operativo de Reputation Decay mediante systemd.

Unidades:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

El servicio ejecuta las fases:

* dry-run;
* apply.

El mecanismo utiliza:

```text
MIN_AGE=86400
FACTOR=0.95
```

La ejecución programada fue verificada con finalización satisfactoria.

## Fail2Ban Sensor

Se mantiene el Sensor Framework con el sensor oficial de Fail2Ban.

Eventos procesados:

* `FOUND`;
* `EXTERNAL_UNBAN`.

El sensor utiliza offset persistente y permite ejecución en modo dry-run o execute.

## Compatibilidad

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity.

---

# v1.1.0

**Fecha:** 2026-07

## Resumen

Primera versión enfocada en consolidar el ciclo de vida operativo del producto.

La versión 1.1 incorpora el Installer Engine, el Sensor Framework, la ampliación del modelo de reputación y diversas mejoras arquitectónicas sin modificar el núcleo de decisión de ARE.

---

## Nuevas funcionalidades

### Installer Engine

Se incorpora el Installer Engine con las operaciones:

* install
* upgrade
* repair
* verify
* uninstall

Características principales:

* detección automática del estado de instalación;
* protección de la configuración persistente;
* conservación de los datos persistentes;
* validación de la instalación;
* desinstalación conservando configuración, datos y logs;
* reutilización de un Installer Core común entre las operaciones de instalación, actualización y reparación.

Las operaciones `install`, `upgrade` y `repair` requieren que el Core utilizado como fuente sea distinto del directorio de instalación activa.

El mecanismo actual no incorpora generación, descarga, extracción ni staging automático de paquetes externos.

---

### Sensor Framework

Se incorpora la primera implementación oficial del Sensor Framework.

Sensor disponible:

* Fail2Ban Sensor

Eventos procesados:

* `FOUND`
* `EXTERNAL_UNBAN`

El sensor permite procesar eventos nuevos de Fail2Ban mediante un archivo de offset persistente.

El procesamiento puede ejecutarse en modo `--dry-run` o `--execute`.

El framework permite incorporar nuevos sensores sin modificar el núcleo de ARE.

---

### Reputation Engine

Ampliación del modelo de reputación.

Categorías soportadas:

* RECON
* EXPLOIT
* CREDENTIAL
* PROTOCOL
* BOT
* ANOMALY
* MALWARE
* DOS
* SOCIAL

---

### Dashboard

Mejoras incorporadas:

* TOP JAILS
* visualización de todas las categorías
* mejoras estadísticas
* separación entre eventos y reputación
* mejoras operativas

---

### Manifest del producto

Se incorpora `manifest/product.sh` como definición oficial de los componentes administrados por ARE.

Centraliza:

* estructura del producto;
* archivos;
* directorios;
* configuración;
* servicios;
* enlaces;
* ejecutables;
* exclusiones;
* componentes persistentes.

---

### Installer Manifest

El Installer Engine utiliza el Manifest como referencia de los componentes administrados por el producto.

Se elimina la duplicación de listas internas.

---

## Mejoras

* consolidación del ciclo de vida operativo del producto;
* separación entre Core, configuración y datos persistentes;
* enlaces oficiales persistentes;
* conservación de configuración durante las operaciones de mantenimiento;
* reutilización del Installer Core;
* validación automática posterior a las operaciones de instalación, actualización y reparación.

---

## Correcciones

* corrección del cálculo de `total_score`;
* corrección de categorías de reputación;
* reorganización del Dashboard;
* reorganización del Backend;
* limpieza del proceso de inicialización;
* eliminación de duplicaciones del Installer;
* conservación de configuración durante upgrades;
* manejo de instalaciones incompletas mediante la operación `repair`.

---

## Arquitectura

La arquitectura permanece basada en:

* Sensor Framework;
* Reputation Engine;
* State Engine;
* Policy Engine;
* Firewall Backend.

Se incorpora oficialmente el Installer Engine como responsable del ciclo de vida del producto.

---

## Compatibilidad

* Linux
* SQLite
* IPSet
* iptables
* ip6tables
* systemd
* Fail2Ban
* ModSecurity

---

# v1.0.1

**Fecha:** 2026-07-05

## Resumen

Primera actualización de mantenimiento de ARE centrada en estabilizar el núcleo del sistema y completar el ciclo de vida de las direcciones IP.

## Nuevas funcionalidades

* Implementación completa del flujo `UNBAN`.
* Integración del backend con IPSet para eliminación de direcciones IP.
* Reorganización del Policy Engine.
* Centralización de la inicialización del backend.
* Reorganización de la documentación del proyecto.

## Correcciones

* Corregida la ausencia de `handle_unban()`.
* Eliminada la doble inicialización de IPSet y Firewall.
* Limpieza y modularización del backend.

## Arquitectura

* Reorganización del módulo `policy/rules/`.
* Separación del proceso de inicialización del backend.

---

# v1.0.0

**Fecha:** 2026-07-05

## Resumen

Primera versión estable de ARE.

## Funcionalidades principales

* Reputation Engine.
* State Engine.
* Policy Engine.
* Firewall Backend basado en IPSet.
* Persistencia mediante SQLite.
* Dashboard.
* Integración con Fail2Ban.
* Integración con ModSecurity.
* Soporte IPv4 e IPv6.

## Estado

Versión inicial estable utilizada en producción.

---

## Licencia

GPL v3
