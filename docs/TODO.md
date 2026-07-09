# ARE TODO

Este documento mantiene el registro de trabajo activo del proyecto.

Se divide en:

- Bugs
- Tasks
- Features
- RFC
- Ideas

---

# BUGS

## BUG-001

**Título:** Implementar `handle_unban()`

**Estado:** ✔ Resuelto

**Versión:** v1.0.1

---

## BUG-002

**Título:** Verificar sincronización Backend ↔ Fail2Ban

**Estado:** En observación

**Prioridad:** Media

**Descripción**

Continuar validando durante operación en producción que todas las acciones generadas por Fail2Ban sean procesadas correctamente por ARE.

---

## BUG-005

**Título:** Inicialización duplicada del backend

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Descripción**

Se eliminó la doble inicialización de IPSet y Firewall centralizando el proceso en `backend/init.sh`.

---

## BUG-006

**Título:** La categoría ANOMALY no se refleja en las estadísticas

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Media

**Descripción**

La categoría ANOMALY ya es utilizada por el Policy Engine y los perfiles de jail, pero actualmente no existe dentro del modelo de reputación persistente (`reputation`).

Como consecuencia, el Dashboard no puede mostrar estadísticas correctas de dicha categoría.

**Impacto**

- Dashboard incompleto.
- Estadísticas inconsistentes.
- Categorías del motor y del Dashboard no coinciden.

**Validación**

- `stats` muestra `Anomaly`.
- `score <ip>` muestra `Anomaly`.
- `FOUND modsec-anomaly` suma correctamente al total.

---

## BUG-007

**Título:** ARE no procesa correctamente eventos BAN/UNBAN provenientes de Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Descripción**

Se detectó que ARE procesa correctamente eventos `FOUND` mediante el sensor Fail2Ban, pero algunos eventos `BAN` y `UNBAN` generados por Fail2Ban no quedan registrados en el historial de ARE.

**Evidencia**

Fail2Ban registra eventos `Unban`, pero al consultar `events <IP>` no aparece información asociada en ARE.

**Impacto**

- El ciclo completo `FOUND → BAN → UNBAN` puede quedar incompleto.
- El historial de reputación puede no reflejar correctamente la actividad real.
- ARE depende parcialmente de que la acción directa de Fail2Ban ejecute correctamente `ban/unban`.

**Hipótesis inicial**

Actualmente existe un sensor para eventos `FOUND`, pero no existe un sensor equivalente para eventos `BAN` y `UNBAN` leídos desde el log de Fail2Ban.

**Archivos relacionados**

- `sensors/fail2ban_found.sh`
- `/etc/fail2ban/action.d/ipset-smart.conf`
- `f2b-ipset.sh`
- `database.sh`

**Validación**

- El sensor Fail2Ban unificado procesa eventos `FOUND`.
- El sensor Fail2Ban unificado procesa eventos `UNBAN`.
- Los eventos `UNBAN` externos se registran como `EXTERNAL_UNBAN`.
- `EXTERNAL_UNBAN` no libera directamente la IP.
- ARE reevalúa la IP mediante el Policy Engine.
- Validado en producción con IP `103.59.161.151`

---

## BUG-008

**Título:** Incoherencia entre State Engine y Policy Engine para estado FILTER

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Descripción**

Durante la ejecución del Decay Engine se detectó que algunas IP quedan con `STATUS=NEW`, pero el Policy Engine devuelve `FILTER` como decisión para `LOW_RISK`.

**Evidencia**

```text
SCORE=23->21 STATUS=NEW POLICY=FILTER REASON=LOW_RISK
```

**Validación**

- Se corrigió `state_update()` para reconocer `FILTER`.
- El Decay Engine ya no muestra incoherencias `STATUS=NEW POLICY=FILTER`.
- Validado con `decay-apply`.

---

# TASKS

## TASK-001

**Título:** Reorganizar reglas del Policy Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Descripción**

Las reglas fueron movidas al módulo:

```
policy/rules/
```

---

## TASK-002

**Título:** Cursor persistente para sensores

**Estado:** OPEN

**Prioridad:** Alta

**Descripción**

Implementar un mecanismo persistente de offset para evitar reprocesar eventos ya leídos desde los logs.

---

## TASK-003

**Título:** Automatizar ejecución del Fail2Ban Sensor

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Descripción**

Se creó un `systemd service` y un `systemd timer` para ejecutar automáticamente el sensor Fail2Ban FOUND cada minuto.

---

## TASK-004

**Título:** Agregar estadísticas por jail

**Estado:** OPEN

**Versión:** v1.1-dev

**Descripción**

Evaluar una sección adicional en `stats` para mostrar actividad por jail, por ejemplo:

