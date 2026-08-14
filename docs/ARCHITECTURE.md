ARE Architecture
Introducción

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para desacoplar la detección de amenazas de la aplicación de contramedidas.

La arquitectura está basada en componentes con responsabilidades diferenciadas, donde los eventos son procesados mediante reputación, estado y política antes de aplicar una contramedida.

Esta separación permite incorporar nuevas fuentes de eventos y evolucionar las políticas manteniendo separado el procesamiento de eventos de la aplicación de acciones sobre el sistema.

Arquitectura general
                 +----------------------+
                 |  External Systems    |
                 +----------+-----------+
                            |
                            v


                    Sensor Framework
                            |
                            v
                  +-------------------+
                  | Reputation Engine |
                  +---------+---------+
                            |
                            v
                    +---------------+
                    |  State Engine |
                    +-------+-------+
                            |
                            v
                    +---------------+
                    | Policy Engine  |
                    +-------+-------+
                            |
                            v
                    +---------------+
                    | Policy Apply   |
                    +-------+-------+
                            |
          +-----------------+------------------+
          |                 |                  |
          v                 v                  v
        ALLOW            WATCH              FILTER
                            |
                            |
                            v
                          BAN
                            |
                            |
                       TEMP_BAN
                            |
                            v
                  Ban Lifecycle Engine
                            |
                            v
                   Firewall Backend
                            |
                            v
                    Operating System
Componentes
Sensor Framework

El Sensor Framework constituye la capa de observación de ARE.

Su responsabilidad consiste en procesar eventos provenientes de sistemas externos y convertirlos en acciones internas que ARE pueda procesar.

En la versión 1.1 se encuentra implementado el sensor de Fail2Ban.

El sensor procesa actualmente:

FOUND
EXTERNAL_UNBAN

Los eventos FOUND son enviados a ARE mediante:

f2b-ipset.sh found <IP> <JAIL>

Los eventos EXTERNAL_UNBAN son enviados mediante:

f2b-ipset.sh external-unban <IP> <JAIL>

El sensor de Fail2Ban admite los siguientes perfiles de jail:

modsec-*
recidive
sshd
telnet

El procesamiento puede ejecutarse en modo de observación (--dry-run) o ejecución (--execute).

La arquitectura permite incorporar nuevas fuentes de eventos sin modificar el mecanismo central de procesamiento.

Reputation Engine

El Reputation Engine mantiene la reputación acumulada de cada dirección IP.

La reputación se almacena persistentemente en SQLite.

ARE v1.1 utiliza las siguientes categorías:

RECON
EXPLOIT
CREDENTIAL
PROTOCOL
BOT
ANOMALY
MALWARE
DOS
SOCIAL

Cada evento puede incrementar la puntuación correspondiente a su categoría según el perfil de reputación asociado al jail.

El total_score representa la suma de las puntuaciones de todas las categorías de reputación.

State Engine

El State Engine determina el estado operativo de una dirección IP a partir de su puntuación total.

Estados utilizados por ARE v1.1:

NEW
WATCH
FILTER
BANNED_TEMP
BANNED

La actualización normal del estado mediante state_update() utiliza los siguientes umbrales:

Puntuación	Estado
0	NEW
1–19	WATCH
20–49	FILTER
50–79	WATCH
≥80	BANNED

BANNED_TEMP forma parte del ciclo de sanción temporal y de las transiciones de estado, pero no es asignado directamente por state_update().

Policy Engine

El Policy Engine evalúa la puntuación de reputación y el estado actual para producir una decisión.

Las decisiones utilizadas por ARE v1.1 son:

ALLOW
WATCH
FILTER
TEMP_BAN
BAN

La política aplica un bloqueo inmediato cuando el estado actual es BANNED.

Los umbrales efectivos de la política son:

Condición	Decisión
Estado BANNED	BAN
Score ≥ 200	TEMP_BAN
Score ≥ 150	BAN
Score ≥ 100	WATCH
Score < 100	ALLOW

