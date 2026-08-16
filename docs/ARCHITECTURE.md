# ARE Architecture

## Introducción

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para transformar eventos de seguridad en decisiones basadas en evidencia.

La arquitectura separa la observación de los eventos, la construcción de reputación, la evaluación del estado, la decisión de política y la ejecución de las acciones.

ARE v2.0 continúa esta arquitectura a partir de la base funcional y establecida en v1.1, incorporando la identidad propia del producto, una estructura operativa independiente de la implementación histórica de `f2b-ipset` y nuevos componentes necesarios para administrar el ciclo completo de reputación y sanciones.

La versión v1.1 constituye la última versión estable liberada. v2.0 se encuentra en desarrollo y validación sobre esa base.

---

# Arquitectura general

La arquitectura actual puede representarse mediante el siguiente flujo:

```text
                         FUENTES EXTERNAS
                               |
             +-----------------+-----------------+
             |                                   |
             v                                   v
        Fail2Ban                         Otras fuentes
             |                         (arquitectura extensible)
             v
       Sensor Framework
             |
             | eventos internos
             v
      +-------------------+
      | Reputation Engine |
      +---------+---------+
                |
                v
         +-------------+
         | State Engine|
         +------+------+
                |
                v
         +-------------+
         | Policy      |
         | Engine      |
         +------+------+
                |
                v
      +-------------------+
      | Ban Lifecycle     |
      | Engine            |
      +---------+---------+
                |
                v
      +-------------------+
      | Apply Engine      |
      +---------+---------+
                |
                v
      +-------------------+
      | Firewall Backend  |
      +---------+---------+
                |
                v
          IPSet / Firewall


       Reputation Decay
              |
              v
      Reputation Engine
              |
              v
        State Engine
              |
              v
        Policy Engine
```

El flujo representa la arquitectura funcional actual. Los componentes externos generan información; ARE procesa esa información y determina la respuesta; el backend ejecuta la acción correspondiente.

---

# Relación entre v1.1 y v2.0

v2.0 no constituye un sistema independiente de v1.1.

La nueva versión se construye sobre las capacidades desarrolladas, probadas y estabilizadas durante v1.1.

Entre los elementos heredados se encuentran:

* Reputation Engine.
* State Engine.
* Policy Engine.
* Sensor Framework.
* Sensor Fail2Ban.
* Firewall Backend.
* SQLite.
* Dashboard.
* Ban Lifecycle Engine.
* Installer Engine.

La evolución hacia v2.0 incorpora principalmente una reorganización de identidad, estructura operativa, instalación y mantenimiento, junto con la integración de capacidades desarrolladas durante la evolución posterior de v1.1.

La arquitectura v2 mantiene como principio que las nuevas capacidades deben integrarse sin duplicar responsabilidades existentes.

---

# Capas de ARE

## Sensor Framework

El Sensor Framework constituye la capa de observación.

Su responsabilidad es recibir información generada por sistemas externos y transformarla en eventos que puedan ser procesados por ARE.

Los sensores no determinan la política de seguridad.

### Sensor Fail2Ban

El sensor Fail2Ban es la primera implementación oficial del Sensor Framework.

Actualmente procesa:

```text
FOUND
EXTERNAL_UNBAN
```

El sensor utiliza un offset persistente para evitar reprocesar eventos ya procesados.

El flujo general es:

```text
Fail2Ban
    |
    v
Sensor Fail2Ban
    |
    v
Evento ARE
```

La arquitectura permite incorporar otros sensores sin modificar la responsabilidad del núcleo de reputación.

---

# Reputation Engine

El Reputation Engine mantiene el conocimiento acumulado sobre las direcciones IP.

Los eventos procesados producen cambios en las categorías de reputación correspondientes y en el `total_score`.

La reputación se mantiene de forma persistente en SQLite.

El modelo de reputación utilizado por ARE se construyó y amplió durante v1.1 y forma parte de la base sobre la que continúa desarrollándose v2.0.

La reputación representa comportamiento acumulado y no solamente el último evento recibido.

---

# State Engine

El State Engine determina el estado operativo de una dirección IP a partir de la información disponible en ARE.

Su función es representar la situación actual de la IP dentro del ciclo de decisión.

Los estados definidos por el modelo actual incluyen:

```text
NEW
WATCH
FILTER
BANNED
```

El State Engine es independiente del mecanismo utilizado posteriormente para ejecutar una acción.

La evolución de v1.1 demostró además la necesidad de mantener sincronizados State Engine y Policy Engine, evitando estados incompatibles con las decisiones generadas por la política.

---

# Policy Engine

El Policy Engine transforma la información de reputación y estado en una decisión.

Las decisiones disponibles incluyen:

```text
ALLOW
WATCH
FILTER
TEMP_BAN
BAN
```

El Policy Engine no ejecuta directamente las modificaciones del firewall.

Su responsabilidad termina en la generación de una decisión coherente con la información disponible.

La ejecución corresponde a las capas posteriores.

---

# Ban Lifecycle Engine

El Ban Lifecycle Engine administra la evolución de las sanciones.

