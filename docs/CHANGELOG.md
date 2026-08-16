# Changelog

Todos los cambios relevantes de ARE (Abuse Reputation Engine) serán documentados en este archivo.

El proyecto sigue un versionado basado en versiones estables.

---

# v2.0.0

**Fecha:** 2026-08-15

## Resumen

Segunda versión mayor de ARE.

La versión 2.0 consolida la identidad propia del producto, abandona la estructura histórica de `f2b-ipset` y establece `/opt/are` como instalación oficial de ARE.

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

## Systemd

ARE v2 administra mediante systemd sus componentes operativos, incluyendo:

```text
are-fail2ban-found.service
are-fail2ban-found.timer
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

## PATH

El Installer Engine configura `/usr/local/sbin` para el entorno de root durante:

* `install`;
* `upgrade`;
* `repair`.

La configuración se realiza de forma idempotente sobre:

```text
/root/.bash_profile
```

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

