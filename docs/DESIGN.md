# ARE Design

## 1. Propósito

Este documento define los principios y decisiones de diseño que guían la implementación de ARE (Abuse Reputation Engine).

`ARCHITECTURE.md` describe cómo está compuesto el sistema.

`DESIGN.md` describe por qué el sistema está diseñado de esa manera.

Las decisiones documentadas aquí corresponden al diseño implementado y validado. Las propuestas futuras pertenecen al Roadmap o a las RFC correspondientes.

---

# 2. Principios de diseño

## 2.1 Responsabilidad única

Cada componente de ARE debe mantener una responsabilidad claramente definida.

La observación, reputación, estado, decisión, sanción, aplicación y administración del producto no deben mezclarse innecesariamente.

La separación permite:

* reducir acoplamiento;
* facilitar pruebas;
* aislar cambios;
* evitar duplicación de lógica;
* facilitar la evolución del sistema.

---

## 2.2 Separación entre observación y decisión

Los sistemas externos producen eventos.

Los sensores transforman esos eventos en información procesable por ARE.

Los sensores no determinan la respuesta de seguridad.

La decisión corresponde al núcleo de ARE.

El flujo conceptual es:

```text
fuente externa
      |
      v
    sensor
      |
      v
    evento
      |
      v
ARE interpreta
      |
      v
ARE decide
```

Esta separación fue establecida durante v1.1 mediante el Sensor Framework y se mantiene en v2.0.

---

## 2.3 Separación entre decisión y ejecución

El Policy Engine determina la acción.

El mecanismo encargado de aplicar la decisión ejecuta la acción mediante el Firewall Backend.

Por lo tanto:

```text
Policy Engine
      |
      | qué hacer
      v
Apply
      |
      | cómo aplicarlo
      v
Firewall Backend
```

El motor de decisión no debe contener lógica específica innecesaria de un backend concreto.

---

## 2.4 Persistencia del conocimiento

ARE no debe depender exclusivamente del estado momentáneo del sistema externo.

El conocimiento acumulado debe mantenerse de forma persistente.

El modelo distingue entre:

```text
events
    |
    +-- actividad observada

reputation
    |
    +-- conocimiento acumulado

sanction_state
    |
    +-- estado de sanción
```

Esta separación permite reconstruir el estado operativo sin confundir el historial de eventos con la reputación o con el ciclo de sanciones.

---

# 3. Modelo de reputación

## 3.1 Reputación acumulada

La reputación representa el comportamiento observado de una dirección IP.

Un evento individual puede modificar la reputación, pero la decisión no debe depender exclusivamente del último evento.

La información histórica es parte fundamental del modelo de ARE.

---

## 3.2 Categorías

Las categorías de reputación permiten clasificar diferentes tipos de comportamiento.

El modelo fue ampliado durante v1.1 y constituye la base utilizada por v2.0.

Los jails no se convierten en columnas independientes de la tabla `reputation`.

La relación entre un jail y una categoría se mantiene mediante `jail_profile`.

Esto permite agregar o modificar perfiles sin modificar la estructura principal de reputación.

El catálogo de categorías soportadas se mantiene explícitamente en
`config/policy.conf` mediante `REPUTATION_CATEGORIES`, como fuente única
de verdad consumida tanto por el modelo de reputación como por la
interfaz de administración (ver Sección 13).

---

# 4. Modelo de decisión basado en riesgo

ARE utiliza la reputación acumulada, el estado y la política para determinar la respuesta.

El modelo evita tratar el tiempo de bloqueo como la única fuente de decisión.

Conceptualmente:

```text
eventos
   |
   v
reputación
   |
   v
estado
   |
   v
política
   |
   v
decisión
```

La respuesta puede evolucionar según el comportamiento acumulado de la IP.

Esto permite diferenciar entre:

* actividad mínima;
* observación;
* filtrado;
* bloqueo temporal;
* bloqueo permanente.

---

## 4.1 Evaluación de riesgo por categoría

El Policy Engine evalúa el riesgo de una IP por categoría de forma
independiente antes de emitir una decisión. Cada categoría de
reputación (Sección 3.2) tiene una regla propia (`policy/rules/*.sh`)
que conoce únicamente su propio umbral, configurado en `policy.conf`, y
aporta al riesgo total solo si lo supera. Ninguna regla conoce a las
demás ni decide una acción por sí misma — esa responsabilidad
corresponde exclusivamente al orquestador (`policy_evaluate()`).

