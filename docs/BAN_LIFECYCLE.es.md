ARE Ban Lifecycle
Introducción

El Ban Lifecycle Engine es el componente encargado de calcular la siguiente sanción cuando el Policy Engine determina que corresponde una sanción temporal (TEMP_BAN).

Su responsabilidad es determinar el nivel de sanción siguiente a partir del nivel de ban actualmente registrado para una dirección IP y de los tiempos configurados para cada nivel.

El Ban Lifecycle Engine no determina si una dirección IP representa una amenaza. Esa responsabilidad corresponde al flujo de reputación, estado y política.

Tampoco modifica directamente el firewall. La aplicación de la sanción corresponde a Policy Apply.

Objetivo

El objetivo del Ban Lifecycle Engine es proporcionar una progresión consistente de las sanciones temporales.

Para cada solicitud de TEMP_BAN, el motor:

Inicializa el registro de sanción de la IP si es necesario.
Obtiene el nivel de ban actual.
Incrementa el nivel en uno.
Determina la duración correspondiente al nuevo nivel.
Devuelve la sanción calculada.
Escala a BAN permanente cuando se alcanza el nivel máximo configurado.

Responsabilidad

La función principal del componente es:

ban_lifecycle_calculate()

Recibe:

dirección IP.

Utiliza:

nivel de ban almacenado en SQLite;
BAN_LEVEL_MAX;
tiempos configurados para los niveles de sanción.

Devuelve una decisión con el formato:

ACCIÓN|TIEMPO|RAZÓN

Ejemplos:

TEMP_BAN|3600|BAN_LEVEL_1

BAN|0|BAN_LEVEL_MAX

Flujo
Policy Engine
      |
      | TEMP_BAN
      v
Policy Apply
      |
      v
Ban Lifecycle Engine
      |
      +--> Obtener ban_level
      |
      +--> Incrementar nivel
      |
      +--> Comparar con BAN_LEVEL_MAX
      |
      +-------------------------+
      |                         |
      v                         v
  Nivel disponible          Nivel máximo
      |                         |
      v                         v
 TEMP_BAN                      BAN
      |                         |
      v                         v
 Tiempo configurado       Escalamiento permanente

Nivel de sanción

El nivel actual de sanción se obtiene desde la información persistente asociada a la dirección IP.

El siguiente nivel se calcula como:

NEXT_LEVEL = CURRENT_LEVEL + 1

Si no existe un nivel registrado, el nivel actual se considera 0.

Por lo tanto, la primera sanción temporal corresponde al nivel 1.

Niveles temporales

El Ban Lifecycle Engine utiliza los tiempos configurados para los siguientes niveles:

BAN_LEVEL_1_TIME
BAN_LEVEL_2_TIME
BAN_LEVEL_3_TIME
BAN_LEVEL_4_TIME
BAN_LEVEL_5_TIME
BAN_LEVEL_6_TIME

El nivel siguiente, BAN_LEVEL_7 (BAN_LEVEL_MAX), no tiene un tiempo configurado — corresponde al escalamiento a bloqueo permanente, ver sección "Escalamiento".

El tiempo utilizado para una sanción depende exclusivamente del nivel siguiente calculado y de su configuración correspondiente.

Un nivel cuyo tiempo configurado exceda el máximo soportado por el Firewall Backend (ver sección "Firewall Backend" e "IPSET_MAX_TIMEOUT") se ajusta automáticamente a ese límite en el momento de aplicar la sanción — el nivel registrado en sanction_state refleja la escalada real, aunque el timeout efectivamente aplicado al firewall pueda ser menor al configurado para ese nivel.

Escalamiento

Antes de seleccionar la duración, el motor comprueba:

NEXT_LEVEL >= BAN_LEVEL_MAX

Cuando esta condición se cumple, el motor devuelve:

BAN|0|BAN_LEVEL_MAX

Esto indica que la sanción debe escalar a un bloqueo permanente.

No se calcula un timeout para esta situación.

Un bloqueo permanente no es alcanzado por el Reputation Decay Engine — su liberación requiere una decisión administrativa explícita, no una recuperación automática por inactividad.

TEMP_BAN

Cuando el nivel siguiente no alcanza BAN_LEVEL_MAX, el motor devuelve:

TEMP_BAN|TIME|BAN_LEVEL_N

donde:

TIME es el tiempo configurado para el nivel;
N es el siguiente nivel de sanción.

Por ejemplo:

TEMP_BAN|3600|BAN_LEVEL_1

representa una sanción temporal correspondiente al nivel 1 con una duración de 3600 segundos.

