# ARE TODO

Este documento mantiene el registro de trabajo y evolución técnica de ARE (Abuse Reputation Engine).

El documento conserva tanto el historial técnico relevante como el trabajo pendiente. Las tareas resueltas permanecen documentadas cuando contienen decisiones, fases, validaciones o información útil para comprender la evolución del proyecto.

Se organiza en:

* Bugs
* Tasks
* Features
* RFC
* Ideas

---

# BUGS

## BUG-002

**Título:** Verificar sincronización Backend ↔ Fail2Ban

**Estado:** En observación

**Prioridad:** Media

**Descripción**

Continuar validando durante la operación en producción que todas las acciones generadas por Fail2Ban sean procesadas correctamente por ARE.

El objetivo es garantizar que la transición entre los eventos generados por Fail2Ban y las decisiones ejecutadas por ARE permanezca sincronizada.

---

# TASKS

## TASK-013

**Título:** Consolidación y limpieza de documentación técnica

**Estado:** En progreso

**Prioridad:** Alta

**Objetivo**

Revisar y normalizar la documentación oficial de ARE para garantizar que refleje el estado real del proyecto y conserve la trazabilidad técnica de su evolución.

**Alcance**

* corregir estados históricos;
* eliminar contradicciones entre documentos;
* conservar decisiones y validaciones relevantes;
* sincronizar versiones;
* separar trabajo histórico de trabajo pendiente;
* mantener la documentación técnica de las fases de implementación;
* evitar pérdida de información durante futuras reorganizaciones documentales.

**Documentos relacionados**

* `docs/PHILOSOPHY.md`
* `docs/PROJECT.md`
* `docs/ROADMAP.md`
* `docs/SECURITY.md`
* `docs/TODO.md`
* `docs/CHANGELOG.md`

---

## TASK-015

**Título:** Eliminar duplicación de `db_get_sanction()` en `database.sh`

**Estado:** Pendiente

**Prioridad:** Baja

**Descripción**

`db_get_sanction()` está definida dos veces en `database.sh`, con contenido
idéntico. No genera comportamiento incorrecto (la segunda definición
sobrescribe a la primera sin cambiar el resultado), pero es ruido que
dificulta la lectura y mantenimiento del archivo.

**Alcance**

Eliminar la primera definición, dejando una sola copia de la función.

**Archivos relacionados**

* `database.sh`

---

## TASK-016

**Título:** Centralizar `LOG_FILE` del sensor Fail2Ban en `config.conf`, y reemplazar el filtro de jails fijo por consulta dinámica a `jail_profile`

**Estado:** ✔ Resuelto

**Prioridad:** Media

**Versión:** v2.1 (en desarrollo)

**Descripción**

`sensors/fail2ban.sh` definía `LOG_FILE="/var/log/fail2ban.log"` como
valor fijo dentro del script, en lugar de tomarlo de
`config/config.conf`. Inconsistente con el principio de centralización
de rutas ya aplicado en TASK-012 para el resto de las variables
operativas.

**Hallazgo adicional durante la resolución**

El mismo archivo tenía un segundo problema del mismo tipo, más
relevante: un filtro fijo de jails permitidos
(`modsec-*|recidive|sshd|telnet`) que determinaba qué eventos `FOUND`
procesar en el camino de polling. Esta lista quedó desactualizada tras
la implementación de RFC-007 (CRUD de `jail_profile`): los perfiles
creados desde entonces (`dovecot`, `postfix-sasl`, `mysqld-auth`,
`apache-badbots`, `mod_evasive`) no estaban en la lista, por lo que sus
eventos `FOUND` se descartaban silenciosamente en el camino de
polling — sin log de error, sin aviso — aunque el jail ya tuviera
perfil administrado en ARE ADMIN.

**Corrección**

* `LOG_FILE` ahora se lee de `FAIL2BAN_LOG_FILE` en `config.conf`, con
  default de compatibilidad (`/var/log/fail2ban.log`) si la variable
  no está definida.
* El filtro fijo de jails fue reemplazado por una consulta dinámica
  contra `jail_profile` (`SELECT COUNT(*) FROM jail_profile WHERE
  name='$JAIL'`) — cualquier jail con perfil administrado se procesa
  automáticamente, sin necesidad de mantener ni actualizar una lista
  en el código cada vez que se crea un perfil nuevo desde el admin.
* Se agregó verificación de existencia del archivo de log antes de
  arrancar, con mensaje de error explícito en vez de fallar
  silenciosamente en el `wc -l`.

**Validación**

Probado en producción con `sqlite3` de referencia (entorno de
desarrollo, sin `sqlite3` instalado directamente): confirmado que
jails ya existentes (`sshd`, `modsec-rce`, `recidive`) siguen
procesándose, jails nuevos que antes se descartaban (`dovecot`,
`postfix-sasl`, `mod_evasive`, `apache-badbots`) ahora se aceptan, y
un jail inventado sin perfil real se sigue descartando correctamente.
Confirmado en el servidor real: `./sensors/fail2ban.sh --dry-run`
corre sin error, y el timer (`are-fail2ban-found.timer`) sigue
procesando eventos reales con normalidad tras el cambio.

**Archivos relacionados**

* `sensors/fail2ban.sh`
* `config/config.conf`

**Archivos relacionados**

* `sensors/fail2ban.sh`
* `config/config.conf`

---

## TASK-017

**Título:** Sincronizar umbrales documentados en `ARCHITECTURE.md` con los valores reales de `policy.conf`

**Estado:** Pendiente

**Prioridad:** Media

**Descripción**

`docs/ARCHITECTURE.md` documenta los umbrales efectivos de política como:

```text
Score ≥ 200 → TEMP_BAN
Score ≥ 150 → BAN
Score ≥ 100 → WATCH
Score < 100 → ALLOW
```

Mientras que `config/policy.conf`, que es la configuración real cargada en
producción, define:

```text
WATCH_SCORE=20
TEMP_BAN_SCORE=60
PERMANENT_BAN_SCORE=100
```

Son dos escalas distintas. La documentación describe un modelo que no
coincide con la configuración activa.

**Alcance**

* ✔ Confirmado (ver RFC-009): el motor real (`policy/decision_engine.sh`)
  no lee `WATCH_SCORE`, `TEMP_BAN_SCORE` ni `PERMANENT_BAN_SCORE` de
  `policy.conf`. Usa umbrales fijos hardcodeados en el código
  (`80`/`50`/`20`), que no coinciden con ninguno de los dos esquemas
  documentados hasta ahora (ni el de `ARCHITECTURE.md` ni el de
  `policy.conf`).
* Actualizar `docs/ARCHITECTURE.md`, Sección "Policy Engine", para
  reflejar el comportamiento real, o postergar esta actualización hasta
  resolver RFC-009 si el rediseño va a cambiar nuevamente estos valores.

**Relacionada con:** RFC-009.

**Archivos relacionados**

* `docs/ARCHITECTURE.md`
* `config/policy.conf`

---

## TASK-018

**Título:** Completar catálogo de categorías y umbrales faltantes en `policy.conf`

**Estado:** En progreso

**Prioridad:** Media

**Descripción**

`config/policy.conf` define umbrales de categoría (`*_THRESHOLD`) para
`RECON`, `EXPLOIT`, `CREDENTIAL`, `PROTOCOL`, `BOT`, `ANOMALY` y `DOS`.
`MALWARE` y `SOCIAL` permanecen sin umbral, a la espera de que exista un
jail/sensor real que reporte a esas categorías (ver RFC-006).

Como parte de la implementación de ARE ADMIN (ver FEAT-005), se incorporó
la variable `REPUTATION_CATEGORIES` a `policy.conf` como catálogo
explícito y única fuente de verdad de las categorías soportadas, consumida
por `admin/categories.sh`.

**Umbrales calibrados en esta sesión**

* `ANOMALY_THRESHOLD=40` — señal heurística blanda (ModSecurity generic
  anomaly), calibrada entre `RECON`(80) y `PROTOCOL`(20): necesita
  acumulación sostenida, pero menos que un simple escaneo.
* `DOS_THRESHOLD=30` — amenaza confirmada (umbral determinístico de
  `mod_evasive`, no heurística), calibrada al mismo nivel que
  `CREDENTIAL`(30): pocos eventos bastan para disparar.

Calibración basada en `weight × confidence` de los jails reales
asignados a cada categoría y en el número de eventos que ese cálculo
implica para cruzar el umbral, siguiendo el mismo criterio ya aplicado a
las categorías existentes (amenaza confirmada = umbral bajo, señal
heurística = umbral alto).

**Alcance**

* ✔ Agregar `REPUTATION_CATEGORIES` a `policy.conf`.
* ✔ `admin/categories.sh` (`categories_list`, `categories_scores`) lee el
  catálogo y los umbrales dinámicamente; muestra `N/D` cuando el umbral no
  está definido.
* ✔ `ANOMALY_THRESHOLD` y `DOS_THRESHOLD` definidos y calibrados.
* Pendiente: `MALWARE_THRESHOLD`, `SOCIAL_THRESHOLD` — depende de que
  esas categorías tengan primero un jail/sensor real reportando (ver
  RFC-006). No se definen umbrales especulativos sin evidencia.

**Archivos relacionados**

* `config/policy.conf`
* `admin/categories.sh`

---

# FEATURES

## FEAT-001

**Título:** Sensor Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Implementado**

* Evento `FOUND`.
* Sensor Fail2Ban.
* Cursor persistente.
* Modo `--dry-run`.
* Modo `--execute`.
* Ejecución automática mediante systemd timer.
* Registro en SQLite.
* Integración con Policy Engine.
* Validación en producción.

**Evolución**

El sensor fue incorporado como primera implementación del Sensor Framework.

El procesamiento utiliza un offset persistente para evitar reprocesar eventos ya procesados.

El framework permite incorporar nuevos sensores sin modificar el núcleo de ARE.

**Pendiente histórico**

Quedan registradas como parte de la evolución del sensor las tareas de limpieza y normalización de configuración que fueron identificadas durante su desarrollo. Estas tareas deberán considerarse únicamente si todavía existen dependencias en la implementación actual.

---

## FEAT-003

**Título:** Mostrar TOP JAILS en `stats`

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Objetivo**

Mostrar en el dashboard estadístico cuáles jails generan mayor actividad.

**Fuente de datos**

Tabla `events`.

**Implementación**

* `stats` muestra TOP JAILS.
* Se excluyen eventos internos como `fail2ban` y `policy_apply`.
* La información se obtiene desde `events`.

**Salida esperada**

```text
TOP JAILS:
modsec-protocol ........ 132
modsec-bruteforce ...... 78
modsec-rce ............. 34
sshd ................... 15
recidive ............... 6
```

---

## FEAT-004

**Título:** Reputation Decay Engine

**Estado:** ✔ Resuelto — recuperación controlada inicial

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Implementar un mecanismo de reducción gradual del score de reputación para IPs sin actividad reciente.

**Reglas iniciales**