La decisión producida por el Policy Engine es posteriormente entregada al mecanismo de aplicación de políticas.

Policy Apply

Policy Apply ejecuta la decisión producida por el Policy Engine.

Las acciones soportadas son:

ALLOW
WATCH
FILTER
TEMP_BAN
BAN

ALLOW y WATCH no aplican un bloqueo de firewall.

FILTER incorpora la dirección IP al conjunto de filtrado.

BAN incorpora la dirección IP al conjunto de bloqueo permanente y establece el estado BANNED.

TEMP_BAN delega el cálculo de la sanción en el Ban Lifecycle Engine antes de aplicar el bloqueo correspondiente.

Ban Lifecycle Engine

El Ban Lifecycle Engine administra la duración y escalamiento de las sanciones temporales.

Se utiliza cuando Policy Apply recibe una decisión TEMP_BAN.

El motor determina si corresponde:

aplicar una sanción temporal;
escalar la sanción a un bloqueo permanente.

Cuando corresponde una sanción temporal, se calcula el momento de finalización y se aplica el timeout correspondiente al conjunto de bloqueo.

Cuando corresponde una escalada permanente, la dirección IP pasa a un bloqueo permanente.

Firewall Backend

El Firewall Backend constituye la capa encargada de aplicar las contramedidas de red sobre el sistema operativo.

ARE v1.1 utiliza:

IPSet para almacenar las direcciones IP;
iptables para las reglas IPv4;
ip6tables para las reglas IPv6.

Se utilizan conjuntos independientes para:

FILTER
BAN

El backend instala reglas de firewall que bloquean las direcciones contenidas en dichos conjuntos.

SQLite

SQLite proporciona la persistencia de ARE.

La base de datos almacena información relacionada con:

reputación;
estados;
eventos;
perfiles de jail;
configuración;
información relacionada con sanciones.
Installer Engine

El Installer Engine administra las operaciones de instalación y mantenimiento del sistema ARE.

Las operaciones contempladas por el instalador son:

install
upgrade
repair
verify
uninstall
Flujo de procesamiento
Evento Fail2Ban
      |
      v
Sensor Framework
      |
      v
FOUND / EXTERNAL_UNBAN
      |
      v
ARE
      |
      +----------------------+
      |                      |
      v                      v
Reputation Engine      External Unban
      |
      v
State Engine
      |
      v
Policy Engine
      |
      v
Policy Apply
      |
      +---------+---------+---------+---------+
      |         |         |         |         |
      v         v         v         v         v
    ALLOW     WATCH     FILTER     BAN    TEMP_BAN
                                      |         |
                                      |         v
                                      |   Ban Lifecycle
                                      |      Engine
                                      |         |
                                      +---------+
                                            |
                                            v
                                     Firewall Backend
                                            |
                                            v
                                      Operating System
Principios arquitectónicos
Separación entre detección y aplicación de contramedidas.
Responsabilidades diferenciadas entre sensores, reputación, estado y política.
Separación entre decisión y ejecución.
Persistencia de la reputación y del estado.
Aplicación centralizada de las decisiones.
Uso de SQLite como persistencia local.
Uso de IPSet como mecanismo de almacenamiento de direcciones bloqueadas o filtradas.
Aplicación de reglas mediante iptables e ip6tables.
Compatibilidad

ARE v1.1 está diseñado para ejecutarse sobre:

Linux
Bash
SQLite
Fail2Ban
IPSet
iptables
ip6tables
systemd

La integración de eventos implementada en esta versión utiliza Fail2Ban como fuente de eventos.

Evolución

ARE v1.1 constituye la versión operativa documentada en este release.

Las futuras ampliaciones del producto deben incorporarse mediante cambios explícitos de arquitectura y documentación en versiones posteriores.

You have not enough Humanizer words left. Upgrade your Surfer plan.