- recidive
- sshd
- modsec-rce
- modsec-protocol
- modsec-bruteforce

Esto debe calcularse desde la tabla `events`, no desde `reputation`

---

## TASK-005

**Título:** Ampliar categorías del Reputation Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Objetivo**

Expandir el modelo de reputación para soportar categorías adicionales de amenazas.

**Categorías objetivo**

- ANOMALY
- MALWARE
- DOS
- SOCIAL

**Alcance inicial**

Implementar primero `ANOMALY` de punta a punta:

- Base de datos.
- `database.sh`.
- `dashboard/stats.sh`.
- `dashboard/score.sh`.

**Validación**

- Nuevas columnas agregadas a `reputation`.
- `ANOMALY`, `MALWARE`, `DOS` y `SOCIAL` integradas al modelo.
- `stats` muestra todas las categorías.
- `score <ip>` muestra todas las categorías.
- `total_score` incluye todas las categorías.

**Nota**

Los jails seguirán mapeándose mediante `jail_profile` hacia una categoría de reputación. No se crearán columnas específicas por jail.

---

## TASK-006

**Título:** Incorporar perfiles de reputación para sshd, telnet y recidive

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Descripción**

Agregar perfiles de reputación para jails críticos que actualmente pueden ser observados por ARE pero no poseen una valoración específica dentro del modelo de riesgo.

**Jails objetivo**

- sshd
- telnet
- recidive

**Objetivo**

Permitir que ARE asigne score a eventos relacionados con accesos reiterados, intentos contra servicios remotos y reincidencia.

**Categorías propuestas**

- sshd → CREDENTIAL
- telnet → CREDENTIAL
- recidive → EXPLOIT

**Nota**

Esta tarea no implementa todavía decisiones autónomas de ban temporal, ban permanente ni descenso de score. Esos puntos permanecen separados como RFC.

**Validación**

- `sshd` agregado como perfil `CREDENTIAL`.
- `telnet` agregado como perfil `CREDENTIAL`.
- `recidive` validado como perfil existente `EXPLOIT`.
- Sensor Fail2Ban permite `sshd` y `telnet`.
- `FOUND sshd` suma score correctamente.
- `FOUND telnet` suma score correctamente.

---

## TASK-007

**Título:** Mejorar Dashboard de Reputación con información temporal

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Media

**Objetivo**

Mejorar la salida del comando `score` para mostrar información temporal legible sobre la reputación de una IP.

**Situación actual**

El dashboard muestra `updated` como timestamp Unix:

```text
Última actualización.. 1783530687

```

**Validación**

- `score` muestra fecha legible de última actividad.
- `score` muestra antigüedad relativa.
- Se reemplazó el timestamp Unix por información útil para administración.

---

## TASK-008

**Título:** Controlar frecuencia de ejecución del Decay Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Descripción**

Actualmente `decay-apply` utiliza `updated` para identificar IPs sin actividad reciente. Sin embargo, `updated` representa la última actividad maliciosa y no la última ejecución de decay.

Esto permite que, si `decay-apply` se ejecuta varias veces en el mismo período, una IP pueda recibir múltiples reducciones de score sin que haya transcurrido una nueva ventana de recuperación.

**Objetivo**

Evitar aplicar decay más de una vez dentro del mismo intervalo definido.

**Solución propuesta**

Agregar un campo independiente para controlar la última ejecución de decay:

```text
last_decay
```

**Validación**

- Se agregó `last_decay` a la tabla `reputation`.
- `db_init()` crea `last_decay` en instalaciones nuevas.
- `decay-dry-run` respeta `last_decay`.
- `decay-apply` actualiza `last_decay`.
- Se evita aplicar decay múltiples veces dentro de la misma ventana.
- Validado con 487 IPs procesadas y segunda ejecución sin candidatas.

---

## TASK-009

**Título:** Consolidar el módulo Policy

**Estado:** IN PROGRESS

**Versión:** v1.1-dev

**Prioridad:** Media

**Objetivo**

Mover progresivamente los archivos `policy*.sh` ubicados en la raíz hacia el directorio `policy/`, sin modificar lógica funcional.

**Fase actual**

Mover `policy_apply.sh` hacia `policy/apply.sh`.

**Regla**

Cada fase debe validar que ARE continúa funcionando antes de continuar con el siguiente archivo.

**Fase 1:** ✔ Resuelta

**Validación**

- `policy_apply.sh` movido a `policy/apply.sh`.
- `bootstrap.sh` actualizado.
- Se agregó wrapper `apply_decision()` para mantener compatibilidad.
- Validado con `top`.
- Validado con `found modsec-protocol`.

**Fase 2:** ✔ Resuelta

**Validación**