* Aplicar decay únicamente a IPs sin actividad durante al menos 24 horas.
* Utilizar un factor inicial de reducción de `0.95`.
* Recalcular `total_score` después de aplicar decay.
* Reevaluar la IP mediante el State Engine.
* Reevaluar la IP mediante el Policy Engine.
* No eliminar la reputación de forma inmediata.

**Parámetros iniciales**

```text
DECAY_MIN_AGE=86400
DECAY_FACTOR=0.95
```

**Modos**

`decay-dry-run`:

* muestra IPs candidatas;
* calcula el score estimado;
* no modifica datos.

`decay-apply`:

* aplica la reducción real;
* actualiza `last_decay`;
* reevalúa State Engine;
* reevalúa Policy Engine;
* no ejecuta directamente cambios sobre firewall.

**Control de frecuencia**

Se incorporó:

```text
last_decay
```

en la tabla `reputation`.

Su finalidad es impedir que una misma IP reciba múltiples reducciones dentro de la misma ventana de recuperación.

**Validación**

* Score reducido correctamente.
* State Engine actualizado.
* Policy Engine evaluado.
* `decay-dry-run` muestra candidatas.
* `decay-dry-run` calcula score estimado.
* `decay-apply` reduce score real.
* `decay-apply` actualiza `last_decay`.
* Se evita aplicar decay múltiples veces dentro de la misma ventana.
* Se validó el procesamiento de 487 IPs.
* Una segunda ejecución sin transcurrir la ventana no genera nuevas candidatas.
* **Validación adicional en producción (2026-08-17):** se confirmó mediante log
  real de `decay-apply` que la recuperación funciona correctamente para IPs en
  estado `WATCH`/`NEW` (liberación efectiva vía `ALLOW` → `apply_decision`), y
  que el estado `BANNED` no es persistente por diseño: `state_update()` lo
  recalcula en cada corrida según el score vigente, sin memoria del estado
  anterior. Ver nota en RFC-005 sobre el caso distinto de `sanction_state.permanent`.

**Recuperación controlada**

La recuperación se encuentra vinculada a la decisión del Policy Engine.

* `ALLOW` puede generar liberación.
* `WATCH` no libera automáticamente.
* `FILTER` no libera automáticamente.
* `TEMP_BAN` no libera automáticamente.
* `BAN` no libera automáticamente.

**Siguiente etapa**

Evaluar la activación controlada de las decisiones generadas por el Decay Engine sobre el estado del firewall, manteniendo separadas la recuperación de reputación y la decisión de aplicación.

---

## FEAT-005

**Título:** Interfaz de Administración (ARE ADMIN)

**Estado:** ✔ Resuelto — 7/7 ramas implementadas y probadas en producción

**Versión objetivo:** v2.0

**Objetivo**

Implementar una interfaz de administración por línea de comandos que
exponga, de forma organizada, las capacidades de consulta, configuración y
operación de los componentes ya existentes de ARE, sin introducir una
nueva autoridad de decisión (ver `docs/DESIGN.md`, Sección 13).

**Diseño**

* Documentado en `docs/DESIGN.md`, Sección 13.
* Estructura: `admin.sh` (entrypoint) + `admin/*.sh` (un módulo por rama
  del menú), replicando el mismo patrón ya validado en `dashboard.sh` +
  `dashboard/`.
* Cambios puramente aditivos: no se movió ni renombró ningún archivo
  existente.

**Estado por rama del menú**

| Rama | Estado |
|---|---|
| 1. Jails / Perfiles | ✔ Implementada y probada (RFC-007) |
| 2. Categorías | ✔ Implementada y probada |
| 3. Sensores | ✔ Implementada y probada |
| 4. Política | ✔ Implementada y probada |
| 5. Estado / Reputación | ✔ Implementada y probada |
| 6. Decay | ✔ Implementada y probada |
| 7. Configuración | ✔ Implementada y probada |

**Validación**

Todas las ramas implementadas fueron probadas de forma aislada con
dependencias simuladas antes de cablearse, y posteriormente **confirmadas
en producción real** tras la integración completa con `are.sh` (subcomando
`admin`) y `bootstrap.sh` (carga de `admin/*.sh` junto al resto de
módulos del sistema).

**Pendiente**

* Rama 4 (Política) permanece sin implementar hasta resolver RFC-009.
* `config/jail_scale.conf` — la escala curada de referencia está definida
  solo para la categoría `BOT`. Otras categorías pueden agregarse con el
  mismo formato cuando exista un caso de uso real (no se inventan
  escalas sin evidencia).
* Definir `ANOMALY_THRESHOLD`, `MALWARE_THRESHOLD`, `DOS_THRESHOLD`,
  `SOCIAL_THRESHOLD` en `policy.conf` (ver TASK-018) — sigue pendiente,
  no relacionado con el cierre de RFC-007.

---

# HISTORIAL DE TASKS RESUELTAS

## TASK-001

**Título:** Reorganizar reglas del Policy Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Las reglas fueron reorganizadas dentro de:

```text
policy/rules/
```

La reorganización permitió separar las reglas de decisión de la implementación general del Policy Engine.

---

## TASK-002

**Título:** Cursor persistente para sensores

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Implementación de un mecanismo persistente de offset para evitar reprocesar eventos ya leídos desde los logs.

El mecanismo quedó integrado en el Sensor Fail2Ban.

---

## TASK-003

**Título:** Automatizar ejecución del Fail2Ban Sensor

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Se creó un servicio y un timer de systemd para ejecutar automáticamente el sensor Fail2Ban.

La ejecución periódica permite procesar nuevos eventos sin intervención manual.

---

## TASK-004

**Título:** Agregar estadísticas por jail

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Se incorporó la sección TOP JAILS al comando `stats`.

La información se obtiene desde la tabla `events`, permitiendo distinguir actividad por jail sin depender de la tabla `reputation`.

---

## TASK-005

**Título:** Ampliar categorías del Reputation Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Expandir el modelo de reputación para soportar categorías adicionales de amenazas.

**Categorías incorporadas**

* ANOMALY
* MALWARE
* DOS
* SOCIAL

**Implementación**

* Base de datos.
* `database.sh`.
* `dashboard/stats.sh`.
* `dashboard/score.sh`.
* cálculo de `total_score`.

**Validación**

* Nuevas columnas agregadas a `reputation`.
* Todas las categorías integradas al modelo.
* `stats` muestra las categorías.
* `score <ip>` muestra las categorías.
* `total_score` incluye las categorías.

**Regla**

Los jails continúan mapeándose mediante `jail_profile` hacia una categoría de reputación.

No se crean columnas específicas por jail.

**Nota (2026-08-17):** si bien las 9 categorías existen como columnas
persistentes, solo 5 (`RECON`, `EXPLOIT`, `CREDENTIAL`, `PROTOCOL`, `BOT`)
tienen una regla de política activa evaluándolas. Ver BUG-012 (ANOMALY
desconectada) y RFC-006 (MALWARE, DOS, SOCIAL sin regla).

---

## TASK-006

**Título:** Incorporar perfiles de reputación para sshd, telnet y recidive

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Asignar perfiles de reputación a jails críticos.

**Jails**

* `sshd` → `CREDENTIAL`
* `telnet` → `CREDENTIAL`
* `recidive` → `EXPLOIT`

**Validación**

* `sshd` agregado como perfil `CREDENTIAL`.
* `telnet` agregado como perfil `CREDENTIAL`.
* `recidive` validado como perfil existente `EXPLOIT`.
* Sensor Fail2Ban permite `sshd` y `telnet`.
* `FOUND sshd` suma score correctamente.
* `FOUND telnet` suma score correctamente.

---

## TASK-007

**Título:** Mejorar Dashboard de Reputación con información temporal

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Media

**Objetivo**

Mejorar la salida de `score <IP>` para mostrar información temporal comprensible.

**Implementación**

Se reemplazó la presentación directa del timestamp Unix por información temporal legible para administración.

**Validación**

* `score` muestra fecha legible de última actividad.
* `score` muestra antigüedad relativa.
* Se eliminó la presentación del timestamp Unix como única información temporal.

---

## TASK-008

**Título:** Controlar frecuencia de ejecución del Decay Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

`updated` representa la última actividad o modificación de reputación, pero no la última ejecución del decay.

Utilizarlo directamente para controlar ejecuciones podía provocar múltiples reducciones dentro de una misma ventana.

**Solución**

Se agregó:

```text
last_decay
```

a `reputation`.

**Validación**

* `db_init()` crea `last_decay` en instalaciones nuevas.
* `decay-dry-run` respeta `last_decay`.
* `decay-apply` actualiza `last_decay`.
* Se evita aplicar decay múltiples veces dentro de la misma ventana.
* Validado con 487 IPs procesadas.

---

## TASK-009

**Título:** Consolidar el módulo Policy

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Objetivo**

Mover progresivamente los archivos `policy*.sh` desde la raíz hacia `policy/`, sin modificar la lógica funcional.

### Fase 1 — `policy_apply.sh`

✔ Resuelta.

* Movido a `policy/apply.sh`.
* `bootstrap.sh` actualizado.
* Se agregó wrapper `apply_decision()` para mantener compatibilidad.
* Validado con `top`.
* Validado con `found modsec-protocol`.

### Fase 2 — Context

✔ Resuelta.

* `policy_context.sh` movido a `policy/context.sh`.
* `policy_context_api.sh` movido a `policy/context_api.sh`.
* `bootstrap.sh` actualizado.
* Referencia antigua corregida en `policy/rules/anomaly.sh`.
* Validado con `top`.
* Validado con `found modsec-protocol`.

### Fase 3 — Decision

✔ Resuelta.

* `policy_decision.sh` movido a `policy/decision.sh`.
* `policy_decision_engine.sh` movido a `policy/decision_engine.sh`.
* `bootstrap.sh` actualizado.
* Referencias internas corregidas.
* Validado con `top`.
* Validado con `found modsec-protocol`.

**Nota (2026-08-17):** se detectó que `policy/decision.sh` y
`policy/decision_engine.sh` definen ambos una función `policy_decide()`.
`bootstrap.sh` carga únicamente `decision_engine.sh`. Investigado y
resuelto: ver RFC-009 — `decision_engine.sh` es el motor real;
`decision.sh` es código muerto, cargado únicamente por `policy/engine.sh`,
que a su vez no es cargado por nadie.

### Fase 4 — Engine

✔ Resuelta.

* `policy_engine.sh` movido a `policy/engine.sh`.
* `policy_risk.sh` movido a `policy/risk.sh`.
* `policy_env.sh` movido a `policy/env.sh`.
* `policy.sh` movido a `policy/policy.sh`.
* `bootstrap.sh` actualizado.
* Validado con `top`.
* Validado con `found modsec-protocol`.

**Nota (2026-08-17):** `policy/engine.sh` contiene un `source
"$BASE/policy_env.sh"` que referencia la ruta anterior a esta migración
(`policy_env.sh` en la raíz), no la ruta final `policy/env.sh`.
Investigado y resuelto: ver RFC-009 — `policy/engine.sh` no es cargado
por ningún archivo del proyecto (confirmado mediante búsqueda
exhaustiva), por lo que esta referencia rota nunca llega a ejecutarse en
producción. Queda como código muerto pendiente de decisión bajo RFC-009.

