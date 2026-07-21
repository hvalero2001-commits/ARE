# ARE Architecture

## Introducción

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para desacoplar completamente la detección de amenazas de la aplicación de contramedidas.

La arquitectura está basada en componentes independientes, donde cada motor posee una única responsabilidad y puede evolucionar sin afectar al resto del sistema.

Esta separación permite incorporar nuevas fuentes de eventos, nuevas políticas y nuevos mecanismos de respuesta manteniendo un núcleo estable.

---

# Arquitectura general

```text
                 +----------------------+
                 |  External Systems    |
                 +----------+-----------+
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v

   ModSecurity         Fail2Ban            Future Sensors
                                              (SSH, Zeek,
                                           Suricata, etc.)

                            │
                            ▼

                     Sensor Framework

                            │
                            ▼

               +---------------------------+
               |     Reputation Engine      |
               +-------------+-------------+
                             │
                             ▼
               +---------------------------+
               |       State Engine        |
               +-------------+-------------+
                             │
                             ▼
               +---------------------------+
               |      Policy Engine        |
               +-------------+-------------+
                             │
                             ▼
               +---------------------------+
               |   Firewall Backend API    |
               +-------------+-------------+
                             │
              +--------------+--------------+
              |                             |
              ▼                             ▼

            IPSet                  Future Backends
                               (nftables, pf,
                              firewalld, APIs)

```

---

# Componentes

## Sensor Framework

El Sensor Framework constituye la capa de observación de ARE.

Su única responsabilidad consiste en transformar eventos provenientes de sistemas externos al formato interno utilizado por el motor de reputación.

Los sensores nunca:

- calculan reputación;
- modifican estados;
- aplican bloqueos;
- toman decisiones.

Actualmente se encuentra implementado:

- Fail2Ban Sensor (`FOUND`).

La arquitectura permite incorporar nuevos sensores sin modificar el núcleo de ARE.

Ejemplos previstos:

- ModSecurity;
- SSH;
- Suricata;
- Zeek;
- CrowdSec;
- Syslog;
- Apache;
- DNS;
- APIs externas.

---

## Reputation Engine

El Reputation Engine mantiene la reputación histórica de cada dirección IP.

Cada evento incrementa la puntuación correspondiente según el perfil de reputación asociado.

Categorías soportadas:

- RECON
- EXPLOIT
- CREDENTIAL
- PROTOCOL
- ANOMALY
- MALWARE
- DOS
- SOCIAL

Toda la reputación permanece almacenada de forma persistente mediante SQLite.

---

## State Engine

El State Engine determina el estado operativo de cada dirección IP.

Estados:

- NEW
- WATCH
- FILTER
- BANNED

---

## Policy Engine

Evalúa:

- reputación;
- estado;
- políticas.

Decisiones:

- ALLOW
- WATCH
- FILTER
- TEMP_BAN
- BAN

---

## Ban Lifecycle Engine

Administra la evolución de las sanciones aplicadas por el Policy Engine.

---

## Firewall Backend

Único componente autorizado para modificar el sistema operativo.

Backends actuales:

- IPSet
- iptables
- ip6tables

Backends previstos para v2:

- nftables
- firewalld
- pf
- Cloud Firewall

---

## SQLite

Persistencia de:

- reputación;
- estados;
- eventos;
- configuración;
- historial de sanciones.

---

## Installer Engine

Administra:

- install
- upgrade
- repair
- verify
- uninstall

---

# Flujo

```text
Evento
    │
    ▼
Sensor Framework
    │
    ▼
Reputation Engine
    │
    ▼
State Engine
    │
    ▼
Policy Engine
    │
    ▼
Ban Lifecycle Engine
    │
    ▼
Firewall Backend
    │
    ▼
Sistema operativo
```

---

# Principios arquitectónicos

- Una responsabilidad por componente.
- Separación entre decisión y ejecución.
- Persistencia del conocimiento.
- Configuración desacoplada.
- Bajo acoplamiento.
- Alta cohesión.
- Evolución incremental.

---

# Compatibilidad

Versión 1.1

- Linux
- SQLite
- Fail2Ban
- ModSecurity
- IPSet
- iptables
- ip6tables
- systemd

---

# Evolución

La arquitectura ha sido diseñada para permitir el crecimiento del proyecto manteniendo estable el núcleo.

Las capacidades que amplían el alcance del producto (nuevos sensores, nuevos backends, API y arquitectura distribuida) forman parte del Roadmap de la v2.
