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