```text
IP
 |
 v
contexto (score por categoría + actividad reciente)
 |
 v
regla EXPLOIT --\
regla BOT -------\
regla RECON ------ >-- acumulador de riesgo
regla PROTOCOL --/
regla ...       -/
 |
 v
riesgo por categoría
 |
 v
MAX(riesgo por categoría, score total acumulado)  <- piso de seguridad
 |
 v
decisión final
```

El **piso de seguridad** garantiza que el motor por categoría nunca sea
menos estricto que una evaluación por score total simple: puede detectar
más (por ejemplo, una señal de fuerza bruta que ninguna categoría
individual refleja), pero nunca menos. Esto evita que una IP con riesgo
repartido entre varias categorías —cada una por debajo de su propio
umbral— evada la detección aunque su score acumulado total sea alto.

Una categoría sin umbral configurado en `policy.conf` no evalúa —
comportamiento explícito, no un error silencioso — lo que permite
incorporar categorías nuevas de forma progresiva, sin necesidad de
definir su criterio de riesgo de antemano.

---

# 5. Ciclo de vida de una IP

Una dirección IP observada por ARE mantiene información durante todo su ciclo de vida.

El ciclo general es:

```text
observación
     |
     v
reputación
     |
     v
estado
     |
     v
decisión
     |
     v
sanción
     |
     v
recuperación
     |
     v
reevaluación
```

El objetivo es evitar que una IP pierda inmediatamente todo su historial por la desaparición temporal de actividad.

---

# 6. Decay y recuperación

## 6.1 Principio

La reputación puede disminuir gradualmente cuando cesa la actividad relevante.

La recuperación no equivale a eliminar la reputación.

El mecanismo reduce progresivamente el score y permite que ARE vuelva a evaluar el estado y la política.

---

## 6.2 Control de frecuencia

El control de ejecución se separa de la actividad general de la IP.

Para ello se utiliza:

```text
last_decay
```

en `reputation`.

Esto evita utilizar la fecha de última actividad como si fuera la fecha de última ejecución del decay.

El diseño permite distinguir:

```text
última actividad
```

de:

```text
último decay aplicado
```

---

## 6.3 Separación entre recuperación y aplicación

El Decay Engine modifica la reputación y provoca una reevaluación.

No debe confundirse la recuperación de reputación con una orden directa de modificación del firewall.

El flujo es:

```text
Decay
  |
  v
Reputation
  |
  v
State Engine
  |
  v
Policy Engine
  |
  v
decisión
```

La aplicación de esa decisión permanece bajo las responsabilidades correspondientes del sistema.

---

# 7. Ban Lifecycle

## 7.1 Separación de responsabilidades

El Ban Lifecycle Engine no determina si una IP es peligrosa.

Esa decisión pertenece a:

* Reputation Engine;
* State Engine;
* Policy Engine.

Ban Lifecycle determina cómo evoluciona una sanción una vez que la política decide aplicar una acción de sanción.

---

## 7.2 Persistencia

El estado de sanción se mantiene en:

```text
sanction_state
```

La información persistida permite distinguir:

* nivel de sanción;
* cantidad histórica;
* duración;
* finalización;
* permanencia.

Esto permite que la reincidencia tenga consecuencias acumulativas.

---

## 7.3 Escalado

Las sanciones pueden evolucionar progresivamente.

El diseño contempla:

```text
TEMP_BAN
    |
    v
mayor nivel
    |
    v
mayor duración
    |
    v
BAN permanente
```

El escalado se mantiene separado de la determinación inicial del riesgo.

---

# 8. Sensores

Los sensores son adaptadores de entrada.

Su responsabilidad es transformar información externa en eventos que ARE pueda procesar.

Un sensor no debe:

* decidir la política;
* modificar directamente la reputación sin pasar por el flujo definido;
* sustituir al Policy Engine;
* asumir responsabilidades del Firewall Backend.

El Sensor Framework permite incorporar nuevas fuentes sin modificar innecesariamente el núcleo.

La primera implementación oficial es el sensor Fail2Ban.

Actualmente procesa:

```text
FOUND
EXTERNAL_UNBAN
```

y utiliza un offset persistente para evitar reprocesamiento.

---

# 9. Fail2Ban como fuente de eventos

Fail2Ban no constituye la autoridad final de decisión de ARE.

Su función dentro del modelo es proporcionar información sobre actividad observada.

El flujo es:

```text
Fail2Ban
    |
    v
Sensor
    |
    v
ARE
    |
    v
Reputation
    |
    v
Policy
```

Esto permite que ARE conserve una visión acumulada de la IP en lugar de depender exclusivamente de una acción individual de Fail2Ban.

---

# 10. Configuración desacoplada

La configuración no debe estar embebida innecesariamente dentro de los motores.

La configuración operativa se mantiene separada del código del producto.

En v2.0 la estructura oficial utiliza:

```text
/opt/are
/opt/are/config
/var/lib/are
/var/log/are
```

El Product Manifest define qué componentes forman parte del producto y cómo son administrados.

La configuración distribuida con el producto y la configuración activa de una instalación son conceptos diferentes.

El Installer administra esta relación.

---

# 11. Product Manifest

`manifest/product.sh` constituye la definición estructural del producto.

El Manifest centraliza:

* identidad del producto;
* versión;
* directorios;
* archivos;
* configuración;
* datos persistentes;
* ejecutables;
* enlaces;
* systemd;
* logrotate;
* exclusiones.

El Manifest no contiene la lógica de los motores.

Su función es proporcionar una fuente única para que el Installer conozca qué debe administrar.

---

# 12. Installer Engine

El Installer Engine administra el ciclo de vida de la instalación.

Las operaciones son:

```text
install
upgrade
repair
verify
uninstall
```

El diseño mantiene separadas:

```text
producto
configuración
datos persistentes
logs
servicios
enlaces
```

Un `upgrade` puede actualizar componentes del producto sin destruir los datos persistentes.

Un `repair` puede reconstruir componentes faltantes de una instalación incompleta.

Un `verify` comprueba que los componentes requeridos se encuentren presentes y operativos.

Un `uninstall` elimina el producto sin convertir automáticamente los datos persistentes en parte del contenido eliminado.

---

# 13. Interfaz de Administración (ARE ADMIN)

## 13.1 Propósito

ARE ADMIN es la interfaz de administración por línea de comandos de ARE.

Su función es exponer, de forma organizada, las capacidades de consulta, configuración y operación de los componentes ya definidos en este documento.

ARE ADMIN no introduce un nuevo motor ni una nueva autoridad de decisión. Es una capa de administración que se apoya sobre los componentes existentes: Reputation Engine, State Engine, Policy Engine, Sensor Framework, Decay Engine e Installer Engine.

Se accede mediante `are.sh admin`, o directamente mediante `admin.sh` como atajo equivalente. Ambos caminos cargan el mismo `bootstrap.sh` utilizado por el resto del sistema, por lo que ARE ADMIN opera siempre sobre los mismos componentes reales, sin duplicar lógica ni mantener un entorno de carga separado.

---

## 13.2 Principio de diseño

ARE ADMIN respeta la separación de responsabilidades establecida en la Sección 2.

La CLI no decide, no aplica y no sanciona. La CLI consulta, administra y, cuando corresponde, invoca a los motores correspondientes respetando el flujo definido por cada uno de ellos.

En consecuencia:

* ARE ADMIN no modifica directamente la tabla `reputation`;
* ARE ADMIN no modifica directamente el Firewall Backend;
* ARE ADMIN no reemplaza al Policy Engine ni al Decay Engine;
* ARE ADMIN administra `jail_profile`, la configuración desacoplada y el ciclo de vida de la instalación a través de las interfaces ya existentes de cada componente.

---

## 13.3 Estructura del menú

El árbol de navegación de ARE ADMIN refleja directamente la composición de ARE descrita en las secciones anteriores. Cada rama corresponde a un componente ya definido en el diseño.

Dos ramas incorporan, además de las capacidades de consulta originales, un ítem adicional de resumen/diagnóstico que reutiliza comandos ya existentes del Dashboard (`dashboard_stats`, `dashboard_status`), sin introducir lógica nueva:

```text
ARE ADMIN
│
├── 1. Jails / Perfiles
│   ├── Listar
│   ├── Crear
│   ├── Modificar
│   ├── Eliminar
│   └── Validar
│
├── 2. Categorías
│   ├── Listar
│   └── Ver puntuaciones
│
├── 3. Sensores
│   ├── Estado
│   └── Configuración
│
├── 4. Política
│   ├── Ver configuración
│   └── Validar
│
├── 5. Estado / Reputación
│   ├── Consultar IP
│   ├── Eventos
│   ├── Top
│   └── Estadísticas
│
├── 6. Decay
│   ├── Estado
│   ├── Dry-run
│   └── Ejecutar
│
├── 7. Configuración
│   ├── Ver
│   ├── Validar
│   └── Estado del sistema
│
└── 0. Salir
```