---

## TASK-010

**Título:** Implementar Ban Lifecycle Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Objetivo**

Implementar un motor encargado de administrar el ciclo de vida de las sanciones aplicadas por ARE.

El Ban Lifecycle Engine no determina si una IP es peligrosa. Esa decisión corresponde al Reputation Engine, State Engine y Policy Engine.

Su responsabilidad consiste en determinar cómo evoluciona una sanción cuando ARE decide aplicar `TEMP_BAN` o `BAN`.

### Persistencia

Se creó:

```text
sanction_state
```

para almacenar el estado de sanción de cada IP.

**Información administrada**

* nivel de ban;
* cantidad de sanciones;
* duración;
* finalización del ban;
* estado permanente.

### Funciones de persistencia

* `db_init_sanction()`
* `db_increment_ban_level()`
* `db_get_ban_level()`

La persistencia fue validada con `sanction-test`.

IP utilizada durante la validación:

```text
84.84.84.84
```

**Nota (2026-08-17):** `db_increment_ban_level()` quedó posteriormente
duplicada en `database.sh` con una versión sin tope de nivel conviviendo
con la versión que sí respeta `BAN_LEVEL_MAX`. Ver BUG-011.

### Simulation Mode

Se implementó el cálculo de la siguiente sanción sin modificar firewall, reputation, policy ni DB.

**Entrada**

* IP
* `ban_level`
* `ban_count`
* `permanent`

**Salida**

```text
ACTION|TIME|REASON
```

**Política inicial**

* Nivel 1: 1 hora.
* Nivel 2: 6 horas.
* Nivel 3: 24 horas.
* Nivel 4: 7 días.
* Nivel 5: 15 días.
* Nivel 6: 30 días.
* Nivel 7: permanente.

El nivel máximo se controla mediante:

```text
BAN_LEVEL_MAX
```

`ban_level` queda limitado al máximo configurado, mientras `ban_count` continúa acumulando las sanciones históricas.

### Integración con TEMP_BAN

✔ Resuelta.

Flujo implementado:

```text
Policy Engine
      ↓
Ban Lifecycle Engine
      ↓
siguiente nivel
      ↓
ban_level / ban_count
      ↓
ban_until
      ↓
Backend
```

Validación:

* `TEMP_BAN` integrado.
* Primera sanción calculada como `BAN_LEVEL_1`.
* Duración aplicada: `3600` segundos.
* `ban_level`, `ban_count` y `ban_until` actualizados.
* Backend ejecutó el bloqueo temporal.
* **Confirmado en producción (2026-08-17):** IP `45.33.70.56` mostró
  escalado real de `BAN_LEVEL_4` → `BAN_LEVEL_5` → `BAN_LEVEL_6` en
  eventos consecutivos, validando la progresión de niveles por
  reincidencia.

### Escalado permanente

✔ Resuelto.

Se implementó el escalado hasta ban permanente.

Con el nivel previo al máximo:

```text
BAN|0|BAN_LEVEL_MAX
```

se ejecuta el bloqueo permanente.

Validación:

* `policy/apply.sh` ejecuta escalado permanente.
* La IP se elimina del conjunto `FILTER`.
* La IP se incorpora al conjunto permanente.
* `sanction_state` conserva:

```text
ban_level = 7
ban_count = 7
ban_until = 0
permanent = 1
```

---

## TASK-011

**Título:** Mostrar estado de sanción en el dashboard de reputación

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Mostrar en `score <IP>` el estado almacenado en `sanction_state`.

**Datos**

* Nivel actual de sanción.
* Cantidad total de sanciones.
* Tipo de sanción actual.
* Fecha de finalización del ban temporal.
* Estado permanente.
* Último ban.
* Último unban.

**Archivos relacionados**

* `dashboard/score.sh`
* `database.sh`
* `sanction_state`

**Validación**

* Dashboard consulta `sanction_state`.
* Muestra nivel actual.
* Muestra cantidad total.
* Distingue sanción temporal y permanente.
* Muestra fecha de finalización cuando corresponde.
* Muestra último ban y último unban.
* Validado con IP `84.84.84.84`.
* **Reutilizado (2026-08-17):** `dashboard_score()` fue conectado
  directamente a la rama "Estado / Reputación → Consultar IP" de ARE ADMIN
  (FEAT-005), sin duplicar lógica.

---

## TASK-012

**Título:** Centralizar rutas y eliminar dependencias estáticas

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Eliminar rutas estáticas del código fuente y centralizar las ubicaciones operativas mediante `config.conf`.

**Alcance**

* Ruta del código.
* Ruta de configuración.
* Ruta de datos.
* Ruta de base de datos.
* Ruta de logs.
* Ruta de sensores.
* Ruta de archivos temporales.
* Ejecutable principal.

**Regla**

No renombrar directorios ni ejecutables hasta eliminar previamente las dependencias estáticas.

### Inventario inicial

Se encontraron referencias en:

* `dashboard.sh`
* `bootstrap.sh`
* `f2b-ipset.sh`
* `policy/apply.sh`
* `policy/engine.sh`
* `policy/env.sh`
* `policy/policy.sh`
* `sensors/fail2ban.sh`
* `testing/run_tests.sh`
* `tmp/sync-f2b-are.sh`
* `config.conf`

También se detectaron referencias antiguas en `policy/env.sh` y `policy/policy.sh`.

### Exclusiones

Inicialmente se excluyeron:

* `docs/`
* archivos `.save`
* ejemplos históricos;
* archivos temporales no utilizados en producción.

Los directorios `testing/` y `tmp/` quedaron fuera del runtime de producción.

### Implementación

* Variables oficiales definidas en `config.conf`.
* `f2b-ipset.sh` localiza dinámicamente su configuración mediante `BASH_SOURCE`.
* `bootstrap.sh` utiliza `ARE_HOME` y `ARE_POLICY_CONFIG`.
* Módulos de producción consumen variables oficiales.
* Sensor Fail2Ban resuelve dinámicamente la ubicación del proyecto.
* Se eliminaron dependencias operativas de rutas fijas externas a la configuración.

**Nota (2026-08-17):** se detectó una excepción no cubierta por esta tarea:
`sensors/fail2ban.sh` sigue teniendo `LOG_FILE="/var/log/fail2ban.log"`
hardcodeado, fuera de `config.conf`. Ver TASK-016.

### Validación

* Sensor obtiene su ubicación mediante `BASH_SOURCE`.
* Usa `ARE_BIN` y `ARE_DATA`.
* No depende de rutas estáticas en `/opt` ni `/var/lib`.
* Validado mediante `are-fail2ban-found.service`.
* Flujo `FOUND → Reputation → Policy → Apply` operativo.
* Validado mediante `stats`.
* Validado mediante servicio del sensor Fail2Ban.

---

## TASK-014

**Título:** Crear instalador modular de ARE

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Crear un Installer Engine que implemente el procedimiento definido en `docs/INSTALL.md`.

**Principios**

* Una responsabilidad por función.
* No sobrescribir configuraciones existentes.
* No eliminar datos persistentes.
* No modificar automáticamente Fail2Ban, ModSecurity o Apache.
* Detener la instalación ante errores críticos.
* Verificar cada etapa antes de continuar.

**Funciones**

* `install_verify_root`
* `install_verify_dependencies`
* `install_create_directories`
* `install_copy_files`
* `install_install_configs`
* `install_create_links`
* `install_permissions`
* `install_database`
* `install_systemd`
* `install_validate`
* `install_finish`

### Upgrade desde paquete externo

✔ Validado.

* Installer Engine detecta instalación existente.
* Copia únicamente `PRODUCT_DIRS` y `PRODUCT_FILES`.
* Conserva configuración y datos persistentes.
* Actualiza enlaces oficiales.
* Actualiza unidades systemd.
* Validación integral satisfactoria.

### Instalación segura de configuración

✔ Validada.

Se creó:

```text
templates/config/
```

como origen oficial de configuración.

Los archivos administrados se obtienen mediante:

```text
PRODUCT_CONFIG_FILES
```

`install_install_configs()`:

* crea enlaces únicamente cuando el destino no existe;
* conserva archivos físicos personalizados;
* reconoce enlaces correctos;
* conserva e informa enlaces rotos;
* conserva e informa enlaces válidos con destino diferente;
* detiene la instalación cuando falta una plantilla obligatoria.

La implementación fue validada en laboratorio aislado y la instalación activa de producción no fue modificada durante esa validación.

---

# RFC

## RFC-001

**Título:** Renombrar CLI oficial a `are`

**Estado:** Draft

**Objetivo**

Establecer `are` como CLI oficial del proyecto.

La decisión deberá contemplar compatibilidad con el nombre histórico utilizado por las instalaciones existentes.

---

## RFC-002

**Título:** Sensor Framework

**Estado:** Accepted

**Versión:** v1.1.0

**Descripción**

ARE incorpora una capa de sensores encargada de transformar eventos externos en eventos internos procesables por el motor de reputación.

El primer sensor oficial corresponde a Fail2Ban.

**Resultado**

El Sensor Framework quedó incorporado en v1.1 y el sensor Fail2Ban constituye su primera implementación oficial.

---

## RFC-003

**Título:** Identity Migration

**Estado:** Draft

**Versión objetivo:** Posterior a v1.1

**Descripción**

Evaluar la transición desde la identidad histórica `f2b-ipset` hacia el nombre oficial del proyecto:

**ARE — Abuse Reputation Engine**

**Objetivo**

Alinear progresivamente:

* comandos;
* rutas;
* servicios;
* configuración;
* documentación;
* identidad del paquete.

**Alcance propuesto**

* Crear CLI oficial `are`.
* Mantener compatibilidad temporal con `f2b-ipset.sh`.
* Evaluar migración futura de `/opt/f2b-ipset/` hacia `/opt/are/`.
* Evaluar migración futura de configuración hacia `/etc/are/`.
* Evaluar migración futura de base de datos hacia rutas ARE.
* Actualizar documentación afectada.

**Regla**

La migración deberá realizarse gradualmente para no romper instalaciones existentes.

---

## RFC-004

**Título:** ARE como autoridad principal de decisión

**Estado:** Draft

**Descripción**

Evaluar la transición del modelo actual hacia un modelo donde Fail2Ban actúe principalmente como fuente de eventos y ARE asuma la autoridad sobre las decisiones de bloqueo, filtrado, liberación y escalado.

**Objetivo**

Permitir que ARE determine la respuesta final utilizando:

* reputación;
* score;
* historial;
* reincidencia;
* estado de la IP;
* política configurada.

El objetivo es evitar que una acción externa de Fail2Ban contradiga una decisión de ARE.

**Impacto esperado**

* Mayor autonomía de ARE.
* Mayor coherencia entre reputación y firewall.
* Control centralizado del ciclo de vida de una IP.
* Fail2Ban como sensor y no como autoridad final.

**Puntos a definir**

* Tratamiento de eventos `BAN`.
* Tratamiento de eventos `UNBAN`.
* Condiciones para liberar una IP.
* Integración con Ban Lifecycle.
* Condiciones para bloqueo permanente.
* Relación entre decisiones de ARE y acciones externas.

