# ARE Installation Guide

## Introducción

Este documento describe el ciclo de vida de instalación de ARE (Abuse Reputation Engine).

ARE v2 consolida la identidad y estructura propias del producto, sustituyendo la estructura histórica utilizada por `f2b-ipset` en v1.1. La estructura de instalación, los componentes administrados y sus ubicaciones son definidos por `manifest/product.sh`.

El Installer Engine administra las operaciones:

```text
install
upgrade
repair
verify
uninstall
```

Estas operaciones mantienen separadas el Core del producto, la configuración y los datos persistentes.

---

# Requisitos

ARE requiere un sistema Linux con:

* Bash
* SQLite 3
* IPSet
* systemd
* privilegios de `root`

Fail2Ban y ModSecurity son integraciones de ARE. No sustituyen las dependencias básicas verificadas directamente por el Installer.

Desde v2.3, si alguna dependencia obligatoria falta, el propio Installer la instala automáticamente usando el gestor de paquetes nativo del sistema (`apt-get`, `dnf` o `yum`, en ese orden de preferencia) — ver sección "Instalación remota" más abajo.

---

# Estructura de instalación

La estructura oficial de ARE v2 es:

```text
/opt/are
    Core y componentes del producto

/opt/are/config
    Configuración del producto

/var/lib/are
    Datos persistentes

/var/lib/are/are.db
    Base de datos de ARE

/var/log/are
    Logs

/usr/local/sbin
    Enlaces ejecutables oficiales

/etc/systemd/system
    Unidades systemd

/etc/logrotate.d
    Configuración de logrotate
```

Esta estructura forma parte de la definición oficial de ARE v2.

La base de datos persistente utilizada por ARE v2 es:

```text
/var/lib/are/are.db
```

La estructura incluye, entre otras, las tablas:

```text
hosts
events
config
jails
reputation
reputation_scores
jail_profile
sanction_state
```

`reputation_scores` almacena el score por categoría de forma normalizada, permitiendo incorporar categorías nuevas de reputación sin modificar el esquema de la base ni el código de las funciones de consulta.

Los datos históricos procedentes de la estructura anterior fueron incorporados a la nueva base persistente de ARE durante la evolución hacia v2.

---

# Product Manifest

El archivo:

```text
manifest/product.sh
```

es la referencia oficial utilizada por el Installer para determinar los componentes administrados por ARE.

El Manifest centraliza:

* identidad y versión del producto;
* estructura de instalación;
* configuración;
* datos persistentes;
* unidades systemd;
* enlaces ejecutables;
* archivos ejecutables;
* configuración de logrotate;
* exclusiones.

El Installer utiliza los valores definidos por el Manifest en lugar de mantener una segunda definición independiente de la estructura del producto.

---

# Árbol fuente

Las operaciones de instalación, actualización y reparación utilizan el árbol fuente que contiene `are-installer`.

El árbol fuente debe ser diferente del destino instalado.

Esto permite que una actualización copie el Core de una versión fuente sobre una instalación existente sin utilizar la instalación activa como origen.

Si el árbol fuente y el destino resuelven al mismo directorio, la operación debe finalizar con error.

---

# Instalación inicial

La instalación se ejecuta mediante:

```bash
are-installer install
```

La operación corresponde a una instalación nueva.

El flujo general es:

```text
Verificar root
       |
       v
Verificar dependencias
       |
       v
Preparar entorno
       |
       v
Detectar estado
       |
       v
Crear estructura
       |
       v
Instalar Core
       |
       v
Instalar configuración inicial
       |
       v
Crear enlaces oficiales
       |
       v
Aplicar permisos
       |
       v
Inicializar base de datos
       |
       v
Preparar logging
       |
       v
Instalar systemd
       |
       v
Instalar logrotate
       |
       v
Validar instalación
```

La operación `install` solo corresponde a una instalación nueva.

Si ARE ya está instalado, debe utilizarse:

```bash
are-installer upgrade
```

Si la instalación se encuentra incompleta, debe utilizarse:

```bash
are-installer repair
```

---

# Instalación remota

Desde v2.3, ARE no requiere clonar el repositorio con git para instalarse. Un servidor nuevo, sin ningún archivo de ARE presente, puede instalarse con un único comando:

```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash
```