---

## 13.4 Correspondencia con los componentes del diseño

Cada rama del menú se apoya en un componente ya definido, sin duplicar su lógica:

* **Jails / Perfiles** administra `jail_profile` (Sección 3.2) mediante un CRUD completo. Crear, Modificar y Eliminar operan sobre la relación jail–categoría, no sobre la estructura de `reputation`. La categoría se restringe a `REPUTATION_CATEGORIES` mediante selección numerada, nunca texto libre. Crear y Modificar ofrecen asistencia de peso/confianza en dos niveles: referencia estadística calculada de perfiles reales existentes en la categoría, o una escala de niveles curada por el administrador (`config/jail_scale.conf`) cuando la categoría la define. Eliminar exige escribir el nombre exacto del jail como confirmación, no solo una respuesta s/N, por ser la única operación destructiva del CRUD. Validar reutiliza el concepto de verificación de consistencia descrito para el Installer Engine (Sección 12), comprobando categoría válida y rangos de peso/confianza.
* **Categorías** expone en modo de solo lectura el modelo de reputación (Sección 3), incluyendo las puntuaciones asociadas a cada categoría. El catálogo de categorías y sus umbrales se leen dinámicamente desde `REPUTATION_CATEGORIES` en `config/policy.conf` (Sección 3.2), evitando que el listado quede hardcodeado en la interfaz.
* **Sensores** expone el estado y la configuración del Sensor Framework (Sección 8), sin permitir que la CLI decida política ni modifique reputación de forma directa. El estado incluye el offset persistente del sensor y el estado del timer de systemd asociado.
* **Política** permite inspeccionar y validar la configuración del Policy Engine (Sección 4), sin ejecutar directamente una decisión sobre una IP concreta. Rama pendiente de implementación: existen definiciones concurrentes del motor de decisión en el código base cuya convivencia no está resuelta; la rama se habilitará una vez identificado el motor canónico (ver `docs/TODO.md`).
* **Estado / Reputación** permite consultar el conocimiento acumulado (Sección 2.4) y el historial de eventos de una IP, obtener un listado priorizado (Top), y consultar un resumen agregado de actividad del sistema (Estadísticas), reutilizando `dashboard_score`, `dashboard_events`, `dashboard_top` y `dashboard_stats` respectivamente.
* **Decay** expone el ciclo descrito en la Sección 6. *Estado* consulta `last_decay` y candidatas actuales; *Dry-run* simula el efecto del Decay Engine sin modificar `reputation` ni provocar una reevaluación real; *Ejecutar* invoca el flujo completo Decay → Reputation → State Engine → Policy Engine (Sección 6.3), delegando la aplicación efectiva de cualquier decisión resultante al mecanismo de Apply ya definido en la Sección 2.3. La operación de Ejecutar requiere confirmación explícita antes de invocarse.
* **Configuración** permite ver y validar la configuración desacoplada (Sección 10), sin embeber dicha configuración en el código de los motores, y consultar el estado operativo general del sistema (base de datos, Decay, Firewall, IPSet) reutilizando `dashboard_status`.

---

## 13.5 Alcance de las operaciones de escritura

Las operaciones de escritura disponibles desde ARE ADMIN se limitan a los elementos de configuración y administración: perfiles de jail y configuración operativa.

ARE ADMIN no ofrece una operación que module directamente `reputation` o `sanction_state`. Cualquier cambio sobre el conocimiento acumulado de una IP resulta exclusivamente de la operación normal de los motores (Sensor Framework, Decay Engine, Policy Engine), y no de una acción manual ejecutada desde la CLI.

Esto preserva la integridad del modelo de reputación descrito en la Sección 3 y evita que la interfaz de administración se convierta en una vía paralela de decisión.

---

## 13.6 Estado de implementación

Las siete ramas definidas en la Sección 13.3 se encuentran implementadas, verificadas mediante pruebas aisladas y confirmadas operando en producción con datos reales: Jails/Perfiles, Categorías, Sensores, Política, Estado/Reputación, Decay y Configuración.

