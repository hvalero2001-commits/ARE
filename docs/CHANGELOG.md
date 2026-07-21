# Changelog

Todos los cambios relevantes de ARE (Abuse Reputation Engine) se documentan en este archivo.

ARE sigue versionado semántico para versiones estables y ramas de desarrollo controladas.

---

# v1.1.0

**Fecha:** 2026-07

## Resumen

Primera versión enfocada en consolidar el ciclo de vida completo del producto.

La versión 1.1 incorpora el Installer Engine, el Sensor Framework, la ampliación del modelo de reputación y diversas mejoras arquitectónicas sin modificar el núcleo de decisión de ARE.

---

## Nuevas funcionalidades

### Installer Engine

Se incorpora el ciclo de vida completo del producto mediante:

- install
- upgrade
- repair
- verify
- uninstall

Características principales:

- detección automática del estado de instalación;
- protección de la configuración persistente;
- actualización segura;
- reparación automática de instalaciones incompletas;
- validación final;
- desinstalación conservando configuración, datos y logs.

---

### Sensor Framework

Se incorpora la primera implementación oficial del Sensor Framework.

Sensor disponible:

- Fail2Ban Sensor (`FOUND`)

El framework permite incorporar nuevos sensores sin modificar el núcleo de ARE.

---

### Reputation Engine

Ampliación del modelo de reputación.

Nuevas categorías:

- ANOMALY
- MALWARE
- DOS
- SOCIAL

Categorías soportadas:

- RECON
- EXPLOIT
- CREDENTIAL
- PROTOCOL
- ANOMALY
- MALWARE
- DOS
- SOCIAL

---

### Dashboard

Mejoras incorporadas:

- TOP JAILS
- visualización de todas las categorías
- mejoras estadísticas
- separación entre eventos y reputación
- mejoras operativas

---

### Manifest del producto

Se incorpora `manifest/product.sh` como definición oficial del paquete.

Centraliza:

- estructura del producto;
- archivos;
- directorios;
- configuración;
- servicios;
- enlaces;
- ejecutables;
- exclusiones;
- componentes persistentes.

---

### Installer Manifest

El Installer Engine pasa a utilizar el Manifest como única fuente de información del paquete.

Se elimina la duplicación de listas internas.

---

## Mejoras

- consolidación del ciclo de vida del producto;
- separación definitiva entre Core y configuración;
- enlaces oficiales persistentes;
- instalación idempotente;
- upgrade seguro;
- repair reutilizando el mismo Installer Core;
- validación automática posterior a cada operación.

---

## Correcciones

- corrección del cálculo de `total_score`;
- corrección de categorías de reputación;
- reorganización del Dashboard;
- reorganización del Backend;
- limpieza del proceso de inicialización;
- eliminación de duplicaciones del Installer;
- conservación de configuración durante upgrades;
- restauración automática de instalaciones incompletas.

---

## Arquitectura

La arquitectura permanece basada en:

- Sensor Framework;
- Reputation Engine;
- State Engine;
- Policy Engine;
- Firewall Backend.

Se incorpora oficialmente el Installer Engine como responsable del ciclo de vida del producto.

---

## Compatibilidad

- Linux
- SQLite
- IPSet
- iptables
- ip6tables
- systemd
- Fail2Ban
- ModSecurity

---

# v1.0.1

**Fecha:** 2026-07-05

## Resumen

Primera actualización de mantenimiento de ARE centrada en estabilizar el núcleo del sistema y completar el ciclo de vida de las direcciones IP.

## Nuevas funcionalidades

- implementación completa del flujo `UNBAN`;
- integración del Backend con IPSet para eliminación de direcciones IP;
- reorganización del Policy Engine;
- centralización de la inicialización del Backend;
- reorganización de la documentación.

## Correcciones

- incorporación de `handle_unban()`;
- eliminación de inicializaciones duplicadas del Backend;
- limpieza y modularización del código.

---

# v1.0.0

**Fecha:** 2026-07-05

## Resumen

Primera versión estable de ARE.

## Funcionalidades principales

- Reputation Engine;
- State Engine;
- Policy Engine;
- Firewall Backend;
- SQLite;
- Dashboard;
- integración con Fail2Ban;
- integración con ModSecurity;
- soporte IPv4 e IPv6.

## Estado

Primera versión estable utilizada en producción.

---

## Licencia

GPL-3.0
