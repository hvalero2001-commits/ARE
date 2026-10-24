# ARE User Guide

## Introducción

Esta guía describe el uso operativo de ARE (Abuse Reputation Engine).

ARE procesa eventos de seguridad, mantiene información persistente de reputación y estado, evalúa las políticas configuradas y aplica las decisiones mediante el backend correspondiente.

---

# Requisitos

ARE debe encontrarse instalado y validado.

Verificar la instalación mediante:

```bash
are-installer verify
```

La interfaz oficial se encuentra disponible mediante:

```bash
are
```

---

# Interfaz de comandos

Los comandos operativos de ARE son:

```text
are admin
are stats
are trends [días]
are top
are score <IP>
are events <IP>
are found <IP> <JAIL>
are ban <IP> <JAIL>
are unban <IP>
are external-unban <IP> [JAIL]
are policy-compare <IP>
are decay-dry-run
are decay-apply
```

El Installer Engine utiliza:

```text
are-installer
```

con las operaciones:

```text
are-installer install
are-installer upgrade
are-installer repair
are-installer verify
are-installer uninstall
```

El punto de entrada oficial se instala mediante `/usr/local/sbin/are`, con el Core de ARE en `/opt/are`.

---

# ARE ADMIN

Interfaz de administración por línea de comandos:

```bash
are admin
```

Organizada en siete ramas:

```text
1) Jails / Perfiles
2) Categorías
3) Sensores
4) Política
5) Estado / Reputación
6) Decay
7) Configuración
0) Salir
```

Cada submenú ofrece `0) Volver` para retroceder un nivel, y `x) Salir` como atajo para cerrar el programa completo desde cualquier punto de la navegación, sin necesidad de volver primero al menú raíz.

Las operaciones de escritura (crear, modificar, eliminar un perfil; ejecutar decay) quedan registradas en un log de auditoría, con usuario, fecha y detalle de la acción:

```text
/var/log/are/admin_audit.log
```

## Jails / Perfiles

Administra la relación entre un jail (de Fail2Ban, o de un sensor por callback como `mod_evasive`) y su categoría de reputación, peso, confianza y decay.

```text
1) Listar
2) Crear
3) Modificar
4) Eliminar
5) Validar
6) Exportar
7) Importar
```

Al crear o modificar un perfil, el sistema ofrece asistencia para elegir peso y confianza: una escala de referencia curada si existe para la categoría, o estadísticas (mínimo, máximo, promedio) calculadas sobre los perfiles ya existentes en esa categoría.

`Exportar` genera un archivo con timestamp en `${ARE_DATA}/backups/jail_profiles/`, con todos los perfiles del servidor. `Importar` permite seleccionar uno de esos archivos y aplicarlo, preguntando una única vez si se debe sobrescribir o conservar los perfiles que ya existan localmente. Este mecanismo permite replicar la calibración de perfiles entre servidores sin recrearlos manualmente uno por uno.

## Categorías

Consulta de solo lectura del catálogo de categorías de reputación y sus umbrales configurados, y de las puntuaciones acumuladas por categoría para una IP concreta.

## Sensores

Estado y configuración de los sensores activos (Fail2Ban y SpamAssassin por polling, `apache_evasive` por callback), leídos dinámicamente desde el registro de sensores.

```text
1) Estado
2) Configuración
3) Activar/Desactivar
```

`Activar/Desactivar` habilita o deshabilita un sensor. Para sensores de patrón polling, controla directamente su timer de systemd. Para sensores de patrón callback (`apache_evasive`), el registro queda marcado, pero el efecto real todavía depende de configuración externa a ARE (ver Roadmap).

## Política

Consulta de solo lectura de la configuración efectiva del Policy Engine: umbrales globales, umbrales por categoría, multiplicadores de reincidencia, y niveles del Ban Lifecycle. La opción de validación comprueba que los umbrales estén en orden ascendente y que cada categoría con umbral definido tenga su regla correspondiente implementada.

## Estado / Reputación

```text
1) Consultar IP
2) Eventos
3) Top
4) Estadísticas
5) Tendencias
```

`Tendencias` muestra la evolución diaria de la actividad (eventos totales, por tipo de acción, e IPs distintas) para una ventana configurable de días.

## Decay

```text
1) Estado
2) Dry-run
3) Ejecutar
```

## Configuración

```text
1) Ver
2) Validar
3) Estado del sistema
```

---

# Estadísticas

Consultar información general del sistema:

```bash
are stats
```

El comando `stats` proporciona información operacional del sistema.

Entre la información incorporada al Dashboard se encuentra la actividad de los Jails.

La sección `TOP JAILS` utiliza la tabla `events` como fuente de información y excluye eventos internos como `fail2ban` y `policy_apply`.

---

# Tendencias

Consultar la evolución diaria de la actividad registrada:

```bash
are trends [días]
```

Por defecto muestra los últimos 7 días. Cada fila incluye eventos totales, desglose por tipo de acción (`FOUND`, `BAN`, `EXTERNAL_UNBAN`) e IPs distintas involucradas ese día.

---

# Top de amenazas

Consultar las principales direcciones según su reputación:

```bash
are top
```

