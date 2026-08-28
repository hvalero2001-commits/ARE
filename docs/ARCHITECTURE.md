# ARE Architecture

## Introducción

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para transformar eventos de seguridad en decisiones basadas en evidencia.

La arquitectura separa la observación de los eventos, la construcción de reputación, la evaluación del estado, la decisión de política y la ejecución de las acciones.

ARE v2.0 continuó esta arquitectura a partir de la base funcional establecida en v1.1, incorporando la identidad propia del producto, una estructura operativa independiente de la implementación histórica de `f2b-ipset` y nuevos componentes necesarios para administrar el ciclo completo de reputación y sanciones. Las versiones v2.1, v2.2, v2.3, v2.4, v2.5 y v2.6 extendieron esa misma base sin introducir una ruptura arquitectónica.

La versión v2.5.0 constituye la última versión estable liberada. v2.6 se encuentra en desarrollo y validación sobre esa base.

---

# Arquitectura general

La arquitectura actual puede representarse mediante el siguiente flujo:

```text
                         FUENTES EXTERNAS
                               |
             +-----------------+-----------------+
             |                                   |
             v                                   v
        Fail2Ban                      Apache (mod_evasive)
             |                                   |
             v                                   v
       Sensor Framework  <----------------------->
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

El Sensor Framework admite dos patrones de entrega de eventos: por *polling* (el sensor consulta periódicamente una fuente externa, como el log de Fail2Ban) y por *callback* (la fuente externa invoca directamente al sensor en el instante del evento, como hace Apache con `mod_evasive`). Ambos patrones convergen en el mismo contrato de entrada hacia el Reputation Engine.

---

# Relación entre v1.1 y v2.0/v2.1

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

La evolución hacia v2.0 incorporó una reorganización de identidad, estructura operativa, instalación y mantenimiento, la interfaz de administración ARE ADMIN, y la reconstrucción del Policy Engine hacia un modelo de evaluación por categoría (ver Sección "Policy Engine" más abajo). v2.1 extendió esa base con administración avanzada de perfiles, la extensibilidad del modelo de reputación, la visibilidad temporal y la persistencia del Firewall Backend a través de reinicios. v2.2 incorporó un sensor real para la categoría SOCIAL, completó el catálogo de umbrales de categoría, y dio los primeros pasos hacia la distribución del producto como paquete instalable.

La arquitectura v2 mantiene como principio que las nuevas capacidades deben integrarse sin duplicar responsabilidades existentes.

---

# Capas de ARE

## Sensor Framework

El Sensor Framework constituye la capa de observación.

Su responsabilidad es recibir información generada por sistemas externos y transformarla en eventos que puedan ser procesados por ARE.

Los sensores no determinan la política de seguridad.

### Sensor Fail2Ban (patrón polling)

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

El jail que reporta cada evento se valida dinámicamente contra `jail_profile` — un jail sin perfil administrado se descarta sin generar evento, sin necesidad de mantener una lista fija de jails permitidos en el código del sensor.

### Sensor Apache/mod_evasive (patrón callback)

Segundo patrón oficial del Sensor Framework, estructuralmente distinto del polling: Apache invoca al sensor directa y síncronamente en el instante en que `mod_evasive` confirma un flood, sin esperar a un ciclo de lectura periódica.

El flujo general es:

```text
mod_evasive (Apache)
    |
    v
Sensor Apache Evasive
    |
    v