Mientras una sanción temporal permanece activa, el Reputation Decay Engine reduce el score de la IP de forma periódica, aplicando la reducción sobre el total agregado y redistribuyéndola proporcionalmente entre las categorías activas de esa IP — no se trunca cada categoría de forma independiente. Esto evita que una IP con actividad repartida entre varias categorías decaiga más rápido que otra con actividad concentrada en una sola, ante el mismo score total. El decay no adelanta ni acorta el timeout ya aplicado al Firewall Backend para una sanción en curso; su efecto se refleja en la evaluación de la siguiente reincidencia.

BAN

Cuando se alcanza el nivel máximo configurado, el Ban Lifecycle Engine devuelve:

BAN|0|BAN_LEVEL_MAX

La aplicación de este resultado corresponde posteriormente a Policy Apply.

El Ban Lifecycle Engine no modifica directamente los conjuntos IPSet ni las reglas de firewall.

Persistencia

El nivel de sanción se mantiene de forma persistente mediante SQLite.

El Ban Lifecycle Engine utiliza la información almacenada para determinar la siguiente sanción.

La reputación y los eventos pertenecen a otros componentes del sistema y no son modificados directamente por este motor.

Una sanción activa (permanente o temporal, con su tiempo restante exacto) se restaura en el Firewall Backend a partir de esta misma información persistente cuando el sistema operativo se reinicia — ver sección "Firewall Backend".

Relación con Policy Engine

El Policy Engine determina que una dirección IP requiere una sanción mediante la decisión:

TEMP_BAN

Policy Apply recibe esa decisión y solicita al Ban Lifecycle Engine calcular la sanción concreta.

El Ban Lifecycle Engine puede devolver:

TEMP_BAN
BAN

Por lo tanto, el flujo es:

Policy Engine
      |
      v
TEMP_BAN
      |
      v
Policy Apply
      |
      v
Ban Lifecycle Engine
      |
      +--------+
      |        |
      v        v
 TEMP_BAN    BAN

Relación con Policy Apply

Ban Lifecycle Engine calcula la sanción.

Policy Apply ejecuta el resultado.

Cuando el resultado es TEMP_BAN, Policy Apply:

calcula el momento de expiración;
incrementa el nivel de ban;
registra la sanción;
ajusta el timeout calculado al máximo soportado por el Firewall Backend, si lo excede;
aplica el timeout al IPSet;
establece el estado correspondiente.

Cuando el resultado es BAN, Policy Apply:

establece el nivel máximo;
marca la sanción como permanente;
elimina contenciones anteriores;
incorpora la IP al conjunto de ban sin timeout;
registra el evento;
establece el estado BANNED.

Firewall Backend

El Ban Lifecycle Engine no interactúa directamente con el firewall.

La modificación del sistema operativo corresponde a Policy Apply mediante los mecanismos de backend utilizados por ARE.

Desde ARE v2.0, este mecanismo utiliza exclusivamente:

IPSet.

iptables e ip6tables ya no forman parte del Firewall Backend de ARE — la gestión directa de reglas de firewall fue reemplazada por el uso exclusivo de conjuntos IPSet, que ARE administra de forma completa, incluyendo su restauración al arrancar el sistema (IPSet no persiste su contenido de forma nativa entre reinicios; ARE lo repuebla desde sanction_state y reputation al inicio, preservando el tiempo restante exacto de las sanciones temporales activas).

El tiempo máximo que IPSet admite para un timeout está limitado (IPSET_MAX_TIMEOUT, en config/policy.conf). Cualquier duración calculada por el Ban Lifecycle Engine que exceda ese límite se ajusta al máximo soportado antes de aplicarse — ver sección "Niveles temporales".

Principios

El Ban Lifecycle Engine mantiene una responsabilidad específica:

calcular la siguiente sanción;
aplicar la progresión de niveles;
seleccionar el tiempo configurado;
determinar cuándo corresponde escalar a BAN.

No es responsable de:

detectar eventos;
calcular reputación;
determinar el estado general de la IP;
decidir inicialmente si corresponde TEMP_BAN;
modificar directamente el firewall;
restaurar el estado del firewall tras un reinicio del sistema.

Resumen

El ciclo de una sanción temporal en ARE es:

Evento
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
TEMP_BAN
   |
   v
Policy Apply
   |
   v
Ban Lifecycle Engine
   |
   +------------------+
   |                  |
   v                  v
TEMP_BAN             BAN
   |                  |
   v                  v
Tiempo configurado   Nivel máximo
(ajustado al límite   |
 de IPSet si excede)  |
   |                  |
   +--------+---------+
            |
            v
       Policy Apply
            |
            v
      Firewall Backend