No determina si una IP representa riesgo. Esa responsabilidad corresponde a Reputation Engine, State Engine y Policy Engine.

Su responsabilidad comienza cuando ARE determina una acción de sanción.

El estado de sanción se mantiene de forma persistente mediante:

```text
sanction_state
```

La información administrada incluye:

* nivel de sanción;
* cantidad acumulada de sanciones;
* duración;
* finalización de sanciones temporales;
* estado permanente.

El mecanismo permite escalar progresivamente las sanciones hasta un bloqueo permanente cuando la política correspondiente lo determina.

El Ban Lifecycle Engine fue implementado y validado durante la evolución de v1.1 y forma parte de la arquitectura sobre la que continúa v2.0.

---

# Apply Engine

El Apply Engine recibe la decisión generada por el Policy Engine y coordina su aplicación.

Su responsabilidad es separar la decisión lógica de la ejecución concreta sobre el sistema operativo.

El flujo es:

```text
Policy Engine
      |
      | decisión
      v
Apply Engine
      |
      v
Firewall Backend
```

Esta separación permite que el motor de decisión no dependa directamente de la implementación concreta del firewall.

El Apply Engine procesa acciones como:

```text
ALLOW
WATCH
FILTER
TEMP_BAN
BAN
```

y coordina las operaciones necesarias para materializar la decisión mediante el backend.

---

# Firewall Backend

El Firewall Backend es la capa encargada de aplicar las decisiones sobre el sistema operativo.

La implementación actual continúa utilizando IPSet junto con las reglas de firewall correspondientes.

La arquitectura mantiene separado el backend del Policy Engine.

Actualmente se utilizan conjuntos diferenciados para las funciones de filtrado y bloqueo, incluyendo soporte IPv4 e IPv6.

El objetivo arquitectónico es que una decisión de ARE no dependa de una implementación específica del mecanismo de firewall.

La incorporación de otros backends pertenece a la evolución futura del proyecto y no debe considerarse una capacidad implementada de v2.0 mientras no haya sido desarrollada y validada.

---

# Reputation Decay Engine

El Reputation Decay Engine permite reducir gradualmente la reputación de direcciones IP que no presentan actividad reciente.

El mecanismo fue desarrollado durante la evolución de v1.1 y continúa formando parte del ciclo operativo de v2.0.

El proceso utiliza:

```text
decay-dry-run
decay-apply
```

`decay-dry-run` permite identificar candidatas y calcular el resultado esperado sin modificar los datos.

`decay-apply` aplica la reducción de reputación y actualiza el estado correspondiente.

La tabla `reputation` mantiene:

```text
last_decay
```

para controlar la frecuencia de aplicación del decay.

Después de una reducción se reevalúan:

```text
Reputation
     |
     v
State Engine
     |
     v
Policy Engine
```

La ejecución periódica se integra mediante systemd.

Las unidades actuales son:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

El Decay Engine mantiene separada la recuperación de reputación de la ejecución directa sobre el firewall.

---

# Persistencia

ARE utiliza SQLite como mecanismo de persistencia.

En v2.0 la base de datos principal se encuentra en:

```text
/var/lib/are/are.db
```

La estructura persistente incluye, entre otras, las siguientes tablas:

```text
config
hosts
events
jails
jail_profile
reputation
sanction_state
```

La persistencia mantiene separadas distintas clases de información:

```text
Eventos
   |
   +---- actividad observada

Reputation
   |
   +---- conocimiento acumulado

sanction_state
   |
   +---- estado del ciclo de sanciones
```

Esta separación permite que el historial de eventos, la reputación y el estado de sanción evolucionen de manera independiente.

---

# Estructura operativa de v2.0

La identidad y estructura operativa del producto fueron reorganizadas en v2.0.

La estructura principal es:

```text
/opt/are
    |
    +---- producto ARE

/var/lib/are
    |
    +---- datos persistentes

/var/log/are
    |
    +---- logs

/usr/local/sbin
    |
    +---- enlaces ejecutables oficiales

/etc/systemd/system
    |
    +---- unidades systemd

/etc/logrotate.d
    |
    +---- configuración logrotate
```

La estructura del producto está definida centralmente mediante:

```text
manifest/product.sh
```

El Product Manifest no implementa lógica de negocio. Define los componentes que forman parte del producto y que deben ser administrados por el Installer Engine.

---

# Installer Engine

El Installer Engine administra el ciclo de vida de la instalación de ARE.

Las operaciones oficiales son:

```text
install
upgrade
repair
verify
uninstall
```

El Installer utiliza el Product Manifest como fuente de definición de los componentes administrados.

El ciclo general es:

```text
Product Manifest
       |
       v
Installer Engine
       |
       +---- install
       +---- upgrade
       +---- repair
       +---- verify
       +---- uninstall
```

El Installer mantiene separadas:

```text
Core del producto
Configuración
Datos persistentes
Logs
Componentes systemd
Enlaces ejecutables
```

`upgrade` actualiza los componentes administrados sin sustituir los datos persistentes.

`repair` permite reconstruir una instalación incompleta.

`verify` comprueba la integridad y los componentes operativos definidos para la instalación.