Evento ARE (categoría DOS)
```

El sensor mantiene, durante su período de transición, doble escritura: aplica el bloqueo directamente sobre el Firewall Backend y, en paralelo, reporta el evento a ARE para su incorporación al modelo de reputación.

La arquitectura permite incorporar otros sensores, de cualquiera de los dos patrones, sin modificar la responsabilidad del núcleo de reputación.

---

# Reputation Engine

El Reputation Engine mantiene el conocimiento acumulado sobre las direcciones IP.

Los eventos procesados producen cambios en las categorías de reputación correspondientes y en el `total_score`.

La reputación se mantiene de forma persistente en SQLite.

El modelo de reputación utilizado por ARE se construyó y amplió durante v1.1 y forma parte de la base sobre la que continuó evolucionando en v2.0, v2.1 y v2.2.

La reputación representa comportamiento acumulado y no solamente el último evento recibido.

Las categorías de reputación soportadas son administradas mediante `REPUTATION_CATEGORIES`, en `config/policy.conf`, como catálogo explícito — no una lista fija en el código de ningún componente.

A partir de v2.1, el modelo de almacenamiento por categoría transiciona de columnas fijas por categoría en la tabla `reputation` hacia un esquema normalizado (`reputation_scores`), donde una categoría nueva se incorpora como dato, sin requerir modificación de esquema ni de código.

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

El estado se recalcula por completo en cada evaluación, en función del score vigente en ese momento — no conserva memoria del estado anterior. Esto permite que una IP pase de `BANNED` a un estado inferior cuando su score disminuye por acción del Decay Engine, sin requerir intervención manual.

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

## Evaluación por categoría

A partir de v2.0, el Policy Engine evalúa el riesgo de una IP por categoría de reputación de forma independiente, en lugar de depender exclusivamente del score total agregado. Cada categoría cuenta con una regla propia (`policy/rules/<categoria>.sh`), que conoce únicamente su propio umbral —configurado en `config/policy.conf`— y aporta al riesgo total solo si lo supera. Ninguna regla conoce a las demás ni decide una acción por sí misma; esa responsabilidad corresponde exclusivamente al orquestador del motor.

El orquestador itera dinámicamente sobre `REPUTATION_CATEGORIES`, por lo que una categoría nueva con su regla correspondiente ya escrita comienza a evaluarse sin necesidad de modificar el orquestador.

Se incorpora además un multiplicador de riesgo por reincidencia, aplicado cuando la IP ya se encuentra en estado de observación o sanción activa, configurable en `config/policy.conf`.

### Piso de seguridad

La decisión final del Policy Engine nunca es menos estricta que la que resultaría de evaluar únicamente el score total acumulado. El motor por categoría puede ser más estricto —detectando señales que el score simple no distingue, como una frecuencia elevada de eventos en poco tiempo— pero nunca menos. Esto evita que una IP con riesgo repartido entre varias categorías, cada una por debajo de su propio umbral individual, evada la detección aunque su score total sea alto.

### Validación no invasiva

Se dispone de un mecanismo de comparación (`policy-compare`) que ejecuta simultáneamente el motor de decisión activo y una evaluación alternativa sobre la misma IP, sin aplicar ninguna decisión, permitiendo validar cambios de comportamiento contra datos reales de producción antes de su adopción definitiva.

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

El Ban Lifecycle Engine fue implementado y validado durante la evolución de v1.1 y forma parte de la arquitectura sobre la que continuó v2.0, v2.1 y v2.2.

Un bloqueo permanente (`sanction_state.permanent = 1`) no es alcanzado por el Reputation Decay Engine — su reconsideración requiere una decisión administrativa explícita, no una recuperación automática por inactividad.

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

Toda duración aplicada al Firewall Backend se ajusta al límite máximo soportado por el mecanismo utilizado (`IPSET_MAX_TIMEOUT` en `config/policy.conf`), registrando explícitamente cuando una sanción calculada excede ese límite.

---

# Firewall Backend

El Firewall Backend es la capa encargada de aplicar las decisiones sobre el sistema operativo.

La implementación actual continúa utilizando IPSet junto con las reglas de firewall correspondientes.

La arquitectura mantiene separado el backend del Policy Engine.

Actualmente se utilizan conjuntos diferenciados para las funciones de filtrado y bloqueo, incluyendo soporte IPv4 e IPv6.

El objetivo arquitectónico es que una decisión de ARE no dependa de una implementación específica del mecanismo de firewall.

La incorporación de otros backends pertenece a la evolución futura del proyecto y no debe considerarse una capacidad implementada mientras no haya sido desarrollada y validada.

## Persistencia del Firewall Backend

`ipset` no persiste nativamente su contenido entre reinicios del sistema operativo. ARE restaura el estado del Firewall Backend al arrancar a partir de la base de datos —fuente de verdad del sistema—, no de un snapshot congelado del firewall: las sanciones activas (permanentes o temporales, preservando el tiempo restante exacto de estas últimas) y las IPs en estado de filtrado se reincorporan a los conjuntos correspondientes mediante una unidad de ejecución única al inicio del sistema, separada del ciclo normal de procesamiento de eventos.

---

# Reputation Decay Engine

El Reputation Decay Engine permite reducir gradualmente la reputación de direcciones IP que no presentan actividad reciente.

El mecanismo fue desarrollado durante la evolución de v1.1 y continúa formando parte del ciclo operativo de v2.0, v2.1 y v2.2.

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

La reducción se aplica sobre el score total agregado de la IP, redistribuyendo el resultado proporcionalmente entre sus categorías activas — no se trunca cada categoría de forma independiente, lo que evitaría que una IP con actividad repartida entre varias categorías decayera más rápido que una con actividad concentrada en una sola, ante el mismo score total.

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
reputation_scores
sanction_state
```

La persistencia mantiene separadas distintas clases de información:

```text
Eventos
   |
   +---- actividad observada

Reputation / Reputation Scores
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

# Interfaz de Administración (ARE ADMIN)

ARE ADMIN es la interfaz de administración por línea de comandos de ARE, incorporada en v2.0.

Se accede mediante `are.sh admin` o el atajo equivalente `admin.sh`, ambos cargando el mismo `bootstrap.sh` utilizado por el resto del sistema — ARE ADMIN opera siempre sobre los mismos componentes reales, sin duplicar lógica ni mantener un entorno de carga separado.

ARE ADMIN no introduce una nueva autoridad de decisión. Es una capa de consulta y administración que se apoya sobre los componentes existentes, respetando la separación de responsabilidades del resto de la arquitectura: no modifica directamente `reputation` ni el Firewall Backend, no reemplaza al Policy Engine ni al Decay Engine.

Las ramas administradas son: Jails/Perfiles, Categorías, Sensores, Política, Estado/Reputación, Decay y Configuración. Las operaciones de escritura quedan registradas en un log de auditoría independiente, con usuario, fecha y detalle de cada acción.

El diseño completo de ARE ADMIN se documenta en `docs/DESIGN.md`, Sección 13.

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

ARE utiliza systemd para la ejecución de procesos periódicos y de arranque único que forman parte del ciclo operativo.

Entre los componentes actualmente administrados se encuentran:

```text
Fail2Ban Sensor (periódico)
Reputation Decay (periódico)
Restauración del Firewall Backend (arranque único)
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
| -------------------- | --------------------------------------- |
| Sensor Framework     | Observación y normalización de eventos |
| Reputation Engine    | Construcción de reputación             |
| State Engine         | Determinación del estado               |
| Policy Engine        | Generación de decisiones, por categoría |
| Ban Lifecycle Engine | Evolución de sanciones                 |
| Apply Engine         | Coordinación de aplicación             |
| Firewall Backend     | Ejecución sobre el sistema operativo, con persistencia entre reinicios |
| Reputation Decay     | Recuperación gradual de reputación     |
| ARE ADMIN            | Administración y consulta del sistema completo |
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

v2.0, v2.1 y v2.2 continúan la arquitectura desarrollada en v1.1.

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

La arquitectura base de v1.1 permanece como fundamento de v2.0, v2.1 y v2.2.

v2.0 introdujo una evolución estructural y operativa que incluye:

* identidad oficial ARE;
* estructura de producto `/opt/are`;
* datos persistentes en `/var/lib/are`;
* logs en `/var/log/are`;
* Product Manifest;
* Installer Engine ampliado;
* comandos oficiales ARE;
* persistencia de `sanction_state`;
* integración operativa del Reputation Decay;
* administración de componentes mediante systemd;
* interfaz de administración ARE ADMIN;
* Policy Engine reconstruido con evaluación por categoría.

v2.1 extendió esa base con:

* administración avanzada de perfiles (exportar/importar entre servidores);
* modelo de reputación extensible sin migración de esquema;
* visibilidad temporal de la actividad del sistema;
* persistencia del Firewall Backend a través de reinicios.

v2.2 extendió esa base con:

* segundo sensor por adaptador (SpamAssassin, categoría SOCIAL), estableciendo el patrón de "adaptador por fuente" dentro del Sensor Framework — la extracción de datos varía según el origen (hoy: Exim), pero el contrato de reporte hacia el Reputation Engine permanece único;
* catálogo de categorías de reputación completo, con umbral definido para las 9 categorías;
* visibilidad temporal ampliada (desglose por categoría, exportación a CSV);
* primera capa de distribución del producto (empaquetado con verificación de integridad, publicación automatizada por versión etiquetada, instalación remota sin depender de clonar el repositorio) — el Installer Engine en sí no fue modificado, esta capa opera exclusivamente antes de la instalación.

v2.3 extendió esa base con:

* administración operativa de sensores desde ARE ADMIN — registro dinámico (`sensor_registry`), activar/desactivar controlando directamente el timer de systemd para sensores de polling o un archivo flag para sensores de callback, sin tocar configuración externa a ARE en ningún caso;
* cierre de la línea de auto-actualización del Installer Engine iniciada en v2.2 — consulta de versión disponible, actualización remota reutilizando el bootstrap existente, e instalación automática de dependencias del sistema faltantes;
* detección estadística de anomalías en tendencias, comparando la actividad del día contra el promedio reciente por categoría, sin instrumentación nueva.

v2.4 extendió esa base con:

* modelo de reputación extensible completo — las columnas de categoría redundantes en `reputation` eliminadas, tanto para instalaciones nuevas (esquema reducido desde el `CREATE TABLE`) como para el mecanismo de migración de datos existentes, sin depender de ninguna versión específica de SQLite salvo para la migración de bases ya creadas con el esquema viejo;
* el Installer Engine pasó a ser responsable de dejar una instalación completamente operativa por sí sola — conjuntos IPSet, reglas de firewall, y unidades systemd sin dependencias externas duras, sin depender de que el operador ejecute pasos manuales adicionales después de instalar.

v2.5 extendió esa base con:

* un patrón de sensor nuevo dentro del Sensor Framework — correlación de comportamiento entre múltiples IPs distintas (no evaluación aislada por IP), necesario para detectar amenazas que Fail2Ban no puede ver por diseño; el reporte a ARE sigue reutilizando el contrato existente (`found <IP> <JAIL>`) por cada IP del grupo, sin introducir un concepto nuevo de "grupo/campaña" en el modelo de datos.

v2.6 extendió esa base con:

* propagación de reputación entre instancias de ARE — un mecanismo de exportar/importar que respeta la separación de responsabilidades ya establecida: la reputación se sigue acumulando exclusivamente vía `db_add_score()`, sin ninguna ruta de escritura alternativa; el filtro de qué se aplica al importar se apoya en `jail_profile`, ya existente, sin necesitar ningún concepto de "rol de servidor" nuevo en el modelo de datos.

Las capacidades futuras que todavía no hayan sido implementadas y validadas no forman parte del estado actual de la arquitectura.