- `policy_context.sh` movido a `policy/context.sh`.
- `policy_context_api.sh` movido a `policy/context_api.sh`.
- `bootstrap.sh` actualizado.
- Referencia antigua corregida en `policy/rules/anomaly.sh`.
- Validado con `top`.
- Validado con `found modsec-protocol`.

---

# FEATURES

## FEAT-001

**Estado:** ✔ Operativo en producción

**Implementado**

- Evento FOUND.
- Sensor Fail2Ban.
- Cursor persistente.
- Modo `--dry-run`.
- Modo `--execute`.
- Ejecución automática mediante systemd timer.
- Registro en SQLite.
- Integración con Policy Engine.
- Validación en producción.

**Pendiente**

- Limpieza final del sensor.
- Mover configuración fija a `config.conf`.

---

## FEAT-003

**Título:** Mostrar TOP JAILS en `stats`

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Validación**

- `stats` muestra TOP JAILS.
- Se excluyen eventos internos como `fail2ban` y `policy_apply`.
- La información se obtiene desde la tabla `events`.

**Prioridad:** Media

**Objetivo**

Mostrar en el dashboard estadístico cuáles jails generan mayor actividad.

**Fuente de datos**

Tabla `events`.

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

**Estado:** ✔ Resuelto - Recuperación controlada inicial

**Versión:** v1.1-dev

**Prioridad:** Alta

**Objetivo**

Implementar un mecanismo de reducción gradual del score de reputación para IPs sin actividad reciente.

**Reglas iniciales**

- Aplicar decay solo a IPs sin actividad durante al menos 24 horas.
- Usar un factor inicial de reducción de `0.95`.
- Recalcular `total_score` después de aplicar decay.
- Reevaluar la IP mediante el Policy Engine.
- No borrar reputación de golpe.

**Parámetros iniciales**

- `DECAY_MIN_AGE=86400`
- `DECAY_FACTOR=0.95`

- `decay-dry-run`: muestra IPs candidatas y score estimado.
- `decay-apply`: aplica reducción real de score y simula la decisión del Policy Engine.
- El Decay Engine todavía no ejecuta cambios sobre firewall.

**Validación actual**

- Score reducido correctamente.
- State Engine actualizado.
- Policy Engine evaluado.
- No se ejecuta `apply_decision()` desde decay.
- `stats` muestra cantidad de IPs candidatas a decay.
- `decay-dry-run` muestra IPs candidatas.
- `decay-dry-run` calcula score estimado.
- `decay-apply` reduce score real.
- `decay-apply` actualiza `last_decay`.
- `decay-apply` reevalúa State Engine.
- `decay-apply` simula Policy Engine.
- No ejecuta cambios sobre firewall.
- Se evita aplicar decay múltiples veces dentro de la misma ventana.
- Validado en producción con 487 IPs procesadas.
- La recuperación por decay solo ejecuta liberación cuando el Policy Engine devuelve `ALLOW`.
- `WATCH`, `FILTER`, `TEMP_BAN` y `BAN` no generan liberación automática.

**Siguiente etapa**

Activar aplicación controlada de decisiones generadas por el Decay Engine.

Cuando una IP reduzca su score y el Policy Engine determine `ALLOW`, `WATCH` o `FILTER`, ARE podrá removerla de `are-blacklist` si ya no corresponde mantener bloqueo activo.

Esta etapa completa el ciclo inicial de recuperación de reputación y permite que ARE controle tanto el bloqueo como la liberación de una IP.

**Validación final**

- `decay-dry-run` muestra candidatas sin modificar datos.
- `decay-apply` reduce score real.
- `last_decay` evita múltiples reducciones dentro de la misma ventana.
- Se reevalúa State Engine después del decay.
- Se reevalúa Policy Engine después del decay.
- Solo `ALLOW` ejecuta recuperación/liberación.
- `WATCH`, `FILTER`, `TEMP_BAN` y `BAN` no liberan IP automáticamente.
- Validado en producción.

---

# RFC

## RFC-001

**Título:** Renombrar CLI oficial a `are`

**Estado:** Draft

**Versión objetivo:** v1.1

---

## RFC-002

**Título:** Sensor Framework

**Estado:** Accepted

**Versión objetivo:** v1.1

**Descripción**

ARE incorpora una capa de sensores encargada de transformar eventos externos en eventos internos procesables por el motor de reputación.

El primer sensor implementado corresponde a Fail2Ban para el procesamiento de eventos FOUND.

---

## RFC-003

**Título:** Identity Migration

**Estado:** Draft

**Versión objetivo:** v1.1

**Descripción**

Completar la transición desde la identidad histórica `f2b-ipset` hacia el nombre oficial del proyecto: **ARE (Abuse Reputation Engine)**.