La implementación de la rama Política (ver RFC-009) reveló, a través de su propia validación, una categoría de reputación (`CREDENTIAL`) sin regla de evaluación asociada pese a tener umbral configurado — corregido como parte del mismo trabajo (ver `docs/TODO.md`, BUG-016). Es un ejemplo del propósito de la validación integrada al CLI: detectar inconsistencias entre configuración e implementación antes de que se manifiesten como comportamiento incorrecto silencioso.

---

# 14. Compatibilidad y evolución

v2.0 no se diseña como una ruptura conceptual respecto de v1.1.

La versión estable v1.1 proporcionó la base funcional sobre la que se desarrolló v2.0.

La evolución de v2.0 afectó principalmente:

* identidad del producto;
* estructura operativa;
* instalación;
* persistencia;
* mantenimiento;
* integración del ciclo de recuperación;
* organización de componentes;
* interfaz de administración.

Las capacidades futuras que todavía no hayan sido implementadas y validadas no deben incorporarse como decisiones de diseño ya realizadas.

---

# 15. Diseño basado en evidencia

Las decisiones de diseño de ARE deben surgir de:

1. necesidad identificada;
2. análisis;
3. implementación;
4. prueba;
5. validación;
6. documentación.

La documentación no debe utilizarse para definir retrospectivamente un comportamiento que el sistema todavía no implementa.

El comportamiento real y validado del sistema es la referencia principal para actualizar este documento.

---

# 16. Evolución incremental

ARE debe evolucionar sin introducir cambios innecesarios.

Una modificación debe integrarse en el componente responsable antes que duplicar una capacidad existente.

Cuando una modificación afecta la arquitectura, debe quedar reflejada en la documentación correspondiente.

Las propuestas que todavía no hayan sido implementadas pertenecen al Roadmap o a las RFC y no forman parte del diseño operativo actual.

---

# 17. Estado del diseño

El diseño actual conserva los principios establecidos durante v1.1 y los adapta a la estructura operativa consolidada a través de v2.0, v2.1 y v2.2.

## Decisiones consolidadas en v2.0

* separación entre sensores y decisión;
* separación entre decisión y ejecución;
* persistencia independiente de eventos, reputación y sanciones;
* Ban Lifecycle como componente independiente;
* recuperación mediante Decay;
* configuración desacoplada;
* Product Manifest como definición estructural del producto;
* Installer Engine como administrador del ciclo de vida de instalación;
* interfaz de administración ARE ADMIN como capa de consulta y administración sobre los componentes existentes, sin autoridad de decisión propia, integrada al punto de entrada oficial (`are.sh admin`) y operando sobre el mismo `bootstrap.sh` que el resto del sistema;
* estructura operativa propia de ARE;
* evolución incremental sobre la base estable de v1.1.

## Decisiones consolidadas en v2.1

* modelo de reputación por categoría normalizado (`reputation_scores`), donde incorporar una categoría nueva es una operación de datos y no una migración de esquema ni de código;
* `total_score` derivado siempre como suma de las categorías, en vez de almacenado de forma independiente — elimina estructuralmente la posibilidad de que se desincronice del dato real;
* segundo patrón de sensor formalizado dentro del Sensor Framework: callback (invocación directa y síncrona en el instante del evento), junto al patrón de polling ya existente;
* filtro de jails resuelto dinámicamente contra `jail_profile`, en vez de mantenido como lista fija en el código de cada sensor;
* administración de perfiles entre servidores (exportar/importar), como mecanismo de propagación de calibración sin recrear cada perfil a mano;
* restauración del Firewall Backend desde la base de datos al arrancar el sistema, dado que IPSet no persiste su contenido de forma nativa entre reinicios.

## Decisiones consolidadas en v2.2

* patrón de "adaptador por fuente" dentro de un sensor: la extracción de datos varía según el origen real (hoy, Exim para SpamAssassin), pero el contrato de reporte hacia el Reputation Engine permanece único — sumar una fuente nueva es agregar una función, no reescribir el sensor;
* separación de responsabilidad entre `config.conf` (infraestructura: qué leer y de dónde) y `policy.conf` (calibración de decisión: cuándo algo importa) aplicada también a la configuración de un sensor, no solo a los umbrales globales;
* calibración proactiva de un umbral de categoría sin sensor local disponible (`MALWARE_THRESHOLD`), como decisión consciente de motor genérico — útil para cualquier servidor con superficie real de esa amenaza, no solo el que lo calibra;
* empaquetado y distribución como capa añadida *antes* del Installer Engine, sin modificar su núcleo — el motor de instalación sigue operando exactamente igual, reciba su fuente de un `git clone` o de un paquete descargado y extraído.