---

# Consultar reputación

Consultar la reputación de una dirección IP:

```bash
are score <IP>
```

Ejemplo:

```bash
are score 192.168.1.10
```

La información de reputación se mantiene en SQLite junto con los datos de hosts, eventos, Jails, perfiles de Jail y estado de sanciones.

La estructura persistente de ARE incluye:

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

`reputation_scores` mantiene el score por categoría de forma normalizada (una fila por IP y categoría), lo que permite incorporar categorías nuevas sin modificar la estructura de la base ni el código de las funciones que la consultan.

La base de datos se encuentra en:

```text
/var/lib/are/are.db
```

---

# Consultar eventos

Consultar los eventos registrados para una dirección IP:

```bash
are events <IP>
```

Ejemplo:

```bash
are events 192.168.1.10
```

Los eventos constituyen el historial de actividad procesado por ARE y también son utilizados por las estadísticas de Jails y por las tendencias temporales.

---

# Procesar un evento FOUND

Procesar manualmente un evento `FOUND`:

```bash
are found <IP> <JAIL>
```

Ejemplo:

```bash
are found 192.168.1.10 modsec-protocol
```

El flujo de procesamiento de un evento `FOUND` es:

```text
FOUND
  │
  ▼
Reputation
  │
  ▼
State
  │
  ▼
Policy (evaluación por categoría)
  │
  ▼
Apply
```

El `JAIL` debe tener un perfil administrado (ver ARE ADMIN, Jails / Perfiles). Un jail sin perfil se descarta sin generar evento, sin necesidad de mantener una lista fija en el código del sensor.

---

# Ban

Procesar un evento de ban:

```bash
are ban <IP> <JAIL>
```

El Jail proporciona el contexto utilizado por ARE para procesar el evento.

Las decisiones de aplicación incluyen `FILTER`, `TEMP_BAN` y `BAN`.

El backend utiliza conjuntos separados para filtrado y bloqueo, tanto para IPv4 como para IPv6.

Cuando la sanción calculada excede el límite máximo de timeout soportado por IPSet, el sistema ajusta automáticamente la duración aplicada a ese límite, registrando la situación en el log.

---

# Unban

Eliminar una sanción activa:

```bash
are unban <IP>
```

El flujo `UNBAN` forma parte del ciclo de vida de las direcciones IP y del backend.

---

# Unban externo

Procesar un evento `EXTERNAL_UNBAN`:

```bash
are external-unban <IP> [JAIL]
```

Los eventos `UNBAN` externos se registran como:

```text
EXTERNAL_UNBAN
```

El `EXTERNAL_UNBAN` no libera directamente la dirección IP.

ARE vuelve a evaluar la dirección mediante el Policy Engine y aplica la decisión resultante.

---

# Comparar decisiones de política

Ejecutar simultáneamente el motor de decisión activo y una evaluación de referencia sobre la misma IP, sin aplicar ninguna decisión:

```bash
are policy-compare <IP>
```

Útil para validar el comportamiento del Policy Engine contra datos reales de producción antes de adoptar un cambio de configuración o de umbrales.

---

# Reputation Decay

ARE dispone de Reputation Decay para reducir progresivamente la reputación de direcciones IP sin actividad reciente.

Los parámetros documentados son:

```text
DECAY_MIN_AGE=86400
DECAY_FACTOR=0.95
```

Esto corresponde a un mínimo de 24 horas sin actividad y un factor inicial de reducción de `0.95`.

La reducción se calcula sobre el score total agregado de la IP y se redistribuye proporcionalmente entre sus categorías activas, evitando que una IP con actividad repartida entre varias categorías decaiga más rápido que otra con actividad concentrada en una sola, ante el mismo score total.

## Simulación

Consultar las IPs candidatas sin modificar la reputación:

```bash
are decay-dry-run
```

La simulación muestra las candidatas y el score estimado.

## Aplicación

Aplicar el decay:

```bash
are decay-apply
```

La operación:

* reduce el score, redistribuido proporcionalmente entre categorías;
* actualiza el estado;
* reevalúa el Policy Engine;
* actualiza `last_decay`;
* evita aplicar múltiples reducciones dentro de la misma ventana.

El Decay no ejecuta directamente cambios sobre el firewall. La liberación automática sólo se produce cuando la política devuelve `ALLOW`; `WATCH`, `FILTER`, `TEMP_BAN` y `BAN` no generan liberación automática.

El mecanismo se encuentra integrado con systemd mediante:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

---

# Sensores

## Fail2Ban (patrón polling)

ARE mantiene un sensor para Fail2Ban que lee el log de forma periódica.

Los eventos procesados por el sensor son:

```text
FOUND
EXTERNAL_UNBAN
```

El sensor utiliza un cursor persistente para procesar nuevos eventos, y valida dinámicamente cada jail contra `jail_profile` — un jail sin perfil administrado se descarta.

## SpamAssassin (patrón polling)

ARE mantiene un sensor para SpamAssassin que lee el log del MTA de forma periódica (adaptador implementado y validado: Exim). Clasifica los mensajes marcados como spam en tres bandas de severidad según su score, cada una con su propio perfil administrado. Reporta a la categoría `SOCIAL`.