El `sudo` va al final del pipe (aplicado a `bash`, no a `curl`) — de otro modo, el privilegio de root no le llega al script que efectivamente ejecuta la instalación.

Este bootstrap (`scripts/install.sh`):

1. consulta la API de GitHub por la última release publicada (o una versión específica, vía la variable de entorno `ARE_VERSION`);
2. descarga el paquete `.tar.gz` correspondiente;
3. verifica su checksum (`.sha256`);
4. lo extrae a un directorio temporal;
5. delega en `are-installer install` desde ese árbol extraído.

El mismo mecanismo sirve para actualizar una instalación existente:

```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash -s -- upgrade
```

o, de forma equivalente, desde una instalación ya activa:

```bash
are-installer upgrade --remote
```

que internamente delega en el mismo bootstrap, sin duplicar la lógica de descarga y verificación.

## Consultar si hay una versión más nueva

Sin descargar ni modificar nada, de solo lectura:

```bash
are-installer check-updates
```

Compara la versión instalada (`PRODUCT_VERSION`, leída del propio manifiesto activo) contra la última release publicada, e informa si hay una más reciente disponible.

## Dependencias faltantes

El auto-instalador de dependencias (ver sección "Requisitos") actúa automáticamente, sin preguntar, durante `install`, `upgrade` y `repair` — tanto por el camino remoto como por el árbol fuente local. `bash` y `systemctl` quedan fuera de este mecanismo: su ausencia implicaría un sistema en un estado que requiere intervención manual, no una instalación automática a ciegas.

---

# Configuración inicial

La configuración forma parte del área administrada por el producto pero se mantiene separada del Core operativo.

Durante una instalación inicial se crean los archivos de configuración definidos por el Manifest.

Una configuración existente no debe ser reemplazada arbitrariamente durante las operaciones de mantenimiento.

La separación entre Core, configuración y datos persistentes es uno de los principios establecidos para ARE v2.

---

# Enlaces ejecutables

ARE v2 proporciona los siguientes comandos oficiales:

```text
are
are-installer
are-fail2ban-sensor
```

Los enlaces son administrados por el Product Manifest.

El comando principal queda establecido como:

```text
/usr/local/sbin/are -> /opt/are/are.sh
```

El Installer también garantiza la disponibilidad de `/usr/local/sbin` en el `PATH` de `root` durante las operaciones:

```text
install
upgrade
repair
```

La modificación del `PATH` se realiza de forma idempotente.

**Nota:** esta modificación del `PATH` se aplica al archivo `/root/.bash_profile`, y solo la leen automáticamente las sesiones de terminal **nuevas** que se abran después de la instalación (un nuevo `ssh`, por ejemplo). Una terminal que ya estaba abierta antes de instalar/actualizar ARE no recarga su `PATH` en memoria sola; requiere `source /root/.bash_profile` manual, o simplemente abrir una sesión nueva.

---

# Actualización

La actualización se ejecuta mediante:

```bash
are-installer upgrade
```

La operación requiere una instalación existente.

El árbol fuente utilizado para la actualización debe corresponder a la versión que se desea instalar y debe ser diferente del árbol instalado.

El proceso actualiza los componentes administrados por el Manifest y conserva los datos persistentes.

El objetivo de `upgrade` es actualizar el Core sin sustituir arbitrariamente:

```text
configuración
base de datos
reputación histórica
estado persistente
```

ARE v2 define explícitamente `upgrade` como la operación destinada a actualizar una instalación existente manteniendo los datos persistentes.

Alternativamente, `are-installer upgrade --remote` realiza la misma operación sin necesitar un árbol fuente local — ver sección "Instalación remota". **Advertencia:** esta variante no compara la versión instalada contra la disponible antes de actuar; aplica siempre la última release publicada, lo que puede downgradear una instalación en una rama de desarrollo más nueva. Verificar con `are-installer check-updates` antes de usar `--remote` si existe esa duda.

---

# Reparación

La reparación se ejecuta mediante:

```bash
are-installer repair
```

Está destinada a una instalación existente que no satisface las condiciones requeridas para considerarse completa.

El objetivo es reconstruir los componentes administrados que sean necesarios para recuperar una instalación funcional.

La reparación conserva la información persistente del sistema.

No debe utilizarse `repair` como sustituto de `upgrade` cuando existe una instalación completa.

---

# Verificación

