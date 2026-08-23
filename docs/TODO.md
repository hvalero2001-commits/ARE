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

**Progreso registrado (sesión IDEA-007, v2.2)**

Avance concreto sobre el alcance "sincronizar versiones" y "separar
trabajo histórico de trabajo pendiente" de este TASK, sin cerrarlo
del todo — el alcance sigue siendo más amplio que lo tocado en esta
sesión:

* `VERSION`, `config/config.conf::VERSION` y
  `manifest/product.sh::PRODUCT_VERSION` estaban desincronizados
  (`2.1.0` en los dos primeros, `2.2.0` en el manifiesto desde
  RFC-016) — alineados los tres a la versión real de desarrollo.
* `RFC-013` documentaba dos pendientes ya resueltos en el mismo
  commit que los implementó — actualizada su sección Pendiente con
  el detalle real.
* `BUG-014` corregido de encabezado (`#` → `##`) y reubicado a su
  posición cronológica, en vez de aparecer fuera de secuencia al
  final del historial.
* `BUG-002` (observación abierta desde v1.x) cerrado con evidencia
  real acumulada, movido de la sección de bugs activos al historial
  resuelto.

---

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

## TASK-015

**Título:** Eliminar duplicación de `db_get_sanction()` en `database.sh`

**Estado:** ✔ Resuelto

**Prioridad:** Baja

**Versión:** v2.1 (en desarrollo)

**Descripción**

`db_get_sanction()` estaba definida dos veces en `database.sh`, con
contenido idéntico. No generaba comportamiento incorrecto (la segunda
definición sobrescribía a la primera sin cambiar el resultado), pero
era ruido que dificultaba la lectura y mantenimiento del archivo.

**Corrección**

Confirmado con `grep -n "^db_get_sanction()" database.sh` que la
función aparece una única vez — la duplicación fue eliminada como
parte de alguna de las reorganizaciones de `database.sh` realizadas
durante RFC-007/RFC-008, sin haber quedado registrada explícitamente
en su momento como resolución de esta tarea puntual.

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

---

## TASK-017

**Título:** Sincronizar umbrales documentados en `ARCHITECTURE.md` con los valores reales de `policy.conf`

**Estado:** ✔ Resuelta — de forma incidental, no por acción directa

**Prioridad:** Media

**Descripción original**

`docs/ARCHITECTURE.md` documentaba los umbrales efectivos de política
como una tabla fija (`Score ≥ 200 → TEMP_BAN`...), mientras que
`config/policy.conf` define umbrales por variable
(`WATCH_SCORE=20`, `TEMP_BAN_SCORE=60`, `PERMANENT_BAN_SCORE=100`) —
dos escalas distintas, documentación que no coincidía con la
configuración activa. En su momento se agregó además la sospecha
(sin confirmar entonces) de que el motor real ni siquiera leía esos
valores de `policy.conf`, sino que usaba umbrales hardcodeados
(`80`/`50`/`20`) — un tercer esquema, distinto a los otros dos.

**Resolución**

Verificado en esta sesión, con el código real delante:
`policy/decision_engine.sh` sí lee `WATCH_SCORE`, `TEMP_BAN_SCORE` y
`PERMANENT_BAN_SCORE` de `policy.conf` — no hay ningún `80/50/20`
hardcodeado. La sospecha de un tercer esquema quedó descartada.

Y sobre el problema original: `docs/ARCHITECTURE.md`, sección
"Policy Engine", **ya no contiene** la tabla de umbrales fijos que
esta tarea reportaba — describe correctamente la evaluación por
categoría, con umbrales configurables en `policy.conf` por regla
(`policy/rules/<categoria>.sh`). El documento fue corregido en algún
punto posterior a cuando se escribió esta tarea (probablemente junto
con la reescritura del motor a evaluación por categoría, `RFC-009`),
pero nadie volvió a cerrar esta entrada para reflejarlo — quedó
pendiente en el papel mucho después de estar resuelta en los hechos.

**Archivos relacionados**

* `docs/ARCHITECTURE.md`
* `config/policy.conf`
* `policy/decision_engine.sh`

---

## TASK-018

**Título:** Completar catálogo de categorías y umbrales faltantes en `policy.conf`

**Estado:** ✔ Resuelto

**Prioridad:** Media

**Descripción**

`config/policy.conf` define umbrales de categoría (`*_THRESHOLD`) para
las 9 categorías del catálogo (`RECON`, `EXPLOIT`, `CREDENTIAL`,
`PROTOCOL`, `BOT`, `ANOMALY`, `DOS`, `MALWARE`, `SOCIAL`).

Como parte de la implementación de ARE ADMIN (ver FEAT-005), se incorporó
la variable `REPUTATION_CATEGORIES` a `policy.conf` como catálogo
explícito y única fuente de verdad de las categorías soportadas, consumida
por `admin/categories.sh`.

**Umbrales calibrados**

* `ANOMALY_THRESHOLD=40` — señal heurística blanda (ModSecurity generic
  anomaly), calibrada entre `RECON`(80) y `PROTOCOL`(20): necesita
  acumulación sostenida, pero menos que un simple escaneo.
* `DOS_THRESHOLD=30` — amenaza confirmada (umbral determinístico de
  `mod_evasive`, no heurística), calibrada al mismo nivel que
  `CREDENTIAL`(30): pocos eventos bastan para disparar.
* `SOCIAL_THRESHOLD=40` (v2.2, RFC-016) — mismo nivel que `ANOMALY`:
  heurística de spam vía SpamAssassin, con el mismo riesgo de falso
  positivo (mensaje legítimo mal puntuado) que un heurístico de
  ModSecurity. Calibrado con sensor real (`sensors/spamassassin.sh`)
  ya reportando en producción.