## Apache / mod_evasive (patrón callback)

Sensor invocado directamente por Apache en el instante en que `mod_evasive` detecta un flood, sin esperar a un ciclo de lectura periódica. Reporta a la categoría `DOS`.

---

# Restauración del Firewall Backend

IPSet no conserva su contenido de forma nativa entre reinicios del sistema operativo. ARE restaura al arrancar las sanciones activas (permanentes y temporales, preservando el tiempo restante exacto de estas últimas) y las IPs en estado de filtrado, a partir de la base de datos — no de un snapshot congelado del firewall.

Este mecanismo se ejecuta una única vez por arranque, mediante:

```text
are-restore-ipsets.service
```

---

# Installer Engine

El Installer Engine administra el ciclo de vida de la instalación mediante:

```bash
are-installer install
are-installer upgrade
are-installer repair
are-installer verify
are-installer uninstall
```

Las operaciones utilizan un único Installer Core y reutilizan sus módulos según la operación.

## Instalar

```bash
are-installer install
```

La instalación crea la estructura requerida, instala el Core, la configuración, la base de datos, los enlaces, permisos, servicios, timers y logrotate, y realiza la validación final.

La instalación no debe utilizar como origen y destino el mismo directorio.

## Actualizar

```bash
are-installer upgrade
```

`upgrade` requiere una instalación existente.

Actualiza el Core y los componentes administrados sin sobrescribir la configuración persistente existente. La operación conserva los datos persistentes y actualiza los enlaces, logging, systemd y logrotate.

## Reparar

```bash
are-installer repair
```

`repair` actúa sobre una instalación incompleta.

Restaura los componentes necesarios y vuelve a validar la instalación.

## Verificar

```bash
are-installer verify
```

La verificación comprueba, entre otros elementos:

* integridad de archivos y directorios;
* enlaces;
* permisos;
* estructura SQLite;
* runtime;
* IPSet;
* systemd;
* logrotate.

Las comprobaciones de la instalación incluyen las tablas:

```text
config
hosts
jails
events
jail_profile
reputation
reputation_scores
sanction_state
```

## Desinstalar

```bash
are-installer uninstall
```

La desinstalación elimina los componentes administrados del producto, incluyendo Core, unidades systemd, enlaces y configuración de logrotate.

Los datos persistentes y la configuración se conservan:

```text
Configuración
Datos
Logs
```

---

# Configuración

ARE utiliza los siguientes archivos de configuración:

```text
config.conf
policy.conf
whitelist.conf
```

Estos archivos son tratados como configuración persistente por el Installer Engine y no se sobrescriben cuando ya existe configuración administrada por el administrador.

Los enlaces de configuración forman parte de la instalación y son verificados por `are-installer verify`.

---

# Ubicaciones principales

Core:

```text
/opt/are
```

Datos persistentes:

```text
/var/lib/are
```

Logs:

```text
/var/log/are
```

Enlaces ejecutables:

```text
/usr/local/sbin
```

Unidades systemd:

```text
/etc/systemd/system
```

---

# Flujo operativo

El flujo general de ARE es:

```text
Evento
   │
   ▼
Reputation
   │
   ▼
State
   │
   ▼
Policy (por categoría)
   │
   ▼
Ban Lifecycle
   │
   ▼
Apply
   │
   ▼
Firewall
```

Fail2Ban y Apache/mod_evasive actúan como fuentes de eventos mediante el Sensor Framework.

ARE mantiene la reputación y el estado, determina la decisión mediante el Policy Engine y ejecuta la acción correspondiente mediante el backend.

---

# Buenas prácticas

* Verificar la instalación después de operaciones de mantenimiento.
* Mantener protegida la configuración.
* Mantener copias de seguridad de los datos persistentes.
* Revisar periódicamente eventos, estadísticas y tendencias.
* Supervisar el estado de los sensores y las decisiones aplicadas.
* Usar `policy-compare` antes de adoptar cambios de umbrales en producción.
* Exportar el catálogo de `jail_profile` antes de cambios mayores, para poder restaurar la calibración si algo sale mal.

---

# Solución de problemas

### Instalación incompleta

Ejecutar:

```bash
are-installer verify
```

Si la instalación es detectada como incompleta:

```bash
are-installer repair
```

### Instalación existente

Para actualizar una instalación existente:

```bash
are-installer upgrade
```

### Consultar una IP

```bash
are score <IP>
```

### Consultar eventos

```bash
are events <IP>
```

### Consultar estadísticas

```bash
are stats
```

### Consultar decay

```bash
are decay-dry-run
```

### Comparar el motor de decisión

```bash
are policy-compare <IP>
```

---

# Referencias

Para información adicional consultar:

```text
README.md
docs/ARCHITECTURE.md
docs/DESIGN.md
docs/INSTALL.md
docs/BAN_LIFECYCLE.md
docs/DEVELOPMENT.md
docs/SECURITY.md
docs/CHANGELOG.md
docs/ROADMAP.md
```

Esta guía contiene únicamente procedimientos y capacidades respaldados por la documentación y las implementaciones verificadas disponibles para ARE.
