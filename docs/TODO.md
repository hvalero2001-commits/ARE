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

## BUG-012

**Título:** Regla de política ANOMALY inalcanzable y desconectada del motor de decisión

**Estado:** Pendiente

**Prioridad:** Alta

**Problema**

`policy/rules/anomaly.sh` define `policy_anomaly()` con dos fallas:

1. **Umbral de bloqueo inalcanzable.** La condición `SCORE -ge 5` hace
   `return 0` antes de evaluar `SCORE -ge 10`, por lo que la rama `BLOCK`
   nunca se ejecuta: cualquier score que cumpliría el umbral de bloqueo ya
   fue capturado antes por el umbral de `WATCH`.

2. **La regla no está conectada al motor.** El array `RULES` en
   `policy/engine.sh` no incluye `anomaly`. Además, el nombre de la función
   (`policy_anomaly`) no sigue el patrón `policy_rule_<nombre>` que usan el
   resto de las reglas (`policy_rule_exploit`, `policy_rule_bot`, etc.), por
   lo que aunque se agregara `anomaly` al array, tampoco engancharía sin
   renombrar la función.

**Impacto**

La categoría `ANOMALY` acumula score en la tabla `reputation` (columna
`anomaly_score`) pero ese score nunca es evaluado por el Policy Engine.
Una IP puede tener actividad anómala significativa sin que eso module la
decisión de bloqueo.

**Evidencia**

```bash
cat policy/rules/anomaly.sh
grep -n "RULES=" -A 6 policy/engine.sh
```

**Corrección propuesta**

* Invertir el orden de las comparaciones (evaluar `-ge 10` antes que
  `-ge 5`), o reestructurar con `elif`.
* Renombrar `policy_anomaly()` a `policy_rule_anomaly()`, consistente con
  el resto de las reglas.
* Incorporar `"anomaly"` al array `RULES` de `policy/engine.sh`.

**Nota**

Investigación cerrada (ver RFC-009): se confirmó que `policy/engine.sh`,
`policy/policy.sh` y `policy/rules/core.sh` son código muerto — ningún
archivo del proyecto los carga mediante `source`. El motor que
efectivamente decide en producción es `policy/decision_engine.sh`, que
no evalúa reglas por categoría en absoluto (ni siquiera las que sí
funcionan, como `exploit` o `bot`).

Por lo tanto, esta corrección puntual de `anomaly.sh` **no tiene efecto
por sí sola**: incluso corrigiendo el orden de las comparaciones y el
nombre de la función, `anomaly.sh` seguiría sin ejecutarse nunca, porque
todo el mecanismo de reglas por categoría (`policy/rules/*.sh`) está
desconectado del flujo real. La corrección de este bug queda supeditada
a la implementación de RFC-009.

**Archivos relacionados**

* `policy/rules/anomaly.sh`
* `policy/engine.sh`

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

**Título:** Centralizar `LOG_FILE` del sensor Fail2Ban en `config.conf`

**Estado:** Pendiente

**Prioridad:** Media

**Descripción**

`sensors/fail2ban.sh` define `LOG_FILE="/var/log/fail2ban.log"` como valor
fijo dentro del script, en lugar de tomarlo de `config/config.conf`. Esto
es inconsistente con el principio de centralización de rutas ya aplicado
en TASK-012 para el resto de las variables operativas (`ARE_HOME`,
`ARE_DATA`, `ARE_BIN`, etc.).

**Alcance**

* Agregar `FAIL2BAN_LOG_FILE` (o nombre equivalente) a `config/config.conf`.
* Modificar `sensors/fail2ban.sh` para leer la variable desde la
  configuración en lugar de tenerla hardcodeada.

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

`config/policy.conf` define umbrales de categoría (`*_THRESHOLD`) solo
para `RECON`, `EXPLOIT`, `CREDENTIAL`, `PROTOCOL` y `BOT`. Las categorías
`ANOMALY`, `MALWARE`, `DOS` y `SOCIAL` —incorporadas al modelo de
reputación en TASK-005 y BUG-006— no tienen umbral definido en
configuración.

Como parte de la implementación de ARE ADMIN (ver FEAT-005), se incorporó
la variable `REPUTATION_CATEGORIES` a `policy.conf` como catálogo
explícito y única fuente de verdad de las categorías soportadas, consumida
por `admin/categories.sh`.

**Alcance**

* ✔ Agregar `REPUTATION_CATEGORIES` a `policy.conf`.
* ✔ `admin/categories.sh` (`categories_list`, `categories_scores`) lee el
  catálogo y los umbrales dinámicamente; muestra `N/D` cuando el umbral no
  está definido.
* Pendiente: definir `ANOMALY_THRESHOLD`, `MALWARE_THRESHOLD`,
  `DOS_THRESHOLD`, `SOCIAL_THRESHOLD` — depende de que `MALWARE`, `DOS` y
  `SOCIAL` tengan primero una regla de política activa (ver RFC-006; hoy
  no existe `policy/rules/malware.sh`, `dos.sh` ni `social.sh`), y de
  resolver BUG-012 para `ANOMALY`.

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

**Estado:** En progreso

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
| 4. Política | Pausada — bloqueada por RFC-009 (rediseño del motor de decisión) |
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

**Estado:** Draft

**Descripción**

