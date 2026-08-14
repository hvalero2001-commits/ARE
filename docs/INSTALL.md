# ARE Installation Guide

## Introducción

Este documento describe el ciclo de vida de instalación de ARE (Abuse Reputation Engine) y el comportamiento implementado por `are-installer`.

El Installer Engine forma parte del árbol del proyecto y utiliza `manifest/product.sh` como definición de los componentes administrados.

Las operaciones disponibles son:

* `install`
* `upgrade`
* `repair`
* `verify`
* `uninstall`

El Installer trabaja directamente sobre un árbol fuente de ARE. El árbol fuente debe ser diferente del directorio de instalación activo.

---

# Requisitos

## Sistema operativo

* Linux

## Dependencias

El Installer verifica la disponibilidad de:

* Bash
* SQLite 3
* IPSet
* iptables
* ip6tables
* systemd

Las dependencias se verifican antes de las operaciones que requieren ejecutarlas.

---

# Permisos

Las operaciones del Installer requieren privilegios de `root`.

El Installer rechaza la ejecución cuando el usuario efectivo no es `root`.

---

# Estructura de instalación

La ubicación oficial definida por `manifest/product.sh` es:

```text
/opt/f2b-ipset
```

## Core

```text
/opt/f2b-ipset
```

Contiene el código y los componentes distribuidos de ARE.

---

## Configuración

```text
/etc/f2b-ipset
```

Contiene:

```text
config.conf
policy.conf
whitelist.conf
```

Estos archivos representan configuración persistente del administrador.

Durante una instalación inicial se crean desde las plantillas presentes en el Core.

Cuando ya existen, el Installer las conserva.

---

## Datos persistentes

```text
/var/lib/f2b-ipset
```

Contiene:

```text
f2b.db
```

La base de datos contiene la información persistente utilizada por ARE.

---

## Logs

```text
/var/log/are
```

Archivo principal:

```text
/var/log/are/are.log
```

---

## Ejecutables

Los enlaces oficiales se crean en:

```text
/usr/local/sbin
```

Enlaces:

```text
are
are-installer
are-fail2ban-sensor
```

Los destinos son:

```text
/opt/f2b-ipset/f2b-ipset.sh
/opt/f2b-ipset/are-installer
/opt/f2b-ipset/sensors/fail2ban.sh
```

---

## systemd

Las unidades administradas por el Installer son:

```text
/etc/systemd/system/are-fail2ban-found.service
/etc/systemd/system/are-fail2ban-found.timer
```

Durante la instalación se configura systemd mediante:

```bash
systemctl daemon-reload
systemctl enable --now are-fail2ban-found.timer
```

---

## logrotate

La configuración administrada se instala en:

```text
/etc/logrotate.d/are
```

---

# Manifest del producto

La definición oficial de los componentes administrados por el Installer se encuentra en:

```text
manifest/product.sh
```

El Manifest define:

* información del producto;
* directorios;
* archivos;
* configuración;
* unidades systemd;
* enlaces ejecutables;
* datos persistentes;
* archivos ejecutables;
* configuración de logrotate;
* componentes excluidos.

El Manifest constituye la referencia utilizada por el Installer para determinar qué componentes debe administrar.

---

# Árbol fuente

El Installer determina automáticamente el árbol fuente a partir de la ubicación real del propio `are-installer`.

Internamente utiliza:

```bash
SOURCE_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
```

Por tanto, el árbol que contiene `are-installer` constituye la fuente utilizada para copiar los componentes del producto.

El destino de instalación se obtiene del Manifest mediante:

```text
PRODUCT_HOME
```

Actualmente:

```text
/opt/f2b-ipset
```

El Installer verifica que el árbol fuente y el destino de instalación sean diferentes.

No está permitido utilizar directamente:

```text
/opt/f2b-ipset
```

como fuente para actualizar o copiar sobre:

```text
/opt/f2b-ipset
```

Cuando ambos directorios resuelven al mismo árbol, la operación finaliza con error.

---

# Detección del estado

El Installer utiliza `install_detect_state()` para determinar el estado básico de la instalación.

Los estados posibles son:

## NEW

Se determina cuando no existen:

```text
/opt/f2b-ipset
/etc/f2b-ipset/config.conf
/var/lib/f2b-ipset
```

En este estado se permite:

```text
install
```

---

## INSTALLED

Se determina cuando existen:

```text
/opt/f2b-ipset
/etc/f2b-ipset/config.conf
/var/lib/f2b-ipset
/opt/f2b-ipset/f2b-ipset.sh
```

En este estado se permiten las operaciones correspondientes a una instalación existente.

---

## INCOMPLETE

Cualquier combinación intermedia de las condiciones anteriores se considera:

```text
INCOMPLETE
```

Este estado indica que la instalación no satisface las condiciones mínimas utilizadas por `install_detect_state()`.

---

# Operación install

La operación se ejecuta mediante:

```bash
are-installer install
```

El Installer:

```text
Verifica root
       │
       ▼
Verifica dependencias
       │
       ▼
Detecta estado
       │
       ▼
Crea directorios
       │
       ▼
Copia Core
       │
       ▼
Instala configuración
       │
       ▼
Crea enlaces
       │
       ▼
Asigna permisos
       │
       ▼
Inicializa SQLite
       │
       ▼
Prepara logging
       │
       ▼
Instala systemd
       │
       ▼
Instala logrotate
       │
       ▼
Valida instalación
```

La operación solo procede cuando el estado detectado es:

```text
NEW
```

Si ARE ya está instalado, el Installer indica utilizar:

```bash
are-installer upgrade
```

Si la instalación está incompleta, indica utilizar:

```bash
are-installer repair
```

---

# Operación upgrade

La operación se ejecuta mediante:

```bash
are-installer upgrade
```

La operación requiere que el estado sea:

```text
INSTALLED
```

El flujo implementado es:

```text
Verificar root
       │
       ▼
Verificar dependencias
       │
       ▼
Detectar instalación
       │
       ▼
Copiar Core desde SOURCE_DIR
       │
       ▼
Instalar configuración
       │
       ▼
Crear enlaces
       │
       ▼
Asignar permisos
       │
       ▼
Inicializar/completar SQLite
       │
       ▼
Preparar logging
       │
       ▼
Instalar systemd
       │
       ▼
Instalar logrotate
       │
       ▼
Validar instalación
```

El Core se copia desde el árbol fuente determinado por la ubicación de `are-installer`.

La configuración existente se conserva.

Los datos persistentes se mantienen en:

```text
/var/lib/f2b-ipset
```

Para ejecutar una actualización, `are-installer` debe ejecutarse desde un árbol fuente diferente de:

```text
/opt/f2b-ipset
```

---

# Operación repair

La operación se ejecuta mediante:

```bash
are-installer repair
```

La operación requiere que el estado sea:

```text
INCOMPLETE
```

El flujo implementado es:

```text
Verificar root
       │
       ▼
Verificar dependencias
       │
       ▼
Detectar instalación incompleta
       │
       ▼
Crear directorios
       │
       ▼
Copiar Core desde SOURCE_DIR
       │
       ▼
Instalar configuración
       │
       ▼
Crear enlaces
       │
       ▼
Asignar permisos
       │
       ▼
Inicializar/completar SQLite
       │
       ▼
Preparar logging
       │
       ▼
Instalar systemd
       │
       ▼
Instalar logrotate
       │
       ▼
Validar instalación
```

La operación utiliza el mismo mecanismo de copia del Core que `install` y `upgrade`.

La configuración existente se conserva.

Los datos persistentes no forman parte del Core reemplazable.

---

# Operación verify

La operación se ejecuta mediante:

```bash
are-installer verify
```

`verify` determina primero el estado de instalación.

Si el estado es:

```text
NEW
```

la operación informa que ARE no está instalado.

Si el estado es:

```text
INCOMPLETE
```

la operación informa que la instalación está incompleta.

Si el estado es:

```text
INSTALLED
```

realiza las verificaciones adicionales implementadas por el Installer.

---

## Verificación de integridad

Se comprueban los componentes declarados mediante:

```text
PRODUCT_DIRS
PRODUCT_FILES
PRODUCT_CONFIG_FILES
PRODUCT_DATA_FILES
```

---

## Verificación de enlaces

Se verifican:

* enlaces de configuración;
* enlaces ejecutables;
* existencia de los destinos;
* ausencia de enlaces rotos;
* correspondencia entre enlace y destino esperado.

---

## Verificación de comandos oficiales

Se verifica la existencia y ejecución de:

```text
/usr/local/sbin/are
/usr/local/sbin/are-installer
/usr/local/sbin/are-fail2ban-sensor
```

---

## Verificación de permisos

Se comprueba la existencia y accesibilidad de:

```text
f2b-ipset.sh
are-installer
sensors/fail2ban.sh
```

También se verifican los archivos de configuración y la base de datos.

---

## Verificación de base de datos

Se verifica la existencia de:

```text
/var/lib/f2b-ipset/f2b.db
```

y de las tablas requeridas:

```text
config
hosts
jails
events
jail_profile
reputation
sanction_state
```

---

## Verificación de IPSet

Se carga la configuración runtime y se verifica la existencia de los conjuntos:

```text
FILTER_SET4
FILTER_SET6
BAN_SET4
BAN_SET6
```

---

## Verificación de firewall

Se comprueba la existencia de las reglas correspondientes en:

```text
iptables
ip6tables
```

para los conjuntos IPv4 e IPv6 configurados.

---

## Verificación de systemd

Se verifica la existencia de las unidades declaradas en:

```text
PRODUCT_SYSTEMD_UNITS
```

Cuando el entorno corresponde al sistema real:

```text
/etc/systemd/system
```

también se verifica el estado de los timers.

---

## Verificación de logrotate

Se verifica la existencia de los archivos declarados mediante:

```text
PRODUCT_LOGROTATE_FILES
```

---

## Verificación de runtime

Finalmente se ejecuta:

```bash
/opt/f2b-ipset/f2b-ipset.sh stats
```

La ejecución debe finalizar correctamente.

---

# Operación uninstall

La operación se ejecuta mediante:

```bash
are-installer uninstall
```

Puede ejecutarse cuando el estado es:

```text
INSTALLED
```

o:

```text
INCOMPLETE
```

El Installer elimina los componentes administrados por el producto.

---

## Componentes eliminados

Se eliminan:

```text
/opt/f2b-ipset
```

Los enlaces oficiales:

```text
/usr/local/sbin/are
/usr/local/sbin/are-installer
/usr/local/sbin/are-fail2ban-sensor
```

Las unidades systemd declaradas.

La configuración de:

```text
/etc/logrotate.d/are
```

---

## Componentes conservados

La operación no elimina:

```text
/etc/f2b-ipset
/var/lib/f2b-ipset
/var/log/are
```

Por tanto, se conservan:

* configuración;
* base de datos;
* reputación;
* eventos;
* logs.

La eliminación de estos datos no forma parte de `uninstall` y permanece bajo control del administrador.

---

# Protección de configuración

La configuración instalada se administra mediante:

```text
/etc/f2b-ipset
```

Las plantillas originales se encuentran dentro del Core:

```text
/opt/f2b-ipset/templates/config
```

Durante una instalación inicial se copian desde las plantillas.

Cuando un archivo de configuración ya existe como archivo regular, `install_install_configs()` lo conserva.

Si existe como enlace simbólico válido, el Installer migra su contenido a un archivo regular persistente.

La configuración administrativa no se reemplaza durante una actualización normal del Core.

---

# Persistencia de datos

La información persistente se encuentra en:

```text
/var/lib/f2b-ipset
```

La base de datos:

```text
/var/lib/f2b-ipset/f2b.db
```

forma parte de los datos persistentes de ARE.

Las operaciones del Installer utilizan las funciones de base de datos para inicializar o completar la estructura necesaria sin sustituir arbitrariamente la base de datos existente.

---

# Arquitectura del Installer

El flujo general implementado es:

```text
                    are-installer
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       install        upgrade        repair
          │              │              │
          └──────────────┼──────────────┘
                         ▼
                  Installer Core
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       Manifest       Runtime       Persistence
          │              │              │
          ▼              ▼              ▼
      Componentes     systemd        SQLite
      del producto    firewall       datos
                     IPSet
```

Las funciones principales implementadas por el Installer incluyen:

```text
install_verify_root()
install_verify_dependencies()
install_detect_state()
install_create_directories()
install_copy_files()
install_install_configs()
install_create_links()
install_permissions()
install_database()
install_logging()
install_systemd()
install_logrotate()
install_validate()

install_verify_integrity()
install_verify_links()
install_verify_command_path()
install_verify_permissions()
install_verify_database()
install_verify_ipset()
install_verify_firewall()
install_verify_systemd()
install_verify_logrotate()
install_verify_runtime()
```

Las operaciones de alto nivel son:

```text
installer_install()
installer_upgrade()
installer_repair()
installer_verify()
installer_uninstall()
```

---

# Estado funcional del Installer

| Operación   | Estado       |
| ----------- | ------------ |
| `install`   | Implementada |
| `upgrade`   | Implementada |
| `repair`    | Implementada |
| `verify`    | Implementada |
| `uninstall` | Implementada |

El Installer utiliza el árbol fuente desde el que se ejecuta `are-installer` y copia sus componentes hacia el destino definido por el Manifest.

El árbol fuente y el destino deben ser diferentes.

---

# Principios del Installer

El Installer mantiene los siguientes principios:

* utilizar el Manifest como referencia de componentes;
* separar Core, configuración y datos persistentes;
* preservar la configuración existente;
* preservar los datos persistentes;
* evitar eliminación accidental de información persistente;
* reutilizar funciones comunes;
* validar la instalación;
* evitar lógica duplicada;
* trabajar sobre una fuente de Core diferente del destino instalado.

---

# Uso

## Verificar instalación

```bash
are-installer verify
```

## Instalar ARE

Desde un árbol fuente separado:

```bash
are-installer install
```

## Actualizar ARE

Desde el árbol fuente que contiene la versión que se desea instalar:

```bash
are-installer upgrade
```

## Reparar una instalación incompleta

Desde un árbol fuente válido:

```bash
are-installer repair
```

## Desinstalar ARE

```bash
are-installer uninstall
```

---

# Compatibilidad

La definición actual del Manifest establece:

```text
PRODUCT_VERSION="1.1.0"
```

La instalación utiliza:

* Linux;
* Bash;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity.

Fail2Ban y ModSecurity forman parte de las integraciones de ARE y no sustituyen las dependencias básicas verificadas directamente por el Installer.

La compatibilidad concreta depende de las características disponibles en el sistema donde ARE sea instalado.

---

# Principio final

La documentación del Installer debe reflejar las capacidades implementadas por el código.

ARE separa el Core instalado de la configuración y los datos persistentes.

Las operaciones de instalación, actualización y reparación utilizan un árbol fuente independiente del destino de instalación, mientras que `verify` comprueba el estado y los componentes instalados.

La configuración, la base de datos y los logs permanecen fuera del Core y reciben un tratamiento diferenciado durante las operaciones de mantenimiento.