La verificación se ejecuta mediante:

```bash
are-installer verify
```

La operación determina primero el estado de la instalación.

Una instalación válida debe disponer de los componentes requeridos por el Product Manifest y de los elementos necesarios para su funcionamiento.

La verificación comprueba, según corresponda:

* integridad de componentes;
* enlaces oficiales;
* comandos ejecutables;
* permisos;
* base de datos;
* conjuntos IPSet;
* unidades systemd;
* configuración de logrotate;
* ejecución funcional del runtime.

La validación de una instalación no modifica deliberadamente su configuración ni sus datos persistentes.

---

# Systemd

ARE v2 utiliza systemd para integrar componentes operativos del producto.

El mecanismo de Reputation Decay forma parte del ciclo operativo de v2 mediante:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

El servicio ejecuta las fases:

```text
dry-run
apply
```

La restauración del Firewall Backend al arrancar el sistema, incorporada en v2.1, se ejecuta una única vez por arranque mediante:

```text
are-restore-ipsets.service
```

Este servicio repuebla los conjuntos IPSet a partir de la base de datos, ya que IPSet no conserva su contenido de forma nativa entre reinicios.

El Installer administra las unidades declaradas por el Product Manifest.

---

# Fail2Ban

ARE mantiene el Sensor Framework para la integración con Fail2Ban.

Los eventos procesados por el sensor son:

```text
FOUND
EXTERNAL_UNBAN
```

El sensor utiliza un offset persistente para procesar nuevos eventos, y valida cada jail dinámicamente contra `jail_profile`.

La integración con Fail2Ban permite que los eventos externos sean incorporados al flujo operativo de ARE sin convertir Fail2Ban en el mecanismo central de reputación del producto.

---

# Desinstalación

La desinstalación se ejecuta mediante:

```bash
are-installer uninstall
```

Su objetivo es retirar los componentes administrados por ARE del sistema.

La operación elimina los componentes del Core, enlaces ejecutables, unidades systemd y configuración de logrotate administrados por el producto.

Los datos persistentes no forman parte de la eliminación normal del Core.

Por tanto, la desinstalación conserva separadamente:

```text
configuración
datos persistentes
base de datos
reputación histórica
logs
```

La separación entre software instalado y datos persistentes permite retirar ARE sin eliminar automáticamente información histórica del sistema.

---

# Evolución desde v1.1

ARE v2 nace sobre la base funcional desarrollada en la rama v1.1.

La rama v1.1 incorporó el Sensor Framework inicial para Fail2Ban y consolidó el modelo de reputación que posteriormente continúa en v2.

La evolución hacia v2 cambia principalmente la identidad y estructura operativa del producto:

```text
ARE v1.1
    |
    | estructura histórica f2b-ipset
    v
ARE v2.0
    |
    +-- /opt/are
    +-- /opt/are/config
    +-- /var/lib/are
    +-- /var/log/are
    +-- Product Manifest
    +-- Installer Engine
    +-- Reputation Decay
    +-- ARE ADMIN
```

La versión 2.0 establece oficialmente `/opt/are` como Core del producto y `/var/lib/are` como ubicación de datos persistentes.

---

# Uso

## Instalar

Desde un árbol fuente independiente:

```bash
are-installer install
```

O de forma remota, sin git ni árbol fuente local (ver "Instalación remota"):

```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash
```

## Actualizar

Desde el árbol fuente de la versión que se desea instalar:

```bash
are-installer upgrade
```

O de forma remota:

```bash
are-installer upgrade --remote
```

## Reparar

Desde un árbol fuente válido:

```bash
are-installer repair
```

## Verificar

```bash
are-installer verify
```

## Consultar actualizaciones disponibles

```bash
are-installer check-updates
```

## Desinstalar

```bash
are-installer uninstall
```

---

# Principio de mantenimiento

El Installer Engine mantiene separadas tres áreas:

```text
Core del producto
       |
       +---- configuración
       |
       +---- datos persistentes
```

Las operaciones de mantenimiento deben actuar únicamente sobre los componentes correspondientes a la operación solicitada.

El Product Manifest constituye la referencia única de los componentes administrados por el Installer, mientras que la información persistente permanece separada del Core.

ARE v2 continúa así la evolución iniciada en v1.1 sin confundir la documentación del Installer con la documentación interna de implementación del script.