`uninstall` elimina el producto y conserva los elementos persistentes que forman parte de la política de conservación establecida por ARE.

---

# Product Manifest

El Product Manifest constituye la definición estructural del producto.

Se encuentra en:

```text
manifest/product.sh
```

Centraliza información como:

* nombre del producto;
* versión;
* directorios administrados;
* archivos administrados;
* configuración;
* datos persistentes;
* ejecutables;
* enlaces oficiales;
* unidades systemd;
* logrotate.

El Manifest permite que el Installer opere sobre una definición única de la estructura del producto.

No contiene la lógica de los motores de ARE.

---

# Comandos oficiales

v2.0 establece los comandos oficiales:

```text
are
are-installer
are-fail2ban-sensor
```

El comando principal se expone mediante:

```text
/usr/local/sbin/are
```

apuntando al ejecutable principal del producto:

```text
/opt/are/are.sh
```

Los enlaces forman parte de los componentes administrados por el Product Manifest.

---

# Systemd

ARE utiliza systemd para la ejecución de procesos periódicos que forman parte del ciclo operativo.

Entre los componentes actualmente administrados se encuentran:

```text
Fail2Ban Sensor
Reputation Decay
```

El uso de systemd permite separar la lógica de ejecución de la lógica de los motores.

Los servicios y timers forman parte de la estructura administrada por el Installer Engine.

---

# Flujo completo de procesamiento

El flujo principal de una señal de seguridad es:

```text
Sistema externo
       |
       v
Sensor
       |
       v
Evento interno ARE
       |
       v
Reputation Engine
       |
       v
State Engine
       |
       v
Policy Engine
       |
       v
Ban Lifecycle Engine
       |
       v
Apply Engine
       |
       v
Firewall Backend
       |
       v
Sistema operativo
```

La información generada durante el procesamiento queda registrada en la persistencia correspondiente.

El flujo de recuperación mediante Decay utiliza una trayectoria diferente:

```text
Reputation Decay
       |
       v
Reputation
       |
       v
State Engine
       |
       v
Policy Engine
```

La decisión resultante se mantiene separada de la ejecución directa del firewall según el estado actual del mecanismo de recuperación.

---

# Separación de responsabilidades

La arquitectura mantiene las siguientes responsabilidades:

| Componente           | Responsabilidad                        |
| -------------------- | -------------------------------------- |
| Sensor Framework     | Observación y normalización de eventos |
| Reputation Engine    | Construcción de reputación             |
| State Engine         | Determinación del estado               |
| Policy Engine        | Generación de decisiones               |
| Ban Lifecycle Engine | Evolución de sanciones                 |
| Apply Engine         | Coordinación de aplicación             |
| Firewall Backend     | Ejecución sobre el sistema operativo   |
| Reputation Decay     | Recuperación gradual de reputación     |
| Installer Engine     | Ciclo de vida del producto             |
| Product Manifest     | Definición estructural del producto    |
| SQLite               | Persistencia                           |

Ningún componente debe asumir responsabilidades pertenecientes a otra capa.

---

# Principios arquitectónicos

## Separación entre observación y decisión

Los sistemas externos generan información.

ARE interpreta esa información y construye conocimiento.

Los sensores no sustituyen al motor de decisión.

---

## Separación entre decisión y ejecución

ARE determina qué acción corresponde.

El backend determina cómo ejecutar dicha acción sobre el sistema operativo.

---

## Persistencia del conocimiento

La reputación, los eventos y el estado de sanción deben conservarse de forma independiente.

La pérdida de uno de estos elementos no debe convertir automáticamente los demás en información inválida.

---

## Una responsabilidad por componente

Cada motor debe mantener una responsabilidad claramente definida.

La ampliación de capacidades debe realizarse mediante componentes o extensiones apropiadas antes que mediante duplicación de lógica.

---

## Configuración desacoplada

Los parámetros operativos deben mantenerse fuera de la lógica de los motores.

La estructura de configuración es administrada por el producto y su Installer.

Las plantillas distribuidas con el producto se diferencian de la configuración operativa utilizada por una instalación.

---

## Evolución incremental

v2.0 continúa la arquitectura desarrollada en v1.1.

Las modificaciones deben realizarse de forma incremental:

```text
analizar
   ↓
desarrollar
   ↓
probar
   ↓
validar
   ↓
documentar
```

La documentación debe reflejar el comportamiento validado del sistema y no anticipar funcionalidades que todavía no hayan sido implementadas.

---

# Estado arquitectónico

La arquitectura base de v1.1 permanece como fundamento de v2.0.

v2.0 introduce una evolución estructural y operativa que incluye:

* identidad oficial ARE;
* estructura de producto `/opt/are`;
* datos persistentes en `/var/lib/are`;
* logs en `/var/log/are`;
* Product Manifest;
* Installer Engine ampliado;
* comandos oficiales ARE;
* persistencia de `sanction_state`;
* integración operativa del Reputation Decay;
* administración de componentes mediante systemd.

La arquitectura de v2.0 continúa en desarrollo y validación.

Las capacidades futuras que todavía no hayan sido implementadas y validadas no forman parte del estado actual de la arquitectura.

