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
                 |  Sensor de eventos   |
                 +----------+-----------+
                            |
                            v
                  +--------------------+
                  |        ARE         |
                  +--------------------+
                  | Reputation Engine  |
                  | State Engine       |
                  | Policy Engine      |
                  +----------+---------+
                             |
                             v
                  +--------------------+
                  | Firewall Backend   |
                  +----------+---------+
                             |
                             v
                   IPSet / Firewall
```

---

# Componentes

## Reputation Engine

Responsable de mantener la reputación histórica de cada dirección IP.

Cada evento recibido incrementa la puntuación correspondiente a una categoría determinada.

Las categorías actuales son:

* EXPLOIT
* RECON
* PROTOCOL
* CREDENTIAL
* ANOMALY

La reputación permanece almacenada en SQLite.

---

## State Engine

Determina el estado operativo de una IP.

Estados implementados en la versión 1:

* NEW
* WATCH
* FILTER
* BANNED

El estado representa la evolución del comportamiento observado y no únicamente el último evento recibido.

---

## Policy Engine

Evalúa la reputación y el estado actual para decidir la acción que debe ejecutarse.

Las decisiones disponibles son:

* ALLOW
* WATCH
* FILTER
* TEMP_BAN
* BAN

El motor de políticas permanece completamente independiente del backend utilizado para aplicar dichas acciones.

---

## Firewall Backend

Es la única capa responsable de interactuar con el sistema operativo.

En la versión 1 se implementa un backend basado en IPSet.

El diseño permite incorporar nuevos backends sin modificar el núcleo de ARE.

Ejemplos futuros:

* nftables
* firewalld
* pf
* APIs externas
* Cloud Firewall

---

## SQLite

Toda la información persistente se almacena en SQLite.

Actualmente ARE mantiene:

* reputación
* estados
* eventos
* perfiles de jail

---

# Flujo de procesamiento

1. Fail2Ban detecta un evento.
2. El evento es enviado a ARE.
3. Se identifica el perfil del jail.
4. Se calcula el score correspondiente.
5. Se actualiza la reputación.
6. Se recalcula el estado.
7. El Policy Engine genera una decisión.
8. El backend aplica dicha decisión.
9. Se registra el evento en la base de datos.

---

# Filosofía del proyecto

ARE no sustituye a Fail2Ban.

Fail2Ban actúa como sensor de eventos.

ARE interpreta esos eventos, mantiene una reputación persistente y decide cuál debe ser la respuesta más adecuada según el comportamiento histórico de la dirección IP.

La inteligencia reside en ARE.

---

# Diseño modular

La arquitectura busca mantener un bajo acoplamiento entre componentes.

Cada módulo debe cumplir una única responsabilidad.

Esto facilita:

* mantenimiento
* pruebas
* ampliaciones
* incorporación de nuevos backends
* evolución del motor de decisión

---

# Compatibilidad

Versión 1

* Linux
* SQLite
* Fail2Ban
* ModSecurity
* IPSet
* iptables
* ip6tables

---

# Evolución

La arquitectura ha sido diseñada para permitir la incorporación de nuevas capacidades sin modificar el núcleo del sistema.

Las futuras versiones podrán añadir nuevos motores, backends y fuentes de eventos manteniendo la misma estructura general.