* `MALWARE_THRESHOLD=30` — mismo nivel que `CREDENTIAL`/`DOS`,
  calibrado **sin sensor local reportando todavía** (excepción
  deliberada al criterio general de "no definir umbrales
  especulativos sin evidencia"): este servidor no tiene superficie
  real de malware (tráfico de e-commerce, sin ClamAV/escaneo de
  archivos activo — ver IDEA sobre recolección de perfiles de
  colegas), pero dejar el umbral indefinido resolvería únicamente el
  problema de este servidor puntual, no el de ARE como motor
  genérico. Un colega que sume un sensor real de malware (ClamAV,
  Imunify360, maldet) encuentra el umbral ya funcionando via
  `jail_profile`, sin tener que definirlo él mismo. Pendiente de
  validación con datos reales el día que exista un sensor, propio o
  de un tercero.

Calibración basada en `weight × confidence` de los jails reales
asignados a cada categoría y en el número de eventos que ese cálculo
implica para cruzar el umbral, siguiendo el mismo criterio ya aplicado
consistentemente en las 9 categorías.

**Alcance**

* ✔ Agregar `REPUTATION_CATEGORIES` a `policy.conf`.
* ✔ `admin/categories.sh` (`categories_list`, `categories_scores`) lee el
  catálogo y los umbrales dinámicamente; muestra `N/D` cuando el umbral no
  está definido.
* ✔ `ANOMALY_THRESHOLD` y `DOS_THRESHOLD` definidos y calibrados.
* ✔ `SOCIAL_THRESHOLD` definido y calibrado con sensor real (RFC-016).
* ✔ `MALWARE_THRESHOLD` definido y calibrado, sin sensor local — ver
  justificación arriba.

**Archivos relacionados**

* `config/policy.conf`
* `admin/categories.sh`

---

## TASK-019

**Título:** Higiene de repositorio previa a IDEA-007 (empaquetado)

**Estado:** ✔ Resuelto

**Prioridad:** Baja

**Versión:** v2.2 (en desarrollo)

**Descripción**

Dos limpiezas menores de repositorio, encontradas al inspeccionar el
contenido real del primer `.tar.gz` generado por
`scripts/build-package.sh` (IDEA-007) — ninguna afectaba el
funcionamiento de ARE, ambas afectaban la calidad de lo distribuido a
un colega nuevo.

**Alcance**

* `.gitignore` — `*.tar.gz`/`*.tar.gz.sha256` no estaban ignorados;
  cada build local ensuciaba `git status` con un binario nuevo.
* Eliminados 5 archivos placeholder vacíos (0 bytes) en `sensors/`
  (`apache.sh`, `crowdsec.sh`, `modsecurity.sh`, `suricata.sh`,
  `zeek.sh`), dejados como recordatorio de intención futura —
  viajaban en el paquete distribuible sin ninguna distinción visual
  respecto a los sensores reales y funcionales. La intención que
  representaban ya está documentada en `ROADMAP.md`, sección
  "Próximas líneas de trabajo"; mantenerlos hubiera obligado a
  excluirlos a mano del empaquetado cada vez que se agregara un
  placeholder nuevo.

**Archivos relacionados**

* `.gitignore`
* `sensors/`

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
filtrando tráfico antes de que llegue a Apache/`mod_evasive`.

**Intento deliberado de validación (2026-08-19, más tarde)**

Se desactivó temporalmente "Under Attack Mode" para intentar destapar
tráfico real que ejercitara el sensor. Confirmado con historial de
`/var/log/apache2/mod_evasive/*.filtered` que `mod_evasive` sí tiene
actividad de detección real y reciente (eventos entre el 5 y el 15 de
agosto, previos a la integración con ARE) — el mecanismo de detección
en sí funciona; lo que falta es que un evento nuevo coincida con la
ventana de observación post-integración. Sin resultado en la primera
hora de monitoreo tras desactivar el modo de Cloudflare.

**Decisión**: se mantiene "Under Attack Mode" desactivado de forma
indefinida (no se reactiva de inmediato), a la espera de que ocurra
un evento real que ejercite el sensor de forma genuina, sin bloquear
el resto del trabajo de la sesión mientras tanto. La integración
queda técnicamente validada (con tráfico de prueba); su primera
validación con tráfico real de flood permanece pendiente.

---

## RFC-013

**Título:** Visibilidad temporal — tendencias diarias de actividad

**Estado:** ✔ Implementada — pendientes cerrados en v2.2

**Versión:** v2.1 (en desarrollo) — cierre de pendientes en v2.2

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
desproporcionado respecto al resto de la semana — investigado por
separado durante la sesión de RFC-016: misma causa que un pico
posterior de `CREDENTIAL`/`EXPLOIT`, ambos coincidentes con ventanas
sin Cloudflare Under Attack Mode.

**Pendientes cerrados en v2.2**

* **Desglose por categoría** — `dashboard_trends_by_category(dias)`:
  mismo patrón de agrupación por día, con `JOIN` contra
  `jail_profile` para resolver la categoría de cada evento a partir
  de su `jail`. El `JOIN` (inner) excluye automáticamente eventos
  internos sin jail administrado (mismo mecanismo implícito que ya
  usa `TOP JAILS`), sin necesidad de una lista de exclusión aparte.
  Opción "6) Tendencias por categoría" en el mismo menú.
* **Exportación a CSV** — `dashboard_trends_export(dias)`: mismo
  patrón de archivo con timestamp en `${ARE_DATA}/backups/trends/`
  ya validado en RFC-011. Opción "7) Exportar tendencias (CSV)".
* Validación en producción de ambos: el desglose por categoría reveló
  un segundo pico real (`CREDENTIAL=3332` el 2026-08-20, contra un
  rango normal de 40-90), confirmando la misma causa raíz que el pico
  de `EXTERNAL_UNBAN` del 15 de agosto.

---

## RFC-014

**Título:** Restaurar ipset desde `sanction_state` al arrancar el sistema

**Estado:** ✔ Implementada

**Versión:** v2.1 (en desarrollo)

**Descripción**

`ipset` no persiste nativamente entre reinicios del servidor — sus
sets viven en memoria del kernel. El mecanismo de persistencia nativo
de AlmaLinux (`ipset.service`) solo restaura los sets con el nombre
histórico (`blacklist`, `blacklist6`, previos a la identidad `are-*`),
que hoy están vacíos y sin uso. Los sets reales de ARE (`are-blacklist`,
`are-filter`, etc.) no tenían ningún mecanismo de restauración
explícito.

**Contexto que motivó la investigación**

Tras una actualización de kernel con reinicio real del servidor, se
observó que `are-blacklist` volvió a tener contenido pese a la falta
de mecanismo de persistencia conocido. Investigación con evidencia
real confirmó que el repoblado ocurría de forma indirecta: el flujo
normal de eventos (`handle_found`/`handle_ban`) reevalúa cualquier IP
que vuelve a generar tráfico contra `sanction_state`, y el hard gate
de `STATUS=BANNED` la re-agrega al ipset. Funcional para IPs
permanentes que reinciden, pero **insuficiente para sanciones
temporales**: una IP con `TEMP_BAN` activo (por ejemplo, con 1 hora
restante de una sanción de 24) se pierde completamente tras un reboot
si no vuelve a generar tráfico antes de que expire su `ban_until`
real en la base — el temporizador de la sanción, en la práctica,
dejaba de cumplirse.

**Implementación**

* `infrastructure/restore_ipsets.sh` (nuevo) — script de ejecución
  única al arrancar: consulta `sanction_state` por IPs con
  `permanent=1` o `ban_until` en el futuro, y las reincorpora al
  ipset correspondiente (`BAN_SET4`/`BAN_SET6` según familia),
  **preservando el tiempo restante exacto** (`ban_until - now`) en
  vez de reiniciar la sanción a su duración completa original.
  Excluye IPs whitelisteadas y sanciones ya expiradas.
* `systemd/are-restore-ipsets.service` (nuevo) — unidad `oneshot` con
  `After=network.target ipset.service` y `Requires=ipset.service`,
  disparada una sola vez por boot, no periódica.
* Agregada a `PRODUCT_SYSTEMD_UNITS` en `manifest/product.sh`.

**Hallazgo real durante la validación: BUG-020**

Al probar la restauración contra datos reales, `ipset add` falló para
varias IPs con "out of range 0-2147483" — el mismo límite máximo de
`ipset` en esta versión ya identificado en RFC-010. La causa raíz no
estaba en el script nuevo: `policy/apply.sh`, en la rama `TEMP_BAN`,
pasaba `SANCTION_TIME` sin capear a `ipset add`. Como
`BAN_LEVEL_6_TIME=2592000` (30 días) supera el límite de `ipset`
(~24.85 días), **cualquier IP real que escalara al nivel 6 del Ban
Lifecycle quedaba marcada como sancionada en `sanction_state` sin
que el bloqueo se aplicara efectivamente en el firewall** — el error
de `ipset` se descartaba silenciosamente (`2>/dev/null`) sin ningún
chequeo del código de salida, en las 4 líneas de `ipset add`/`ipset
del` de todo el archivo.

**Corrección de BUG-020**

* Nueva variable `IPSET_MAX_TIMEOUT=2147483` en `config.conf` (real y
  plantilla), como fuente única del límite — usada tanto en
  `policy/apply.sh` como en `restore_ipsets.sh`, sin repetir el
  número en ningún lugar.
* `policy/apply.sh`: `SANCTION_TIME` se capea a `IPSET_MAX_TIMEOUT`
  antes de aplicarse, con `WARN` explícito cuando ocurre.
* Se agregó `-exist` a las 4 llamadas de `ipset add`/`ipset del` en
  `policy/apply.sh` (ausente en el original, a diferencia de
  `infrastructure/ipset.sh::banIP()`, que ya lo usaba) — hace la
  operación idempotente y elimina el motivo original por el que
  alguien había silenciado los errores.
* Se eliminó el silenciamiento de errores (`2>/dev/null`) en las 4
  líneas, reemplazado por chequeo explícito del código de salida y
  `ERROR` visible en el log cuando `ipset` falla de verdad.

**Validación**

Reproducido el bug con una IP de prueba forzada a `ban_level=5` en
`sanction_state` (para que `ban_lifecycle_calculate()` calculara el
salto a nivel 6): confirmado el `WARN` de capeo y el `ipset add`
exitoso con `timeout 2147483` (antes: error "out of range", sin
bloqueo real aplicado). Restauración completa probada simulando un
reboot (`ipset flush` + `restore_ipsets.sh`): 168 IPs reales
restauradas sin errores, incluyendo las mismas IPs que antes fallaban
por rango (`192.42.116.107`, `85.11.167.225`), ahora correctamente
capeadas. Confirmado que los tiempos restaurados no son valores
"redondos" del Ban Lifecycle sino tiempos restantes reales
(`191.242.209.98` con `1829537s`, ~21.2 días, no coincide con ningún
nivel fijo de la tabla), confirmando que se preserva el tiempo
restante genuino, no se reinicia la sanción.

**Validación con reboot real (2026-08-19, extensión posterior)**

Confirmado con un reinicio genuino del servidor (no simulado):
`are-restore-ipsets.service` corrió automáticamente al arrancar
(`journalctl` confirma ejecución sin intervención manual), y
`are-blacklist` quedó poblado con 146 sanciones activas reales tras
el boot.

**Hallazgo adicional durante esta validación: `FILTER_SET` también se
pierde en cada reinicio, sin ningún mecanismo de restauración**

El diseño original de esta RFC solo cubría `BAN_SET`, restaurado desde
`sanction_state`. El estado `FILTER` (`reputation.status='FILTER'`) es
un mecanismo distinto — no vive en `sanction_state`, no tiene
`ban_until` que preservar — y quedó completamente fuera del alcance
original. Confirmado con evidencia real: tras el reboot, la base de
datos tenía 178 IPs con `status='FILTER'`, pero el `ipset are-filter`
solo conservaba 13 (las que habían vuelto a generar tráfico y fueron
re-agregadas por el flujo normal, igual que ocurre con `BAN` cuando no
existía este mecanismo).

**Corrección**

`infrastructure/restore_ipsets.sh` extendido: además de restaurar
`BAN_SET` desde `sanction_state` (con tiempo restante preservado),
ahora también restaura `FILTER_SET` desde `reputation.status='FILTER'`
(sin timeout, igual que la creación original en `policy/apply.sh`).
Misma exclusión de IPs whitelisteadas en ambos casos.

**Validación de la extensión**

Simulado con `ipset flush are-filter` + corrida del script: log
confirma `FILTER restaurados=178`, coincidiendo con el conteo real de
`reputation.status='FILTER'` en la base; el `ipset` quedó con 170
entradas (diferencia esperable por exclusión de whitelist).

**Pendiente**

* Evaluar si el mismo problema de timeout fuera de rango puede
  afectar a `FILTER_SET` en escenarios de muy larga duración (hoy
  `FILTER` no usa timeout, por lo que no aplica actualmente).

**Archivos relacionados**

* `infrastructure/restore_ipsets.sh` (nuevo)
* `systemd/are-restore-ipsets.service` (nuevo)
* `policy/apply.sh`
* `config/config.conf`
* `manifest/product.sh`

---

## RFC-015

**Título:** Atajo de salida directa en ARE ADMIN (`x) Salir`)

**Estado:** ✔ Implementada

**Versión:** v2.1 (en desarrollo)

**Descripción**

Hasta esta RFC, salir de ARE ADMIN desde cualquier submenú requería
navegar de vuelta al menú raíz (`0) Volver`, repetido tantas veces
como niveles de profundidad) antes de poder usar `0) Salir` desde
ahí. Con 7 ramas y hasta 7 opciones por rama, un administrador que
solo quería cerrar la sesión debía recorrer el árbol completo hacia
atrás.

**Decisión de diseño**

Se evaluaron dos alternativas: agregar un número nuevo (ej. `9)
Salir`) junto a las opciones existentes, o renombrar `0)` de "Volver"
a "Salir" cambiando su semántica. Se descartaron ambas: la primera
por no escalar bien si una rama crece más allá de 8-9 opciones
numéricas (el atajo dejaría de distinguirse visualmente del resto); la
segunda por reasignar el significado de una tecla ya conocida y muy
usada (`0`), con riesgo de que alguien cierre el programa pensando
que solo retrocede un nivel.

Se optó por una letra (`x`) en lugar de un número: nunca compite con
el rango de opciones numéricas de ningún submenú, sin importar cuánto
crezca, y queda visualmente distinguida del resto de las opciones.

**Implementación**

* `admin_exit()` (nueva, en `admin/core.sh`): función única de
  salida, invocada desde los 8 puntos donde corresponde (el `0)` del
  menú raíz y el alias `x|X` en los 7 submenús), evitando duplicar el
  mensaje de despedida en cada archivo.
* Cada uno de los 7 submenús (`jails.sh`, `categories.sh`,
  `sensors_menu.sh`, `config_menu.sh`, `policy_menu.sh`,
  `decay_menu.sh`, `state_menu.sh`) agrega `x) Salir` a su listado de
  opciones y `x|X) admin_exit ;;` a su `case`, sin modificar ninguna
  otra opción existente (`0) Volver` conserva su semántica y número
  originales en todos los niveles).
* El menú raíz no repite la línea visual `x) Salir` (ya tiene
  `0) Salir` explícito, que cumple la misma función), pero sí acepta
  el alias `x|X` por consistencia con el resto de la interfaz.

**Hallazgo adicional durante la revisión de `sensors_menu.sh`**

Al tocar ese archivo para agregar la opción `x`, se encontró que
`sensors_status()` y `sensors_config()` mostraban información
desactualizada al administrador: `apache_evasive` figuraba como
sensor "no implementado aún" (implementado desde RFC-012), y
`sensors_config()` describía el log de Fail2Ban como ruta fija y el
filtro de jails como lista estática (ambos corregidos desde
TASK-016). Corregido en el mismo cambio, ya que el archivo se estaba
modificando de todos modos.

**Validación**

Probado en las 7 ramas: `x` desde cualquier submenú cierra el
programa completo de inmediato, sin pasar por el menú raíz. `0)
Volver` sigue funcionando sin cambios en su comportamiento original.

**Archivos relacionados**

* `admin/core.sh`
* `admin/jails.sh`
* `admin/categories.sh`
* `admin/sensors_menu.sh`
* `admin/config_menu.sh`
* `admin/policy_menu.sh`
* `admin/decay_menu.sh`
* `admin/state_menu.sh`

---

## RFC-016

**Título:** Sensor SpamAssassin — categoría SOCIAL

**Estado:** ✔ Implementada y validada en producción

**Versión:** v2.2 (en desarrollo)

**Descripción**

Primera funcionalidad de la línea v2.2. Surge de completar una
categoría que ya existía en el modelo desde RFC-009
(`REPUTATION_CATEGORIES`, regla `policy_rule_social()`) pero sin
ningún sensor real que la alimentara — `SOCIAL_THRESHOLD` estaba
vacío y la regla, aunque escrita, nunca se ejecutaba.

Se evaluó primero MALWARE como candidato de la misma naturaleza (sin
sensor), pero se descartó por falta de superficie real en este
servidor (tráfico es e-commerce → clientes, sin ClamAV/escaneo de
malware activo) — queda como IDEA para publicación/comunidad, no como
tarea de v2.2. SpamAssassin, en cambio, sí tiene tráfico real
(mensajería de e-commerce saliente vía Exim), y quedó como la
categoría con datos disponibles para calibrar sin depender de
terceros.

**Decisiones de diseño**

* **Bandas en vez de score variable por evento.** Se descartó pasar
  el score de SpamAssassin como peso variable directo (rompería el
  contrato de `handle_found()`, que toma weight/confidence fijos del
  `jail_profile`). En su lugar, tres jails virtuales por rango de
  score (`spamassassin-low` 5.0–9.99, `spamassassin-med` 10.0–14.99,
  `spamassassin-high` ≥15.0), cada uno con su propio perfil — cero
  cambios en `database.sh` ni en `policy/`.
* **Adaptador por MTA.** El sensor (`sensors/spamassassin.sh`) aísla
  la extracción de IP+score en una función por MTA
  (`extract_spam_event_<mta>`, seleccionada por `SPAMASSASSIN_MTA` en
  `config.conf`). Único adaptador implementado y validado: `exim`.
  Sumar otro MTA es agregar una función, no reescribir el sensor.
* **Separación config.conf / policy.conf.** `SPAMASSASSIN_MTA` y
  `SPAMASSASSIN_LOG_FILE` (infraestructura) quedan en `config.conf`;
  `SPAMASSASSIN_MIN_SCORE` y los límites de banda (calibración de
  decisión, mismo tipo de valor que un `*_THRESHOLD`) quedan en
  `policy.conf`. Diferencia estructural real respecto a
  `sensors/fail2ban.sh`: ese sensor no necesita leer `policy.conf`
  porque no clasifica nada, reenvía el evento crudo; este sí clasifica
  antes de reportar, así que necesita ambos archivos.
* **`SOCIAL_THRESHOLD=40`**, calibrado por criterio (sin volumen
  histórico propio para basarse, a diferencia de `ANOMALY`/`DOS`) —
  mismo nivel que `ANOMALY`, por tratarse de una señal heurística
  igual de propensa a falsos positivos (spam mal clasificado, SPF
  roto), no una confirmación binaria como `CREDENTIAL`/`DOS`.

**Implementación**

* `sensors/spamassassin.sh` — patrón polling (offset por línea,
  mismo esquema que `sensors/fail2ban.sh`), filtro dinámico contra
  `jail_profile` (mismo criterio que TASK-016), `$ARE_BIN found`
  para reportar.
* 3 `jail_profile` nuevos, categoría `SOCIAL`:
  `spamassassin-low` (10 / 0.6), `spamassassin-med` (25 / 0.75),
  `spamassassin-high` (50 / 0.9).
* Automatización: `are-spamassassin.service` + `are-spamassassin.timer`
  (systemd, cada 1 min, `After=/Requires=exim.service` en vez de
  `fail2ban.service` — dependencia adaptada a la fuente real de
  datos). Sin symlink en `PRODUCT_EXECUTABLE_LINKS` (los sensores no
  se invocan manualmente).
* Alta en `manifest/product.sh` → `PRODUCT_SYSTEMD_UNITS`.
* `policy/rules/social.sh` no requirió ningún cambio — ya existía
  desde RFC-009 con el contrato correcto, esperando que
  `SOCIAL_THRESHOLD` dejara de estar vacío.

**Bug encontrado y corregido durante la implementación**

Al crear `spamassassin-high` en ARE ADMIN, quedó con weight=25 en vez
de 50 (igual al de `spamassassin-med`), sin diferenciar la banda alta
de la media. Detectado al validar los primeros 7 eventos reales
contra la fórmula real de `handle_found()`
(`score = round(weight × confidence × 0.25)`, confirmada leyendo
`are.sh` en vez de asumida) — los 3 primeros eventos `high` dieron
score 6, idéntico al esperado para `med`. Corregido en ARE ADMIN antes
de automatizar con systemd. Los 3 eventos ya aplicados con el weight
incorrecto no se revirtieron: `SOCIAL_THRESHOLD` todavía no existía
en ese momento, no afectaron ninguna decisión real.

**Validación**

Probado en producción contra el `mainlog` real de Exim:
* `--dry-run` inicial: 7 eventos reales clasificados correctamente en
  sus 3 bandas.
* `--execute` manual: pipeline completo confirmado
  (`FOUND → Score → POLICY → APPLY`), incluida acumulación correcta
  entre eventos de la misma IP (`96.127.160.85`: dos hits de
  `spamassassin-high`, `RAW_TOTAL` 6→12).
* Automatización con systemd verificada (`systemctl list-timers`,
  `journalctl -u are-spamassassin.service`).
* `./are.sh admin` → Política → Validar: 9/9 categorías con regla
  activa (antes de este RFC, `SOCIAL` estaba en la lista pero sin
  ejercer ningún efecto real).
* Primer día completo de datos reales (2026-08-20): 1 evento
  registrado en tendencias por categoría — volumen bajo, coherente
  con la calibración conservadora elegida.

**Pendiente**

* Adaptador para otro MTA (Postfix), sin caso de uso real todavía en
  la flota.
* Recalibrar bandas/umbral con más volumen histórico una vez pase
  más tiempo (igual criterio que `ANOMALY`/`DOS` en su momento).

---

## RFC-017

**Título:** Activar/desactivar sensores desde ARE ADMIN, con registro dinámico

**Estado:** ✔ Implementada y validada en producción (Fase 1 y Fase 2 completas)

**Versión:** v2.3 (en desarrollo)

**Descripción**

Surge de una necesidad real: cuando el proyecto tenga varios sensores,
no todos los colegas que instalen ARE van a querer usarlos todos —
alguien sin SpamAssassin no debería tener ese sensor consumiendo
recursos ni generando ruido. Hoy no existe ningún mecanismo para
activar o desactivar un sensor desde ARE ADMIN; el único control es
manual, a nivel de systemd (`systemctl disable`) o, en el caso de
`apache_evasive`, comentando una línea en la configuración de Apache.

**Decisiones de diseño**

* **`jail_profile` no se toca.** `RFC-007` estableció explícitamente
  que ese modelo es agnóstico del sensor de origen — "la existencia y
  las propiedades de riesgo de un jail viven exclusivamente en
  `jail_profile`... nunca hardcodeadas dentro del código de un sensor
  particular". Mezclar el estado de un sensor ahí rompería esa
  separación intencional.
* **Registro nuevo, separado: tabla `sensor_registry`.** No una lista
  fija en el código (mismo motivo que llevó a `jail_profile` a ser
  dinámico en `TASK-016`) — un sensor nuevo, presente o futuro, se da
  de alta como fila, no como código nuevo en el menú.
* **`jail` y `sensor` son conceptos independientes, por diseño.** Un
  sensor de polling como `fail2ban.sh` alimenta muchos jails a la vez
  (`sshd`, `dovecot`, `mysqld-auth`, todos los `modsec-*`...) sin
  relación explícita en la base — la relación vive en el propio script
  del sensor (qué log lee, qué jails reporta), no en una tabla.
  Activar/desactivar es a nivel de **sensor**, no de jail individual.
* **Dos patrones de activación, según el tipo de sensor** (mismos dos
  patrones que ya distingue el Sensor Framework — polling vs callback):
  * **Polling** (`fail2ban`, `spamassassin`) — activar/desactivar es
    `systemctl enable --now` / `systemctl disable --now` sobre el
    `.timer` correspondiente. Mecanismo que ya existe, se reutiliza sin
    cambios.
  * **Callback** (`apache_evasive`) — no hay timer que tocar; Apache lo
    invoca directo vía `DOSSystemCommand`. Requiere que el propio
    script chequee un flag de estado al arrancar, y salga sin hacer
    nada si está desactivado — cambio real dentro del sensor, no solo
    en ARE ADMIN.
* **Auto-provisión de perfiles: hook opcional por sensor, no
  universal.** Solo `spamassassin.sh` necesita crear sus 3 jails
  (`spamassassin-low/med/high`) al activarse — `fail2ban`/
  `apache_evasive` no crean nada, sus jails ya se dan de alta a mano
  por el administrador. Se resuelve con una función opcional que cada
  sensor puede definir (`<sensor>_on_enable()`), no con lógica genérica
  en el registro.

**Esquema propuesto**

```sql
CREATE TABLE sensor_registry (
    name TEXT PRIMARY KEY,       -- 'fail2ban', 'spamassassin', 'apache_evasive'
    pattern TEXT NOT NULL,       -- 'polling' | 'callback'
    enabled INTEGER NOT NULL DEFAULT 1,
    systemd_timer TEXT,          -- NULL para sensores callback
    description TEXT
);
```

**Fases de implementación**

* **Fase 1 — Sensores de polling** (`fail2ban`, `spamassassin`):
  * Tabla `sensor_registry`, poblada al instalar/actualizar con los
    sensores presentes en `sensors/*.sh`.
  * `admin/sensors_menu.sh` corregido para leer dinámicamente (hoy
    tiene texto fijo, sin mención al sensor de SpamAssassin — hallazgo
    de esta sesión) y agregar opción de activar/desactivar.
  * Wrapper sobre `systemctl enable/disable --now` del timer
    correspondiente.
  * Hook `<sensor>_on_enable()` para SpamAssassin (auto-provisión de
    los 3 jails).
* **Fase 2 — Sensor de callback** (`apache_evasive`): flag de estado
  chequeado por el propio script al arrancar. Más delicado porque toca
  el sensor en sí, no solo el menú — se aborda por separado, sin
  bloquear la Fase 1.

**Pendiente de decidir antes de implementar**

**Pregunta de diseño resuelta durante la implementación**

Qué pasa con la reputación histórica al desactivar un sensor con
auto-provisión (SpamAssassin): **no hace falta tocar `jail_profile`
en absoluto.** El sensor y el jail son independientes por diseño
(`RFC-007`) — desactivar el sensor solo detiene la generación de
eventos nuevos (`systemctl disable` del timer); los `jail_profile`
existentes y toda su reputación histórica quedan intactos, sin
necesidad de ningún flag adicional. Coherente con `PHILOSOPHY.md`:
"el conocimiento no desaparece... permanece disponible para futuras
decisiones". La única condición real es que el hook de
auto-provisión (todavía no implementado) sea idempotente al
reactivar — no debe recrear ni resetear jails que ya existan.

**Fase 1 — Implementada y validada**

* `database.sh`: tabla `sensor_registry` (`name`, `pattern`,
  `enabled`, `systemd_timer`, `description`), poblada en `db_init()`
  con los 3 sensores reales. Funciones de acceso:
  `db_list_sensor_registry()`, `db_get_sensor()`,
  `db_sensor_exists()`, `db_set_sensor_enabled()`.
* `admin/sensors_menu.sh`: `sensors_status()` reescrita para leer
  `sensor_registry` dinámicamente en vez de texto fijo por sensor —
  un sensor nuevo aparece solo, sin código nuevo en este archivo.
  Nueva opción `3) Activar/Desactivar`, con `systemctl enable/disable
  --now` real sobre el timer correspondiente para sensores de
  polling. Para `apache_evasive` (callback), el toggle solo marca el
  registro y avisa explícitamente que todavía no tiene efecto real,
  a la espera de la Fase 2 — no se simula un comportamiento que no
  existe.
* `sensors_config()` recibió el bloque de SpamAssassin que le
  faltaba (hallazgo de esta sesión: nunca se había agregado, pese a
  existir desde `RFC-016`); queda estático por ahora, hacerlo
  dinámico del todo excede el alcance decidido en este RFC.

**Fase 2 — Sensor de callback (`apache_evasive`): ✔ Implementada y validada en producción**

* Flag de estado por **archivo** (`$ARE_DATA/apache_evasive.disabled`),
  no columna de `sensor_registry` consultada por `sqlite3` — decisión
  tomada por costo: este script puede invocarse con mucha frecuencia
  durante un flood real, y una consulta a la base en cada invocación
  sería cara justo en el peor momento. Mismo criterio que ya aplica
  el resto del framework (los sensores de polling ya evitan cargar
  `bootstrap.sh` completo, por la misma razón de liviandad).
* **Alcance del "desactivado" acotado deliberadamente**: solo se
  detiene el bloqueo (`ipset add`) y el reporte a ARE (`are.sh ban`).
  No se toca la configuración de Apache/`mod_evasive` en sí — eso
  sería entrar en un sistema ajeno al proyecto. En vez de bloquear
  sin avisar o quedar completamente mudo, se envía igual un email
  informativo ("actividad detectada, sin acción tomada"), evitando
  que el correo original mienta sobre un bloqueo que no ocurrió.
* **Hallazgo de higiene aprovechado en el mismo cambio**: el script
  nunca había alineado con la convención de `config.conf` que ya usan
  `fail2ban.sh`/`spamassassin.sh` desde que se movió a `sensors/` en
  `RFC-012` (cambio mínimo en ese momento, solo ruta). Ahora sourcea
  `config.conf` y usa `$ARE_DATA`/`$ARE_BIN` en vez de rutas fijas
  hardcodeadas — sin tocar nada de lo específico del mecanismo de
  notificación (emails, `BANNEDTIME`, directorio de logs de
  `mod_evasive`), fuera de alcance de este cambio.
* `admin/sensors_menu.sh`: el bloque `callback` de `sensors_toggle()`
  pasó de solo avisar a escribir/borrar el archivo flag real.

**Validación**

Probado de punta a punta con el camino de invocación real de
producción (`DOSSystemCommand "sudo /opt/are/sensors/apache_evasive.sh
%s"`, corrido como `nobody` vía `sudo` hacia `root` — confirmado con
`sudo -l -U nobody`), no con una simulación aproximada:

* Sensor deshabilitado: IP de prueba (rango `RFC 5737`) sin bloqueo
  en `ipset`, sin reputación registrada (`TOTAL=0`), email informativo
  correcto generado.
* Sensor rehabilitado: segunda IP de prueba con ban real aplicado
  (`ipset` confirma el bloqueo, `DOS=66`, `TEMP_BAN` con sanción
  vigente nivel 1) — confirma que reactivar no rompió el
  comportamiento normal.

**Auto-provisión de perfiles — ✔ Implementada**

`sensors_provision_spamassassin()` en `admin/sensors_menu.sh`, con la
lista de jails **duplicada** respecto a la semilla de
`database.sh::db_init()`, en vez de sourcear
`sensors/spamassassin.sh` para reutilizar una función ahí — esa
alternativa se evaluó y se descartó, porque el script del sensor no
está guardado tras un chequeo de ejecución directa (`BASH_SOURCE`
vs `$0`); sourcearlo ejecutaría por efecto secundario toda su lógica
de procesamiento (flock, lectura del log completo, offset) solo por
querer la función de auto-provisión. Reestructurar el sensor para
soportar ese guard era una opción, pero se descartó por tocar el
flujo de ejecución de un sensor ya validado en producción sin
necesidad real — duplicar una lista corta de 3 líneas es más seguro
que ese riesgo.

Invocada desde el bloque `polling` de `sensors_toggle()`, condicional
al sensor específico (`spamassassin`), justo antes de reactivar su
timer. Idempotente (`db_jail_profile_exists` antes de crear).

**Validación:** con los 3 jails ya existentes en producción,
deshabilitar y volver a habilitar el sensor no imprimió ningún
"Perfil creado" y no modificó `weight`/`confidence`/`decay` de
ninguno — confirmado por consulta directa a la base antes y después.

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

## IDEA-005

**Título:** Detección de compromiso de cuenta de correo (autenticación exitosa tras fuerza bruta)

Surge del análisis de `SOCIAL`/`CREDENTIAL`: un ataque de fuerza
bruta que logra autenticarse contra una cuenta de correo (IMAP/POP)
no genera ninguna señal hoy si el número de intentos fallidos no
llega a cruzar el umbral del jail de Fail2Ban correspondiente — el
caso más grave (cuenta comprometida) puede pasar invisible.

Requeriría un sensor nuevo (no extensión de `dovecot` ni de
`spamassassin.sh`) que correlacione fallos y éxitos por usuario en
una ventana corta, parseando el log crudo de dovecot. Sin datos reales
de ningún caso (ni de compromiso ni de falso positivo por typo
humano) para calibrar un umbral de intentos — no tiene sentido
diseñarlo hasta contar con evidencia real.

Además, el modelo de acción de ARE (WATCH/FILTER/TEMP_BAN/PERMANENT_BAN,
todo a nivel de IP) no resuelve este escenario: banear la IP atacante
no revoca el acceso ya obtenido a la cuenta. Requeriría una acción
nueva (alerta a admin), no solo un sensor nuevo — ARE hoy no tiene
ningún mecanismo de notificación.

Se descartó depender de cpHulk (ya implementado en este servidor
puntual vía cPanel) como sustituto: ARE no puede asumir capas de
seguridad específicas de un stack que un colega puede no tener.
cpHulk queda como IDEA aparte (IDEA-006), fuente opcional, no
requisito.

---

## IDEA-006

**Título:** Integrar cpHulk como sensor CREDENTIAL

Mismo patrón que `mod_evasive` (RFC-010): una herramienta externa que
ya defiende por su cuenta (bloqueo de fuerza bruta cross-servicio en
cPanel/WHM), reportando a ARE para sumar a reputación/decay/ban
lifecycle en vez de operar aislada. Categoría `CREDENTIAL`. Pendiente
de identificar dónde loguea cpHulk sus bloqueos (típicamente tabla
MySQL propia, no archivo plano) antes de poder diseñar el sensor.

---

## IDEA-007

**Título:** Empaquetado, distribución y auto-actualización del Installer Engine

El Installer Engine existe desde v1.1 (`install`/`upgrade`/`repair`/
`verify`/`uninstall`, completo y probado), pero la propia
documentación aclaraba explícito: "el mecanismo actual no incorpora
generación, descarga, extracción ni staging automático de paquetes
externos". Había motor de instalación, pero no paquete distribuible —
para instalar ARE en un servidor nuevo hacía falta el árbol fuente ya
copiado a mano (clonar el repo, o copiar carpeta por carpeta) antes
de poder correr `are-installer install`.

Fricción real, no hipotética: el software se está replicando a
colegas y otros servidores de la flota, y cada vez que eso pasaba,
alguien clonaba git a mano en vez de bajar un paquete de una release
y correr un instalador.

**Fase 1 — Empaquetado manual: ✔ Implementada**

* `scripts/build-package.sh` — genera un `.tar.gz` a partir de
  `PRODUCT_VERSION` y `PRODUCT_EXCLUDED` del manifiesto (reutilizados,
  sin duplicar esa lista en un segundo lugar). `VERSION` se sincroniza
  automáticamente desde `PRODUCT_VERSION` en cada build, en vez de
  mantenerse a mano — evita el tipo de desincronización encontrada y
  corregida esta misma sesión (`VERSION`/`config.conf` en 2.1.0
  mientras `PRODUCT_VERSION` ya estaba en 2.2.0).
* Probado en producción: `are-v2.2.0.tar.gz` (132K, 121 archivos),
  confirmado sin rastro de `.git`, `testing`, `tmp`,
  `database-test.sh`.
* Efecto colateral positivo: al inspeccionar el contenido del paquete
  generado, se encontraron 5 archivos placeholder vacíos en
  `sensors/` (`apache.sh`, `crowdsec.sh`, `modsecurity.sh`,
  `suricata.sh`, `zeek.sh`) que viajaban sin distinción junto a los
  sensores reales — eliminados, la intención que representaban ya
  está documentada en `ROADMAP.md`.

**Fase 2 — Automatización y distribución: ✔ Implementada**

* `.github/workflows/release-package.yml` — disparado por tag
  (`v*.*.*`), corre `build-package.sh` y publica el `.tar.gz` +
  `.sha256` como asset de la release, reutilizando el script de
  Fase 1 tal cual.
* `scripts/install.sh` — bootstrap de una línea
  (`curl ... | bash`): descarga el paquete de la última release (o
  una versión específica vía `ARE_VERSION`), verifica el checksum,
  extrae, y delega en `are-installer install`.
* Primera prueba real, con el tag `v2.2.0`: el workflow falló
  (`release not found`) porque `gh release upload` requiere que la
  Release ya exista — nunca se había creado una manualmente antes de
  taggear. Corregido en `BUG-024`: el workflow ahora crea la Release
  si no existe, en el mismo paso.

**Fase 3 — Auto-actualización estilo repositorio de paquetes**

Inspirado en el patrón de `apt`/`yum`/`dnf`.

* **`are-installer check-updates` — ✔ Implementada.** Solo lectura,
  sin root: consulta la API de GitHub (`/releases/latest`), compara
  contra `PRODUCT_VERSION` (leído del propio manifiesto de la
  instalación activa — no hizo falta ningún mecanismo nuevo de
  "versión instalada", `PRODUCT_VERSION` ya lo es en el momento en
  que corre el comando) usando `sort -V` para orden semántico, e
  informa si hay una versión más reciente sin tocar nada del sistema.
* **`are-installer upgrade --remote` — ✔ Implementada.** Wrapper
  delgado en `are-installer` que delega en `scripts/install.sh
  upgrade` (Fase 2) — sin duplicar la lógica de descarga/checksum/
  extracción, coherente con "reutilización antes que duplicación".
  Requirió agregar `scripts` a `PRODUCT_DIRS` en el manifiesto (no
  estaba, así que `install.sh` nunca se copiaba a una instalación
  real, solo vivía en el repo fuente). Validado en producción real
  tras corregir `BUG-025` (`/tmp` con `noexec` rompía la extracción).
  **Gap conocido, no bloqueante:** el comando no compara versión
  antes de aplicar — baja o sube el código a lo que sea la última
  release publicada, sin verificar contra `PRODUCT_VERSION` local
  (a diferencia de `check-updates`, que sí compara). Corrido en una
  rama de desarrollo más nueva que la última release, esto downgradea
  el código sin aviso — comportamiento observado y confirmado durante
  la validación (ver `BUG-025`). Quedaría como mejora natural
  encadenar `check-updates` antes de `upgrade --remote` y pedir
  confirmación si la versión instalada ya es igual o más nueva.

Coherente con "reutilización antes que duplicación" en las tres
fases: ningún cambio al núcleo del Installer Engine, solo las piezas
que faltan para que deje de depender de que alguien clone el repo a
mano, y eventualmente para que el propio sistema se entere solo de
que hay una versión nueva.

---

## IDEA-008

**Título:** Detección de anomalías en tendencias

**Estado:** ✔ Implementada y validada en producción

**Versión:** v2.3 (en desarrollo)

Extensión directa de RFC-013 (desglose de tendencias por categoría).
La noche de implementación de RFC-016 se encontraron dos anomalías
reales revisando la tabla a mano (`EXPLOIT=1461` el 15 de agosto,
`CREDENTIAL=3332` el 20 de agosto) — ambas visibles solo porque un
humano estaba mirando la tabla en ese momento. Sin esa revisión
activa, ninguna de las dos se hubiera notado.

**Implementación**

* `dashboard/trends.sh` — `dashboard_trends_anomalies(dias)`: para
  cada una de las 9 categorías, compara el conteo de eventos de
  **hoy** contra el promedio de los `dias` días previos (sin incluir
  hoy). Marca con `⚠` cuando hoy es al menos 3 veces ese promedio,
  con un piso mínimo (`hoy >= 10`) para no marcar ruido cuando los
  números son chicos. Mismo patrón de `JOIN` contra `jail_profile`
  que ya usa `dashboard_trends_by_category()` (RFC-016) — sin
  instrumentación nueva, reutiliza `events` tal cual.
* `admin/state_menu.sh` — opción `8) Anomalías en tendencias` en la
  rama Estado/Reputación, mismo patrón que las opciones 5-7
  (pedir días, validar, wrapper, `admin_pause`).

**Por qué encaja con los principios ya establecidos del proyecto**

* No inventa ningún valor de riesgo — es puramente estadístico
  (promedio sobre datos ya existentes), no toca `policy.conf` ni el
  modelo de decisión.
* Reutiliza datos existentes — la tabla `events` y el patrón de
  consulta ya escrito en `dashboard_trends_by_category()` (RFC-016).
* Es observabilidad, no automatización de bloqueo — no banea nada,
  no cambia comportamiento del sistema, solo hace visible algo que
  ya estaba en los datos.
* Da una primera forma concreta a `IDEA-004` (Dashboard avanzado),
  que hoy es solo una intención general.

**Validación**

Corrida en producción el día en que los números estaban dentro de lo
normal — "sin anomalías detectadas", correcto. Validada por cálculo
contra el caso histórico conocido: con el pico real de
`CREDENTIAL=3332` del 2026-08-20 (promedio de los días previos
visibles ~71), la función lo habría marcado sin dudas de haber
corrido ese día — más de 46 veces el promedio, muy por encima del
umbral `3×`. Limitación de diseño reconocida: es un chequeo del día
actual, no una auditoría retroactiva — no puede señalar anomalías de
días pasados si se corre después de que ya ocurrieron.

**Archivos relacionados**

* `dashboard/trends.sh`
* `admin/state_menu.sh`

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

## BUG-002

**Título:** Verificar sincronización Backend ↔ Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v2.2 (cierre de una observación abierta desde v1.x)

**Descripción original**

Continuar validando durante la operación en producción que todas las
acciones generadas por Fail2Ban sean procesadas correctamente por
ARE — garantizar que la transición entre los eventos generados por
Fail2Ban y las decisiones ejecutadas por ARE permanezca sincronizada.

**Validación**

Cerrado con evidencia acumulada de múltiples sesiones de producción,
confirmada de forma extensiva durante la implementación de RFC-016:
decenas de eventos reales de distintos jails de Fail2Ban
(`modsec-bruteforce`, `modsec-scanner`, `modsec-bots`, `recidive`,
`modsec-protocol`, `modsec-anomaly`) procesados correctamente de
punta a punta (`FOUND → Score → POLICY → APPLY`), incluyendo un caso
de correlación multi-categoría sobre una misma IP
(`216.180.246.162`) y acumulación correcta entre eventos repetidos
(`96.127.160.85`). Sin ningún caso de desincronización detectado en
ninguna de las revisiones.

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

## BUG-014

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

## BUG-021

**Título:** Consulta de filtro dinámico en `sensors/fail2ban.sh` sin manejo de bloqueo de SQLite

**Estado:** ✔ Resuelto

**Versión:** v2.1 (en desarrollo)

**Problema**

La consulta de filtro dinámico agregada en TASK-016
(`SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL'`) usaba
`sqlite3` directo, sin timeout de espera ante bloqueo (`database is
locked`) ni blindaje contra respuesta vacía. Al correr manualmente
`./sensors/fail2ban.sh --dry-run` mientras el timer automático
(`are-fail2ban-found.timer`) escribía simultáneamente en la misma
base, la consulta fallaba con `Error: database is locked`, y el
`$PROFILE_EXISTS` vacío resultante rompía la comparación
`[ "$PROFILE_EXISTS" -eq 0 ]` con `integer expression expected`.

**Impacto**

Cada choque de concurrencia hacía que la línea de log en curso se
descartara sin procesar — en el peor caso, durante una ráfaga de
eventos reales de una IP atacante, varios de esos eventos podrían no
sumar a su reputación.

**Detección**

Encontrado al correr manualmente el sensor en `--dry-run` para probar
el jail nuevo `courier-auth`, mientras el timer automático procesaba
en paralelo eventos reales de otra IP (`195.178.110.223`, ya
bloqueada correctamente por el flujo normal — el hallazgo fue
específicamente sobre la ejecución manual concurrente, no sobre un
fallo del bloqueo en sí).

**Corrección**

```bash
PROFILE_EXISTS=$(sqlite3 -cmd ".timeout 3000" "$DB_FILE" "SELECT COUNT(*) FROM jail_profile WHERE name='$JAIL';" 2>/dev/null)
PROFILE_EXISTS="${PROFILE_EXISTS:-0}"
```

`.timeout 3000` espera hasta 3 segundos si la base está bloqueada por
otro proceso, en vez de fallar de inmediato. El blindaje
`${PROFILE_EXISTS:-0}` evita que una respuesta vacía rompa la
comparación entera posterior.

**Recomendación operativa**

Para pruebas manuales del sensor, detener el timer automático antes
de correr `--dry-run`/`--execute` manualmente
(`systemctl stop are-fail2ban-found.timer`), evitando el choque de
raíz además del fix de timeout.

**Archivos relacionados**

* `sensors/fail2ban.sh`

---

## BUG-022

**Título:** `db_exec()` sin manejo de bloqueo de SQLite — punto único de fallo de todo el sistema

**Estado:** ✔ Resuelto

**Versión:** v2.1 (en desarrollo)

**Problema**

`db_exec()`, la función central que ejecuta prácticamente cada
lectura y escritura de ARE, invocaba `sqlite3` sin `.timeout`:

```bash
RESULT=$(sqlite3 -batch "$DB_FILE" "$SQL" 2>/dev/null)
```

Idéntico patrón al identificado y corregido en BUG-021, pero en el
punto del que dependen todas las demás funciones del sistema
(`handle_ban`, `handle_found`, `db_add_score`,
`db_recalculate_total`, auditoría, decay, restauración de ipset al
arrancar), no una consulta puntual.

**Impacto**

Cualquier choque de escrituras concurrentes contra la base —
especialmente probable durante un ataque real, cuando múltiples
eventos llegan en rápida sucesión (ver el ataque de
`195.178.110.223` que motivó el hallazgo de BUG-021) — podía hacer
que `sqlite3` fallara con `database is locked` en cualquier punto del
sistema, no solo en el sensor.

**Verificación de que el error no se perdía en un segundo nivel**

Se confirmó que `db_error()`, invocada cuando `sqlite3` retorna
código de error distinto de cero, sí registra el problema
correctamente vía `ERROR()` — el punto ciego era exclusivamente la
ausencia de `.timeout`, no un segundo nivel de silenciamiento.

**Corrección**

```bash
RESULT=$(sqlite3 -batch -cmd ".timeout 3000" "$DB_FILE" "$SQL" 2>/dev/null)
```

Mismo timeout de 3 segundos que BUG-021, aplicado en el punto único
del que dependen todas las funciones de `database.sh`.

**Validación**

Reproducido un escenario de 5 escrituras concurrentes reales
(`db_add_score` en paralelo, mismo instante, contra la misma base):
las 5 se aplicaron correctamente, sin ningún error de bloqueo.

**Archivos relacionados**

* `database.sh` (`db_exec`)

---

## BUG-023

**Título:** `PRODUCT_EXECUTABLE_FILES` incompleto tras RFC-016 — sensores nuevos sin permiso de ejecución en instalación limpia

**Estado:** ✔ Resuelto

**Versión:** v2.2 (en desarrollo)

**Problema**

El commit de RFC-016 agregó `sensors/spamassassin.sh` y las unidades
systemd correspondientes, pero no actualizó
`manifest/product.sh::PRODUCT_EXECUTABLE_FILES`. `sensors/` ya estaba
declarado en `PRODUCT_DIRS` (copia automática de directorio completo),
pero eso solo copia los archivos — los permisos de ejecución se
asignan aparte, únicamente a lo listado en
`PRODUCT_EXECUTABLE_FILES`. `sensors/apache_evasive.sh` tampoco
estaba, desde antes de RFC-016.

**Impacto**

En una instalación nueva o un `upgrade`, `install_permissions()`
aplica `chmod 0644` a todos los archivos y solo despliega `0755`
sobre los declarados en `PRODUCT_EXECUTABLE_FILES`. Sin la entrada,
`spamassassin.sh` y `apache_evasive.sh` quedarían copiados pero sin
permiso de ejecución — falla silenciosa: el timer de systemd
fallaría (`Permission denied`) sin ningún error visible durante la
instalación misma. Detectado antes de que afectara a ningún colega,
al correr `are-installer verify` de forma preventiva en este
servidor.

**Corrección**

Se agregaron las dos entradas faltantes a `PRODUCT_EXECUTABLE_FILES`:

```bash
PRODUCT_EXECUTABLE_FILES=(
    are-installer
    are.sh
    sensors/fail2ban.sh
    sensors/apache_evasive.sh
    sensors/spamassassin.sh
)
```

**Validación**

```bash
bash -n manifest/product.sh
./are-installer verify
```

`are-installer verify` confirmado limpio: 11/11 checks en OK
(Integridad, Enlaces, Comandos oficiales, Permisos, Base de datos,
IPSet, Firewall, Systemd, Logrotate, Runtime).

**Archivos relacionados**

* `manifest/product.sh`

---

## BUG-024

**Título:** Workflow de release fallaba si la Release de GitHub no existía

**Estado:** ✔ Resuelto

**Versión:** v2.3 (en desarrollo)

**Problema**

`gh release upload` (usado en `.github/workflows/release-package.yml`,
IDEA-007 Fase 2) requiere que la Release ya exista en GitHub — solo
sube assets a algo creado previamente, no crea nada. El primer disparo
real del workflow, con el tag `v2.2.0`, falló con `release not found`:
nunca se había creado una Release manualmente antes de ese tag.

**Corrección**

El paso final del workflow ahora verifica primero si la Release
existe (`gh release view`); si existe, sube los assets como antes
(`--clobber`); si no, la crea con `gh release create` en el mismo
paso, con los assets adjuntos directamente en la creación.

**Validación**

Confirmado en producción: el primer intento con `v2.2.0` falló
exactamente como se documenta arriba; con la Release creada a mano
como corrección puntual, `Re-run failed jobs` completó los 4 pasos
sin error, con ambos assets (`.tar.gz` + `.sha256`) visibles en la
Release. Esta corrección elimina la dependencia del paso manual para
cualquier tag futuro.

**Archivos relacionados**

* `.github/workflows/release-package.yml`

---

## BUG-025

**Título:** `scripts/install.sh` fallaba en servidores con `/tmp` montado `noexec`

**Estado:** ✔ Resuelto

**Versión:** v2.3 (en desarrollo)

**Problema**

`WORK_DIR="$(mktemp -d)"` usa el directorio temporal por defecto del
sistema (`/tmp`). En este servidor, `/tmp` y `/var/tmp` están
montados con la opción `noexec` (hardening estándar, común en
entornos cPanel — confirmado con `mount | grep -i tmp`, mismo
dispositivo `/usr/tmpDSK` montado en ambos puntos). El paquete
descargado y extraído ahí tenía el bit de ejecución correcto
(`-rwxr-xr-x`, confirmado con `ls -la` y por extracción manual), pero
el punto de montaje bloquea la ejecución de todos modos, a nivel de
kernel, sin importar los permisos del archivo — el chequeo
`[ -x "./are-installer" ]` daba falso, con el mensaje "are-installer
no encontrado o sin permiso de ejecución", que llevaba a sospechar
del paquete cuando el paquete estaba bien.

**Diagnóstico**

Confirmado con `bash -x` sobre el script real y con extracción manual
paso a paso en un `mktemp -d` sin el `trap cleanup` que borra la
evidencia — mismo `.tar.gz`, mismo checksum verificado en ambos
casos, resultado distinto según el punto de montaje del directorio de
trabajo.

**Corrección**

`WORK_DIR` movido de `/tmp` a `/root` (el `$HOME` de root, que el
script ya exige como usuario obligatorio) — sin restricción `noexec`
en la evidencia disponible, y consistente con que `upgrade`/`install`
ya requieren privilegios de root de todos modos.

```bash
WORK_DIR="$(mktemp -d /root/.are-install.XXXXXX)"
```

Se evaluó `/opt` como alternativa antes de decidir `/root` — se
descartó por convención: `/opt` está reservado para software
instalado de forma permanente (el propio `/opt/are` cumple ese rol),
no para directorios de trabajo transitorios.

**Validación**

Confirmado en producción real: `are-installer upgrade --remote`
completó los 30+ pasos de `installer_upgrade()` sin error
(descarga, checksum, extracción, copia de Core, configuración,
enlaces, permisos, base de datos, systemd, logrotate, validación
final — `are-installer verify` 11/11 en OK después).

Efecto colateral de la prueba, no relacionado con el bug en sí: al
correr `upgrade --remote` con la única release publicada (`v2.2.0`)
estando en una rama de desarrollo más nueva (`v2.3-dev`), el comando
sobrescribió el código local sin comparar versiones — comportamiento
esperado del diseño actual (no compara, solo aplica lo último
publicado), pero sin aviso previo del riesgo antes de ejecutarlo en
el servidor de producción real, en vez de en un entorno aislado.
Recuperado sin pérdida de datos (`git checkout -- .`, con `events` y
`jail_profile` verificados intactos en la base — ni `install_copy_files`
ni `install_database` tocan datos persistentes). Queda como lección
de proceso: cualquier prueba de `upgrade --remote` en este servidor
debe advertirse explícitamente como "toca el código real de
producción" antes de ejecutarla.

**Archivos relacionados**

* `scripts/install.sh`

---

## BUG-026

**Título:** `sensors/spamassassin.sh` sin protección contra corridas solapadas — reprocesamiento duplicado del log

**Estado:** ✔ Resuelto

**Versión:** v2.3 (en desarrollo)

**Problema**

El sensor no tenía ningún mecanismo de bloqueo (`flock`) entre lectura
del offset, procesamiento del log, y escritura del nuevo offset. Si
dos instancias corrían solapadas — el timer de systemd (cada 60s) en
paralelo con una corrida manual, o el archivo de offset tocado a mano
mientras el timer seguía activo, como ocurrió durante una sesión de
diagnóstico de esta misma noche — ambas instancias podían leer el
mismo offset viejo, procesar el mismo tramo del log dos o más veces,
y generar eventos `FOUND` duplicados con la fecha de cada corrida
extra, no la fecha real del evento original.

**Impacto real confirmado en producción**

`96.127.160.85` (dos eventos reales legítimos, del 16 y 17 de agosto)
terminó con `SOCIAL=78` en vez de `22` — 6 eventos duplicados de una
misma corrida solapada, sumados encima de los 2 reales. La reputación
inflada disparó una decisión `TEMP_BAN` real, aplicada al firewall
sobre datos falsos — ver `BUG-027` para la segunda mitad del
problema (por qué el `unban` posterior no revirtió esa sanción de
forma persistente).

**Corrección**

`flock` no bloqueante sobre un archivo de lock dedicado
(`$ARE_DATA/spamassassin.lock`), envolviendo la lectura del offset,
el procesamiento del log, y la escritura del offset nuevo. Si otra
instancia ya tiene el lock, la corrida nueva se cierra sin hacer
nada, en vez de leer un offset que la otra instancia todavía no
terminó de escribir. Aplica tanto a `--execute` como `--dry-run`,
para que un diagnóstico manual no pueda corromper el estado de una
corrida real en curso.

**Validación**

Reprocesamiento completo del historial (`offset=0`,
`sensors/spamassassin.sh --execute`) tras la corrección: 8 eventos
reales procesados, cero duplicados — coincide exacto con el conteo
manual de líneas `Warning` reales del log completo.

**Archivos relacionados**

* `sensors/spamassassin.sh`

---

## BUG-027

**Título:** `handle_unban()` no persiste el unban en `sanction_state`

**Estado:** ✔ Resuelto

**Versión:** v2.3 (en desarrollo)

**Problema**

`handle_unban()` en `are.sh` quita la IP de los conjuntos `ipset`
(`ban_set`, `filter_set`) y registra el evento `UNBAN` en `events`,
pero nunca llama a `db_register_sanction_unban()` — la función que
existe en `database.sh` para exactamente este propósito
(`ban_until=0`, `last_unban=NOW`). La fila de `sanction_state` queda
exactamente igual que antes del unban.

**Impacto**

El unban funciona en caliente (la IP sale del firewall real de
inmediato), pero la persistencia miente: `sanction_state` sigue
diciendo que hay una sanción vigente hasta una fecha futura.
`are-restore-ipsets.service`, que repuebla el firewall al arrancar el
sistema a partir de `sanction_state` (no de un snapshot del firewall
en sí — ver `BAN_LIFECYCLE.md`), volvería a aplicar el ban ya
revertido si el servidor se reinicia antes de que esa fecha pase.
Encontrado al revertir el ban falso generado por `BUG-026`: el
`unban` reportó éxito, pero `sanction_state` seguía mostrando
`last_unban=0` y `ban_until` sin cambios.

**Corrección**

Una línea agregada a `handle_unban()`, antes del registro del evento:

```bash
db_register_sanction_unban "$ip"
```

**Validación**

Confirmado en producción con `96.127.160.85`: antes de la corrección,
`sanction_state` mostraba `ban_until=1787372819, last_unban=0` pese a
un `unban` ya ejecutado. Tras la corrección y un segundo `unban`,
`ban_until=0, last_unban=1787440100` (timestamp real) — persistencia
ahora consistente con el estado real del firewall.

**Archivos relacionados**

* `are.sh`

---

## BUG-028

**Título:** `sensors/spamassassin.sh` descartaba mensajes con score alto clasificados "NOT spam" por SpamAssassin

**Estado:** ✔ Resuelto

**Versión:** v2.3 (en desarrollo)

**Problema**

El sensor filtraba exclusivamente por el veredicto textual de
SpamAssassin (`"detected message as spam ("`), delegando en el
criterio interno de esa herramienta en vez de decidir por score
propio contra `SPAMASSASSIN_MIN_SCORE`. Encontrado en producción: un
mensaje real con score `6.2` (por encima de
`SPAMASSASSIN_MIN_SCORE=5.0`) fue clasificado internamente por
SpamAssassin como "NOT spam", pese a que el propio servidor de
correo igual rechazó la entrega del mensaje — dos criterios internos
de SpamAssassin/Exim desalineados entre sí (probablemente
`required_score` interno de SpamAssassin más alto que el umbral real
de rechazo de Exim), ninguno de los cuales ARE debía heredar
ciegamente.

**Decisión de diseño**

ARE es un motor de riesgo propio — no delega su criterio de
clasificación en el flag booleano interno de otra herramienta. El
sensor ahora captura ambos veredictos (`"spam"` y `"NOT spam"`) y
extrae el score de cualquiera de los dos; la decisión de si cuenta
como evento real queda 100% del lado del propio pipeline de ARE
(`SPAMASSASSIN_MIN_SCORE`, ya existente), no del texto del log.

**Corrección**

```bash
case "$line" in
    *"detected message as spam ("*|*"detected message as NOT spam ("*)
        score=$(echo "$line" | grep -oP 'message as (NOT )?spam \(\K[0-9.\-]+(?=\))')
        ...
```

La línea de rechazo genérico de Exim (`"rejected after DATA"`) sigue
correctamente excluida — no tiene un score entre paréntesis inmediato
después de "spam", el patrón no la matchea.

**Incidente durante la corrección**

Al resetear el offset a `0` antes de copiar el archivo corregido, el
timer automático (todavía con el código viejo) procesó el backlog
completo en esa ventana, descartando de nuevo el evento que estábamos
corrigiendo. Y una segunda prueba, con el archivo ya corregido pero
sin detener el timer primero, generó duplicados reales (mismo patrón
de fondo que `BUG-026`, pese al `flock` — el `flock` protege contra
corridas *simultáneas*, no contra que el timer normal consuma un
offset reseteado a mano entre pruebas manuales). Ambos incidentes
llevaron a un tercer y definitivo reprocesamiento completo del
historial (`DELETE` de todos los eventos `spamassassin-*`, offset a
`0`, timer detenido explícitamente durante todo el proceso).

**Lección de proceso, reforzando `BUG-026`:** cualquier manipulación
manual del offset de este sensor debe hacerse con el timer detenido
(`systemctl stop are-spamassassin.timer`) desde el primer paso, no
solo cuando se anticipa un choque directo — el timer corriendo cada
60 segundos es suficiente para interferir con cualquier ventana de
prueba, aunque nunca coincida literalmente en el mismo segundo que la
corrida manual.

**Validación**

Reprocesamiento final limpio: 12 eventos totales, sin duplicados
(`96.127.160.85` con 2 filas son sus dos eventos reales legítimos,
no un error). Confirmado con consulta directa
(`GROUP BY ip, jail HAVING COUNT(*) > 1` devuelve únicamente esa fila
esperada). El mensaje que originó el hallazgo (`103.16.72.108`,
score `6.2`) confirmado presente, clasificado `spamassassin-low`.

**Archivos relacionados**

* `sensors/spamassassin.sh`

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
v2.2.0
```

La versión v2.3 se encuentra en desarrollo activo.

El trabajo futuro deberá incorporarse al Roadmap antes de convertirse en una línea formal de desarrollo.
