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
Escala a BAN cuando se alcanza el nivel máximo configurado.
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

El tiempo utilizado para una sanción depende exclusivamente del nivel siguiente calculado y de su configuración correspondiente.

Escalamiento

Antes de seleccionar la duración, el motor comprueba:

NEXT_LEVEL >= BAN_LEVEL_MAX

Cuando esta condición se cumple, el motor devuelve:

BAN|0|BAN_LEVEL_MAX

Esto indica que la sanción debe escalar a un bloqueo permanente.

No se calcula un timeout para esta situación.

TEMP_BAN

Cuando el nivel siguiente no alcanza BAN_LEVEL_MAX, el motor devuelve:

TEMP_BAN|TIME|BAN_LEVEL_N

donde:

TIME es el tiempo configurado para el nivel;
N es el siguiente nivel de sanción.

Por ejemplo:

TEMP_BAN|3600|BAN_LEVEL_1

representa una sanción temporal correspondiente al nivel 1 con una duración de 3600 segundos.

BAN

Cuando se alcanza el nivel máximo configurado, el Ban Lifecycle Engine devuelve:

BAN|0|BAN_LEVEL_MAX

La aplicación de este resultado corresponde posteriormente a Policy Apply.

El Ban Lifecycle Engine no modifica directamente los conjuntos IPSet ni las reglas de firewall.

Persistencia

El nivel de sanción se mantiene de forma persistente mediante SQLite.

El Ban Lifecycle Engine utiliza la información almacenada para determinar la siguiente sanción.

La reputación y los eventos pertenecen a otros componentes del sistema y no son modificados directamente por este motor.

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

En ARE v1.1 estos mecanismos utilizan:

IPSet;
iptables;
ip6tables.
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
modificar directamente el firewall.
Resumen

El ciclo de una sanción temporal en ARE v1.1 es:

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
   |                  |
   +--------+---------+
            |
            v
       Policy Apply
            |
            v
      Firewall Backend
