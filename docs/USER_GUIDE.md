# ARE User Guide

## Introducción

Esta guía describe el uso operativo de ARE (Abuse Reputation Engine) v2.0.

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
are stats
are top
are score <IP>
are events <IP>
are found <IP> <JAIL>
are ban <IP> <JAIL>
are unban <IP>
are external-unban <IP> [JAIL]
are autoban
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

# Estadísticas

Consultar información general del sistema:

```bash
are stats
```

El comando `stats` proporciona información operacional del sistema.

Entre la información incorporada al Dashboard se encuentra la actividad de los Jails.

La sección `TOP JAILS` utiliza la tabla `events` como fuente de información y excluye eventos internos como `fail2ban` y `policy_apply`.

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

La estructura persistente de ARE v2 incluye:

```text
hosts
events
config
jails
reputation
jail_profile
sanction_state
```

La base de datos de la instalación v2 se encuentra en:

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

Los eventos constituyen el historial de actividad procesado por ARE y también son utilizados por las estadísticas de Jails.

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
Policy
  │
  ▼
Apply
```

El procesamiento de `FOUND` mediante el Sensor Framework y su integración con el Policy Engine fueron validados durante la evolución del proyecto.

---

# Ban

Procesar un evento de ban:

```bash
are ban <IP> <JAIL>
```

El Jail proporciona el contexto utilizado por ARE para procesar el evento.

Las decisiones de aplicación incluyen `FILTER`, `TEMP_BAN` y `BAN`.

El backend utiliza conjuntos separados para filtrado y bloqueo, tanto para IPv4 como para IPv6.

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

ARE vuelve a evaluar la dirección mediante el Policy Engine y aplica la decisión resultante. Este comportamiento fue validado en producción.

---

# Autoban

Ejecutar el mecanismo de enforcement automático:

```bash
are autoban
```

---

# Reputation Decay

ARE dispone de Reputation Decay para reducir progresivamente la reputación de direcciones IP sin actividad reciente.

Los parámetros documentados son:

```text
DECAY_MIN_AGE=86400
DECAY_FACTOR=0.95
```

Esto corresponde a un mínimo de 24 horas sin actividad y un factor inicial de reducción de `0.95`.

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

* reduce el score;
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

# Fail2Ban Sensor

ARE mantiene un Sensor Framework para Fail2Ban.

Los eventos procesados por el sensor son:

```text
FOUND
EXTERNAL_UNBAN
```

El sensor utiliza un cursor persistente para procesar nuevos eventos.

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
* reglas de firewall;
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

La estructura v2 fue validada sobre la instalación activa de `/opt/are`, incluyendo Product Manifest, enlaces oficiales, Installer Engine, base de datos y servicio de Reputation Decay.

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
Policy
   │
   ▼
Decision
   │
   ▼
Apply
   │
   ▼
Firewall
```

Fail2Ban actúa como fuente de eventos mediante el Sensor Framework.

ARE mantiene la reputación y el estado, determina la decisión mediante el Policy Engine y ejecuta la acción correspondiente mediante el backend.

---

# Buenas prácticas

* Verificar la instalación después de operaciones de mantenimiento.
* Mantener protegida la configuración.
* Mantener copias de seguridad de los datos persistentes.
* Revisar periódicamente eventos y estadísticas.
* Supervisar el estado de los sensores y las decisiones aplicadas.

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

---

# Versión

Esta guía corresponde a:

```text
ARE v2.0
```

La estructura v2 utiliza `/opt/are` como Core y `/var/lib/are/are.db` como base persistente.

---

# Referencias

Para información adicional consultar:

```text
README.md
docs/ARCHITECTURE.md
docs/DESIGN.md
docs/INSTALL.md
docs/DEVELOPMENT.md
docs/SECURITY.md
docs/CHANGELOG.md
```

Esta guía contiene únicamente procedimientos y capacidades respaldados por la documentación y las implementaciones verificadas disponibles para ARE v2.0.