El modelo actual de reputación almacena cada categoría como una columna
fija en la tabla `reputation` (`recon_score`, `exploit_score`, etc.).
Agregar una categoría nueva requiere modificar el esquema (`ALTER TABLE`)
y actualizar múltiples funciones que enumeran las columnas explícitamente
(`db_get_reputation()`, `db_sum_categories()`, `db_top_attackers()`,
`dashboard/score.sh`).

**Objetivo**

Evaluar la migración hacia un esquema normalizado, por ejemplo
`reputation_scores(ip, category, score)`, donde agregar una categoría
nueva sea una operación de datos (`INSERT`) y no una migración de
estructura. Esto es consistente con el principio ya documentado en
`docs/DESIGN.md` Sección 3.2 de no convertir jails en columnas
independientes — el mismo criterio aplicado hoy de forma inconsistente
a las categorías.

**Nota de riesgo operativo**

Dado que el sistema corre en múltiples servidores de producción, esta
migración debe evaluarse con un entorno de prueba/canario antes de
aplicarse, no como cambio directo en caliente.

---

## RFC-009

**Título:** Motor de decisión único: reactivar evaluación de riesgo por categoría

**Estado:** Draft — investigación completa, diseño pendiente de implementación

**Descripción**

Se investigó cuál de las múltiples definiciones concurrentes del Policy
Engine (ver histórico de esta investigación, originalmente registrada
como BUG-013) gobierna efectivamente las decisiones en producción. La
investigación se dio por cerrada con evidencia completa:

**Motor real confirmado:** `policy/decision_engine.sh::policy_decide()`.
Confirmado por dos vías independientes: (1) es la única función de
decisión invocada directamente desde `are.sh`, en las tres funciones que
procesan eventos (`handle_found`, `handle_ban`,
`handle_external_unban`); (2) su lógica de `HARD OVERRIDE` para
`STATUS=BANNED` coincide exactamente con el `REASON=STATE_BANNED`
observado en logs reales de producción (`decay-apply`, IP
`138.2.102.66`).

**Código muerto confirmado, sin uso en ningún punto del flujo real:**

* `policy/policy.sh` (`policy_action()`, array `POLICY_RULES`)
* `policy/engine.sh` (`policy_evaluate()`)
* `policy/rules/core.sh` (segunda definición de `policy_evaluate()`)
* `policy/decision.sh` (segunda definición de `policy_decide()`, cargada
  únicamente por `policy/engine.sh`, que a su vez no es cargado por
  nadie)

Confirmado mediante búsqueda exhaustiva de invocaciones
(`policy_evaluate`, `policy_rule_*`) fuera de sus propias definiciones:
no existen.

**Hallazgo principal — el motor real no evalúa por categoría**

`policy_decide()` decide exclusivamente por umbrales fijos sobre el
score total (`TOTAL -ge 80` → `BAN`, `-ge 50` → `TEMP_BAN`, `-ge 20` →
`FILTER`, `-gt 0` → `WATCH`), sin distinguir entre categorías
(`EXPLOIT`, `CREDENTIAL`, `ANOMALY`, etc.) y sin leer los umbrales
configurados en `config/policy.conf`. El sistema de reglas modulares por
categoría (`policy/rules/exploit.sh`, `bot.sh`, `bruteforce.sh`,
`recon.sh`, `protocol.sh`, `anomaly.sh`), que sí contempla esa
distinción, existe y está razonablemente bien escrito, pero nunca se
ejecuta en el flujo real.

**Objetivo de diseño (confirmado con el mantenedor del proyecto)**

El comportamiento deseado es que la categoría que activa un evento
module el score/riesgo asignado — una IP clasificada por actividad
`ANOMALY` no debería representar el mismo riesgo que un intento de
inyección SQL (`EXPLOIT`) — y que el motor evalúe ese riesgo por
categoría antes de decidir la acción, aplicando el ciclo de sanción
escalonada (Ban Lifecycle) cuando corresponda. Esta es precisamente la
intención original detrás de `policy/engine.sh` y `policy/rules/*.sh`,
que quedó parcialmente implementada y desconectada del flujo real.

**Alcance propuesto**

* Decidir explícitamente: reactivar y completar el motor modular
  (`engine.sh` + `rules/*.sh`), o rediseñar uno nuevo que preserve la
  evaluación por categoría sin arrastrar el código ya abandonado.
* Si se reactiva el existente: corregir BUG-012 (orden de comparación y
  nombre de función en `anomaly.sh`), completar reglas faltantes para
  `MALWARE`, `DOS`, `SOCIAL` (ver RFC-006), y conectar `policy_evaluate()`
  al flujo real que hoy usa `policy_decide()`.
* Definir la relación entre el resultado por categoría y los umbrales
  globales de `policy.conf` (hoy sin uso real, ver TASK-017).
* Eliminar el código confirmado como muerto (`policy.sh`, `engine.sh`
  actual, `rules/core.sh`, `decision.sh`) una vez completada la
  migración, no antes.

**Nota de riesgo operativo**

Cambiar el motor de decisión activo afecta directamente el
comportamiento de bloqueo en múltiples servidores de producción. Se
recomienda: (1) implementar y probar en un entorno aislado; (2) aplicar
primero en un único servidor "canario" antes de replicar al resto de la
flota; (3) mantener capacidad de rollback inmediato (`decision_engine.sh`
actual como fallback) durante el período de validación.

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
