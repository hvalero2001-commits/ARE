# ARE Architecture

## Introducción

ARE (Abuse Reputation Engine) ha sido diseñado bajo una arquitectura modular, desacoplada y orientada a motores de decisión.

Cada componente posee una responsabilidad específica, permitiendo extender el sistema sin modificar el núcleo del proyecto.

La filosofía principal de ARE es separar la detección de amenazas de la toma de decisiones.

---

# Arquitectura general

```text
                 +----------------------+
                 |     ModSecurity      |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |      Fail2Ban        |
                 +----------+-----------+
                            |
             +--------------+--------------+
             |                             |
             v                             v
     +------------------+         +------------------+
     | Action Backend   |         |     Sensors      |
     | BAN / UNBAN      |         | Fail2Ban FOUND   |
     +--------+---------+         +--------+---------+
              \                         /
               \                       /
                +---------------------+
                |         ARE         |
                +---------------------+
                | Reputation Engine   |
                | State Engine        |
                | Policy Engine       |
                +----------+----------+
                           |
                           v
                +---------------------+
                | Firewall Backend    |
                +----------+----------+
                           |
                           v
                    IPSet / Firewall
```

---

# Componentes

## Sensors

Los sensores constituyen la capa de observación de ARE.

Su única responsabilidad es transformar eventos generados por sistemas externos en eventos internos comprensibles para el motor de reputación.

Los sensores nunca toman decisiones de seguridad.

La arquitectura incorpora una capa de sensores para desacoplar las fuentes de eventos del núcleo de ARE.

Actualmente el primer sensor implementado es:

- Fail2Ban Sensor (FOUND)

La arquitectura permite incorporar nuevos sensores sin modificar el núcleo del sistema.

Ejemplos futuros:

- ModSecurity
- Suricata
- Zeek
- CrowdSec
- Apache
- Syslog

---

## Reputation Engine

Responsable de mantener la reputación histórica de cada dirección IP.

Cada evento recibido incrementa la puntuación correspondiente a una categoría determinada.

Categorías actuales:

- EXPLOIT
- RECON
- PROTOCOL
- CREDENTIAL
- ANOMALY

Toda la reputación permanece almacenada de forma persistente en SQLite.

---

## State Engine

Determina el estado operativo actual de una dirección IP.

Estados implementados:

- NEW
- WATCH
- FILTER
- BANNED

El estado representa la evolución histórica del comportamiento observado y no únicamente el último evento recibido.

---

## Policy Engine

Evalúa la reputación y el estado actual para determinar la acción más adecuada.

Decisiones disponibles:

- ALLOW
- WATCH
- FILTER
- TEMP_BAN
- BAN

El Policy Engine permanece completamente desacoplado del backend encargado de ejecutar dichas acciones.

---

## Firewall Backend

Es la única capa responsable de interactuar con el sistema operativo.

Actualmente se implementa un backend basado en IPSet.

La arquitectura permite incorporar nuevos backends sin modificar el núcleo de ARE.

Backends previstos:

- IPSet
- nftables
- firewalld
- pf
- Cloud Firewall
- APIs externas

---

## SQLite

Toda la información persistente del sistema se almacena en SQLite.

Actualmente ARE mantiene:

- reputación
- estados
- eventos
- perfiles de jail
- configuración

---

# Flujo de procesamiento

1. Un sistema externo detecta un evento.
2. El sensor correspondiente transforma dicho evento al formato interno de ARE.
3. Se identifica el perfil de reputación asociado al evento.
4. Se calcula el score correspondiente.
5. Se actualiza la reputación.
6. Se recalcula el estado.
7. El Policy Engine genera una decisión.
8. El Firewall Backend ejecuta la acción correspondiente.
9. El evento queda registrado en la base de datos.

---

# Filosofía del proyecto

ARE no sustituye los sistemas de detección existentes.

Los sistemas externos actúan como fuentes de eventos.

ARE interpreta dichos eventos, mantiene una reputación persistente y decide cuál debe ser la respuesta más adecuada según el comportamiento histórico observado.

La inteligencia y la toma de decisiones residen exclusivamente en ARE.

---

# Diseño modular

La arquitectura busca mantener un bajo acoplamiento entre componentes.

Cada módulo debe cumplir una única responsabilidad.

Este diseño facilita:

- mantenimiento
- pruebas
- ampliaciones
- incorporación de nuevos sensores
- incorporación de nuevos backends
- evolución del motor de decisión

---

# Compatibilidad

Versión 1

- Linux
- SQLite
- Fail2Ban
- ModSecurity
- IPSet
- iptables
- ip6tables

---

# Evolución

La arquitectura ha sido diseñada para permitir la incorporación de nuevas capacidades sin modificar el núcleo del sistema.

Las futuras versiones podrán añadir:

- nuevos sensores
- nuevos motores
- nuevos backends
- nuevas fuentes de eventos
- nuevos mecanismos de reputación

manteniendo la misma arquitectura modular y desacoplada.

---

## Principios de diseño

### Una única responsabilidad

Cada motor de ARE debe cumplir una única responsabilidad claramente definida.

### Separación entre decisión y ejecución

ARE decide qué hacer.

Los backends ejecutan la acción correspondiente.

### Persistencia del conocimiento

Toda decisión importante debe mantenerse de forma persistente.

ARE distingue entre:

- historial de eventos
- reputación
- estado de sanción

### Configuración desacoplada

Toda política debe residir en `/etc/f2b-ipset`.

Los motores nunca contendrán parámetros de configuración embebidos.

### Evolución basada en evidencia

ARE ha sido diseñado y validado sobre tráfico real en un entorno de producción.

Las decisiones de arquitectura se fundamentan en el comportamiento observado y no únicamente en modelos teóricos.