**Objetivo**

Alinear nombres de comandos, rutas, servicios, configuración y documentación con la identidad oficial del proyecto.

**Alcance inicial**

- Crear CLI oficial `are`.
- Mantener compatibilidad temporal con `f2b-ipset.sh`.
- Evaluar migración futura de `/opt/f2b-ipset/` hacia `/opt/are/`.
- Evaluar migración futura de configuración hacia `/etc/are/`.
- Evaluar migración futura de base de datos hacia rutas ARE.
- Actualizar documentación afectada.

**Nota**

Esta migración debe realizarse de forma gradual para no romper instalaciones existentes.

**Estado:** ✔ Validado en producción

**Implementado**

- Evento FOUND.
- Procesamiento desde Sensor Fail2Ban.
- Cursor persistente.
- Modo `--dry-run`.
- Modo `--execute`.
- Registro en SQLite.
- Integración con Policy Engine.
- Pruebas manuales y producción real satisfactorias.

**Pendiente**

- Ejecución continua.
- Limpieza final del sensor.
- Definir política de ejecución automática.

---

## RFC-004

**Título:** ARE como autoridad principal de decisión

**Estado:** Draft

**Versión objetivo:** v1.1

**Descripción**

Evaluar la transición del modelo actual, donde Fail2Ban ejecuta decisiones de `BAN` y `UNBAN`, hacia un modelo donde Fail2Ban actúa únicamente como fuente de eventos y ARE asume la autoridad principal sobre las decisiones de bloqueo, filtrado, liberación y escalado.

**Objetivo**

Permitir que ARE decida la respuesta final según reputación, score, historial, reincidencia y estado de la IP, evitando que un `UNBAN` externo contradiga una decisión tomada por el Policy Engine.

**Impacto esperado**

- Mayor autonomía de ARE.
- Mejor coherencia entre reputación y firewall.
- Control centralizado del ciclo de vida de una IP.
- Fail2Ban pasa a actuar como sensor, no como autoridad de decisión.

**Puntos a definir**

- Cómo tratar eventos `BAN` de Fail2Ban.
- Cómo tratar eventos `UNBAN` de Fail2Ban.
- Cuándo ARE debe liberar una IP.
- Cómo calcular escalado por reincidencia.
- Tiempo máximo de bloqueo temporal.
- Condiciones para bloqueo permanente.

**Validación inicial**

Se implementó y validó manualmente el comando:

```bash
./f2b-ipset.sh external-unban <IP> <JAIL>
```

---

## RFC-005

**Título:** Reputation Decay y ciclo autónomo de ban/unban

**Estado:** Draft

**Versión objetivo:** v1.1 / evaluación

**Descripción**

Diseñar un mecanismo para que ARE pueda reducir gradualmente el score de reputación de una IP cuando no exista actividad reciente, permitiendo que la reputación se recupere con el tiempo.

**Objetivo**

Permitir que ARE controle de forma autónoma el ciclo completo de una IP:

- observación;
- score;
- decisión;
- ban temporal;
- escalado por reincidencia;
- recuperación progresiva;
- unban decidido por ARE;
- ban permanente en casos críticos.

**Principios**

- Una IP deja de ser peligrosa gradualmente.
- La reputación no se borra de golpe.
- El `UNBAN` debe ser consecuencia de una decisión de ARE.
- Fail2Ban actúa como sensor, no como autoridad de decisión.
- Los límites de escalado deben ser configurables por el SysAdmin.

**Puntos a definir**

- Frecuencia del Decay Engine.
- Fórmula de reducción del score.
- Umbral para liberar una IP.
- Ban inicial.
- Multiplicador por reincidencia.
- Máximo de días para ban temporal.
- Condición para ban permanente.
- Relación entre `state`, `score` y `last_event`.

**Validación inicial**

Se verificó que la tabla `reputation` mantiene el campo `updated`, el cual representa la última modificación real de reputación de una IP.

Este valor permite calcular el tiempo sin actividad reciente y puede utilizarse como base para un futuro Decay Engine.

Ejemplo:

```text
ip | total_score | status | updated
5.5.5.5 | 1675 | BANNED | 2026-07-02
```

---

# IDEAS

## IDEA-001

Exportación de métricas.

---

## IDEA-002

API REST.

---

## IDEA-003

Backend Manager.

---

## IDEA-004

Reputation Decay Engine.

---

## IDEA-005

Dashboard avanzado.

---

# OBSERVACIONES

La rama **v1.1-dev** se utiliza para el desarrollo activo de nuevas funcionalidades.

Las versiones **1.0.x** permanecen destinadas exclusivamente a mantenimiento y corrección de errores.