## Decisiones consolidadas en v2.3

* el estado de activación de un sensor (`sensor_registry`) es independiente del estado de un jail (`jail_profile`) — desactivar un sensor detiene la generación de eventos nuevos, sin necesidad de tocar ni marcar los perfiles ya existentes; la reputación histórica permanece intacta sin ningún flag adicional;
* el mecanismo de activación de un sensor depende de su patrón, no de una interfaz única: `systemctl` para polling, archivo flag liviano para callback — evaluado explícitamente el costo de consultar la base de datos en cada invocación para un sensor que puede dispararse con mucha frecuencia (callback bajo flood real), y descartado en favor de un chequeo de archivo;
* un motor de riesgo propio decide con su propio criterio, no delega en el veredicto interno de otra herramienta — el sensor de SpamAssassin filtra por score contra `SPAMASSASSIN_MIN_SCORE`, no por el flag booleano "spam"/"NOT spam" que la herramienta externa asigna con su propio criterio interno, potencialmente desalineado del umbral real de riesgo que le importa a ARE.

## Decisiones consolidadas en v2.4

* simplificar un `CREATE TABLE` para instalaciones nuevas no requiere esperar a una versión moderna de SQLite en ningún servidor — solo `ALTER TABLE ... DROP COLUMN` sobre una base ya existente la requiere; separar ambos casos permitió avanzar la mitad del trabajo de inmediato, en vez de bloquear todo por la limitación de un único entorno;
* la instalación debe dejar el producto completamente operativo por sí sola, sin depender de que el operador ejecute ningún paso manual después — cualquier verificación (`verify`) que dependa de un efecto colateral de una ejecución posterior, en vez de la instalación misma, es una instalación incompleta aunque parezca funcionar en la práctica;
* una dependencia dura (`Requires=`) entre un componente propio y una herramienta externa opcional asume que esa herramienta siempre va a estar presente — cuando el propio componente ya tolera su ausencia de forma limpia (un log inexistente, por ejemplo), la dependencia de systemd debe reflejar eso mismo (`After=`, no `Requires=`), no ser más estricta que la lógica que ya existe;
* validar una demostración con comandos manuales de por medio no es lo mismo que validar la instalación en sí — cualquier verificación de un flujo automatizado debe reproducir exactamente ese flujo, sin intervención humana entre el disparador y la comprobación del resultado.

## Decisiones consolidadas en v2.5

* un sensor puede necesitar correlación con estado (agrupar múltiples eventos por ventana de tiempo) en vez de evaluación línea por línea — el contrato de reporte hacia ARE (`found <IP> <JAIL>`) sigue siendo el mismo, la complejidad de agregación queda encapsulada dentro del sensor, sin tocar el modelo de datos ni el motor de decisión;
* un parámetro de configuración específico de un sensor no debe asumir el caso de uso de quien lo pidió — un marcador de ruta genérico y configurable (`cart`, aplicable a cualquier catálogo de e-commerce) generaliza el sensor mucho más que un valor hardcodeado al negocio puntual que originó la necesidad;
* documentar la evidencia real que justifica un umbral de detección (capturas de correlación real, verificación de infraestructura de origen) antes de calibrarlo, en vez de elegir un número arbitrario — la calibración del `jail_profile` de un sensor nuevo debe poder explicarse con esa misma evidencia, no solo con intuición.

## Decisiones consolidadas en v2.6

* no todo dato compartido entre dos instancias del mismo producto tiene el mismo mecanismo de conflicto correcto — la configuración (`jail_profile`) necesita "sobrescribir/conservar" porque cada campo tiene un único valor válido; la reputación no necesita elegir nada, porque ya está diseñada para acumularse, y el import simplemente reutiliza esa misma acumulación;
* un filtro de relevancia no siempre necesita una decisión explícita del administrador — apoyarse en una estructura que ya existe (`jail_profile`, reflejo del rol real del servidor) resuelve "¿esto le sirve a este servidor?" gratis, sin inventar un concepto nuevo de "rol" en el modelo de datos.

Las capacidades futuras que todavía no hayan sido implementadas y validadas no forman parte del estado actual del diseño; pertenecen al Roadmap o a las RFC correspondientes.

La versión v2.6 se encuentra en desarrollo y validación. Este documento describe únicamente decisiones correspondientes al estado implementado y comprobado.