**Validación inicial**

Se implementó y validó manualmente:

```bash
./f2b-ipset.sh external-unban <IP> <JAIL>
```

Esta validación no implica que la RFC haya sido aceptada.

---

## RFC-005

**Título:** Ciclo autónomo de recuperación y sanción

**Estado:** Draft

**Descripción**

Definir la evolución futura del ciclo completo de una IP cuando ARE controle de forma autónoma la relación entre reputación, estado, sanciones y recuperación.

La parte correspondiente al cálculo básico de Reputation Decay ya fue implementada en v1.1 y no debe considerarse pendiente dentro de esta RFC.

**Objetivo futuro**

Evaluar un ciclo compuesto por:

```text
observación
    ↓
reputación
    ↓
decisión
    ↓
sanción
    ↓
escalado
    ↓
recuperación
    ↓
reevaluación
    ↓
liberación
```

**Principios**

* Una IP deja de ser peligrosa gradualmente.
* La reputación no se elimina de golpe.
* La liberación debe ser consecuencia de una decisión de ARE.
* Fail2Ban actúa como fuente de información.
* Los límites de escalado deben ser configurables.

**Puntos pendientes de definición**

* Frecuencia definitiva del Decay Engine.
* Fórmula definitiva de recuperación.
* Umbral de liberación.
* Relación entre score y estado de sanción.
* Condiciones para liberar un `TEMP_BAN`.
* Condiciones para conservar un bloqueo aunque el score disminuya.
* Relación entre reincidencia y Ban Lifecycle.
* Condición definitiva para `BAN` permanente.
* Tratamiento de `EXTERNAL_UNBAN`.

**Nota (2026-08-17):** se verificó en producción que la liberación por
score decreciente **sí funciona correctamente** para el `status` general
(`reputation.status`, vía `state_update()` + `policy_decide()`) — no es un
punto pendiente. Lo que permanece efectivamente sin resolver dentro de
esta RFC es específicamente la ausencia de mecanismo de reconsideración
para `sanction_state.permanent = 1`, que es un flag independiente del
`status` y no es evaluado por el flujo de Decay actual. Ver también
RFC-008 para la relación con el modelo de categorías.

---

## RFC-006

**Título:** Reglas de política activas para MALWARE, DOS y SOCIAL

**Estado:** Draft

**Descripción**

Las categorías `MALWARE`, `DOS` y `SOCIAL` existen como columnas en la
tabla `reputation` desde TASK-005/BUG-006, pero no cuentan con un archivo
`policy/rules/*.sh` que las evalúe. A diferencia de `ANOMALY` (que sí tiene
una regla escrita, aunque desconectada — ver BUG-012), estas tres
categorías no tienen ninguna lógica de decisión asociada todavía.

**Objetivo**

Definir el criterio de riesgo para cada una y su regla correspondiente,
siguiendo el mismo patrón que `policy/rules/exploit.sh`,
`policy/rules/bot.sh`, etc.

**Puntos a definir**

* Umbral y severidad relativa de cada categoría frente a las ya activas.
* Fuente de eventos que alimenta cada categoría (¿qué jail o sensor
  produce actividad `DOS` o `SOCIAL` hoy?).

**Relación con otras entradas:** bloquea la parte pendiente de TASK-018
(umbrales de categoría en `policy.conf`).

---

## RFC-007

**Título:** Administración genérica de perfiles de jail (CRUD sobre `jail_profile`)

**Estado:** ✔ Implementada

**Versión:** v2.0 (en desarrollo)

**Descripción original**

El esquema actual de `jail_profile` fue definido para un conjunto acotado
de jails. La necesidad original planteada era poder incorporar perfiles
adicionales (por ejemplo, un jail de SMTP) a partir de reportes o
configuración existente en Fail2Ban, sin duplicar trabajo manual jail por
jail.

**Redefinición del alcance durante el diseño**

Al auditar `handle_ban()`/`handle_found()` en `are.sh`, se confirmó que
el motor de decisión **ya es agnóstico del origen del reporte**: cualquier
`<ip> <jail>` que llegue con un perfil existente en `jail_profile` se
procesa igual, sin importar si proviene de Fail2Ban, o en el futuro de
Suricata, CrowdSec, ModSecurity u otro sensor (ver Sensor Framework,
`docs/DESIGN.md` Sección 8). No había, entonces, nada que "migrar" desde
Fail2Ban específicamente — los 9 jails activos en producción ya tenían
perfil.

El problema real era la **ausencia de administración genérica**: crear,
modificar o eliminar un perfil requería edición manual de SQL. La RFC se
redefinió en consecuencia: no es una migración de datos, es un CRUD
administrable desde ARE ADMIN, que habilita agregar cualquier jail nuevo
—de cualquier sensor presente o futuro— sin tocar código ni base de
datos a mano.

**Principio de diseño resultante (para incorporar a `DESIGN.md`)**

> Cualquier sensor que ARE incorpore, presente o futuro, entrega un
> reporte `<ip> <jail>`. La existencia y las propiedades de riesgo de
> ese `jail` (categoría, peso, confianza) viven exclusivamente en
> `jail_profile`, administrable vía ARE ADMIN — nunca hardcodeadas
> dentro del código de un sensor particular.

**Implementación**

CRUD completo en `admin/jails.sh`, con funciones de soporte nuevas en
`database.sh`:

* `db_list_jail_profiles()`
* `db_jail_profile_exists()`
* `db_create_jail_profile()`
* `db_get_jail_profile_full()`
* `db_update_jail_profile()`
* `db_delete_jail_profile()`
* `db_validate_jail_profiles()`
* `db_category_weight_stats()` — referencia estadística (min/máx/promedio)
  calculada de perfiles reales existentes en la categoría, para asistir
  al administrador sin inventar valores de riesgo.

**Escalas de referencia curadas por categoría**

Se incorporó `config/jail_scale.conf` (nuevo archivo de configuración
desacoplada, variable `ARE_JAIL_SCALE_CONFIG` en `config.conf`) para
categorías donde el administrador define niveles de riesgo explícitos en
vez de depender solo del promedio histórico. Formato:
`CATEGORIA|NIVEL|PESO|CONFIANZA`. Cargada inicialmente solo para `BOT`,
con 5 niveles (leve → malicioso). Extensible por categoría sin tocar
código — cada categoría nueva es una línea agregada al archivo.

**Selección de categoría restringida**

La categoría se elige de una lista numerada contra `REPUTATION_CATEGORIES`
(TASK-018), nunca por texto libre — elimina el riesgo de typos que
generarían categorías fantasma no reconocidas por el resto del sistema.

**Salvaguardas de UX/seguridad**

* `Crear` rechaza nombres duplicados, sugiere `Modificar`.
* `Modificar` selecciona el jail por lista numerada (no texto libre) y
  ofrece "mantener valor actual" en cada campo, incluida la opción de
  volver a elegir un nivel de escala en vez de escribir un número al
  azar.
* `Eliminar` selecciona por lista numerada y exige escribir el nombre
  exacto del jail como confirmación (no solo `s/N`) — única operación
  destructiva del CRUD.
* `Validar` detecta perfiles con categoría fuera de `REPUTATION_CATEGORIES`,
  peso ≤ 0, o confianza fuera de 0.0-1.0.

**Validación**

Probado en producción real, sesión 2026-08-18:

* Creación de `apache-badbots` (categoría `BOT`, escala curada, nivel 2).
* Modificación del mismo jail a nivel 4 (peso 3.0→7.0, confianza 0.6→0.8),
  incluyendo prueba de "mantener actual" y de cancelación con `N`.
* Eliminación de un jail de prueba (`apache-auth`), incluyendo caso de
  confirmación con nombre incorrecto (correctamente rechazado, sin
  borrar) y caso de confirmación correcta.
* `Validar` sobre los 13 perfiles reales resultantes: `TODOS LOS
  PERFILES SON VÁLIDOS`.

**Relación con ARE ADMIN**

La rama "1. Jails / Perfiles" del menú (ver FEAT-005), previamente
pausada, queda **implementada y confirmada en producción**.

---

## RFC-008

**Título:** Modelo de categorías extensible (columnas fijas → esquema normalizado)

**Estado:** En progreso — Fases 1-3 completas, Fase 4 pospuesta (limitación de SQLite). Ver también BUG-019 (decay proporcional).

**Versión:** v2.1 (en desarrollo)

**Descripción**

El modelo actual de reputación almacena cada categoría como una columna
fija en la tabla `reputation` (`recon_score`, `exploit_score`, etc.).
Agregar una categoría nueva requiere modificar el esquema (`ALTER TABLE`)
y actualizar múltiples funciones que enumeran las columnas explícitamente
(`db_get_reputation()`, `db_sum_categories()`, `db_top_attackers()`,
`dashboard/score.sh`).

**Objetivo**

Migrar hacia un esquema normalizado, `reputation_scores(ip, category,
score)`, donde agregar una categoría nueva sea una operación de datos
(`INSERT`) y no una migración de estructura. Consistente con el
principio ya documentado en `docs/DESIGN.md` Sección 3.2 de no
convertir jails en columnas independientes — el mismo criterio ahora
aplicado también a las categorías.

**Decisión de diseño confirmada:** `total_score` deja de ser un campo
independiente almacenado y pasa a derivarse siempre como `SUM(score)`
sobre `reputation_scores`. Esto no es solo normalización — es la
corrección estructural definitiva de BUG-017 (ver más abajo): al no
existir dos números que puedan desincronizarse, la deriva de
truncamiento deja de ser posible por diseño, no por parche.

**Plan de migración en fases**

1. ✔ **Fase 1 — Completa.** Crear `reputation_scores` junto a la tabla
   existente (aditivo, sin tocar `reputation`), migrar los datos
   existentes, y verificar la migración comparando `SUM(score)` contra
   `total_score` IP por IP.
2. ✔ **Fase 2 — Completa.** `db_get_reputation`, `db_sum_categories`,
   `db_top_attackers` reescritas para leer de `reputation_scores` (vía
   `MAX(CASE WHEN category=...)` como pivote manual, SQLite no tiene
   `PIVOT` nativo). Validado en producción: `./are.sh score`,
   `./are.sh stats`, `./are.sh top` devuelven exactamente los mismos
   valores que antes de la migración, para las mismas IPs.
3. ✔ **Fase 3 — Completa.** `db_add_score` reescrita como
   `INSERT ... ON CONFLICT DO UPDATE` genérico (reemplaza el `case` de
   9 ramas por categoría) y `db_recalculate_total` como `SUM()` sobre
   `reputation_scores` — esta última corrige BUG-017 en el momento de
   escritura, no solo en la migración histórica.

   Dos bugs propios de la implementación de esta fase, encontrados y
   corregidos durante la validación manual (no en producción real, que
   nunca los sufrió — ver detalle):

   * `db_add_score()` no garantizaba la existencia previa de la fila
     en `reputation` antes de hacer `UPDATE ... WHERE ip=...`; un
     `UPDATE` sobre una fila inexistente no falla ni crea nada,
     simplemente no afecta filas. En producción esto nunca se
     manifestó porque `handle_found()`/`handle_ban()` siempre llaman
     `db_init_reputation()` antes de `db_add_score()` — se manifestó
     únicamente en pruebas manuales que invocaban la función de forma
     aislada. Corregido con `INSERT OR IGNORE INTO reputation (ip,
     updated) VALUES (...)` al inicio de la función, como garantía
     adicional.
   * `db_get_reputation()` propagaba `NULL` a toda la cadena de salida
     cuando la subconsulta de `updated` no encontraba fila en
     `reputation` (concatenación con `NULL` en SQL da `NULL`
     completo). Corregido envolviendo esa subconsulta en `COALESCE(...,
     0)`.

4. **Fase 4 — Pospuesta, sin fecha, por limitación técnica real.**
   Eliminar las columnas de categoría de `reputation` requiere
   `ALTER TABLE ... DROP COLUMN`, soportado recién desde SQLite
   3.35.0. El servidor de producción corre SQLite 3.26.0 (AlmaLinux 8,
   `baseos`), que no ofrece actualización de este paquete por el
   modelo de ABI estable de RHEL 8 — confirmado con `dnf check-update`.
   En esta versión, eliminar columnas requeriría recrear la tabla
   completa (crear nueva sin esas columnas, copiar datos, renombrar),
   una operación bloqueante de mayor riesgo sobre una tabla con más de
   2200 IPs reales en producción activa. Se evaluó y descartó
   actualizar SQLite a nivel de sistema operativo por el riesgo que
   implica para otros componentes del servidor (cPanel/WHM y
   dependencias asociadas). Las columnas viejas no generan ningún
   problema funcional mientras permanezcan sin uso — el sistema ya no
   las lee ni las escribe (confirmado mediante `grep` exhaustivo; las
   únicas referencias restantes son en `db_migrate_reputation_scores()`
   y `db_merge_comma_duplicates()`, funciones de migración histórica
   ya ejecutadas, que quedan como herramientas de referencia). Se
   revisitará si el sistema operativo del servidor se actualiza en el
   futuro.

**Hallazgo real durante la Fase 1: BUG-018**

La primera corrida de `db_verify_reputation_scores_migration()` sobre
la base real de producción (2366 IPs) no mostró discrepancias
esperables de redondeo — mostró **145 IPs completamente ausentes** de
la comparación esperada, con un patrón que resultó ser un bug de
datos independiente de la migración. Ver BUG-018 en el historial de
resueltos.

**Hallazgo real durante la Fase 1: BUG-017**

Tras resolver BUG-018, la verificación repetida mostró una segunda
categoría de discrepancia, sistemática y de menor magnitud, en la
gran mayoría de las 2366 IPs: `total_score` (columna almacenada)
consistentemente mayor que `SUM(score)` real de sus categorías. Causa
identificada: `reputation_decay_apply()` trunca (`CAST ... AS
INTEGER`) cada columna de categoría de forma independiente, y también
trunca `total_score` por separado — 9 truncamientos independientes
pierden fracciones más rápido que 1 solo truncamiento sobre el total
agregado, y el error se acumula con cada corrida diaria del Decay
Engine. No se corrige como parche aparte: la Fase 2/3 de esta misma
RFC lo resuelve de raíz al eliminar `total_score` como campo
almacenado.

**Nota de riesgo operativo**

Dado que el sistema corre en múltiples servidores de producción, cada
fase debe validarse en el servidor actual antes de replicarse a la
flota — mismo criterio de servidor canario ya aplicado en RFC-009.

---

## RFC-009

**Título:** Motor de decisión único: evaluación de riesgo por categoría

**Estado:** ✔ Implementada y validada en producción (servidor canario)

**Descripción**

Se investigó cuál de las múltiples definiciones concurrentes del Policy
Engine (originalmente registrada como BUG-013) gobernaba efectivamente
las decisiones en producción. La investigación confirmó que
`policy/decision_engine.sh::policy_decide()` era el único motor real —
decidiendo exclusivamente por score total, sin distinguir categoría, sin
leer umbrales de `policy.conf` — mientras que `policy/engine.sh`,
`policy/policy.sh`, `policy/rules/core.sh` y `policy/decision.sh` eran
código muerto, sin invocación en ningún punto alcanzable del flujo real.

**Objetivo de diseño**

Que la categoría que activa un evento module el riesgo asignado — una IP
clasificada por `ANOMALY` no representa el mismo riesgo que un intento
de `EXPLOIT` — evaluando cada categoría de forma independiente
(principio de responsabilidad única: *"un módulo no decide, solo
califica; un orquestador dirige"*), sin perder la protección de base que
ya ofrecía el motor por score total.

**Implementación**

* **`policy/context.sh` / `policy/context_api.sh`** — extendidos de
  `CTX_V1` (5 categorías) a `CTX_V2` (9 categorías completas +
  eventos 24h).
* **`policy/risk.sh`** — corregido: el multiplicador de reincidencia
  (`RISK_MULT_WATCH`, `RISK_MULT_BANNED`) se calculaba pero nunca se
  aplicaba al total; ahora se aplica realmente, con valores desde
  `policy.conf` (no hardcodeados). Aritmética migrada a `awk` para
  soportar decimales.
* **`policy/decision_engine.sh`** — umbrales (`WATCH_SCORE`,
  `TEMP_BAN_SCORE`, `PERMANENT_BAN_SCORE`) ahora leídos de
  `policy.conf`; si un umbral no está definido, ese nivel se salta sin
  romper, en vez de comparar contra un valor fijo o vacío.
* **9 reglas nuevas en `policy/rules/`** (`exploit`, `bot`, `recon`,
  `protocol`, `bruteforce`, `anomaly`, `malware`, `dos`, `social`),
  todas con el mismo contrato único: leen su propio umbral de
  `policy.conf`, aportan al acumulador de riesgo (`risk_add`) solo si lo
  superan, y no conocen la existencia de las demás reglas ni de la
  decisión final. Si una categoría no tiene umbral configurado, su regla
  no evalúa (comportamiento explícito, no un error silencioso). Corrige
  además BUG-012 de raíz (`anomaly.sh` reescrita con el nuevo contrato).
* **`policy/engine.sh`** — reescrito como orquestador único
  (`policy_evaluate()`), reemplazando a los tres dispatchers muertos.
  Itera dinámicamente sobre `REPUTATION_CATEGORIES` (no un array
  hardcodeado), por lo que una categoría nueva con su regla ya empieza a
  evaluarse sin tocar el orquestador. Incluye:
  - Chequeo de whitelist al inicio (ausente en el diseño original,
    causaba errores de `bc` con IPs sin datos, ej. `::1`).
  - Hard gate de `STATUS=BANNED`, igual que el motor anterior.
  - **Piso de seguridad**: la decisión final usa
    `MAX(riesgo_por_categoría, score_total_acumulado)` — el motor por
    categoría puede ser más estricto que el anterior (detecta señales
    que el score simple no distingue, como bruteforce), pero nunca
    menos estricto. Sin este piso, una IP con riesgo repartido entre
    categorías —cada una por debajo de su propio umbral— podía evadir
    la detección aunque su score total fuera alto (caso real detectado:
    `45.33.70.56`, reincidente conocida).

**Herramienta de validación no invasiva**

Se agregó el comando `are.sh policy-compare <IP>`, que ejecuta ambos
motores (el anterior y el nuevo) sobre la misma IP sin aplicar ninguna
decisión, mostrando si coinciden o difieren. Usado para validar el
comportamiento contra datos reales antes del corte a producción.

**Incidentes durante el despliegue (documentados por transparencia)**

* Al construir `handle_policy_compare()`, se detectó que
  `config/whitelist.conf` tenía un espacio final en la línea de la IP
  real del VPS (`208.109.242.73`), lo que hacía fallar la coincidencia
  exacta de `grep -Fqx` — la IP no estaba efectivamente protegida por la
  whitelist en producción. Corregido con `sed 's/[ \t]*$//'` sobre el
  archivo completo.
* Durante el corte manual de `handle_found()`, `handle_ban()` y
  `handle_external_unban()` (reemplazar las llamadas a `policy_decide()`
  directo por `policy_evaluate()`), una edición a mano en
  `handle_external_unban()` dejó la variable de resultado declarada en
  minúscula (`local ... decision ...`) pero asignada en mayúscula
  (`DECISION=$(policy_evaluate ...)`), causando que `action`/`reason`
  quedaran vacíos y la acción resultante fuera `UNKNOWN ACTION` sin
  aplicar nada. Detectado en el primer evento `EXTERNAL_UNBAN` real
  post-corte, diagnosticado comparando `policy_decide` y
  `policy_evaluate` de forma aislada (fuera de un subshell de pipe, que
  había ocultado el error en el primer intento de diagnóstico), y
  corregido con un cambio de una sola línea.

**Validación en producción**

Corte realizado en un único servidor (canario), sin replicar a otros
nodos de la flota. Ventana de monitoreo con tráfico real de Fail2Ban:

```
[POLICY] CATEGORY_RISK=23 RAW_TOTAL=25 EFFECTIVE=25 → FILTER (LOW_RISK)
[POLICY] CATEGORY_RISK=22 RAW_TOTAL=25 EFFECTIVE=25 → FILTER (LOW_RISK)
[POLICY] CATEGORY_RISK=0  RAW_TOTAL=2  EFFECTIVE=2  → WATCH (MINIMAL_RISK)
[POLICY] CATEGORY_RISK=0  RAW_TOTAL=3  EFFECTIVE=3  → WATCH (MINIMAL_RISK)
```

En los dos primeros casos, `CATEGORY_RISK < RAW_TOTAL` y el piso de
seguridad tomó el valor de `RAW_TOTAL` — confirmación en datos reales
(no solo simulados) de que el mecanismo de seguridad funciona como fue
diseñado. Cero errores, cero `WARN`, cero `UNKNOWN ACTION` tras la
corrección del incidente de despliegue.

**Pendiente**

* Monitorear una ventana más amplia (recomendado: 24-48h) antes de
  replicar el corte al resto de la flota de servidores.
* ✔ Definido `ANOMALY_THRESHOLD=40`, `DOS_THRESHOLD=30`. Pendiente:
  `MALWARE_THRESHOLD`, `SOCIAL_THRESHOLD` — sin jail/sensor real
  todavía reportando a esas categorías (ver RFC-006, TASK-018).
* ✔ Código muerto eliminado (`policy/policy.sh`, `policy/rules/core.sh`,
  `policy/decision.sh`), tras confirmación repetida de que ningún
  archivo los carga ni invoca, y validación funcional completa
  post-eliminación (`stats`, `score`, `policy-compare`, las 7 ramas de
  ARE ADMIN). Backup preservado fuera del repositorio.
* ✔ Rama "4. Política" de ARE ADMIN implementada — ver FEAT-005.
  Su propia validación detectó y permitió corregir BUG-016
  (`CREDENTIAL` sin regla asociada).

---



## RFC-010

**Título:** Integrar `mod_evasive` como sensor real de ARE (categoría DOS)

**Estado:** ✔ Implementada en modo doble escritura, validada con tráfico simulado

**Descripción**

`mod_evasive` (protección anti-flood a nivel de Apache) operaba
completamente por fuera de ARE: `/usr/local/bin/ddos_system.sh`
escribía directo al ipset sin pasar por `database.sh`, sin generar
reputación, sin registrar eventos, y sin posibilidad de recuperación
gradual vía Decay. Esta decisión fue intencional en su momento: se
prefirió no integrar `mod_evasive` a ARE mientras el motor no tenía
soporte real para la categoría `DOS`. Con RFC-009 completa, la
integración quedó desbloqueada.

**Calibración del perfil**

A diferencia de las categorías de acumulación gradual (`RECON`,
`PROTOCOL`), `mod_evasive` ya aplica su propio umbral interno
(`DOSSiteCount`) antes de reportar — cuando reporta, ya es un flood
confirmado, no una sospecha. El perfil se calibró para reflejar esto:
`weight=70, confidence=0.95` (score ≈ 66-67 por evento), suficiente
para que un único reporte cruce `TEMP_BAN_SCORE=60` de inmediato, sin
esperar acumulación — a diferencia del bloqueo fijo de 4 semanas
anterior, ahora escala vía Ban Lifecycle (1h → 6h → 1d → ... →
permanente según reincidencia real).

**Implementación**

* Corrección previa (fuera de ARE, en `ddos_system.sh`): el `ipset add`
  original no especificaba `timeout`, por lo que el set (`timeout 0`
  por defecto) dejaba la IP baneada permanentemente pese a que el
  email notificaba "4 semanas". Corregido con `timeout` explícito
  (ajustado al máximo válido de `ipset`, `2147483647`, tras un primer
  intento con `2419200` fuera de rango en la versión instalada).
* `ddos_system.sh` modificado con **doble escritura**: mantiene el
  `ipset add` directo (protección inmediata sin downtime) y agrega
  `are.sh ban "$SOURCEIP" mod_evasive`, registrado en un log separado
  (`/var/log/are/mod_evasive_report.log`) para monitoreo independiente
  del resto del script.
* Logrotate integrado para el log nuevo: plantilla
  `templates/logrotate/mod_evasive_report` (mismo esquema que
  `are.log`: diario, 14 rotaciones, comprimido), agregada a
  `PRODUCT_LOGROTATE_FILES` en `manifest/product.sh`, instalada en
  `/etc/logrotate.d/` y verificada con `logrotate -d` y
  `are-installer verify`.

**Validación**

Probado con IPs de prueba (rango `192.0.2.0/24`, reservado para
documentación, `RFC 5737`):

```
Evento recibido: 192.0.2.99 desde mod_evasive
Score aplicado: 66
[POLICY] CATEGORY_RISK=99 RAW_TOTAL=66 EFFECTIVE=99   (multiplicador de reincidencia activo)
Policy decision: TEMP_BAN (MEDIUM_RISK)
[APPLY] EXECUTE: TEMP BAN (3600 sec)
[APPLY] SANCTION LEVEL: BAN_LEVEL_1
```

Confirmado con `./are.sh score` (Threat Level HIGH, sanción nivel 1,
vigencia exacta de 1 hora) y con `ban-lifecycle-test` (segundo evento
escala correctamente a `BAN_LEVEL_2`, 21600 seg / 6h). Prueba de
integración completa vía `ddos_system.sh 192.0.2.100` confirmó ambos
caminos (ipset directo + reporte a ARE) funcionando en el mismo
evento.

**Pendiente**

* Ventana de monitoreo con tráfico real (no simulado) antes de decidir
  si se retira el `ipset add` directo y ARE pasa a ser la única vía de
  bloqueo.
* Evaluar reducción de la lista `DOSWhitelist` de Cloudflare una vez
  que el modelo de reputación de ARE demuestre absorber esos falsos
  positivos en producción real.
* Replicar el cambio de `ddos_system.sh` y la corrección de timeout a
  otros servidores de la flota que tengan el mismo script (vive fuera
  del repositorio de ARE, en `/usr/local/bin/`, sin sincronización
  automática vía git).

---

## RFC-011

**Título:** Exportar / Importar `jail_profile`

**Estado:** ✔ Implementada y validada en producción

**Versión:** v2.1 (en desarrollo)

**Descripción**

Primera funcionalidad de la línea v2.1. Surgida de una recomendación
hecha durante el diseño original de RFC-007 (propagar cambios de
perfil entre servidores de forma controlada y auditable), retomada al
confirmarse que el software ya se está replicando a colegas y otros
servidores de la flota.

**Objetivo**

Permitir que un administrador exporte el catálogo completo de
`jail_profile` de un servidor a un archivo portable, e importe ese
archivo en otro servidor — evitando recrear manualmente cada perfil
calibrado (peso, confianza, decay, categoría) jail por jail.

**Implementación**

* Nuevas opciones "6) Exportar" y "7) Importar" en la rama
  Jails/Perfiles de ARE ADMIN.
* Formato de archivo: texto plano, mismo esquema de campos que ya usa
  internamente `db_list_jail_profiles()`
  (`NOMBRE|CATEGORIA|PESO|CONFIANZA|DECAY|DESCRIPCION`), con cabecera
  de comentarios (fecha, hostname de origen).
* Ubicación fija: `${ARE_DATA}/backups/jail_profiles/` — dato
  persistente, no producto, coherente con la separación
  PRODUCT/CONFIG/DATA ya establecida en `DESIGN.md` Sección 10.
* Exportar genera nombre de archivo con timestamp automático, sin
  pedir ruta ni riesgo de sobrescribir un backup anterior.
* Importar presenta los archivos disponibles como lista numerada (no
  texto libre), y pregunta una única vez cómo resolver conflictos con
  perfiles ya existentes (sobrescribir todos / conservar todos —
  default: conservar), en vez de preguntar jail por jail.
* Validación por línea durante la importación: categoría reconocida
  en `REPUTATION_CATEGORIES`, peso y confianza numéricos — líneas
  inválidas se reportan como error y se omiten, sin abortar el resto
  de la importación.
* No se agregó ninguna función nueva a `database.sh`: reutiliza
  `db_list_jail_profiles()`, `db_jail_profile_exists()`,
  `db_create_jail_profile()`, `db_update_jail_profile()`, ya
  existentes desde RFC-007.
* Ambas operaciones quedan registradas en el log de auditoría
  (`admin_audit.log`).

**Validación**

Probado en producción real: exportación de los 17 perfiles reales del
servidor (incluyendo los calibrados en la misma sesión: `dovecot`,
`postfix-sasl`, `mysqld-auth`, `mod_evasive`), seguida de importación
del mismo archivo con modo "conservar" — resultado `Creados: 0,
Actualizados: 0, Omitidos: 17, Errores: 0`, confirmando que la
detección de perfiles existentes funciona correctamente sin riesgo de
sobrescritura accidental.

---

## RFC-012

**Título:** Formalizar `apache_evasive.sh` como sensor oficial (patrón callback)

**Estado:** ✔ Implementada

**Versión:** v2.1 (en desarrollo)

**Descripción**

El script que reportaba eventos de `mod_evasive` a ARE
(`ddos_system.sh`, ver RFC-010) vivía fuera del repositorio, en
`/usr/local/bin/`, sin versionar y sin manifiesto — un colega que
instalara ARE desde cero no lo recibía. Se formaliza como
`sensors/apache_evasive.sh`, parte oficial del Sensor Framework.

**Segundo patrón de sensor documentado**

El Sensor Framework (`docs/DESIGN.md` Sección 8) solo documentaba el
patrón de *polling* (`sensors/fail2ban.sh`, systemd timer que lee un
log periódicamente). `apache_evasive.sh` es estructuralmente distinto:
Apache lo invoca **directo y síncrono** en el instante que
`mod_evasive` confirma un flood (patrón *callback*). Se documenta como
segundo patrón válido dentro del mismo framework, no como excepción.

**Implementación**

* Movido a `sensors/apache_evasive.sh`, ya cubierto por `PRODUCT_DIRS`
  en el manifiesto (el directorio `sensors/` completo ya se instalaba
  como unidad).
* `300-mod_evasive.conf` (`DOSSystemCommand`) actualizado a la ruta
  nueva.
* Entrada de `sudoers` actualizada para apuntar a la ruta dentro del
  repositorio.
* Eliminadas las llamadas a `/usr/local/bin/firewall_snapshot.sh`
  (mecanismo de backup de reglas `iptables` para sobrevivir reinicios,
  obsoleto desde la migración a `ipset`, que persiste sus reglas de
  forma nativa).

**Hallazgo de seguridad detectado y corregido en el proceso**

Al confirmar que `firewall_snapshot.sh` ya no se ejecutaba, se
encontró en `/etc/sudoers` un permiso sin restricción de argumentos
para el usuario bajo el que corre Apache (`nobody`):
`nobody ALL=NOPASSWD: /sbin/iptables *`. Este permiso ya no tenía
ningún consumidor real — su único propósito histórico era
`firewall_snapshot.sh`. Eliminado, reduciendo la superficie de ataque:
si el proceso de Apache llegara a comprometerse, ya no tendría control
irrestricto sobre el firewall vía `sudo iptables`. Confirmado con
`sudo -l -U nobody` que el permiso desapareció sin afectar los
comandos que sí siguen en uso (`at`, `apache_evasive.sh`).

**Observación post-implementación (2026-08-19)**

Revisión de `mod_evasive_report.log`, `reputation_scores` (categoría
`DOS`) e `ipset are-blacklist` una jornada después del cutover: sin
eventos reales registrados desde la integración, solo las IPs de
prueba usadas durante el desarrollo (`192.0.2.99`, `192.0.2.100`).
Explicado por medidas de mitigación tomadas por el administrador el
mismo día del pico detectado en RFC-013 (2026-08-15): cierre temporal
del acceso a la tienda sin registro (principal blanco de los
escaneos) y activación de Cloudflare "Under Attack Mode", ambas
filtrando tráfico antes de que llegue a Apache/`mod_evasive`. La
integración queda técnicamente validada (con tráfico de prueba); su
primera validación con tráfico real de flood quedará pendiente hasta
que se reabra el acceso sin registro y se desactive el modo de
Cloudflare.

---

## RFC-013

**Título:** Visibilidad temporal — tendencias diarias de actividad

**Estado:** ✔ Implementada

**Versión:** v2.1 (en desarrollo)

**Descripción**

Las vistas existentes (`dashboard_stats`, `dashboard_top`,
`dashboard_score`, `dashboard_status`) muestran una foto del estado
actual del sistema, pero ninguna permite ver cómo evolucionó la
actividad a lo largo del tiempo. Con más de 60.000 eventos reales
acumulados en la tabla `events`, no había forma de responder
preguntas como "¿esta semana hubo más ataques que la anterior?" o
"¿qué día tuve el pico de actividad?" sin consultar la base
manualmente.

**Implementación**

* `dashboard/trends.sh` (nuevo módulo) — `dashboard_trends(dias)`:
  agrupa eventos por día (`date(fecha, 'unixepoch')`), desglosando
  totales, `FOUND`, `BAN`, `EXTERNAL_UNBAN`, e IPs distintas por día,
  para una ventana configurable (default 7 días).
* Nueva opción "5) Tendencias" en la rama Estado/Reputación de ARE
  ADMIN, sin renumerar las opciones existentes.
* Sin datos nuevos ni instrumentación adicional: reutiliza
  exclusivamente la tabla `events` ya existente, poblada por el flujo
  normal de `handle_found`/`handle_ban`/`handle_external_unban` desde
  el inicio del proyecto.

**Validación**

Probado en producción con los 7 días reales más recientes. Reveló de
inmediato un pico real no detectado previamente: el 2026-08-15
registró 5767 eventos (vs. un rango normal de 500-1300 en los demás
días de la muestra), con un volumen de `EXTERNAL_UNBAN` (1518)
desproporcionado respecto al resto de la semana — queda anotado como
punto a investigar por separado, sin bloquear el cierre de esta RFC.

**Pendiente**

* Desglose por categoría dentro de la misma ventana temporal
  (extensión natural, mismo patrón de consulta).
* Exportación a CSV, reutilizando el patrón ya validado en RFC-011.

---



# IDEAS

## IDEA-001

**Título:** Exportación de métricas

Evaluar mecanismos para exportar métricas de ARE hacia sistemas externos.

---

## IDEA-002

**Título:** API REST

Evaluar una API para consulta e integración externa.

---

## IDEA-003

**Título:** Backend Manager

Evaluar una capa de administración de múltiples backends de firewall.

---

## IDEA-004

**Título:** Dashboard avanzado

Evaluar ampliaciones del dashboard, incluyendo:

* métricas históricas;
* gráficos;
* consultas avanzadas;
* análisis temporal;
* evolución de reputación.

---

# HISTORIAL DE BUGS RESUELTOS

Las siguientes incidencias forman parte del historial técnico de ARE y se conservan para trazabilidad.

## BUG-001

**Título:** Implementar `handle_unban()`

**Estado:** ✔ Resuelto

**Versión:** v1.0.1

**Corrección**

Se incorporó `handle_unban()` para completar el flujo de liberación de direcciones IP.

---

## BUG-005

**Título:** Inicialización duplicada del backend

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Corrección**

Se eliminó la doble inicialización de IPSet y Firewall centralizando el proceso en:

```text
backend/init.sh
```

---

## BUG-006

**Título:** La categoría ANOMALY no se refleja en las estadísticas

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Media

**Problema**

La categoría `ANOMALY` era utilizada por el Policy Engine y los perfiles de jail, pero no formaba parte inicialmente del modelo de reputación persistente.

**Impacto**

* Dashboard incompleto.
* Estadísticas inconsistentes.
* Categorías del motor y Dashboard no coincidentes.

**Corrección**

Se incorporó `ANOMALY` al modelo persistente junto con:

* `MALWARE`
* `DOS`
* `SOCIAL`

**Validación**

* `stats` muestra `Anomaly`.
* `score <ip>` muestra `Anomaly`.
* `FOUND modsec-anomaly` incrementa correctamente el total.

**Nota (2026-08-17):** si bien la categoría se refleja correctamente en
las estadísticas (objetivo original de este bug, sigue resuelto), se
detectó posteriormente que la regla de política asociada
(`policy/rules/anomaly.sh`) no se ejecuta en el flujo de decisión. Ver
BUG-012, que es un problema distinto (visualización vs. evaluación).

---

## BUG-007

**Título:** ARE no procesa correctamente eventos BAN/UNBAN provenientes de Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

ARE procesaba eventos `FOUND`, pero determinados eventos `BAN` y `UNBAN` generados por Fail2Ban no quedaban registrados correctamente en el historial.

**Evidencia inicial**

Fail2Ban registraba eventos `Unban`, pero la consulta:

```text
events <IP>
```

no mostraba la actividad correspondiente.

**Impacto**

* El ciclo `FOUND → BAN → UNBAN` podía quedar incompleto.
* El historial podía no representar la actividad real.
* ARE dependía parcialmente de la acción directa de Fail2Ban.

**Corrección**

El sensor Fail2Ban unificado incorporó el procesamiento de:

* `FOUND`
* `UNBAN`

Los eventos externos de liberación se registran como:

```text
EXTERNAL_UNBAN
```

`EXTERNAL_UNBAN` no libera directamente la IP.

ARE reevalúa la IP mediante el Policy Engine.

**Archivos relacionados**

* `sensors/fail2ban_found.sh`
* `/etc/fail2ban/action.d/ipset-smart.conf`
* `f2b-ipset.sh`
* `database.sh`

**Validación**

Validado en producción con:

```text
103.59.161.151
```

---

## BUG-008

**Título:** Incoherencia entre State Engine y Policy Engine para estado FILTER

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

Durante la ejecución del Decay Engine se detectaron IPs con:

```text
STATUS=NEW
```

mientras el Policy Engine devolvía:

```text
FILTER
```

para:

```text
LOW_RISK
```

**Evidencia**

```text
SCORE=23->21 STATUS=NEW POLICY=FILTER REASON=LOW_RISK
```

**Corrección**

Se modificó `state_update()` para reconocer `FILTER`.

**Validación**

El Decay Engine dejó de producir la incoherencia:

```text
STATUS=NEW POLICY=FILTER
```

Validado mediante:

```text
decay-apply
```

**Nota (2026-08-17):** se observó un caso similar en apariencia
(`STATUS=WATCH POLICY=TEMP_BAN` para la IP `45.33.70.56`), pero se
descartó como reaparición de este bug: la IP tenía historial de
reincidencia reciente (múltiples `BAN_LEVEL` escalados en 24 horas), por
lo que la política considera correctamente más que el score puntual. No
requiere acción.

---

## BUG-009

**Título:** `policy/apply.sh` no implementa la acción FILTER

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

El Policy Engine devolvía correctamente `FILTER`, pero `policy/apply.sh` no tenía una rama para ejecutar dicha acción.

**Evidencia**

```text
Policy decision: FILTER (LOW_RISK)
[APPLY] UNKNOWN ACTION: FILTER
```

**Corrección**

Se agregó soporte para:

```text
FILTER
```

IPv4 utiliza:

```text
FILTER_SET4
```

IPv6 utiliza:

```text
FILTER_SET6
```

`BAN` y `TEMP_BAN` utilizan sus conjuntos correspondientes.

**Validación**

Validado con:

```text
87.87.87.87
```

La IP fue incorporada correctamente a:

```text
are-filter
```

y el evento `FILTER` quedó registrado.

---

## BUG-010

**Título:** Ban Lifecycle no reconoce escalado permanente por salida multilínea

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

Ban Lifecycle devolvía:

```text
BAN|0|BAN_LEVEL_MAX
```

pero `policy/apply.sh` interpretaba incorrectamente el resultado como un ban temporal.

**Evidencia**

```text
[APPLY] Ban Lifecycle:
BAN|0|BAN_LEVEL_MAX

[APPLY] EXECUTE: TEMP BAN (0 sec)
```

**Corrección**

Se normalizó la salida de:

```text
ban_lifecycle_calculate()
```

y `policy/apply.sh` reconoce correctamente:

```text
BAN|0|BAN_LEVEL_MAX
```

**Validación**

El escalado permanente se ejecuta correctamente.

---

---

## BUG-011

**Título:** `db_increment_ban_level()` definida dos veces con comportamiento distinto

**Estado:** ✔ Resuelto

**Versión:** v2.0 (en desarrollo)

**Problema**

`database.sh` contenía dos definiciones de `db_increment_ban_level()`:
una sin límite de nivel y otra con `MAX_LEVEL`. La segunda sobrescribía
a la primera únicamente por orden textual dentro del archivo, sin
garantía explícita.

**Impacto**

Riesgo de que el Ban Lifecycle Engine dejara de respetar
`BAN_LEVEL_MAX` ante una futura reorganización del archivo (ver
TASK-009, donde ya se movieron funciones equivalentes a archivos
propios).

**Corrección**

Eliminada la definición sin tope. Permanece únicamente la versión con
`CASE WHEN ban_level < $MAX_LEVEL ...`.

**Validación**

```bash
./are.sh sanction-test 84.84.84.84
# Nivel de sanción actual: 7
```

Confirmado en producción, respetando `BAN_LEVEL_MAX`.

**Archivos relacionados**

* `database.sh`

---

## BUG-012

**Título:** Regla de política ANOMALY inalcanzable y desconectada del motor de decisión

**Estado:** ✔ Resuelto

**Versión:** v2.0 (en desarrollo)

**Corrección**

Resuelta como parte de RFC-009: `anomaly.sh` reescrita con el contrato
único de regla, conectada al orquestador real (`policy_evaluate()`).

**Archivos relacionados**

* `policy/rules/anomaly.sh`

---

## BUG-015

**Título:** Variable `DECISION`/`decision` con case inconsistente en `handle_external_unban()`

**Estado:** ✔ Resuelto

**Versión:** v2.0 (en desarrollo)

**Problema**

Durante el cutover manual de RFC-009 (reemplazar las tres llamadas a
`policy_decide()` por `policy_evaluate()` en `are.sh`), la edición de
`handle_external_unban()` asignó el resultado a `DECISION` (mayúscula),
mientras el resto de la función seguía leyendo `$decision` (minúscula,
declarada en el `local`). El resultado real de `policy_evaluate()`
quedaba en una variable que nadie consumía; `action` y `reason` quedaban
vacíos.

**Impacto**

Cada evento `EXTERNAL_UNBAN` en producción resultaba en
`[WARN] [APPLY] UNKNOWN ACTION:` — la IP no era re-evaluada
correctamente tras un unban externo, sin aplicar ninguna acción.

**Evidencia**

```
Policy decision after external unban:  ()
[APPLY] ACTION.........
[WARN ] [APPLY] UNKNOWN ACTION:
```

**Corrección**

```bash
sed -i '166s/DECISION=/decision=/' are.sh
```

**Validación**

```bash
./are.sh external-unban 185.202.158.215 modsec-lfi
```

Resultado tras el fix: `Policy decision after external unban: FILTER
(LOW_RISK)`, con `[APPLY] EXECUTE: FILTER` ejecutando correctamente.
Confirmado con una segunda IP real (`67.219.16.7`) sin recurrencia del
problema.

**Archivos relacionados**

* `are.sh`

---

## BUG-016

**Título:** Falta `policy/rules/credential.sh` — categoría CREDENTIAL sin regla evaluando su score

**Estado:** ✔ Resuelto

**Versión:** v2.0 (en desarrollo)

**Problema**

Durante la implementación de RFC-009 se escribieron reglas para 8 de
las 9 categorías (`exploit`, `bot`, `recon`, `protocol`, `bruteforce`,
`anomaly`, `malware`, `dos`, `social`). `CREDENTIAL` quedó sin regla
propia — `bruteforce.sh` evalúa una señal relacionada
(`ctx_get_events_24h`, frecuencia de eventos) pero no el score
acumulado de la categoría (`ctx_get_credential`) contra
`CREDENTIAL_THRESHOLD`.

**Impacto**

`CREDENTIAL_THRESHOLD=30` estaba definido en `policy.conf` y la
categoría figuraba en `REPUTATION_CATEGORIES`, pero ningún componente
del motor la evaluaba por score. Los 6 jails reales que suman a
`credential_score` (`sshd`, `telnet`, `dovecot`, `postfix-sasl`,
`mysqld-auth`, `modsec-bruteforce`) acumulaban reputación sin que ese
acumulado aportara al riesgo total — solo la señal de frecuencia de
`bruteforce.sh` protegía indirectamente esos jails.

**Detección**

Encontrado por la propia herramienta construida para detectarlo: la
opción "Validar" de la rama Política de ARE ADMIN (ver FEAT-005),
diseñada específicamente para confirmar que cada categoría con umbral
definido tenga su regla correspondiente en `policy/rules/`.

**Corrección**

Se creó `policy/rules/credential.sh`, mismo contrato único que las
demás 8 reglas: lee `CREDENTIAL_THRESHOLD` de `policy.conf`, aporta
`ctx_get_credential` al acumulador de riesgo si lo supera. Agregada a
`bootstrap.sh` junto al resto de `policy/rules/*.sh`.

**Validación**

```
POLÍTICA - Validación
  [OK]    CREDENTIAL -> policy_rule_credential()
  Resultado: CONFIGURACIÓN DE POLÍTICA VÁLIDA
```

Confirmado en producción con las 9 categorías mostrando `[OK]`.

**Archivos relacionados**

* `policy/rules/credential.sh` (nuevo)
* `bootstrap.sh`

---

## BUG-017

**Título:** Deriva de truncamiento entre `total_score` y la suma real de categorías

**Estado:** Identificado — corrección estructural en curso (ver RFC-008)

**Versión:** v2.1 (en desarrollo)

**Problema**

`reputation_decay_apply()` trunca (`CAST(... AS INTEGER)`) cada
columna de categoría de forma independiente, y trunca `total_score`
por separado en la misma sentencia. Nueve truncamientos
independientes pierden fracciones más rápido que un único
truncamiento sobre el total agregado. Con el Decay Engine corriendo
diariamente, el error se acumula: `total_score` almacenado queda
sistemáticamente por encima de lo que la suma real de sus categorías
justificaría.

**Impacto**

El motor de decisión (`policy_evaluate()`, piso de seguridad de
RFC-009) usa `total_score` como referencia — una deriva sistemática
hacia arriba no genera falsos negativos de seguridad, pero sí
distorsiona la precisión del score real con el que se calibran los
umbrales.

**Evidencia**

Detectado al verificar la migración de RFC-008 contra la base real de
producción (2366 IPs, servidor con 8 días de uptime y decay diario
activo). Prácticamente todas las IPs con actividad histórica muestran
`total_score` (viejo) mayor que `SUM(score)` real (nuevo), en
magnitud proporcional a la antigüedad de la IP — consistente con
acumulación diaria, no con un evento puntual.

**Corrección**

No se aplica un parche aislado. Se resuelve de raíz como parte de las
Fases 2-3 de RFC-008: al eliminar `total_score` como campo almacenado
y calcularlo siempre como `SUM(score)` sobre `reputation_scores`, dos
números que puedan desincronizarse dejan de existir — la deriva se
vuelve estructuralmente imposible, no solo corregida puntualmente.

**Archivos relacionados**

* `decay.sh` (`reputation_decay_apply`)
* Ver RFC-008 para la corrección definitiva.

---

## BUG-018

**Título:** IPs con coma sin limpiar en `EXTERNAL_UNBAN`, reputación partida en filas duplicadas

**Estado:** ✔ Resuelto

**Versión:** v2.1 (en desarrollo)

**Problema**

`sensors/fail2ban.sh` limpiaba el carácter `,` al final de la IP
únicamente en la rama `Found` (`IP="${IP%,}"`), no en la rama `Unban`.
Cuando una línea de log de Fail2Ban con formato de "Unban" traía la
IP seguida de coma, esa coma viajaba sin limpiar hasta
`handle_external_unban()`, que creaba/actualizaba una fila de
`reputation` para `"<ip>,"` como si fuera una IP distinta de `"<ip>"`.

**Impacto**

Reputación de IPs reales partida entre dos filas independientes en la
base de datos. Confirmado con evidencia real: `45.148.10.238` tenía
195 puntos en su fila limpia (`BANNED`) y 57 puntos adicionales en su
fila con coma (`WATCH`), sin que el motor de decisión pudiera ver el
score combinado real. Caso más grave detectado: `20.48.234.177` tenía
**0** en su fila limpia y **51** en la fila con coma — el score real
de esa IP era completamente invisible para el sistema.

**Evidencia**

Detectado al ejecutar `db_verify_reputation_scores_migration()`
(construida para RFC-008) contra la base real: 145 IPs con fila
duplicada por coma, la mayoría de ellas coincidiendo exactamente con
IPs reales que también existían limpias.

**Corrección**

* `sensors/fail2ban.sh`: agregada la limpieza `IP="${IP%,}"` también
  en la rama `Unban`, después de la asignación de `IP` (línea 49).
* `database.sh`: nueva función `db_merge_comma_duplicates()` — para
  cada par de filas limpia/con-coma, suma los scores por categoría,
  recalcula `total_score`, mueve los eventos asociados (tabla
  `events`) a la IP limpia, elimina la fila sucia, y ejecuta
  `state_update()` sobre el resultado.

**Validación**

Ejecutado en producción real sobre las 145 IPs afectadas. Verificado:
`db_verify_reputation_scores_migration()` pasó de listar 145 filas
con coma a `0`. `45.148.10.238` quedó en `251` puntos (195+57, sin
pérdida). `20.48.234.177` recuperó su score real (`51`, antes
invisible con `0`).

**Archivos relacionados**

* `sensors/fail2ban.sh`
* `database.sh`

---

## BUG-019

**Título:** Decay trunca cada categoría por separado — IPs con actividad diversificada decaen más rápido que las concentradas

**Estado:** ✔ Resuelto

**Versión:** v2.1 (en desarrollo)

**Problema**

`reputation_decay_apply()` (ya migrada a `reputation_scores` en RFC-008
Fase 3) aplicaba el factor de decay a cada fila de categoría por
separado: `UPDATE reputation_scores SET score = CAST(score * FACTOR AS
INTEGER)`. Cuando una IP tenía su score repartido entre varias
categorías, cada una truncaba de forma independiente, perdiendo más
fracción acumulada en total que si el factor se aplicara una sola vez
sobre el score agregado.

**Impacto**

Detectado con evidencia real en producción: una IP con
`EXPLOIT=18, RECON=3, CREDENTIAL=2, ANOMALY=2` (total=25) decayó a
`21` en una sola corrida (`25→21`, factor 0.95), cuando un único
truncamiento sobre el agregado daría `23` (`25×0.95=23.75→23`).
Consecuencia de seguridad real: una IP con actividad diversificada en
varias categorías se liberaba más rápido que una con actividad
concentrada en una sola, con el mismo score total — el resultado era
el inverso de lo deseable, ya que diversidad de técnicas de ataque
suele ser señal de mayor sofisticación, no de menor riesgo.

**Corrección**

`reputation_decay_apply()` calcula ahora el nuevo total como un único
truncamiento sobre el agregado (`new_total = floor(old_total *
FACTOR)`), y redistribuye ese total entre las categorías de forma
proporcional a su peso relativo, usando el método del "mayor resto"
(implementado en `awk` dentro del loop bash existente) para garantizar
que la suma de las categorías redistribuidas sea exactamente igual al
nuevo total, sin perder ni sobrar puntos. Para IPs con una sola
categoría activa, el resultado es idéntico al método anterior — el fix
solo cambia el comportamiento quando hay diversidad de categorías.

**Validación**

Probado con 4 casos límite (una sola categoría, score muy bajo cercano
a liberación, 5 categorías con valores chicos, y el caso real de
producción) ejecutando el `awk` real vía subprocess, no una
reimplementación aproximada. Confirmado en producción real: IP de
prueba reproduciendo el caso original (`203.0.113.60`) decayó
correctamente a `EXPLOIT=16, RECON=3, CREDENTIAL=2, ANOMALY=2`, total
`23` (antes: `21`). La misma corrida de `reputation_decay_apply()`
procesó además dos IPs reales de tráfico genuino
(`45.73.162.125`, `78.151.73.141`) con el mismo patrón de corrección
(`25→23`), confirmando el fix con datos de producción real, no solo
simulados.

**Archivos relacionados**

* `decay.sh` (`reputation_decay_apply`)

---

# BUG-014

**Título:** Bloque de código huérfano en `dashboard/events.sh`

**Estado:** ✔ Resuelto

**Versión:** v2.0 (en desarrollo)

**Problema**

`dashboard/events.sh` contenía un bloque `db_exec("SELECT COUNT(*) FROM
events WHERE date(fecha,'unixepoch')=date('now')")` ubicado fuera del
cuerpo de la función `dashboard_events()`, después de su cierre `}`. Al
estar a nivel de archivo, se ejecutaba en cada `source` del módulo (por
ejemplo, cada carga de `bootstrap.sh`), no cuando se invocaba la función.

**Impacto**

Overhead silencioso en cada carga del módulo. La misma lógica ya existía
correctamente implementada como función independiente:
`db_count_events_today()` en `database.sh`, consumida por
`dashboard/stats.sh`. El bloque suelto era una copia abandonada, sin
consumidor.

**Evidencia**

```bash
grep -rn "eventos_hoy\|events_today\|date('now')" --include="*.sh" .
# ./dashboard/stats.sh:31:    TODAY=$(db_count_events_today)
# ./dashboard/events.sh:29:        WHERE date(fecha, 'unixepoch') = date('now');
# ./database.sh:665:db_count_events_today() {
```

**Corrección**

Se eliminó el bloque huérfano de `dashboard/events.sh`, dejando únicamente
la definición de `dashboard_events()`.

**Validación**

```bash
./are.sh events 45.148.10.238
./are.sh events 5.5.5.5
```

Ambos casos confirmados en producción, comportamiento idéntico al previo
a la corrección.

---

---

# OBSERVACIONES

La documentación de trabajo debe mantenerse sincronizada con el estado real de ARE.

Las entradas históricas resueltas se conservan cuando aportan:

* contexto;
* decisiones arquitectónicas;
* fases de implementación;
* evidencias;
* validaciones;
* información necesaria para comprender la evolución del sistema.

Las funcionalidades ya incorporadas en una versión estable no deberán reaparecer como trabajo pendiente.

Las RFC representan propuestas sujetas a decisión y no deben confundirse con funcionalidades implementadas.

Las ideas no constituyen compromisos de implementación.

La versión estable documentada actualmente es:

```text
v1.1.0
```

La versión v2.0 se encuentra en desarrollo activo, incluyendo la
implementación de ARE ADMIN (FEAT-005).

El trabajo futuro deberá incorporarse al Roadmap antes de convertirse en una línea formal de desarrollo.
